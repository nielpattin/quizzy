import { Hono } from 'hono'
import { authMiddleware } from '../middleware/auth'
import type { AuthContext } from '../middleware/auth'
import { db } from '../db/index'
import { gameSessions, gameSessionParticipants, quizSnapshots, questionsSnapshots, quizzes, questions, users, questionTimings, categories } from '../db/schema'
import { eq, and, desc, ilike, sql } from 'drizzle-orm'
import { WebSocketService } from '../services/websocket-service'

type Variables = {
  user: AuthContext
}

const sessionRoutes = new Hono<{ Variables: Variables }>()

async function checkAndCompleteSession(sessionId: string) {
  try {
    // Get session details
    const [session] = await db
      .select()
      .from(gameSessions)
      .where(eq(gameSessions.id, sessionId))

    if (!session || session.endedAt) {
      return // Session doesn't exist or already ended
    }

    // Get all questions for this session
    const sessionQuestions = await db
      .select()
      .from(questionsSnapshots)
      .where(eq(questionsSnapshots.snapshotId, session.quizSnapshotId))
      .orderBy(questionsSnapshots.orderIndex)

    const totalQuestions = sessionQuestions.length
    if (totalQuestions === 0) {
      return // No questions in session
    }

    // Get all participants and their answered questions
    const participantsWithAnswers = await db
      .select({
        participantId: gameSessionParticipants.id,
        userId: gameSessionParticipants.userId,
        answeredQuestions: sql<number>`COUNT(DISTINCT ${questionTimings.questionSnapshotId})`.mapWith(Number),
      })
      .from(gameSessionParticipants)
      .leftJoin(
        questionTimings,
        and(
          eq(questionTimings.participantId, gameSessionParticipants.id),
          sql`${questionTimings.submittedAt} IS NOT NULL`
        )
      )
      .where(eq(gameSessionParticipants.sessionId, sessionId))
      .groupBy(gameSessionParticipants.id, gameSessionParticipants.userId)

    // Check if all participants have answered all questions
    const allParticipantsCompleted = participantsWithAnswers.every(
      p => p.answeredQuestions >= totalQuestions
    )

    // Also check if there are any active participants (at least one)
    const hasActiveParticipants = participantsWithAnswers.length > 0

    if (allParticipantsCompleted && hasActiveParticipants) {
      // Only auto-end solo sessions (maxParticipants === 1)
      // Multiplayer sessions should only be ended by the host
      if (session.maxParticipants === 1) {
        await db
          .update(gameSessions)
          .set({
            isLive: false,
            endedAt: new Date(),
          })
          .where(eq(gameSessions.id, sessionId))

        console.log(`Solo session ${sessionId} automatically completed - all participants finished all questions`)
      } else {
        console.log(`Multiplayer session ${sessionId} - all participants completed but not auto-ending (host must end session)`)
      }
    }
  } catch (error) {
    console.error('Error checking session completion:', error)
  }
}

function generateSessionCode(): string {
  const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789'
  let code = ''
  for (let i = 0; i < 6; i++) {
    code += chars.charAt(Math.floor(Math.random() * chars.length))
  }
  return code
}

sessionRoutes.post('/', authMiddleware, async (c) => {
  const { userId } = c.get('user') as AuthContext
  const body = await c.req.json()

  try {
    if (!body.quizId) {
      return c.json({ error: 'quizId is required' }, 400)
    }

    const [quiz] = await db
      .select()
      .from(quizzes)
      .where(and(eq(quizzes.id, body.quizId), eq(quizzes.isDeleted, false)))

    if (!quiz) {
      return c.json({ error: 'Quiz not found' }, 404)
    }

    // Check for reusable session: same quiz, same version, current user is host, not ended
    const existingSessions = await db
      .select({
        session: gameSessions,
        snapshot: quizSnapshots,
      })
      .from(gameSessions)
      .innerJoin(quizSnapshots, eq(gameSessions.quizSnapshotId, quizSnapshots.id))
      .where(and(
        eq(quizSnapshots.quizId, quiz.id),
        eq(gameSessions.quizVersion, quiz.version),
        eq(gameSessions.hostId, userId),
        sql`${gameSessions.endedAt} IS NULL`
      ))
      .limit(1)

    // If reusable session found, return it (host doesn't need participant record)
    if (existingSessions.length > 0) {
      const existingSession = existingSessions[0].session

      return c.json({
        ...existingSession,
        participantId: null, // Host is not a participant
      }, 200)
    }

    // No reusable session found, create new session
    const [snapshot] = await db
      .insert(quizSnapshots)
      .values({
        quizId: quiz.id,
        version: quiz.version,
        title: quiz.title,
        description: quiz.description,
        questionCount: quiz.questionCount,
      })
      .returning()

    const quizQuestions = await db
      .select()
      .from(questions)
      .where(eq(questions.quizId, quiz.id))
      .orderBy(questions.orderIndex)

    if (quizQuestions.length > 0) {
      const snapshotQuestions = quizQuestions.map(q => ({
        snapshotId: snapshot.id,
        type: q.type,
        questionText: q.questionText,
        imageUrl: q.imageUrl,
        data: q.data,
        orderIndex: q.orderIndex,
      }))

      await db
        .insert(questionsSnapshots)
        .values(snapshotQuestions)
    }

    const code = generateSessionCode()

    const [newSession] = await db
      .insert(gameSessions)
      .values({
        hostId: userId,
        quizSnapshotId: snapshot.id,
        title: body.title || quiz.title,
        description: body.description || null,
        imageUrl: quiz.imageUrl || null,
        estimatedMinutes: body.estimatedMinutes || 10,
        isPublic: body.isPublic !== undefined ? body.isPublic : false, // Default: private session
        maxParticipants: body.maxParticipants || 1, // Default: solo play (1 participant slot)
        hasEndTime: body.hasEndTime !== undefined ? body.hasEndTime : false,
        endTime: body.endTime ? new Date(body.endTime) : null,
        code,
        quizVersion: quiz.version,
        isLive: false, // Session starts as NOT live, host must explicitly start it
        startedAt: null, // Will be set when session actually starts
      })
      .returning()

    // Don't auto-create participant for host
    // Host can join as player separately if they want to participate
    // This allows the host to act as facilitator only (like Kahoot)

    // Broadcast session created (only if public)
    if (newSession.isPublic) {
      await WebSocketService.broadcastSessionCreated(newSession.id, {
        id: newSession.id,
        title: newSession.title,
        isLive: newSession.isLive,
        participantCount: 0, // Start with 0 participants
        playerCount: 0, // Start with 0 players
        code: newSession.code,
        startedAt: newSession.startedAt,
        endedAt: newSession.endedAt,
        createdAt: newSession.createdAt,
      })
    }

    return c.json({
      ...newSession,
      participantId: null, // Host is not a participant by default
    }, 201)
  } catch (error) {
    console.error('Error creating game session:', error)
    return c.json({ error: 'Failed to create game session' }, 500)
  }
})

sessionRoutes.get('/code/:code', async (c) => {
  const code = c.req.param('code')

  try {
    const [session] = await db
      .select({
        id: gameSessions.id,
        title: gameSessions.title,
        imageUrl: gameSessions.imageUrl,
        estimatedMinutes: gameSessions.estimatedMinutes,
        isLive: gameSessions.isLive,
        participantCount: gameSessions.participantCount,
        playerCount: gameSessions.playerCount,
        code: gameSessions.code,
        startedAt: gameSessions.startedAt,
        createdAt: gameSessions.createdAt,
        host: {
          id: users.id,
          username: users.username,
          fullName: users.fullName,
          profilePictureUrl: users.profilePictureUrl,
        },
        snapshot: {
          id: quizSnapshots.id,
          title: quizSnapshots.title,
          questionCount: quizSnapshots.questionCount,
        },
      })
      .from(gameSessions)
      .leftJoin(users, eq(gameSessions.hostId, users.id))
      .leftJoin(quizSnapshots, eq(gameSessions.quizSnapshotId, quizSnapshots.id))
      .where(eq(gameSessions.code, code.toUpperCase()))

    if (!session) {
      return c.json({ error: 'Session not found' }, 404)
    }

    return c.json(session)
  } catch (error) {
    console.error('Error fetching session by code:', error)
    return c.json({ error: 'Failed to fetch session' }, 500)
  }
})

sessionRoutes.get('/:id', async (c) => {
  const sessionId = c.req.param('id')

  try {
    const [session] = await db
      .select({
        id: gameSessions.id,
        hostId: gameSessions.hostId,
        title: gameSessions.title,
        description: gameSessions.description,
        imageUrl: gameSessions.imageUrl,
        estimatedMinutes: gameSessions.estimatedMinutes,
        isLive: gameSessions.isLive,
        isPublic: gameSessions.isPublic,
        participantCount: gameSessions.participantCount,
        playerCount: gameSessions.playerCount,
        maxParticipants: gameSessions.maxParticipants,
        code: gameSessions.code,
        hasEndTime: gameSessions.hasEndTime,
        endTime: gameSessions.endTime,
        startedAt: gameSessions.startedAt,
        endedAt: gameSessions.endedAt,
        createdAt: gameSessions.createdAt,
        quizId: quizSnapshots.quizId,
        quizSnapshotId: quizSnapshots.id,
        host: {
          id: users.id,
          username: users.username,
          fullName: users.fullName,
          profilePictureUrl: users.profilePictureUrl,
        },
        snapshot: {
          id: quizSnapshots.id,
          quizId: quizSnapshots.quizId,
          title: quizSnapshots.title,
          description: quizSnapshots.description,
          questionCount: quizSnapshots.questionCount,
        },
      })
      .from(gameSessions)
      .leftJoin(users, eq(gameSessions.hostId, users.id))
      .leftJoin(quizSnapshots, eq(gameSessions.quizSnapshotId, quizSnapshots.id))
      .where(eq(gameSessions.id, sessionId))

    if (!session) {
      return c.json({ error: 'Session not found' }, 404)
    }

    return c.json(session)
  } catch (error) {
    console.error('Error fetching session:', error)
    return c.json({ error: 'Failed to fetch session' }, 500)
  }
})

sessionRoutes.put('/:id', authMiddleware, async (c) => {
  const { userId } = c.get('user') as AuthContext
  const sessionId = c.req.param('id')
  const body = await c.req.json()

  try {
    // Get current session
    const [session] = await db
      .select()
      .from(gameSessions)
      .where(eq(gameSessions.id, sessionId))

    if (!session) {
      return c.json({ error: 'Session not found' }, 404)
    }

    // Only host can update session
    if (session.hostId !== userId) {
      return c.json({ error: 'Only the host can update this session' }, 403)
    }

    // Prepare update data
    const updateData: any = {}
    
    if (body.title !== undefined) updateData.title = body.title
    if (body.description !== undefined) updateData.description = body.description
    if (body.imageUrl !== undefined) updateData.imageUrl = body.imageUrl
    if (body.isPublic !== undefined) updateData.isPublic = body.isPublic
    
    // Allow maxPlayers to be updated ONLY if session hasn't started (not live and only host joined)
    if (body.maxParticipants !== undefined) {
      if (!session.isLive && session.participantCount <= 1) {
        updateData.maxParticipants = body.maxParticipants
      } else {
        return c.json({ error: 'Cannot change max players after session has started or participants have joined' }, 400)
      }
    }
    
    if (body.hasEndTime !== undefined) updateData.hasEndTime = body.hasEndTime
    if (body.endTime !== undefined) updateData.endTime = body.endTime ? new Date(body.endTime) : null

    // Update session
    const [updatedSession] = await db
      .update(gameSessions)
      .set(updateData)
      .where(eq(gameSessions.id, sessionId))
      .returning()

    // TODO: Broadcast session update to participants if needed
    // await WebSocketService.broadcastSessionUpdate(sessionId, updatedSession)

    return c.json(updatedSession, 200)
  } catch (error) {
    console.error('Error updating session:', error)
    return c.json({ error: 'Failed to update session' }, 500)
  }
})

// Start a session (set isLive = true)
sessionRoutes.post('/:id/start', authMiddleware, async (c) => {
  const { userId } = c.get('user') as AuthContext
  const sessionId = c.req.param('id')

  try {
    // Get current session
    const [session] = await db
      .select()
      .from(gameSessions)
      .where(eq(gameSessions.id, sessionId))

    if (!session) {
      return c.json({ error: 'Session not found' }, 404)
    }

    // Only host can start session
    if (session.hostId !== userId) {
      return c.json({ error: 'Only the host can start this session' }, 403)
    }

    // Check session hasn't ended
    if (session.endedAt) {
      return c.json({ error: 'Session has already ended' }, 400)
    }

    // Check session isn't already live
    if (session.isLive) {
      return c.json({ error: 'Session is already live' }, 400)
    }

    // Update session to live
    const [updatedSession] = await db
      .update(gameSessions)
      .set({
        isLive: true,
        startedAt: new Date(),
      })
      .where(eq(gameSessions.id, sessionId))
      .returning()

    // Broadcast session started event to all participants
    await WebSocketService.broadcastSessionStarted(sessionId)

    return c.json(updatedSession, 200)
  } catch (error) {
    console.error('Error starting session:', error)
    return c.json({ error: 'Failed to start session' }, 500)
  }
})

sessionRoutes.post('/:id/join', authMiddleware, async (c) => {
  const { userId } = c.get('user') as AuthContext
  const sessionId = c.req.param('id')

  try {
    const [session] = await db
      .select()
      .from(gameSessions)
      .where(eq(gameSessions.id, sessionId))

    if (!session) {
      return c.json({ error: 'Session not found' }, 404)
    }

    // Allow rejoining sessions that were auto-ended (for "Play Again" functionality)
    // Only prevent joining if session is truly ended (not live and explicitly ended by host)
    // Auto-ended sessions (endedAt set but could be from auto-completion) can be rejoined
    if (session.endedAt && !session.isLive) {
      // Check if this user already has participants - if yes, allow Play Again
      const existingUserParticipants = await db
        .select()
        .from(gameSessionParticipants)
        .where(and(
          eq(gameSessionParticipants.sessionId, sessionId),
          eq(gameSessionParticipants.userId, userId)
        ))
      
      // If user has no previous attempts, session is truly ended - reject
      if (existingUserParticipants.length === 0) {
        return c.json({ error: 'Session has ended' }, 400)
      }
      // Otherwise allow Play Again - user is rejoining for another attempt
    }

    // Check if session has capacity
    if (session.participantCount >= session.maxParticipants) {
      return c.json({ error: 'Session is full' }, 400)
    }

    // Check if this is user's first join (for playerCount tracking)
    const existingParticipants = await db
      .select()
      .from(gameSessionParticipants)
      .where(and(
        eq(gameSessionParticipants.sessionId, sessionId),
        eq(gameSessionParticipants.userId, userId)
      ))

    const isFirstJoin = existingParticipants.length === 0

    // Create new participant (allow multiple attempts)
    const [newParticipant] = await db
      .insert(gameSessionParticipants)
      .values({
        sessionId,
        userId,
      })
      .returning()

    // Update session counts
    // Note: participantCount tracks total completed plays, not joins
    // It will be incremented when participant completes all questions
    await db
      .update(gameSessions)
      .set({
        playerCount: isFirstJoin ? session.playerCount + 1 : session.playerCount,
      })
      .where(eq(gameSessions.id, sessionId))

    // Broadcast participant joined event
    await WebSocketService.broadcastParticipantJoined(sessionId, userId)

    return c.json(newParticipant, 201)
  } catch (error) {
    console.error('Error joining session:', error)
    return c.json({ error: 'Failed to join session' }, 500)
  }
})



sessionRoutes.get('/:id/participants', async (c) => {
  const sessionId = c.req.param('id')

  try {
    const participants = await db
      .select({
        id: gameSessionParticipants.id,
        userId: gameSessionParticipants.userId,
        score: gameSessionParticipants.score,
        rank: gameSessionParticipants.rank,
        joinedAt: gameSessionParticipants.joinedAt,
        user: {
          id: users.id,
          username: users.username,
          fullName: users.fullName,
          profilePictureUrl: users.profilePictureUrl,
        },
      })
      .from(gameSessionParticipants)
      .leftJoin(users, eq(gameSessionParticipants.userId, users.id))
      .where(eq(gameSessionParticipants.sessionId, sessionId))
      .orderBy(gameSessionParticipants.joinedAt)

    return c.json(participants)
  } catch (error) {
    console.error('Error fetching participants:', error)
    return c.json({ error: 'Failed to fetch participants' }, 500)
  }
})

// Get current user's participants in this session with progress info
sessionRoutes.get('/:id/participants/me', authMiddleware, async (c) => {
  const { userId } = c.get('user') as AuthContext
  const sessionId = c.req.param('id')

  try {
    // Get session to fetch total questions
    const [session] = await db
      .select({
        quizSnapshotId: gameSessions.quizSnapshotId,
      })
      .from(gameSessions)
      .where(eq(gameSessions.id, sessionId))

    if (!session) {
      return c.json({ error: 'Session not found' }, 404)
    }

    // Get total questions for this session
    const totalQuestionsResult = await db
      .select({
        count: sql<number>`COUNT(*)`.mapWith(Number),
      })
      .from(questionsSnapshots)
      .where(eq(questionsSnapshots.snapshotId, session.quizSnapshotId))

    const totalQuestions = totalQuestionsResult[0]?.count || 0

    // Get user's participants with answered question count
    // Only include participants who have started playing (have at least one question_timing record)
    const participants = await db
      .select({
        id: gameSessionParticipants.id,
        sessionId: gameSessionParticipants.sessionId,
        userId: gameSessionParticipants.userId,
        score: gameSessionParticipants.score,
        rank: gameSessionParticipants.rank,
        joinedAt: gameSessionParticipants.joinedAt,
        answeredQuestions: sql<number>`COUNT(DISTINCT CASE WHEN ${questionTimings.submittedAt} IS NOT NULL THEN ${questionTimings.questionSnapshotId} END)`.mapWith(Number),
        totalTimings: sql<number>`COUNT(${questionTimings.id})`.mapWith(Number),
      })
      .from(gameSessionParticipants)
      .leftJoin(
        questionTimings,
        eq(questionTimings.participantId, gameSessionParticipants.id)
      )
      .where(and(
        eq(gameSessionParticipants.sessionId, sessionId),
        eq(gameSessionParticipants.userId, userId)
      ))
      .groupBy(
        gameSessionParticipants.id,
        gameSessionParticipants.sessionId,
        gameSessionParticipants.userId,
        gameSessionParticipants.score,
        gameSessionParticipants.rank,
        gameSessionParticipants.joinedAt
      )
      .having(sql`COUNT(${questionTimings.id}) > 0`)
      .orderBy(desc(gameSessionParticipants.joinedAt))

    // Add computed fields - assign attempt numbers chronologically
    // With DESC order: index 0 = newest (highest #), index N = oldest (#1)
    const participantsWithProgress = participants.map((p, index) => ({
      ...p,
      totalQuestions,
      isCompleted: p.answeredQuestions >= totalQuestions,
      attemptNumber: participants.length - index, // Latest gets highest number
    }))

    return c.json({ participants: participantsWithProgress })
  } catch (error) {
    console.error('Error fetching user participants:', error)
    return c.json({ error: 'Failed to fetch user participants' }, 500)
  }
})

sessionRoutes.get('/:id/leaderboard', async (c) => {
  const sessionId = c.req.param('id')

  try {
    const participants = await db
      .select({
        id: gameSessionParticipants.id,
        score: gameSessionParticipants.score,
        rank: gameSessionParticipants.rank,
        joinedAt: gameSessionParticipants.joinedAt,
        user: {
          id: users.id,
          username: users.username,
          fullName: users.fullName,
          profilePictureUrl: users.profilePictureUrl,
        },
      })
      .from(gameSessionParticipants)
      .leftJoin(users, eq(gameSessionParticipants.userId, users.id))
      .where(eq(gameSessionParticipants.sessionId, sessionId))
      .orderBy(desc(gameSessionParticipants.score))

    return c.json(participants)
  } catch (error) {
    console.error('Error fetching leaderboard:', error)
    return c.json({ error: 'Failed to fetch leaderboard' }, 500)
  }
})

sessionRoutes.get('/:id/questions', async (c) => {
  const sessionId = c.req.param('id')

  try {
    const [session] = await db
      .select()
      .from(gameSessions)
      .where(eq(gameSessions.id, sessionId))

    if (!session) {
      return c.json({ error: 'Session not found' }, 404)
    }

    const sessionQuestions = await db
      .select()
      .from(questionsSnapshots)
      .where(eq(questionsSnapshots.snapshotId, session.quizSnapshotId))
      .orderBy(questionsSnapshots.orderIndex)

    return c.json(sessionQuestions)
  } catch (error) {
    console.error('Error fetching session questions:', error)
    return c.json({ error: 'Failed to fetch session questions' }, 500)
  }
})

sessionRoutes.get('/:id/question/:index', authMiddleware, async (c) => {
  const { userId } = c.get('user') as AuthContext
  const sessionId = c.req.param('id')
  const questionIndex = parseInt(c.req.param('index'))

  try {
    const [session] = await db
      .select()
      .from(gameSessions)
      .where(eq(gameSessions.id, sessionId))

    if (!session) {
      return c.json({ error: 'Session not found' }, 404)
    }

    // Find the LATEST participant for this user in this session (for "Play Again" support)
    const [participant] = await db
      .select()
      .from(gameSessionParticipants)
      .where(and(
        eq(gameSessionParticipants.sessionId, sessionId),
        eq(gameSessionParticipants.userId, userId)
      ))
      .orderBy(desc(gameSessionParticipants.joinedAt))
      .limit(1)

    if (!participant) {
      return c.json({ error: 'Not a participant in this session' }, 404)
    }

    const sessionQuestions = await db
      .select()
      .from(questionsSnapshots)
      .where(eq(questionsSnapshots.snapshotId, session.quizSnapshotId))
      .orderBy(questionsSnapshots.orderIndex)

    if (questionIndex < 0 || questionIndex >= sessionQuestions.length) {
      return c.json({ error: 'Question index out of range' }, 400)
    }

    const question = sessionQuestions[questionIndex]
    const timeLimit = question.data?.timeLimit || 30

    // Check if timing record already exists
    const [existingTiming] = await db
      .select()
      .from(questionTimings)
      .where(and(
        eq(questionTimings.participantId, participant.id),
        eq(questionTimings.questionSnapshotId, question.id)
      ))

    if (existingTiming) {
      return c.json({
        question,
        timing: {
          id: existingTiming.id,
          timeLimit,
          serverStartTime: existingTiming.serverStartTime.toISOString(),
          deadlineTime: existingTiming.deadlineTime.toISOString(),
        },
      })
    }

    // Create timing record with correct participantId
    const [timingRecord] = await db
      .insert(questionTimings)
      .values({
        participantId: participant.id,
        questionSnapshotId: question.id,
        sessionId,
        serverStartTime: new Date(),
        deadlineTime: new Date(Date.now() + timeLimit * 1000),
      })
      .returning()

    return c.json({
      question,
      timing: {
        id: timingRecord.id,
        timeLimit,
        serverStartTime: timingRecord.serverStartTime.toISOString(),
        deadlineTime: timingRecord.deadlineTime.toISOString(),
      },
    })
  } catch (error) {
    console.error('Error fetching question with timing:', error)
    return c.json({ error: 'Failed to fetch question with timing' }, 500)
  }
})

sessionRoutes.post('/:id/answer', authMiddleware, async (c) => {
  const { userId } = c.get('user') as AuthContext
  const sessionId = c.req.param('id')
  const body = await c.req.json()

  try {
    if (!body.questionId || !body.answer) {
      return c.json({ error: 'questionId and answer are required' }, 400)
    }

    // Find the LATEST participant for this user in this session (for "Play Again" support)
    const [participant] = await db
      .select()
      .from(gameSessionParticipants)
      .where(and(
        eq(gameSessionParticipants.sessionId, sessionId),
        eq(gameSessionParticipants.userId, userId)
      ))
      .orderBy(desc(gameSessionParticipants.joinedAt))
      .limit(1)

    if (!participant) {
      return c.json({ error: 'Not a participant in this session' }, 404)
    }

    // Get timing record
    const [timing] = await db
      .select()
      .from(questionTimings)
      .where(and(
        eq(questionTimings.participantId, participant.id),
        eq(questionTimings.questionSnapshotId, body.questionId),
        eq(questionTimings.sessionId, sessionId)
      ))
      .limit(1)

    if (!timing) {
      return c.json({ error: 'Question timing not found' }, 404)
    }

    // Check if time expired
    const now = new Date()
    if (now > timing.deadlineTime) {
      // Accept late submission but give 0 score
      await db
        .update(questionTimings)
        .set({ submittedAt: now })
        .where(eq(questionTimings.id, timing.id))

      // Don't update participant score (0 points)
      return c.json({
        isCorrect: false,
        score: 0,
        message: 'Time expired - no points awarded',
      })
    }

    // Process answer (simplified - in real implementation, validate against correct answer)
    const isCorrect = Math.random() > 0.5 // Placeholder logic
    const score = isCorrect ? 100 : 0

    // Update timing record
    await db
      .update(questionTimings)
      .set({ submittedAt: now })
      .where(eq(questionTimings.id, timing.id))

    // Update participant score
    await db
      .update(gameSessionParticipants)
      .set({
        score: sql`${gameSessionParticipants.score} + ${score}`,
      })
      .where(eq(gameSessionParticipants.id, participant.id))

    // Check if this participant just completed all questions for the first time
    const [session] = await db
      .select()
      .from(gameSessions)
      .where(eq(gameSessions.id, sessionId))
    
    if (session) {
      // Get total questions for this session
      const sessionQuestions = await db
        .select()
        .from(questionsSnapshots)
        .where(eq(questionsSnapshots.snapshotId, session.quizSnapshotId))
      
      const totalQuestions = sessionQuestions.length
      
      // Count how many questions this participant has answered (including the one just submitted)
      const [answeredCount] = await db
        .select({
          count: sql<number>`COUNT(DISTINCT ${questionTimings.questionSnapshotId})`.mapWith(Number)
        })
        .from(questionTimings)
        .where(and(
          eq(questionTimings.participantId, participant.id),
          sql`${questionTimings.submittedAt} IS NOT NULL`
        ))
      
      // If participant just completed all questions (answeredCount equals totalQuestions)
      // Increment participantCount (total plays)
      if (answeredCount.count === totalQuestions) {
        await db
          .update(gameSessions)
          .set({
            participantCount: sql`${gameSessions.participantCount} + 1`,
          })
          .where(eq(gameSessions.id, sessionId))
        
        console.log(`Participant ${participant.id} completed all ${totalQuestions} questions - incrementing play count to ${session.participantCount + 1}`)
      }
    }

    // Check if session should be automatically completed
    await checkAndCompleteSession(sessionId)

    return c.json({
      isCorrect,
      score,
      message: isCorrect ? 'Correct answer!' : 'Incorrect answer',
    })
  } catch (error) {
    console.error('Error submitting answer:', error)
    return c.json({ error: 'Failed to submit answer' }, 500)
  }
})

sessionRoutes.get('/user/:userId/hosted', async (c) => {
  const targetUserId = c.req.param('userId')

  try {
    const hostedSessions = await db
      .select({
        id: gameSessions.id,
        title: gameSessions.title,
        imageUrl: sql<string>`COALESCE(${gameSessions.imageUrl}, ${quizzes.imageUrl})`,
        estimatedMinutes: gameSessions.estimatedMinutes,
        isLive: gameSessions.isLive,
        participantCount: gameSessions.participantCount,
        playerCount: gameSessions.playerCount,
        code: gameSessions.code,
        startedAt: gameSessions.startedAt,
        endedAt: gameSessions.endedAt,
        createdAt: gameSessions.createdAt,
      })
      .from(gameSessions)
      .leftJoin(quizSnapshots, eq(gameSessions.quizSnapshotId, quizSnapshots.id))
      .leftJoin(quizzes, eq(quizSnapshots.quizId, quizzes.id))
      .where(eq(gameSessions.hostId, targetUserId))
      .orderBy(desc(gameSessions.createdAt))

    return c.json(hostedSessions)
  } catch (error) {
    console.error('Error fetching hosted sessions:', error)
    return c.json({ error: 'Failed to fetch hosted sessions' }, 500)
  }
})

sessionRoutes.post('/:id/leave', authMiddleware, async (c) => {
  const { userId } = c.get('user') as AuthContext
  const sessionId = c.req.param('id')

  try {
    const [session] = await db
      .select()
      .from(gameSessions)
      .where(eq(gameSessions.id, sessionId))

    if (!session) {
      return c.json({ error: 'Session not found' }, 404)
    }

    // Find the LATEST participant for this user in this session
    const [existingParticipant] = await db
      .select()
      .from(gameSessionParticipants)
      .where(and(
        eq(gameSessionParticipants.sessionId, sessionId),
        eq(gameSessionParticipants.userId, userId)
      ))
      .orderBy(desc(gameSessionParticipants.joinedAt))
      .limit(1)

    if (!existingParticipant) {
      return c.json({ error: 'Not a participant in this session' }, 400)
    }

    // Check if participant has started playing (has any question_timings)
    const timings = await db
      .select()
      .from(questionTimings)
      .where(eq(questionTimings.participantId, existingParticipant.id))
      .limit(1)

    // Only delete participant if they haven't started playing
    // If they have timings, preserve their game progress
    if (timings.length === 0) {
      // No timings = lobby member only, safe to delete
      // Delete by ID to avoid deleting all participants for this user
      await db
        .delete(gameSessionParticipants)
        .where(eq(gameSessionParticipants.id, existingParticipant.id))

      // Note: No need to decrement participantCount since it only tracks completed plays
      // and this participant never completed (no timings)

      // Broadcast participant left event
      await WebSocketService.broadcastParticipantLeft(sessionId, userId)

      return c.json({ message: 'Left session successfully' })
    } else {
      // Has timings = game in progress, keep participant record
      // Just acknowledge the leave request (user navigating away)
      // The participant record preserves their progress
      return c.json({ 
        message: 'Progress saved', 
        note: 'Participant record preserved for game continuation' 
      })
    }
  } catch (error) {
    console.error('Error leaving session:', error)
    return c.json({ error: 'Failed to leave session' }, 500)
  }
})

sessionRoutes.get('/user/:userId/played', async (c) => {
  const targetUserId = c.req.param('userId')

  try {
    const playedSessions = await db
      .select({
        id: gameSessions.id,
        hostId: gameSessions.hostId,
        title: gameSessions.title,
        imageUrl: sql<string>`COALESCE(${gameSessions.imageUrl}, ${quizzes.imageUrl})`,
        estimatedMinutes: gameSessions.estimatedMinutes,
        isLive: gameSessions.isLive,
        participantCount: gameSessions.participantCount,
        code: gameSessions.code,
        startedAt: gameSessions.startedAt,
        endedAt: gameSessions.endedAt,
        createdAt: gameSessions.createdAt,
        host: {
          id: users.id,
          username: users.username,
          fullName: users.fullName,
          profilePictureUrl: users.profilePictureUrl,
        },
        category: {
          id: categories.id,
          name: categories.name,
          slug: categories.slug,
        },
        snapshot: {
          id: quizSnapshots.id,
          quizId: quizSnapshots.quizId,
          title: quizSnapshots.title,
          questionCount: quizSnapshots.questionCount,
        },
        participant: {
          id: gameSessionParticipants.id,
          score: gameSessionParticipants.score,
          rank: gameSessionParticipants.rank,
          joinedAt: gameSessionParticipants.joinedAt,
        },
      })
      .from(gameSessionParticipants)
      .leftJoin(gameSessions, eq(gameSessionParticipants.sessionId, gameSessions.id))
      .leftJoin(quizSnapshots, eq(gameSessions.quizSnapshotId, quizSnapshots.id))
      .leftJoin(quizzes, eq(quizSnapshots.quizId, quizzes.id))
      .leftJoin(categories, eq(quizzes.categoryId, categories.id))
      .leftJoin(users, eq(gameSessions.hostId, users.id))
      .where(eq(gameSessionParticipants.userId, targetUserId))
      .orderBy(desc(gameSessionParticipants.joinedAt))

    // Deduplicate sessions - keep only the most recent participant for each session
    const uniqueSessions = new Map()
    
    for (const session of playedSessions) {
      const sessionId = session.id
      
      // If we haven't seen this session yet, or this participant is more recent
      if (!uniqueSessions.has(sessionId)) {
        uniqueSessions.set(sessionId, session)
      }
      // Note: Already ordered by joinedAt DESC, so first occurrence is most recent
    }

    return c.json(Array.from(uniqueSessions.values()))
  } catch (error) {
    console.error('Error fetching played sessions:', error)
    return c.json({ error: 'Failed to fetch played sessions' }, 500)
  }
})

export default sessionRoutes

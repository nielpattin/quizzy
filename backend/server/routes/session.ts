import { Hono } from 'hono'
import { authMiddleware } from '../middleware/auth'
import type { AuthContext } from '../middleware/auth'
import { db } from '../db/index'
import { gameSessions, gameSessionParticipants, quizSnapshots, questionsSnapshots, quizzes, questions, users, userQuestionTimings } from '../db/schema'
import { eq, and, desc, ilike, sql } from 'drizzle-orm'
import { WebSocketService } from '../services/websocket-service'

type Variables = {
  user: AuthContext
}

const sessionRoutes = new Hono<{ Variables: Variables }>()

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

    const [snapshot] = await db
      .insert(quizSnapshots)
      .values({
        quizId: quiz.id,
        version: quiz.version,
        title: quiz.title,
        description: quiz.description,
        category: quiz.category,
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
        estimatedMinutes: body.estimatedMinutes || 10,
        code,
        quizVersion: quiz.version,
      })
      .returning()

    return c.json(newSession, 201)
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
        estimatedMinutes: gameSessions.estimatedMinutes,
        isLive: gameSessions.isLive,
        joinedCount: gameSessions.joinedCount,
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
        title: gameSessions.title,
        estimatedMinutes: gameSessions.estimatedMinutes,
        isLive: gameSessions.isLive,
        joinedCount: gameSessions.joinedCount,
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
        snapshot: {
          id: quizSnapshots.id,
          title: quizSnapshots.title,
          description: quizSnapshots.description,
          category: quizSnapshots.category,
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

    if (session.endedAt) {
      return c.json({ error: 'Session has ended' }, 400)
    }

    const [existingParticipant] = await db
      .select()
      .from(gameSessionParticipants)
      .where(and(
        eq(gameSessionParticipants.sessionId, sessionId),
        eq(gameSessionParticipants.userId, userId)
      ))

    if (existingParticipant) {
      return c.json({ message: 'Already joined this session', participant: existingParticipant })
    }

    const [newParticipant] = await db
      .insert(gameSessionParticipants)
      .values({
        sessionId,
        userId,
      })
      .returning()

    await db
      .update(gameSessions)
      .set({
        joinedCount: session.joinedCount + 1,
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

sessionRoutes.post('/:id/start', authMiddleware, async (c) => {
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

    if (session.hostId !== userId) {
      return c.json({ error: 'Only the host can start the session' }, 403)
    }

    if (session.startedAt) {
      return c.json({ error: 'Session already started' }, 400)
    }

    const [updatedSession] = await db
      .update(gameSessions)
      .set({
        isLive: true,
        startedAt: new Date(),
      })
      .where(eq(gameSessions.id, sessionId))
      .returning()

    return c.json(updatedSession)
  } catch (error) {
    console.error('Error starting session:', error)
    return c.json({ error: 'Failed to start session' }, 500)
  }
})

sessionRoutes.post('/:id/end', authMiddleware, async (c) => {
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

    if (session.hostId !== userId) {
      return c.json({ error: 'Only the host can end the session' }, 403)
    }

    if (session.endedAt) {
      return c.json({ error: 'Session already ended' }, 400)
    }

    const [updatedSession] = await db
      .update(gameSessions)
      .set({
        isLive: false,
        endedAt: new Date(),
      })
      .where(eq(gameSessions.id, sessionId))
      .returning()

    return c.json(updatedSession)
  } catch (error) {
    console.error('Error ending session:', error)
    return c.json({ error: 'Failed to end session' }, 500)
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

    // Create timing record
    const [timingRecord] = await db
      .insert(userQuestionTimings)
      .values({
        userId,
        questionId: question.id,
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

    // Get timing record
    const [timing] = await db
      .select()
      .from(userQuestionTimings)
      .where(and(
        eq(userQuestionTimings.userId, userId),
        eq(userQuestionTimings.questionId, body.questionId),
        eq(userQuestionTimings.sessionId, sessionId)
      ))
      .limit(1)

    if (!timing) {
      return c.json({ error: 'Question timing not found' }, 404)
    }

    // Check if time expired
    const now = new Date()
    if (now > timing.deadlineTime) {
      return c.json({
        error: 'time_expired',
        message: 'Time limit exceeded',
        correctAnswer: body.questionId, // In real implementation, fetch actual correct answer
      }, 400)
    }

    // Process answer (simplified - in real implementation, validate against correct answer)
    const isCorrect = Math.random() > 0.5 // Placeholder logic
    const score = isCorrect ? 100 : 0

    // Update timing record
    await db
      .update(userQuestionTimings)
      .set({ submittedAt: now })
      .where(eq(userQuestionTimings.id, timing.id))

    // Update participant score
    await db
      .update(gameSessionParticipants)
      .set({
        score: sql`${gameSessionParticipants.score} + ${score}`,
      })
      .where(and(
        eq(gameSessionParticipants.sessionId, sessionId),
        eq(gameSessionParticipants.userId, userId)
      ))

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
        estimatedMinutes: gameSessions.estimatedMinutes,
        isLive: gameSessions.isLive,
        joinedCount: gameSessions.joinedCount,
        code: gameSessions.code,
        startedAt: gameSessions.startedAt,
        endedAt: gameSessions.endedAt,
        createdAt: gameSessions.createdAt,
      })
      .from(gameSessions)
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

    const [existingParticipant] = await db
      .select()
      .from(gameSessionParticipants)
      .where(and(
        eq(gameSessionParticipants.sessionId, sessionId),
        eq(gameSessionParticipants.userId, userId)
      ))

    if (!existingParticipant) {
      return c.json({ error: 'Not a participant in this session' }, 400)
    }

    await db
      .delete(gameSessionParticipants)
      .where(and(
        eq(gameSessionParticipants.sessionId, sessionId),
        eq(gameSessionParticipants.userId, userId)
      ))

    await db
      .update(gameSessions)
      .set({
        joinedCount: Math.max(0, session.joinedCount - 1),
      })
      .where(eq(gameSessions.id, sessionId))

    // Broadcast participant left event
    await WebSocketService.broadcastParticipantLeft(sessionId, userId)

    return c.json({ message: 'Left session successfully' })
  } catch (error) {
    console.error('Error leaving session:', error)
    return c.json({ error: 'Failed to leave session' }, 500)
  }
})

sessionRoutes.post('/:id/score', authMiddleware, async (c) => {
  const { userId } = c.get('user') as AuthContext
  const sessionId = c.req.param('id')
  const body = await c.req.json()

  try {
    if (!body.score || body.score < 0) {
      return c.json({ error: 'Valid score is required' }, 400)
    }

    const [session] = await db
      .select()
      .from(gameSessions)
      .where(eq(gameSessions.id, sessionId))

    if (!session) {
      return c.json({ error: 'Session not found' }, 404)
    }

    const [existingParticipant] = await db
      .select()
      .from(gameSessionParticipants)
      .where(and(
        eq(gameSessionParticipants.sessionId, sessionId),
        eq(gameSessionParticipants.userId, userId)
      ))

    if (!existingParticipant) {
      return c.json({ error: 'Not a participant in this session' }, 400)
    }

    const [updatedParticipant] = await db
      .update(gameSessionParticipants)
      .set({
        score: body.score,
        rank: body.rank, // Optional rank update
      })
      .where(and(
        eq(gameSessionParticipants.sessionId, sessionId),
        eq(gameSessionParticipants.userId, userId)
      ))
      .returning()

    return c.json(updatedParticipant)
  } catch (error) {
    console.error('Error updating score:', error)
    return c.json({ error: 'Failed to update score' }, 500)
  }
})

sessionRoutes.get('/user/:userId/played', async (c) => {
  const targetUserId = c.req.param('userId')

  try {
    const playedSessions = await db
      .select({
        id: gameSessions.id,
        title: gameSessions.title,
        estimatedMinutes: gameSessions.estimatedMinutes,
        isLive: gameSessions.isLive,
        joinedCount: gameSessions.joinedCount,
        startedAt: gameSessions.startedAt,
        endedAt: gameSessions.endedAt,
        createdAt: gameSessions.createdAt,
        participant: {
          score: gameSessionParticipants.score,
          rank: gameSessionParticipants.rank,
          joinedAt: gameSessionParticipants.joinedAt,
        },
      })
      .from(gameSessionParticipants)
      .leftJoin(gameSessions, eq(gameSessionParticipants.sessionId, gameSessions.id))
      .where(eq(gameSessionParticipants.userId, targetUserId))
      .orderBy(desc(gameSessionParticipants.joinedAt))

    return c.json(playedSessions)
  } catch (error) {
    console.error('Error fetching played sessions:', error)
    return c.json({ error: 'Failed to fetch played sessions' }, 500)
  }
})

export default sessionRoutes

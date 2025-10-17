import { Hono } from 'hono'
import { authMiddleware } from '@/middleware/auth'
import type { AuthContext } from '@/middleware/auth'
import { db } from '@/db'
import { gameSessions, gameSessionParticipants, quizSnapshots, questionsSnapshots, quizzes, questions, users } from '@/db/schema'
import { eq, and, desc } from 'drizzle-orm'

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

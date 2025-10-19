import { Hono } from 'hono'
import { authMiddleware } from '@/middleware/auth'
import type { AuthContext } from '@/middleware/auth'
import { db } from '@/db'
import { savedQuizzes, quizSnapshots, quizzes, questions, questionsSnapshots } from '@/db/schema'
import { eq, and, desc } from 'drizzle-orm'

type Variables = {
  user: AuthContext
}

const favoriteRoutes = new Hono<{ Variables: Variables }>()

favoriteRoutes.post('/:quizId', authMiddleware, async (c) => {
  const { userId } = c.get('user') as AuthContext
  const quizId = c.req.param('quizId')

  try {
    const [quiz] = await db
      .select()
      .from(quizzes)
      .where(and(eq(quizzes.id, quizId), eq(quizzes.isDeleted, false)))

    if (!quiz) {
      return c.json({ error: 'Quiz not found' }, 404)
    }

    const [latestSnapshot] = await db
      .select()
      .from(quizSnapshots)
      .where(eq(quizSnapshots.quizId, quizId))
      .orderBy(desc(quizSnapshots.version))
      .limit(1)

    let snapshotId: string

    if (latestSnapshot) {
      snapshotId = latestSnapshot.id
    } else {
      const [newSnapshot] = await db
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

      snapshotId = newSnapshot.id

      const quizQuestions = await db
        .select()
        .from(questions)
        .where(eq(questions.quizId, quiz.id))
        .orderBy(questions.orderIndex)

      if (quizQuestions.length > 0) {
        const snapshotQuestions = quizQuestions.map(q => ({
          snapshotId: newSnapshot.id,
          type: q.type,
          questionText: q.questionText,
          data: q.data,
          orderIndex: q.orderIndex,
        }))

        await db
          .insert(questionsSnapshots)
          .values(snapshotQuestions)
      }
    }

    const [existingFavorite] = await db
      .select()
      .from(savedQuizzes)
      .where(and(
        eq(savedQuizzes.userId, userId),
        eq(savedQuizzes.quizSnapshotId, snapshotId)
      ))

    if (existingFavorite) {
      return c.json({ message: 'Quiz already saved' }, 200)
    }

    const [newFavorite] = await db
      .insert(savedQuizzes)
      .values({
        userId,
        quizSnapshotId: snapshotId,
      })
      .returning()

    await db
      .update(quizzes)
      .set({
        favoriteCount: quiz.favoriteCount + 1,
      })
      .where(eq(quizzes.id, quizId))

    return c.json(newFavorite, 201)
  } catch (error) {
    console.error('Error saving quiz:', error)
    return c.json({ error: 'Failed to save quiz' }, 500)
  }
})

favoriteRoutes.delete('/:quizId', authMiddleware, async (c) => {
  const { userId } = c.get('user') as AuthContext
  const quizId = c.req.param('quizId')

  try {
    const snapshots = await db
      .select()
      .from(quizSnapshots)
      .where(eq(quizSnapshots.quizId, quizId))

    const snapshotIds = snapshots.map(s => s.id)

    if (snapshotIds.length === 0) {
      return c.json({ error: 'Quiz not found' }, 404)
    }

    const [existingFavorite] = await db
      .select()
      .from(savedQuizzes)
      .where(and(
        eq(savedQuizzes.userId, userId),
        eq(savedQuizzes.quizSnapshotId, snapshotIds[0])
      ))

    if (!existingFavorite) {
      return c.json({ error: 'Quiz not saved' }, 404)
    }

    await db
      .delete(savedQuizzes)
      .where(and(
        eq(savedQuizzes.userId, userId),
        eq(savedQuizzes.quizSnapshotId, existingFavorite.quizSnapshotId)
      ))

    const [quiz] = await db
      .select()
      .from(quizzes)
      .where(eq(quizzes.id, quizId))

    if (quiz) {
      await db
        .update(quizzes)
        .set({
          favoriteCount: Math.max(0, quiz.favoriteCount - 1),
        })
        .where(eq(quizzes.id, quizId))
    }

    return c.json({ message: 'Quiz unsaved successfully' })
  } catch (error) {
    console.error('Error unsaving quiz:', error)
    return c.json({ error: 'Failed to unsave quiz' }, 500)
  }
})

favoriteRoutes.get('/', authMiddleware, async (c) => {
  const { userId } = c.get('user') as AuthContext

  try {
    const favorites = await db
      .select({
        id: savedQuizzes.id,
        savedAt: savedQuizzes.savedAt,
        quiz: {
          id: quizSnapshots.quizId,
          title: quizSnapshots.title,
          description: quizSnapshots.description,
          category: quizSnapshots.category,
          questionCount: quizSnapshots.questionCount,
          playCount: quizzes.playCount,
          createdAt: quizSnapshots.createdAt,
        },
      })
      .from(savedQuizzes)
      .leftJoin(quizSnapshots, eq(savedQuizzes.quizSnapshotId, quizSnapshots.id))
      .leftJoin(quizzes, eq(quizSnapshots.quizId, quizzes.id))
      .where(eq(savedQuizzes.userId, userId))
      .orderBy(desc(savedQuizzes.savedAt))

    return c.json(favorites)
  } catch (error) {
    console.error('Error fetching favorites:', error)
    return c.json({ error: 'Failed to fetch favorites' }, 500)
  }
})

favoriteRoutes.get('/check/:quizId', authMiddleware, async (c) => {
  const { userId } = c.get('user') as AuthContext
  const quizId = c.req.param('quizId')

  try {
    const snapshots = await db
      .select()
      .from(quizSnapshots)
      .where(eq(quizSnapshots.quizId, quizId))

    const snapshotIds = snapshots.map(s => s.id)

    if (snapshotIds.length === 0) {
      return c.json({ isSaved: false })
    }

    const [existingFavorite] = await db
      .select()
      .from(savedQuizzes)
      .where(and(
        eq(savedQuizzes.userId, userId),
        eq(savedQuizzes.quizSnapshotId, snapshotIds[0])
      ))

    return c.json({ isSaved: !!existingFavorite })
  } catch (error) {
    console.error('Error checking favorite status:', error)
    return c.json({ error: 'Failed to check favorite status' }, 500)
  }
})

export default favoriteRoutes

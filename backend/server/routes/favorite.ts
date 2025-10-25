import { Hono } from 'hono'
import { authMiddleware } from '@/middleware/auth'
import type { AuthContext } from '@/middleware/auth'
import { db } from '@/db'
import { favoriteQuizzes, quizzes } from '@/db/schema'
import { eq, and, desc } from 'drizzle-orm'

type Variables = {
  user: AuthContext
}

const favoriteRoutes = new Hono<{ Variables: Variables }>()

favoriteRoutes.post('/', authMiddleware, async (c) => {
  const { userId } = c.get('user') as AuthContext
  const body = await c.req.json()
  const quizId = body.quizId

  if (!quizId) {
    return c.json({ error: 'quizId is required' }, 400)
  }

  try {
    const [quiz] = await db
      .select()
      .from(quizzes)
      .where(and(eq(quizzes.id, quizId), eq(quizzes.isDeleted, false)))

    if (!quiz) {
      return c.json({ error: 'Quiz not found' }, 404)
    }

    const [existingFavorite] = await db
      .select()
      .from(favoriteQuizzes)
      .where(and(
        eq(favoriteQuizzes.userId, userId),
        eq(favoriteQuizzes.quizId, quizId)
      ))

    if (existingFavorite) {
      return c.json({ message: 'Quiz already favorited' }, 200)
    }

    const [newFavorite] = await db
      .insert(favoriteQuizzes)
      .values({
        userId,
        quizId,
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
    console.error('Error favoriting quiz:', error)
    return c.json({ error: 'Failed to favorite quiz' }, 500)
  }
})

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

    const [existingFavorite] = await db
      .select()
      .from(favoriteQuizzes)
      .where(and(
        eq(favoriteQuizzes.userId, userId),
        eq(favoriteQuizzes.quizId, quizId)
      ))

    if (existingFavorite) {
      return c.json({ message: 'Quiz already favorited' }, 200)
    }

    const [newFavorite] = await db
      .insert(favoriteQuizzes)
      .values({
        userId,
        quizId,
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
    console.error('Error favoriting quiz:', error)
    return c.json({ error: 'Failed to favorite quiz' }, 500)
  }
})

favoriteRoutes.delete('/:quizId', authMiddleware, async (c) => {
  const { userId } = c.get('user') as AuthContext
  const quizId = c.req.param('quizId')

  try {
    const [existingFavorite] = await db
      .select()
      .from(favoriteQuizzes)
      .where(and(
        eq(favoriteQuizzes.userId, userId),
        eq(favoriteQuizzes.quizId, quizId)
      ))

    if (!existingFavorite) {
      return c.json({ error: 'Quiz not favorited' }, 404)
    }

    await db
      .delete(favoriteQuizzes)
      .where(and(
        eq(favoriteQuizzes.userId, userId),
        eq(favoriteQuizzes.quizId, quizId)
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

    return c.json({ message: 'Favorite removed successfully' })
  } catch (error) {
    console.error('Error removing favorite:', error)
    return c.json({ error: 'Failed to remove favorite' }, 500)
  }
})

favoriteRoutes.get('/', authMiddleware, async (c) => {
  const { userId } = c.get('user') as AuthContext

  try {
    const favorites = await db
      .select({
        id: favoriteQuizzes.id,
        favoritedAt: favoriteQuizzes.favoritedAt,
        quiz: quizzes,
      })
      .from(favoriteQuizzes)
      .innerJoin(quizzes, eq(favoriteQuizzes.quizId, quizzes.id))
      .where(eq(favoriteQuizzes.userId, userId))
      .orderBy(desc(favoriteQuizzes.favoritedAt))

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
    const [existingFavorite] = await db
      .select()
      .from(favoriteQuizzes)
      .where(and(
        eq(favoriteQuizzes.userId, userId),
        eq(favoriteQuizzes.quizId, quizId)
      ))

    return c.json({ isFavorited: !!existingFavorite })
  } catch (error) {
    console.error('Error checking favorite status:', error)
    return c.json({ error: 'Failed to check favorite status' }, 500)
  }
})

export default favoriteRoutes

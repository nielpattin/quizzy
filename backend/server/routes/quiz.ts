import { Hono } from 'hono'
import { authMiddleware, type AuthContext } from '../middleware/auth'
import { db } from '../db/index'
import { quizzes, questions, users, categories } from '../db/schema'
import { eq, and, desc, sql } from 'drizzle-orm'
import { WebSocketService } from '../services/websocket-service'

type Variables = {
  user: AuthContext
}

const quizRoutes = new Hono<{ Variables: Variables }>()

quizRoutes.post('/', authMiddleware, async (c) => {
  const { userId } = c.get('user') as AuthContext
  const body = await c.req.json()

  try {
    if (!body.title) {
      return c.json({ error: 'Title is required' }, 400)
    }

    // Validate categoryId if provided
    if (body.categoryId) {
      const [category] = await db.select().from(categories).where(eq(categories.id, body.categoryId));
      if (!category) {
        return c.json({ error: 'Invalid category ID' }, 400)
      }
    }

    const [newQuiz] = await db
      .insert(quizzes)
      .values({
        userId,
        title: body.title,
        description: body.description || null,
        categoryId: body.categoryId || null,
        imageUrl: body.imageUrl || null,
        collectionId: body.collectionId || null,
        isPublic: body.isPublic !== undefined ? body.isPublic : true,
        questionsVisible: body.questionsVisible !== undefined ? body.questionsVisible : false,
      })
      .returning()

    return c.json(newQuiz, 201)
  } catch (error) {
    console.error('Error creating quiz:', error)
    return c.json({ error: 'Failed to create quiz' }, 500)
  }
})

quizRoutes.get('/featured', async (c) => {
  try {
    const sevenDaysAgo = new Date()
    sevenDaysAgo.setDate(sevenDaysAgo.getDate() - 7)

    const featuredQuizzes = await db
      .select({
        id: quizzes.id,
        title: quizzes.title,
        description: quizzes.description,
        category: {
          id: categories.id,
          name: categories.name,
          slug: categories.slug,
        },
        imageUrl: quizzes.imageUrl,
        questionCount: quizzes.questionCount,
        playCount: quizzes.playCount,
        favoriteCount: quizzes.favoriteCount,
        createdAt: quizzes.createdAt,
        user: {
          id: users.id,
          username: users.username,
          fullName: users.fullName,
          profilePictureUrl: users.profilePictureUrl,
        },
      })
      .from(quizzes)
      .leftJoin(users, eq(quizzes.userId, users.id))
      .leftJoin(categories, eq(quizzes.categoryId, categories.id))
      .where(and(
        eq(quizzes.isPublic, true),
        eq(quizzes.isDeleted, false),
        sql`${quizzes.questionCount} >= 5`,
        sql`${quizzes.createdAt} >= ${sevenDaysAgo.toISOString()}`
      ))
      .orderBy(
        desc(sql`(${quizzes.playCount} * 0.5 + ${quizzes.favoriteCount} * 0.3 + ${quizzes.questionCount} * 0.2)`)
      )
      .limit(10)

    return c.json(featuredQuizzes)
  } catch (error) {
    console.error('Error fetching featured quizzes:', error)
    return c.json({ error: 'Failed to fetch featured quizzes' }, 500)
  }
})

quizRoutes.get('/trending', async (c) => {
  try {
    const trendingQuizzes = await db
      .select({
        id: quizzes.id,
        title: quizzes.title,
        description: quizzes.description,
        category: {
          id: categories.id,
          name: categories.name,
          slug: categories.slug,
        },
        imageUrl: quizzes.imageUrl,
        questionCount: quizzes.questionCount,
        playCount: quizzes.playCount,
        favoriteCount: quizzes.favoriteCount,
        createdAt: quizzes.createdAt,
        user: {
          id: users.id,
          username: users.username,
          fullName: users.fullName,
          profilePictureUrl: users.profilePictureUrl,
        },
      })
      .from(quizzes)
      .leftJoin(users, eq(quizzes.userId, users.id))
      .leftJoin(categories, eq(quizzes.categoryId, categories.id))
      .where(and(eq(quizzes.isPublic, true), eq(quizzes.isDeleted, false)))
      .orderBy(desc(quizzes.playCount))
      .limit(20)

    return c.json(trendingQuizzes)
  } catch (error) {
    console.error('Error fetching trending quizzes:', error)
    return c.json({ error: 'Failed to fetch trending quizzes' }, 500)
  }
})

quizRoutes.get('/category/:category', async (c) => {
  const categorySlug = c.req.param('category')

  try {
    const categoryQuizzes = await db
      .select({
        id: quizzes.id,
        title: quizzes.title,
        description: quizzes.description,
        category: {
          id: categories.id,
          name: categories.name,
          slug: categories.slug,
        },
        imageUrl: quizzes.imageUrl,
        questionCount: quizzes.questionCount,
        playCount: quizzes.playCount,
        favoriteCount: quizzes.favoriteCount,
        createdAt: quizzes.createdAt,
        user: {
          id: users.id,
          username: users.username,
          fullName: users.fullName,
          profilePictureUrl: users.profilePictureUrl,
        },
      })
      .from(quizzes)
      .leftJoin(users, eq(quizzes.userId, users.id))
      .leftJoin(categories, eq(quizzes.categoryId, categories.id))
      .where(and(
        eq(categories.slug, categorySlug),
        eq(quizzes.isPublic, true),
        eq(quizzes.isDeleted, false)
      ))
      .orderBy(desc(quizzes.createdAt))
      .limit(20)

    return c.json(categoryQuizzes)
  } catch (error) {
    console.error('Error fetching category quizzes:', error)
    return c.json({ error: 'Failed to fetch category quizzes' }, 500)
  }
})

quizRoutes.get('/user/:userId', async (c) => {
  const targetUserId = c.req.param('userId')

  try {
    const userQuizzes = await db
      .select({
        id: quizzes.id,
        title: quizzes.title,
        description: quizzes.description,
        category: {
          id: categories.id,
          name: categories.name,
          slug: categories.slug,
        },
        imageUrl: quizzes.imageUrl,
        questionCount: quizzes.questionCount,
        playCount: quizzes.playCount,
        favoriteCount: quizzes.favoriteCount,
        isPublic: quizzes.isPublic,
        createdAt: quizzes.createdAt,
        updatedAt: quizzes.updatedAt,
      })
      .from(quizzes)
      .leftJoin(categories, eq(quizzes.categoryId, categories.id))
      .where(and(eq(quizzes.userId, targetUserId), eq(quizzes.isDeleted, false)))
      .orderBy(desc(quizzes.createdAt))

    return c.json(userQuizzes)
  } catch (error) {
    console.error('Error fetching user quizzes:', error)
    return c.json({ error: 'Failed to fetch user quizzes' }, 500)
  }
})

quizRoutes.get('/:id/questions', async (c) => {
  const quizId = c.req.param('id')

  try {
    const [quiz] = await db
      .select()
      .from(quizzes)
      .where(and(eq(quizzes.id, quizId), eq(quizzes.isDeleted, false)))

    if (!quiz) {
      return c.json({ error: 'Quiz not found' }, 404)
    }

    if (!quiz.questionsVisible && !quiz.isPublic) {
      return c.json({ error: 'Questions are not visible for this quiz' }, 403)
    }

    const quizQuestions = await db
      .select()
      .from(questions)
      .where(eq(questions.quizId, quizId))
      .orderBy(questions.orderIndex)

    return c.json(quizQuestions)
  } catch (error) {
    console.error('Error fetching questions:', error)
    return c.json({ error: 'Failed to fetch questions' }, 500)
  }
})

quizRoutes.get('/:id', async (c) => {
  const quizId = c.req.param('id')

  try {
    const [quiz] = await db
      .select({
        id: quizzes.id,
        title: quizzes.title,
        description: quizzes.description,
        category: {
          id: categories.id,
          name: categories.name,
          slug: categories.slug,
        },
        imageUrl: quizzes.imageUrl,
        questionCount: quizzes.questionCount,
        playCount: quizzes.playCount,
        favoriteCount: quizzes.favoriteCount,
        shareCount: quizzes.shareCount,
        isPublic: quizzes.isPublic,
        questionsVisible: quizzes.questionsVisible,
        version: quizzes.version,
        createdAt: quizzes.createdAt,
        updatedAt: quizzes.updatedAt,
        user: {
          id: users.id,
          username: users.username,
          fullName: users.fullName,
          profilePictureUrl: users.profilePictureUrl,
          followersCount: users.followersCount,
        },
      })
      .from(quizzes)
      .leftJoin(users, eq(quizzes.userId, users.id))
      .leftJoin(categories, eq(quizzes.categoryId, categories.id))
      .where(and(eq(quizzes.id, quizId), eq(quizzes.isDeleted, false)))

    if (!quiz) {
      return c.json({ error: 'Quiz not found' }, 404)
    }

    return c.json(quiz)
  } catch (error) {
    console.error('Error fetching quiz:', error)
    return c.json({ error: 'Failed to fetch quiz' }, 500)
  }
})

quizRoutes.put('/:id', authMiddleware, async (c) => {
  const { userId } = c.get('user') as AuthContext
  const quizId = c.req.param('id')
  const body = await c.req.json()

  try {
    const [existingQuiz] = await db
      .select()
      .from(quizzes)
      .where(and(eq(quizzes.id, quizId), eq(quizzes.isDeleted, false)))

    if (!existingQuiz) {
      return c.json({ error: 'Quiz not found' }, 404)
    }

    if (existingQuiz.userId !== userId) {
      return c.json({ error: 'Unauthorized' }, 403)
    }

    // Validate categoryId if provided
    if (body.categoryId) {
      const [category] = await db.select().from(categories).where(eq(categories.id, body.categoryId));
      if (!category) {
        return c.json({ error: 'Invalid category ID' }, 400)
      }
    }

    const [updatedQuiz] = await db
      .update(quizzes)
      .set({
        title: body.title,
        description: body.description,
        categoryId: body.categoryId,
        imageUrl: body.imageUrl,
        collectionId: body.collectionId,
        isPublic: body.isPublic,
        questionsVisible: body.questionsVisible,
        updatedAt: new Date(),
      })
      .where(eq(quizzes.id, quizId))
      .returning()

    return c.json(updatedQuiz)
  } catch (error) {
    console.error('Error updating quiz:', error)
    return c.json({ error: 'Failed to update quiz' }, 500)
  }
})

quizRoutes.delete('/:id', authMiddleware, async (c) => {
  const { userId } = c.get('user') as AuthContext
  const quizId = c.req.param('id')

  try {
    const [existingQuiz] = await db
      .select()
      .from(quizzes)
      .where(and(eq(quizzes.id, quizId), eq(quizzes.isDeleted, false)))

    if (!existingQuiz) {
      return c.json({ error: 'Quiz not found' }, 404)
    }

    if (existingQuiz.userId !== userId) {
      return c.json({ error: 'Unauthorized' }, 403)
    }

    await db
      .update(quizzes)
      .set({
        isDeleted: true,
        deletedAt: new Date(),
      })
      .where(eq(quizzes.id, quizId))

    return c.json({ message: 'Quiz deleted successfully' })
  } catch (error) {
    console.error('Error deleting quiz:', error)
    return c.json({ error: 'Failed to delete quiz' }, 500)
  }
})

quizRoutes.delete('/:id/questions', authMiddleware, async (c) => {
  const { userId } = c.get('user') as AuthContext
  const quizId = c.req.param('id')

  try {
    const [quiz] = await db
      .select()
      .from(quizzes)
      .where(and(eq(quizzes.id, quizId), eq(quizzes.isDeleted, false)))

    if (!quiz) {
      return c.json({ error: 'Quiz not found' }, 404)
    }

    if (quiz.userId !== userId) {
      return c.json({ error: 'Unauthorized' }, 403)
    }

    await db
      .delete(questions)
      .where(eq(questions.quizId, quizId))

    await db
      .update(quizzes)
      .set({
        questionCount: 0,
        updatedAt: new Date(),
      })
      .where(eq(quizzes.id, quizId))

    return c.json({ message: 'All questions deleted successfully' })
  } catch (error) {
    console.error('Error deleting all questions:', error)
    return c.json({ error: 'Failed to delete all questions' }, 500)
  }
})

export default quizRoutes

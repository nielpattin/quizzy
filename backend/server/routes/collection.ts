import { Hono } from 'hono'
import { authMiddleware } from '@/middleware/auth'
import type { AuthContext } from '@/middleware/auth'
import { db } from '@/db'
import { collections, quizzes, users } from '@/db/schema'
import { eq, and, desc } from 'drizzle-orm'

type Variables = {
  user: AuthContext
}

const collectionRoutes = new Hono<{ Variables: Variables }>()

collectionRoutes.post('/', authMiddleware, async (c) => {
  const { userId } = c.get('user') as AuthContext
  const body = await c.req.json()

  try {
    if (!body.title) {
      return c.json({ error: 'Title is required' }, 400)
    }

    const [newCollection] = await db
      .insert(collections)
      .values({
        userId,
        title: body.title,
        description: body.description || null,
        imageUrl: body.imageUrl || null,
        isPublic: body.isPublic !== undefined ? body.isPublic : true,
      })
      .returning()

    return c.json(newCollection, 201)
  } catch (error) {
    console.error('Error creating collection:', error)
    return c.json({ error: 'Failed to create collection' }, 500)
  }
})

collectionRoutes.get('/:id', async (c) => {
  const collectionId = c.req.param('id')

  try {
    const [collection] = await db
      .select({
        id: collections.id,
        title: collections.title,
        description: collections.description,
        imageUrl: collections.imageUrl,
        quizCount: collections.quizCount,
        isPublic: collections.isPublic,
        createdAt: collections.createdAt,
        updatedAt: collections.updatedAt,
        user: {
          id: users.id,
          username: users.username,
          fullName: users.fullName,
          profilePictureUrl: users.profilePictureUrl,
        },
      })
      .from(collections)
      .leftJoin(users, eq(collections.userId, users.id))
      .where(eq(collections.id, collectionId))

    if (!collection) {
      return c.json({ error: 'Collection not found' }, 404)
    }

    const collectionQuizzes = await db
      .select({
        id: quizzes.id,
        title: quizzes.title,
        description: quizzes.description,
        category: {
          id: categories.id,
          name: categories.name,
          slug: categories.slug,
        },
        questionCount: quizzes.questionCount,
        playCount: quizzes.playCount,
        favoriteCount: quizzes.favoriteCount,
        createdAt: quizzes.createdAt,
      })
      .from(quizzes)
      .leftJoin(categories, eq(quizzes.categoryId, categories.id))
      .where(and(eq(quizzes.collectionId, collectionId), eq(quizzes.isDeleted, false)))
      .orderBy(desc(quizzes.createdAt))

    return c.json({
      ...collection,
      quizzes: collectionQuizzes,
    })
  } catch (error) {
    console.error('Error fetching collection:', error)
    return c.json({ error: 'Failed to fetch collection' }, 500)
  }
})

collectionRoutes.put('/:id', authMiddleware, async (c) => {
  const { userId } = c.get('user') as AuthContext
  const collectionId = c.req.param('id')
  const body = await c.req.json()

  try {
    const [existingCollection] = await db
      .select()
      .from(collections)
      .where(eq(collections.id, collectionId))

    if (!existingCollection) {
      return c.json({ error: 'Collection not found' }, 404)
    }

    if (existingCollection.userId !== userId) {
      return c.json({ error: 'Unauthorized' }, 403)
    }

    const [updatedCollection] = await db
      .update(collections)
      .set({
        title: body.title,
        description: body.description,
        imageUrl: body.imageUrl,
        isPublic: body.isPublic,
        updatedAt: new Date(),
      })
      .where(eq(collections.id, collectionId))
      .returning()

    return c.json(updatedCollection)
  } catch (error) {
    console.error('Error updating collection:', error)
    return c.json({ error: 'Failed to update collection' }, 500)
  }
})

collectionRoutes.delete('/:id', authMiddleware, async (c) => {
  const { userId } = c.get('user') as AuthContext
  const collectionId = c.req.param('id')

  try {
    const [existingCollection] = await db
      .select()
      .from(collections)
      .where(eq(collections.id, collectionId))

    if (!existingCollection) {
      return c.json({ error: 'Collection not found' }, 404)
    }

    if (existingCollection.userId !== userId) {
      return c.json({ error: 'Unauthorized' }, 403)
    }

    await db
      .update(quizzes)
      .set({ collectionId: null })
      .where(eq(quizzes.collectionId, collectionId))

    await db
      .delete(collections)
      .where(eq(collections.id, collectionId))

    return c.json({ message: 'Collection deleted successfully' })
  } catch (error) {
    console.error('Error deleting collection:', error)
    return c.json({ error: 'Failed to delete collection' }, 500)
  }
})

collectionRoutes.post('/:id/add-quiz', authMiddleware, async (c) => {
  const { userId } = c.get('user') as AuthContext
  const collectionId = c.req.param('id')
  const body = await c.req.json()

  try {
    if (!body.quizId) {
      return c.json({ error: 'quizId is required' }, 400)
    }

    const [collection] = await db
      .select()
      .from(collections)
      .where(eq(collections.id, collectionId))

    if (!collection) {
      return c.json({ error: 'Collection not found' }, 404)
    }

    if (collection.userId !== userId) {
      return c.json({ error: 'Unauthorized' }, 403)
    }

    const [quiz] = await db
      .select()
      .from(quizzes)
      .where(and(eq(quizzes.id, body.quizId), eq(quizzes.isDeleted, false)))

    if (!quiz) {
      return c.json({ error: 'Quiz not found' }, 404)
    }

    if (quiz.userId !== userId) {
      return c.json({ error: 'Can only add your own quizzes to collections' }, 403)
    }

    await db
      .update(quizzes)
      .set({ collectionId })
      .where(eq(quizzes.id, body.quizId))

    await db
      .update(collections)
      .set({
        quizCount: collection.quizCount + 1,
        updatedAt: new Date(),
      })
      .where(eq(collections.id, collectionId))

    return c.json({ message: 'Quiz added to collection successfully' })
  } catch (error) {
    console.error('Error adding quiz to collection:', error)
    return c.json({ error: 'Failed to add quiz to collection' }, 500)
  }
})

collectionRoutes.delete('/:id/remove-quiz/:quizId', authMiddleware, async (c) => {
  const { userId } = c.get('user') as AuthContext
  const collectionId = c.req.param('id')
  const quizId = c.req.param('quizId')

  try {
    const [collection] = await db
      .select()
      .from(collections)
      .where(eq(collections.id, collectionId))

    if (!collection) {
      return c.json({ error: 'Collection not found' }, 404)
    }

    if (collection.userId !== userId) {
      return c.json({ error: 'Unauthorized' }, 403)
    }

    const [quiz] = await db
      .select()
      .from(quizzes)
      .where(and(eq(quizzes.id, quizId), eq(quizzes.collectionId, collectionId)))

    if (!quiz) {
      return c.json({ error: 'Quiz not found in this collection' }, 404)
    }

    await db
      .update(quizzes)
      .set({ collectionId: null })
      .where(eq(quizzes.id, quizId))

    await db
      .update(collections)
      .set({
        quizCount: Math.max(0, collection.quizCount - 1),
        updatedAt: new Date(),
      })
      .where(eq(collections.id, collectionId))

    return c.json({ message: 'Quiz removed from collection successfully' })
  } catch (error) {
    console.error('Error removing quiz from collection:', error)
    return c.json({ error: 'Failed to remove quiz from collection' }, 500)
  }
})

collectionRoutes.get('/user/:userId', async (c) => {
  const targetUserId = c.req.param('userId')

  try {
    const userCollections = await db
      .select({
        id: collections.id,
        title: collections.title,
        description: collections.description,
        imageUrl: collections.imageUrl,
        quizCount: collections.quizCount,
        isPublic: collections.isPublic,
        createdAt: collections.createdAt,
        updatedAt: collections.updatedAt,
      })
      .from(collections)
      .where(eq(collections.userId, targetUserId))
      .orderBy(desc(collections.createdAt))

    return c.json(userCollections)
  } catch (error) {
    console.error('Error fetching user collections:', error)
    return c.json({ error: 'Failed to fetch user collections' }, 500)
  }
})

export default collectionRoutes

import { Hono } from 'hono'
import { db } from '@/db'
import { quizzes, users, collections, posts, searchHistory } from '@/db/schema'
import { ilike, or, and, eq, desc } from 'drizzle-orm'
import { authMiddleware } from '@/middleware/auth'

const searchRoutes = new Hono()

searchRoutes.get('/quizzes', async (c) => {
  const query = c.req.query('q') || ''
  const category = c.req.query('category')
  const limit = parseInt(c.req.query('limit') || '20')
  const offset = parseInt(c.req.query('offset') || '0')

  if (!query.trim() && !category) {
    return c.json({ error: 'Search query or category is required' }, 400)
  }

  try {
    let conditions = [eq(quizzes.isDeleted, false), eq(quizzes.isPublic, true)]

    if (query.trim()) {
      conditions.push(
        or(
          ilike(quizzes.title, `%${query}%`),
          ilike(quizzes.description, `%${query}%`)
        ) as any
      )
    }

    if (category) {
      conditions.push(eq(quizzes.category, category))
    }

    const results = await db
      .select({
        id: quizzes.id,
        title: quizzes.title,
        description: quizzes.description,
        category: quizzes.category,
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
      .where(and(...conditions))
      .orderBy(desc(quizzes.playCount))
      .limit(limit)
      .offset(offset)

    return c.json(results)
  } catch (error) {
    console.error('Error searching quizzes:', error)
    return c.json({ error: 'Failed to search quizzes' }, 500)
  }
})

searchRoutes.get('/users', async (c) => {
  const query = c.req.query('q') || ''
  const limit = parseInt(c.req.query('limit') || '20')
  const offset = parseInt(c.req.query('offset') || '0')

  if (!query.trim()) {
    return c.json({ error: 'Search query is required' }, 400)
  }

  try {
    const results = await db
      .select({
        id: users.id,
        username: users.username,
        fullName: users.fullName,
        bio: users.bio,
        profilePictureUrl: users.profilePictureUrl,
        followersCount: users.followersCount,
        followingCount: users.followingCount,
        accountType: users.accountType,
      })
      .from(users)
      .where(
        or(
          ilike(users.username, `%${query}%`),
          ilike(users.fullName, `%${query}%`)
        )
      )
      .orderBy(desc(users.followersCount))
      .limit(limit)
      .offset(offset)

    return c.json(results)
  } catch (error) {
    console.error('Error searching users:', error)
    return c.json({ error: 'Failed to search users' }, 500)
  }
})

searchRoutes.get('/collections', async (c) => {
  const query = c.req.query('q') || ''
  const limit = parseInt(c.req.query('limit') || '20')
  const offset = parseInt(c.req.query('offset') || '0')

  if (!query.trim()) {
    return c.json({ error: 'Search query is required' }, 400)
  }

  try {
    const results = await db
      .select({
        id: collections.id,
        title: collections.title,
        description: collections.description,
        imageUrl: collections.imageUrl,
        quizCount: collections.quizCount,
        isPublic: collections.isPublic,
        createdAt: collections.createdAt,
        user: {
          id: users.id,
          username: users.username,
          fullName: users.fullName,
          profilePictureUrl: users.profilePictureUrl,
        },
      })
      .from(collections)
      .leftJoin(users, eq(collections.userId, users.id))
      .where(
        and(
          eq(collections.isPublic, true),
          or(
            ilike(collections.title, `%${query}%`),
            ilike(collections.description, `%${query}%`)
          )
        )
      )
      .orderBy(desc(collections.quizCount))
      .limit(limit)
      .offset(offset)

    return c.json(results)
  } catch (error) {
    console.error('Error searching collections:', error)
    return c.json({ error: 'Failed to search collections' }, 500)
  }
})

searchRoutes.get('/posts', async (c) => {
  const query = c.req.query('q') || ''
  const limit = parseInt(c.req.query('limit') || '20')
  const offset = parseInt(c.req.query('offset') || '0')

  if (!query.trim()) {
    return c.json({ error: 'Search query is required' }, 400)
  }

  try {
    const results = await db
      .select({
        id: posts.id,
        text: posts.text,
        postType: posts.postType,
        imageUrl: posts.imageUrl,
        questionText: posts.questionText,
        likesCount: posts.likesCount,
        commentsCount: posts.commentsCount,
        createdAt: posts.createdAt,
        user: {
          id: users.id,
          username: users.username,
          fullName: users.fullName,
          profilePictureUrl: users.profilePictureUrl,
        },
      })
      .from(posts)
      .leftJoin(users, eq(posts.userId, users.id))
      .where(
        and(
          eq(posts.moderationStatus, 'approved'),
          or(
            ilike(posts.text, `%${query}%`),
            ilike(posts.questionText, `%${query}%`)
          )
        )
      )
      .orderBy(desc(posts.createdAt))
      .limit(limit)
      .offset(offset)

    return c.json(results)
  } catch (error) {
    console.error('Error searching posts:', error)
    return c.json({ error: 'Failed to search posts' }, 500)
  }
})

searchRoutes.get('/', async (c) => {
  const query = c.req.query('q') || ''
  const limit = parseInt(c.req.query('limit') || '10')

  if (!query.trim()) {
    return c.json({ error: 'Search query is required' }, 400)
  }

  try {
    const [quizResults, userResults, collectionResults, postResults] = await Promise.all([
      db
        .select({
          id: quizzes.id,
          title: quizzes.title,
          description: quizzes.description,
          category: quizzes.category,
          questionCount: quizzes.questionCount,
          playCount: quizzes.playCount,
          favoriteCount: quizzes.favoriteCount,
          createdAt: quizzes.createdAt,
        })
        .from(quizzes)
        .where(
          and(
            eq(quizzes.isDeleted, false),
            eq(quizzes.isPublic, true),
            or(
              ilike(quizzes.title, `%${query}%`),
              ilike(quizzes.description, `%${query}%`)
            )
          )
        )
        .orderBy(desc(quizzes.playCount))
        .limit(limit),
      db
        .select({
          id: users.id,
          username: users.username,
          fullName: users.fullName,
          bio: users.bio,
          profilePictureUrl: users.profilePictureUrl,
          followersCount: users.followersCount,
          followingCount: users.followingCount,
        })
        .from(users)
        .where(
          or(
            ilike(users.username, `%${query}%`),
            ilike(users.fullName, `%${query}%`)
          )
        )
        .orderBy(desc(users.followersCount))
        .limit(limit),
      db
        .select({
          id: collections.id,
          title: collections.title,
          description: collections.description,
          quizCount: collections.quizCount,
          createdAt: collections.createdAt,
        })
        .from(collections)
        .where(
          and(
            eq(collections.isPublic, true),
            or(
              ilike(collections.title, `%${query}%`),
              ilike(collections.description, `%${query}%`)
            )
          )
        )
        .orderBy(desc(collections.quizCount))
        .limit(limit),
      db
        .select({
          id: posts.id,
          text: posts.text,
          postType: posts.postType,
          likesCount: posts.likesCount,
          commentsCount: posts.commentsCount,
          createdAt: posts.createdAt,
        })
        .from(posts)
        .where(
          and(
            eq(posts.moderationStatus, 'approved'),
            or(
              ilike(posts.text, `%${query}%`),
              ilike(posts.questionText, `%${query}%`)
            )
          )
        )
        .orderBy(desc(posts.createdAt))
        .limit(limit),
    ])

    return c.json({
      quizzes: quizResults,
      users: userResults,
      collections: collectionResults,
      posts: postResults,
    })
  } catch (error) {
    console.error('Error searching:', error)
    return c.json({ error: 'Failed to search' }, 500)
  }
})

searchRoutes.post('/history', authMiddleware, async (c) => {
  const userId = c.get('userId')
  const { query, filterType } = await c.req.json()

  if (!query?.trim()) {
    return c.json({ error: 'Search query is required' }, 400)
  }

  try {
    const existing = await db
      .select()
      .from(searchHistory)
      .where(
        and(
          eq(searchHistory.userId, userId),
          eq(searchHistory.query, query.trim())
        )
      )
      .limit(1)

    if (existing.length > 0) {
      await db
        .delete(searchHistory)
        .where(eq(searchHistory.id, existing[0].id))
    }

    const [result] = await db
      .insert(searchHistory)
      .values({
        userId,
        query: query.trim(),
        filterType: filterType || null,
      })
      .returning()

    return c.json(result)
  } catch (error) {
    console.error('Error saving search history:', error)
    return c.json({ error: 'Failed to save search history' }, 500)
  }
})

searchRoutes.get('/history', authMiddleware, async (c) => {
  const userId = c.get('userId')
  const limit = parseInt(c.req.query('limit') || '10')

  try {
    const results = await db
      .select({
        id: searchHistory.id,
        query: searchHistory.query,
        filterType: searchHistory.filterType,
        createdAt: searchHistory.createdAt,
      })
      .from(searchHistory)
      .where(eq(searchHistory.userId, userId))
      .orderBy(desc(searchHistory.createdAt))
      .limit(limit)

    return c.json(results)
  } catch (error) {
    console.error('Error fetching search history:', error)
    return c.json({ error: 'Failed to fetch search history' }, 500)
  }
})

searchRoutes.delete('/history/:id', authMiddleware, async (c) => {
  const userId = c.get('userId')
  const historyId = c.req.param('id')

  try {
    const result = await db
      .delete(searchHistory)
      .where(
        and(
          eq(searchHistory.id, historyId),
          eq(searchHistory.userId, userId)
        )
      )
      .returning()

    if (result.length === 0) {
      return c.json({ error: 'Search history not found' }, 404)
    }

    return c.json({ message: 'Search history deleted successfully' })
  } catch (error) {
    console.error('Error deleting search history:', error)
    return c.json({ error: 'Failed to delete search history' }, 500)
  }
})

export default searchRoutes

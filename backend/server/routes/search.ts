import { Hono } from 'hono'
import { db } from '@/db'
import { quizzes, users } from '@/db/schema'
import { ilike, or, and, eq, desc } from 'drizzle-orm'

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

searchRoutes.get('/', async (c) => {
  const query = c.req.query('q') || ''
  const limit = parseInt(c.req.query('limit') || '10')

  if (!query.trim()) {
    return c.json({ error: 'Search query is required' }, 400)
  }

  try {
    const [quizResults, userResults] = await Promise.all([
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
    ])

    return c.json({
      quizzes: quizResults,
      users: userResults,
    })
  } catch (error) {
    console.error('Error searching:', error)
    return c.json({ error: 'Failed to search' }, 500)
  }
})

export default searchRoutes

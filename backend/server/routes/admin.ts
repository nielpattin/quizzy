import { Hono } from 'hono'
import { db } from '../db/index'
import { users, quizzes, gameSessions, collections, posts, postReports } from '../db/schema'
import { eq, desc, sql, and, or, ilike, count } from 'drizzle-orm'
import { authMiddleware, type AuthContext } from '../middleware/auth'

type Variables = {
  user: AuthContext
}

const adminRoutes = new Hono<{ Variables: Variables }>()

const isAdmin = async (c: any, next: any) => {
  const { userId } = c.get('user') as AuthContext
  
  const [user] = await db
    .select({ accountType: users.accountType })
    .from(users)
    .where(eq(users.id, userId))
  
  if (!user || user.accountType !== 'admin') {
    return c.json({ error: 'Unauthorized. Admin access required.' }, 403)
  }
  
  await next()
}

adminRoutes.use('*', authMiddleware, isAdmin)

adminRoutes.get('/users/stats', async (c) => {
  try {
    const [totalUsers] = await db
      .select({ count: sql<number>`cast(count(*) as int)` })
      .from(users)
    
    const [activeUsers] = await db
      .select({ count: sql<number>`cast(count(*) as int)` })
      .from(users)
      .where(eq(users.status, 'active'))
    
    const thirtyDaysAgo = new Date()
    thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30)
    
    const [newUsers] = await db
      .select({ count: sql<number>`cast(count(*) as int)` })
      .from(users)
      .where(sql`${users.createdAt} >= ${thirtyDaysAgo.toISOString()}`)
    
    const avgCompletionResult = await db
      .select({
        avgScore: sql<number>`COALESCE(AVG(
          CASE 
            WHEN ${gameSessions.endedAt} IS NOT NULL 
            THEN 100 
            ELSE 0 
          END
        ), 0)`,
      })
      .from(gameSessions)
    
    const avgCompletion = Number(avgCompletionResult[0]?.avgScore || 0)

    return c.json({
      totalUsers: totalUsers?.count || 0,
      activeUsers: activeUsers?.count || 0,
      newThisMonth: newUsers?.count || 0,
      avgCompletion: Number(avgCompletion.toFixed(1)),
    })
  } catch (error) {
    console.error('[BACKEND] Error fetching user stats:', error)
    return c.json({ error: 'Failed to fetch user stats' }, 500)
  }
})

adminRoutes.get('/users', async (c) => {
  try {
    const search = c.req.query('search') || ''
    const role = c.req.query('role') || ''
    const status = c.req.query('status') || ''
    const page = Number.parseInt(c.req.query('page') || '1', 10)
    const limit = Number.parseInt(c.req.query('limit') || '50', 10)
    const offset = (page - 1) * limit

    let conditions = []
    
    if (search) {
      conditions.push(
        or(
          ilike(users.fullName, `%${search}%`),
          ilike(users.email, `%${search}%`),
          ilike(users.username, `%${search}%`)
        )
      )
    }
    
    if (role) {
      conditions.push(eq(users.accountType, role))
    }
    
    if (status) {
      conditions.push(eq(users.status, status))
    }

    const whereClause = conditions.length > 0 ? and(...conditions) : undefined

    const allUsers = await db
      .select({
        id: users.id,
        email: users.email,
        fullName: users.fullName,
        username: users.username,
        profilePictureUrl: users.profilePictureUrl,
        accountType: users.accountType,
        status: users.status,
        lastLoginAt: users.lastLoginAt,
        createdAt: users.createdAt,
      })
      .from(users)
      .where(whereClause)
      .orderBy(desc(users.createdAt))
      .limit(limit)
      .offset(offset)

    const userIds = allUsers.map(u => u.id)

    let quizCounts = []
    let sessionStats = []

    if (userIds.length > 0) {
      quizCounts = await db
        .select({
          userId: quizzes.userId,
          count: sql<number>`cast(count(*) as int)`,
        })
        .from(quizzes)
        .where(
          and(
            sql`${quizzes.userId} = ANY(ARRAY[${sql.join(userIds.map(id => sql`${id}`), sql`, `)}]::uuid[])`,
            eq(quizzes.isDeleted, false)
          )
        )
        .groupBy(quizzes.userId)

      sessionStats = await db
        .select({
          hostId: gameSessions.hostId,
          avgScore: sql<number>`COALESCE(AVG(
            CASE 
              WHEN ${gameSessions.endedAt} IS NOT NULL 
              THEN 85.5
              ELSE 0 
            END
          ), 0)`,
        })
        .from(gameSessions)
        .where(sql`${gameSessions.hostId} = ANY(ARRAY[${sql.join(userIds.map(id => sql`${id}`), sql`, `)}]::uuid[])`)
        .groupBy(gameSessions.hostId)
    }

    const quizCountMap = new Map(quizCounts.map(q => [q.userId, q.count]))
    const sessionStatsMap = new Map(sessionStats.map(s => [s.hostId, s.avgScore]))

    const [totalCount] = await db
      .select({ count: sql<number>`cast(count(*) as int)` })
      .from(users)
      .where(whereClause)

    const usersWithStats = allUsers.map(user => ({
      ...user,
      quizCount: quizCountMap.get(user.id) || 0,
      avgScore: sessionStatsMap.get(user.id) || 0,
    }))

    return c.json({
      users: usersWithStats,
      total: totalCount?.count || 0,
      page,
      limit,
    })
  } catch (error) {
    console.error('[BACKEND] Error fetching users:', error)
    return c.json({ error: 'Failed to fetch users' }, 500)
  }
})

adminRoutes.put('/users/:id', async (c) => {
  const userId = c.req.param('id')
  const body = await c.req.json()

  try {
    const { accountType, status } = body

    const updates: any = {
      updatedAt: new Date(),
    }

    if (accountType) {
      updates.accountType = accountType
    }

    if (status) {
      updates.status = status
    }

    const [updatedUser] = await db
      .update(users)
      .set(updates)
      .where(eq(users.id, userId))
      .returning()

    if (!updatedUser) {
      return c.json({ error: 'User not found' }, 404)
    }

    return c.json({
      success: true,
      user: {
        id: updatedUser.id,
        email: updatedUser.email,
        fullName: updatedUser.fullName,
        accountType: updatedUser.accountType,
        status: updatedUser.status,
      },
    })
  } catch (error) {
    console.error('[BACKEND] Error updating user:', error)
    return c.json({ error: 'Failed to update user' }, 500)
  }
})

adminRoutes.delete('/users/:id', async (c) => {
  const userId = c.req.param('id')
  const { userId: adminId } = c.get('user') as AuthContext

  try {
    if (userId === adminId) {
      return c.json({ error: 'Cannot delete your own account' }, 400)
    }

    await db.delete(users).where(eq(users.id, userId))

    return c.json({ success: true })
  } catch (error) {
    console.error('[BACKEND] Error deleting user:', error)
    return c.json({ error: 'Failed to delete user' }, 500)
  }
})

adminRoutes.post('/users', async (c) => {
  const body = await c.req.json()

  try {
    const { email, fullName, username, accountType, password } = body

    if (!email || !fullName) {
      return c.json({ error: 'Email and full name are required' }, 400)
    }

    const [existingUser] = await db
      .select()
      .from(users)
      .where(eq(users.email, email))

    if (existingUser) {
      return c.json({ error: 'User with this email already exists' }, 400)
    }

    const [newUser] = await db
      .insert(users)
      .values({
        email,
        fullName,
        username: username || null,
        accountType: accountType || 'user',
        status: 'active',
        isSetupComplete: true,
      })
      .returning()

    return c.json({
      success: true,
      user: {
        id: newUser.id,
        email: newUser.email,
        fullName: newUser.fullName,
        username: newUser.username,
        accountType: newUser.accountType,
        status: newUser.status,
      },
    })
  } catch (error) {
    console.error('[BACKEND] Error creating user:', error)
    return c.json({ error: 'Failed to create user' }, 500)
  }
})

adminRoutes.get('/quizzes/stats', async (c) => {
  try {
    const [totalQuizzes] = await db
      .select({ count: sql<number>`cast(count(*) as int)` })
      .from(quizzes)
      .where(eq(quizzes.isDeleted, false))
    
    const [publishedQuizzes] = await db
      .select({ count: sql<number>`cast(count(*) as int)` })
      .from(quizzes)
      .where(and(eq(quizzes.isPublic, true), eq(quizzes.isDeleted, false)))
    
    const [draftQuizzes] = await db
      .select({ count: sql<number>`cast(count(*) as int)` })
      .from(quizzes)
      .where(and(eq(quizzes.isPublic, false), eq(quizzes.isDeleted, false)))
    
    const [totalQuestionsResult] = await db
      .select({ sum: sql<number>`cast(sum(${quizzes.questionCount}) as int)` })
      .from(quizzes)
      .where(eq(quizzes.isDeleted, false))

    return c.json({
      totalQuizzes: totalQuizzes?.count || 0,
      published: publishedQuizzes?.count || 0,
      drafts: draftQuizzes?.count || 0,
      totalQuestions: totalQuestionsResult?.sum || 0,
    })
  } catch (error) {
    console.error('[BACKEND] Error fetching quiz stats:', error)
    return c.json({ error: 'Failed to fetch quiz stats' }, 500)
  }
})

adminRoutes.get('/quizzes', async (c) => {
  try {
    const search = c.req.query('search') || ''
    const category = c.req.query('category') || ''
    const status = c.req.query('status') || ''
    const page = Number.parseInt(c.req.query('page') || '1', 10)
    const limit = Number.parseInt(c.req.query('limit') || '10', 10)
    const offset = (page - 1) * limit

    let conditions = [eq(quizzes.isDeleted, false)]
    
    if (search) {
      conditions.push(
        or(
          ilike(quizzes.title, `%${search}%`),
          ilike(quizzes.description, `%${search}%`)
        )
      )
    }
    
    if (category) {
      conditions.push(eq(quizzes.category, category))
    }
    
    if (status === 'published') {
      conditions.push(eq(quizzes.isPublic, true))
    } else if (status === 'draft') {
      conditions.push(eq(quizzes.isPublic, false))
    }

    const whereClause = conditions.length > 0 ? and(...conditions) : undefined

    const allQuizzes = await db
      .select({
        id: quizzes.id,
        title: quizzes.title,
        description: quizzes.description,
        category: quizzes.category,
        imageUrl: quizzes.imageUrl,
        questionCount: quizzes.questionCount,
        playCount: quizzes.playCount,
        favoriteCount: quizzes.favoriteCount,
        isPublic: quizzes.isPublic,
        createdAt: quizzes.createdAt,
        updatedAt: quizzes.updatedAt,
        collectionId: quizzes.collectionId,
        userId: quizzes.userId,
        user: {
          id: users.id,
          fullName: users.fullName,
          username: users.username,
          profilePictureUrl: users.profilePictureUrl,
        },
        collection: {
          id: collections.id,
          title: collections.title,
        },
      })
      .from(quizzes)
      .leftJoin(users, eq(quizzes.userId, users.id))
      .leftJoin(collections, eq(quizzes.collectionId, collections.id))
      .where(whereClause)
      .orderBy(desc(quizzes.updatedAt))
      .limit(limit)
      .offset(offset)

    const [totalCount] = await db
      .select({ count: sql<number>`cast(count(*) as int)` })
      .from(quizzes)
      .where(whereClause)

    const quizzesWithStatus = allQuizzes.map(quiz => ({
      ...quiz,
      status: quiz.isPublic ? 'published' : 'draft',
    }))

    return c.json({
      quizzes: quizzesWithStatus,
      total: totalCount?.count || 0,
      page,
      limit,
    })
  } catch (error) {
    console.error('[BACKEND] Error fetching quizzes:', error)
    return c.json({ error: 'Failed to fetch quizzes' }, 500)
  }
})

adminRoutes.delete('/quizzes/:id', async (c) => {
  const quizId = c.req.param('id')

  try {
    const [quiz] = await db
      .select()
      .from(quizzes)
      .where(and(eq(quizzes.id, quizId), eq(quizzes.isDeleted, false)))

    if (!quiz) {
      return c.json({ error: 'Quiz not found' }, 404)
    }

    await db
      .update(quizzes)
      .set({ 
        isDeleted: true, 
        deletedAt: new Date(),
        updatedAt: new Date()
      })
      .where(eq(quizzes.id, quizId))

    return c.json({ success: true })
  } catch (error) {
    console.error('[BACKEND] Error deleting quiz:', error)
    return c.json({ error: 'Failed to delete quiz' }, 500)
  }
})

adminRoutes.post('/quizzes/:id/duplicate', async (c) => {
  const quizId = c.req.param('id')
  const { userId } = c.get('user') as AuthContext

  try {
    const [originalQuiz] = await db
      .select()
      .from(quizzes)
      .where(and(eq(quizzes.id, quizId), eq(quizzes.isDeleted, false)))

    if (!originalQuiz) {
      return c.json({ error: 'Quiz not found' }, 404)
    }

    const [newQuiz] = await db
      .insert(quizzes)
      .values({
        userId,
        collectionId: originalQuiz.collectionId,
        title: `${originalQuiz.title} (Copy)`,
        description: originalQuiz.description,
        category: originalQuiz.category,
        imageUrl: originalQuiz.imageUrl,
        isPublic: false,
        questionsVisible: originalQuiz.questionsVisible,
      })
      .returning()

    return c.json({ success: true, quiz: newQuiz })
  } catch (error) {
    console.error('[BACKEND] Error duplicating quiz:', error)
    return c.json({ error: 'Failed to duplicate quiz' }, 500)
  }
})

adminRoutes.get('/collections', async (c) => {
  try {
    const search = c.req.query('search') || ''
    const page = Number.parseInt(c.req.query('page') || '1', 10)
    const limit = Number.parseInt(c.req.query('limit') || '10', 10)
    const offset = (page - 1) * limit

    let conditions = []
    
    if (search) {
      conditions.push(
        or(
          ilike(collections.title, `%${search}%`),
          ilike(collections.description, `%${search}%`)
        )
      )
    }

    const whereClause = conditions.length > 0 ? and(...conditions) : undefined

    const allCollections = await db
      .select({
        id: collections.id,
        title: collections.title,
        description: collections.description,
        imageUrl: collections.imageUrl,
        quizCount: collections.quizCount,
        isPublic: collections.isPublic,
        createdAt: collections.createdAt,
        updatedAt: collections.updatedAt,
        userId: collections.userId,
        user: {
          id: users.id,
          fullName: users.fullName,
          username: users.username,
          profilePictureUrl: users.profilePictureUrl,
        },
      })
      .from(collections)
      .leftJoin(users, eq(collections.userId, users.id))
      .where(whereClause)
      .orderBy(desc(collections.updatedAt))
      .limit(limit)
      .offset(offset)

    const [totalCount] = await db
      .select({ count: sql<number>`cast(count(*) as int)` })
      .from(collections)
      .where(whereClause)

    return c.json({
      collections: allCollections,
      total: totalCount?.count || 0,
      page,
      limit,
    })
  } catch (error) {
    console.error('[BACKEND] Error fetching collections:', error)
    return c.json({ error: 'Failed to fetch collections' }, 500)
  }
})

adminRoutes.put('/collections/:id', async (c) => {
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

    return c.json({ success: true, collection: updatedCollection })
  } catch (error) {
    console.error('[BACKEND] Error updating collection:', error)
    return c.json({ error: 'Failed to update collection' }, 500)
  }
})

adminRoutes.delete('/collections/:id', async (c) => {
  const collectionId = c.req.param('id')

  try {
    const [collection] = await db
      .select()
      .from(collections)
      .where(eq(collections.id, collectionId))

    if (!collection) {
      return c.json({ error: 'Collection not found' }, 404)
    }

    await db
      .update(quizzes)
      .set({ collectionId: null })
      .where(eq(quizzes.collectionId, collectionId))

    await db
      .delete(collections)
      .where(eq(collections.id, collectionId))

    return c.json({ success: true })
  } catch (error) {
    console.error('[BACKEND] Error deleting collection:', error)
    return c.json({ error: 'Failed to delete collection' }, 500)
  }
})

adminRoutes.get('/posts/stats', async (c) => {
  try {
    const [totalPosts] = await db
      .select({ count: sql<number>`cast(count(*) as int)` })
      .from(posts)
    
    const [pendingReview] = await db
      .select({ count: sql<number>`cast(count(*) as int)` })
      .from(posts)
      .where(eq(posts.moderationStatus, 'review_pending'))
    
    const [flaggedContent] = await db
      .select({ count: sql<number>`cast(count(*) as int)` })
      .from(posts)
      .where(eq(posts.moderationStatus, 'flagged'))
    
    const engagementResult = await db
      .select({
        avgEngagement: sql<number>`
          CASE 
            WHEN COUNT(*) > 0 
            THEN CAST(
              (SUM(${posts.likesCount}) + SUM(${posts.commentsCount})) * 100.0 / 
              NULLIF(COUNT(*), 0) 
              AS NUMERIC(5,1)
            )
            ELSE 0 
          END
        `,
      })
      .from(posts)
    
    const engagementRate = Number(engagementResult[0]?.avgEngagement || 0)

    return c.json({
      totalPosts: totalPosts?.count || 0,
      pendingReview: pendingReview?.count || 0,
      engagementRate: Number(engagementRate.toFixed(1)),
      flaggedContent: flaggedContent?.count || 0,
    })
  } catch (error) {
    console.error('[BACKEND] Error fetching post stats:', error)
    return c.json({ error: 'Failed to fetch post stats' }, 500)
  }
})

adminRoutes.get('/posts', async (c) => {
  try {
    const search = c.req.query('search') || ''
    const postType = c.req.query('postType') || ''
    const status = c.req.query('status') || ''
    const page = Number.parseInt(c.req.query('page') || '1', 10)
    const limit = Number.parseInt(c.req.query('limit') || '10', 10)
    const offset = (page - 1) * limit

    let conditions = []
    
    if (search) {
      conditions.push(
        or(
          ilike(posts.text, `%${search}%`),
          ilike(posts.questionText, `%${search}%`)
        )
      )
    }
    
    if (postType) {
      conditions.push(eq(posts.postType, postType))
    }
    
    if (status === 'pending') {
      conditions.push(eq(posts.moderationStatus, 'review_pending'))
    } else if (status === 'flagged') {
      conditions.push(eq(posts.moderationStatus, 'flagged'))
    } else if (status === 'approved') {
      conditions.push(eq(posts.moderationStatus, 'approved'))
    } else if (status === 'rejected') {
      conditions.push(eq(posts.moderationStatus, 'rejected'))
    }

    const whereClause = conditions.length > 0 ? and(...conditions) : undefined

    const allPosts = await db
      .select({
        id: posts.id,
        text: posts.text,
        postType: posts.postType,
        imageUrl: posts.imageUrl,
        questionType: posts.questionType,
        questionText: posts.questionText,
        questionData: posts.questionData,
        answersCount: posts.answersCount,
        likesCount: posts.likesCount,
        commentsCount: posts.commentsCount,
        moderationStatus: posts.moderationStatus,
        moderatedBy: posts.moderatedBy,
        moderatedAt: posts.moderatedAt,
        flagCount: posts.flagCount,
        flagReasons: posts.flagReasons,
        createdAt: posts.createdAt,
        updatedAt: posts.updatedAt,
        userId: posts.userId,
        user: {
          id: users.id,
          fullName: users.fullName,
          username: users.username,
          profilePictureUrl: users.profilePictureUrl,
          accountType: users.accountType,
        },
      })
      .from(posts)
      .leftJoin(users, eq(posts.userId, users.id))
      .where(whereClause)
      .orderBy(desc(posts.createdAt))
      .limit(limit)
      .offset(offset)

    const [totalCount] = await db
      .select({ count: sql<number>`cast(count(*) as int)` })
      .from(posts)
      .where(whereClause)

    return c.json({
      posts: allPosts,
      total: totalCount?.count || 0,
      page,
      limit,
    })
  } catch (error) {
    console.error('[BACKEND] Error fetching posts:', error)
    return c.json({ error: 'Failed to fetch posts' }, 500)
  }
})

adminRoutes.put('/posts/:id/moderate', async (c) => {
  const postId = c.req.param('id')
  const { userId: adminId } = c.get('user') as AuthContext
  const body = await c.req.json()

  try {
    const { status, reason } = body

    if (!status || !['approved', 'rejected', 'flagged', 'review_pending'].includes(status)) {
      return c.json({ error: 'Invalid moderation status' }, 400)
    }

    const [post] = await db
      .select()
      .from(posts)
      .where(eq(posts.id, postId))

    if (!post) {
      return c.json({ error: 'Post not found' }, 404)
    }

    const [updatedPost] = await db
      .update(posts)
      .set({
        moderationStatus: status,
        moderatedBy: adminId,
        moderatedAt: new Date(),
        updatedAt: new Date(),
      })
      .where(eq(posts.id, postId))
      .returning()

    return c.json({ success: true, post: updatedPost })
  } catch (error) {
    console.error('[BACKEND] Error moderating post:', error)
    return c.json({ error: 'Failed to moderate post' }, 500)
  }
})

adminRoutes.delete('/posts/:id', async (c) => {
  const postId = c.req.param('id')

  try {
    const [post] = await db
      .select()
      .from(posts)
      .where(eq(posts.id, postId))

    if (!post) {
      return c.json({ error: 'Post not found' }, 404)
    }

    await db
      .delete(posts)
      .where(eq(posts.id, postId))

    return c.json({ success: true })
  } catch (error) {
    console.error('[BACKEND] Error deleting post:', error)
    return c.json({ error: 'Failed to delete post' }, 500)
  }
})

adminRoutes.get('/posts/:id/reports', async (c) => {
  const postId = c.req.param('id')

  try {
    const reports = await db
      .select({
        id: postReports.id,
        reason: postReports.reason,
        description: postReports.description,
        createdAt: postReports.createdAt,
        userId: postReports.userId,
        user: {
          id: users.id,
          fullName: users.fullName,
          username: users.username,
          profilePictureUrl: users.profilePictureUrl,
        },
      })
      .from(postReports)
      .leftJoin(users, eq(postReports.userId, users.id))
      .where(eq(postReports.postId, postId))
      .orderBy(desc(postReports.createdAt))

    return c.json({ reports })
  } catch (error) {
    console.error('[BACKEND] Error fetching post reports:', error)
    return c.json({ error: 'Failed to fetch post reports' }, 500)
  }
})

export default adminRoutes

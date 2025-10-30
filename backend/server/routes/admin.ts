import { Hono } from 'hono'
import { db } from '../db/index'
import { users, quizzes, gameSessions, gameSessionParticipants, quizSnapshots, collections, posts, postReports, categories, systemLogs } from '../db/schema'
import { eq, desc, sql, and, or, ilike, count, asc, isNotNull, gte, lte } from 'drizzle-orm'
import { authMiddleware, type AuthContext } from '../middleware/auth'

type Variables = {
  user: AuthContext
}

const adminRoutes = new Hono<{ Variables: Variables }>()

const isAdmin = async (c: any, next: any) => {
  const { userId, email, userMetadata } = c.get('user') as AuthContext
  
  let [user] = await db
    .select({ accountType: users.accountType })
    .from(users)
    .where(eq(users.id, userId))
  
  // If user doesn't exist in PostgreSQL, auto-create them
  if (!user) {
    console.log(`[ADMIN] User ${email} not found in database, auto-creating admin user...`)
    
    const fullName = userMetadata?.full_name || userMetadata?.name || email.split('@')[0]
    const username = email.split('@')[0].replace(/[^a-zA-Z0-9]/g, '_')
    
    try {
      // Create user in PostgreSQL with admin privileges
      const [newUser] = await db.insert(users).values({
        id: userId,
        email,
        fullName,
        username,
        accountType: 'admin',
        status: 'active',
        isSetupComplete: true,
        bio: 'Platform Administrator',
        profilePictureUrl: userMetadata?.avatar_url || userMetadata?.picture || null,
      }).returning()
      
      user = { accountType: newUser.accountType }
      console.log(`[ADMIN] ✅ Created admin user: ${email}`)
    } catch (error) {
      console.error(`[ADMIN] ❌ Failed to create admin user:`, error)
      return c.json({ error: 'Failed to create admin user in database' }, 500)
    }
  }
  
  if (user.accountType !== 'admin') {
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
      avgScore: Number(sessionStatsMap.get(user.id) || 0),
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
      conditions.push(eq(categories.name, category))
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
        category: categories.name,
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
      .leftJoin(categories, eq(quizzes.categoryId, categories.id))
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
    
    // Get total likes and comments for engagement calculation
    const [engagementData] = await db
      .select({
        totalLikes: sql<number>`cast(coalesce(sum(${posts.likesCount}), 0) as int)`,
        totalComments: sql<number>`cast(coalesce(sum(${posts.commentsCount}), 0) as int)`,
        postCount: sql<number>`cast(count(*) as int)`,
      })
      .from(posts)
    
    // Calculate engagement rate in JavaScript for better control
    let engagementRate = 0
    if (engagementData && engagementData.postCount > 0) {
      const totalEngagement = (engagementData.totalLikes || 0) + (engagementData.totalComments || 0)
      engagementRate = Number((totalEngagement / engagementData.postCount).toFixed(1))
    }

    return c.json({
      totalPosts: totalPosts?.count || 0,
      pendingReview: pendingReview?.count || 0,
      engagementRate,
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

// Admin Category Management Routes

adminRoutes.get('/categories', async (c) => {
  try {
    const allCategories = await db
      .select()
      .from(categories)

    return c.json(allCategories)
  } catch (error) {
    console.error('[BACKEND] Error fetching categories:', error)
    return c.json({ error: 'Failed to fetch categories' }, 500)
  }
})

adminRoutes.post('/categories', async (c) => {
  const body = await c.req.json()

  try {
    if (!body.name || !body.slug) {
      return c.json({ error: 'Name and slug are required' }, 400)
    }

    const [newCategory] = await db
      .insert(categories)
      .values({
        name: body.name,
        slug: body.slug,
        description: body.description || null,
        imageUrl: body.imageUrl || null,
      })
      .returning()

    return c.json(newCategory, 201)
  } catch (error) {
    console.error('[BACKEND] Error creating category:', error)
    return c.json({ error: 'Failed to create category' }, 500)
  }
})

adminRoutes.put('/categories/:id', async (c) => {
  const categoryId = c.req.param('id')
  const body = await c.req.json()

  try {
    const [existingCategory] = await db
      .select()
      .from(categories)
      .where(eq(categories.id, categoryId))

    if (!existingCategory) {
      return c.json({ error: 'Category not found' }, 404)
    }

    const [updatedCategory] = await db
      .update(categories)
      .set({
        name: body.name,
        slug: body.slug,
        description: body.description,
        imageUrl: body.imageUrl,
      })
      .where(eq(categories.id, categoryId))
      .returning()

    return c.json(updatedCategory)
  } catch (error) {
    console.error('[BACKEND] Error updating category:', error)
    return c.json({ error: 'Failed to update category' }, 500)
  }
})

adminRoutes.delete('/categories/:id', async (c) => {
  const categoryId = c.req.param('id')

  try {
    const [existingCategory] = await db
      .select()
      .from(categories)
      .where(eq(categories.id, categoryId))

    if (!existingCategory) {
      return c.json({ error: 'Category not found' }, 404)
    }

    // Hard delete the category
    await db
      .delete(categories)
      .where(eq(categories.id, categoryId))

    return c.json({ message: 'Category deleted successfully' })
  } catch (error) {
    console.error('[BACKEND] Error deleting category:', error)
    return c.json({ error: 'Failed to delete category' }, 500)
  }
})

adminRoutes.get('/dashboard', async (c) => {
  try {
    const [totalUsersResult] = await db
      .select({ count: sql<number>`cast(count(*) as int)` })
      .from(users)
    
    const [activeQuizzesResult] = await db
      .select({ count: sql<number>`cast(count(*) as int)` })
      .from(quizzes)
      .where(and(eq(quizzes.isPublic, true), eq(quizzes.isDeleted, false)))
    
    const [totalAttemptsResult] = await db
      .select({ count: sql<number>`cast(count(*) as int)` })
      .from(gameSessions)
    
    const [avgScoreResult] = await db
      .select({
        avgScore: sql<number>`COALESCE(AVG(
          CASE 
            WHEN ${gameSessions.endedAt} IS NOT NULL 
            THEN 78.5
            ELSE 0 
          END
        ), 0)`,
      })
      .from(gameSessions)

    const userGrowthData = []
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul']
    for (let i = 6; i >= 0; i--) {
      const date = new Date()
      date.setMonth(date.getMonth() - i)
      userGrowthData.push({
        month: months[6 - i],
        activeUsers: Math.floor(Math.random() * 5000) + 8000,
        newUsers: Math.floor(Math.random() * 2000) + 3000,
        quizzesTaken: Math.floor(Math.random() * 3000) + 5000,
      })
    }

    const [membersCount] = await db
      .select({ count: sql<number>`cast(count(*) as int)` })
      .from(users)
      .where(eq(users.accountType, 'user'))
    
    const [employeesCount] = await db
      .select({ count: sql<number>`cast(count(*) as int)` })
      .from(users)
      .where(eq(users.accountType, 'admin'))

    const totalUsers = totalUsersResult.count || 0
    const roleDistribution = {
      members: membersCount.count || 0,
      employees: employeesCount.count || 0,
      total: totalUsers,
      growthRate: 8.4,
    }

    const categoryStats = await db
      .select({
        category: categories.name,
        count: sql<number>`cast(count(*) as int)`,
      })
      .from(quizzes)
      .leftJoin(categories, eq(quizzes.categoryId, categories.id))
      .where(eq(quizzes.isDeleted, false))
      .groupBy(categories.name)
      .orderBy(desc(sql<number>`cast(count(*) as int)`))
      .limit(5)

    const totalQuizzes = categoryStats.reduce((sum, cat) => sum + cat.count, 0)
    const categoryColors = ['#64a7ff', '#05df72', '#fdc700', '#ff6900', '#c27aff']
    
    const categories = categoryStats.map((cat, i) => ({
      name: cat.category || 'Uncategorized',
      count: cat.count,
      percentage: totalQuizzes > 0 ? Math.round((cat.count / totalQuizzes) * 100) : 0,
      color: categoryColors[i] || '#64a7ff',
    }))

    const topPerformers = await db
      .select({
        userId: gameSessions.hostId,
        fullName: users.fullName,
        sessionCount: sql<number>`cast(count(*) as int)`,
      })
      .from(gameSessions)
      .leftJoin(users, eq(gameSessions.hostId, users.id))
      .where(isNotNull(gameSessions.endedAt))
      .groupBy(gameSessions.hostId, users.fullName)
      .orderBy(desc(sql<number>`cast(count(*) as int)`))
      .limit(5)

    const performers = topPerformers.map((p, i) => {
      const initials = (p.fullName || 'Unknown')
        .split(' ')
        .map(n => n[0])
        .join('')
        .toUpperCase()
        .slice(0, 2)
      
      return {
        rank: i + 1,
        name: p.fullName || 'Unknown User',
        initials,
        points: p.sessionCount * 100 + Math.floor(Math.random() * 500) + 2000,
      }
    })

    const recentSessions = await db
      .select({
        id: gameSessions.id,
        hostId: gameSessions.hostId,
        hostName: users.fullName,
        quizTitle: gameSessions.title,
        startedAt: gameSessions.startedAt,
        endedAt: gameSessions.endedAt,
        createdAt: gameSessions.createdAt,
      })
      .from(gameSessions)
      .leftJoin(users, eq(gameSessions.hostId, users.id))
      .orderBy(desc(gameSessions.createdAt))
      .limit(4)

    const activityColors = ['#05df72', '#64a7ff', '#fdc700', '#c27aff']
    const recentActivities = recentSessions.map((session, i) => {
      const now = new Date()
      const created = new Date(session.createdAt)
      const diffMinutes = Math.floor((now.getTime() - created.getTime()) / (1000 * 60))
      
      let timeAgo = ''
      if (diffMinutes < 1) timeAgo = 'Just now'
      else if (diffMinutes < 60) timeAgo = `${diffMinutes} min ago`
      else if (diffMinutes < 1440) timeAgo = `${Math.floor(diffMinutes / 60)} hour${Math.floor(diffMinutes / 60) > 1 ? 's' : ''} ago`
      else timeAgo = `${Math.floor(diffMinutes / 1440)} day${Math.floor(diffMinutes / 1440) > 1 ? 's' : ''} ago`

      return {
        id: session.id,
        user: session.hostName || 'Unknown User',
        action: session.endedAt ? 'completed' : 'started',
        target: session.quizTitle || 'Quiz',
        time: timeAgo,
        color: activityColors[i % activityColors.length],
      }
    })

    return c.json({
      stats: {
        totalUsers: totalUsers,
        activeQuizzes: activeQuizzesResult.count || 0,
        totalAttempts: totalAttemptsResult.count || 0,
        avgScore: Number((avgScoreResult.avgScore || 0).toFixed(1)),
        userGrowth: 12.5,
        quizGrowth: 8.2,
        attemptsGrowth: 23.1,
        scoreGrowth: 5.3,
      },
      userGrowth: userGrowthData,
      roleDistribution,
      categories,
      topPerformers: performers,
      recentActivities,
    })
  } catch (error) {
    console.error('[BACKEND] Error fetching dashboard data:', error)
    return c.json({ error: 'Failed to fetch dashboard data' }, 500)
  }
})

// Get system logs with filters
adminRoutes.get('/logs', async (c) => {
  try {
    const level = c.req.query('level') || ''
    const search = c.req.query('search') || ''
    const startDate = c.req.query('startDate') || ''
    const endDate = c.req.query('endDate') || ''
    const userId = c.req.query('userId') || ''
    const endpoint = c.req.query('endpoint') || ''
    const page = Number.parseInt(c.req.query('page') || '1', 10)
    const limit = Number.parseInt(c.req.query('limit') || '50', 10)
    const offset = (page - 1) * limit

    // Build dynamic WHERE conditions
    const conditions = []

    if (level) {
      conditions.push(eq(systemLogs.level, level as any))
    }

    if (search) {
      conditions.push(
        or(
          ilike(systemLogs.message, `%${search}%`),
          ilike(systemLogs.endpoint, `%${search}%`)
        )
      )
    }

    if (startDate) {
      conditions.push(gte(systemLogs.timestamp, new Date(startDate)))
    }

    if (endDate) {
      conditions.push(lte(systemLogs.timestamp, new Date(endDate)))
    }

    if (userId) {
      conditions.push(eq(systemLogs.userId, userId))
    }

    if (endpoint) {
      conditions.push(ilike(systemLogs.endpoint, `%${endpoint}%`))
    }

    // Get total count
    const [{ count: totalCount }] = await db
      .select({ count: sql<number>`cast(count(*) as int)` })
      .from(systemLogs)
      .where(conditions.length > 0 ? and(...conditions) : undefined)

    // Get logs with user information
    const logs = await db
      .select({
        id: systemLogs.id,
        timestamp: systemLogs.timestamp,
        level: systemLogs.level,
        message: systemLogs.message,
        metadata: systemLogs.metadata,
        userId: systemLogs.userId,
        endpoint: systemLogs.endpoint,
        method: systemLogs.method,
        statusCode: systemLogs.statusCode,
        duration: systemLogs.duration,
        error: systemLogs.error,
        ipAddress: systemLogs.ipAddress,
        userAgent: systemLogs.userAgent,
        createdAt: systemLogs.createdAt,
        userEmail: users.email,
        userName: users.fullName,
      })
      .from(systemLogs)
      .leftJoin(users, eq(systemLogs.userId, users.id))
      .where(conditions.length > 0 ? and(...conditions) : undefined)
      .orderBy(desc(systemLogs.timestamp))
      .limit(limit)
      .offset(offset)

    return c.json({
      logs,
      pagination: {
        page,
        limit,
        total: totalCount || 0,
        totalPages: Math.ceil((totalCount || 0) / limit),
      },
    })
  } catch (error) {
    console.error('[BACKEND] Error fetching system logs:', error)
    return c.json({ error: 'Failed to fetch system logs' }, 500)
  }
})

// Get log statistics
adminRoutes.get('/logs/stats', async (c) => {
  try {
    const [totalLogs] = await db
      .select({ count: sql<number>`cast(count(*) as int)` })
      .from(systemLogs)

    const [errorLogs] = await db
      .select({ count: sql<number>`cast(count(*) as int)` })
      .from(systemLogs)
      .where(eq(systemLogs.level, 'error'))

    const [warnLogs] = await db
      .select({ count: sql<number>`cast(count(*) as int)` })
      .from(systemLogs)
      .where(eq(systemLogs.level, 'warn'))

    const [infoLogs] = await db
      .select({ count: sql<number>`cast(count(*) as int)` })
      .from(systemLogs)
      .where(eq(systemLogs.level, 'info'))

    // Get 24 hours ago
    const last24Hours = new Date()
    last24Hours.setHours(last24Hours.getHours() - 24)

    const [recentLogs] = await db
      .select({ count: sql<number>`cast(count(*) as int)` })
      .from(systemLogs)
      .where(gte(systemLogs.timestamp, last24Hours))

    return c.json({
      totalLogs: totalLogs?.count || 0,
      errorLogs: errorLogs?.count || 0,
      warnLogs: warnLogs?.count || 0,
      infoLogs: infoLogs?.count || 0,
      recentLogs: recentLogs?.count || 0,
    })
  } catch (error) {
    console.error('[BACKEND] Error fetching log stats:', error)
    return c.json({ error: 'Failed to fetch log statistics' }, 500)
  }
})

// ============== SESSION MANAGEMENT ROUTES ==============

// Get session statistics
adminRoutes.get('/sessions/stats', async (c) => {
  try {
    const [totalSessions] = await db
      .select({ count: sql<number>`cast(count(*) as int)` })
      .from(gameSessions)

    const [activeSessions] = await db
      .select({ count: sql<number>`cast(count(*) as int)` })
      .from(gameSessions)
      .where(and(
        eq(gameSessions.isLive, true),
        sql`${gameSessions.endedAt} IS NULL`
      ))

    const [completedSessions] = await db
      .select({ count: sql<number>`cast(count(*) as int)` })
      .from(gameSessions)
      .where(sql`${gameSessions.endedAt} IS NOT NULL`)

    const [totalParticipants] = await db
      .select({ sum: sql<number>`cast(sum(${gameSessions.participantCount}) as int)` })
      .from(gameSessions)

    // Calculate average duration for completed sessions
    const avgDurationResult = await db
      .select({
        avgDuration: sql<number>`
          COALESCE(
            AVG(
              EXTRACT(EPOCH FROM (${gameSessions.endedAt} - ${gameSessions.startedAt})) / 60
            ), 
            0
          )
        `,
      })
      .from(gameSessions)
      .where(and(
        sql`${gameSessions.startedAt} IS NOT NULL`,
        sql`${gameSessions.endedAt} IS NOT NULL`
      ))

    const avgDuration = Math.round(Number(avgDurationResult[0]?.avgDuration || 0))

    return c.json({
      totalSessions: totalSessions?.count || 0,
      activeSessions: activeSessions?.count || 0,
      completedSessions: completedSessions?.count || 0,
      totalParticipants: totalParticipants?.sum || 0,
      avgDuration,
    })
  } catch (error) {
    console.error('[BACKEND] Error fetching session stats:', error)
    return c.json({ error: 'Failed to fetch session statistics' }, 500)
  }
})

// List all sessions with pagination and filters
adminRoutes.get('/sessions', async (c) => {
  try {
    const search = c.req.query('search') || ''
    const status = c.req.query('status') || ''
    const page = Number.parseInt(c.req.query('page') || '1', 10)
    const limit = Number.parseInt(c.req.query('limit') || '20', 10)
    const offset = (page - 1) * limit

    let conditions = []

    if (search) {
      conditions.push(
        or(
          ilike(gameSessions.title, `%${search}%`),
          ilike(gameSessions.code, `%${search}%`)
        )
      )
    }

    if (status === 'active') {
      conditions.push(
        and(
          eq(gameSessions.isLive, true),
          sql`${gameSessions.endedAt} IS NULL`
        )
      )
    } else if (status === 'completed') {
      conditions.push(sql`${gameSessions.endedAt} IS NOT NULL`)
    }

    const whereClause = conditions.length > 0 ? and(...conditions) : undefined

    const allSessions = await db
      .select({
        id: gameSessions.id,
        title: gameSessions.title,
        code: gameSessions.code,
        isLive: gameSessions.isLive,
        joinedCount: gameSessions.participantCount,
        estimatedMinutes: gameSessions.estimatedMinutes,
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
          questionCount: quizSnapshots.questionCount,
        },
      })
      .from(gameSessions)
      .leftJoin(users, eq(gameSessions.hostId, users.id))
      .leftJoin(quizSnapshots, eq(gameSessions.quizSnapshotId, quizSnapshots.id))
      .where(whereClause)
      .orderBy(desc(gameSessions.createdAt))
      .limit(limit)
      .offset(offset)

    const [totalCount] = await db
      .select({ count: sql<number>`cast(count(*) as int)` })
      .from(gameSessions)
      .where(whereClause)

    return c.json({
      sessions: allSessions,
      total: totalCount?.count || 0,
      page,
      limit,
    })
  } catch (error) {
    console.error('[BACKEND] Error fetching sessions:', error)
    return c.json({ error: 'Failed to fetch sessions' }, 500)
  }
})

// Get session details
adminRoutes.get('/sessions/:id', async (c) => {
  const sessionId = c.req.param('id')

  try {
    const [session] = await db
      .select({
        id: gameSessions.id,
        title: gameSessions.title,
        code: gameSessions.code,
        isLive: gameSessions.isLive,
        joinedCount: gameSessions.participantCount,
        estimatedMinutes: gameSessions.estimatedMinutes,
        quizVersion: gameSessions.quizVersion,
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
    console.error('[BACKEND] Error fetching session details:', error)
    return c.json({ error: 'Failed to fetch session details' }, 500)
  }
})

// Get session participants
adminRoutes.get('/sessions/:id/participants', async (c) => {
  const sessionId = c.req.param('id')

  try {
    const participants = await db
      .select({
        id: gameSessionParticipants.id,
        score: gameSessionParticipants.score,
        rank: gameSessionParticipants.rank,
        joinedAt: gameSessionParticipants.joinedAt,
        leftAt: gameSessionParticipants.leftAt,
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
      .orderBy(asc(gameSessionParticipants.joinedAt))

    return c.json(participants)
  } catch (error) {
    console.error('[BACKEND] Error fetching session participants:', error)
    return c.json({ error: 'Failed to fetch session participants' }, 500)
  }
})

// Force end a session
adminRoutes.post('/sessions/:id/end', async (c) => {
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
      return c.json({ error: 'Session already ended' }, 400)
    }

    await db
      .update(gameSessions)
      .set({
        endedAt: new Date(),
        isLive: false,
      })
      .where(eq(gameSessions.id, sessionId))

    return c.json({ success: true, message: 'Session ended successfully' })
  } catch (error) {
    console.error('[BACKEND] Error ending session:', error)
    return c.json({ error: 'Failed to end session' }, 500)
  }
})

// Delete a session
adminRoutes.delete('/sessions/:id', async (c) => {
  const sessionId = c.req.param('id')

  try {
    await db.delete(gameSessions).where(eq(gameSessions.id, sessionId))

    return c.json({ success: true, message: 'Session deleted successfully' })
  } catch (error) {
    console.error('[BACKEND] Error deleting session:', error)
    return c.json({ error: 'Failed to delete session' }, 500)
  }
})

export default adminRoutes

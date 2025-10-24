import { Hono } from 'hono'
import { db } from '../db/index'
import { users, quizzes, gameSessions } from '../db/schema'
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

export default adminRoutes

import { Hono } from 'hono'
import { db } from '../db/index'
import { users } from '../db/schema'
import { desc, sql } from 'drizzle-orm'
import { optionalAuthMiddleware, type AuthContext } from '../middleware/auth'

const leaderboardRoutes = new Hono()

// Get coin leaderboard
leaderboardRoutes.get('/coins', optionalAuthMiddleware, async (c) => {
  const authContext = c.get('user') as AuthContext | undefined
  const limit = Number(c.req.query('limit')) || 100
  
  try {
    const leaderboard = await db
      .select({
        rank: sql<number>`ROW_NUMBER() OVER (ORDER BY ${users.coins} DESC)`.mapWith(Number),
        userId: users.id,
        username: users.username,
        fullName: users.fullName,
        profilePictureUrl: users.profilePictureUrl,
        coins: users.coins,
        isCurrentUser: sql<boolean>`${users.id} = ${authContext?.userId || 'null'}`.mapWith(Boolean),
      })
      .from(users)
      .orderBy(desc(users.coins))
      .limit(limit)
    
    return c.json({ leaderboard })
  } catch (error) {
    console.error('[BACKEND] Error fetching leaderboard:', error)
    return c.json({ error: 'Failed to fetch leaderboard' }, 500)
  }
})

export default leaderboardRoutes

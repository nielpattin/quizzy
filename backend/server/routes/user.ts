import { Hono } from 'hono'
import { db } from '../db/index'
import { users, quizzes, gameSessions, posts, follows, categories, coinTransactions } from '../db/schema'
import { eq, and, desc, sql } from 'drizzle-orm'
import { authMiddleware, optionalAuthMiddleware, type AuthContext } from '../middleware/auth'

type Variables = {
  user: AuthContext
}

const userRoutes = new Hono<{ Variables: Variables }>()

// Update profile endpoint
userRoutes.put('/profile', authMiddleware, async (c) => {
  const { userId } = c.get('user') as AuthContext
  const body = await c.req.json()

  try {
    const { fullName, username, bio } = body

    // Validate required field
    if (!fullName || fullName.trim() === '') {
      return c.json({ error: 'Full name is required' }, 400)
    }

    // Check if username is already taken by another user
    if (username) {
      const [existingUser] = await db
        .select()
        .from(users)
        .where(eq(users.username, username))

      if (existingUser && existingUser.id !== userId) {
        return c.json({ error: 'Username is already taken' }, 400)
      }
    }

    const [updatedUser] = await db
      .update(users)
      .set({
        fullName: fullName.trim(),
        username: username?.trim() || null,
        bio: bio?.trim() || null,
        updatedAt: new Date(),
      })
      .where(eq(users.id, userId))
      .returning()

    return c.json({
      success: true,
      user: {
        id: updatedUser.id,
        fullName: updatedUser.fullName,
        username: updatedUser.username,
        bio: updatedUser.bio,
      }
    })
  } catch (error) {
    console.error('[BACKEND] Error updating profile:', error)
    return c.json({ error: 'Failed to update profile' }, 500)
  }
})

// Update profile picture endpoint
userRoutes.put('/profile/picture', authMiddleware, async (c) => {
  const { userId } = c.get('user') as AuthContext
  const body = await c.req.json()

  try {
    const { profilePictureUrl } = body

    if (!profilePictureUrl) {
      return c.json({ error: 'Profile picture URL is required' }, 400)
    }

    const [updatedUser] = await db
      .update(users)
      .set({
        profilePictureUrl,
        updatedAt: new Date(),
      })
      .where(eq(users.id, userId))
      .returning()

    return c.json({
      success: true,
      profilePictureUrl: updatedUser.profilePictureUrl
    })
  } catch (error) {
    console.error('[BACKEND] Error updating profile picture:', error)
    return c.json({ error: 'Failed to update profile picture' }, 500)
  }
})

// Get user profile by ID (public endpoint with optional auth)
userRoutes.get('/profile/:userId', optionalAuthMiddleware, async (c) => {
  const targetUserId = c.req.param('userId')
  const authContext = c.get('user') as AuthContext | undefined

  try {
    const [user] = await db
      .select({
        id: users.id,
        fullName: users.fullName,
        username: users.username,
        bio: users.bio,
        profilePictureUrl: users.profilePictureUrl,
        accountType: users.accountType,
        coins: users.coins,
        createdAt: users.createdAt,
      })
      .from(users)
      .where(eq(users.id, targetUserId))

    if (!user) {
      return c.json({ error: 'User not found' }, 404)
    }

    // Get follower/following counts
    const [followerCount] = await db
      .select({ count: sql<number>`cast(count(*) as int)` })
      .from(follows)
      .where(eq(follows.followingId, targetUserId))

    const [followingCount] = await db
      .select({ count: sql<number>`cast(count(*) as int)` })
      .from(follows)
      .where(eq(follows.followerId, targetUserId))

    // Check if current user follows this user
    let isFollowing = false
    if (authContext?.userId) {
      const [followRecord] = await db
        .select()
        .from(follows)
        .where(
          and(
            eq(follows.followerId, authContext.userId),
            eq(follows.followingId, targetUserId)
          )
        )
      isFollowing = !!followRecord
    }

    // Get user's public quizzes
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
        createdAt: quizzes.createdAt,
      })
      .from(quizzes)
      .leftJoin(categories, eq(quizzes.categoryId, categories.id))
      .where(
        and(
          eq(quizzes.userId, targetUserId),
          eq(quizzes.isPublic, true),
          eq(quizzes.isDeleted, false)
        )
      )
      .orderBy(desc(quizzes.createdAt))
      .limit(20)

    // Get user's game sessions
    const userSessions = await db
      .select({
        id: gameSessions.id,
        title: gameSessions.title,
        estimatedMinutes: gameSessions.estimatedMinutes,
        isLive: gameSessions.isLive,
        participantCount: gameSessions.participantCount,
        code: gameSessions.code,
        startedAt: gameSessions.startedAt,
        endedAt: gameSessions.endedAt,
        createdAt: gameSessions.createdAt,
      })
      .from(gameSessions)
      .where(eq(gameSessions.hostId, targetUserId))
      .orderBy(desc(gameSessions.createdAt))
      .limit(20)

    // Get user's posts
    const userPosts = await db
      .select({
        id: posts.id,
        text: posts.text,
        postType: posts.postType,
        imageUrl: posts.imageUrl,
        likesCount: posts.likesCount,
        commentsCount: posts.commentsCount,
        createdAt: posts.createdAt,
      })
      .from(posts)
      .where(eq(posts.userId, targetUserId))
      .orderBy(desc(posts.createdAt))
      .limit(20)

    return c.json({
      id: user.id,
      fullName: user.fullName,
      username: user.username,
      bio: user.bio,
      profilePictureUrl: user.profilePictureUrl,
      accountType: user.accountType,
      coins: user.coins,
      followersCount: followerCount?.count || 0,
      followingCount: followingCount?.count || 0,
      isFollowing,
      createdAt: user.createdAt,
      quizzes: userQuizzes,
      sessions: userSessions,
      posts: userPosts,
    })
  } catch (error) {
    console.error('[BACKEND] Error fetching user profile:', error)
    return c.json({ error: 'Failed to fetch user profile' }, 500)
  }
})

// Profile endpoint with auth (current user)
userRoutes.get('/profile', authMiddleware, async (c) => {
  const { userId, email, userMetadata } = c.get('user') as AuthContext

  try {
    let [user] = await db
      .select({
        id: users.id,
        email: users.email,
        fullName: users.fullName,
        username: users.username,
        dob: users.dob,
        bio: users.bio,
        profilePictureUrl: users.profilePictureUrl,
        accountType: users.accountType,
        isSetupComplete: users.isSetupComplete,
        coins: users.coins,
        createdAt: users.createdAt,
        updatedAt: users.updatedAt,
      })
      .from(users)
      .where(eq(users.id, userId))

    if (!user) {
      return c.json({ 
        error: 'User not found in database', 
        code: 'USER_NOT_FOUND' 
      }, 404)
    }

    // Get follower/following counts
    const [followerCount] = await db
      .select({ count: sql<number>`cast(count(*) as int)` })
      .from(follows)
      .where(eq(follows.followingId, userId))

    const [followingCount] = await db
      .select({ count: sql<number>`cast(count(*) as int)` })
      .from(follows)
      .where(eq(follows.followerId, userId))

    return c.json({
      id: user.id,
      email: user.email,
      fullName: user.fullName,
      username: user.username,
      dob: user.dob,
      bio: user.bio,
      profilePictureUrl: user.profilePictureUrl,
      accountType: user.accountType,
      isSetupComplete: user.isSetupComplete,
      coins: user.coins,
      followersCount: followerCount?.count || 0,
      followingCount: followingCount?.count || 0,
      createdAt: user.createdAt,
      updatedAt: user.updatedAt,
    })
  } catch (error) {
    console.error('[BACKEND] Error fetching user profile:', error)
    return c.json({ error: 'Failed to fetch user profile' }, 500)
  }
})

// Setup endpoint with auth
userRoutes.post('/setup', authMiddleware, async (c) => {
  const { userId, email, userMetadata } = c.get('user') as AuthContext
  const body = await c.req.json()

  try {
    const { username, fullName, dob, accountType } = body

    // Validate required fields
    if (!username || !fullName || !dob) {
      return c.json({ error: 'Missing required fields: username, fullName, dob' }, 400)
    }

    // Check if username is already taken
    const [existingUser] = await db
      .select()
      .from(users)
      .where(eq(users.username, username))

    if (existingUser && existingUser.id !== userId) {
      return c.json({ error: 'Username is already taken' }, 400)
    }

    // Check if user exists
    const [user] = await db
      .select()
      .from(users)
      .where(eq(users.id, userId))

    let updatedUser

    if (!user) {
      // Create new user with setup information
      const avatarUrl = userMetadata?.avatar_url || userMetadata?.picture || null
      
      const [newUser] = await db
        .insert(users)
        .values({
          id: userId,
          email: email,
          fullName: fullName,
          username: username,
          dob: dob,
          profilePictureUrl: avatarUrl,
          accountType: accountType || 'user',
          isSetupComplete: true,
        })
        .returning()
      
      updatedUser = newUser
    } else {
      // Update existing user with setup information
      const [updated] = await db
        .update(users)
        .set({
          username,
          fullName,
          dob: dob,
          accountType: accountType || user.accountType,
          isSetupComplete: true,
          updatedAt: new Date(),
        })
        .where(eq(users.id, userId))
        .returning()
      
      updatedUser = updated
    }

    return c.json({
      id: updatedUser.id,
      email: updatedUser.email,
      fullName: updatedUser.fullName,
      username: updatedUser.username,
      dob: updatedUser.dob,
      bio: updatedUser.bio,
      profilePictureUrl: updatedUser.profilePictureUrl,
      accountType: updatedUser.accountType,
      isSetupComplete: updatedUser.isSetupComplete,
      createdAt: updatedUser.createdAt,
      updatedAt: updatedUser.updatedAt,
    })
  } catch (error) {
    console.error('[BACKEND] Error completing user setup:', error)
    return c.json({ error: 'Failed to complete setup' }, 500)
  }
})

// Get user's quizzes
userRoutes.get('/quizzes', authMiddleware, async (c) => {
  const { userId } = c.get('user') as AuthContext

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
        shareCount: quizzes.shareCount,
        isPublic: quizzes.isPublic,
        createdAt: quizzes.createdAt,
      })
      .from(quizzes)
      .leftJoin(categories, eq(quizzes.categoryId, categories.id))
      .where(and(eq(quizzes.userId, userId), eq(quizzes.isDeleted, false)))
      .orderBy(desc(quizzes.createdAt))

    return c.json(userQuizzes)
  } catch (error) {
    console.error('[BACKEND] Error fetching user quizzes:', error)
    return c.json({ error: 'Failed to fetch quizzes' }, 500)
  }
})

// Get user's game sessions
userRoutes.get('/sessions', authMiddleware, async (c) => {
  const { userId } = c.get('user') as AuthContext

  try {
    const userSessions = await db
      .select({
        id: gameSessions.id,
        title: gameSessions.title,
        estimatedMinutes: gameSessions.estimatedMinutes,
        isLive: gameSessions.isLive,
        participantCount: gameSessions.participantCount,
        code: gameSessions.code,
        startedAt: gameSessions.startedAt,
        endedAt: gameSessions.endedAt,
        createdAt: gameSessions.createdAt,
      })
      .from(gameSessions)
      .where(eq(gameSessions.hostId, userId))
      .orderBy(desc(gameSessions.createdAt))

    return c.json(userSessions)
  } catch (error) {
    console.error('[BACKEND] Error fetching user sessions:', error)
    return c.json({ error: 'Failed to fetch sessions' }, 500)
  }
})

// Get user's posts
userRoutes.get('/posts', authMiddleware, async (c) => {
  const { userId } = c.get('user') as AuthContext

  try {
    const userPosts = await db
      .select({
        id: posts.id,
        text: posts.text,
        likesCount: posts.likesCount,
        commentsCount: posts.commentsCount,
        createdAt: posts.createdAt,
      })
      .from(posts)
      .where(eq(posts.userId, userId))
      .orderBy(desc(posts.createdAt))

    return c.json(userPosts)
  } catch (error) {
    console.error('[BACKEND] Error fetching user posts:', error)
    return c.json({ error: 'Failed to fetch posts' }, 500)
  }
})

// Get user coins endpoint
userRoutes.get('/coins', authMiddleware, async (c) => {
  const { userId } = c.get('user') as AuthContext
  
  try {
    const [user] = await db
      .select({ coins: users.coins })
      .from(users)
      .where(eq(users.id, userId))
    
    return c.json({ coins: user?.coins || 0 })
  } catch (error) {
    console.error('[BACKEND] Error fetching coins:', error)
    return c.json({ error: 'Failed to fetch coins' }, 500)
  }
})

// Get coin transaction history endpoint
userRoutes.get('/coins/transactions', authMiddleware, async (c) => {
  const { userId } = c.get('user') as AuthContext
  const limit = Number(c.req.query('limit')) || 50
  const offset = Number(c.req.query('offset')) || 0
  
  try {
    const transactions = await db
      .select()
      .from(coinTransactions)
      .where(eq(coinTransactions.userId, userId))
      .orderBy(desc(coinTransactions.createdAt))
      .limit(limit)
      .offset(offset)
    
    return c.json({ transactions })
  } catch (error) {
    console.error('[BACKEND] Error fetching transactions:', error)
    return c.json({ error: 'Failed to fetch transactions' }, 500)
  }
})

export default userRoutes
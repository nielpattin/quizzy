import { Hono } from 'hono'
import { authMiddleware } from '@/middleware/auth'
import type { AuthContext } from '@/middleware/auth'
import { db } from '@/db'
import { users } from '@/db/schema'
import { eq } from 'drizzle-orm'

type Variables = {
  user: AuthContext
}

const userRoutes = new Hono<{ Variables: Variables }>()

userRoutes.get('/profile', authMiddleware, async (c) => {
  const { userId, email, userMetadata } = c.get('user') as AuthContext

  try {
    let [user] = await db.select().from(users).where(eq(users.id, userId))

    if (!user) {
      const fullName = userMetadata?.full_name || userMetadata?.name || ''
      const avatarUrl = userMetadata?.avatar_url || userMetadata?.picture || null
      
      console.log(`[BACKEND] User ${userId} not found, creating new user with email ${email}`)
      console.log(`[BACKEND] OAuth metadata - fullName: "${fullName}", avatarUrl: "${avatarUrl}"`)
      
      const [newUser] = await db
        .insert(users)
        .values({
          id: userId,
          email: email,
          fullName: fullName,
          profilePictureUrl: avatarUrl,
          isSetupComplete: false,
        })
        .returning()
      
      user = newUser
      console.log(`[BACKEND] Created new user: ${userId}, isSetupComplete: ${user.isSetupComplete}`)
    }

    console.log(`[BACKEND] Returning user profile: ${userId}, isSetupComplete: ${user.isSetupComplete}`)

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
      createdAt: user.createdAt,
      updatedAt: user.updatedAt,
    })
  } catch (error) {
    console.error('[BACKEND] Error fetching user profile:', error)
    return c.json({ error: 'Failed to fetch user profile' }, 500)
  }
})

userRoutes.put('/profile', authMiddleware, async (c) => {
  const { userId } = c.get('user') as AuthContext
  const body = await c.req.json()

  try {
    const [updatedUser] = await db
      .update(users)
      .set({
        fullName: body.fullName,
        username: body.username,
        dob: body.dob,
        bio: body.bio,
        profilePictureUrl: body.profilePictureUrl,
        accountType: body.accountType,
        isSetupComplete: body.isSetupComplete,
        updatedAt: new Date(),
      })
      .where(eq(users.id, userId))
      .returning()

    if (!updatedUser) {
      return c.json({ error: 'User not found' }, 404)
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
    console.error('Error updating user profile:', error)
    return c.json({ error: 'Failed to update user profile' }, 500)
  }
})

userRoutes.post('/setup', authMiddleware, async (c) => {
  const { userId } = c.get('user') as AuthContext
  const body = await c.req.json()

  console.log(`[BACKEND] Setup request for user ${userId}:`, body)

  try {
    if (!body.username || !body.fullName || !body.dob) {
      console.log(`[BACKEND] Setup validation failed: missing fields`)
      return c.json({ error: 'Username, full name, and date of birth are required' }, 400)
    }

    const [existingUser] = await db
      .select()
      .from(users)
      .where(eq(users.username, body.username))

    if (existingUser && existingUser.id !== userId) {
      console.log(`[BACKEND] Setup failed: username ${body.username} already taken`)
      return c.json({ error: 'Username already taken' }, 409)
    }

    console.log(`[BACKEND] Updating user ${userId} with setup data`)
    const [updatedUser] = await db
      .update(users)
      .set({
        username: body.username,
        fullName: body.fullName,
        dob: body.dob,
        isSetupComplete: true,
        updatedAt: new Date(),
      })
      .where(eq(users.id, userId))
      .returning()

    if (!updatedUser) {
      console.log(`[BACKEND] Setup failed: user ${userId} not found`)
      return c.json({ error: 'User not found' }, 404)
    }

    console.log(`[BACKEND] Setup complete for user ${userId}, isSetupComplete: ${updatedUser.isSetupComplete}`)

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

export default userRoutes

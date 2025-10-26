import { Hono } from 'hono'
import { authMiddleware } from '@/middleware/auth'
import type { AuthContext } from '@/middleware/auth'
import { db } from '@/db'
import { follows, users } from '@/db/schema'
import { eq, and, desc } from 'drizzle-orm'
import { NotificationService } from '@/services/notification-service'

type Variables = {
  user: AuthContext
}

const followRoutes = new Hono<{ Variables: Variables }>()

followRoutes.post('/:userId', authMiddleware, async (c) => {
  const { userId: followerId } = c.get('user') as AuthContext
  const followingId = c.req.param('userId')

  try {
    if (followerId === followingId) {
      return c.json({ error: 'Cannot follow yourself' }, 400)
    }

    const [targetUser] = await db
      .select()
      .from(users)
      .where(eq(users.id, followingId))

    if (!targetUser) {
      return c.json({ error: 'User not found' }, 404)
    }

    const [existingFollow] = await db
      .select()
      .from(follows)
      .where(and(
        eq(follows.followerId, followerId),
        eq(follows.followingId, followingId)
      ))

    if (existingFollow) {
      return c.json({ message: 'Already following this user' }, 200)
    }

    const [newFollow] = await db
      .insert(follows)
      .values({
        followerId,
        followingId,
      })
      .returning()

    await db
      .update(users)
      .set({
        followersCount: targetUser.followersCount + 1,
      })
      .where(eq(users.id, followingId))

    const [follower] = await db
      .select()
      .from(users)
      .where(eq(users.id, followerId))

    if (follower) {
      await db
        .update(users)
        .set({
          followingCount: follower.followingCount + 1,
        })
        .where(eq(users.id, followerId))
    }

    // Create notification for new follow
    await NotificationService.createFollowNotification(followerId, followingId)

    return c.json(newFollow, 201)
  } catch (error) {
    console.error('Error following user:', error)
    return c.json({ error: 'Failed to follow user' }, 500)
  }
})

followRoutes.delete('/:userId', authMiddleware, async (c) => {
  const { userId: followerId } = c.get('user') as AuthContext
  const followingId = c.req.param('userId')

  try {
    const [existingFollow] = await db
      .select()
      .from(follows)
      .where(and(
        eq(follows.followerId, followerId),
        eq(follows.followingId, followingId)
      ))

    if (!existingFollow) {
      return c.json({ error: 'Not following this user' }, 404)
    }

    await db
      .delete(follows)
      .where(and(
        eq(follows.followerId, followerId),
        eq(follows.followingId, followingId)
      ))

    const [targetUser] = await db
      .select()
      .from(users)
      .where(eq(users.id, followingId))

    if (targetUser) {
      await db
        .update(users)
        .set({
          followersCount: Math.max(0, targetUser.followersCount - 1),
        })
        .where(eq(users.id, followingId))
    }

    const [follower] = await db
      .select()
      .from(users)
      .where(eq(users.id, followerId))

    if (follower) {
      await db
        .update(users)
        .set({
          followingCount: Math.max(0, follower.followingCount - 1),
        })
        .where(eq(users.id, followerId))
    }

    return c.json({ message: 'Unfollowed successfully' })
  } catch (error) {
    console.error('Error unfollowing user:', error)
    return c.json({ error: 'Failed to unfollow user' }, 500)
  }
})

followRoutes.get('/:userId/followers', async (c) => {
  const targetUserId = c.req.param('userId')

  try {
    const followers = await db
      .select({
        id: follows.id,
        createdAt: follows.createdAt,
        user: {
          id: users.id,
          username: users.username,
          fullName: users.fullName,
          profilePictureUrl: users.profilePictureUrl,
          bio: users.bio,
          followersCount: users.followersCount,
          followingCount: users.followingCount,
        },
      })
      .from(follows)
      .leftJoin(users, eq(follows.followerId, users.id))
      .where(eq(follows.followingId, targetUserId))
      .orderBy(desc(follows.createdAt))

    return c.json(followers)
  } catch (error) {
    console.error('Error fetching followers:', error)
    return c.json({ error: 'Failed to fetch followers' }, 500)
  }
})

followRoutes.get('/:userId/following', async (c) => {
  const targetUserId = c.req.param('userId')

  try {
    const following = await db
      .select({
        id: follows.id,
        createdAt: follows.createdAt,
        user: {
          id: users.id,
          username: users.username,
          fullName: users.fullName,
          profilePictureUrl: users.profilePictureUrl,
          bio: users.bio,
          followersCount: users.followersCount,
          followingCount: users.followingCount,
        },
      })
      .from(follows)
      .leftJoin(users, eq(follows.followingId, users.id))
      .where(eq(follows.followerId, targetUserId))
      .orderBy(desc(follows.createdAt))

    return c.json(following)
  } catch (error) {
    console.error('Error fetching following:', error)
    return c.json({ error: 'Failed to fetch following' }, 500)
  }
})

followRoutes.get('/check/:userId', authMiddleware, async (c) => {
  const { userId: followerId } = c.get('user') as AuthContext
  const followingId = c.req.param('userId')

  try {
    const [existingFollow] = await db
      .select()
      .from(follows)
      .where(and(
        eq(follows.followerId, followerId),
        eq(follows.followingId, followingId)
      ))

    return c.json({ isFollowing: !!existingFollow })
  } catch (error) {
    console.error('Error checking follow status:', error)
    return c.json({ error: 'Failed to check follow status' }, 500)
  }
})

export default followRoutes

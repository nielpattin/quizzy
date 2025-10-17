import { Hono } from 'hono'
import { authMiddleware } from '@/middleware/auth'
import type { AuthContext } from '@/middleware/auth'
import { db } from '@/db'
import { notifications, users, posts } from '@/db/schema'
import { eq, and, desc } from 'drizzle-orm'

type Variables = {
  user: AuthContext
}

const notificationRoutes = new Hono<{ Variables: Variables }>()

notificationRoutes.get('/', authMiddleware, async (c) => {
  const { userId } = c.get('user') as AuthContext
  const limit = parseInt(c.req.query('limit') || '50')
  const offset = parseInt(c.req.query('offset') || '0')
  const unreadOnly = c.req.query('unreadOnly') === 'true'

  try {
    const conditions = [eq(notifications.userId, userId)]

    if (unreadOnly) {
      conditions.push(eq(notifications.isUnread, true))
    }

    const userNotifications = await db
      .select({
        id: notifications.id,
        type: notifications.type,
        title: notifications.title,
        subtitle: notifications.subtitle,
        isUnread: notifications.isUnread,
        createdAt: notifications.createdAt,
        relatedUser: {
          id: users.id,
          username: users.username,
          fullName: users.fullName,
          profilePictureUrl: users.profilePictureUrl,
        },
        relatedPost: {
          id: posts.id,
          text: posts.text,
        },
      })
      .from(notifications)
      .leftJoin(users, eq(notifications.relatedUserId, users.id))
      .leftJoin(posts, eq(notifications.relatedPostId, posts.id))
      .where(and(...conditions))
      .orderBy(desc(notifications.createdAt))
      .limit(limit)
      .offset(offset)

    return c.json(userNotifications)
  } catch (error) {
    console.error('Error fetching notifications:', error)
    return c.json({ error: 'Failed to fetch notifications' }, 500)
  }
})

notificationRoutes.get('/unread-count', authMiddleware, async (c) => {
  const { userId } = c.get('user') as AuthContext

  try {
    const [result] = await db
      .select({ count: notifications.id })
      .from(notifications)
      .where(and(
        eq(notifications.userId, userId),
        eq(notifications.isUnread, true)
      ))

    return c.json({ count: result?.count || 0 })
  } catch (error) {
    console.error('Error fetching unread count:', error)
    return c.json({ error: 'Failed to fetch unread count' }, 500)
  }
})

notificationRoutes.put('/:id/read', authMiddleware, async (c) => {
  const { userId } = c.get('user') as AuthContext
  const notificationId = c.req.param('id')

  try {
    const [notification] = await db
      .select()
      .from(notifications)
      .where(eq(notifications.id, notificationId))

    if (!notification) {
      return c.json({ error: 'Notification not found' }, 404)
    }

    if (notification.userId !== userId) {
      return c.json({ error: 'Unauthorized' }, 403)
    }

    const [updatedNotification] = await db
      .update(notifications)
      .set({ isUnread: false })
      .where(eq(notifications.id, notificationId))
      .returning()

    return c.json(updatedNotification)
  } catch (error) {
    console.error('Error marking notification as read:', error)
    return c.json({ error: 'Failed to mark notification as read' }, 500)
  }
})

notificationRoutes.put('/read-all', authMiddleware, async (c) => {
  const { userId } = c.get('user') as AuthContext

  try {
    await db
      .update(notifications)
      .set({ isUnread: false })
      .where(and(
        eq(notifications.userId, userId),
        eq(notifications.isUnread, true)
      ))

    return c.json({ message: 'All notifications marked as read' })
  } catch (error) {
    console.error('Error marking all notifications as read:', error)
    return c.json({ error: 'Failed to mark all notifications as read' }, 500)
  }
})

notificationRoutes.delete('/:id', authMiddleware, async (c) => {
  const { userId } = c.get('user') as AuthContext
  const notificationId = c.req.param('id')

  try {
    const [notification] = await db
      .select()
      .from(notifications)
      .where(eq(notifications.id, notificationId))

    if (!notification) {
      return c.json({ error: 'Notification not found' }, 404)
    }

    if (notification.userId !== userId) {
      return c.json({ error: 'Unauthorized' }, 403)
    }

    await db
      .delete(notifications)
      .where(eq(notifications.id, notificationId))

    return c.json({ message: 'Notification deleted successfully' })
  } catch (error) {
    console.error('Error deleting notification:', error)
    return c.json({ error: 'Failed to delete notification' }, 500)
  }
})

notificationRoutes.post('/', authMiddleware, async (c) => {
  const { userId } = c.get('user') as AuthContext
  const body = await c.req.json()

  try {
    if (!body.type || !body.title || !body.targetUserId) {
      return c.json({ error: 'type, title, and targetUserId are required' }, 400)
    }

    const [newNotification] = await db
      .insert(notifications)
      .values({
        userId: body.targetUserId,
        type: body.type,
        title: body.title,
        subtitle: body.subtitle || null,
        relatedUserId: userId,
        relatedPostId: body.relatedPostId || null,
      })
      .returning()

    return c.json(newNotification, 201)
  } catch (error) {
    console.error('Error creating notification:', error)
    return c.json({ error: 'Failed to create notification' }, 500)
  }
})

export default notificationRoutes

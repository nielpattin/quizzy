import { Worker } from 'bullmq'
import { db } from '../db'
import { notifications, users } from '../db/schema'
import { eq } from 'drizzle-orm'
import { WebSocketService } from '../services/websocket-service'
import type { NotificationJobData } from '../services/notification-queue'

const connection = {
  host: process.env.REDIS_HOST || 'localhost',
  port: parseInt(process.env.REDIS_PORT || '6379'),
  password: process.env.REDIS_PASSWORD || undefined,
}

export const notificationWorker = new Worker<NotificationJobData>(
  'notifications',
  async (job) => {
    const startTime = Date.now()
    const { notificationId, userId, type } = job.data
    const shortJobId = notificationId.substring(0, 8)
    const shortUserId = userId.substring(0, 8)

    try {
      console.log(`[Worker] Processing job:${shortJobId} -> user:${shortUserId} | type:${type}`)

      const [notification] = await db
        .select()
        .from(notifications)
        .where(eq(notifications.id, notificationId))

      if (!notification) {
        console.error(`[Worker] Notification not found: ${shortJobId}`)
        return
      }

      const [user] = await db.select().from(users).where(eq(users.id, userId))

      if (!user) {
        console.error(`[Worker] User not found: ${shortUserId}`)
        return
      }

      // Fetch notification with related user details
      const notificationWithUser = await db
        .select({
          id: notifications.id,
          userId: notifications.userId,
          type: notifications.type,
          title: notifications.title,
          subtitle: notifications.subtitle,
          relatedUserId: notifications.relatedUserId,
          relatedPostId: notifications.relatedPostId,
          relatedQuizId: notifications.relatedQuizId,
          status: notifications.status,
          createdAt: notifications.createdAt,
          relatedUser: {
            id: users.id,
            username: users.username,
            fullName: users.fullName,
            profilePictureUrl: users.profilePictureUrl,
          }
        })
        .from(notifications)
        .leftJoin(users, eq(notifications.relatedUserId, users.id))
        .where(eq(notifications.id, notificationId))
      
      const fullNotification = notificationWithUser[0]

      // Log compact notification details
      const relatedUsername = fullNotification.relatedUser?.username || 'unknown'
      const shortRelatedId = fullNotification.relatedUserId?.substring(0, 8) || 'none'
      console.log(`[Worker] Loaded notification | title:"${fullNotification.title}" | from:${relatedUsername} (${shortRelatedId})`)

      const wasSent = await WebSocketService.broadcastToUser(userId, {
        type: 'notification',
        notification: fullNotification,
      })

      const elapsedMs = Date.now() - startTime

      if (wasSent) {
        // User was online, mark as delivered
        const sentAt = new Date()
        await db
          .update(notifications)
          .set({
            status: 'DELIVERED',
            deliveryChannel: 'websocket',
            sentAt,
          })
          .where(eq(notifications.id, notificationId))

        console.log(`[DB] Updated status -> DELIVERED | sentAt:${sentAt.toISOString()}`)
        console.log(`[Worker] Job:${shortJobId} completed | user:${shortUserId} | delivered:true | took:${elapsedMs}ms`)
      } else {
        // User was offline, mark as pending
        await db
          .update(notifications)
          .set({ status: 'PENDING' })
          .where(eq(notifications.id, notificationId))
        
        console.log(`[DB] Updated status -> PENDING | will retry later`)
        console.log(`[Worker] Job:${shortJobId} completed | user:${shortUserId} | delivered:false | pending | took:${elapsedMs}ms`)
      }
    } catch (error) {
      const elapsedMs = Date.now() - startTime
      console.error(`[Worker] Error processing job:${shortJobId} | took:${elapsedMs}ms |`, error)
      throw error
    }
  },
  {
    connection,
    concurrency: 10,
  }
)

notificationWorker.on('completed', (job) => {
  // Job completion is already logged in detail above, skip generic message
})

notificationWorker.on('failed', (job, err) => {
  const shortJobId = job?.id?.toString().substring(0, 8) || 'unknown'
  console.error(`[Worker] Job:${shortJobId} failed after retries |`, err.message)
})

const redisHost = process.env.REDIS_HOST || 'localhost'
const redisPort = process.env.REDIS_PORT || '6379'
console.log(`[Worker] Started | Concurrency: 10 | Redis: ${redisHost}:${redisPort}`)

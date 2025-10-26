import { Queue } from 'bullmq'

const connection = {
  host: process.env.REDIS_HOST || 'localhost',
  port: parseInt(process.env.REDIS_PORT || '6379'),
  password: process.env.REDIS_PASSWORD || undefined,
}

export const notificationQueue = new Queue('notifications', {
  connection,
  defaultJobOptions: {
    attempts: 3,
    backoff: {
      type: 'exponential',
      delay: 5000,
    },
    removeOnComplete: {
      count: 100,
      age: 3600,
    },
    removeOnFail: {
      count: 50,
    },
  },
})

export interface NotificationJobData {
  notificationId: string
  userId: string
  type: string
}

export async function enqueueNotification(data: NotificationJobData) {
  try {
    const priority = data.type === 'follow' ? 1 : 2
    await notificationQueue.add('send-notification', data, {
      priority,
    })
    const shortJobId = data.notificationId.substring(0, 8)
    console.log(`[Queue] Enqueued job:${shortJobId} | priority:${priority} | type:${data.type}`)
  } catch (error) {
    console.error('[Queue] Failed to enqueue notification:', error)
    throw error
  }
}

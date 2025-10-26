import { createBullBoard } from '@bull-board/api'
import { BullMQAdapter } from '@bull-board/api/bullMQAdapter'
import { HonoAdapter } from '@bull-board/hono'
import { notificationQueue } from '../services/notification-queue'
import { Hono } from 'hono'
import { serveStatic } from '@hono/node-server/serve-static'

// Create Bull Board server adapter with static file serving
const serverAdapter = new HonoAdapter(serveStatic)
serverAdapter.setBasePath('/admin/queues')

// Create Bull Board with notification queue
createBullBoard({
  queues: [new BullMQAdapter(notificationQueue)],
  serverAdapter,
})

// Create and export the Hono app with Bull Board routes
export const queueDashboard = new Hono()
queueDashboard.route('/', serverAdapter.registerPlugin())

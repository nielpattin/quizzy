import { Hono } from 'hono'
import { cors } from 'hono/cors'
import userRoutes from './routes/user'
import quizRoutes from './routes/quiz'
import socialRoutes from './routes/social'
import sessionRoutes from './routes/session'
import collectionRoutes from './routes/collection'
import favoriteRoutes from './routes/favorite'
import followRoutes from './routes/follow'
import notificationRoutes from './routes/notification'
import questionRoutes from './routes/question'
import searchRoutes from './routes/search'
import uploadRoutes from './routes/upload'
import adminRoutes from './routes/admin'
import authRoutes from './routes/auth'
import categoryRoutes from './routes/category'
import { queueDashboard } from './routes/queue-dashboard'
import { 
  authenticateWebSocket, 
  handleWebSocketMessage, 
  handleWebSocketClose, 
  handleWebSocketError,
  activeConnections
} from './websocket'
import { RedisConnectionStore } from './services/redis-connection-store'
import './services/notification-worker'

const app = new Hono()

app.use('/*', cors({
  origin: '*',
  allowMethods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
  allowHeaders: ['Content-Type', 'Authorization'],
}))

app.get('/', (c) => {
  return c.json({ 
    message: 'Quizzy API', 
    version: '1.0.0',
    status: 'running',
  })
})

// Mount all routes
app.route('/api/user', userRoutes)
app.route('/api/quiz', quizRoutes)
app.route('/api/social', socialRoutes)
app.route('/api/session', sessionRoutes)
app.route('/api/collection', collectionRoutes)
app.route('/api/favorite', favoriteRoutes)
app.route('/api/follow', followRoutes)
app.route('/api/notification', notificationRoutes)
app.route('/api/question', questionRoutes)
app.route('/api/search', searchRoutes)
app.route('/api/upload', uploadRoutes)
app.route('/api/admin', adminRoutes)
app.route('/api/auth', authRoutes)
app.route('/api/categories', categoryRoutes)

// Mount Bull Board queue dashboard
app.route('/admin/queues', queueDashboard)

const port = 8000
console.log(`[Server] Listening on port ${port}`)

export default {
  port,
  websocket: {
    async open(ws: any) {
      const context = ws.data
      if (context) {
        // Add to local Map for message sending
        activeConnections.set(ws, context)
        
        // Add to Redis for persistence across hot reloads
        await RedisConnectionStore.addConnection(context.userId, context.email)
        
        const shortUserId = context.userId.substring(0, 8)
        const totalConnections = activeConnections.size
        console.log(`[WS] Connection opened | user:${shortUserId} | email:${context.email} | total:${totalConnections}`)
        
        // Send connection confirmation to client
        ws.send(JSON.stringify({ 
          type: 'connected', 
          message: 'WebSocket connection established',
          userId: context.userId 
        }))
      }
    },
    async message(ws: any, message: string | Buffer) {
      const context = activeConnections.get(ws)
      if (context) {
        await handleWebSocketMessage(ws, message.toString(), context)
      }
    },
    async close(ws: any) {
      handleWebSocketClose(ws)
    },
    error(ws: any, error: Error) {
      handleWebSocketError(ws, error)
    },
  },
  async fetch(request: Request, server: any) {
    const url = new URL(request.url)
    
    // Handle WebSocket upgrade
    if (url.pathname === '/ws') {
      const hasToken = url.searchParams.has('token')
      const token = url.searchParams.get('token')
      const tokenPreview = token ? `${token.substring(0, 20)}...${token.substring(token.length - 10)}` : 'none'
      
      console.log(`[WS] Upgrade request | path:/ws | token:${hasToken ? tokenPreview : 'missing'}`)
      
      const context = await authenticateWebSocket(request)
      if (!context) {
        console.log('[WS] Upgrade failed | reason:unauthorized')
        return new Response('Unauthorized', { status: 401 })
      }
      
      const shortUserId = context.userId.substring(0, 8)
      console.log(`[WS] Upgrading connection | user:${shortUserId} | email:${context.email}`)
      
      if (server.upgrade(request, { data: context })) {
        return undefined
      }
      
      console.log('[WS] Upgrade call failed | reason:server_error')
      return new Response('WebSocket upgrade failed', { status: 400 })
    }
    
    // Handle regular HTTP requests with Hono
    return app.fetch(request, server)
  },
}
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
import { 
  authenticateWebSocket, 
  handleWebSocketMessage, 
  handleWebSocketClose, 
  handleWebSocketError,
  activeConnections
} from './websocket'

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

const port = 8000
console.log(`🚀 Quizzy API server running on http://localhost:${port}`)

export default {
  port,
  websocket: {
    async open(ws: any) {
      const context = ws.data
      if (context) {
        activeConnections.set(ws, context)
        console.log(`✅ WebSocket opened for user ${context.userId} (${context.email})`)
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
      const context = await authenticateWebSocket(request)
      if (!context) {
        console.log('❌ WebSocket upgrade failed: Unauthorized')
        return new Response('Unauthorized', { status: 401 })
      }
      
      console.log(`🔌 Upgrading WebSocket for user ${context.userId} (${context.email})`)
      
      if (server.upgrade(request, { data: context })) {
        return undefined
      }
      
      return new Response('WebSocket upgrade failed', { status: 400 })
    }
    
    // Handle regular HTTP requests with Hono
    return app.fetch(request, server)
  },
}
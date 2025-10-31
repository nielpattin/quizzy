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
import leaderboardRoutes from './routes/leaderboard'
import { queueDashboard } from './routes/queue-dashboard'
import { 
  authenticateWebSocket, 
  handleWebSocketMessage, 
  handleWebSocketClose, 
  handleWebSocketError,
  activeConnections
} from './websocket'
import { RedisConnectionStore } from './services/redis-connection-store'
import { loggingMiddleware, errorLoggingMiddleware } from './middleware/logging-middleware'
import { logger } from './lib/logger'
import './services/notification-worker'

const app = new Hono()

// Apply error logging middleware first (to catch all errors)
app.use('/*', errorLoggingMiddleware)

// Apply CORS
app.use('/*', cors({
  origin: '*',
  allowMethods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
  allowHeaders: ['Content-Type', 'Authorization'],
}))

// Apply HTTP request logging middleware
app.use('/*', loggingMiddleware)

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
app.route('/api/leaderboard', leaderboardRoutes)

// Mount Bull Board queue dashboard
app.route('/admin/queues', queueDashboard)

const port = 8000
logger.info({ port }, `Server starting on port ${port}`)

// Log active WebSocket connections on startup (check both Map and Redis)
const inMemoryCount = activeConnections.size
const redisUsers = await RedisConnectionStore.getOnlineUsers()
const redisCount = redisUsers.length

if (inMemoryCount > 0 || redisCount > 0) {
  const displayCount = Math.max(inMemoryCount, redisCount)
  const source = inMemoryCount > 0 ? 'in-memory' : 'Redis-persisted after hot reload'
  console.log(`[WS] Active connections: ${displayCount} user${displayCount === 1 ? '' : 's'} online (${source})`)
  
  // Show in-memory connections first (normal startup or before hot reload)
  if (inMemoryCount > 0) {
    const connections = Array.from(activeConnections.values())
    const maxDisplay = 5
    const toDisplay = connections.slice(0, maxDisplay)
    
    toDisplay.forEach((context, index) => {
      const shortUserId = context.userId.substring(0, 8)
      const isLast = index === toDisplay.length - 1 && connections.length <= maxDisplay
      const prefix = isLast ? '└─' : '├─'
      console.log(`[WS]   ${prefix} user:${shortUserId} | ${context.email}`)
    })
    
    if (connections.length > maxDisplay) {
      console.log(`[WS]   └─ and ${connections.length - maxDisplay} more...`)
    }
  }
  // Show Redis-persisted connections (after hot reload when Map is empty)
  else if (redisCount > 0) {
    const maxDisplay = 5
    const toDisplay = redisUsers.slice(0, maxDisplay)
    
    for (let i = 0; i < toDisplay.length; i++) {
      const userId = toDisplay[i]
      const metadata = await RedisConnectionStore.getConnection(userId)
      if (metadata) {
        const shortUserId = userId.substring(0, 8)
        const isLast = i === toDisplay.length - 1 && redisUsers.length <= maxDisplay
        const prefix = isLast ? '└─' : '├─'
        const duration = Math.floor((Date.now() - metadata.connectedAt) / 1000)
        console.log(`[WS]   ${prefix} user:${shortUserId} | ${metadata.email} | duration:${duration}s`)
      }
    }
    
    if (redisUsers.length > maxDisplay) {
      console.log(`[WS]   └─ and ${redisUsers.length - maxDisplay} more...`)
    }
  }
} else {
  console.log('[WS] No active connections')
}

// WebSocket heartbeat: ping clients every 25s and cleanup dead connections
setInterval(() => {
  activeConnections.forEach((context, ws) => {
    try {
      if (ws.readyState === 1) { // OPEN
        ws.send(JSON.stringify({ type: 'ping' }))
      } else {
        // Connection not open, trigger cleanup
        handleWebSocketClose(ws)
      }
    } catch (error) {
      // Failed to send, force close
      try { ws.close() } catch {}
    }
  })
}, 25000)

// Hot reload cleanup: log active connections before reload
if (import.meta.hot) {
  import.meta.hot.dispose(() => {
    const count = activeConnections.size
    if (count > 0) {
      console.log(`[WS] Hot reload triggered | ${count} connection${count === 1 ? '' : 's'} will be restored from Redis`)
    }
    // Note: We don't close connections here - they persist across hot reloads
    // Redis will maintain the state and they'll be shown in the startup log
  })
}

export default {
  port,
  websocket: {
    async open(ws: any) {
      const context = ws.data
      if (context) {
        // Add to local Map for message sending
        activeConnections.set(ws, context)
        
        // Check if this is a reconnect (user was recently online in Redis)
        const wasOnline = await RedisConnectionStore.isUserOnline(context.userId)
        
        // Add to Redis for persistence across hot reloads
        await RedisConnectionStore.addConnection(context.userId, context.email)
        
        // Subscribe to user's notification channel
        await RedisConnectionStore.subscribeToUser(context.userId, (message) => {
          // Forward Redis pub/sub message to WebSocket
          if (ws.readyState === 1) { // OPEN
            ws.send(JSON.stringify(message))
            const shortUserId = context.userId.substring(0, 8)
            console.log(`[WS] Forwarded Redis message -> user:${shortUserId} | type:${message.type}`)
          }
        })
        
        const shortUserId = context.userId.substring(0, 8)
        const totalConnections = activeConnections.size
        const status = wasOnline ? 'reconnected' : 'connected'
        console.log(`[WS] ${status} | user:${shortUserId} | email:${context.email} | total:${totalConnections}`)
        
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
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
  fetch: app.fetch,
}
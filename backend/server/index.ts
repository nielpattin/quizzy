import { Hono } from 'hono'
import { cors } from 'hono/cors'
import userRoutes from '@/routes/user'
import testRoutes from '@/routes/test'

const app = new Hono()

app.use('/*', cors({
  origin: '*',
  allowMethods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
  allowHeaders: ['Content-Type', 'Authorization'],
}))

app.get('/', (c) => {
  return c.json({ message: 'Quizzy API', version: '1.0.0' })
})

app.route('/api/user', userRoutes)
app.route('/api/test', testRoutes)

export default {
  port: 8000,
  fetch: app.fetch,
}

import { OpenAPIHono } from '@hono/zod-openapi'
import { cors } from 'hono/cors'
import { Scalar } from '@scalar/hono-api-reference'
import userRoutes from '@/routes/user'
import testRoutes from '@/routes/test'

const app = new OpenAPIHono()

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

app.doc('/doc', {
  openapi: '3.1.0',
  info: {
    title: 'Quizzy API',
    version: '1.0.0',
    description: 'API documentation for Quizzy - Quiz application with social features',
  },
  servers: [
    {
      url: 'http://localhost:8000',
      description: 'Development server',
    },
  ],
})

app.get('/scalar', Scalar({ url: '/doc', theme: 'purple', pageTitle: 'Quizzy API Documentation' }))

export default {
  port: 8000,
  fetch: app.fetch,
}

import { Context, Next } from 'hono'
import { RateLimiterRedis } from 'rate-limiter-flexible'
import Redis from 'ioredis'

const redis = new Redis({
  host: process.env.REDIS_HOST || 'localhost',
  port: parseInt(process.env.REDIS_PORT || '6379'),
  password: process.env.REDIS_PASSWORD || undefined,
})

// Rate limiter for like/unlike actions: 20 actions per minute per user
const likeLimiter = new RateLimiterRedis({
  storeClient: redis,
  keyPrefix: 'rate_limit:like',
  points: 20, // Number of actions allowed
  duration: 60, // Per 60 seconds
  blockDuration: 0, // Don't block, just reject
})

export const rateLimitLikes = async (c: Context, next: Next) => {
  const user = c.get('user') as { userId: string } | undefined
  
  if (!user) {
    return c.json({ error: 'Unauthorized' }, 401)
  }

  try {
    await likeLimiter.consume(user.userId, 1)
    await next()
  } catch (rejRes: any) {
    const retryAfter = Math.ceil(rejRes.msBeforeNext / 1000)
    return c.json(
      { 
        error: 'Too many requests. Please slow down.',
        retryAfter 
      }, 
      429
    )
  }
}

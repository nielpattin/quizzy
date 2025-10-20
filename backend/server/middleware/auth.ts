import type { Context, Next } from 'hono'
import { createClient } from '@supabase/supabase-js'
import type { User } from '@supabase/supabase-js'

export type AuthContext = {
  userId: string
  email: string
  userMetadata?: {
    full_name?: string
    avatar_url?: string
    name?: string
    picture?: string
  }
}

export const authMiddleware = async (c: Context, next: Next) => {
  const authHeader = c.req.header('Authorization')

  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return c.json({ error: 'Missing or invalid authorization header' }, 401)
  }

  const token = authHeader.replace('Bearer ', '')

  try {
    // Create Supabase client for server-side auth
    const supabase = createClient(
      process.env.SUPABASE_URL!,
      process.env.SUPABASE_ANON_KEY!
    )

    // Verify token using Supabase's built-in method
    const { data: { user }, error } = await supabase.auth.getUser(token)

    if (error || !user) {
      const errorMessage = error?.message || 'Invalid or expired token'
      const errorCode = error?.code || 'invalid_token'
      
      console.error('[BACKEND] Auth error:', {
        message: errorMessage,
        code: errorCode,
        status: error?.status
      })
      
      // Return 401 for expired or invalid tokens
      return c.json({ error: errorMessage, code: errorCode }, 401)
    }

    const context: AuthContext = {
      userId: user.id,
      email: user.email || '',
      userMetadata: user.user_metadata || {},
    }

    c.set('user', context)
    await next()
  } catch (error) {
    console.error('[BACKEND] Auth middleware error:', error)
    // Return 401 for any auth-related errors (like expired JWT)
    return c.json({ error: 'Authentication failed', details: error instanceof Error ? error.message : 'Unknown error' }, 401)
  }
}

export const optionalAuthMiddleware = async (c: Context, next: Next) => {
  const authHeader = c.req.header('Authorization')

  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    await next()
    return
  }

  const token = authHeader.replace('Bearer ', '')

  try {
    const supabase = createClient(
      process.env.SUPABASE_URL!,
      process.env.SUPABASE_ANON_KEY!
    )

    const { data: { user }, error } = await supabase.auth.getUser(token)

    if (!error && user) {
      const context: AuthContext = {
        userId: user.id,
        email: user.email || '',
        userMetadata: user.user_metadata || {},
      }

      c.set('user', context)
    }
  } catch (error) {
    console.error('[BACKEND] Optional auth middleware error:', error)
  }

  await next()
}
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
      console.error('[BACKEND] Auth error:', error)
      return c.json({ error: 'Invalid or expired token' }, 401)
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
    return c.json({ error: 'Authentication failed' }, 500)
  }
}
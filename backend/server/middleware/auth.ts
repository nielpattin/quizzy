import type { Context, Next } from 'hono'
import { supabase } from '@/lib/supabase'

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
    const { data, error } = await supabase.auth.getUser(token)

    if (error || !data.user) {
      return c.json({ error: 'Invalid or expired token' }, 401)
    }

    c.set('user', {
      userId: data.user.id,
      email: data.user.email!,
      userMetadata: data.user.user_metadata,
    } as AuthContext)

    await next()
  } catch (error) {
    console.error('Auth middleware error:', error)
    return c.json({ error: 'Authentication failed' }, 401)
  }
}

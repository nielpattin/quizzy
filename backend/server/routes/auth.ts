import { Hono } from 'hono'
import { db } from '../db/index'
import { users } from '../db/schema'
import { eq, sql } from 'drizzle-orm'
import { supabaseAdmin } from '../lib/supabase'

const authRoutes = new Hono()

authRoutes.get('/check-admin', async (c) => {
  try {
    const [adminExists] = await db
      .select({ count: sql<number>`cast(count(*) as int)` })
      .from(users)
      .where(eq(users.accountType, 'admin'))

    return c.json({
      hasAdmin: (adminExists?.count || 0) > 0,
    })
  } catch (error) {
    console.error('[BACKEND] Error checking admin existence:', error)
    return c.json({ error: 'Failed to check admin existence' }, 500)
  }
})

authRoutes.post('/create-first-admin', async (c) => {
  try {
    const body = await c.req.json()
    const { email, password, fullName } = body

    if (!email || !password || !fullName) {
      return c.json({ error: 'Email, password, and full name are required' }, 400)
    }

    const [existingAdmin] = await db
      .select({ count: sql<number>`cast(count(*) as int)` })
      .from(users)
      .where(eq(users.accountType, 'admin'))

    if ((existingAdmin?.count || 0) > 0) {
      return c.json({ error: 'Admin user already exists' }, 400)
    }

    if (!supabaseAdmin) {
      return c.json({ 
        error: 'Supabase admin client not configured. Please set SUPABASE_SERVICE_ROLE_KEY in .env' 
      }, 500)
    }

    const { data: authData, error: authError } = await supabaseAdmin.auth.admin.createUser({
      email,
      password,
      email_confirm: true,
      user_metadata: {
        role: 'admin',
        full_name: fullName,
      },
    })

    if (authError || !authData.user) {
      console.error('[BACKEND] Supabase user creation error:', authError)
      return c.json({ 
        error: authError?.message || 'Failed to create Supabase user' 
      }, 400)
    }

    const [newUser] = await db
      .insert(users)
      .values({
        id: authData.user.id,
        email: email,
        fullName: fullName,
        accountType: 'admin',
        status: 'active',
        isSetupComplete: true,
      })
      .returning()

    const { data: sessionData, error: sessionError } = await supabaseAdmin.auth.signInWithPassword({
      email,
      password,
    })

    if (sessionError || !sessionData.session) {
      console.error('[BACKEND] Auto-login error after admin creation:', sessionError)
      return c.json({
        success: true,
        message: 'Admin created successfully. Please log in.',
        user: {
          id: newUser.id,
          email: newUser.email,
          fullName: newUser.fullName,
        },
      })
    }

    return c.json({
      success: true,
      user: {
        id: newUser.id,
        email: newUser.email,
        fullName: newUser.fullName,
        accountType: newUser.accountType,
      },
      session: {
        access_token: sessionData.session.access_token,
        refresh_token: sessionData.session.refresh_token,
        expires_at: sessionData.session.expires_at,
      },
    })
  } catch (error) {
    console.error('[BACKEND] Error creating first admin:', error)
    return c.json({ error: 'Failed to create first admin' }, 500)
  }
})

export default authRoutes

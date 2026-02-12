// Edge Function: Business Authentication
// Handles business login with credential verification and lockout management

import { serve } from 'https://deno.land/std@0.224.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import { crypto } from 'https://deno.land/std@0.224.0/crypto/mod.ts'

const MAX_LOGIN_ATTEMPTS = 5
const LOCKOUT_DURATION_MINUTES = 15

function supabaseAdmin() {
  const url = Deno.env.get('SUPABASE_URL')!
  const serviceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
  return createClient(url, serviceKey, {
    auth: { persistSession: false },
    db: { schema: 'public' },
  })
}

async function hashPassword(password: string): Promise<string> {
  const encoder = new TextEncoder()
  const data = encoder.encode(password)
  const hashBuffer = await crypto.subtle.digest('SHA-256', data)
  const hashArray = Array.from(new Uint8Array(hashBuffer))
  const hashHex = hashArray.map(b => b.toString(16).padStart(2, '0')).join('')
  return hashHex
}

async function verifyBusinessCredentials(
  sb: ReturnType<typeof supabaseAdmin>,
  username: string,
  password: string
): Promise<{ success: boolean; businessId?: string; error?: string }> {
  try {
    // Get business credential
    const { data: credential, error: credentialError } = await sb
      .from('business_credentials')
      .select('id, business_id, password_hash, is_active, failed_login_attempts, locked_until')
      .eq('username', username)
      .single()

    if (credentialError || !credential) {
      return { success: false, error: 'Invalid username or password' }
    }

    // Check if account is active
    if (!credential.is_active) {
      return { success: false, error: 'Account is inactive' }
    }

    // Check if account is locked
    if (credential.locked_until) {
      const lockedUntil = new Date(credential.locked_until)
      if (lockedUntil > new Date()) {
        const remainingMinutes = Math.ceil((lockedUntil.getTime() - Date.now()) / 60000)
        return {
          success: false,
          error: 'Account is locked',
          // Note: lockoutRemaining will be set by caller
        }
      }
    }

    // Hash provided password
    const passwordHash = await hashPassword(password)

    // Verify password
    if (credential.password_hash !== passwordHash) {
      // Increment failed attempts
      const newAttempts = (credential.failed_login_attempts || 0) + 1
      const shouldLock = newAttempts >= MAX_LOGIN_ATTEMPTS

      await sb
        .from('business_credentials')
        .update({
          failed_login_attempts: newAttempts,
          locked_until: shouldLock
            ? new Date(Date.now() + LOCKOUT_DURATION_MINUTES * 60 * 1000).toISOString()
            : null,
        })
        .eq('id', credential.id)

      const remainingAttempts = MAX_LOGIN_ATTEMPTS - newAttempts

      if (shouldLock) {
        return {
          success: false,
          error: 'Too many failed attempts. Account locked.',
          // Note: lockedOut and lockoutRemaining will be set by caller
        }
      }

      return {
        success: false,
        error: 'Invalid username or password',
        // Note: remainingAttempts will be set by caller
      }
    }

    // Success - reset failed attempts and update last login
    await sb
      .from('business_credentials')
      .update({
        failed_login_attempts: 0,
        locked_until: null,
        last_login_at: new Date().toISOString(),
      })
      .eq('id', credential.id)

    // Create session record
    const expiresAt = new Date(Date.now() + 8 * 60 * 60 * 1000) // 8 hours
    await sb.from('business_sessions').insert({
      business_id: credential.business_id,
      username: username,
      expires_at: expiresAt.toISOString(),
      access_level: 'business',
    })

    return {
      success: true,
      businessId: credential.business_id,
    }
  } catch (e) {
    console.error('Error verifying business credentials:', e)
    return { success: false, error: 'Internal server error' }
  }
}

serve(async (req) => {
  try {
    if (req.method !== 'POST') {
      return Response.json({ error: 'Method not allowed' }, { status: 405 })
    }

    const body = await req.json() as {
      username?: string
      password?: string
      twoFactorCode?: string
    }

    if (!body.username || !body.password) {
      return Response.json(
        { success: false, error: 'Username and password required' },
        { status: 400 }
      )
    }

    const sb = supabaseAdmin()

    // Verify credentials
    const result = await verifyBusinessCredentials(sb, body.username, body.password)

    if (result.success) {
      return Response.json({
        success: true,
        businessId: result.businessId,
      })
    }

    // Handle failed authentication
    // Get current credential state for lockout info
    const { data: credential } = await sb
      .from('business_credentials')
      .select('failed_login_attempts, locked_until')
      .eq('username', body.username)
      .single()

    let lockedOut = false
    let lockoutRemaining: number | undefined
    let remainingAttempts: number | undefined

    if (credential) {
      if (credential.locked_until) {
        const lockedUntil = new Date(credential.locked_until)
        if (lockedUntil > new Date()) {
          lockedOut = true
          lockoutRemaining = Math.ceil((lockedUntil.getTime() - Date.now()) / 60000)
        }
      } else {
        remainingAttempts = Math.max(0, MAX_LOGIN_ATTEMPTS - (credential.failed_login_attempts || 0))
      }
    }

    const response: any = {
      success: false,
      error: result.error || 'Authentication failed',
    }

    if (lockedOut && lockoutRemaining !== undefined) {
      response.lockedOut = true
      response.lockoutRemaining = lockoutRemaining
    } else if (remainingAttempts !== undefined) {
      response.remainingAttempts = remainingAttempts
    }

    return Response.json(response, { status: 401 })
  } catch (e) {
    console.error('Business auth error:', e)
    return Response.json(
      { success: false, error: 'Internal server error' },
      { status: 500 }
    )
  }
})


// E-Commerce Data Enrichment API
// Phase 21: E-Commerce Data Enrichment Integration POC
// Section 21.1: Foundation & Infrastructure

import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import type {
  RealWorldBehaviorRequest,
  QuantumPersonalityRequest,
  CommunityInfluenceRequest,
  APIResponse,
  RealWorldBehaviorData,
  QuantumPersonalityData,
  CommunityInfluenceData,
} from './models.ts'
import { RealWorldBehaviorService } from './services/real-world-behavior-service.ts'
import { QuantumPersonalityService } from './services/quantum-personality-service.ts'
import { CommunityInfluenceService } from './services/community-influence-service.ts'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

interface RequestContext {
  apiKey: string
  partnerId: string
  endpoint: string
  timestamp: Date
}

serve(async (req) => {
  // Handle CORS preflight
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    // Initialize Supabase client
    const supabaseUrl = Deno.env.get('SUPABASE_URL') ?? ''
    const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    const supabase = createClient(supabaseUrl, supabaseServiceKey)

    // Extract API key from Authorization header
    const authHeader = req.headers.get('Authorization')
    const apiKey = authHeader?.replace('Bearer ', '') || authHeader?.replace('ApiKey ', '') || null

    if (!apiKey) {
      return new Response(
        JSON.stringify({
          success: false,
          error: {
            code: 'AUTHENTICATION_FAILED',
            message: 'API key required. Provide API key in Authorization header as "Bearer {api_key}" or "ApiKey {api_key}"',
          },
        }),
        {
          status: 401,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        }
      )
    }

    // Authenticate API key
    const { data: keyData, error: keyError } = await supabase
      .from('api_keys')
      .select('id, partner_id, rate_limit_per_minute, rate_limit_per_day, is_active, expires_at')
      .eq('api_key_hash', await hashAPIKey(apiKey))
      .eq('is_active', true)
      .single()

    if (keyError || !keyData) {
      return new Response(
        JSON.stringify({
          success: false,
          error: {
            code: 'AUTHENTICATION_FAILED',
            message: 'Invalid API key',
          },
        }),
        {
          status: 401,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        }
      )
    }

    // Check if API key is expired
    if (keyData.expires_at && new Date(keyData.expires_at) < new Date()) {
      return new Response(
        JSON.stringify({
          success: false,
          error: {
            code: 'API_KEY_EXPIRED',
            message: 'API key has expired',
          },
        }),
        {
          status: 401,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        }
      )
    }

    // Check rate limit
    const rateLimitCheck = await checkRateLimit(supabase, keyData.id, keyData.rate_limit_per_minute, keyData.rate_limit_per_day)
    if (!rateLimitCheck.allowed) {
      return new Response(
        JSON.stringify({
          success: false,
          error: {
            code: 'RATE_LIMIT_EXCEEDED',
            message: rateLimitCheck.message,
          },
        }),
        {
          status: 429,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        }
      )
    }

    // Parse request
    const url = new URL(req.url)
    const endpoint = url.pathname.split('/').pop() || ''

    // Route request
    let response: Response
    const startTime = Date.now()

    try {
      switch (endpoint) {
        case 'real-world-behavior':
          response = await handleRealWorldBehavior(req, supabase, keyData.partner_id, startTime)
          break
        case 'quantum-personality':
          response = await handleQuantumPersonality(req, supabase, keyData.partner_id, startTime)
          break
        case 'community-influence':
          response = await handleCommunityInfluence(req, supabase, keyData.partner_id, startTime)
          break
        default:
          response = new Response(
            JSON.stringify({
              success: false,
              error: {
                code: 'ENDPOINT_NOT_FOUND',
                message: `Endpoint "${endpoint}" not found. Available endpoints: real-world-behavior, quantum-personality, community-influence`,
              },
            }),
            {
              status: 404,
              headers: { ...corsHeaders, 'Content-Type': 'application/json' },
            }
          )
      }
    } catch (error) {
      response = new Response(
        JSON.stringify({
          success: false,
          error: {
            code: 'PROCESSING_ERROR',
            message: error.message || 'Internal server error',
          },
        }),
        {
          status: 500,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        }
      )
    }

    // Log request
    const processingTime = Date.now() - startTime
    await logRequest(supabase, keyData.id, endpoint, req.method, response.status, processingTime)

    return response
  } catch (error) {
    return new Response(
      JSON.stringify({
        success: false,
        error: {
          code: 'INTERNAL_ERROR',
          message: error.message || 'An unexpected error occurred',
        },
      }),
      {
        status: 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      }
    )
  }
})

// Hash API key for storage/comparison
async function hashAPIKey(apiKey: string): Promise<string> {
  const encoder = new TextEncoder()
  const data = encoder.encode(apiKey)
  const hashBuffer = await crypto.subtle.digest('SHA-256', data)
  const hashArray = Array.from(new Uint8Array(hashBuffer))
  return hashArray.map(b => b.toString(16).padStart(2, '0')).join('')
}

// Check rate limit
async function checkRateLimit(
  supabase: any,
  apiKeyId: string,
  limitPerMinute: number,
  limitPerDay: number
): Promise<{ allowed: boolean; message?: string }> {
  const now = new Date()
  const oneMinuteAgo = new Date(now.getTime() - 60 * 1000)
  const oneDayAgo = new Date(now.getTime() - 24 * 60 * 60 * 1000)

  // Check per-minute limit
  const { count: minuteCount } = await supabase
    .from('api_request_logs')
    .select('*', { count: 'exact', head: true })
    .eq('api_key_id', apiKeyId)
    .gte('created_at', oneMinuteAgo.toISOString())

  if (minuteCount >= limitPerMinute) {
    return {
      allowed: false,
      message: `Rate limit exceeded: ${limitPerMinute} requests per minute`,
    }
  }

  // Check per-day limit
  const { count: dayCount } = await supabase
    .from('api_request_logs')
    .select('*', { count: 'exact', head: true })
    .eq('api_key_id', apiKeyId)
    .gte('created_at', oneDayAgo.toISOString())

  if (dayCount >= limitPerDay) {
    return {
      allowed: false,
      message: `Rate limit exceeded: ${limitPerDay} requests per day`,
    }
  }

  return { allowed: true }
}

// Log request
async function logRequest(
  supabase: any,
  apiKeyId: string,
  endpoint: string,
  method: string,
  status: number,
  processingTimeMs: number
): Promise<void> {
  await supabase.from('api_request_logs').insert({
    api_key_id: apiKeyId,
    endpoint,
    method,
    response_status: status,
    processing_time_ms: processingTimeMs,
  })
}

// Endpoint handlers (Section 21.2: Core Endpoints)
async function handleRealWorldBehavior(req: Request, supabase: any, partnerId: string, startTime: number): Promise<Response> {
  try {
    const requestBody: RealWorldBehaviorRequest = await req.json()
    
    // Validate request
    if (!requestBody.user_segment || !requestBody.user_segment.segment_id) {
      return new Response(
        JSON.stringify({
          success: false,
          error: {
            code: 'INVALID_REQUEST',
            message: 'user_segment.segment_id is required',
          },
        }),
        {
          status: 400,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        }
      )
    }

    // Process request
    const service = new RealWorldBehaviorService(supabase)
    const data = await service.getRealWorldBehavior(requestBody)

    // Generate response
    const requestId = crypto.randomUUID()
    const processingTime = Date.now() - startTime
    const response: APIResponse<RealWorldBehaviorData> = {
      success: true,
      data,
      metadata: {
        request_id: requestId,
        processing_time_ms: processingTime,
        api_version: '1.0.0-poc',
        timestamp: new Date().toISOString(),
      },
    }

    return new Response(
      JSON.stringify(response),
      {
        status: 200,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      }
    )
  } catch (error) {
    return new Response(
      JSON.stringify({
        success: false,
        error: {
          code: 'PROCESSING_ERROR',
          message: error.message || 'Failed to process real-world behavior request',
        },
      }),
      {
        status: 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      }
    )
  }
}

async function handleQuantumPersonality(req: Request, supabase: any, partnerId: string, startTime: number): Promise<Response> {
  try {
    const requestBody: QuantumPersonalityRequest = await req.json()
    
    // Validate request
    if (!requestBody.user_segment || !requestBody.user_segment.segment_id) {
      return new Response(
        JSON.stringify({
          success: false,
          error: {
            code: 'INVALID_REQUEST',
            message: 'user_segment.segment_id is required',
          },
        }),
        {
          status: 400,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        }
      )
    }

    if (!requestBody.product_quantum_state) {
      return new Response(
        JSON.stringify({
          success: false,
          error: {
            code: 'INVALID_REQUEST',
            message: 'product_quantum_state is required',
          },
        }),
        {
          status: 400,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        }
      )
    }

    // Process request
    const service = new QuantumPersonalityService(supabase)
    const data = await service.getQuantumPersonality(requestBody)

    // Generate response
    const requestId = crypto.randomUUID()
    const processingTime = Date.now() - startTime
    const response: APIResponse<QuantumPersonalityData> = {
      success: true,
      data,
      metadata: {
        request_id: requestId,
        processing_time_ms: processingTime,
        api_version: '1.0.0-poc',
        timestamp: new Date().toISOString(),
      },
    }

    return new Response(
      JSON.stringify(response),
      {
        status: 200,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      }
    )
  } catch (error) {
    return new Response(
      JSON.stringify({
        success: false,
        error: {
          code: 'PROCESSING_ERROR',
          message: error.message || 'Failed to process quantum personality request',
        },
      }),
      {
        status: 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      }
    )
  }
}

async function handleCommunityInfluence(req: Request, supabase: any, partnerId: string, startTime: number): Promise<Response> {
  try {
    const requestBody: CommunityInfluenceRequest = await req.json()
    
    // Validate request
    if (!requestBody.user_segment || !requestBody.user_segment.segment_id) {
      return new Response(
        JSON.stringify({
          success: false,
          error: {
            code: 'INVALID_REQUEST',
            message: 'user_segment.segment_id is required',
          },
        }),
        {
          status: 400,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        }
      )
    }

    // Process request
    const service = new CommunityInfluenceService(supabase)
    const data = await service.getCommunityInfluence(requestBody)

    // Generate response
    const requestId = crypto.randomUUID()
    const processingTime = Date.now() - startTime
    const response: APIResponse<CommunityInfluenceData> = {
      success: true,
      data,
      metadata: {
        request_id: requestId,
        processing_time_ms: processingTime,
        api_version: '1.0.0-poc',
        timestamp: new Date().toISOString(),
      },
    }

    return new Response(
      JSON.stringify(response),
      {
        status: 200,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      }
    )
  } catch (error) {
    return new Response(
      JSON.stringify({
        success: false,
        error: {
          code: 'PROCESSING_ERROR',
          message: error.message || 'Failed to process community influence request',
        },
      }),
      {
        status: 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      }
    )
  }
}

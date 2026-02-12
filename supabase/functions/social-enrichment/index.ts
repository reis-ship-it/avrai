// Supabase Edge Function: Social Data Enrichment
// Phase 11 Section 4: Edge Mesh Functions
// Enriches social data with insights for personality learning

import { serve } from 'https://deno.land/std@0.224.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

interface RequestBody {
  agentId: string
  userId?: string // Optional: for user lookup if needed
}

function supabaseAdmin() {
  const url = Deno.env.get('SUPABASE_URL')!
  const serviceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
  return createClient(url, serviceKey, {
    auth: { persistSession: false },
  })
}

interface RespectPattern {
  categories: Record<string, number>
  spotTypes: Record<string, number>
  listTypes: Record<string, number>
  totalRespects: number
}

interface FollowNetwork {
  totalFollows: number
  networkDepth: number
  averageConnections: number
}

interface SocialInfluence {
  respectScore: number
  followScore: number
  engagementScore: number
  overallInfluence: number
}

function analyzeRespectPatterns(respects: any[]): RespectPattern {
  const categories: Record<string, number> = {}
  const spotTypes: Record<string, number> = {}
  const listTypes: Record<string, number> = {}
  
  for (const respect of respects || []) {
    if (respect.spots) {
      const category = respect.spots.category
      if (category) {
        categories[category] = (categories[category] || 0) + 1
      }
      spotTypes[respect.spots.id] = (spotTypes[respect.spots.id] || 0) + 1
    }
    
    if (respect.spot_lists) {
      const listName = respect.spot_lists.name
      if (listName) {
        listTypes[listName] = (listTypes[listName] || 0) + 1
      }
    }
  }
  
  return {
    categories,
    spotTypes,
    listTypes,
    totalRespects: respects?.length || 0,
  }
}

function analyzeFollowNetwork(follows: any[]): FollowNetwork {
  const totalFollows = follows?.length || 0
  // Simple network depth calculation (could be enhanced)
  const networkDepth = totalFollows > 10 ? 3 : totalFollows > 5 ? 2 : 1
  const averageConnections = totalFollows > 0 ? totalFollows / Math.max(1, totalFollows) : 0
  
  return {
    totalFollows,
    networkDepth,
    averageConnections,
  }
}

function calculateSocialInfluence(
  respects: any[],
  follows: any[]
): SocialInfluence {
  const respectCount = respects?.length || 0
  const followCount = follows?.length || 0
  
  // Calculate scores (0.0-1.0)
  const respectScore = Math.min(1.0, respectCount / 100)
  const followScore = Math.min(1.0, followCount / 50)
  const engagementScore = (respectScore + followScore) / 2
  const overallInfluence = (respectScore * 0.4 + followScore * 0.3 + engagementScore * 0.3)
  
  return {
    respectScore,
    followScore,
    engagementScore,
    overallInfluence,
  }
}

serve(async (req) => {
  try {
    // CORS headers
    const corsHeaders = {
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
    }

    // Handle OPTIONS request
    if (req.method === 'OPTIONS') {
      return new Response('ok', { headers: corsHeaders })
    }

    const body: RequestBody = await req.json()
    const { agentId, userId } = body

    if (!agentId) {
      return new Response(
        JSON.stringify({ error: 'agentId is required' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    const supabase = supabaseAdmin()

    // Note: Since we use agentId but tables use userId, we need to look up userId
    // For now, we'll query using a placeholder approach
    // TODO: Enhance when user_agent_mappings table exists
    
    // Query social data (using agentId lookup if possible, otherwise use userId if provided)
    // For Phase 11, we'll use a simplified approach that queries by userId if provided
    // In production, this would use a user_agent_mappings table
    
    let respects: any[] = []
    let follows: any[] = []
    
    if (userId) {
      // Query user_respects
      const { data: respectsData, error: respectsError } = await supabase
        .from('user_respects')
        .select('*, spots(*), spot_lists(*)')
        .eq('user_id', userId)
        .limit(50)
      
      if (!respectsError) {
        respects = respectsData || []
      }

      // Query user_follows
      const { data: followsData, error: followsError } = await supabase
        .from('user_follows')
        .select('*, following_user:users!user_follows_following_id_fkey(*)')
        .eq('follower_id', userId)
        .limit(50)
      
      if (!followsError) {
        follows = followsData || []
      }
    }

    // Enrich with insights
    const insights = {
      respectPatterns: analyzeRespectPatterns(respects),
      followNetwork: analyzeFollowNetwork(follows),
      socialInfluence: calculateSocialInfluence(respects, follows),
    }

    return new Response(
      JSON.stringify({ insights }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 200,
      }
    )
  } catch (e) {
    console.error('Social enrichment error:', e)
    return new Response(
      JSON.stringify({ error: String(e) }),
      {
        status: 500,
        headers: { 'Content-Type': 'application/json' },
      }
    )
  }
})

// Supabase Edge Function: LLM Generation with Structured Context
// Phase 11 Section 4: Edge Mesh Functions
// Generates LLM responses with distilled context from retrieval layer

import { serve } from 'https://deno.land/std@0.224.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

interface RequestBody {
  query: string
  structuredContext?: {
    traits?: string[]
    places?: any[]
    social_graph?: any[]
    onboarding_data?: any
    agentId?: string
  }
  dimensionScores?: Record<string, number>
  personalityProfile?: any
}

function supabaseAdmin() {
  const url = Deno.env.get('SUPABASE_URL')!
  const serviceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
  return createClient(url, serviceKey, {
    auth: { persistSession: false },
  })
}

function buildPrompt(
  query: string,
  structuredContext: any,
  dimensionScores: any,
  personalityProfile: any,
): string {
  const traits = structuredContext?.traits?.join(', ') || 'none'
  const placesCount = structuredContext?.places?.length || 0
  const socialCount = structuredContext?.social_graph?.length || 0

  return `
User query: ${query}

Structured context:
- Traits: ${traits}
- Places: ${placesCount} places
- Social graph: ${socialCount} connections

Dimension scores: ${JSON.stringify(dimensionScores || {})}
Personality profile: ${JSON.stringify(personalityProfile || {})}

Provide a helpful recommendation based on this context.
`
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

    const apiKey = Deno.env.get('GEMINI_API_KEY')
    if (!apiKey) {
      return new Response(
        JSON.stringify({ error: 'GEMINI_API_KEY not configured' }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    const body: RequestBody = await req.json()
    const {
      query,
      structuredContext = {},
      dimensionScores = {},
      personalityProfile,
    } = body

    if (!query) {
      return new Response(
        JSON.stringify({ error: 'query is required' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Build prompt with distilled context
    const prompt = buildPrompt(query, structuredContext, dimensionScores, personalityProfile)

    // Call Gemini API
    // Use gemini-2.0-flash (available model, fast and free tier compatible)
    const model = 'gemini-2.0-flash'
    const url = `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent?key=${apiKey}`

    const response = await fetch(url, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        contents: [{
          role: 'user',
          parts: [{ text: prompt }],
        }],
        generationConfig: {
          temperature: 0.7,
          maxOutputTokens: 500,
          topP: 0.95,
          topK: 40,
        },
      }),
    })

    if (!response.ok) {
      const errorText = await response.text()
      console.error('Gemini API error:', errorText)
      return new Response(
        JSON.stringify({ error: `Gemini API error: ${response.status}`, details: errorText }),
        { status: response.status, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    const data = await response.json()

    if (!data.candidates || data.candidates.length === 0) {
      return new Response(
        JSON.stringify({ error: 'No response from Gemini' }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    const generatedText = data.candidates[0].content?.parts?.[0]?.text || 
      'I apologize, but I could not generate a response.'

    // Store response in database if agentId is provided
    if (structuredContext?.agentId) {
      try {
        const supabase = supabaseAdmin()
        
        // Create llm_responses table if it doesn't exist (will be created via migration)
        // For now, we'll attempt to insert, but won't fail if table doesn't exist
        await supabase
          .from('llm_responses')
          .insert({
            agent_id: structuredContext.agentId,
            query: query,
            response: generatedText,
            created_at: new Date().toISOString(),
          })
          .then(({ error }) => {
            if (error) {
              // Table might not exist yet, log but don't fail
              console.log('Note: llm_responses table may not exist yet:', error.message)
            }
          })
      } catch (e) {
        // Don't fail the request if storing fails
        console.log('Note: Could not store LLM response:', e)
      }
    }

    return new Response(
      JSON.stringify({
        response: generatedText,
        model: model,
        usage: data.usageMetadata,
      }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 200,
      }
    )
  } catch (e) {
    console.error('LLM generation error:', e)
    return new Response(
      JSON.stringify({ error: String(e) }),
      {
        status: 500,
        headers: { 'Content-Type': 'application/json' },
      }
    )
  }
})

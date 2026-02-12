// Supabase Edge Function: Google Gemini LLM Chat
// Provides LLM-powered responses for SPOTS AI features
import { serve } from 'https://deno.land/std@0.224.0/http/server.ts'

interface ChatMessage {
  role: 'user' | 'assistant' | 'system'
  content: string
}

interface LLMRequest {
  messages: ChatMessage[]
  context?: {
    userId?: string
    location?: { lat: number; lng: number }
    preferences?: Record<string, any>
    recentSpots?: any[]
  }
  temperature?: number
  maxTokens?: number
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

    const body: LLMRequest = await req.json()
    const { messages, context, temperature = 0.7, maxTokens = 500 } = body

    if (!messages || messages.length === 0) {
      return new Response(
        JSON.stringify({ error: 'Messages are required' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Build system context from SPOTS context with full AI/ML integration
    let systemContext = `You are a helpful assistant for SPOTS, a location discovery app that helps people find meaningful places through personalized lists and community recommendations.

Key principles:
- Help users discover authentic local spots, not tourist traps
- Respect user privacy - never ask for personal information
- Be concise and actionable
- Focus on community-driven recommendations
- Help with creating lists, finding spots, and discovering new places
- Personalize responses based on user's personality and preferences`

    if (context) {
      // Basic context
      if (context.location) {
        systemContext += `\n\nUser's current location: ${context.location.lat}, ${context.location.lng}`
      }
      if (context.preferences) {
        systemContext += `\n\nUser preferences: ${JSON.stringify(context.preferences)}`
      }
      if (context.recentSpots && context.recentSpots.length > 0) {
        systemContext += `\n\nUser recently visited: ${context.recentSpots.map((s: any) => s.name || s).join(', ')}`
      }
      
      // Personality integration
      if (context.personality) {
        const p = context.personality
        systemContext += `\n\nUser Personality Profile:
- Archetype: ${p.archetype || 'developing'}
- Evolution Generation: ${p.evolutionGeneration || 1}
- Authenticity Score: ${((p.authenticity || 0.5) * 100).toFixed(0)}%
- Dominant Traits: ${(p.dominantTraits || []).join(', ') || 'developing'}
- Personality Dimensions: ${JSON.stringify(p.dimensions || {})}
- Dimension Confidence: ${JSON.stringify(p.dimensionConfidence || {})}

Use this personality profile to personalize your responses. Match your tone and recommendations to their personality archetype and dominant traits.`
      }
      
      // Vibe integration
      if (context.vibe) {
        const v = context.vibe
        systemContext += `\n\nUser Vibe Profile:
- Vibe Archetype: ${v.archetype || 'neutral'}
- Overall Energy: ${((v.overallEnergy || 0.5) * 100).toFixed(0)}%
- Social Preference: ${((v.socialPreference || 0.5) * 100).toFixed(0)}%
- Exploration Tendency: ${((v.explorationTendency || 0.5) * 100).toFixed(0)}%
- Temporal Context: ${v.temporalContext || 'unknown'}

Adjust your recommendations based on their vibe. High energy users might want active spots, high social preference users might want community spaces, high exploration users might want unique/novel places.`
      }
      
      // AI2AI insights integration
      if (context.ai2aiInsights && context.ai2aiInsights.length > 0) {
        systemContext += `\n\nAI2AI Learning Insights (from network learning):
${context.ai2aiInsights.map((insight: any) => 
  `- ${insight.type}: Learning quality ${((insight.learningQuality || 0) * 100).toFixed(0)}%, Dimension insights: ${JSON.stringify(insight.dimensionInsights || {})}`
).join('\n')}

Use these insights to enhance your recommendations. The AI2AI network has learned patterns that can inform better suggestions.`
      }
      
      // Connection metrics integration
      if (context.connectionMetrics) {
        const cm = context.connectionMetrics
        systemContext += `\n\nAI2AI Connection Status:
- Compatibility: ${((cm.currentCompatibility || 0) * 100).toFixed(0)}%
- Learning Effectiveness: ${((cm.learningEffectiveness || 0) * 100).toFixed(0)}%
- AI Pleasure Score: ${((cm.aiPleasureScore || 0) * 100).toFixed(0)}%
- Status: ${cm.status || 'unknown'}

The user's AI personality is actively learning from the network. Consider this in your recommendations.`
      }
      
      // Language style integration (Phase 2.4)
      if (context.languageStyle) {
        systemContext += `\n\n${context.languageStyle}

Important: Match the user's communication style gradually. Don't copy exactly, but adapt your responses to feel natural to them. The style should influence your tone, vocabulary choices, and phrasing, but your responses should still be authentic and helpful.`
      }
    }

    // Convert messages to Gemini format
    // Gemini uses a different format - we need to structure it properly
    const geminiMessages = messages.map((msg) => ({
      role: msg.role === 'assistant' ? 'model' : 'user',
      parts: [{ text: msg.content }],
    }))

    // Add system context as first user message
    geminiMessages.unshift({
      role: 'user',
      parts: [{ text: systemContext }],
    })

    // Call Gemini API
    const model = 'gemini-pro' // Free tier model
    const url = `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent?key=${apiKey}`

    const response = await fetch(url, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        contents: geminiMessages,
        generationConfig: {
          temperature,
          maxOutputTokens: maxTokens,
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

    const generatedText = data.candidates[0].content?.parts?.[0]?.text || 'I apologize, but I could not generate a response.'

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
    console.error('LLM chat error:', e)
    return new Response(
      JSON.stringify({ error: String(e) }),
      { status: 500, headers: { 'Content-Type': 'application/json' } }
    )
  }
})


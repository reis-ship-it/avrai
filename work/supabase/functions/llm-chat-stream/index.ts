// Supabase Edge Function: Google Gemini LLM Chat with SSE Streaming
// Provides streaming LLM-powered responses for SPOTS AI features
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
    personality?: any
    vibe?: any
    ai2aiInsights?: any[]
    connectionMetrics?: any
    languageStyle?: string
    conversationPreferences?: Record<string, any>
  }
  temperature?: number
  maxTokens?: number
}

function appendSafeContext(systemContext: string, context?: LLMRequest['context']): string {
  if (!context) return systemContext

  let next = systemContext
  if (context.location) {
    next += `\n\nApproximate location: ${context.location.lat}, ${context.location.lng}`
  }

  const prefs = context.preferences ?? {}
  if (Array.isArray(prefs.traits) && prefs.traits.length > 0) {
    next += `\n\nKnown preference signals: ${prefs.traits.slice(0, 8).join(', ')}`
  }
  if (typeof prefs.known_places_count === 'number') {
    next += `\nKnown places count: ${prefs.known_places_count}`
  }
  if (typeof prefs.social_graph_count === 'number') {
    next += `\nSocial graph count: ${prefs.social_graph_count}`
  }
  if (prefs.personality?.archetype) {
    next += `\nPersonality archetype: ${prefs.personality.archetype}`
  }
  if (Array.isArray(prefs.personality?.dominant_traits) && prefs.personality.dominant_traits.length > 0) {
    next += `\nDominant traits: ${prefs.personality.dominant_traits.slice(0, 5).join(', ')}`
  }

  const conversationPreferences = context.conversationPreferences as Record<string, unknown> | undefined
  if (conversationPreferences?.display_name && conversationPreferences?.summary) {
    next += `\n\nLocal context: ${String(conversationPreferences.display_name)}. ${String(conversationPreferences.summary)}`
  }

  if (typeof context.languageStyle === 'string' && context.languageStyle.trim().length > 0) {
    next += `\n\nCommunication style guidance: ${context.languageStyle.trim()}`
  }

  return next
}

serve(async (req) => {
  try {
    // CORS headers for SSE
    const corsHeaders = {
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
      'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
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

    systemContext = appendSafeContext(systemContext, context)

    const embeddedSystemMessages = messages
      .filter((msg) => msg.role === 'system' && msg.content.trim().length > 0)
      .map((msg) => msg.content.trim())
    if (embeddedSystemMessages.length > 0) {
      systemContext += `\n\nAdditional system guidance:\n${embeddedSystemMessages.join('\n')}`
    }

    // Convert messages to Gemini format
    const geminiMessages = messages
      .filter((msg) => msg.role !== 'system')
      .map((msg) => ({
      role: msg.role === 'assistant' ? 'model' : 'user',
      parts: [{ text: msg.content }],
    }))

    // Gemini does not expose a true system role in this endpoint, so we pass
    // consolidated system guidance as a dedicated leading instruction message.
    geminiMessages.unshift({
      role: 'user',
      parts: [{ text: `SYSTEM INSTRUCTIONS:\n${systemContext}` }],
    })

    // Call Gemini API with streaming enabled
    const model = 'gemini-pro' // Free tier model
    const url = `https://generativelanguage.googleapis.com/v1beta/models/${model}:streamGenerateContent?alt=sse&key=${apiKey}`

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

    // Create SSE stream with enhanced error handling
    const encoder = new TextEncoder()
    const body = new ReadableStream({
      async start(controller) {
        let reader: ReadableStreamDefaultReader<Uint8Array> | null = null
        let timeoutId: number | null = null
        const STREAM_TIMEOUT = 300000 // 5 minutes timeout for long responses
        
        try {
          reader = response.body?.getReader()
          if (!reader) {
            controller.enqueue(encoder.encode('data: {"error": "No response body"}\n\n'))
            controller.close()
            return
          }

          // Set timeout for long-running streams
          timeoutId = setTimeout(() => {
            console.error('Stream timeout after 5 minutes')
            controller.enqueue(
              encoder.encode('data: {"error": "Stream timeout - response too long"}\n\n')
            )
            controller.enqueue(encoder.encode('data: {"done": true}\n\n'))
            controller.close()
            reader?.cancel()
          }, STREAM_TIMEOUT)

          let buffer = ''
          let hasReceivedData = false
          
          while (true) {
            const { done, value } = await reader.read()
            
            if (done) {
              // Clear timeout on successful completion
              if (timeoutId) clearTimeout(timeoutId)
              
              // Send completion event
              controller.enqueue(encoder.encode('data: {"done": true}\n\n'))
              controller.close()
              break
            }

            // Mark that we've received data
            hasReceivedData = true

            // Decode chunk
            buffer += new TextDecoder().decode(value)
            
            // Process complete events (split by double newline)
            const events = buffer.split('\n\n')
            buffer = events.pop() || '' // Keep incomplete event in buffer

            for (const event of events) {
              if (!event.trim()) continue
              
              // Parse SSE data
              const dataMatch = event.match(/data: (.+)/)
              if (!dataMatch) continue
              
              try {
                const data = JSON.parse(dataMatch[1])
                
                // Check for Gemini API errors
                if (data.error) {
                  console.error('Gemini API error in stream:', data.error)
                  controller.enqueue(
                    encoder.encode(`data: ${JSON.stringify({ error: data.error.message || String(data.error) })}\n\n`)
                  )
                  controller.enqueue(encoder.encode('data: {"done": true}\n\n'))
                  controller.close()
                  if (timeoutId) clearTimeout(timeoutId)
                  return
                }
                
                // Extract text from Gemini response
                if (data.candidates && data.candidates.length > 0) {
                  const candidate = data.candidates[0]
                  
                  // Check for finish reason (error or safety)
                  if (candidate.finishReason && candidate.finishReason !== 'STOP') {
                    console.warn('Gemini finish reason:', candidate.finishReason)
                    if (candidate.finishReason === 'SAFETY') {
                      controller.enqueue(
                        encoder.encode('data: {"error": "Response blocked by safety filters"}\n\n')
                      )
                    }
                  }
                  
                  const text = candidate.content?.parts?.[0]?.text
                  if (text) {
                    // Send text chunk to client
                    controller.enqueue(
                      encoder.encode(`data: ${JSON.stringify({ text })}\n\n`)
                    )
                  }
                }
              } catch (e) {
                console.error('Error parsing Gemini SSE data:', e)
                // Continue processing - don't break the stream on parse errors
              }
            }
          }
        } catch (e) {
          console.error('Stream error:', e)
          // Send error event before closing
          controller.enqueue(
            encoder.encode(`data: ${JSON.stringify({ error: String(e) })}\n\n`)
          )
          controller.enqueue(encoder.encode('data: {"done": true}\n\n'))
          controller.close()
        } finally {
          // Cleanup
          if (timeoutId) clearTimeout(timeoutId)
          if (reader) {
            try {
              await reader.cancel()
            } catch (e) {
              console.error('Error canceling reader:', e)
            }
          }
        }
      },
    })

    return new Response(body, {
      headers: {
        ...corsHeaders,
        'Content-Type': 'text/event-stream',
        'Cache-Control': 'no-cache',
        'Connection': 'keep-alive',
      },
    })
  } catch (e) {
    console.error('LLM chat stream error:', e)
    return new Response(
      JSON.stringify({ error: String(e) }),
      { 
        status: 500, 
        headers: { 
          'Content-Type': 'application/json',
          'Access-Control-Allow-Origin': '*',
        } 
      }
    )
  }
})


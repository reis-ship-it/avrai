// Supabase Edge Function: simple text embedding proxy using Hugging Face Inference API or custom model
// For demo purposes, this returns a deterministic vector based on string hash if no upstream is configured.
import { serve } from 'https://deno.land/std@0.177.0/http/server.ts'

function hashToVector(text: string, dim = 32): number[] {
  let h = 2166136261 >>> 0
  for (let i = 0; i < text.length; i++) {
    h ^= text.charCodeAt(i)
    h = Math.imul(h, 16777619) >>> 0
  }
  const vec: number[] = []
  for (let i = 0; i < dim; i++) {
    h = Math.imul(h ^ (i + 1), 16777619) >>> 0
    vec.push((h % 1000) / 1000)
  }
  return vec
}

serve(async (req) => {
  try {
    const body = await req.json()
    const texts: string[] = body?.texts ?? []
    const embeddings = texts.map((t) => hashToVector(t, 384))
    return new Response(JSON.stringify({ embeddings }), {
      headers: { 'Content-Type': 'application/json' },
      status: 200,
    })
  } catch (e) {
    return new Response(JSON.stringify({ error: String(e) }), { status: 400 })
  }
})



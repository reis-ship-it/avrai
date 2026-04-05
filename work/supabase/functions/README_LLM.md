# LLM Integration Setup Guide

This guide will help you set up Google Gemini LLM integration for SPOTS.

## 🧠 Local on-device LLM (model-pack system)

SPOTS supports a **local model-pack system** for on-device inference. Because model weights are multi‑GB, they are **not shipped inside the base app install**. Instead, eligible devices **auto-download on Wi‑Fi by default (opt-out)** using a **signed manifest** fetched from Supabase.

**Source of truth docs:**
- `docs/plans/architecture/LOCAL_LLM_MODEL_PACK_SYSTEM.md`
- `docs/plans/onboarding/ONBOARDING_LLM_DOWNLOAD_AND_BOOTSTRAP_ARCHITECTURE.md`

## 🚀 Quick Start

### Step 1: Get Google Gemini API Key

1. Go to [Google AI Studio](https://makersuite.google.com/app/apikey)
2. Sign in with your Google account
3. Click "Create API Key"
4. Copy your API key (starts with `AIza...`)

### Step 2: Deploy the Edge Function

```bash
# Make sure you're in the project root
cd /path/to/SPOTS

# Deploy the LLM chat function
supabase functions deploy llm-chat --no-verify-jwt
```

### (Optional) Step 2b: Deploy the signed local model-pack manifest function

This function serves a **signed** model-pack manifest used by the app in release builds:

```bash
supabase functions deploy local-llm-manifest --no-verify-jwt
```

### Step 3: Set the API Key Secret

```bash
# Set your Gemini API key as a Supabase secret
supabase secrets set GEMINI_API_KEY=your_api_key_here
```

**Important:** Replace `your_api_key_here` with your actual API key from Step 1.

### (Optional) Step 3b: Configure local-llm-manifest signing + artifact metadata

1) Generate an Ed25519 keypair for signing:

```bash
dart run scripts/security/generate_local_llm_manifest_keys.dart
```

2) Set Supabase secrets (server-side signing seed + key id):

```bash
supabase secrets set LOCAL_LLM_MANIFEST_KEY_ID=v1
supabase secrets set LOCAL_LLM_MANIFEST_SIGNING_KEY_B64=<base64_32_byte_seed>
```

3) Configure artifact URLs + hashes (Supabase Storage public URLs recommended):

```bash
# llama8b (default)
supabase secrets set LOCAL_LLM_ANDROID_GGUF_URL=<https://.../model.gguf>
supabase secrets set LOCAL_LLM_ANDROID_GGUF_SHA256=<64_hex_chars>
supabase secrets set LOCAL_LLM_ANDROID_GGUF_SIZE_BYTES=<bytes>

supabase secrets set LOCAL_LLM_IOS_COREML_ZIP_URL=<https://.../model_coreml.zip>
supabase secrets set LOCAL_LLM_IOS_COREML_ZIP_SHA256=<64_hex_chars>
supabase secrets set LOCAL_LLM_IOS_COREML_ZIP_SIZE_BYTES=<bytes>

# small3b (optional tier)
supabase secrets set LOCAL_LLM_ANDROID_GGUF_URL_3B=<https://.../model.gguf>
supabase secrets set LOCAL_LLM_ANDROID_GGUF_SHA256_3B=<64_hex_chars>
supabase secrets set LOCAL_LLM_ANDROID_GGUF_SIZE_BYTES_3B=<bytes>

supabase secrets set LOCAL_LLM_IOS_COREML_ZIP_URL_3B=<https://.../model_coreml.zip>
supabase secrets set LOCAL_LLM_IOS_COREML_ZIP_SHA256_3B=<64_hex_chars>
supabase secrets set LOCAL_LLM_IOS_COREML_ZIP_SIZE_BYTES_3B=<bytes>
```

4) Provide the **public key** to the app at build time:

- `--dart-define=LOCAL_LLM_MANIFEST_PUBLIC_KEY_B64_V1=<base64_public_key>`

### Step 4: Verify Deployment

```bash
# Test the function
curl -X POST https://your-project.supabase.co/functions/v1/llm-chat \
  -H "Authorization: Bearer YOUR_ANON_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "messages": [
      {"role": "user", "content": "Hello! Can you help me find coffee shops?"}
    ]
  }'
```

## 📋 Configuration

### Environment Variables

The function uses the following environment variable:
- `GEMINI_API_KEY` - Your Google Gemini API key (required)

### Model Configuration

The function uses `gemini-pro` by default (free tier). To change the model, edit `supabase/functions/llm-chat/index.ts` and update the `model` variable.

Available models:
- `gemini-pro` - Free tier, good for most use cases
- `gemini-pro-vision` - For image understanding (requires API key upgrade)

## 🔧 Troubleshooting

### Function Not Found

If you get a 404 error:
1. Make sure you deployed the function: `supabase functions deploy llm-chat`
2. Check your Supabase project URL is correct
3. Verify you're using the correct function name (`llm-chat`)

### API Key Error

If you get "GEMINI_API_KEY not configured":
1. Make sure you set the secret: `supabase secrets set GEMINI_API_KEY=...`
2. Verify the secret name matches exactly: `GEMINI_API_KEY`
3. Redeploy the function after setting the secret

### Rate Limit Errors

Google Gemini free tier has rate limits:
- 60 requests per minute
- If you hit limits, the function will return an error

Solutions:
- Add retry logic in your Dart code
- Upgrade to paid tier for higher limits
- Implement request queuing

## 💰 Cost Information

**Google Gemini Free Tier:**
- 60 requests per minute
- 1,500 requests per day
- No credit card required

**Paid Tier (if needed):**
- $0.00025 per 1K characters input
- $0.0005 per 1K characters output
- Very affordable for most apps

## 🧪 Testing

### Test from Dart Code

```dart
import 'package:spots/core/services/llm_service.dart';
import 'package:get_it/get_it.dart';

final llmService = GetIt.instance<LLMService>();

final response = await llmService.generateRecommendation(
  userQuery: 'Find coffee shops near me',
  userContext: LLMContext(
    location: Position(latitude: 40.7128, longitude: -74.0060),
  ),
);

print(response);
```

### Test from Terminal

```bash
# Using curl
curl -X POST https://your-project.supabase.co/functions/v1/llm-chat \
  -H "Authorization: Bearer YOUR_ANON_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "messages": [
      {"role": "user", "content": "Hello!"}
    ],
    "context": {
      "location": {"lat": 40.7128, "lng": -74.0060}
    }
  }'
```

## 📚 Next Steps

1. ✅ Deploy the function
2. ✅ Set your API key
3. ✅ Test the integration
4. Update your UI to use the LLM service
5. Add error handling and retry logic
6. Monitor usage and costs

## 🔒 Security Notes

- API keys are stored securely in Supabase secrets
- Never commit API keys to git
- Use environment variables for local development
- Rotate keys periodically

## 📖 Additional Resources

- [Google Gemini API Docs](https://ai.google.dev/docs)
- [Supabase Edge Functions Docs](https://supabase.com/docs/guides/functions)
- [SPOTS LLM Integration Guide](../../docs/plans/llm_integration/LLM_INTEGRATION_COMPLETE.md)


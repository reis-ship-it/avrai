# Google Gemini LLM Integration - Setup Instructions

**Status:** ✅ Implementation Complete  
**Date:** November 18, 2025

---

## 🎯 **What Was Implemented**

✅ **Supabase Edge Function** (`supabase/functions/llm-chat/index.ts`)
- Google Gemini API integration
- CORS support
- Error handling
- Context-aware responses

✅ **Dart LLM Service** (`lib/core/services/llm_service.dart`)
- LLM service wrapper
- Chat functionality
- Recommendation generation
- List name suggestions
- Conversation management

✅ **Updated Command Processor** (`lib/presentation/widgets/common/ai_command_processor.dart`)
- LLM-powered command processing
- Fallback to rule-based if LLM unavailable
- Context-aware responses

✅ **Dependency Injection** (`lib/injection_container.dart`)
- LLM service registered
- Supabase client integration
- Optional service (app works without it)

---

## 🚀 **Quick Setup (5 Minutes)**

### **Step 1: Get Google Gemini API Key**

1. Visit [Google AI Studio](https://makersuite.google.com/app/apikey)
2. Sign in with your Google account
3. Click **"Create API Key"**
4. Copy your API key (starts with `AIza...`)

**Note:** Free tier includes:
- 60 requests per minute
- 1,500 requests per day
- No credit card required

### **Step 2: Deploy Edge Function**

```bash
# Navigate to project root
cd /path/to/SPOTS

# Deploy the LLM chat function
supabase functions deploy llm-chat --no-verify-jwt
```

### **Step 3: Set API Key Secret**

```bash
# Set your Gemini API key
supabase secrets set GEMINI_API_KEY=your_api_key_here
```

**Replace `your_api_key_here` with your actual API key from Step 1.**

### **Step 4: Verify It Works**

Test the function:

```bash
curl -X POST https://your-project.supabase.co/functions/v1/llm-chat \
  -H "Authorization: Bearer YOUR_ANON_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "messages": [
      {"role": "user", "content": "Hello! Can you help me find coffee shops?"}
    ]
  }'
```

You should get a JSON response with a `response` field containing the AI's answer.

---

## 📱 **Using in Your App**

### **Basic Usage**

```dart
import 'package:spots/core/services/llm_service.dart';
import 'package:get_it/get_it.dart';

// Get the LLM service
final llmService = GetIt.instance<LLMService>();

// Generate a recommendation
final response = await llmService.generateRecommendation(
  userQuery: 'Find coffee shops near me',
  userContext: LLMContext(
    location: Position(latitude: 40.7128, longitude: -74.0060),
  ),
);

print(response); // AI-generated response
```

### **In Your UI**

The `AICommandProcessor` now automatically uses the LLM if available:

```dart
// In your widget
final response = await AICommandProcessor.processCommand(
  userInput,
  context,
  userContext: LLMContext(
    userId: currentUser.id,
    location: currentLocation,
    preferences: userPreferences,
  ),
);

// Display response
showDialog(
  context: context,
  builder: (context) => AlertDialog(
    title: Text('AI Response'),
    content: Text(response),
  ),
);
```

### **Chat Interface**

```dart
// Maintain conversation history
List<ChatMessage> conversationHistory = [];

// Add user message
conversationHistory.add(ChatMessage(
  role: ChatRole.user,
  content: userMessage,
));

// Get AI response
final response = await llmService.continueConversation(
  conversationHistory: conversationHistory,
  userMessage: userMessage,
  context: userContext,
);

// Add AI response
conversationHistory.add(ChatMessage(
  role: ChatRole.assistant,
  content: response,
));
```

---

## 🔧 **Configuration**

### **Change Model**

Edit `supabase/functions/llm-chat/index.ts`:

```typescript
// Change this line:
const model = 'gemini-pro'; // or 'gemini-pro-vision' for images
```

### **Adjust Temperature**

Temperature controls randomness (0.0 = deterministic, 1.0 = creative):

```dart
final response = await llmService.chat(
  messages: messages,
  temperature: 0.7, // Default, adjust as needed
);
```

### **Adjust Max Tokens**

Control response length:

```dart
final response = await llmService.chat(
  messages: messages,
  maxTokens: 500, // Default, adjust as needed
);
```

---

## 🐛 **Troubleshooting**

### **Function Not Found (404)**

**Problem:** Function doesn't exist or not deployed.

**Solution:**
```bash
# Redeploy the function
supabase functions deploy llm-chat --no-verify-jwt

# Verify it exists
supabase functions list
```

### **API Key Error**

**Problem:** "GEMINI_API_KEY not configured"

**Solution:**
```bash
# Set the secret
supabase secrets set GEMINI_API_KEY=your_key_here

# Verify it's set (won't show value, but confirms it exists)
supabase secrets list
```

### **Rate Limit Errors**

**Problem:** "429 Too Many Requests"

**Solution:**
- Free tier: 60 requests/minute
- Add retry logic with exponential backoff
- Consider upgrading to paid tier if needed

### **LLM Service Not Available**

**Problem:** App falls back to rule-based responses

**Solution:**
- Check Supabase connection
- Verify function is deployed
- Check API key is set correctly
- Check logs: `supabase functions logs llm-chat`

---

## 💰 **Cost Information**

### **Free Tier (Current)**
- ✅ 60 requests per minute
- ✅ 1,500 requests per day
- ✅ No credit card required
- ✅ Perfect for development and small apps

### **Paid Tier (If Needed)**
- $0.00025 per 1K characters input
- $0.0005 per 1K characters output
- Very affordable for production apps

**Example:** 1,000 users, 10 queries/user/month = ~$2-5/month

---

## 📊 **Monitoring**

### **View Function Logs**

```bash
# View recent logs
supabase functions logs llm-chat

# Follow logs in real-time
supabase functions logs llm-chat --follow
```

### **Monitor Usage**

Check Google AI Studio dashboard:
- Visit [Google AI Studio](https://makersuite.google.com/app/apikey)
- Click on your API key
- View usage statistics

---

## 🔒 **Security Best Practices**

1. ✅ **API keys stored in Supabase secrets** (not in code)
2. ✅ **Server-side only** (Edge Function, not client)
3. ✅ **CORS configured** (only your app can call it)
4. ✅ **Error handling** (doesn't expose sensitive info)

**Never:**
- ❌ Commit API keys to git
- ❌ Store API keys in client code
- ❌ Share API keys publicly

---

## 📚 **Next Steps**

1. ✅ **Deploy function** - `supabase functions deploy llm-chat`
2. ✅ **Set API key** - `supabase secrets set GEMINI_API_KEY=...`
3. ✅ **Test integration** - Try a query in your app
4. 🔄 **Add error handling** - Handle rate limits gracefully
5. 🔄 **Add retry logic** - For transient failures
6. 🔄 **Monitor usage** - Track costs and performance
7. 🔄 **Optimize prompts** - Improve response quality

---

## 🎉 **You're Ready!**

Your LLM integration is complete and ready to use. The app will automatically:
- Use Gemini for AI responses when available
- Fall back to rule-based responses if LLM unavailable
- Handle errors gracefully
- Provide context-aware recommendations

**Start using it in your app now!**

---

**Questions?** Check:
- [Supabase Edge Functions Docs](https://supabase.com/docs/guides/functions)
- [Google Gemini API Docs](https://ai.google.dev/docs)
- [SPOTS LLM Integration Assessment](./llm_integration_assessment.md)


# Deploy Google Gemini LLM Integration

## ✅ **Prerequisites**

1. **Supabase CLI installed**
   ```bash
   # Install if needed
   npm install -g supabase
   ```

2. **Supabase project linked**
   ```bash
   # Link your project (if not already linked)
   supabase link --project-ref your-project-ref
   ```

3. **Google Gemini API Key**
   - Get it from: https://makersuite.google.com/app/apikey
   - Copy your API key (starts with `AIza...`)

---

## 🚀 **Deployment Steps**

### **Step 1: Deploy the Edge Function**

```bash
cd /Users/reisgordon/SPOTS
supabase functions deploy llm-chat --no-verify-jwt
```

**Expected output:**
```
Deploying function llm-chat...
Function llm-chat deployed successfully!
```

### **Step 2: Set Your Gemini API Key**

```bash
supabase secrets set GEMINI_API_KEY=your_api_key_here
```

**Replace `your_api_key_here` with your actual API key from Google AI Studio.**

**Expected output:**
```
Secret GEMINI_API_KEY set successfully
```

### **Step 3: Verify Deployment**

Test the function:

```bash
# Get your project URL and anon key from Supabase dashboard
curl -X POST https://your-project.supabase.co/functions/v1/llm-chat \
  -H "Authorization: Bearer YOUR_ANON_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "messages": [
      {"role": "user", "content": "Hello! Can you help me find coffee shops?"}
    ]
  }'
```

**Expected response:**
```json
{
  "response": "I'd be happy to help you find coffee shops! ...",
  "model": "gemini-pro",
  "usage": {...}
}
```

---

## 🧪 **Test in Your App**

Once deployed, test in your Flutter app:

```dart
import 'package:spots/core/services/llm_service.dart';
import 'package:get_it/get_it.dart';

final llmService = GetIt.instance<LLMService>();

final response = await llmService.generateRecommendation(
  userQuery: 'Find coffee shops near me',
);

print(response); // Should print AI-generated response!
```

---

## 🐛 **Troubleshooting**

### **Function Not Found (404)**
- Make sure you deployed: `supabase functions deploy llm-chat`
- Check your project URL is correct

### **API Key Error**
- Verify secret is set: `supabase secrets list`
- Make sure key starts with `AIza...`
- Redeploy after setting secret: `supabase functions deploy llm-chat`

### **Rate Limit (429)**
- Free tier: 60 requests/minute
- Add retry logic or wait a minute

### **CORS Errors**
- Function already has CORS headers
- Make sure you're using the correct anon key

---

## ✅ **Success Checklist**

- [ ] Function deployed successfully
- [ ] API key secret set
- [ ] Test curl command works
- [ ] App can call LLM service
- [ ] AI responses are working

---

**Ready to deploy? Run the commands above!**


# Test Your LLM Integration

## ✅ Setup Complete!

Your Google Gemini LLM integration is now fully deployed and configured!

---

## 🧪 Test the Function

### **Option 1: Test from Terminal**

```bash
# Get your anon key from Supabase dashboard
# Go to: Settings → API → anon/public key

curl -X POST https://nfzlwgbvezwwrutqpedy.supabase.co/functions/v1/llm-chat \
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

### **Option 2: Test in Your Flutter App**

```dart
import 'package:spots/core/services/llm_service.dart';
import 'package:get_it/get_it.dart';

// Get the LLM service
final llmService = GetIt.instance<LLMService>();

// Test it
try {
  final response = await llmService.generateRecommendation(
    userQuery: 'Find coffee shops near me',
  );
  
  print('AI Response: $response');
  // Should print an AI-generated response!
} catch (e) {
  print('Error: $e');
}
```

### **Option 3: Test with Context**

```dart
import 'package:spots/core/services/llm_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get_it/get_it.dart';

final llmService = GetIt.instance<LLMService>();

// Get current location (if available)
final position = await Geolocator.getCurrentPosition();

final response = await llmService.generateRecommendation(
  userQuery: 'What should I do this weekend?',
  userContext: LLMContext(
    location: position,
    preferences: {
      'favoriteCategories': ['coffee', 'parks', 'restaurants'],
    },
  ),
);

print(response);
```

---

## 🎯 Use in Your UI

The `AICommandProcessor` automatically uses the LLM:

```dart
// In your widget
final response = await AICommandProcessor.processCommand(
  userInput,
  context,
  userContext: LLMContext(
    location: currentLocation,
  ),
);

// Display the response
showDialog(
  context: context,
  builder: (context) => AlertDialog(
    title: Text('AI Response'),
    content: Text(response),
  ),
);
```

---

## 📊 Monitor Usage

### **View Function Logs**

```bash
supabase functions logs llm-chat
```

### **Check Google AI Studio**

Visit https://makersuite.google.com/app/apikey to see:
- API usage statistics
- Rate limits
- Request history

---

## 🎉 You're All Set!

Your LLM integration is:
- ✅ Deployed to Supabase
- ✅ API key configured
- ✅ Ready to use in your app

**Start using it now!** 🚀

---

## 🐛 Troubleshooting

### **If you get errors:**

1. **Check API key is set:**
   ```bash
   supabase secrets list
   ```

2. **Check function logs:**
   ```bash
   supabase functions logs llm-chat
   ```

3. **Verify function is deployed:**
   ```bash
   supabase functions list
   ```

4. **Test with curl** (see Option 1 above)

---

**Happy coding!** 🎉


# Quick API Key Setup Guide

**Date:** January 2025  
**Purpose:** Step-by-step guide to set your API keys

---

## 🔑 **WHERE TO PUT YOUR API KEYS**

### **1. OpenWeatherMap API Key** 🌦️

You have **2 options** (choose one):

#### **Option A: Environment Variable (Recommended)**

Run your app with the API key as a parameter:

```bash
flutter run --dart-define=OPENWEATHERMAP_API_KEY=your_weather_api_key_here
```

**For VS Code/Android Studio:**
Create or edit `.vscode/launch.json` (or run configuration):
```json
{
  "version": "0.2.0",
  "configurations": [
    {
      "name": "SPOTS",
      "request": "launch",
      "type": "dart",
      "args": [
        "--dart-define=OPENWEATHERMAP_API_KEY=your_weather_api_key_here"
      ]
    }
  ]
}
```

#### **Option B: Direct in Code (Development Only)**

Edit `lib/weather_config.dart` line 34:

```dart
static String getApiKey() {
  if (apiKey.isNotEmpty) {
    return apiKey;
  }
  
  // ⚠️ WARNING: Only for development! Never commit this!
  return 'your_weather_api_key_here'; // ← Put your key here
}
```

**⚠️ IMPORTANT:** If you use Option B, make sure this file is in `.gitignore` and **never commit it with your key!**

---

### **2. Gemini API Key** 🤖

Set via Supabase secrets (for Edge Functions):

```bash
supabase secrets set GEMINI_API_KEY=your_gemini_api_key_here
```

**Verify it's set:**
```bash
supabase secrets list
```

You should see `GEMINI_API_KEY` in the list.

**Note:** This is stored in Supabase, not in your Flutter code. The Edge Functions will use it automatically.

---

## ✅ **QUICK SETUP STEPS**

### **Step 1: Set OpenWeatherMap Key**

**Easiest way (for development):**

1. Open `lib/weather_config.dart`
2. Find line 34: `return '';`
3. Replace with: `return 'your_weather_api_key_here';`
4. Save the file

**Or use environment variable:**
```bash
flutter run --dart-define=OPENWEATHERMAP_API_KEY=your_key
```

### **Step 2: Set Gemini Key**

```bash
cd /Users/reisgordon/SPOTS
supabase secrets set GEMINI_API_KEY=your_gemini_api_key_here
```

**Verify:**
```bash
supabase secrets list
```

---

## 🧪 **TEST IF IT WORKS**

### **Test OpenWeatherMap:**

Run your app and check the logs. You should see:
```
Collected current weather: Clear
```

Or check if the key is valid:
```dart
print('Weather API valid: ${WeatherConfig.isValid}'); // Should be true
```

### **Test Gemini:**

The Gemini key is used by Supabase Edge Functions. Test via:
```bash
curl -X POST https://your-project.supabase.co/functions/v1/llm-chat \
  -H "Authorization: Bearer YOUR_ANON_KEY" \
  -H "Content-Type: application/json" \
  -d '{"messages": [{"role": "user", "content": "Hello"}]}'
```

---

## 📝 **RECOMMENDED SETUP**

### **For Development:**

**Option 1: Quick & Easy (Direct in Code)**
- Edit `lib/weather_config.dart` line 34
- Set Gemini via `supabase secrets set`

**Option 2: Best Practice (Environment Variables)**
- Use `--dart-define` when running
- Set Gemini via `supabase secrets set`

### **For Production:**

**Always use environment variables:**
- Set `OPENWEATHERMAP_API_KEY` in CI/CD secrets
- Set `GEMINI_API_KEY` via Supabase secrets (already done)

---

## 🔒 **SECURITY REMINDER**

- ✅ **DO:** Use environment variables for production
- ✅ **DO:** Add `weather_config.dart` to `.gitignore` if you put key directly
- ❌ **DON'T:** Commit API keys to git
- ❌ **DON'T:** Share keys publicly

---

## 📋 **CHECKLIST**

- [ ] OpenWeatherMap API key set (in code or environment variable)
- [ ] Gemini API key set via `supabase secrets set`
- [ ] Verified keys work (check logs)
- [ ] `.gitignore` updated (if using direct code method)

---

## 🆘 **TROUBLESHOOTING**

### **OpenWeatherMap not working:**
- Check key is correct (no extra spaces)
- Wait 10-60 minutes after signup for activation
- Check `WeatherConfig.isValid` returns `true`

### **Gemini not working:**
- Verify secret is set: `supabase secrets list`
- Check Supabase project is correct
- Verify Edge Function is deployed


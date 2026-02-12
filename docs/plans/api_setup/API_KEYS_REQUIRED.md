# API Keys Required for SPOTS

**Date:** January 2025  
**Status:** Configuration Guide  
**Purpose:** List all API keys needed for the SPOTS app

---

## 🎯 **QUICK REFERENCE**

| API Service | Required | Free Tier | Status | Config File |
|------------|----------|-----------|--------|-------------|
| **Google Places API** | ✅ Yes | $200/month credit | Already configured | `lib/google_places_config.dart` |
| **OpenWeatherMap** | ✅ Yes | 1,000 calls/day | Needs setup | `lib/weather_config.dart` |
| **Supabase** | ✅ Yes | Free tier available | Already configured | `lib/supabase_config.dart` |
| **Firebase** | ✅ Yes | Free tier | Already configured | `lib/firebase_options.dart` |
| **Gemini API** | ⚠️ Optional | Free tier | Needs setup | Supabase secrets |

---

## 📋 **DETAILED API KEY REQUIREMENTS**

### **1. Google Places API** ✅ **ALREADY CONFIGURED**

**Purpose:** Location search, place details, nearby search

**Status:** ✅ Already has API key configured

**Configuration:**
- **File:** `lib/google_places_config.dart`
- **Environment Variable:** `GOOGLE_PLACES_API_KEY`
- **Current Status:** Has fallback key (should use environment variable in production)

**How to Set:**
```bash
flutter run --dart-define=GOOGLE_PLACES_API_KEY=your_api_key_here
```

**To Get API Key:**
1. Go to: https://console.cloud.google.com/
2. Create/select project
3. Enable "Places API"
4. Create API key
5. Set restrictions (recommended)

**Free Tier:** $200/month credit (usually sufficient)

**Cost:** Free up to $200/month, then pay-as-you-go

---

### **2. OpenWeatherMap API** ⚠️ **NEEDS SETUP**

**Purpose:** Weather data for continuous learning system

**Status:** ⚠️ **NOT YET CONFIGURED** - Needs API key

**Configuration:**
- **File:** `lib/weather_config.dart`
- **Environment Variable:** `OPENWEATHERMAP_API_KEY`
- **Current Status:** Empty (needs API key)

**How to Set:**
```bash
flutter run --dart-define=OPENWEATHERMAP_API_KEY=your_api_key_here
```

**To Get API Key:**
1. Go to: https://openweathermap.org/api
2. Sign up for free account
3. Navigate to "API keys" section
4. Copy your API key (starts with random characters)
5. Wait 10-60 minutes for key activation

**Free Tier:** 
- 1,000 calls/day
- 60 calls/minute
- Current weather + forecast

**Cost:** Free tier usually sufficient, $40/month for 100k calls if needed

**Required For:**
- Weather-based location recommendations
- Temporal pattern learning
- Context-aware suggestions

---

### **3. Supabase** ✅ **ALREADY CONFIGURED**

**Purpose:** Backend database, authentication, storage

**Status:** ✅ Already configured (needs credentials)

**Configuration:**
- **File:** `lib/supabase_config.dart`
- **Environment Variables:** 
  - `SUPABASE_URL`
  - `SUPABASE_ANON_KEY`
  - `SUPABASE_SERVICE_ROLE_KEY` (optional)

**How to Set:**
```bash
flutter run \
  --dart-define=SUPABASE_URL=https://your-project.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=your_anon_key \
  --dart-define=SUPABASE_SERVICE_ROLE_KEY=your_service_role_key
```

**To Get Credentials:**
1. Go to: https://supabase.com/
2. Create/select project
3. Go to Settings → API
4. Copy:
   - Project URL
   - `anon` public key
   - `service_role` secret key (keep secret!)

**Free Tier:** 
- 500MB database
- 1GB file storage
- 2GB bandwidth/month
- Unlimited API requests

**Cost:** Free tier usually sufficient for development

---

### **4. Firebase** ✅ **ALREADY CONFIGURED**

**Purpose:** Analytics, authentication, storage, real-time features

**Status:** ✅ Already configured via `firebase_options.dart`

**Configuration:**
- **File:** `lib/firebase_options.dart` (auto-generated)
- **Setup:** Via Firebase CLI (`firebase init`)

**To Set Up:**
1. Install Firebase CLI: `npm install -g firebase-tools`
2. Login: `firebase login`
3. Initialize: `firebase init`
4. Select features (Analytics, Auth, Firestore, Storage)
5. `firebase_options.dart` is auto-generated

**Free Tier:**
- Analytics: Free (unlimited events)
- Authentication: Free (50k MAU)
- Firestore: Free (1GB storage, 50k reads/day)
- Storage: Free (5GB storage, 1GB downloads/day)

**Cost:** Free tier usually sufficient

**Note:** Firebase uses project configuration files, not API keys directly

---

### **5. Gemini API** ⚠️ **OPTIONAL**

**Purpose:** LLM chat functionality (if using AI features)

**Status:** ⚠️ Optional - Only needed if using LLM features

**Configuration:**
- **Location:** Supabase Edge Function secrets
- **Set via:** `supabase secrets set GEMINI_API_KEY=your_key`

**How to Set:**
```bash
supabase secrets set GEMINI_API_KEY=your_api_key_here
```

**To Get API Key:**
1. Go to: https://makersuite.google.com/app/apikey
2. Click "Create API Key"
3. Copy key (starts with `AIza...`)

**Free Tier:** 
- 15 requests/minute
- 1,500 requests/day

**Cost:** Free tier available, then pay-as-you-go

**Required For:** LLM chat features (optional)

---

## 🚀 **QUICK SETUP GUIDE**

### **Minimum Required (Core Functionality):**

1. **Google Places API** ✅ (Already configured)
2. **Supabase** ✅ (Needs credentials)
3. **Firebase** ✅ (Already configured)

### **Recommended (Full Features):**

4. **OpenWeatherMap** ⚠️ (Needs API key)
5. **Gemini API** ⚠️ (Optional, for AI features)

---

## 📝 **SETUP COMMANDS**

### **For Development:**

```bash
# Set all API keys at once
flutter run \
  --dart-define=GOOGLE_PLACES_API_KEY=your_google_key \
  --dart-define=OPENWEATHERMAP_API_KEY=your_weather_key \
  --dart-define=SUPABASE_URL=https://your-project.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=your_supabase_anon_key
```

### **For Production:**

Use environment variables or CI/CD secrets - **never commit API keys to git!**

---

## 🔒 **SECURITY BEST PRACTICES**

### **✅ DO:**
- Use environment variables (`--dart-define`)
- Set API key restrictions in Google Cloud Console
- Use `.gitignore` to exclude config files with keys
- Rotate keys regularly
- Use different keys for dev/staging/production

### **❌ DON'T:**
- Commit API keys to git
- Share keys in public repositories
- Use production keys in development
- Hardcode keys in source files (except temporary dev)

---

## 📊 **COST SUMMARY**

| Service | Free Tier | Estimated Monthly Cost |
|---------|-----------|------------------------|
| Google Places | $200 credit | $0-20 (usually free) |
| OpenWeatherMap | 1k calls/day | $0 (free tier sufficient) |
| Supabase | 500MB DB | $0 (free tier sufficient) |
| Firebase | Generous limits | $0 (free tier sufficient) |
| Gemini API | 1.5k requests/day | $0 (free tier sufficient) |

**Total Estimated Cost:** **$0-20/month** (mostly free tiers)

---

## ✅ **CHECKLIST**

- [x] Google Places API - Already configured
- [ ] OpenWeatherMap API - **NEEDS API KEY**
- [x] Supabase - Already configured (needs credentials)
- [x] Firebase - Already configured
- [ ] Gemini API - Optional (needs API key if using)

---

## 🆘 **TROUBLESHOOTING**

### **OpenWeatherMap Not Working:**
- Check API key is set: `WeatherConfig.isValid`
- Wait 10-60 minutes after signup for key activation
- Check rate limits (60 calls/minute)

### **Google Places Not Working:**
- Verify API key in Google Cloud Console
- Check API is enabled (Places API)
- Verify billing is enabled (even for free tier)

### **Supabase Not Connecting:**
- Verify URL format: `https://xxx.supabase.co`
- Check anon key is correct
- Verify project is active

---

## 📚 **RESOURCES**

- **Google Places API:** https://console.cloud.google.com/
- **OpenWeatherMap:** https://openweathermap.org/api
- **Supabase:** https://supabase.com/dashboard
- **Firebase:** https://console.firebase.google.com/
- **Gemini API:** https://makersuite.google.com/app/apikey

---

## 📝 **SUMMARY**

**Required API Keys:**
1. ✅ **Google Places API** - Already configured
2. ⚠️ **OpenWeatherMap** - **NEEDS SETUP** (for weather features)
3. ✅ **Supabase** - Already configured (needs credentials)
4. ✅ **Firebase** - Already configured
5. ⚠️ **Gemini API** - Optional (for AI features)

**Priority:**
- **High:** Google Places (already done), Supabase (needs credentials)
- **Medium:** OpenWeatherMap (for continuous learning)
- **Low:** Gemini API (optional AI features)

**Total Cost:** Mostly free tiers, ~$0-20/month


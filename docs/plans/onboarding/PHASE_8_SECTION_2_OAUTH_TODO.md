# Phase 8 Section 2: OAuth Flows & Platform APIs - TODO

**Date:** December 23, 2025  
**Status:** 📋 Pending Implementation  
**Priority:** P2 - Enhancement (Structure complete, OAuth flows pending)  
**Related:** `docs/plans/onboarding/ONBOARDING_PROCESS_PLAN.md` - Phase 2

---

## 🎯 **CURRENT STATUS**

**✅ Completed:**
- `SocialMediaConnection` model created
- `SocialMediaConnectionService` structure complete
- Service registered in dependency injection
- UI integration complete (SocialMediaConnectionPage, OnboardingPage, AILoadingPage)
- Connection management (connect/disconnect) structure in place
- **OAuth flows implemented for Google, Instagram, Facebook**
- **Deep linking configured (Android + iOS)**
- **Token encryption using flutter_secure_storage**
- **API integrations implemented (with placeholder fallback)**
  - Google profile data fetching
  - Instagram profile data fetching
  - Facebook profile data fetching
  - Instagram follows fetching
  - Facebook friends fetching

**⏳ Pending:**
- Google Places API full integration (saved places, reviews, photos) - structure in place, needs API setup
- Enhanced error handling and rate limit management
- Token refresh implementation

---

## 📋 **TODO: OAuth Flow Implementations**

### **2.2.1: Google OAuth Flow**

**Files to Update:**
- `lib/core/services/social_media_connection_service.dart` - `connectPlatform()` method for 'google'

**Implementation Steps:**
1. Add `google_sign_in` package to `pubspec.yaml` (or use `oauth2` package)
2. Implement Google OAuth flow:
   - Launch Google Sign-In
   - Request scopes: `profile`, `email`, `https://www.googleapis.com/auth/places`, `https://www.googleapis.com/auth/photos`
   - Handle OAuth callback
   - Exchange authorization code for access token
   - Store access token and refresh token (encrypted)
3. Fetch initial profile data after connection
4. Update `connectPlatform()` to use real OAuth

**Dependencies:**
- Google OAuth credentials (Client ID, Client Secret)
- `google_sign_in` package or `oauth2` package

**Reference:**
- Google OAuth 2.0 Documentation
- Google Places API Documentation
- Google Photos API Documentation

---

### **2.2.2: Instagram Graph API OAuth Flow**

**Files to Update:**
- `lib/core/services/social_media_connection_service.dart` - `connectPlatform()` method for 'instagram'

**Implementation Steps:**
1. Add Instagram Graph API OAuth support
2. Implement Instagram OAuth flow:
   - Launch Instagram OAuth URL
   - Request permissions: `user_profile`, `user_media`
   - Handle OAuth callback
   - Exchange authorization code for access token
   - Store access token and refresh token (encrypted)
3. Fetch initial profile data after connection
4. Update `connectPlatform()` to use real OAuth

**Dependencies:**
- Instagram App ID and App Secret
- Instagram Graph API access
- OAuth redirect URI configured in Instagram app settings

**Reference:**
- Instagram Graph API Documentation
- Instagram Basic Display API (alternative)

---

### **2.2.3: Facebook Graph API OAuth Flow**

**Files to Update:**
- `lib/core/services/social_media_connection_service.dart` - `connectPlatform()` method for 'facebook'

**Implementation Steps:**
1. Add Facebook Graph API OAuth support
2. Implement Facebook OAuth flow:
   - Launch Facebook OAuth URL
   - Request permissions: `public_profile`, `email`, `user_friends`
   - Handle OAuth callback
   - Exchange authorization code for access token
   - Store access token and refresh token (encrypted)
3. Fetch initial profile data after connection
4. Update `connectPlatform()` to use real OAuth

**Dependencies:**
- Facebook App ID and App Secret
- Facebook Graph API access
- OAuth redirect URI configured in Facebook app settings

**Reference:**
- Facebook Graph API Documentation
- Facebook Login Documentation

---

## 📋 **TODO: Platform API Integrations**

### **2.3.1: Google Places API Integration**

**Files to Update:**
- `lib/core/services/social_media_connection_service.dart` - `fetchGooglePlacesData()` method

**Implementation Steps:**
1. Use Google Places API (New) to fetch:
   - Saved places from user's Google Maps
   - Reviews written by user
   - Photos uploaded by user
2. Use Google My Business API for business reviews
3. Parse and structure data for `SocialMediaVibeAnalyzer`
4. Handle rate limits and pagination

**Dependencies:**
- Google Places API key
- Google My Business API access
- OAuth token with appropriate scopes

**Reference:**
- Google Places API (New) Documentation
- Google My Business API Documentation

---

### **2.3.2: Instagram Graph API Integration**

**Files to Update:**
- `lib/core/services/social_media_connection_service.dart` - `fetchProfileData()` and `fetchFollows()` methods for 'instagram'

**Implementation Steps:**
1. Use Instagram Graph API to fetch:
   - User profile (username, profile picture, bio)
   - User's follows/followers
   - User's posts (for vibe analysis)
2. Parse and structure data for `SocialMediaVibeAnalyzer`
3. Handle rate limits and pagination

**Dependencies:**
- Instagram Graph API access token
- Instagram Business Account (for Graph API)

**Reference:**
- Instagram Graph API Documentation

---

### **2.3.3: Facebook Graph API Integration**

**Files to Update:**
- `lib/core/services/social_media_connection_service.dart` - `fetchProfileData()` and `fetchFollows()` methods for 'facebook'

**Implementation Steps:**
1. Use Facebook Graph API to fetch:
   - User profile (name, email, profile picture)
   - User's friends (with privacy permissions)
   - User's pages/likes
2. Parse and structure data for `SocialMediaVibeAnalyzer`
3. Handle rate limits and pagination

**Dependencies:**
- Facebook Graph API access token
- Appropriate permissions granted

**Reference:**
- Facebook Graph API Documentation

---

## 🔒 **Security Considerations**

### **Token Encryption (Phase 8.3)**

**Current State:**
- Tokens stored in `StorageService` (not encrypted)
- TODO comments indicate encryption needed

**Future Implementation:**
- Use `flutter_secure_storage` or encrypted storage
- Encrypt tokens before storing
- Decrypt tokens when retrieving
- Handle token refresh securely

**Reference:**
- Phase 8.3 Security Implementation
- `lib/core/services/field_encryption_service.dart` (if exists)

---

## 📊 **Implementation Priority**

1. **High Priority:**
   - Google OAuth (most users likely to connect)
   - Google Places API integration (most valuable data)

2. **Medium Priority:**
   - Instagram OAuth and API
   - Facebook OAuth and API

3. **Low Priority:**
   - Twitter OAuth (if needed)
   - TikTok OAuth (if needed)
   - LinkedIn OAuth (if needed)

---

## 🧪 **Testing Requirements**

When implementing OAuth flows, add tests for:
- OAuth flow completion
- Token storage and retrieval
- Token refresh
- API data fetching
- Error handling (OAuth failures, API errors)
- Privacy (agentId usage, no userId exposure)

---

## 📚 **Related Documentation**

- `docs/plans/onboarding/ONBOARDING_PROCESS_PLAN.md` - Main onboarding plan
- `lib/core/services/social_media_connection_service.dart` - Service implementation
- `lib/core/models/social_media_connection.dart` - Connection model

---

**Status:** 📋 Ready for OAuth Implementation  
**Last Updated:** December 23, 2025  
**Next Steps:** Implement Google OAuth flow first (highest priority)


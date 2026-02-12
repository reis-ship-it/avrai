# OAuth Redirect URI Setup Guide for AVRAI

**Date:** January 7, 2025  
**Status:** ✅ Active Guide  
**Purpose:** Step-by-step guide to update OAuth redirect URIs to `avrai://oauth` in all provider consoles

---

## Overview

This guide walks you through updating OAuth redirect URIs in each provider's developer console to use the new AVRAI deep link scheme: `avrai://oauth`.

---

## Redirect URI Format

**New Format:** `avrai://oauth`

**Previous Format:** `spots://oauth/[platform]/callback`

**Why Changed:**
- Matches new app identity (`avrai://` instead of `spots://`)
- Simpler format (no platform-specific paths)
- Platform information passed via query parameter: `avrai://oauth?platform=google&code=...&state=...`

---

## Provider-Specific Instructions

### 1. Google Cloud Console

**Where to Update:**
- Google Cloud Console → APIs & Services → Credentials → OAuth 2.0 Client IDs

**Steps:**

1. Go to: https://console.cloud.google.com/apis/credentials
2. Sign in with your Google account
3. Select your project (or create one)
4. Find your **OAuth 2.0 Client ID** (iOS and/or Android)
5. Click **Edit** (pencil icon)
6. Under **Authorized redirect URIs**, add:
   ```
   avrai://oauth
   ```
7. If you have the old `spots://oauth/...` URIs, remove them
8. Click **Save**

**For iOS OAuth Client:**
- Also verify **Bundle ID**: `com.avrai.app`
- Update if needed

**For Android OAuth Client:**
- Verify **Package name**: `com.avrai.app`
- Verify **SHA-1 certificate fingerprint** (get from: `keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android`)

---

### 2. Facebook/Meta for Developers

**Where to Update:**
- Meta for Developers → Your App → Settings → Basic → App Domains

**Steps:**

1. Go to: https://developers.facebook.com/apps/
2. Sign in with your Facebook account
3. Select your app (or create one)
4. Go to **Settings** → **Basic**
5. Scroll to **App Domains**
6. Under **Valid OAuth Redirect URIs**, add:
   ```
   avrai://oauth
   ```
7. Remove old `spots://oauth/...` URIs if present
8. Click **Save Changes**

**Additional Setup:**
- Go to **Settings** → **Basic** → **Add Platform** → **iOS**
  - Bundle ID: `com.avrai.app`
- Go to **Settings** → **Basic** → **Add Platform** → **Android**
  - Package Name: `com.avrai.app`
  - Class Name: `com.avrai.app.MainActivity`
  - Key Hashes: Add your app's key hash (see Android setup below)

---

### 3. Twitter/X Developer Portal

**Where to Update:**
- Twitter Developer Portal → Your App → Settings → User authentication settings

**Steps:**

1. Go to: https://developer.twitter.com/en/portal/dashboard
2. Sign in with your Twitter/X account
3. Select your app (or create one)
4. Go to **Settings** → **User authentication settings**
5. Under **Callback URI / Redirect URL**, add:
   ```
   avrai://oauth
   ```
6. Remove old `spots://oauth/...` URIs if present
7. Click **Save**

**Additional Setup:**
- **App permissions:** Enable required scopes (read, write, etc.)
- **Type of App:** Mobile app

---

### 4. Instagram Basic Display API

**Where to Update:**
- Meta for Developers → Your App → Products → Instagram Basic Display → Settings

**Steps:**

1. Go to: https://developers.facebook.com/apps/
2. Sign in with your Facebook account
3. Select your app
4. Go to **Products** → **Instagram Basic Display**
5. Click **Settings**
6. Under **Valid OAuth Redirect URIs**, add:
   ```
   avrai://oauth
   ```
7. Remove old `spots://oauth/...` URIs if present
8. Click **Save Changes**

---

### 5. Reddit API

**Where to Update:**
- Reddit Apps → Your App → Edit → Redirect URI

**Steps:**

1. Go to: https://www.reddit.com/prefs/apps
2. Sign in with your Reddit account
3. Find your app (or create one: **create app**)
4. Click **Edit**
5. Under **Redirect URI**, update to:
   ```
   avrai://oauth
   ```
6. Remove old `spots://oauth/...` URIs if present
7. Click **Update app**

---

### 6. TikTok for Developers

**Where to Update:**
- TikTok for Developers → Your App → Manage → Basic Information → Redirect URI

**Steps:**

1. Go to: https://developers.tiktok.com/apps/
2. Sign in with your TikTok account
3. Select your app (or create one)
4. Go to **Manage** → **Basic Information**
5. Under **Redirect URI**, add:
   ```
   avrai://oauth
   ```
6. Remove old `spots://oauth/...` URIs if present
7. Click **Save**

---

### 7. LinkedIn Developer Portal

**Where to Update:**
- LinkedIn Developer Portal → Your App → Auth → Redirect URLs

**Steps:**

1. Go to: https://www.linkedin.com/developers/apps
2. Sign in with your LinkedIn account
3. Select your app (or create one)
4. Go to **Auth** tab
5. Under **Redirect URLs**, add:
   ```
   avrai://oauth
   ```
6. Remove old `spots://oauth/...` URIs if present
7. Click **Update**

---

### 8. Pinterest Developers

**Where to Update:**
- Pinterest Developers → Your App → Settings → Redirect URIs

**Steps:**

1. Go to: https://developers.pinterest.com/apps/
2. Sign in with your Pinterest account
3. Select your app (or create one)
4. Go to **Settings**
5. Under **Redirect URIs**, add:
   ```
   avrai://oauth
   ```
6. Remove old `spots://oauth/...` URIs if present
7. Click **Save**

---

### 9. Tumblr Developer

**Where to Update:**
- Tumblr Developer → Your App → Settings → Callback URL

**Steps:**

1. Go to: https://www.tumblr.com/oauth/apps
2. Sign in with your Tumblr account
3. Find your app (or register new application)
4. Under **Application Website** / **Default Callback URL**, update to:
   ```
   avrai://oauth
   ```
5. Remove old `spots://oauth/...` URIs if present
6. Click **Register**

---

### 10. Are.na Developer

**Where to Update:**
- Are.na Developer → Your App → Settings → Redirect URI

**Steps:**

1. Go to: https://www.are.na/oauth/applications
2. Sign in with your Are.na account
3. Find your app (or create new application)
4. Under **Redirect URI**, update to:
   ```
   avrai://oauth
   ```
5. Remove old `spots://oauth/...` URIs if present
6. Click **Update Application**

---

## Android Key Hash Setup (for Facebook/Meta)

**Required for:** Facebook/Meta OAuth

**Get Your Key Hash:**

For debug keystore:
```bash
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android | grep SHA1
```

For release keystore:
```bash
keytool -list -v -keystore path/to/your/release.keystore -alias your_alias | grep SHA1
```

**Convert SHA-1 to Key Hash:**

1. Copy the SHA-1 fingerprint (e.g., `AB:CD:EF:...`)
2. Remove colons and convert to lowercase: `abcdef...`
3. Use this online tool or OpenSSL:
   ```bash
   echo -n "YOUR_SHA1_HEX" | xxd -r -p | openssl base64
   ```

**Add to Facebook:**
1. Go to Meta for Developers → Your App → Settings → Basic → Android
2. Paste the key hash under **Key Hashes**
3. Click **Save Changes**

---

## Verification Checklist

After updating each provider, verify:

- [ ] **Google Cloud Console:** `avrai://oauth` added to redirect URIs
- [ ] **Facebook/Meta:** `avrai://oauth` added, iOS bundle ID set, Android package name set, key hash added
- [ ] **Twitter/X:** `avrai://oauth` added to callback URIs
- [ ] **Instagram:** `avrai://oauth` added to redirect URIs
- [ ] **Reddit:** Redirect URI updated to `avrai://oauth`
- [ ] **TikTok:** `avrai://oauth` added to redirect URIs
- [ ] **LinkedIn:** `avrai://oauth` added to redirect URLs
- [ ] **Pinterest:** `avrai://oauth` added to redirect URIs
- [ ] **Tumblr:** Callback URL updated to `avrai://oauth`
- [ ] **Are.na:** Redirect URI updated to `avrai://oauth`
- [ ] **Old URIs removed:** All `spots://oauth/...` URIs removed from all providers
- [ ] **Code updated:** OAuth config uses `avrai://oauth` (✅ Already done)

---

## Testing OAuth Flow

After updating redirect URIs:

1. **Test with each provider:**
   - Open app → Connect [Provider]
   - OAuth flow should redirect to `avrai://oauth?platform=[provider]&code=...`
   - App should handle the deep link and complete OAuth

2. **Check logs:**
   ```dart
   // Should see in logs:
   📥 Received deep link: avrai://oauth?platform=google&code=...
   ✅ OAuth callback received for platform: google
   ```

3. **Verify token exchange:**
   - OAuth callback should complete successfully
   - Tokens should be stored securely
   - Connection should be saved

---

## Troubleshooting

### Error: "Redirect URI mismatch"

**Solution:**
- Verify redirect URI exactly matches: `avrai://oauth`
- Check for typos (extra spaces, wrong scheme, etc.)
- Some providers require exact match (no trailing slashes)

### Error: "Invalid redirect URI format"

**Solution:**
- Some providers may not support custom URL schemes
- May need to use a web redirect that then redirects to `avrai://oauth`
- Example: `https://your-domain.com/oauth/callback` → redirects to `avrai://oauth?code=...`

### Deep link not opening app

**Solution:**
- Verify iOS Info.plist has `avrai://` scheme configured (✅ Already done)
- Verify AndroidManifest.xml has `avrai://oauth` intent filter (✅ Already done)
- Reinstall app after manifest changes
- Test deep link: `xcrun simctl openurl booted avrai://oauth?platform=google&code=test`

### OAuth flow works but platform not detected

**Solution:**
- Verify `platform` query parameter is included in OAuth redirect
- Check deep link handler logs for received parameters
- Update OAuth authorization URL to include `platform` in state or callback

---

## Quick Reference

**Redirect URI:** `avrai://oauth`

**Expected Format:**
```
avrai://oauth?platform=[provider]&code=[auth_code]&state=[csrf_token]
```

**Providers to Update:**
1. Google Cloud Console
2. Facebook/Meta
3. Twitter/X
4. Instagram (Meta)
5. Reddit
6. TikTok
7. LinkedIn
8. Pinterest
9. Tumblr
10. Are.na

---

**Last Updated:** January 7, 2025  
**Status:** ✅ Code updated, ⏳ Pending provider console updates

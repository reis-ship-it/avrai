# Google Play Console Setup Guide for AVRAI

**Date:** January 7, 2025  
**Status:** ⏳ Manual Registration Required  
**Purpose:** Step-by-step guide to register Google Play Developer account and create AVRAI app

---

## Overview

This guide walks you through registering a Google Play Developer account and creating the AVRAI app listing in Google Play Console.

---

## Prerequisites

1. **Google Account** (Gmail account)
2. **Payment Method** (Credit/Debit card)
3. **$25 One-Time Registration Fee**
4. **Identity Verification Documents** (may be required)

---

## Step-by-Step Registration

### Step 1: Sign Up for Google Play Developer Account

1. Go to: https://play.google.com/console/signup
2. **Sign in** with your Google account
3. Click **"Create account"** or **"Continue"**

### Step 2: Complete Registration Form

Fill in the required information:

1. **Account Details:**
   - Developer name: `AVRAI` (or your company name)
   - Email: Your Google account email
   - Phone number: Verified phone number

2. **Payment Information:**
   - Pay **$25 one-time registration fee**
   - Credit/Debit card required

3. **Developer Program Policies:**
   - Read and accept the **Developer Program Policies**
   - Read and accept the **Distribution Agreement**
   - Confirm you are not in a restricted country

4. **Identity Verification** (if prompted):
   - May require government-issued ID
   - Can take 1-3 business days to verify

### Step 3: Wait for Account Activation

- **Instant:** Usually activates immediately after payment
- **Delayed:** May require manual review (1-3 business days)
- Check email for activation confirmation

---

## Step 4: Create New App in Play Console

Once your account is activated:

1. Go to: https://play.google.com/console/u/0/developers/
2. Click **"Create app"** (top right)
3. Fill in the app details:

### App Details:

- **App name:** `AVRAI`
- **Default language:** `English (United States)`
- **App or game:** Select `App`
- **Free or paid:** `Free` (or `Paid` if you plan to charge)
- Click **"Create app"**

### Store Listing Setup:

1. **App name:** `AVRAI`
2. **Short description:** (max 80 characters)
   ```
   AI2AI-powered app for discovering meaningful places and building authentic communities.
   ```
3. **Full description:** (max 4000 characters)
   ```
   AVRAI (Authentic Value Recognition Application) is an AI2AI-powered, offline-first mobile application that helps people discover meaningful places, build authentic communities, and find belonging through personalized recommendations and event hosting.

   Features:
   - Offline-first architecture for privacy and reliability
   - AI2AI communication between devices (no p2p)
   - Personalized spot recommendations
   - Event hosting and discovery
   - Secure, private personality learning

   AVRAI helps you open doors to places where you truly belong.
   ```

4. **App icon:** Upload app icon (512x512 PNG, no transparency)
5. **Feature graphic:** Upload feature graphic (1024x500 PNG/JPG)
6. **Screenshots:** Upload screenshots (at least 2, max 8)

### Technical Setup:

1. **Package name:** `com.avrai.app`
   - ⚠️ **Must match** the package name in `android/app/build.gradle`
   - Already configured: `applicationId "com.avrai.app"`

2. **App signing:** 
   - Use Google Play App Signing (recommended)
   - Upload your signing key (or let Google manage it)

3. **Release channels:**
   - Internal testing (up to 100 testers)
   - Closed testing (up to 1000 testers per track)
   - Open testing (unlimited testers)
   - Production (public release)

---

## Step 5: Complete Required Forms

Before you can publish, complete:

1. **App content ratings:**
   - Complete IARC questionnaire
   - Submit for rating

2. **Privacy policy:**
   - Required URL for privacy policy
   - Must cover data collection, usage, sharing

3. **Target audience and content:**
   - Select target age group
   - Declare content (ads, in-app purchases, etc.)

4. **Data safety:**
   - Declare data collection practices
   - Types of data collected
   - How data is used/shared

5. **Ads:**
   - Declare if app shows ads
   - Ad content settings

6. **App access:**
   - Declare if app is restricted
   - Eligibility requirements

---

## Step 6: Upload First Build

1. **Create internal test release:**
   - Go to **Release** → **Testing** → **Internal testing**
   - Click **"Create new release"**

2. **Upload APK/AAB:**
   ```bash
   # Build release bundle
   flutter build appbundle --release
   ```
   - Upload `build/app/outputs/bundle/release/app-release.aab`

3. **Release notes:**
   - Add release notes for testers
   - Click **"Save"** → **"Review release"** → **"Start rollout to Internal testing"**

---

## Verification Checklist

Before submitting for review, verify:

- [ ] App name matches: `AVRAI`
- [ ] Package name is: `com.avrai.app`
- [ ] App icon uploaded (512x512)
- [ ] Feature graphic uploaded (1024x500)
- [ ] At least 2 screenshots uploaded
- [ ] Short description (≤80 chars)
- [ ] Full description (≤4000 chars)
- [ ] Privacy policy URL provided
- [ ] Content rating completed
- [ ] Data safety form completed
- [ ] App signing configured
- [ ] Test build uploaded successfully
- [ ] Release notes added

---

## Important Notes

### Package Name Consistency

**CRITICAL:** The package name in Google Play Console **MUST match** exactly with:
- `android/app/build.gradle`: `applicationId "com.avrai.app"`
- `android/app/src/main/AndroidManifest.xml`: `package="com.avrai.app"`
- `android/app/src/main/kotlin/com/avrai/app/` (folder structure)

✅ Already configured in your project!

### Firebase Integration

The Android Firebase config file (`android/app/google-services.json`) is already configured with:
- **Package name:** `com.avrai.app`
- **Project:** `avrai1`

This will automatically connect once the app is created in Play Console.

---

## Next Steps After Account Registration

Once your Google Play Developer account is active:

1. **Create the app** in Play Console (follow Step 4 above)
2. **Complete store listing** (screenshots, descriptions, etc.)
3. **Complete required forms** (content rating, privacy, data safety)
4. **Upload test build** via internal testing
5. **Test thoroughly** before production release

---

## Troubleshooting

### Error: "Package name already exists"

**Solution:**
- The package name `com.avrai.app` must be unique across all Google Play apps
- If already taken, you'll need to use a different package name (e.g., `com.avrai.mobile`)
- ⚠️ **This would require updating** all Android config files

### Error: "App signing key mismatch"

**Solution:**
- Use Google Play App Signing (let Google manage keys)
- Or upload your existing signing key if migrating

### Identity Verification Pending

**Solution:**
- Check email for verification requests
- Provide requested documents (government ID, etc.)
- Usually resolves within 1-3 business days

---

## Quick Reference Commands

```bash
# Build release bundle for Google Play
flutter build appbundle --release

# Output location:
# build/app/outputs/bundle/release/app-release.aab

# Build APK for testing (if needed)
flutter build apk --release

# Output location:
# build/app/outputs/flutter-apk/app-release.apk
```

---

## Resources

- **Google Play Console:** https://play.google.com/console/
- **Developer Policies:** https://play.google.com/about/developer-content-policy/
- **App Signing:** https://support.google.com/googleplay/android-developer/answer/9842756
- **Flutter Android Deployment:** https://docs.flutter.dev/deployment/android

---

**Last Updated:** January 7, 2025  
**Status:** ⏳ Waiting for Google Play Developer account registration

---

## Summary

**Current Status:**
- ✅ Firebase Android config configured (`com.avrai.app`)
- ✅ Android project configured with correct package name
- ⏳ **Pending:** Google Play Developer account registration ($25 fee)
- ⏳ **Pending:** App creation in Play Console
- ⏳ **Pending:** Store listing setup
- ⏳ **Pending:** First build upload

**Estimated Time:**
- Account registration: 10-15 minutes + verification time
- App creation: 5-10 minutes
- Store listing: 30-60 minutes (depends on assets ready)
- First build upload: 10-15 minutes

**Total estimated setup time:** 1-2 hours (excluding account verification delays)

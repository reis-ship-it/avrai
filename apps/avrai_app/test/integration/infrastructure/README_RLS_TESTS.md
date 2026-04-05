# RLS Policy Tests Setup Guide

## Overview

The RLS (Row Level Security) policy tests verify that Supabase security policies are correctly configured and enforced. These tests require a Supabase connection to run.

## Setup

### 1. Get Supabase Credentials

1. Go to your Supabase project: https://supabase.com/dashboard
2. Navigate to **Settings** → **API**
3. Copy the following:
   - **Project URL** (e.g., `https://xxxxx.supabase.co`)
   - **anon public** key
   - **service_role** key (for admin tests - keep secret!)

### 2. Set Environment Variables

#### Option A: Environment Variables (Recommended for CI/CD)

```bash
export SUPABASE_URL="https://your-project.supabase.co"
export SUPABASE_ANON_KEY="your-anon-key-here"
export SUPABASE_SERVICE_ROLE_KEY="your-service-role-key-here"  # Optional, for admin tests
```

#### Option B: Dart Define Flags (For Local Testing)

```bash
flutter test test/integration/rls_policy_test.dart \
  --dart-define=SUPABASE_URL=https://your-project.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=your-anon-key-here \
  --dart-define=SUPABASE_SERVICE_ROLE_KEY=your-service-role-key-here
```

### 3. Run Tests

```bash
flutter test test/integration/rls_policy_test.dart
```

## Test Behavior

- **With Credentials:** Tests will connect to Supabase and verify RLS policies
- **Without Credentials:** Tests will be skipped gracefully (no failures)

## Test Coverage

The tests verify:

1. **User Access Control**
   - Users can access their own data
   - Users cannot access other users' data
   - Users can update their own data
   - Users cannot update other users' data

2. **Admin Access Control**
   - Admin access with privacy filtering
   - Personal data is filtered from admin queries

3. **Unauthorized Access Blocking**
   - Unauthenticated access is blocked
   - Invalid tokens are rejected
   - RLS policies are enforced on all tables

4. **Service Role Access**
   - Service role can access data for system operations
   - Service role access is logged for audit

## Notes

- Tests require RLS policies to be set up in your Supabase database
- Some tests require test users to be created (marked with TODO comments)
- Service role tests require `SUPABASE_SERVICE_ROLE_KEY` to be set
- Tests will skip gracefully if credentials are not available

## Security Warning

⚠️ **Never commit Supabase credentials to version control!**

- Use environment variables or dart-define flags
- Add `.env` files to `.gitignore`
- Never commit `supabase_config.dart` with real credentials


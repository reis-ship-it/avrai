# Admin Backend Connections Test

Integration tests verify all backend integrations for the god-mode admin system.

## Prerequisites

1. **Supabase Configuration**: Ensure your Supabase credentials are configured in `lib/supabase_config.dart` (optional - tests work with or without real Supabase)
2. **Dependencies**: All required packages should be installed (`flutter pub get`)

## Running the Tests

### Flutter Integration Tests (Recommended)

```bash
# From project root
flutter test test/integration/admin_backend_connections_integration_test.dart
```

### With Real Supabase Connection

To test with real Supabase connections:

```bash
flutter test test/integration/admin_backend_connections_integration_test.dart \
  --dart-define=SUPABASE_URL=... \
  --dart-define=SUPABASE_ANON_KEY=...
```

Tests will gracefully skip Supabase-dependent tests if credentials are not available.

## What Gets Tested

### 1. Supabase Initialization ✅
- Verifies Supabase client can be initialized
- Checks connection to Supabase backend

### 2. Supabase Service ✅
- Tests `SupabaseService` connection
- Verifies client access

### 3. Admin Services Initialization ✅
- `ConnectionMonitor`
- `AdminAuthService`
- `AdminCommunicationService`
- `BusinessAccountService`
- `PredictiveAnalytics`
- `AdminGodModeService`

### 4. Database Queries ✅
- Users table
- Spots table
- Spot lists table
- User respects table
- Business accounts table (if exists)

### 5. Admin God-Mode Service Methods ✅
- Authorization checks
- Dashboard data retrieval
- User search
- Business accounts retrieval

### 6. Privacy Filtering ✅
- Verifies user search returns only ID and AI signature
- Ensures no personal data leaks

### 7. AI Data Streams ✅
- Reverse index functionality
- AI signature lookups
- Session retrieval

## Expected Test Results

The integration tests verify:
- ✅ Supabase service initialization
- ✅ Admin services initialization
- ✅ Authorization enforcement
- ✅ AI signature lookups
- ✅ Error handling
- ✅ Service disposal

All tests should pass. Tests that require Supabase will gracefully skip if credentials are not available.

## Troubleshooting

### "Supabase URL or Anon Key not configured"
- Check `lib/supabase_config.dart` has valid credentials
- Ensure environment variables are set if using them

### "Unauthorized" errors
- This is expected if you haven't logged in as an admin
- The tests verify that authorization is properly enforced
- To test with authorization, log in first using `AdminAuthService`

### "Table not found" warnings
- Some tables may not exist yet (e.g., `business_accounts`)
- This is normal and the tests handle it gracefully
- Create the tables in Supabase if you need them

### Connection timeouts
- Check your internet connection
- Verify Supabase project is active
- Check Supabase dashboard for any service issues

## Integration with CI/CD

You can integrate the integration tests into your CI/CD pipeline:

```yaml
# Example GitHub Actions
- name: Test Admin Backend Connections
  run: flutter test test/integration/admin_backend_connections_integration_test.dart
  env:
    SUPABASE_URL: ${{ secrets.SUPABASE_URL }}
    SUPABASE_ANON_KEY: ${{ secrets.SUPABASE_ANON_KEY }}
```

## Next Steps

After running the tests successfully:

1. **Test with Real Data**: Log in as admin and test with actual user data
2. **Monitor Performance**: Check query performance with large datasets
3. **Security Audit**: Verify privacy filtering with real user data
4. **Load Testing**: Test with multiple concurrent admin users


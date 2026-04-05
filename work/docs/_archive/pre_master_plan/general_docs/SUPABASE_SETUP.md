# Supabase Setup for SPOTS

This guide will help you set up a real Supabase backend for your SPOTS project.

## 🚀 Quick Start

### 1. Install Supabase CLI

```bash
# Using npm
npm install -g supabase

# Using Homebrew (macOS)
brew install supabase/tap/supabase
```

### 2. Run the Setup Script

```bash
# Make the script executable (if not already)
chmod +x scripts/setup_supabase.sh

# Run the setup script
./scripts/setup_supabase.sh
```

### 3. Create a Supabase Project

1. Go to [https://supabase.com](https://supabase.com)
2. Sign up or log in
3. Click "New Project"
4. Choose your organization
5. Enter project details:
   - **Name**: `spots-backend` (or your preferred name)
   - **Database Password**: Choose a strong password
   - **Region**: Choose closest to your users
6. Click "Create new project"

### 4. Get Your Project Credentials

1. In your Supabase project dashboard, go to **Settings** → **API**
2. Copy the following values:
   - **Project URL** (e.g., `https://your-project-id.supabase.co`)
   - **anon public** key
   - **service_role** key (keep this secret!)

### 5. Update Configuration

Update config via dart-defines (recommended) or set `lib/supabase_config.dart` defaults for local only. Prefer environment/CI variables for credentials.

```dart
// Run with defines (recommended):
// flutter run --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...
// See lib/supabase_config.dart for keys.
```

### 6. Test Your Connection

```bash
# Run the test script
dart run scripts/supabase/test_supabase_connection.dart

Or run the full suite (REST + verification + Flutter smoke if env provided):

```bash
chmod +x scripts/supabase/run_all.sh
./scripts/supabase/run_all.sh
```
```

## 📋 Database Schema

The setup script creates the following database schema:

### Tables

- **`users`** - User profiles (extends Supabase auth)
- **`spots`** - Location spots with coordinates
- **`spot_lists`** - Collections of spots
- **`spot_list_items`** - Junction table for spots in lists
- **`user_respects`** - User interactions (likes, follows)
- **`user_follows`** - User following relationships

### Storage Buckets

- **`user-avatars`** - User profile pictures
- **`spot-images`** - Images for spots
- **`list-images`** - Images for spot lists

### Security

- Row Level Security (RLS) enabled on all tables
- Policies ensure users can only access their own data
- Public read access for spots and public lists
- Secure file upload policies

## 🔧 Development Workflow

### Local Development

```bash
# Start local Supabase
supabase start

# Apply schema changes
supabase db push

# Stop local Supabase
supabase stop
```

### Production Deployment

```bash
# Link to your production project
supabase link --project-ref YOUR_PROJECT_REF

# Deploy schema to production
supabase db push

# Deploy edge functions (if any)
supabase functions deploy
```

## 🧪 Testing

### Connection Test

```bash
dart run scripts/test_supabase_connection.dart
```

### Integration Test

```bash
# Run the network package tests
cd packages/spots_network
flutter test
```

### Manual Testing

1. **Authentication Test**:
   ```dart
   final backend = SupabaseInitializer.backend;
   final user = await backend?.auth.signInAnonymously();
   print('User: ${user?.id}');
   ```

2. **Database Test**:
   ```dart
   final response = await backend?.data.getDocuments('users');
   print('Users: ${response?.data?.length}');
   ```

3. **Storage Test**:
   ```dart
   final url = await backend?.data.uploadFile('test.txt', [1, 2, 3, 4, 5]);
   print('Uploaded: $url');
   ```

## 🔐 Security Best Practices

### Environment Variables

Never commit your actual Supabase credentials to version control. Use environment variables:

```dart
// Use environment variables in production
static const String url = String.fromEnvironment('SUPABASE_URL');
static const String anonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
```

### Service Role Key

The service role key has admin privileges. Only use it for:
- Server-side operations
- Database migrations
- Admin functions

Never expose it in client-side code.

### Row Level Security

All tables have RLS enabled with appropriate policies:
- Users can only modify their own data
- Public read access for spots and public lists
- Secure file upload with user-specific folders

## 🚨 Troubleshooting

### Common Issues

1. **"Invalid API key"**
   - Check your anon key is correct
   - Ensure you're using the right project URL

2. **"Table doesn't exist"**
   - Run `supabase db push` to apply schema
   - Check migrations are applied correctly

3. **"Permission denied"**
   - Verify RLS policies are set up correctly
   - Check user authentication status

4. **"Storage bucket not found"**
   - Run the storage migration: `supabase db push`
   - Check bucket names match configuration

### Debug Mode

Enable debug mode for detailed logs:

```dart
static const bool debug = true;
```

### Health Check

```dart
final status = await SupabaseInitializer.getConnectionStatus();
print('Status: $status');
```

## 📚 Additional Resources

- [Supabase Documentation](https://supabase.com/docs)
- [Flutter Supabase Package](https://pub.dev/packages/supabase_flutter)
- [Row Level Security Guide](https://supabase.com/docs/guides/auth/row-level-security)
- [Storage Guide](https://supabase.com/docs/guides/storage)

## 🔄 Migration Guide

When you need to update the database schema:

1. Create a new migration:
   ```bash
   supabase migration new add_new_table
   ```

2. Edit the generated SQL file in `supabase/migrations/`

3. Apply the migration:
   ```bash
   supabase db push
   ```

4. Update your Dart models if needed

## 🎯 Next Steps

After setting up Supabase:

1. **Integrate with your app**:
   ```dart
   // In your main.dart
   await SupabaseInitializer.initialize();
   ```

2. **Add authentication flows**:
   - Email/password signup
   - Social login (Google, Apple)
   - Anonymous sign-in

3. **Implement data operations**:
   - CRUD operations for spots
   - List management
   - File uploads

4. **Add real-time features**:
   - Live updates for spots
   - User presence
   - Real-time messaging

5. **Deploy to production**:
   - Set up CI/CD
   - Configure environment variables
   - Monitor performance

---

**Need help?** Check the troubleshooting section or create an issue in the repository.

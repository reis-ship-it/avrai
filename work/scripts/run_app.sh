#!/bin/bash

# AVRAI App Runner
# Loads credentials from .env and passes them to Flutter via --dart-define

set -e

# Get the script directory and repo root
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
REPO_ROOT="$( cd "$SCRIPT_DIR/../.." && pwd )"
APP_DIR="$REPO_ROOT/apps/avrai_app"

# Load credentials from .env file at repo root
# Copy .env.example to .env and fill in your values
if [ -f "$REPO_ROOT/.env" ]; then
  export $(grep -v '^#' "$REPO_ROOT/.env" | grep -v '^\s*$' | xargs)
fi

if [ -z "$SUPABASE_URL" ] || [ -z "$SUPABASE_ANON_KEY" ]; then
  echo "❌ Missing SUPABASE_URL or SUPABASE_ANON_KEY."
  echo "   Copy .env.example to .env and fill in your values."
  exit 1
fi

# Check if Flutter is available
if ! command -v flutter &> /dev/null; then
    echo "❌ Flutter not found. Please install Flutter first."
    exit 1
fi

# Build dart-define flags from environment
DART_DEFINES=(
  "--dart-define=SUPABASE_URL=$SUPABASE_URL"
  "--dart-define=SUPABASE_ANON_KEY=$SUPABASE_ANON_KEY"
)

# Optional keys - only pass if set
[ -n "$GOOGLE_PLACES_API_KEY" ] && DART_DEFINES+=("--dart-define=GOOGLE_PLACES_API_KEY=$GOOGLE_PLACES_API_KEY")
[ -n "$GOOGLE_OAUTH_CLIENT_ID" ] && DART_DEFINES+=("--dart-define=GOOGLE_OAUTH_CLIENT_ID=$GOOGLE_OAUTH_CLIENT_ID")
[ -n "$GOOGLE_OAUTH_CLIENT_ID_ANDROID" ] && DART_DEFINES+=("--dart-define=GOOGLE_OAUTH_CLIENT_ID_ANDROID=$GOOGLE_OAUTH_CLIENT_ID_ANDROID")
[ -n "$GOOGLE_OAUTH_CLIENT_ID_IOS" ] && DART_DEFINES+=("--dart-define=GOOGLE_OAUTH_CLIENT_ID_IOS=$GOOGLE_OAUTH_CLIENT_ID_IOS")
[ -n "$FIREBASE_ANDROID_API_KEY" ] && DART_DEFINES+=("--dart-define=FIREBASE_ANDROID_API_KEY=$FIREBASE_ANDROID_API_KEY")
[ -n "$FIREBASE_IOS_API_KEY" ] && DART_DEFINES+=("--dart-define=FIREBASE_IOS_API_KEY=$FIREBASE_IOS_API_KEY")
[ -n "$FIREBASE_WEB_API_KEY" ] && DART_DEFINES+=("--dart-define=FIREBASE_WEB_API_KEY=$FIREBASE_WEB_API_KEY")
[ -n "$OPENWEATHERMAP_API_KEY" ] && DART_DEFINES+=("--dart-define=OPENWEATHERMAP_API_KEY=$OPENWEATHERMAP_API_KEY")
[ -n "$USE_REAL_OAUTH" ] && DART_DEFINES+=("--dart-define=USE_REAL_OAUTH=$USE_REAL_OAUTH")

# Run Flutter from the app directory with all credentials
cd "$APP_DIR"
flutter run "${DART_DEFINES[@]}" "$@"

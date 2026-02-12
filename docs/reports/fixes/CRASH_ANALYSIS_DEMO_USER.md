# Crash Analysis: Why the App Crashed When Demo User Was Already Logged In

## The Problem

When the demo user was already logged in and had completed onboarding, the app would crash with "Lost connection to device" right after startup. The logs showed **6 consecutive onboarding completion checks** before the crash.

## Root Cause: Competing Navigation and Race Conditions

### The Crash Sequence

1. **App Starts** → `AuthBloc` is in `AuthInitial` state
2. **AuthWrapper Triggers Auth Check** → `AuthCheckRequested` event is dispatched
3. **AuthBloc Emits States** → `AuthLoading` → `Authenticated` (user found in database)
4. **Multiple Systems React Simultaneously**:
   - **Router Redirect Function** (listens to `authBloc.stream` via `refreshListenable`)
   - **AuthWrapper FutureBuilder** (checks onboarding completion)
   - **AuthWrapper PostFrameCallback** (tries to navigate to `/home`)

### The Race Condition

```
Time 0ms:  AuthBloc emits Authenticated
Time 1ms:  Router redirect function called → checks onboarding → returns '/home'
Time 2ms:  AuthWrapper FutureBuilder calls _checkOnboardingCompletion()
Time 3ms:  Router redirect called AGAIN (because navigation triggered)
Time 4ms:  AuthWrapper PostFrameCallback executes → context.go('/home')
Time 5ms:  Router redirect called AGAIN (because navigation triggered)
Time 6ms:  HomePage starts building → triggers LoadLists()
Time 7ms:  Router redirect called AGAIN (because auth state change)
... (repeats 6 times)
Time Xms:  CRASH - Multiple widgets trying to build/access services simultaneously
```

### Why It Crashed

1. **Multiple Navigation Attempts**: Both the router redirect AND AuthWrapper were trying to navigate to `/home` at the same time
2. **Rapid Widget Rebuilds**: Each navigation attempt triggered a rebuild, which triggered more navigation attempts
3. **Service Access During Rebuild**: `HomePage` tried to access services (BLoCs, repositories) while widgets were being rapidly built/destroyed
4. **Native Plugin Access**: `MapView` tried to initialize Google Maps/Geolocator during this rapid rebuild cycle
5. **Memory Protection Error**: The rapid rebuilds and service access caused a memory protection violation (KERN_PROTECTION_FAILURE)

### The Evidence

From the logs:
```
flutter: [OnboardingCompletionService] 🐛 🔍 [CHECK_CACHE] ... (6 times in a row)
Lost connection to device.
```

This shows:
- The onboarding check was called 6 times in rapid succession
- Each check likely triggered a navigation attempt
- The crash happened during this rapid cycle

## The Fix

By clearing the demo user cache and data on startup:
- The user is no longer "already logged in"
- `AuthCheckRequested` returns `Unauthenticated` (no user found)
- Router redirect doesn't try to navigate to `/home`
- AuthWrapper doesn't try to navigate
- No competing navigation attempts
- App starts cleanly

## Why This Wasn't Obvious

The crash happened **after** successful initialization:
- ✅ Firebase initialized
- ✅ Database initialized  
- ✅ Dependency injection complete
- ✅ App started successfully
- ❌ **CRASH** when trying to navigate with an already-authenticated user

The issue was in the **navigation/routing logic**, not in initialization.

## Lessons Learned

1. **Avoid Competing Navigation Systems**: Don't have both router redirects AND widget-level navigation trying to do the same thing
2. **Cache Can Cause Issues**: Stale cache can cause unexpected navigation behavior
3. **Race Conditions in Navigation**: Multiple async operations checking the same condition can cause rapid rebuilds
4. **Test with Clean State**: Always test with fresh data, not cached/old state

## Prevention

To prevent this in the future:
1. **Single Source of Truth**: Use router redirects OR widget-level navigation, not both
2. **Debounce Navigation**: Add delays/debouncing to prevent rapid navigation attempts
3. **Guard Against Rapid Rebuilds**: Check `mounted` and add guards before navigation
4. **Clear Cache on Startup**: Optionally clear stale cache to ensure clean state


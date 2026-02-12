# Single Navigation System Implementation

## Problem

The app had **two competing navigation systems** that caused crashes:
1. **Router redirect function** (in `app_router.dart`) - handles navigation based on auth/onboarding state
2. **AuthWrapper widget** (in `auth_wrapper.dart`) - also tried to navigate based on auth/onboarding state

When both ran simultaneously, they created rapid navigation loops and widget rebuilds, causing memory protection errors.

## Solution: Single Navigation System

### Architecture

**GoRouter redirect function** is now the **single source of truth** for all navigation decisions:
- ✅ Checks authentication state
- ✅ Checks onboarding completion
- ✅ Decides where to navigate
- ✅ Handles all redirects

**AuthWrapper** is now simplified to:
- ✅ Trigger initial auth check (`AuthCheckRequested`)
- ✅ Show loading states
- ✅ Show login page for unauthenticated users
- ❌ **NO navigation logic** (removed all `context.go()` calls)

### Changes Made

#### 1. Simplified AuthWrapper (`lib/presentation/pages/auth/auth_wrapper.dart`)

**Before:**
- Complex state management with flags (`_didRedirectToOnboarding`, `_didRedirectToHome`)
- Multiple async checks (`_checkOnboardingStatus`, `_checkOnboardingCompletion`)
- Navigation logic with `context.go('/home')` and `context.go('/onboarding')`
- ~236 lines of code

**After:**
- Simple widget that triggers auth check once
- Shows loading states based on auth state
- Shows login page for unauthenticated users
- **No navigation logic** - router handles everything
- ~60 lines of code (75% reduction)

#### 2. Enhanced Router Redirect (`lib/presentation/routes/app_router.dart`)

**Improvements:**
- More comprehensive redirect logic
- Handles edge cases (onboarding done but on onboarding page → redirect to home)
- Handles signup page redirects
- Clearer logic flow

**Key Logic:**
```dart
if (authState is Authenticated) {
  // Check onboarding
  if (!onboardingDone) {
    // Redirect to onboarding (unless already there)
    return '/onboarding';
  } else {
    // Onboarding done - redirect from root/login/signup/onboarding to home
    if (isRoot || isLoggingIn || isSignup || isOnboarding) {
      return '/home';
    }
    // Allow navigation to other pages
    return null;
  }
}
```

## Benefits

1. **No More Competing Navigation**: Only one system makes navigation decisions
2. **No More Race Conditions**: Router redirect runs synchronously, no competing async operations
3. **Simpler Code**: AuthWrapper is 75% smaller and easier to understand
4. **Easier to Debug**: All navigation logic in one place
5. **More Reliable**: No rapid rebuilds or navigation loops

## Navigation Flow

```
App Starts
  ↓
AuthWrapper triggers AuthCheckRequested
  ↓
AuthBloc emits Authenticated
  ↓
Router redirect function runs (single source of truth)
  ↓
Checks onboarding completion
  ↓
Returns redirect path: '/home' or '/onboarding' or null
  ↓
GoRouter navigates to the returned path
```

## Testing

To verify the single navigation system works:

1. **Fresh Start (No User)**:
   - App should show login page
   - Router redirect returns `/login` for unauthenticated users

2. **Authenticated + Onboarding Not Done**:
   - Router redirect returns `/onboarding`
   - User sees onboarding page

3. **Authenticated + Onboarding Done**:
   - Router redirect returns `/home` (if on root/login/signup/onboarding)
   - User sees home page

4. **No Rapid Rebuilds**:
   - Should see only 1-2 onboarding checks (not 6+)
   - No "Lost connection to device" crashes

## Migration Notes

- **AuthWrapper** no longer handles navigation - it's just a loading/auth trigger widget
- **All navigation** is handled by router redirect function
- **No breaking changes** - same user experience, just cleaner implementation


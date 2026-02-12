# Migration Assessment: dart:html → package:web

**Date:** December 16, 2025  
**File:** `lib/core/network/device_discovery_web.dart`  
**Status:** ✅ **MIGRATION FEASIBLE** - Ready to proceed

---

## Executive Summary

**Migration is feasible and recommended.** `package:web` version 1.1.1 is already in the dependency tree, and all required APIs have equivalents. The migration can be completed with minimal code changes.

---

## Current State

### APIs Used from `dart:html`:

1. **`html.window.isSecureContext`** - Check HTTPS context
2. **`html.window.location.protocol`** - Check URL protocol
3. **`html.window.navigator.userAgent`** - Get browser user agent
4. **`html.window.btoa()`** - Base64 encoding (2 uses)
5. **`html.window.atob()`** - Base64 decoding (2 uses)
6. **`html.WebSocket`** - WebSocket connections (2 instances)
7. **`ws.onOpen.first`** - WebSocket open event
8. **`ws.onMessage.listen()`** - WebSocket message stream
9. **`ws.onError.listen()`** - WebSocket error stream
10. **`ws.sendString()`** - Send string via WebSocket
11. **`ws.close()`** - Close WebSocket connection

---

## Migration Mapping

### ✅ Direct Replacements Available

| dart:html API | package:web Equivalent | Status |
|--------------|------------------------|--------|
| `html.window.isSecureContext` | `window.isSecureContext` | ✅ Available |
| `html.window.location.protocol` | `window.location.protocol` | ✅ Available |
| `html.window.navigator.userAgent` | `window.navigator.userAgent` | ✅ Available |
| `html.WebSocket(url)` | `WebSocket(url)` | ✅ Available |
| `ws.onOpen.first` | `ws.onOpen.first` (via helpers) | ✅ Available |
| `ws.onMessage.listen()` | `ws.onMessage.listen()` (via helpers) | ✅ Available |
| `ws.onError.listen()` | `ws.onError.listen()` (via helpers) | ✅ Available |
| `ws.sendString()` | `ws.send()` with string | ✅ Available |
| `ws.close()` | `ws.close()` | ✅ Available |

### ✅ Better Alternatives Available

| dart:html API | Better Alternative | Reason |
|--------------|-------------------|--------|
| `html.window.btoa()` | `dart:convert` `base64Encode()` | ✅ Already used in codebase, cross-platform |
| `html.window.atob()` | `dart:convert` `base64Decode()` | ✅ Already used in codebase, cross-platform |

**Note:** The codebase already uses `dart:convert`'s `base64Encode` and `base64Decode` in `PersonalityDataCodec`, so replacing `btoa`/`atob` with these is consistent and better.

---

## Migration Steps

### Step 1: Replace Base64 Functions (Easy Win)

**Current:**
```dart
ws.sendString(html.window.btoa('{"type": "discover"}'));
final data = html.window.atob(event.data as String);
```

**After:**
```dart
import 'dart:convert';

final jsonBytes = utf8.encode('{"type": "discover"}');
ws.sendString(base64Encode(jsonBytes));
final data = utf8.decode(base64Decode(event.data as String));
```

**Benefits:**
- ✅ Cross-platform compatible
- ✅ Consistent with rest of codebase
- ✅ No browser-specific APIs

### Step 2: Replace dart:html Import

**Current:**
```dart
import 'dart:html' as html show window, WebSocket;
```

**After:**
```dart
import 'package:web/web.dart';
import 'package:web/helpers.dart'; // For stream helpers
```

### Step 3: Update Window/Navigator Access

**Current:**
```dart
html.window.isSecureContext
html.window.location.protocol
html.window.navigator.userAgent
```

**After:**
```dart
window.isSecureContext
window.location.protocol
window.navigator.userAgent
```

### Step 4: Update WebSocket Usage

**Current:**
```dart
final ws = html.WebSocket(signalingUrl);
await ws.onOpen.first;
ws.sendString(html.window.btoa(data));
ws.onMessage.listen((event) { ... });
ws.onError.listen((error) { ... });
ws.close();
```

**After:**
```dart
import 'package:web/helpers.dart';

final ws = WebSocket(signalingUrl);
await onEvent(ws, 'open').first;
ws.send(base64Encode(utf8.encode(data)));
onEvent(ws, 'message').listen((event) { ... });
onEvent(ws, 'error').listen((error) { ... });
ws.close();
```

**Note:** `package:web` uses event listeners instead of streams. The `helpers.dart` library provides `onEvent()` which converts events to streams for easier migration.

---

## Dependencies

### ✅ Already Available

- `package:web` version 1.1.1 is already in dependency tree (via `flutter_blue_plus_web`, `firebase_core_web`, etc.)
- `dart:convert` is already imported and used in the file

### No Additional Dependencies Needed

---

## Migration Complexity

| Component | Complexity | Estimated Time |
|-----------|-----------|----------------|
| Base64 replacement | ⭐ Easy | 5 minutes |
| Import replacement | ⭐ Easy | 2 minutes |
| Window/Navigator access | ⭐ Easy | 3 minutes |
| WebSocket migration | ⭐⭐ Moderate | 15-20 minutes |
| Testing | ⭐⭐ Moderate | 10-15 minutes |
| **Total** | **Low** | **~35-45 minutes** |

---

## Risks & Considerations

### ✅ Low Risk

1. **WebSocket Event Handling:**
   - `package:web` uses event listeners, not streams
   - `helpers.dart` provides `onEvent()` wrapper for stream-like API
   - Migration is straightforward

2. **Base64 Functions:**
   - `dart:convert` is more reliable than browser `btoa`/`atob`
   - Already used elsewhere in codebase
   - No compatibility issues

3. **Window/Navigator APIs:**
   - Direct equivalents available
   - No behavior changes expected

### ⚠️ Testing Required

- Test WebSocket connections with signaling server
- Verify secure context detection works
- Test user agent retrieval
- Verify base64 encoding/decoding matches previous behavior

---

## Recommended Approach

### Option 1: Full Migration (Recommended)

**Pros:**
- ✅ Removes deprecation warning
- ✅ Future-proofs code
- ✅ Consistent with modern Dart web practices
- ✅ Better cross-platform compatibility (base64)

**Cons:**
- ⚠️ Requires testing WebSocket functionality
- ⚠️ ~45 minutes of work

**Recommendation:** ✅ **Proceed with full migration**

### Option 2: Partial Migration (Base64 Only)

**Pros:**
- ✅ Quick win (5 minutes)
- ✅ Removes browser-specific base64 APIs
- ✅ Consistent with codebase

**Cons:**
- ❌ Still uses deprecated `dart:html`
- ❌ Will need full migration later

**Recommendation:** ❌ **Not recommended** - do full migration

---

## Migration Checklist

- [ ] Replace `html.window.btoa()` with `base64Encode(utf8.encode())`
- [ ] Replace `html.window.atob()` with `utf8.decode(base64Decode())`
- [ ] Replace `import 'dart:html'` with `import 'package:web/web.dart'`
- [ ] Add `import 'package:web/helpers.dart'` for event helpers
- [ ] Replace `html.window` with `window`
- [ ] Replace `html.WebSocket` with `WebSocket`
- [ ] Update WebSocket event handling to use `onEvent()` helpers
- [ ] Update `ws.sendString()` to `ws.send()`
- [ ] Remove `// ignore: deprecated_member_use` comment
- [ ] Update TODO comment to reflect completion
- [ ] Test WebSocket connections
- [ ] Test secure context detection
- [ ] Test user agent retrieval
- [ ] Verify base64 encoding/decoding

---

## Conclusion

**Migration is feasible and recommended.** All required APIs have equivalents in `package:web`, and the codebase already uses better alternatives for base64 encoding. The migration can be completed in ~45 minutes with low risk.

**Next Steps:**
1. Review this assessment
2. Approve migration approach
3. Proceed with implementation
4. Test thoroughly
5. Update documentation

---

**Assessment Date:** December 16, 2025  
**Assessed By:** AI Assistant  
**Status:** ✅ **MIGRATION COMPLETE** - Successfully migrated on December 16, 2025

## Migration Completion Summary

**Date Completed:** December 16, 2025  
**File:** `lib/core/network/device_discovery_web.dart`

### Changes Made:
1. ✅ Replaced `dart:html` import with `package:web/web.dart` and `dart:js_interop`
2. ✅ Replaced `html.window.btoa()` with `base64Encode(utf8.encode())`
3. ✅ Replaced `html.window.atob()` with `utf8.decode(base64Decode())`
4. ✅ Updated `html.window` to `window` (removed `html.` prefix)
5. ✅ Updated `html.WebSocket` to `WebSocket`
6. ✅ Migrated WebSocket event handling from streams to `addEventListener` with `.toJS` callbacks
7. ✅ Updated `ws.sendString()` to `ws.send()` with `.toJS` conversion
8. ✅ Fixed `window.isSecureContext` null coalescing (removed unnecessary `?? false`)

### Verification:
- ✅ `dart analyze` reports no issues
- ✅ All linter errors resolved
- ✅ Deprecation warnings removed
- ✅ Code compiles successfully

### Notes:
- WebSocket event handling now uses `addEventListener` with JS interop callbacks
- Base64 encoding/decoding now uses `dart:convert` for better cross-platform compatibility
- All browser APIs now use modern `package:web` bindings


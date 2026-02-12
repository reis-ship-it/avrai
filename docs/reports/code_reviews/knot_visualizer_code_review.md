# Knot Visualizer Code Review

**Date:** January 30, 2026  
**Reviewer:** AI Assistant  
**Scope:** All knot visualization code (3D Visualization System)

---

## Executive Summary

**Overall Rating: B+ (Good with room for improvement)**

The knot visualizer implementation is well-structured with good separation of concerns, proper error handling, and comprehensive feature coverage. There are some areas requiring attention, particularly around memory management, potential race conditions, and code duplication.

---

## Files Reviewed

| File | Lines | Rating |
|------|-------|--------|
| `lib/core/services/visualization/three_js_bridge_service.dart` | 661 | A- |
| `lib/core/services/visualization/visualization_prewarmer.dart` | 263 | B+ |
| `lib/core/models/visualization_style.dart` | 424 | A |
| `lib/presentation/widgets/visualization/three_js_visualization_widget.dart` | 398 | B+ |
| `lib/presentation/widgets/onboarding/knot_birth_experience_widget.dart` | 443 | B |
| `lib/presentation/widgets/ai2ai/network_3d_visualization_widget.dart` | 281 | B+ |
| `assets/three_js/index.html` | ~1000 | B |

---

## Critical Issues (Must Fix)

### 1. Memory Leak in BirthExperienceVisualizationWidget

**File:** `three_js_visualization_widget.dart` (lines 386-395)

```dart
onReady: (bridge) {
  // Subscribe to birth-specific events
  bridge.onPhaseChange.listen((phase) {  // ⚠️ Never cancelled
    onPhaseChange?.call(phase);
  });
  bridge.onBirthComplete.listen((data) {  // ⚠️ Never cancelled
    onBirthComplete?.call(data);
  });
  onReady?.call(bridge);
},
```

**Problem:** Stream subscriptions are created but never stored or cancelled, causing memory leaks.

**Fix:**
```dart
// Store subscriptions in parent widget and cancel in dispose
StreamSubscription<String>? _phaseSub;
StreamSubscription<Map<String, dynamic>>? _completeSub;

// In onReady callback
_phaseSub = bridge.onPhaseChange.listen(...);
_completeSub = bridge.onBirthComplete.listen(...);

// In dispose
_phaseSub?.cancel();
_completeSub?.cancel();
```

---

### 2. Potential Race Condition in Prewarmer

**File:** `visualization_prewarmer.dart` (lines 43, 248)

```dart
final _readyCompleter = Completer<void>();  // Created once

// Both prewarm() and prewarmBirthExperience() complete this:
if (!_readyCompleter.isCompleted) {
  _readyCompleter.complete();
}
```

**Problem:** If `prewarm()` is called, completes, then `prewarmBirthExperience()` is called after reset, the completer is already completed.

**Fix:**
```dart
Completer<void> _readyCompleter = Completer<void>();

void reset() {
  if (_wasUsed) {
    // ... existing reset logic ...
    _readyCompleter = Completer<void>();  // Create new completer
  }
}
```

---

### 3. Deprecated API Usage in Fallback Painter

**File:** `network_3d_visualization_widget.dart` (lines 237, 271-272)

```dart
..color = AppColors.electricGreen.withOpacity(0.3)  // ⚠️ Deprecated
```

**Fix:**
```dart
..color = AppColors.electricGreen.withValues(alpha: 0.3)
```

---

## High Priority Issues

### 4. Inconsistent Null Safety in JS Evaluation

**File:** `network_3d_visualization_widget.dart` (lines 170, 176, 182)

```dart
await _bridge!.evaluateJS('window.networkRenderer?.pulseEdge($edgeIndex)');
```

**Problem:** Using `?.` in JavaScript is good, but if `networkRenderer` is undefined, Flutter won't know the call failed silently.

**Improvement:** Add return value checking:
```dart
Future<bool> pulseEdge(int edgeIndex) async {
  if (_bridge == null || !_threeJsReady) return false;
  
  final result = await _bridge!.evaluateJSAndGetResult(
    'window.networkRenderer?.pulseEdge($edgeIndex) ?? false'
  );
  return result == true;
}
```

---

### 5. Missing Input Sanitization for User IDs

**File:** `network_3d_visualization_widget.dart` (line 176)

```dart
await _bridge!.evaluateJS('window.networkRenderer?.highlightNode("$userId")');
```

**Problem:** `userId` is interpolated directly into JavaScript, creating potential injection risk.

**Fix:**
```dart
// Escape the userId or use JSON encoding
final safeUserId = jsonEncode(userId);
await _bridge!.evaluateJS('window.networkRenderer?.highlightNode($safeUserId)');
```

---

### 6. No Timeout on Ready Wait

**File:** `three_js_bridge_service.dart` (lines 219-222)

```dart
if (!_isReady) {
  developer.log('WebView not ready, waiting...', name: _logName);
  await onReady.first;  // ⚠️ Could wait forever
}
```

**Fix:**
```dart
if (!_isReady) {
  developer.log('WebView not ready, waiting...', name: _logName);
  try {
    await onReady.first.timeout(
      const Duration(seconds: 10),
      onTimeout: () => throw TimeoutException('WebView ready timeout'),
    );
  } on TimeoutException {
    developer.log('WebView ready timeout', name: _logName);
    rethrow;
  }
}
```

---

## Medium Priority Issues

### 7. Code Duplication in Prewarmer

**File:** `visualization_prewarmer.dart`

The `prewarm()` and `prewarmBirthExperience()` methods share ~80% identical code.

**Recommendation:** Extract common logic:
```dart
Future<void> _prewarmWithHtml(String htmlFile) async {
  // Shared logic
}

Future<void> prewarm() => _prewarmWithHtml('index.html');
Future<void> prewarmBirthExperience() => _prewarmWithHtml('birth_experience.html');
```

---

### 8. Magic Numbers in JavaScript

**File:** `index.html` (various locations)

```javascript
const tubularSegments = data.style?.lod === 'high' ? 200 : 
                        data.style?.lod === 'low' ? 50 : 100;
```

**Recommendation:** Define constants:
```javascript
const LOD_SETTINGS = {
  high: { tubularSegments: 200, radialSegments: 16 },
  medium: { tubularSegments: 100, radialSegments: 8 },
  low: { tubularSegments: 50, radialSegments: 4 }
};
```

---

### 9. Missing Error Boundary in Widget

**File:** `three_js_visualization_widget.dart`

No error boundary catches exceptions from the bridge or WebView creation.

**Recommendation:** Add `ErrorWidget.builder` or wrap in try-catch:
```dart
try {
  _bridge = ThreeJsBridgeService();
  await _bridge!.initialize(controller);
} catch (e, st) {
  developer.log('Bridge initialization failed', error: e, stackTrace: st);
  if (mounted) {
    setState(() => _error = e.toString());
  }
}
```

---

### 10. Inconsistent JSON Key Casing

**File:** `three_js_bridge_service.dart`

Dart uses camelCase, but JSON keys are also camelCase. This is fine, but verify JavaScript expects the same:

```dart
// Dart side
'crossingNumber': knot.invariants.crossingNumber,

// JS side - must match exactly
const crossingNumber = data.invariants?.crossingNumber;  // ✓
```

**Status:** Currently consistent - no change needed, just noting for future reference.

---

## Low Priority Issues

### 11. Unused Parameter in KnotVisualizationStyle

**File:** `visualization_style.dart`

```dart
this.secondaryColor = 0x66FF99, // AppColors.primaryLight
```

The `secondaryColor` is passed to JS but not always used in all material types.

**Recommendation:** Document which material types use which properties.

---

### 12. Console Logging in Production

**File:** `index.html`

```javascript
console.log(`Shader loaded: ${shaderPath}`);
```

**Recommendation:** Use conditional logging:
```javascript
const DEBUG = false;
if (DEBUG) console.log(`Shader loaded: ${shaderPath}`);
```

---

### 13. `shouldRepaint` Always Returns True

**File:** `network_3d_visualization_widget.dart` (line 279)

```dart
@override
bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
```

**Improvement:** Compare actual data:
```dart
@override
bool shouldRepaint(covariant _NetworkFallbackPainter oldDelegate) {
  return nodes != oldDelegate.nodes || edges != oldDelegate.edges;
}
```

---

## Positive Observations

### Well Done

1. **Excellent Documentation**
   - All public APIs have doc comments
   - Patent references are consistent
   - Section dividers improve readability

2. **Good Error Handling**
   - `ErrorReporter` class in JavaScript
   - Try-catch blocks around critical operations
   - Graceful fallbacks (e.g., audio failure doesn't break visuals)

3. **Performance Considerations**
   - Prewarming strategy is smart
   - LOD system for different view sizes
   - Hardware acceleration enabled

4. **Clean Architecture**
   - Bridge pattern separates concerns
   - Style classes are composable
   - Factory methods for common configurations

5. **Proper Resource Cleanup**
   - `dispose()` methods close streams
   - System UI restored on widget dispose
   - Bridge cleanup before disposal

6. **Offline Support**
   - Three.js bundled locally
   - No CDN dependencies in production

---

## Security Considerations

| Area | Status | Notes |
|------|--------|-------|
| XSS in JS evaluation | ⚠️ Medium Risk | User IDs not sanitized |
| WebView sandboxing | ✓ Secure | No URL overriding enabled |
| Data exposure | ✓ Secure | Only renders local data |
| Network requests | ✓ Secure | All assets local |

---

## Performance Observations

| Metric | Status | Notes |
|--------|--------|-------|
| Cold start | ~300-500ms | Acceptable with prewarming |
| Memory usage | Unknown | Need profiling |
| Animation FPS | Unknown | Need device testing |
| Bundle size | ~1.3MB | Three.js is large |

**Recommendation:** Add Three.js tree-shaking or lazy loading for non-visualization pages.

---

## Action Items Summary

### Critical (Fix Before Release)
- [ ] Fix memory leak in BirthExperienceVisualizationWidget
- [ ] Fix race condition in Completer
- [ ] Fix deprecated `withOpacity` calls

### High Priority
- [ ] Add input sanitization for user IDs in JS
- [ ] Add timeout to ready wait
- [ ] Add return value checking for JS calls

### Medium Priority
- [ ] Extract common prewarmer logic
- [ ] Define LOD constants in JavaScript
- [ ] Add error boundary to widget

### Low Priority
- [ ] Add conditional logging in production
- [ ] Optimize `shouldRepaint`
- [ ] Document which style properties affect which materials

---

## Conclusion

The knot visualizer codebase is well-architected and follows good practices. The critical issues identified are primarily around memory management and race conditions, which are common in async/WebView code and easily fixable. The security concern around JavaScript injection should be addressed before any user-generated content is displayed.

**Recommended Next Steps:**
1. Fix critical issues immediately
2. Add integration tests for the WebView lifecycle
3. Profile memory usage on devices
4. Consider lazy-loading Three.js bundle

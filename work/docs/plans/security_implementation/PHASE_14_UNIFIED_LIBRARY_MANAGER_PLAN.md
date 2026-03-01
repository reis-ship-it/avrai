# Phase 14: Unified Library Manager - Long-Term Plan

**Date:** January 1, 2026  
**Status:** 📋 Planning Complete - Ready for Implementation  
**Approach:** Unified Manager + Framework (Long-Term Solution)

---

## 🎯 **Executive Summary**

This document outlines the long-term plan for implementing a unified library manager for Signal Protocol native libraries, combining:

1. **Unified Library Manager** (Option 3) - Centralized management of all native libraries
2. **Process-Level Loading** (Option 2) - iOS/macOS frameworks use `DynamicLibrary.process()`
3. **macOS Framework** (Option B - Long-Term) - Build macOS framework for consistency

**Decision:** Implement long-term solution immediately (no short-term migration needed)

**Timeline:** 4-5 days total
- Framework build: 1-2 days
- Manager implementation: 2-3 hours
- Binding updates: 1-2 hours
- Testing: 2-3 hours
- Buffer: 1 day

---

## 📊 **Current State**

### **What We Have**
- ✅ iOS framework (SignalFFI.framework) - embedded, uses `DynamicLibrary.process()`
- ✅ macOS dylib files - explicit loading with `DynamicLibrary.open()`
- ✅ Three binding classes with separate library loading:
  - `SignalFFIBindings` - loads main + wrapper libraries
  - `SignalPlatformBridgeBindings` - loads bridge library
  - `SignalRustWrapperBindings` - loads wrapper library
- ✅ Static references to prevent GC (in `SignalFFIBindings`)

### **What We Need**
- ⏳ macOS framework (SignalFFI.framework) - for consistency with iOS
- ⏳ Unified library manager - single point of control
- ⏳ Updated binding classes - use manager instead of direct loading
- ⏳ Process-level loading for macOS - after framework is built

---

## 🏗️ **Architecture Overview**

### **Target Architecture**

```
┌─────────────────────────────────────────────────────────┐
│           SignalLibraryManager (Singleton)              │
│  ┌──────────────────────────────────────────────────┐  │
│  │  getMainLibrary()     → libsignal_ffi            │  │
│  │  getWrapperLibrary()  → libsignal_ffi_wrapper    │  │
│  │  getBridgeLibrary()   → libsignal_callback_bridge │  │
│  └──────────────────────────────────────────────────┘  │
│                                                          │
│  Loading Strategy:                                       │
│  • iOS/macOS: DynamicLibrary.process() (framework)      │
│  • Android/Linux/Windows: DynamicLibrary.open()         │
└─────────────────────────────────────────────────────────┘
                          ↓
        ┌─────────────────┼─────────────────┐
        ↓                 ↓                 ↓
┌──────────────┐  ┌──────────────┐  ┌──────────────┐
│ SignalFFI    │  │ Platform     │  │ Rust         │
│ Bindings     │  │ Bridge       │  │ Wrapper      │
│              │  │ Bindings     │  │ Bindings     │
└──────────────┘  └──────────────┘  └──────────────┘
```

### **Benefits**

1. **Unified Management**
   - Single point of control for all libraries
   - Consistent loading strategy across platforms
   - Centralized error handling and logging

2. **iOS Optimization**
   - Process-level loading (already working)
   - OS-managed lifecycle
   - Reduced SIGABRT crashes

3. **macOS Optimization**
   - Process-level loading (after framework)
   - Framework approach (standard practice)
   - Consistency with iOS

4. **Maintainability**
   - One manager to update
   - Easy to add new platforms
   - Clear separation of concerns

5. **Production Stability**
   - OS-managed lifecycle
   - No manual disposal needed
   - Better error handling

---

## 📋 **Implementation Plan**

### **Phase 1: Build macOS Framework** (1-2 days)

#### **Step 1.1: Build libsignal-ffi for macOS**

**Prerequisites:**
- Rust toolchain installed
- libsignal-ffi source code at `native/signal_ffi/libsignal`

**Commands:**
```bash
cd native/signal_ffi/libsignal

# Add macOS targets (if not already added)
rustup target add aarch64-apple-darwin  # Apple Silicon
rustup target add x86_64-apple-darwin    # Intel (if needed)

# Build for macOS (Apple Silicon)
cargo build --release --target aarch64-apple-darwin

# Or for Intel
cargo build --release --target x86_64-apple-darwin
```

**Output:**
- `target/aarch64-apple-darwin/release/libsignal_ffi.a` (static library)

**Verification:**
- [ ] Library builds successfully
- [ ] Library is correct architecture (aarch64 or x86_64)
- [ ] Library size is reasonable (not empty)

---

#### **Step 1.2: Create macOS Framework Structure**

**Framework Structure:**
```
native/signal_ffi/macos/SignalFFI.framework/
├── SignalFFI                    # Binary (libsignal_ffi.a)
├── Headers/                     # C headers (if needed)
│   └── signal_ffi.h
├── Modules/                     # Module map
│   └── module.modulemap
├── Resources/                   # Resources (if needed)
└── Info.plist                   # Framework metadata
```

**Commands:**
```bash
# Create framework structure
mkdir -p native/signal_ffi/macos/SignalFFI.framework/Headers
mkdir -p native/signal_ffi/macos/SignalFFI.framework/Modules
mkdir -p native/signal_ffi/macos/SignalFFI.framework/Resources

# Copy built library
cp target/aarch64-apple-darwin/release/libsignal_ffi.a \
   native/signal_ffi/macos/SignalFFI.framework/SignalFFI

# Create module map (similar to iOS)
cat > native/signal_ffi/macos/SignalFFI.framework/Modules/module.modulemap << 'EOF'
framework module SignalFFI {
    umbrella header "signal_ffi.h"
    export *
    module * { export * }
}
EOF

# Create Info.plist
cat > native/signal_ffi/macos/SignalFFI.framework/Info.plist << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleIdentifier</key>
    <string>com.spots.SignalFFI</string>
    <key>CFBundleName</key>
    <string>SignalFFI</string>
    <key>CFBundleVersion</key>
    <string>1.0</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>MinimumOSVersion</key>
    <string>11.0</string>
</dict>
</plist>
EOF
```

**Verification:**
- [ ] Framework structure created
- [ ] Binary copied correctly
- [ ] Module map created
- [ ] Info.plist created

---

#### **Step 1.3: Build Wrapper and Bridge Libraries for Framework**

**Option A: Include in Same Framework**
- Build wrapper and bridge as separate static libraries
- Link them into SignalFFI.framework
- Single framework contains all libraries

**Option B: Separate Frameworks** (Recommended)
- Build SignalWrapper.framework
- Build SignalBridge.framework
- Three separate frameworks (cleaner separation)

**Commands (Option B):**
```bash
# Build wrapper library
cd native/signal_ffi/wrapper
cargo build --release --target aarch64-apple-darwin

# Build bridge library
cd native/signal_ffi/bridge
cargo build --release --target aarch64-apple-darwin

# Create frameworks (similar to Step 1.2)
# ... (repeat for wrapper and bridge)
```

**Verification:**
- [ ] Wrapper library builds
- [ ] Bridge library builds
- [ ] Frameworks created correctly

---

#### **Step 1.4: Embed Framework in macOS App Bundle**

**Xcode Configuration:**
1. Open Xcode project
2. Add frameworks to project:
   - SignalFFI.framework
   - SignalWrapper.framework (if separate)
   - SignalBridge.framework (if separate)
3. Configure "Embed & Sign":
   - Target → General → Frameworks, Libraries, and Embedded Content
   - Set to "Embed & Sign"
4. Set library search paths:
   - Build Settings → Library Search Paths
   - Add: `$(PROJECT_DIR)/native/signal_ffi/macos`

**Verification:**
- [ ] Frameworks added to Xcode project
- [ ] "Embed & Sign" configured
- [ ] Library search paths set
- [ ] App builds successfully

---

**Phase 1 Checklist:**
- [ ] libsignal-ffi builds for macOS
- [ ] Framework structure created
- [ ] Wrapper library builds (if separate)
- [ ] Bridge library builds (if separate)
- [ ] Frameworks embedded in Xcode
- [ ] App builds with frameworks
- [ ] Framework loads correctly at runtime

**Estimated Time:** 1-2 days (first time), 30-60 minutes (subsequent builds)

---

### **Phase 2: Create Unified Library Manager** (2-3 hours)

#### **Step 2.1: Create `SignalLibraryManager` Class**

**File:** `lib/core/crypto/signal/signal_library_manager.dart`

**Structure:**
```dart
/// Signal Protocol Library Manager
/// 
/// Centralized manager for all Signal Protocol native libraries.
/// Provides process-level loading for iOS/macOS to reduce SIGABRT crashes.
/// 
/// **Benefits:**
/// - Single point of control for library lifecycle
/// - Process-level loading on iOS/macOS (OS manages lifecycle)
/// - Shared library instances across all services
/// - Better debugging and monitoring
class SignalLibraryManager {
  static const String _logName = 'SignalLibraryManager';
  
  // Singleton instance
  static final SignalLibraryManager _instance = SignalLibraryManager._internal();
  factory SignalLibraryManager() => _instance;
  SignalLibraryManager._internal();
  
  // Shared library instances (loaded once, shared across all services)
  DynamicLibrary? _mainLib;
  DynamicLibrary? _wrapperLib;
  DynamicLibrary? _bridgeLib;
  
  // Static references to prevent GC during test finalization
  // ignore: unused_field - Intentionally unused to prevent GC
  static DynamicLibrary? _staticMainLib;
  // ignore: unused_field - Intentionally unused to prevent GC
  static DynamicLibrary? _staticWrapperLib;
  // ignore: unused_field - Intentionally unused to prevent GC
  static DynamicLibrary? _staticBridgeLib;
  
  // ... implementation
}
```

**Key Features:**
- Singleton pattern (one instance for entire app)
- Lazy loading (loads on first access)
- Static references (prevent GC)
- Error handling (throws `SignalProtocolException` on failure)
- Logging (detailed logs for debugging)

---

#### **Step 2.2: Implement Library Getters**

**Main Library Getter:**
```dart
/// Get the main Signal Protocol library (libsignal_ffi)
/// 
/// Uses process-level loading for iOS/macOS to reduce SIGABRT crashes.
DynamicLibrary getMainLibrary() {
  if (_mainLib != null) {
    return _mainLib!;
  }
  
  try {
    if (Platform.isIOS || Platform.isMacOS) {
      // iOS/macOS: Framework is embedded, use process-level loading
      developer.log(
        'Loading main library using process-level loading (${Platform.operatingSystem})',
        name: _logName,
      );
      _mainLib = DynamicLibrary.process();
    } else if (Platform.isAndroid) {
      _mainLib = DynamicLibrary.open('libsignal_jni.so');
    } else if (Platform.isLinux) {
      _mainLib = DynamicLibrary.open('libsignal_ffi.so');
    } else if (Platform.isWindows) {
      _mainLib = DynamicLibrary.open('signal_ffi.dll');
    } else {
      throw SignalProtocolException('Unsupported platform: ${Platform.operatingSystem}');
    }
    
    // Keep static reference to prevent GC
    _staticMainLib = _mainLib;
    
    developer.log('✅ Main library loaded successfully', name: _logName);
    return _mainLib!;
  } catch (e, stackTrace) {
    developer.log(
      'Failed to load main library: $e',
      name: _logName,
      error: e,
      stackTrace: stackTrace,
    );
    throw SignalProtocolException('Failed to load main Signal Protocol library: $e');
  }
}
```

**Wrapper Library Getter:**
- Same pattern as main library
- Uses `getWrapperLibrary()` method
- Process-level for iOS/macOS, explicit for others

**Bridge Library Getter:**
- Same pattern as main library
- Uses `getBridgeLibrary()` method
- Process-level for iOS/macOS, explicit for others

---

#### **Step 2.3: Add Lifecycle Management**

**Initialization Tracking:**
```dart
bool get areLibrariesLoaded => 
    _mainLib != null && _wrapperLib != null && _bridgeLib != null;
```

**Disposal (Test-Only):**
```dart
/// Dispose all libraries (test-only, production never calls this)
/// 
/// **Note:** In production, libraries live for app lifetime.
/// This is only for test cleanup.
void dispose() {
  developer.log('Disposing Signal Library Manager', name: _logName);
  _mainLib = null;
  _wrapperLib = null;
  _bridgeLib = null;
  // Note: Static references remain to prevent GC during test finalization
}
```

---

**Phase 2 Checklist:**
- [ ] `SignalLibraryManager` class created
- [ ] Singleton pattern implemented
- [ ] `getMainLibrary()` implemented
- [ ] `getWrapperLibrary()` implemented
- [ ] `getBridgeLibrary()` implemented
- [ ] Process-level loading for iOS/macOS
- [ ] Explicit loading for other platforms
- [ ] Static references for GC prevention
- [ ] Error handling and logging
- [ ] Lifecycle management methods

**Estimated Time:** 2-3 hours

---

### **Phase 3: Update Binding Classes** (1-2 hours)

#### **Step 3.1: Update `SignalFFIBindings`**

**File:** `lib/core/crypto/signal/signal_ffi_bindings.dart`

**Changes:**
1. Add `SignalLibraryManager` instance:
   ```dart
   final SignalLibraryManager _libManager = SignalLibraryManager();
   ```

2. Remove `_loadLibrary()` and `_loadWrapperLibrary()` methods

3. Update `initialize()` to use manager:
   ```dart
   Future<void> initialize() async {
     if (_initialized) return;
     
     // Use unified manager instead of direct loading
     _lib = _libManager.getMainLibrary();
     _wrapperLib = _libManager.getWrapperLibrary();
     
     // ... rest of initialization (function bindings, etc.)
   }
   ```

4. Remove static library references (now in manager):
   - Remove `static DynamicLibrary? _staticLib;`
   - Remove `static DynamicLibrary? _staticWrapperLib;`

5. Keep all function bindings unchanged

**Verification:**
- [ ] Manager instance added
- [ ] Old loading methods removed
- [ ] `initialize()` uses manager
- [ ] Static references removed
- [ ] All function bindings still work

---

#### **Step 3.2: Update `SignalPlatformBridgeBindings`**

**File:** `lib/core/crypto/signal/signal_platform_bridge_bindings.dart`

**Changes:**
1. Add `SignalLibraryManager` instance:
   ```dart
   final SignalLibraryManager _libManager = SignalLibraryManager();
   ```

2. Remove `_loadLibrary()` method

3. Update `initialize()` to use manager:
   ```dart
   Future<void> initialize() async {
     if (_initialized) return;
     
     // Use unified manager
     _lib = _libManager.getBridgeLibrary();
     
     // ... rest of initialization
   }
   ```

**Verification:**
- [ ] Manager instance added
- [ ] Old loading method removed
- [ ] `initialize()` uses manager
- [ ] All function bindings still work

---

#### **Step 3.3: Update `SignalRustWrapperBindings`**

**File:** `lib/core/crypto/signal/signal_rust_wrapper_bindings.dart`

**Changes:**
1. Add `SignalLibraryManager` instance:
   ```dart
   final SignalLibraryManager _libManager = SignalLibraryManager();
   ```

2. Remove `_loadLibrary()` method

3. Update `initialize()` to use manager:
   ```dart
   Future<void> initialize() async {
     if (_initialized) return;
     
     // Use unified manager
     _lib = _libManager.getWrapperLibrary();
     
     // ... rest of initialization
   }
   ```

**Verification:**
- [ ] Manager instance added
- [ ] Old loading method removed
- [ ] `initialize()` uses manager
- [ ] All function bindings still work

---

**Phase 3 Checklist:**
- [ ] `SignalFFIBindings` updated
- [ ] `SignalPlatformBridgeBindings` updated
- [ ] `SignalRustWrapperBindings` updated
- [ ] All old loading code removed
- [ ] All bindings use manager
- [ ] No duplicate library loading
- [ ] All tests still pass

**Estimated Time:** 1-2 hours

---

### **Phase 4: Testing and Validation** (2-3 hours)

#### **Step 4.1: Unit Tests for Library Manager**

**File:** `test/core/crypto/signal/signal_library_manager_test.dart`

**Test Cases:**
1. **Singleton Pattern**
   - Test that `SignalLibraryManager()` returns same instance
   - Test that multiple calls return same instance

2. **Library Loading - iOS**
   - Test `getMainLibrary()` returns `DynamicLibrary`
   - Test `getWrapperLibrary()` returns `DynamicLibrary`
   - Test `getBridgeLibrary()` returns `DynamicLibrary`
   - Test uses `DynamicLibrary.process()` on iOS

3. **Library Loading - macOS**
   - Test `getMainLibrary()` returns `DynamicLibrary`
   - Test uses `DynamicLibrary.process()` on macOS (after framework)

4. **Library Loading - Other Platforms**
   - Test uses `DynamicLibrary.open()` on Android/Linux/Windows
   - Test correct library names per platform

5. **Error Handling**
   - Test throws `SignalProtocolException` on unsupported platform
   - Test throws `SignalProtocolException` on load failure

6. **Lifecycle Management**
   - Test `areLibrariesLoaded` getter
   - Test `dispose()` method (test-only)

**Verification:**
- [ ] All unit tests pass
- [ ] Tests cover all platforms
- [ ] Error cases tested

---

#### **Step 4.2: Integration Tests**

**Files:**
- `test/integration/signal_protocol_e2e_test.dart`
- `test/integration/user_message_encryption_test.dart`

**Test Cases:**
1. **Full Signal Protocol Flow**
   - Test identity key generation
   - Test prekey bundle generation
   - Test X3DH key exchange
   - Test message encryption/decryption

2. **Unified Manager Integration**
   - Test all binding classes use manager
   - Test libraries are shared (same instance)
   - Test no duplicate loading

3. **Regression Tests**
   - Test all existing functionality still works
   - Test no performance regressions
   - Test no memory leaks

**Verification:**
- [ ] All integration tests pass
- [ ] No regressions in functionality
- [ ] Performance is acceptable

---

#### **Step 4.3: Production Readiness**

**Smoke Test:**
1. Initialize Signal Protocol in production-like environment
2. Generate identity key
3. Encrypt/decrypt message
4. Verify no crashes

**Framework Embedding Test:**
1. Build app with frameworks
2. Launch app
3. Verify frameworks load correctly
4. Verify no runtime errors

**Verification:**
- [ ] Smoke test passes
- [ ] Framework embedding works
- [ ] App launches successfully
- [ ] No runtime errors

---

**Phase 4 Checklist:**
- [ ] Unit tests for library manager
- [ ] Integration tests pass
- [ ] Production smoke test passes
- [ ] Framework embedding verified
- [ ] No regressions
- [ ] Performance acceptable

**Estimated Time:** 2-3 hours

---

## 📈 **Success Criteria**

### **Functional Requirements**
- [ ] macOS framework builds successfully
- [ ] Framework embeds in app bundle correctly
- [ ] Unified manager loads all libraries correctly
- [ ] iOS uses `DynamicLibrary.process()` (framework)
- [ ] macOS uses `DynamicLibrary.process()` (framework)
- [ ] All binding classes use manager
- [ ] All existing functionality works
- [ ] No regressions in tests

### **Non-Functional Requirements**
- [ ] All tests pass
- [ ] Production smoke test passes
- [ ] No SIGABRT crashes in production
- [ ] Performance is acceptable
- [ ] Code is maintainable
- [ ] Documentation is complete

---

## 🚨 **Risk Mitigation**

### **Risk 1: Framework Build Fails**

**Probability:** Medium  
**Impact:** High

**Mitigation:**
- Test build process on clean environment first
- Document all build steps
- Keep dylib approach as temporary fallback

**Fallback:**
- Use dylib files with explicit loading
- Migrate to framework later

---

### **Risk 2: Framework Doesn't Embed Correctly**

**Probability:** Low  
**Impact:** High

**Mitigation:**
- Follow iOS framework embedding process (already working)
- Test embedding in Xcode
- Verify library search paths

**Fallback:**
- Manual embedding in Xcode
- Use dylib files temporarily

---

### **Risk 3: Process-Level Loading Doesn't Work**

**Probability:** Low  
**Impact:** Medium

**Mitigation:**
- Test with iOS first (already working)
- Verify framework is embedded correctly
- Test with macOS framework

**Fallback:**
- Use `DynamicLibrary.open()` with framework path
- Keep explicit loading as backup

---

### **Risk 4: Breaking Changes in Binding Classes**

**Probability:** Low  
**Impact:** High

**Mitigation:**
- Update one binding class at a time
- Test after each update
- Keep old code commented until verified

**Fallback:**
- Revert to old loading approach
- Fix issues incrementally

---

## 📝 **Documentation Updates**

### **Files to Update**
1. **`PHASE_14_STATUS.md`**
   - Update status to reflect unified manager implementation
   - Add new section for library manager

2. **`PHASE_14_IMPLEMENTATION_CHECKLIST.md`**
   - Add unified manager tasks
   - Mark framework build tasks

3. **`PHASE_14_SETUP_GUIDE.md`**
   - Update macOS setup instructions
   - Add framework build steps

4. **`PHASE_14_QUICK_START.md`**
   - Update quick start for unified manager
   - Simplify library loading instructions

5. **`README.md`** (if applicable)
   - Update Signal Protocol section
   - Add framework information

---

## 🎯 **Timeline Summary**

### **Week 1: Foundation**

**Day 1-2: Build macOS Framework**
- Build libsignal-ffi for macOS
- Create framework structure
- Build wrapper and bridge libraries
- Embed in Xcode project
- Test framework loads

**Day 3: Unified Library Manager**
- Create `SignalLibraryManager` class
- Implement singleton pattern
- Implement library getters
- Add process-level loading
- Add error handling

**Day 4: Update Binding Classes**
- Update `SignalFFIBindings`
- Update `SignalPlatformBridgeBindings`
- Update `SignalRustWrapperBindings`
- Remove duplicate code
- Verify all bindings work

**Day 5: Testing**
- Unit tests for library manager
- Integration tests
- Production smoke tests
- Verify no regressions
- Update documentation

---

## ✅ **Implementation Checklist**

### **Phase 1: Framework Build**
- [ ] Build libsignal-ffi for macOS
- [ ] Create framework structure
- [ ] Build wrapper library (if separate)
- [ ] Build bridge library (if separate)
- [ ] Create module map
- [ ] Create Info.plist
- [ ] Embed in Xcode project
- [ ] Test framework loads

### **Phase 2: Unified Manager**
- [ ] Create `SignalLibraryManager` class
- [ ] Implement singleton pattern
- [ ] Implement `getMainLibrary()`
- [ ] Implement `getWrapperLibrary()`
- [ ] Implement `getBridgeLibrary()`
- [ ] Add process-level loading (iOS/macOS)
- [ ] Add explicit loading (other platforms)
- [ ] Add static references
- [ ] Add error handling
- [ ] Add logging

### **Phase 3: Binding Updates**
- [ ] Update `SignalFFIBindings`
- [ ] Update `SignalPlatformBridgeBindings`
- [ ] Update `SignalRustWrapperBindings`
- [ ] Remove old loading code
- [ ] Verify all bindings work

### **Phase 4: Testing**
- [ ] Unit tests for manager
- [ ] Integration tests
- [ ] Production smoke tests
- [ ] Framework embedding test
- [ ] Verify no regressions

### **Documentation**
- [ ] Update `PHASE_14_STATUS.md`
- [ ] Update `PHASE_14_IMPLEMENTATION_CHECKLIST.md`
- [ ] Update `PHASE_14_SETUP_GUIDE.md`
- [ ] Update `PHASE_14_QUICK_START.md`

---

## 🔄 **Migration Path**

### **Current State → Target State**

**Before:**
```
SignalFFIBindings
  ├─ _loadLibrary() → DynamicLibrary.open()
  └─ _loadWrapperLibrary() → DynamicLibrary.open()

SignalPlatformBridgeBindings
  └─ _loadLibrary() → DynamicLibrary.open()

SignalRustWrapperBindings
  └─ _loadLibrary() → DynamicLibrary.open()
```

**After:**
```
SignalLibraryManager (Singleton)
  ├─ getMainLibrary() → DynamicLibrary.process() (iOS/macOS)
  ├─ getWrapperLibrary() → DynamicLibrary.process() (iOS/macOS)
  └─ getBridgeLibrary() → DynamicLibrary.process() (iOS/macOS)

SignalFFIBindings
  └─ Uses SignalLibraryManager

SignalPlatformBridgeBindings
  └─ Uses SignalLibraryManager

SignalRustWrapperBindings
  └─ Uses SignalLibraryManager
```

---

## 📚 **References**

### **Related Documents**
- `PHASE_14_STATUS.md` - Current implementation status
- `PHASE_14_HYBRID_IMPLEMENTATION_PLAN.md` - Previous hybrid approach
- `PHASE_14_SIGABRT_FINAL_ANALYSIS.md` - SIGABRT analysis
- `PHASE_14_TEST_STRATEGY_AND_SIGABRT.md` - Test strategy

### **External Resources**
- [Dart FFI Documentation](https://dart.dev/guides/libraries/c-interop)
- [iOS Framework Embedding](https://developer.apple.com/documentation/xcode/embedding-frameworks-in-an-app)
- [macOS Framework Guide](https://developer.apple.com/library/archive/documentation/MacOSX/Conceptual/BPFrameworks/)

---

## 🎉 **Expected Outcomes**

### **Immediate Benefits**
1. ✅ Unified management of all native libraries
2. ✅ Process-level loading on iOS/macOS
3. ✅ Reduced SIGABRT crashes
4. ✅ Better error handling and logging
5. ✅ Easier debugging

### **Long-Term Benefits**
1. ✅ Consistency across platforms
2. ✅ Easier maintenance (one manager)
3. ✅ Standard framework approach
4. ✅ Production stability
5. ✅ Scalability for new platforms

---

**Last Updated:** January 1, 2026  
**Status:** 📋 Planning Complete - Ready for Implementation  
**Next Step:** Begin Phase 1 - Build macOS Framework

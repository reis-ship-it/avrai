# Phase 14: FFI Bindings - Next Steps

**Date:** December 28, 2025  
**Status:** 📋 Analysis Complete - Ready for Implementation  
**Next Step:** Implement FFI Function Bindings

---

## 🔍 **Analysis Results**

### **Key Functions Identified**

From `signal_ffi.h`, the following functions are needed:

1. **Identity Key Management:**
   - `signal_identitykeypair_serialize()` - Serialize identity key pair
   - `signal_identitykeypair_deserialize()` - Deserialize identity key pair
   - `signal_privatekey_generate()` - Generate private key (for identity key)

2. **Prekey Bundle:**
   - `signal_pre_key_bundle_new()` - Create prekey bundle
   - `signal_pre_key_bundle_get_*()` - Get bundle components

3. **Message Encryption/Decryption:**
   - `signal_encrypt_message()` - Encrypt message (Double Ratchet)
   - `signal_decrypt_message()` - Decrypt message (Double Ratchet)
   - `signal_decrypt_pre_key_message()` - Decrypt prekey message (X3DH)

4. **Session Management:**
   - `signal_process_prekey_bundle()` - Process prekey bundle (X3DH key exchange)

### **Store Interface Requirements**

libsignal-ffi uses a **callback-based store interface**:

- `SignalFfiSessionStoreStruct` - Session store callbacks
- `SignalFfiIdentityKeyStoreStruct` - Identity key store callbacks
- `SignalFfiPreKeyStoreStruct` - Prekey store callbacks
- `SignalFfiSignedPreKeyStoreStruct` - Signed prekey store callbacks
- `SignalFfiKyberPreKeyStoreStruct` - Kyber prekey store callbacks

**This means we need to:**
1. Implement Dart callback functions
2. Convert them to C function pointers
3. Pass them to libsignal-ffi functions

---

## 🎯 **Implementation Strategy**

### **Phase 1: Basic Library Loading** (✅ Complete)
- ✅ Library loading implemented
- ✅ Platform-specific paths configured

### **Phase 2: Core Function Bindings** (Next Step)
**⚠️ CRITICAL: Test-Each-Function Approach**

**MANDATORY WORKFLOW:**
1. **Implement ONE function** (e.g., identity key generation)
2. **Write test immediately** (before moving to next function)
3. **Run test and verify** (fix any issues before proceeding)
4. **Only then proceed** to next function

**This prevents:**
- Cascading errors from untested functions
- Difficult debugging of multiple broken functions
- Integration issues from incorrect assumptions

**Implementation Steps:**
1. **Define Function Signatures:**
   - Create typedefs for ONE function at a time
   - Map C types to Dart types
   - **TEST:** Verify typedef compiles

2. **Implement Store Callbacks (as needed):**
   - Create Dart functions for store operations
   - Convert to C function pointers using `Pointer.fromFunction()`
   - **TEST:** Verify callbacks can be called from C

3. **Implement Core Functions (ONE AT A TIME):**
   - Identity key generation → **TEST IMMEDIATELY**
   - Identity key serialization → **TEST IMMEDIATELY**
   - Prekey bundle creation → **TEST IMMEDIATELY**
   - Message encryption → **TEST IMMEDIATELY**
   - Message decryption → **TEST IMMEDIATELY**
   - Session processing → **TEST IMMEDIATELY**

### **Phase 3: Integration** (After Phase 2)
- Connect to `SignalProtocolService`
- Test with real data
- Handle errors gracefully

---

## 📋 **Implementation Checklist**

### **Step 1: Identity Key Generation** (2-3 hours)
- [ ] Define function signature for `signal_privatekey_generate()`
- [ ] **TEST:** Verify function can be looked up and called
- [ ] Implement `generateIdentityKeyPair()` wrapper
- [ ] **TEST:** Verify identity key pair is generated correctly
- [ ] Implement serialization/deserialization
- [ ] **TEST:** Verify round-trip serialization works

### **Step 2: Store Callbacks (Minimal)** (3-4 hours)
- [ ] Implement basic session store callback
- [ ] **TEST:** Verify callback can be called from C
- [ ] Implement basic identity key store callback
- [ ] **TEST:** Verify callback can be called from C
- [ ] Implement basic prekey store callbacks
- [ ] **TEST:** Verify callbacks can be called from C

### **Step 3: Prekey Bundle Creation** (2-3 hours)
- [ ] Define function signature for `signal_pre_key_bundle_new()`
- [ ] **TEST:** Verify function can be looked up
- [ ] Implement `generatePreKeyBundle()` wrapper
- [ ] **TEST:** Verify prekey bundle is created correctly

### **Step 4: X3DH Key Exchange** (3-4 hours)
- [ ] Define function signature for `signal_process_prekey_bundle()`
- [ ] **TEST:** Verify function can be looked up
- [ ] Implement `performX3DHKeyExchange()` wrapper
- [ ] **TEST:** Verify X3DH key exchange creates session

### **Step 5: Message Encryption** (3-4 hours)
- [ ] Define function signature for `signal_encrypt_message()`
- [ ] **TEST:** Verify function can be looked up
- [ ] Implement `encryptMessage()` wrapper
- [ ] **TEST:** Verify message encryption produces valid ciphertext

### **Step 6: Message Decryption** (3-4 hours)
- [ ] Define function signature for `signal_decrypt_message()`
- [ ] **TEST:** Verify function can be looked up
- [ ] Implement `decryptMessage()` wrapper
- [ ] **TEST:** Verify message decryption recovers plaintext

### **Step 7: Error Handling** (2-3 hours)
- [ ] Convert Signal error codes to Dart exceptions
- [ ] **TEST:** Verify errors are handled correctly
- [ ] Handle memory management errors
- [ ] **TEST:** Verify memory is freed correctly
- [ ] Validate inputs
- [ ] **TEST:** Verify invalid inputs are rejected

### **Step 8: Integration Testing** (4-6 hours)
- [ ] End-to-end test: Generate keys → Create bundle → Encrypt → Decrypt
- [ ] **TEST:** Verify full flow works
- [ ] Integration tests with `SignalProtocolService`
- [ ] **TEST:** Verify service integration works
- [ ] Platform-specific tests (Android/iOS)
- [ ] **TEST:** Verify platform-specific behavior

---

## 🔧 **Technical Notes**

### **Memory Management**
- libsignal-ffi uses `SignalOwnedBuffer` for returned data
- Must free buffers after use
- Use `package:ffi/ffi.dart` for memory management

### **Type Conversions**
- `Uint8List` ↔ `Pointer<Uint8>`
- `String` ↔ `Pointer<Utf8>`
- Dart objects ↔ C structs

### **Error Handling**
- All functions return `SignalFfiError*`
- Check for null (success) or extract error code
- Convert to `SignalProtocolException`

---

## 📚 **Reference**

- **C Header:** `native/signal_ffi/libsignal/swift/Sources/SignalFfi/signal_ffi.h`
- **FFI Template:** `lib/core/crypto/signal/signal_ffi_bindings_template.dart`
- **Current Implementation:** `lib/core/crypto/signal/signal_ffi_bindings.dart`
- **Signal Protocol Spec:** https://signal.org/docs/

---

## ⚠️ **Complexity Note**

The callback-based store interface adds significant complexity. 

**MANDATORY APPROACH:**
1. **Test-Each-Function:** Test immediately after implementing each function
2. **Simplified Approach:** Implement minimal store callbacks first
3. **Incremental:** Add functions one at a time
4. **No Skipping Tests:** Never proceed to next function without testing current one

**Why This Matters:**
- FFI errors are difficult to debug
- Multiple broken functions compound debugging difficulty
- Early testing catches issues before they cascade
- Each function builds on previous ones - must be correct

**Testing Requirements:**
- ✅ Write test BEFORE or IMMEDIATELY AFTER implementing function
- ✅ Run test and verify it passes
- ✅ Fix any issues before proceeding
- ✅ Document any platform-specific behavior discovered

**Estimated Total Time:** 18-26 hours for complete implementation (includes testing time)

---

**Status:** Ready to begin Phase 2 implementation! 🚀

# What is FFI? A Complete Explanation

**Date:** December 9, 2025  
**Purpose:** Comprehensive explanation of FFI (Foreign Function Interface) and why it's complex

---

## 🎯 **WHAT IS FFI?**

**FFI (Foreign Function Interface)** is a way for one programming language to **call functions** written in a **different programming language**.

Think of it like this:
- **Dart** (your Flutter app) wants to use a function
- But that function is written in **Rust** (or C, C++, etc.)
- **FFI** is the "bridge" that lets Dart call the Rust function

---

## 🏗️ **HOW FFI WORKS**

### **Simple Analogy**

Imagine you're in a restaurant:

```
You (Dart) → Waiter (FFI) → Kitchen (Rust Library) → Food (Result)
```

1. **You (Dart)** place an order: "I want encrypted data"
2. **Waiter (FFI)** translates your order to the kitchen's language
3. **Kitchen (Rust)** prepares the food (encrypts the data)
4. **Waiter (FFI)** brings the food back to you
5. **You (Dart)** receive the encrypted data

### **Technical Flow**

```
Dart Code
    ↓
FFI Bindings (translation layer)
    ↓
Native Library (Rust/C/C++)
    ↓
Result comes back through FFI
    ↓
Dart Code receives result
```

---

## 💻 **REAL-WORLD EXAMPLE: Calling Rust from Dart**

### **The Rust Library (What You Want to Use)**

Let's say Signal has a Rust library with this function:

```rust
// This is Rust code (you don't write this, Signal wrote it)
pub extern "C" fn signal_encrypt_message(
    plaintext: *const u8,      // Pointer to bytes
    length: i32,                // Length of bytes
    recipient_id: *const c_char, // String
) -> *mut u8 {                  // Returns pointer to encrypted bytes
    // ... encryption happens here ...
    // Returns pointer to encrypted data
}
```

**What this means:**
- Function name: `signal_encrypt_message`
- Takes: plaintext bytes, length, recipient ID
- Returns: pointer to encrypted bytes
- Written in **Rust**, compiled to a **native library** (`.so` on Linux, `.dylib` on macOS, `.dll` on Windows)

### **The Dart Code (What You Write)**

Now you want to call this Rust function from Dart:

```dart
// This is Dart code (you write this)
import 'dart:ffi';  // FFI library
import 'dart:io';

// Step 1: Load the native library
final DynamicLibrary _lib = Platform.isAndroid
    ? DynamicLibrary.open('libsignal_ffi.so')  // Android
    : Platform.isIOS
        ? DynamicLibrary.process()              // iOS
        : DynamicLibrary.open('libsignal_ffi.dylib'); // macOS

// Step 2: Define the function signature (how to call it)
typedef NativeEncryptMessage = Pointer<Uint8> Function(
  Pointer<Uint8> plaintext,  // Pointer to bytes
  Int32 length,              // Length
  Pointer<Utf8> recipientId, // String
);
typedef EncryptMessage = Pointer<Uint8> Function(
  Pointer<Uint8> plaintext,
  int length,
  Pointer<Utf8> recipientId,
);

// Step 3: Look up the function in the library
final encryptMessage = _lib
    .lookup<NativeFunction<NativeEncryptMessage>>('signal_encrypt_message')
    .asFunction<EncryptMessage>();

// Step 4: Use the function
Future<Uint8List> encryptMessageDart(
  Uint8List plaintext,
  String recipientId,
) async {
  // Convert Dart types to C types (this is the complex part!)
  
  // Allocate memory for plaintext
  final plaintextPtr = malloc<Uint8>(plaintext.length);
  plaintextPtr.asTypedList(plaintext.length).setAll(0, plaintext);
  
  // Convert String to C string
  final recipientIdPtr = recipientId.toNativeUtf8();
  
  // Call the Rust function!
  final resultPtr = encryptMessage(
    plaintextPtr,
    plaintext.length,
    recipientIdPtr,
  );
  
  // Convert result back to Dart types
  // (Need to know the length - this is tricky!)
  final resultLength = /* somehow get length */;
  final result = resultPtr.asTypedList(resultLength).toList();
  
  // CRITICAL: Free memory (or you get memory leaks!)
  malloc.free(plaintextPtr);
  malloc.free(recipientIdPtr);
  malloc.free(resultPtr);
  
  return Uint8List.fromList(result);
}
```

---

## ⚠️ **WHY FFI IS COMPLEX**

### **1. Type Conversion**

**The Problem:** Dart types ≠ C/Rust types

| Dart Type | C/Rust Type | Conversion Needed |
|-----------|-------------|-------------------|
| `String` | `*const c_char` | Convert to UTF-8 bytes, allocate memory |
| `Uint8List` | `*const u8` | Allocate memory, copy bytes |
| `int` | `i32` | Usually direct, but need to be careful |
| `List<T>` | `*const T` | Allocate array, copy elements |

**Example of Complexity:**

```dart
// Dart: Simple string
String name = "Hello";

// C: Need to convert to null-terminated UTF-8
// Step 1: Convert to UTF-8 bytes
final bytes = utf8.encode(name);
// Step 2: Allocate memory (one extra byte for null terminator)
final ptr = malloc<Uint8>(bytes.length + 1);
// Step 3: Copy bytes
ptr.asTypedList(bytes.length).setAll(0, bytes);
// Step 4: Add null terminator
ptr[bytes.length] = 0;
// Step 5: Cast to C string type
final cString = ptr.cast<Utf8>();
```

**One line in Dart becomes 5+ lines with memory management!**

### **2. Memory Management**

**The Problem:** C/Rust uses manual memory management, Dart uses garbage collection.

**In Dart (Automatic):**
```dart
String name = "Hello";
// Dart automatically frees memory when done
```

**In FFI (Manual):**
```dart
final ptr = malloc<Uint8>(100);
// ... use ptr ...
malloc.free(ptr);  // MUST free manually or memory leak!
```

**Common Mistakes:**

```dart
// ❌ WRONG: Forgot to free memory
Future<Uint8List> encrypt(Uint8List data) {
  final ptr = malloc<Uint8>(data.length);
  ptr.asTypedList(data.length).setAll(0, data);
  // ... use ptr ...
  // Forgot to free! Memory leak!
  return result;
}

// ✅ CORRECT: Always free memory
Future<Uint8List> encrypt(Uint8List data) {
  final ptr = malloc<Uint8>(data.length);
  try {
    ptr.asTypedList(data.length).setAll(0, data);
    // ... use ptr ...
    return result;
  } finally {
    malloc.free(ptr);  // Always free, even if error occurs
  }
}
```

**Memory Leaks Are Serious:**
- App uses more and more memory
- Eventually crashes
- Hard to debug (memory leaks are silent)

### **3. Platform-Specific Code**

**The Problem:** Different platforms load libraries differently.

**Android:**
```dart
final lib = DynamicLibrary.open('libsignal_ffi.so');
```

**iOS:**
```dart
final lib = DynamicLibrary.process();  // Different!
```

**macOS:**
```dart
final lib = DynamicLibrary.open('libsignal_ffi.dylib');  // Different extension!
```

**Windows:**
```dart
final lib = DynamicLibrary.open('signal_ffi.dll');  // Different again!
```

**Web:**
```dart
// FFI doesn't work on Web at all!
// Need completely different approach (WASM, etc.)
```

**You need platform-specific code for each platform!**

### **4. Error Handling**

**The Problem:** C/Rust errors don't translate to Dart exceptions.

**In Rust:**
```rust
fn encrypt(data: &[u8]) -> Result<Vec<u8>, Error> {
    // Returns Result type
}
```

**In Dart FFI:**
```dart
// How do you know if Rust function failed?
final result = encryptMessage(ptr, length, id);
// Did it succeed? How do you check?
// Rust might return null pointer on error
// Or set an error code somewhere
// You need to handle this manually
```

**Example:**
```dart
final result = encryptMessage(ptr, length, id);
if (result == nullptr) {
  // How do we get the error message?
  // Need to call another function to get error
  final errorCode = getLastError();
  throw Exception('Encryption failed: $errorCode');
}
```

### **5. Function Signatures Must Match Exactly**

**The Problem:** If function signature is wrong, crash or undefined behavior.

**Rust Function:**
```rust
fn encrypt(plaintext: *const u8, length: i32) -> *mut u8
```

**Dart Binding (WRONG):**
```dart
typedef Encrypt = Pointer<Uint8> Function(
  Pointer<Uint8> plaintext,
  int length,  // ❌ WRONG: Should be Int32, not int
);
```

**What Happens:**
- Might work sometimes
- Might crash randomly
- Might corrupt memory
- **Very hard to debug!**

**Dart Binding (CORRECT):**
```dart
typedef Encrypt = Pointer<Uint8> Function(
  Pointer<Uint8> plaintext,
  Int32 length,  // ✅ CORRECT: Matches Rust exactly
);
```

### **6. No Type Safety**

**The Problem:** FFI bypasses Dart's type system.

**In Normal Dart:**
```dart
String encrypt(String data) {
  // Dart compiler checks types
  // Can't pass wrong type
}
```

**In FFI:**
```dart
final result = encryptMessage(
  plaintextPtr,
  length,
  recipientIdPtr,
);
// No type checking!
// If you pass wrong pointer, crash!
// If you pass wrong length, memory corruption!
```

**Example Bug:**
```dart
// ❌ WRONG: Passing wrong type
final result = encryptMessage(
  plaintextPtr,
  "wrong type",  // Should be int, but Dart doesn't catch this!
  recipientIdPtr,
);
// Crashes at runtime, not compile time!
```

---

## 🔧 **REAL-WORLD FFI EXAMPLE: Complete Implementation**

Let's see a complete, working example:

```dart
// lib/core/crypto/signal_ffi_bindings.dart
import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';
import 'package:ffi/ffi.dart';  // Helper library

class SignalFFIBindings {
  // Load the native library
  late final DynamicLibrary _lib;
  
  SignalFFIBindings() {
    _lib = _loadLibrary();
    _initializeBindings();
  }
  
  DynamicLibrary _loadLibrary() {
    if (Platform.isAndroid) {
      return DynamicLibrary.open('libsignal_ffi.so');
    } else if (Platform.isIOS) {
      return DynamicLibrary.process();
    } else if (Platform.isMacOS) {
      return DynamicLibrary.open('libsignal_ffi.dylib');
    } else if (Platform.isWindows) {
      return DynamicLibrary.open('signal_ffi.dll');
    } else {
      throw UnsupportedError('Platform not supported');
    }
  }
  
  // Function signatures
  late final EncryptMessage _encryptMessage;
  late final DecryptMessage _decryptMessage;
  late final GetError _getError;
  
  void _initializeBindings() {
    // Define function signatures
    typedef NativeEncryptMessage = Pointer<Uint8> Function(
      Pointer<Uint8> plaintext,
      Int32 length,
      Pointer<Utf8> recipientId,
      Pointer<Int32> outLength,  // Output: length of encrypted data
    );
    typedef EncryptMessage = Pointer<Uint8> Function(
      Pointer<Uint8> plaintext,
      int length,
      Pointer<Utf8> recipientId,
      Pointer<Int32> outLength,
    );
    
    // Look up functions
    _encryptMessage = _lib
        .lookup<NativeFunction<NativeEncryptMessage>>('signal_encrypt_message')
        .asFunction<EncryptMessage>();
    
    // Similar for decrypt, getError, etc.
  }
  
  /// Encrypt a message
  Future<Uint8List> encrypt(
    Uint8List plaintext,
    String recipientId,
  ) async {
    // Allocate memory for plaintext
    final plaintextPtr = malloc<Uint8>(plaintext.length);
    try {
      plaintextPtr.asTypedList(plaintext.length).setAll(0, plaintext);
      
      // Convert String to C string
      final recipientIdPtr = recipientId.toNativeUtf8();
      try {
        // Allocate memory for output length
        final outLengthPtr = malloc<Int32>();
        try {
          // Call Rust function
          final resultPtr = _encryptMessage(
            plaintextPtr,
            plaintext.length,
            recipientIdPtr,
            outLengthPtr,
          );
          
          // Check for errors (Rust returns null on error)
          if (resultPtr == nullptr) {
            final error = _getError();
            throw Exception('Encryption failed: $error');
          }
          
          // Get output length
          final outLength = outLengthPtr.value;
          
          // Copy result to Dart
          final result = Uint8List.fromList(
            resultPtr.asTypedList(outLength).toList(),
          );
          
          // Free Rust-allocated memory (Rust function provides free function)
          _freeBuffer(resultPtr);
          
          return result;
        } finally {
          malloc.free(outLengthPtr);
        }
      } finally {
        malloc.free(recipientIdPtr);
      }
    } finally {
      malloc.free(plaintextPtr);
    }
  }
  
  // Similar for decrypt, etc.
}
```

**Notice:**
- 3 levels of try/finally for memory management
- Manual pointer management everywhere
- Error checking after every call
- Platform-specific library loading

**This is why FFI is complex!**

---

## 📊 **FFI vs. Pure Dart Comparison**

### **Pure Dart (Approach 2)**

```dart
// Simple and clean
Future<Uint8List> encrypt(Uint8List plaintext) async {
  final cipher = GCMBlockCipher(AESEngine());
  // ... encryption ...
  return encrypted;
}
```

**Pros:**
- ✅ Easy to read
- ✅ Type-safe
- ✅ Automatic memory management
- ✅ Works everywhere (including Web)
- ✅ Easy to debug

### **FFI (Approach 1)**

```dart
// Complex and error-prone
Future<Uint8List> encrypt(Uint8List plaintext) async {
  final ptr = malloc<Uint8>(plaintext.length);
  try {
    ptr.asTypedList(plaintext.length).setAll(0, plaintext);
    final resultPtr = _encryptMessage(ptr, plaintext.length, idPtr, outLenPtr);
    if (resultPtr == nullptr) {
      throw Exception('Failed');
    }
    final result = Uint8List.fromList(resultPtr.asTypedList(outLenPtr.value).toList());
    _freeBuffer(resultPtr);
    return result;
  } finally {
    malloc.free(ptr);
  }
}
```

**Cons:**
- ⚠️ Complex code
- ⚠️ Manual memory management
- ⚠️ No type safety
- ⚠️ Platform-specific
- ⚠️ Hard to debug
- ⚠️ Doesn't work on Web

---

## 🎯 **WHEN TO USE FFI**

**Use FFI when:**
- ✅ You need to use an existing native library
- ✅ Performance is critical (native code is faster)
- ✅ Library is battle-tested and secure
- ✅ You have FFI expertise

**Don't use FFI when:**
- ❌ You can implement in pure Dart
- ❌ You need Web support
- ❌ You want simple, maintainable code
- ❌ You don't have FFI expertise

---

## 💡 **SUMMARY**

**FFI (Foreign Function Interface):**
- Way to call functions from other languages (Rust, C, etc.)
- Complex because of:
  - Type conversion
  - Memory management
  - Platform-specific code
  - Error handling
  - No type safety
- **Why Approach 1 (FFI) is complex:**
  - Need to create bindings
  - Need to manage memory
  - Need platform-specific code
  - Need to handle errors manually

**Why Approach 2 (Pure Dart) is simpler:**
- No FFI needed
- Automatic memory management
- Type-safe
- Works everywhere
- Easier to debug

**Trade-off:**
- **FFI:** More complex, but uses battle-tested library
- **Pure Dart:** Simpler, but you implement everything yourself

---

**Last Updated:** December 9, 2025  
**Status:** Complete Explanation**


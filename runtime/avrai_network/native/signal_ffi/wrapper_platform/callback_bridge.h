// Platform-Specific Callback Bridge for Signal Protocol
// Phase 14: Signal Protocol Implementation - Option 1
//
// This bridge works around Dart FFI limitations by creating function pointers
// in platform-specific code (C/Objective-C/Swift/JNI) that Dart cannot create.

#ifndef SIGNAL_CALLBACK_BRIDGE_H
#define SIGNAL_CALLBACK_BRIDGE_H

#include <stdint.h>
#include <stddef.h>

#ifdef __cplusplus
extern "C" {
#endif

// Forward declaration for CallbackArgs struct (defined in Rust wrapper)
typedef struct CallbackArgs CallbackArgs;

// Dispatch callback function type
// Takes pointer address as u64 (workaround for Dart FFI limitation)
typedef int32_t (*DispatchCallback)(uint64_t args_address);

// Register the Dart dispatch callback
// Option 1: Accept function pointer directly
void signal_register_dispatch_callback(DispatchCallback callback);

// Option 2: Accept function pointer as void* (address)
// This allows Dart to pass the function pointer address without creating a function pointer
void signal_register_dispatch_callback_ptr(void* callback_ptr);

// Option 3: Look up Dart function by name using dlsym
// This avoids needing to create function pointers in Dart!
// Dart exports the function with @pragma('vm:entry-point') and a specific name
void signal_register_dispatch_callback_by_name(const char* function_name);

// Get function pointer for dispatch callback
// Returns the address of a C function that can be called from Rust
// The C function will call the registered Dart callback
void* signal_get_dispatch_function_ptr(void);

#ifdef __cplusplus
}
#endif

#endif // SIGNAL_CALLBACK_BRIDGE_H

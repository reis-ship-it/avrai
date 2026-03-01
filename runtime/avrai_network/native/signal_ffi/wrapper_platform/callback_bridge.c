// Platform-Specific Callback Bridge Implementation (C)
// Phase 14: Signal Protocol Implementation - Option 1
//
// This file implements the callback bridge for macOS/Linux/Windows.
// It creates a C function pointer that can be called from Rust,
// which then calls the registered Dart callback.

#include "callback_bridge.h"
#include <stdlib.h>
#include <dlfcn.h> // For dlsym

// Global storage for the Dart callback
// We store it as a function pointer that can be called from C
static DispatchCallback g_dart_callback = NULL;

// Alternative: Store callback as a void* (function pointer address)
// This allows Dart to pass the function pointer address directly
static void* g_dart_callback_ptr = NULL;

// C wrapper function that Rust can call
// This function matches the signature Rust expects: extern "C" fn(u64) -> c_int
int32_t signal_dispatch_wrapper(uint64_t args_address) {
    if (g_dart_callback == NULL) {
        return 1; // Error: callback not registered
    }
    
    // Call the registered Dart callback
    return g_dart_callback(args_address);
}

// Register the Dart dispatch callback
// Option 1: Accept function pointer directly
void signal_register_dispatch_callback(DispatchCallback callback) {
    g_dart_callback = callback;
}

// Option 2: Accept function pointer as void* (address)
// This allows Dart to pass the function pointer address without creating a function pointer
void signal_register_dispatch_callback_ptr(void* callback_ptr) {
    g_dart_callback_ptr = callback_ptr;
    // Cast to function pointer type
    g_dart_callback = (DispatchCallback)callback_ptr;
}

// Option 3: Look up Dart function by name using dlsym
// This avoids needing to create function pointers in Dart!
// Dart exports the function with @pragma('vm:entry-point') and a specific name
void signal_register_dispatch_callback_by_name(const char* function_name) {
    // Look up the function by name
    void* func_ptr = dlsym(RTLD_DEFAULT, function_name);
    if (func_ptr != NULL) {
        g_dart_callback = (DispatchCallback)func_ptr;
        g_dart_callback_ptr = func_ptr;
    }
}

// Get function pointer for dispatch callback
// Returns the address of signal_dispatch_wrapper
void* signal_get_dispatch_function_ptr(void) {
    return (void*)signal_dispatch_wrapper;
}

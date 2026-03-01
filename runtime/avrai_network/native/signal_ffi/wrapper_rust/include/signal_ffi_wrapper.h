// Signal FFI Wrapper (Rust) - public header
//
// This header exists to satisfy XCFramework packaging requirements.
// The Rust wrapper is loaded/linked via exported symbols looked up through Dart FFI.

#pragma once

#include <stdint.h>

// Registers the Dart dispatch callback.
//
// The callback signature is `int32_t (*)(CallbackArgs*)`, passed opaquely as `void*`.
void spots_rust_register_dispatch_callback(void* callback);

// Function-pointer getters for libsignal-ffi store callback wrappers.
void* spots_rust_get_load_session_wrapper_ptr(void);
void* spots_rust_get_store_session_wrapper_ptr(void);
void* spots_rust_get_get_identity_key_pair_wrapper_ptr(void);
void* spots_rust_get_get_local_registration_id_wrapper_ptr(void);
void* spots_rust_get_save_identity_key_wrapper_ptr(void);
void* spots_rust_get_get_identity_key_wrapper_ptr(void);
void* spots_rust_get_is_trusted_identity_wrapper_ptr(void);

// PreKeyStore
void* spots_rust_get_load_pre_key_wrapper_ptr(void);
void* spots_rust_get_store_pre_key_wrapper_ptr(void);
void* spots_rust_get_remove_pre_key_wrapper_ptr(void);

// SignedPreKeyStore
void* spots_rust_get_load_signed_pre_key_wrapper_ptr(void);
void* spots_rust_get_store_signed_pre_key_wrapper_ptr(void);

// KyberPreKeyStore
void* spots_rust_get_load_kyber_pre_key_wrapper_ptr(void);
void* spots_rust_get_store_kyber_pre_key_wrapper_ptr(void);
void* spots_rust_get_mark_kyber_pre_key_used_wrapper_ptr(void);


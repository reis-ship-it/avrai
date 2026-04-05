// Signal Protocol FFI Wrapper
// Phase 14: Signal Protocol Implementation - Option 1
//
// This wrapper library bridges Dart FFI callbacks with libsignal-ffi's store interface.
// It solves the Dart FFI limitation where complex callback signatures cannot be used
// directly in struct fields.

#ifndef SIGNAL_FFI_WRAPPER_H
#define SIGNAL_FFI_WRAPPER_H

#include <stdint.h>
#include <stddef.h>

// Forward declarations for libsignal-ffi types
// These match the types defined in signal_ffi.h
typedef struct SignalSessionRecord SignalSessionRecord;
typedef struct SignalPrivateKey SignalPrivateKey;
typedef struct SignalPublicKey SignalPublicKey;
typedef struct SignalProtocolAddress SignalProtocolAddress;

// Wrapper structs matching signal_ffi.h
typedef struct {
  SignalSessionRecord *raw;
} SignalMutPointerSessionRecord;

typedef struct {
  const SignalSessionRecord *raw;
} SignalConstPointerSessionRecord;

typedef struct {
  const SignalProtocolAddress *raw;
} SignalConstPointerProtocolAddress;

typedef struct {
  SignalPrivateKey *raw;
} SignalMutPointerPrivateKey;

typedef struct {
  const SignalPublicKey *raw;
} SignalConstPointerPublicKey;

typedef struct {
  SignalPublicKey *raw;
} SignalMutPointerPublicKey;

// ============================================================================
// CALLBACK REGISTRATION FUNCTIONS
// ============================================================================
// These functions are called from Dart to register callbacks.
// Function pointers are passed as void* to avoid Dart FFI limitations.

// Session Store Callbacks
void spots_register_load_session_callback(void* callback);
void spots_register_store_session_callback(void* callback);

// Identity Key Store Callbacks
void spots_register_get_identity_key_pair_callback(void* callback);
void spots_register_get_local_registration_id_callback(void* callback);
void spots_register_save_identity_key_callback(void* callback);
void spots_register_get_identity_key_callback(void* callback);
void spots_register_is_trusted_identity_callback(void* callback);

// ============================================================================
// WRAPPER FUNCTIONS
// ============================================================================
// These functions match libsignal-ffi's expected callback signatures.
// They look up registered Dart callbacks and invoke them.

// Session Store Wrappers
int spots_load_session_wrapper(void *store_ctx, SignalMutPointerSessionRecord *recordp, SignalConstPointerProtocolAddress address);
int spots_store_session_wrapper(void *store_ctx, SignalConstPointerProtocolAddress address, SignalConstPointerSessionRecord record);

// Identity Key Store Wrappers
int spots_get_identity_key_pair_wrapper(void *store_ctx, SignalMutPointerPrivateKey *keyp);
int spots_get_local_registration_id_wrapper(void *store_ctx, uint32_t *idp);
int spots_save_identity_key_wrapper(void *store_ctx, SignalConstPointerProtocolAddress address, SignalConstPointerPublicKey public_key);
int spots_get_identity_key_wrapper(void *store_ctx, SignalMutPointerPublicKey *public_keyp, SignalConstPointerProtocolAddress address);
int spots_is_trusted_identity_wrapper(void *store_ctx, SignalConstPointerProtocolAddress address, SignalConstPointerPublicKey public_key, unsigned int direction);

#endif // SIGNAL_FFI_WRAPPER_H

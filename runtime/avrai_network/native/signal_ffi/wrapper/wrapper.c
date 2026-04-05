// Signal Protocol FFI Wrapper Implementation
// Phase 14: Signal Protocol Implementation - Option 1
//
// This file implements the callback registry and wrapper functions.

#include "wrapper.h"
#include <stdlib.h>
#include <string.h>

// ============================================================================
// CALLBACK REGISTRY
// ============================================================================
// Global storage for registered Dart callbacks.
// Function pointers are stored as void* and cast when called.

// Session Store Callbacks
typedef int (*LoadSessionCallback)(void*, void*, void*);
typedef int (*StoreSessionCallback)(void*, void*, void*);

// Identity Key Store Callbacks
typedef int (*GetIdentityKeyPairCallback)(void*, void*);
typedef int (*GetLocalRegistrationIdCallback)(void*, void*);
typedef int (*SaveIdentityKeyCallback)(void*, void*, void*);
typedef int (*GetIdentityKeyCallback)(void*, void*, void*);
typedef int (*IsTrustedIdentityCallback)(void*, void*, void*, unsigned int);

static LoadSessionCallback g_load_session_callback = NULL;
static StoreSessionCallback g_store_session_callback = NULL;
static GetIdentityKeyPairCallback g_get_identity_key_pair_callback = NULL;
static GetLocalRegistrationIdCallback g_get_local_registration_id_callback = NULL;
static SaveIdentityKeyCallback g_save_identity_key_callback = NULL;
static GetIdentityKeyCallback g_get_identity_key_callback = NULL;
static IsTrustedIdentityCallback g_is_trusted_identity_callback = NULL;

// ============================================================================
// CALLBACK REGISTRATION FUNCTIONS
// ============================================================================

void spots_register_load_session_callback(void* callback) {
    g_load_session_callback = (LoadSessionCallback)callback;
}

void spots_register_store_session_callback(void* callback) {
    g_store_session_callback = (StoreSessionCallback)callback;
}

void spots_register_get_identity_key_pair_callback(void* callback) {
    g_get_identity_key_pair_callback = (GetIdentityKeyPairCallback)callback;
}

void spots_register_get_local_registration_id_callback(void* callback) {
    g_get_local_registration_id_callback = (GetLocalRegistrationIdCallback)callback;
}

void spots_register_save_identity_key_callback(void* callback) {
    g_save_identity_key_callback = (SaveIdentityKeyCallback)callback;
}

void spots_register_get_identity_key_callback(void* callback) {
    g_get_identity_key_callback = (GetIdentityKeyCallback)callback;
}

void spots_register_is_trusted_identity_callback(void* callback) {
    g_is_trusted_identity_callback = (IsTrustedIdentityCallback)callback;
}

// ============================================================================
// WRAPPER FUNCTIONS
// ============================================================================
// These functions match libsignal-ffi's expected callback signatures.
// They convert parameters to void* and invoke the registered Dart callbacks.

int spots_load_session_wrapper(void *store_ctx, SignalMutPointerSessionRecord *recordp, SignalConstPointerProtocolAddress address) {
    if (g_load_session_callback == NULL) {
        return 1; // Error: callback not registered
    }
    
    // Convert parameters to void* for the simplified callback signature
    return g_load_session_callback(store_ctx, (void*)recordp, (void*)&address);
}

int spots_store_session_wrapper(void *store_ctx, SignalConstPointerProtocolAddress address, SignalConstPointerSessionRecord record) {
    if (g_store_session_callback == NULL) {
        return 1; // Error: callback not registered
    }
    
    // Convert parameters to void* for the simplified callback signature
    // Note: We pass address of 'address' and 'record' since they're structs
    return g_store_session_callback(store_ctx, (void*)&address, (void*)&record);
}

int spots_get_identity_key_pair_wrapper(void *store_ctx, SignalMutPointerPrivateKey *keyp) {
    if (g_get_identity_key_pair_callback == NULL) {
        return 1; // Error: callback not registered
    }
    
    return g_get_identity_key_pair_callback(store_ctx, (void*)keyp);
}

int spots_get_local_registration_id_wrapper(void *store_ctx, uint32_t *idp) {
    if (g_get_local_registration_id_callback == NULL) {
        return 1; // Error: callback not registered
    }
    
    return g_get_local_registration_id_callback(store_ctx, (void*)idp);
}

int spots_save_identity_key_wrapper(void *store_ctx, SignalConstPointerProtocolAddress address, SignalConstPointerPublicKey public_key) {
    if (g_save_identity_key_callback == NULL) {
        return 1; // Error: callback not registered
    }
    
    // Convert parameters to void* for the simplified callback signature
    return g_save_identity_key_callback(store_ctx, (void*)&address, (void*)&public_key);
}

int spots_get_identity_key_wrapper(void *store_ctx, SignalMutPointerPublicKey *public_keyp, SignalConstPointerProtocolAddress address) {
    if (g_get_identity_key_callback == NULL) {
        return 1; // Error: callback not registered
    }
    
    // Convert parameters to void* for the simplified callback signature
    return g_get_identity_key_callback(store_ctx, (void*)public_keyp, (void*)&address);
}

int spots_is_trusted_identity_wrapper(void *store_ctx, SignalConstPointerProtocolAddress address, SignalConstPointerPublicKey public_key, unsigned int direction) {
    if (g_is_trusted_identity_callback == NULL) {
        return 1; // Error: callback not registered
    }
    
    // Convert parameters to void* for the simplified callback signature
    return g_is_trusted_identity_callback(store_ctx, (void*)&address, (void*)&public_key, direction);
}

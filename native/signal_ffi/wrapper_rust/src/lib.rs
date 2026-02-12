// Signal Protocol FFI Wrapper (Rust)
// Phase 14: Signal Protocol Implementation - Option 1
//
// This Rust wrapper bridges Dart FFI callbacks with libsignal-ffi's store interface.
// Uses Callback ID Dispatch Pattern to work around Dart FFI limitations.
//
// Architecture:
//   Dart → C FFI → Rust Wrapper (callback ID dispatch) → libsignal-ffi (C library) → Signal Protocol
//
// The Rust wrapper uses callback IDs instead of function pointers:
// 1. Dart registers callbacks with unique IDs (no function pointers needed!)
// 2. Rust wrapper stores callback IDs in a registry
// 3. Single dispatch function (Dart CAN create this - it has only one parameter!)
// 4. Dispatch function receives callback ID + parameters, looks up callback, and invokes it

use std::ffi::{c_int, c_void};
use std::sync::Mutex;

// ============================================================================
// CALLBACK ID DISPATCH SYSTEM
// ============================================================================
// Uses single-parameter struct pattern to work around Dart FFI limitations

// Callback ID type
type CallbackId = u64;

// Callback ID constants (must match Dart callback IDs)
const CALLBACK_ID_LOAD_SESSION: CallbackId = 1;
const CALLBACK_ID_STORE_SESSION: CallbackId = 2;
const CALLBACK_ID_GET_IDENTITY_KEY_PAIR: CallbackId = 3;
const CALLBACK_ID_GET_LOCAL_REGISTRATION_ID: CallbackId = 4;
const CALLBACK_ID_SAVE_IDENTITY_KEY: CallbackId = 5;
const CALLBACK_ID_GET_IDENTITY_KEY: CallbackId = 6;
const CALLBACK_ID_IS_TRUSTED_IDENTITY: CallbackId = 7;
const CALLBACK_ID_LOAD_PRE_KEY: CallbackId = 8;
const CALLBACK_ID_STORE_PRE_KEY: CallbackId = 9;
const CALLBACK_ID_REMOVE_PRE_KEY: CallbackId = 10;
const CALLBACK_ID_LOAD_SIGNED_PRE_KEY: CallbackId = 11;
const CALLBACK_ID_STORE_SIGNED_PRE_KEY: CallbackId = 12;
const CALLBACK_ID_LOAD_KYBER_PRE_KEY: CallbackId = 13;
const CALLBACK_ID_STORE_KYBER_PRE_KEY: CallbackId = 14;
const CALLBACK_ID_MARK_KYBER_PRE_KEY_USED: CallbackId = 15;

// Callback args struct (single parameter for dispatch function)
#[repr(C)]
pub struct CallbackArgs {
    pub callback_id: u64,
    pub store_ctx: *mut c_void,
    pub arg1: *mut c_void,
    pub arg2: *mut c_void,
    pub arg3: *mut c_void,
    pub direction: u32,
}

// Dispatch function type
//
// Dart can create a C function pointer for a single-parameter struct pointer,
// so we pass the CallbackArgs pointer directly (no u64 address encoding).
type DispatchCallback = extern "C" fn(*mut CallbackArgs) -> c_int;

struct CallbackRegistry {
    dispatch: Option<DispatchCallback>,
}

// Global callback registry (thread-safe)
static CALLBACK_REGISTRY: Mutex<CallbackRegistry> = Mutex::new(CallbackRegistry {
    dispatch: None,
});

fn call_dispatch(
    callback_id: CallbackId,
    store_ctx: *mut c_void,
    arg1: *mut c_void,
    arg2: *mut c_void,
    arg3: *mut c_void,
    direction: u32,
) -> c_int {
    let registry = CALLBACK_REGISTRY.lock().unwrap();
    if let Some(dispatch) = registry.dispatch {
        let args = CallbackArgs {
            callback_id,
            store_ctx,
            arg1,
            arg2,
            arg3,
            direction,
        };

        let args_box = Box::new(args);
        let args_ptr = Box::into_raw(args_box);

        let result = dispatch(args_ptr);

        // Free the struct
        unsafe {
            let _ = Box::from_raw(args_ptr);
        }

        result
    } else {
        1 // Error: dispatch callback not registered
    }
}

// ============================================================================
// CALLBACK REGISTRATION FUNCTIONS (CALLED FROM DART)
// ============================================================================
// Dart registers a single dispatch function that handles all callbacks.

#[no_mangle]
pub extern "C" fn spots_rust_register_dispatch_callback(callback: *mut c_void) {
    let callback_fn: DispatchCallback = unsafe { std::mem::transmute(callback) };
    let mut registry = CALLBACK_REGISTRY.lock().unwrap();
    registry.dispatch = Some(callback_fn);
}

// ============================================================================
// FORWARD DECLARATIONS FOR LIBSIGNAL-FFI TYPES
// ============================================================================

#[repr(C)]
pub struct SignalSessionRecord {
    _private: [u8; 0],
}

#[repr(C)]
pub struct SignalProtocolAddress {
    _private: [u8; 0],
}

#[repr(C)]
pub struct SignalPrivateKey {
    _private: [u8; 0],
}

#[repr(C)]
pub struct SignalPublicKey {
    _private: [u8; 0],
}

#[repr(C)]
pub struct SignalPreKeyRecord {
    _private: [u8; 0],
}

#[repr(C)]
pub struct SignalSignedPreKeyRecord {
    _private: [u8; 0],
}

#[repr(C)]
pub struct SignalKyberPreKeyRecord {
    _private: [u8; 0],
}

// Wrapper structs matching libsignal-ffi
#[repr(C)]
pub struct SignalMutPointerSessionRecord {
    pub raw: *mut SignalSessionRecord,
}

#[repr(C)]
pub struct SignalConstPointerSessionRecord {
    pub raw: *const SignalSessionRecord,
}

#[repr(C)]
pub struct SignalConstPointerProtocolAddress {
    pub raw: *const SignalProtocolAddress,
}

#[repr(C)]
pub struct SignalMutPointerPrivateKey {
    pub raw: *mut SignalPrivateKey,
}

#[repr(C)]
pub struct SignalConstPointerPublicKey {
    pub raw: *const SignalPublicKey,
}

#[repr(C)]
pub struct SignalMutPointerPublicKey {
    pub raw: *mut SignalPublicKey,
}

#[repr(C)]
pub struct SignalMutPointerPreKeyRecord {
    pub raw: *mut SignalPreKeyRecord,
}

#[repr(C)]
pub struct SignalConstPointerPreKeyRecord {
    pub raw: *const SignalPreKeyRecord,
}

#[repr(C)]
pub struct SignalMutPointerSignedPreKeyRecord {
    pub raw: *mut SignalSignedPreKeyRecord,
}

#[repr(C)]
pub struct SignalConstPointerSignedPreKeyRecord {
    pub raw: *const SignalSignedPreKeyRecord,
}

#[repr(C)]
pub struct SignalMutPointerKyberPreKeyRecord {
    pub raw: *mut SignalKyberPreKeyRecord,
}

#[repr(C)]
pub struct SignalConstPointerKyberPreKeyRecord {
    pub raw: *const SignalKyberPreKeyRecord,
}

// ============================================================================
// WRAPPER FUNCTIONS (CALLED BY LIBSIGNAL-FFI)
// ============================================================================
// These functions match libsignal-ffi's expected callback signatures.
// They retrieve the Dart callback from the registry and invoke it with the callback ID.

// Load session wrapper
#[no_mangle]
pub extern "C" fn spots_rust_load_session_wrapper(
    store_ctx: *mut c_void,
    recordp: *mut SignalMutPointerSessionRecord,
    address: SignalConstPointerProtocolAddress,
) -> c_int {
    call_dispatch(
        CALLBACK_ID_LOAD_SESSION,
        store_ctx,
        recordp as *mut c_void,
        (&address as *const SignalConstPointerProtocolAddress) as *mut c_void,
        std::ptr::null_mut(),
        0,
    )
}

// Store session wrapper
#[no_mangle]
pub extern "C" fn spots_rust_store_session_wrapper(
    store_ctx: *mut c_void,
    address: SignalConstPointerProtocolAddress,
    record: SignalConstPointerSessionRecord,
) -> c_int {
    call_dispatch(
        CALLBACK_ID_STORE_SESSION,
        store_ctx,
        (&address as *const SignalConstPointerProtocolAddress) as *mut c_void,
        (&record as *const SignalConstPointerSessionRecord) as *mut c_void,
        std::ptr::null_mut(),
        0,
    )
}

// Get identity key pair wrapper
#[no_mangle]
pub extern "C" fn spots_rust_get_identity_key_pair_wrapper(
    store_ctx: *mut c_void,
    keyp: *mut SignalMutPointerPrivateKey,
) -> c_int {
    call_dispatch(
        CALLBACK_ID_GET_IDENTITY_KEY_PAIR,
        store_ctx,
        keyp as *mut c_void,
        std::ptr::null_mut(),
        std::ptr::null_mut(),
        0,
    )
}

// Get local registration ID wrapper
#[no_mangle]
pub extern "C" fn spots_rust_get_local_registration_id_wrapper(
    store_ctx: *mut c_void,
    idp: *mut u32,
) -> c_int {
    call_dispatch(
        CALLBACK_ID_GET_LOCAL_REGISTRATION_ID,
        store_ctx,
        idp as *mut c_void,
        std::ptr::null_mut(),
        std::ptr::null_mut(),
        0,
    )
}

// Save identity key wrapper
#[no_mangle]
pub extern "C" fn spots_rust_save_identity_key_wrapper(
    store_ctx: *mut c_void,
    address: SignalConstPointerProtocolAddress,
    public_key: SignalConstPointerPublicKey,
) -> c_int {
    call_dispatch(
        CALLBACK_ID_SAVE_IDENTITY_KEY,
        store_ctx,
        (&address as *const SignalConstPointerProtocolAddress) as *mut c_void,
        (&public_key as *const SignalConstPointerPublicKey) as *mut c_void,
        std::ptr::null_mut(),
        0,
    )
}

// Get identity key wrapper
#[no_mangle]
pub extern "C" fn spots_rust_get_identity_key_wrapper(
    store_ctx: *mut c_void,
    public_keyp: *mut SignalMutPointerPublicKey,
    address: SignalConstPointerProtocolAddress,
) -> c_int {
    call_dispatch(
        CALLBACK_ID_GET_IDENTITY_KEY,
        store_ctx,
        public_keyp as *mut c_void,
        (&address as *const SignalConstPointerProtocolAddress) as *mut c_void,
        std::ptr::null_mut(),
        0,
    )
}

// Is trusted identity wrapper
#[no_mangle]
pub extern "C" fn spots_rust_is_trusted_identity_wrapper(
    store_ctx: *mut c_void,
    address: SignalConstPointerProtocolAddress,
    public_key: SignalConstPointerPublicKey,
    direction: u32,
) -> c_int {
    call_dispatch(
        CALLBACK_ID_IS_TRUSTED_IDENTITY,
        store_ctx,
        (&address as *const SignalConstPointerProtocolAddress) as *mut c_void,
        (&public_key as *const SignalConstPointerPublicKey) as *mut c_void,
        std::ptr::null_mut(),
        direction,
    )
}

// ============================================================================
// PREKEY STORE WRAPPERS
// ============================================================================

#[no_mangle]
pub extern "C" fn spots_rust_load_pre_key_wrapper(
    store_ctx: *mut c_void,
    recordp: *mut SignalMutPointerPreKeyRecord,
    id: u32,
) -> c_int {
    let id_box = Box::new(id);
    let id_ptr = Box::into_raw(id_box) as *mut c_void;
    let result = call_dispatch(
        CALLBACK_ID_LOAD_PRE_KEY,
        store_ctx,
        recordp as *mut c_void,
        id_ptr,
        std::ptr::null_mut(),
        0,
    );
    unsafe {
        let _ = Box::from_raw(id_ptr as *mut u32);
    }
    result
}

#[no_mangle]
pub extern "C" fn spots_rust_store_pre_key_wrapper(
    store_ctx: *mut c_void,
    id: u32,
    record: SignalConstPointerPreKeyRecord,
) -> c_int {
    let id_box = Box::new(id);
    let id_ptr = Box::into_raw(id_box) as *mut c_void;
    let result = call_dispatch(
        CALLBACK_ID_STORE_PRE_KEY,
        store_ctx,
        (&record as *const SignalConstPointerPreKeyRecord) as *mut c_void,
        id_ptr,
        std::ptr::null_mut(),
        0,
    );
    unsafe {
        let _ = Box::from_raw(id_ptr as *mut u32);
    }
    result
}

#[no_mangle]
pub extern "C" fn spots_rust_remove_pre_key_wrapper(store_ctx: *mut c_void, id: u32) -> c_int {
    let id_box = Box::new(id);
    let id_ptr = Box::into_raw(id_box) as *mut c_void;
    let result = call_dispatch(
        CALLBACK_ID_REMOVE_PRE_KEY,
        store_ctx,
        id_ptr,
        std::ptr::null_mut(),
        std::ptr::null_mut(),
        0,
    );
    unsafe {
        let _ = Box::from_raw(id_ptr as *mut u32);
    }
    result
}

// ============================================================================
// SIGNED PREKEY STORE WRAPPERS
// ============================================================================

#[no_mangle]
pub extern "C" fn spots_rust_load_signed_pre_key_wrapper(
    store_ctx: *mut c_void,
    recordp: *mut SignalMutPointerSignedPreKeyRecord,
    id: u32,
) -> c_int {
    let id_box = Box::new(id);
    let id_ptr = Box::into_raw(id_box) as *mut c_void;
    let result = call_dispatch(
        CALLBACK_ID_LOAD_SIGNED_PRE_KEY,
        store_ctx,
        recordp as *mut c_void,
        id_ptr,
        std::ptr::null_mut(),
        0,
    );
    unsafe {
        let _ = Box::from_raw(id_ptr as *mut u32);
    }
    result
}

#[no_mangle]
pub extern "C" fn spots_rust_store_signed_pre_key_wrapper(
    store_ctx: *mut c_void,
    id: u32,
    record: SignalConstPointerSignedPreKeyRecord,
) -> c_int {
    let id_box = Box::new(id);
    let id_ptr = Box::into_raw(id_box) as *mut c_void;
    let result = call_dispatch(
        CALLBACK_ID_STORE_SIGNED_PRE_KEY,
        store_ctx,
        (&record as *const SignalConstPointerSignedPreKeyRecord) as *mut c_void,
        id_ptr,
        std::ptr::null_mut(),
        0,
    );
    unsafe {
        let _ = Box::from_raw(id_ptr as *mut u32);
    }
    result
}

// ============================================================================
// KYBER PREKEY STORE WRAPPERS
// ============================================================================

#[no_mangle]
pub extern "C" fn spots_rust_load_kyber_pre_key_wrapper(
    store_ctx: *mut c_void,
    recordp: *mut SignalMutPointerKyberPreKeyRecord,
    id: u32,
) -> c_int {
    let id_box = Box::new(id);
    let id_ptr = Box::into_raw(id_box) as *mut c_void;
    let result = call_dispatch(
        CALLBACK_ID_LOAD_KYBER_PRE_KEY,
        store_ctx,
        recordp as *mut c_void,
        id_ptr,
        std::ptr::null_mut(),
        0,
    );
    unsafe {
        let _ = Box::from_raw(id_ptr as *mut u32);
    }
    result
}

#[no_mangle]
pub extern "C" fn spots_rust_store_kyber_pre_key_wrapper(
    store_ctx: *mut c_void,
    id: u32,
    record: SignalConstPointerKyberPreKeyRecord,
) -> c_int {
    let id_box = Box::new(id);
    let id_ptr = Box::into_raw(id_box) as *mut c_void;
    let result = call_dispatch(
        CALLBACK_ID_STORE_KYBER_PRE_KEY,
        store_ctx,
        (&record as *const SignalConstPointerKyberPreKeyRecord) as *mut c_void,
        id_ptr,
        std::ptr::null_mut(),
        0,
    );
    unsafe {
        let _ = Box::from_raw(id_ptr as *mut u32);
    }
    result
}

#[no_mangle]
pub extern "C" fn spots_rust_mark_kyber_pre_key_used_wrapper(
    store_ctx: *mut c_void,
    id: u32,
    signed_prekey_id: u32,
    base_key: SignalConstPointerPublicKey,
) -> c_int {
    let id_box = Box::new(id);
    let id_ptr = Box::into_raw(id_box) as *mut c_void;
    let spk_box = Box::new(signed_prekey_id);
    let spk_ptr = Box::into_raw(spk_box) as *mut c_void;

    let result = call_dispatch(
        CALLBACK_ID_MARK_KYBER_PRE_KEY_USED,
        store_ctx,
        (&base_key as *const SignalConstPointerPublicKey) as *mut c_void,
        id_ptr,
        spk_ptr,
        0,
    );

    unsafe {
        let _ = Box::from_raw(id_ptr as *mut u32);
        let _ = Box::from_raw(spk_ptr as *mut u32);
    }

    result
}

// ============================================================================
// FUNCTION POINTER GETTERS (FOR DART)
// ============================================================================
// These functions return the addresses of the wrapper functions.
// Dart can look up these functions and get their addresses to pass to libsignal-ffi.

#[no_mangle]
pub extern "C" fn spots_rust_get_load_session_wrapper_ptr() -> *mut c_void {
    spots_rust_load_session_wrapper as *mut c_void
}

#[no_mangle]
pub extern "C" fn spots_rust_get_store_session_wrapper_ptr() -> *mut c_void {
    spots_rust_store_session_wrapper as *mut c_void
}

#[no_mangle]
pub extern "C" fn spots_rust_get_get_identity_key_pair_wrapper_ptr() -> *mut c_void {
    spots_rust_get_identity_key_pair_wrapper as *mut c_void
}

#[no_mangle]
pub extern "C" fn spots_rust_get_get_local_registration_id_wrapper_ptr() -> *mut c_void {
    spots_rust_get_local_registration_id_wrapper as *mut c_void
}

#[no_mangle]
pub extern "C" fn spots_rust_get_save_identity_key_wrapper_ptr() -> *mut c_void {
    spots_rust_save_identity_key_wrapper as *mut c_void
}

#[no_mangle]
pub extern "C" fn spots_rust_get_get_identity_key_wrapper_ptr() -> *mut c_void {
    spots_rust_get_identity_key_wrapper as *mut c_void
}

#[no_mangle]
pub extern "C" fn spots_rust_get_is_trusted_identity_wrapper_ptr() -> *mut c_void {
    spots_rust_is_trusted_identity_wrapper as *mut c_void
}

#[no_mangle]
pub extern "C" fn spots_rust_get_load_pre_key_wrapper_ptr() -> *mut c_void {
    spots_rust_load_pre_key_wrapper as *mut c_void
}

#[no_mangle]
pub extern "C" fn spots_rust_get_store_pre_key_wrapper_ptr() -> *mut c_void {
    spots_rust_store_pre_key_wrapper as *mut c_void
}

#[no_mangle]
pub extern "C" fn spots_rust_get_remove_pre_key_wrapper_ptr() -> *mut c_void {
    spots_rust_remove_pre_key_wrapper as *mut c_void
}

#[no_mangle]
pub extern "C" fn spots_rust_get_load_signed_pre_key_wrapper_ptr() -> *mut c_void {
    spots_rust_load_signed_pre_key_wrapper as *mut c_void
}

#[no_mangle]
pub extern "C" fn spots_rust_get_store_signed_pre_key_wrapper_ptr() -> *mut c_void {
    spots_rust_store_signed_pre_key_wrapper as *mut c_void
}

#[no_mangle]
pub extern "C" fn spots_rust_get_load_kyber_pre_key_wrapper_ptr() -> *mut c_void {
    spots_rust_load_kyber_pre_key_wrapper as *mut c_void
}

#[no_mangle]
pub extern "C" fn spots_rust_get_store_kyber_pre_key_wrapper_ptr() -> *mut c_void {
    spots_rust_store_kyber_pre_key_wrapper as *mut c_void
}

#[no_mangle]
pub extern "C" fn spots_rust_get_mark_kyber_pre_key_used_wrapper_ptr() -> *mut c_void {
    spots_rust_mark_kyber_pre_key_used_wrapper as *mut c_void
}

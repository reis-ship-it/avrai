// libsignal-ffi (C FFI) - minimal public header
//
// This is a minimal header used for XCFramework packaging.
// SPOTS loads symbols via Dart FFI by name; headers are not required at runtime.

#pragma once

#include <stdint.h>

// Opaque pointer types used by the C-FFI surface.
typedef struct SignalFfiError SignalFfiError;
typedef struct SignalBorrowedBuffer SignalBorrowedBuffer;
typedef struct SignalOwnedBuffer SignalOwnedBuffer;
typedef struct SignalConstPointerProtocolAddress SignalConstPointerProtocolAddress;
typedef struct SignalConstPointerFfiSessionStoreStruct SignalConstPointerFfiSessionStoreStruct;
typedef struct SignalConstPointerFfiIdentityKeyStoreStruct SignalConstPointerFfiIdentityKeyStoreStruct;
typedef struct SignalConstPointerPreKeyBundle SignalConstPointerPreKeyBundle;
typedef struct SignalMutPointerCiphertextMessage SignalMutPointerCiphertextMessage;
typedef struct SignalConstPointerSignalMessage SignalConstPointerSignalMessage;

// Core session functions used by SPOTS.
SignalFfiError* signal_process_prekey_bundle(
  SignalConstPointerPreKeyBundle bundle,
  SignalConstPointerProtocolAddress protocol_address,
  SignalConstPointerFfiSessionStoreStruct session_store,
  SignalConstPointerFfiIdentityKeyStoreStruct identity_key_store,
  uint64_t now
);

SignalFfiError* signal_encrypt_message(
  SignalMutPointerCiphertextMessage* out,
  SignalBorrowedBuffer ptext,
  SignalConstPointerProtocolAddress protocol_address,
  SignalConstPointerFfiSessionStoreStruct session_store,
  SignalConstPointerFfiIdentityKeyStoreStruct identity_key_store,
  uint64_t now
);

SignalFfiError* signal_decrypt_message(
  SignalOwnedBuffer* out,
  SignalConstPointerSignalMessage message,
  SignalConstPointerProtocolAddress protocol_address,
  SignalConstPointerFfiSessionStoreStruct session_store,
  SignalConstPointerFfiIdentityKeyStoreStruct identity_key_store
);


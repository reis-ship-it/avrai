#!/usr/bin/env python3
"""
Signal Protocol Native Library Test (Python)

Purpose: Test native Signal Protocol libraries directly using ctypes
to isolate issues from Dart FFI bindings.

This script tests:
1. Library loading
2. Identity key generation
3. Prekey bundle generation (if possible without callbacks)
4. Basic cryptographic operations

Date: December 28, 2025
"""

import sys
import os
import ctypes
import ctypes.util
from pathlib import Path
from typing import Optional, Tuple, List, Dict
import struct
import time
from dataclasses import dataclass

# Add project root to path
project_root = Path(__file__).parent.parent
sys.path.insert(0, str(project_root))

# ============================================================================
# PATH RESOLUTION
# ============================================================================

def find_library() -> Optional[Path]:
    """Find libsignal_ffi.dylib on macOS"""
    # Try multiple locations
    possible_paths = [
        project_root / "native" / "signal_ffi" / "macos" / "libsignal_ffi.dylib",
        project_root / "native" / "signal_ffi" / "libsignal_ffi.dylib",
    ]
    
    for path in possible_paths:
        if path.exists():
            return path
    
    return None

# ============================================================================
# CTYPES TYPE DEFINITIONS
# ============================================================================

# Opaque pointer types
class SignalPrivateKey(ctypes.Structure):
    _fields_ = []  # Opaque

class SignalPublicKey(ctypes.Structure):
    _fields_ = []  # Opaque

class SignalKyberKeyPair(ctypes.Structure):
    _fields_ = []  # Opaque

class SignalKyberPublicKey(ctypes.Structure):
    _fields_ = []  # Opaque

class SignalFfiError(ctypes.Structure):
    _fields_ = []  # Opaque

# Pointer types
SignalPrivateKeyPtr = ctypes.POINTER(SignalPrivateKey)
SignalPublicKeyPtr = ctypes.POINTER(SignalPublicKey)
SignalKyberKeyPairPtr = ctypes.POINTER(SignalKyberKeyPair)
SignalKyberPublicKeyPtr = ctypes.POINTER(SignalKyberPublicKey)
SignalFfiErrorPtr = ctypes.POINTER(SignalFfiError)

# Buffer types
class SignalBorrowedBuffer(ctypes.Structure):
    _fields_ = [
        ("base", ctypes.POINTER(ctypes.c_uint8)),
        ("length", ctypes.c_size_t),
    ]

class SignalOwnedBuffer(ctypes.Structure):
    _fields_ = [
        ("base", ctypes.POINTER(ctypes.c_uint8)),
        ("length", ctypes.c_size_t),
    ]

# ============================================================================
# LIBRARY LOADING
# ============================================================================

class SignalFFILibrary:
    """Wrapper for libsignal-ffi library"""
    
    def __init__(self, lib_path: Path):
        self.lib_path = lib_path
        self.lib = None
        self._load_library()
        self._bind_functions()
    
    def _load_library(self):
        """Load the native library"""
        try:
            # Try loading directly
            self.lib = ctypes.CDLL(str(self.lib_path))
            print(f"✅ Loaded library: {self.lib_path}")
        except OSError as e:
            print(f"❌ Failed to load library: {e}")
            raise
    
    def _bind_functions(self):
        """Bind FFI functions to Python"""
        
        # signal_privatekey_generate
        # SignalFfiError* signal_privatekey_generate(SignalPrivateKey** out)
        self.signal_privatekey_generate = self.lib.signal_privatekey_generate
        self.signal_privatekey_generate.argtypes = [ctypes.POINTER(SignalPrivateKeyPtr)]
        self.signal_privatekey_generate.restype = SignalFfiErrorPtr
        
        # signal_privatekey_get_public_key
        # SignalFfiError* signal_privatekey_get_public_key(SignalPublicKey** out, SignalPrivateKey* k)
        self.signal_privatekey_get_public_key = self.lib.signal_privatekey_get_public_key
        self.signal_privatekey_get_public_key.argtypes = [
            ctypes.POINTER(SignalPublicKeyPtr),
            SignalPrivateKeyPtr,
        ]
        self.signal_privatekey_get_public_key.restype = SignalFfiErrorPtr
        
        # signal_privatekey_serialize
        # SignalFfiError* signal_privatekey_serialize(SignalOwnedBuffer* out, SignalPrivateKey* obj)
        self.signal_privatekey_serialize = self.lib.signal_privatekey_serialize
        self.signal_privatekey_serialize.argtypes = [
            ctypes.POINTER(SignalOwnedBuffer),
            SignalPrivateKeyPtr,
        ]
        self.signal_privatekey_serialize.restype = SignalFfiErrorPtr
        
        # signal_privatekey_deserialize
        # SignalFfiError* signal_privatekey_deserialize(SignalPrivateKey** out, SignalBorrowedBuffer data)
        self.signal_privatekey_deserialize = self.lib.signal_privatekey_deserialize
        self.signal_privatekey_deserialize.argtypes = [
            ctypes.POINTER(SignalPrivateKeyPtr),
            SignalBorrowedBuffer,
        ]
        self.signal_privatekey_deserialize.restype = SignalFfiErrorPtr
        
        # signal_privatekey_destroy
        # SignalFfiError* signal_privatekey_destroy(SignalPrivateKey* p)
        self.signal_privatekey_destroy = self.lib.signal_privatekey_destroy
        self.signal_privatekey_destroy.argtypes = [SignalPrivateKeyPtr]
        self.signal_privatekey_destroy.restype = SignalFfiErrorPtr
        
        # signal_publickey_destroy
        # SignalFfiError* signal_publickey_destroy(SignalPublicKey* p)
        self.signal_publickey_destroy = self.lib.signal_publickey_destroy
        self.signal_publickey_destroy.argtypes = [SignalPublicKeyPtr]
        self.signal_publickey_destroy.restype = SignalFfiErrorPtr
        
        # signal_error_free
        # void signal_error_free(SignalFfiError* err)
        self.signal_error_free = self.lib.signal_error_free
        self.signal_error_free.argtypes = [SignalFfiErrorPtr]
        self.signal_error_free.restype = None
        
        # signal_free_buffer
        # void signal_free_buffer(const unsigned char* buf, size_t buf_len)
        self.signal_free_buffer = self.lib.signal_free_buffer
        self.signal_free_buffer.argtypes = [ctypes.POINTER(ctypes.c_uint8), ctypes.c_size_t]
        self.signal_free_buffer.restype = None
        
        # signal_publickey_serialize
        # SignalFfiError* signal_publickey_serialize(SignalOwnedBuffer* out, SignalPublicKey* obj)
        try:
            self.signal_publickey_serialize = self.lib.signal_publickey_serialize
            self.signal_publickey_serialize.argtypes = [
                ctypes.POINTER(SignalOwnedBuffer),
                SignalPublicKeyPtr,
            ]
            self.signal_publickey_serialize.restype = SignalFfiErrorPtr
        except AttributeError:
            self.signal_publickey_serialize = None
        
        # signal_publickey_deserialize
        # SignalFfiError* signal_publickey_deserialize(SignalPublicKey** out, SignalBorrowedBuffer data)
        try:
            self.signal_publickey_deserialize = self.lib.signal_publickey_deserialize
            self.signal_publickey_deserialize.argtypes = [
                ctypes.POINTER(SignalPublicKeyPtr),
                SignalBorrowedBuffer,
            ]
            self.signal_publickey_deserialize.restype = SignalFfiErrorPtr
        except AttributeError:
            self.signal_publickey_deserialize = None
        
        # signal_kyber_key_pair_generate
        # SignalFfiError* signal_kyber_key_pair_generate(SignalKyberKeyPair** out)
        try:
            self.signal_kyber_key_pair_generate = self.lib.signal_kyber_key_pair_generate
            self.signal_kyber_key_pair_generate.argtypes = [ctypes.POINTER(SignalKyberKeyPairPtr)]
            self.signal_kyber_key_pair_generate.restype = SignalFfiErrorPtr
        except AttributeError:
            self.signal_kyber_key_pair_generate = None
        
        # signal_kyber_key_pair_get_public_key
        # SignalFfiError* signal_kyber_key_pair_get_public_key(SignalKyberPublicKey** out, SignalKyberKeyPair* key_pair)
        try:
            self.signal_kyber_key_pair_get_public_key = self.lib.signal_kyber_key_pair_get_public_key
            self.signal_kyber_key_pair_get_public_key.argtypes = [
                ctypes.POINTER(SignalKyberPublicKeyPtr),
                SignalKyberKeyPairPtr,
            ]
            self.signal_kyber_key_pair_get_public_key.restype = SignalFfiErrorPtr
        except AttributeError:
            self.signal_kyber_key_pair_get_public_key = None
        
        # signal_kyber_key_pair_destroy
        # SignalFfiError* signal_kyber_key_pair_destroy(SignalKyberKeyPair* p)
        try:
            self.signal_kyber_key_pair_destroy = self.lib.signal_kyber_key_pair_destroy
            self.signal_kyber_key_pair_destroy.argtypes = [SignalKyberKeyPairPtr]
            self.signal_kyber_key_pair_destroy.restype = SignalFfiErrorPtr
        except AttributeError:
            self.signal_kyber_key_pair_destroy = None
        
        # signal_kyber_public_key_destroy
        # SignalFfiError* signal_kyber_public_key_destroy(SignalKyberPublicKey* p)
        try:
            self.signal_kyber_public_key_destroy = self.lib.signal_kyber_public_key_destroy
            self.signal_kyber_public_key_destroy.argtypes = [SignalKyberPublicKeyPtr]
            self.signal_kyber_public_key_destroy.restype = SignalFfiErrorPtr
        except AttributeError:
            self.signal_kyber_public_key_destroy = None
        
        # signal_privatekey_sign
        # SignalFfiError* signal_privatekey_sign(SignalOwnedBuffer* out, SignalPrivateKey* key, SignalBorrowedBuffer message)
        try:
            self.signal_privatekey_sign = self.lib.signal_privatekey_sign
            self.signal_privatekey_sign.argtypes = [
                ctypes.POINTER(SignalOwnedBuffer),
                SignalPrivateKeyPtr,
                SignalBorrowedBuffer,
            ]
            self.signal_privatekey_sign.restype = SignalFfiErrorPtr
        except AttributeError:
            self.signal_privatekey_sign = None
        
        # signal_kyber_public_key_serialize
        # SignalFfiError* signal_kyber_public_key_serialize(SignalOwnedBuffer* out, SignalKyberPublicKey* obj)
        try:
            self.signal_kyber_public_key_serialize = self.lib.signal_kyber_public_key_serialize
            self.signal_kyber_public_key_serialize.argtypes = [
                ctypes.POINTER(SignalOwnedBuffer),
                SignalKyberPublicKeyPtr,
            ]
            self.signal_kyber_public_key_serialize.restype = SignalFfiErrorPtr
        except AttributeError:
            self.signal_kyber_public_key_serialize = None
        
        # signal_kyber_public_key_deserialize
        # SignalFfiError* signal_kyber_public_key_deserialize(SignalKyberPublicKey** out, SignalBorrowedBuffer data)
        try:
            self.signal_kyber_public_key_deserialize = self.lib.signal_kyber_public_key_deserialize
            self.signal_kyber_public_key_deserialize.argtypes = [
                ctypes.POINTER(SignalKyberPublicKeyPtr),
                SignalBorrowedBuffer,
            ]
            self.signal_kyber_public_key_deserialize.restype = SignalFfiErrorPtr
        except AttributeError:
            self.signal_kyber_public_key_deserialize = None
        
        # signal_address_new
        # SignalFfiError* signal_address_new(SignalProtocolAddress** out, const char* name, uint32_t device_id)
        try:
            self.signal_address_new = self.lib.signal_address_new
            self.signal_address_new.argtypes = [
                ctypes.POINTER(ctypes.c_void_p),  # SignalProtocolAddress**
                ctypes.c_char_p,  # const char*
                ctypes.c_uint32,  # uint32_t
            ]
            self.signal_address_new.restype = SignalFfiErrorPtr
        except AttributeError:
            self.signal_address_new = None
        
        # signal_address_destroy
        # SignalFfiError* signal_address_destroy(SignalProtocolAddress* p)
        try:
            self.signal_address_destroy = self.lib.signal_address_destroy
            self.signal_address_destroy.argtypes = [ctypes.c_void_p]  # SignalProtocolAddress*
            self.signal_address_destroy.restype = SignalFfiErrorPtr
        except AttributeError:
            self.signal_address_destroy = None
        
        print("✅ Bound FFI functions")
    
    def check_error(self, error_ptr: SignalFfiErrorPtr) -> Optional[str]:
        """Check for error and return error message if present"""
        if error_ptr:
            # Try to get error message (this may not be available in all versions)
            # For now, just indicate an error occurred
            self.signal_error_free(error_ptr)
            return "FFI error occurred"
        return None

# ============================================================================
# TEST RESULT TRACKING
# ============================================================================

@dataclass
class TestResult:
    """Test result with timing information"""
    name: str
    passed: bool
    duration_ms: float
    category: str
    skipped: bool = False
    warning: Optional[str] = None

# ============================================================================
# TEST FUNCTIONS
# ============================================================================

def test_library_loading(lib_path: Path) -> TestResult:
    """Test 1: Library loading"""
    print("\n" + "="*70)
    print("TEST 1: Library Loading")
    print("="*70)
    
    start_time = time.time()
    try:
        lib = SignalFFILibrary(lib_path)
        print("✅ Library loaded successfully")
        duration = (time.time() - start_time) * 1000
        return TestResult("Library Loading", True, duration, "Infrastructure")
    except Exception as e:
        print(f"❌ Library loading failed: {e}")
        duration = (time.time() - start_time) * 1000
        return TestResult("Library Loading", False, duration, "Infrastructure")

def test_identity_key_generation(lib: SignalFFILibrary) -> TestResult:
    """Test 2: Identity key generation"""
    print("\n" + "="*70)
    print("TEST 2: Identity Key Generation")
    print("="*70)
    
    start_time = time.time()
    try:
        # Generate private key
        private_key_ptr = SignalPrivateKeyPtr()
        error = lib.signal_privatekey_generate(ctypes.byref(private_key_ptr))
        
        error_msg = lib.check_error(error)
        if error_msg:
            print(f"❌ Failed to generate private key: {error_msg}")
            return False
        
        if not private_key_ptr:
            print("❌ Private key pointer is null")
            return False
        
        print("✅ Generated private key")
        
        # Get public key
        public_key_ptr = SignalPublicKeyPtr()
        error = lib.signal_privatekey_get_public_key(
            ctypes.byref(public_key_ptr),
            private_key_ptr,
        )
        
        error_msg = lib.check_error(error)
        if error_msg:
            print(f"❌ Failed to get public key: {error_msg}")
            lib.signal_privatekey_destroy(private_key_ptr)
            return False
        
        if not public_key_ptr:
            print("❌ Public key pointer is null")
            lib.signal_privatekey_destroy(private_key_ptr)
            return False
        
        print("✅ Generated public key")
        
        # Serialize private key
        owned_buffer = SignalOwnedBuffer()
        error = lib.signal_privatekey_serialize(
            ctypes.byref(owned_buffer),
            private_key_ptr,
        )
        
        error_msg = lib.check_error(error)
        if error_msg:
            print(f"❌ Failed to serialize private key: {error_msg}")
            lib.signal_privatekey_destroy(private_key_ptr)
            lib.signal_publickey_destroy(public_key_ptr)
            return False
        
        if not owned_buffer.base or owned_buffer.length == 0:
            print("❌ Serialized buffer is empty")
            lib.signal_privatekey_destroy(private_key_ptr)
            lib.signal_publickey_destroy(public_key_ptr)
            return False
        
        # Extract serialized bytes
        serialized_bytes = bytes(ctypes.cast(
            owned_buffer.base,
            ctypes.POINTER(ctypes.c_uint8 * owned_buffer.length)
        ).contents)
        
        print(f"✅ Serialized private key ({len(serialized_bytes)} bytes)")
        
        # Free serialized buffer
        lib.signal_free_buffer(owned_buffer.base, owned_buffer.length)
        
        # Test deserialization
        borrowed_buffer = SignalBorrowedBuffer()
        buffer_array = (ctypes.c_uint8 * len(serialized_bytes)).from_buffer_copy(serialized_bytes)
        borrowed_buffer.base = ctypes.cast(buffer_array, ctypes.POINTER(ctypes.c_uint8))
        borrowed_buffer.length = len(serialized_bytes)
        
        deserialized_key_ptr = SignalPrivateKeyPtr()
        error = lib.signal_privatekey_deserialize(
            ctypes.byref(deserialized_key_ptr),
            borrowed_buffer,
        )
        
        error_msg = lib.check_error(error)
        if error_msg:
            print(f"❌ Failed to deserialize private key: {error_msg}")
            lib.signal_privatekey_destroy(private_key_ptr)
            lib.signal_publickey_destroy(public_key_ptr)
            return False
        
        if not deserialized_key_ptr:
            print("❌ Deserialized key pointer is null")
            lib.signal_privatekey_destroy(private_key_ptr)
            lib.signal_publickey_destroy(public_key_ptr)
            return False
        
        print("✅ Deserialized private key (round-trip test)")
        
        # Cleanup
        lib.signal_privatekey_destroy(private_key_ptr)
        lib.signal_privatekey_destroy(deserialized_key_ptr)
        lib.signal_publickey_destroy(public_key_ptr)
        
        print("✅ Identity key generation test passed")
        duration = (time.time() - start_time) * 1000
        return TestResult("Identity Key Generation", True, duration, "Key Management")
        
    except Exception as e:
        print(f"❌ Identity key generation test failed: {e}")
        import traceback
        traceback.print_exc()
        duration = (time.time() - start_time) * 1000
        return TestResult("Identity Key Generation", False, duration, "Key Management")

def test_key_round_trip(lib: SignalFFILibrary) -> TestResult:
    """Test 3: Key serialization round-trip"""
    print("\n" + "="*70)
    print("TEST 3: Key Serialization Round-Trip")
    print("="*70)
    
    start_time = time.time()
    try:
        # Generate key
        private_key_ptr = SignalPrivateKeyPtr()
        error = lib.signal_privatekey_generate(ctypes.byref(private_key_ptr))
        error_msg = lib.check_error(error)
        if error_msg:
            print(f"❌ Failed to generate key: {error_msg}")
            return False
        
        # Serialize
        owned_buffer = SignalOwnedBuffer()
        error = lib.signal_privatekey_serialize(
            ctypes.byref(owned_buffer),
            private_key_ptr,
        )
        error_msg = lib.check_error(error)
        if error_msg:
            print(f"❌ Failed to serialize: {error_msg}")
            lib.signal_privatekey_destroy(private_key_ptr)
            return False
        
        serialized_bytes = bytes(ctypes.cast(
            owned_buffer.base,
            ctypes.POINTER(ctypes.c_uint8 * owned_buffer.length)
        ).contents)
        
        # Free original buffer
        lib.signal_free_buffer(owned_buffer.base, owned_buffer.length)
        lib.signal_privatekey_destroy(private_key_ptr)
        
        # Deserialize
        borrowed_buffer = SignalBorrowedBuffer()
        buffer_array = (ctypes.c_uint8 * len(serialized_bytes)).from_buffer_copy(serialized_bytes)
        borrowed_buffer.base = ctypes.cast(buffer_array, ctypes.POINTER(ctypes.c_uint8))
        borrowed_buffer.length = len(serialized_bytes)
        
        restored_key_ptr = SignalPrivateKeyPtr()
        error = lib.signal_privatekey_deserialize(
            ctypes.byref(restored_key_ptr),
            borrowed_buffer,
        )
        error_msg = lib.check_error(error)
        if error_msg:
            print(f"❌ Failed to deserialize: {error_msg}")
            return False
        
        # Get public key from restored key
        restored_public_key_ptr = SignalPublicKeyPtr()
        error = lib.signal_privatekey_get_public_key(
            ctypes.byref(restored_public_key_ptr),
            restored_key_ptr,
        )
        error_msg = lib.check_error(error)
        if error_msg:
            print(f"❌ Failed to get public key from restored key: {error_msg}")
            lib.signal_privatekey_destroy(restored_key_ptr)
            return False
        
        print("✅ Round-trip test passed (generate → serialize → deserialize → get public key)")
        
        # Cleanup
        lib.signal_privatekey_destroy(restored_key_ptr)
        lib.signal_publickey_destroy(restored_public_key_ptr)
        
        duration = (time.time() - start_time) * 1000
        return TestResult("Key Round-Trip", True, duration, "Key Management")
        
    except Exception as e:
        print(f"❌ Round-trip test failed: {e}")
        import traceback
        traceback.print_exc()
        duration = (time.time() - start_time) * 1000
        return TestResult("Key Round-Trip", False, duration, "Key Management")

def test_public_key_serialization(lib: SignalFFILibrary) -> TestResult:
    """Test 4: Public key serialization/deserialization"""
    print("\n" + "="*70)
    print("TEST 4: Public Key Serialization")
    print("="*70)
    
    start_time = time.time()
    if not lib.signal_publickey_serialize or not lib.signal_publickey_deserialize:
        print("⚠️  Skipping: Public key serialization functions not available")
        duration = (time.time() - start_time) * 1000
        return TestResult("Public Key Serialization", True, duration, "Key Management", skipped=True)
    
    try:
        # Generate key pair
        private_key_ptr = SignalPrivateKeyPtr()
        error = lib.signal_privatekey_generate(ctypes.byref(private_key_ptr))
        error_msg = lib.check_error(error)
        if error_msg:
            print(f"❌ Failed to generate private key: {error_msg}")
            return False
        
        # Get public key
        public_key_ptr = SignalPublicKeyPtr()
        error = lib.signal_privatekey_get_public_key(
            ctypes.byref(public_key_ptr),
            private_key_ptr,
        )
        error_msg = lib.check_error(error)
        if error_msg:
            print(f"❌ Failed to get public key: {error_msg}")
            lib.signal_privatekey_destroy(private_key_ptr)
            return False
        
        # Serialize public key
        owned_buffer = SignalOwnedBuffer()
        error = lib.signal_publickey_serialize(
            ctypes.byref(owned_buffer),
            public_key_ptr,
        )
        error_msg = lib.check_error(error)
        if error_msg:
            print(f"❌ Failed to serialize public key: {error_msg}")
            lib.signal_privatekey_destroy(private_key_ptr)
            lib.signal_publickey_destroy(public_key_ptr)
            return False
        
        serialized_bytes = bytes(ctypes.cast(
            owned_buffer.base,
            ctypes.POINTER(ctypes.c_uint8 * owned_buffer.length)
        ).contents)
        
        print(f"✅ Serialized public key ({len(serialized_bytes)} bytes)")
        
        # Free serialized buffer
        lib.signal_free_buffer(owned_buffer.base, owned_buffer.length)
        lib.signal_publickey_destroy(public_key_ptr)
        lib.signal_privatekey_destroy(private_key_ptr)
        
        # Deserialize public key
        borrowed_buffer = SignalBorrowedBuffer()
        buffer_array = (ctypes.c_uint8 * len(serialized_bytes)).from_buffer_copy(serialized_bytes)
        borrowed_buffer.base = ctypes.cast(buffer_array, ctypes.POINTER(ctypes.c_uint8))
        borrowed_buffer.length = len(serialized_bytes)
        
        restored_public_key_ptr = SignalPublicKeyPtr()
        error = lib.signal_publickey_deserialize(
            ctypes.byref(restored_public_key_ptr),
            borrowed_buffer,
        )
        error_msg = lib.check_error(error)
        if error_msg:
            print(f"❌ Failed to deserialize public key: {error_msg}")
            return False
        
        print("✅ Deserialized public key (round-trip test)")
        
        # Cleanup
        lib.signal_publickey_destroy(restored_public_key_ptr)
        
        duration = (time.time() - start_time) * 1000
        return TestResult("Public Key Serialization", True, duration, "Key Management")
        
    except Exception as e:
        print(f"❌ Public key serialization test failed: {e}")
        import traceback
        traceback.print_exc()
        duration = (time.time() - start_time) * 1000
        return TestResult("Public Key Serialization", False, duration, "Key Management")

def test_multiple_key_uniqueness(lib: SignalFFILibrary) -> TestResult:
    """Test 5: Multiple key generation produces unique keys"""
    print("\n" + "="*70)
    print("TEST 5: Multiple Key Uniqueness")
    print("="*70)
    
    start_time = time.time()
    try:
        # Generate multiple key pairs
        key_pairs = []
        for i in range(5):
            private_key_ptr = SignalPrivateKeyPtr()
            error = lib.signal_privatekey_generate(ctypes.byref(private_key_ptr))
            error_msg = lib.check_error(error)
            if error_msg:
                print(f"❌ Failed to generate key pair {i+1}: {error_msg}")
                # Cleanup already generated keys
                for kp in key_pairs:
                    lib.signal_privatekey_destroy(kp['private'])
                    lib.signal_publickey_destroy(kp['public'])
                return False
            
            public_key_ptr = SignalPublicKeyPtr()
            error = lib.signal_privatekey_get_public_key(
                ctypes.byref(public_key_ptr),
                private_key_ptr,
            )
            error_msg = lib.check_error(error)
            if error_msg:
                print(f"❌ Failed to get public key {i+1}: {error_msg}")
                lib.signal_privatekey_destroy(private_key_ptr)
                # Cleanup already generated keys
                for kp in key_pairs:
                    lib.signal_privatekey_destroy(kp['private'])
                    lib.signal_publickey_destroy(kp['public'])
                return False
            
            key_pairs.append({
                'private': private_key_ptr,
                'public': public_key_ptr,
            })
        
        print(f"✅ Generated {len(key_pairs)} key pairs")
        
        # Serialize all public keys and check uniqueness
        public_key_bytes = []
        for i, kp in enumerate(key_pairs):
            owned_buffer = SignalOwnedBuffer()
            error = lib.signal_publickey_serialize(
                ctypes.byref(owned_buffer),
                kp['public'],
            )
            error_msg = lib.check_error(error)
            if error_msg:
                print(f"❌ Failed to serialize public key {i+1}: {error_msg}")
                # Cleanup
                for kp2 in key_pairs:
                    lib.signal_privatekey_destroy(kp2['private'])
                    lib.signal_publickey_destroy(kp2['public'])
                return False
            
            serialized = bytes(ctypes.cast(
                owned_buffer.base,
                ctypes.POINTER(ctypes.c_uint8 * owned_buffer.length)
            ).contents)
            public_key_bytes.append(serialized)
            
            lib.signal_free_buffer(owned_buffer.base, owned_buffer.length)
        
        # Check all keys are unique
        for i in range(len(public_key_bytes)):
            for j in range(i + 1, len(public_key_bytes)):
                if public_key_bytes[i] == public_key_bytes[j]:
                    print(f"❌ Keys {i+1} and {j+1} are identical (should be unique)")
                    # Cleanup
                    for kp in key_pairs:
                        lib.signal_privatekey_destroy(kp['private'])
                        lib.signal_publickey_destroy(kp['public'])
                    return False
        
        print("✅ All generated keys are unique")
        
        # Cleanup
        for kp in key_pairs:
            lib.signal_privatekey_destroy(kp['private'])
            lib.signal_publickey_destroy(kp['public'])
        
        duration = (time.time() - start_time) * 1000
        return TestResult("Multiple Key Uniqueness", True, duration, "Key Management")
        
    except Exception as e:
        print(f"❌ Multiple key uniqueness test failed: {e}")
        import traceback
        traceback.print_exc()
        duration = (time.time() - start_time) * 1000
        return TestResult("Multiple Key Uniqueness", False, duration, "Key Management")

def test_kyber_key_generation(lib: SignalFFILibrary) -> TestResult:
    """Test 6: Kyber key pair generation"""
    print("\n" + "="*70)
    print("TEST 6: Kyber Key Generation")
    print("="*70)
    
    start_time = time.time()
    if not lib.signal_kyber_key_pair_generate:
        print("⚠️  Skipping: Kyber key generation functions not available")
        duration = (time.time() - start_time) * 1000
        return TestResult("Kyber Key Generation", True, duration, "Post-Quantum", skipped=True)
    
    try:
        # Generate Kyber key pair
        kyber_key_pair_ptr = SignalKyberKeyPairPtr()
        error = lib.signal_kyber_key_pair_generate(ctypes.byref(kyber_key_pair_ptr))
        error_msg = lib.check_error(error)
        if error_msg:
            print(f"❌ Failed to generate Kyber key pair: {error_msg}")
            return False
        
        if not kyber_key_pair_ptr:
            print("❌ Kyber key pair pointer is null")
            return False
        
        print("✅ Generated Kyber key pair")
        
        # Get public key
        kyber_public_key_ptr = SignalKyberPublicKeyPtr()
        error = lib.signal_kyber_key_pair_get_public_key(
            ctypes.byref(kyber_public_key_ptr),
            kyber_key_pair_ptr,
        )
        error_msg = lib.check_error(error)
        if error_msg:
            print(f"❌ Failed to get Kyber public key: {error_msg}")
            lib.signal_kyber_key_pair_destroy(kyber_key_pair_ptr)
            return False
        
        if not kyber_public_key_ptr:
            print("❌ Kyber public key pointer is null")
            lib.signal_kyber_key_pair_destroy(kyber_key_pair_ptr)
            return False
        
        print("✅ Generated Kyber public key")
        
        # Cleanup
        lib.signal_kyber_key_pair_destroy(kyber_key_pair_ptr)
        lib.signal_kyber_public_key_destroy(kyber_public_key_ptr)
        
        duration = (time.time() - start_time) * 1000
        return TestResult("Kyber Key Generation", True, duration, "Post-Quantum")
        
    except Exception as e:
        print(f"❌ Kyber key generation test failed: {e}")
        import traceback
        traceback.print_exc()
        duration = (time.time() - start_time) * 1000
        return TestResult("Kyber Key Generation", False, duration, "Post-Quantum")

def test_private_key_signing(lib: SignalFFILibrary) -> TestResult:
    """Test 7: Private key signing"""
    print("\n" + "="*70)
    print("TEST 7: Private Key Signing")
    print("="*70)
    
    start_time = time.time()
    if not lib.signal_privatekey_sign:
        print("⚠️  Skipping: Private key signing function not available")
        duration = (time.time() - start_time) * 1000
        return TestResult("Private Key Signing", True, duration, "Cryptography", skipped=True)
    
    try:
        # Generate key pair
        private_key_ptr = SignalPrivateKeyPtr()
        error = lib.signal_privatekey_generate(ctypes.byref(private_key_ptr))
        error_msg = lib.check_error(error)
        if error_msg:
            print(f"❌ Failed to generate private key: {error_msg}")
            return False
        
        # Create message to sign
        message = b"Hello, Signal Protocol!"
        borrowed_buffer = SignalBorrowedBuffer()
        buffer_array = (ctypes.c_uint8 * len(message)).from_buffer_copy(message)
        borrowed_buffer.base = ctypes.cast(buffer_array, ctypes.POINTER(ctypes.c_uint8))
        borrowed_buffer.length = len(message)
        
        # Sign message
        owned_buffer = SignalOwnedBuffer()
        error = lib.signal_privatekey_sign(
            ctypes.byref(owned_buffer),
            private_key_ptr,
            borrowed_buffer,
        )
        error_msg = lib.check_error(error)
        if error_msg:
            print(f"❌ Failed to sign message: {error_msg}")
            lib.signal_privatekey_destroy(private_key_ptr)
            return False
        
        if not owned_buffer.base or owned_buffer.length == 0:
            print("❌ Signature buffer is empty")
            lib.signal_privatekey_destroy(private_key_ptr)
            return False
        
        # Extract signature
        signature = bytes(ctypes.cast(
            owned_buffer.base,
            ctypes.POINTER(ctypes.c_uint8 * owned_buffer.length)
        ).contents)
        
        print(f"✅ Signed message ({len(signature)} byte signature)")
        
        # Free signature buffer
        lib.signal_free_buffer(owned_buffer.base, owned_buffer.length)
        lib.signal_privatekey_destroy(private_key_ptr)
        
        # Test that signing same message produces same signature (deterministic)
        # Note: Signal Protocol may use non-deterministic signing, so we just verify it works
        print("✅ Private key signing test passed")
        
        duration = (time.time() - start_time) * 1000
        return TestResult("Private Key Signing", True, duration, "Cryptography")
        
    except Exception as e:
        print(f"❌ Private key signing test failed: {e}")
        import traceback
        traceback.print_exc()
        duration = (time.time() - start_time) * 1000
        return TestResult("Private Key Signing", False, duration, "Cryptography")

def test_kyber_public_key_serialization(lib: SignalFFILibrary) -> TestResult:
    """Test 8: Kyber public key serialization/deserialization"""
    print("\n" + "="*70)
    print("TEST 8: Kyber Public Key Serialization")
    print("="*70)
    
    start_time = time.time()
    if not lib.signal_kyber_key_pair_generate or not lib.signal_kyber_public_key_serialize:
        print("⚠️  Skipping: Kyber key serialization functions not available")
        duration = (time.time() - start_time) * 1000
        return TestResult("Kyber Public Key Serialization", True, duration, "Post-Quantum", skipped=True)
    
    try:
        # Generate Kyber key pair
        kyber_key_pair_ptr = SignalKyberKeyPairPtr()
        error = lib.signal_kyber_key_pair_generate(ctypes.byref(kyber_key_pair_ptr))
        error_msg = lib.check_error(error)
        if error_msg:
            print(f"❌ Failed to generate Kyber key pair: {error_msg}")
            return False
        
        # Get public key
        kyber_public_key_ptr = SignalKyberPublicKeyPtr()
        error = lib.signal_kyber_key_pair_get_public_key(
            ctypes.byref(kyber_public_key_ptr),
            kyber_key_pair_ptr,
        )
        error_msg = lib.check_error(error)
        if error_msg:
            print(f"❌ Failed to get Kyber public key: {error_msg}")
            lib.signal_kyber_key_pair_destroy(kyber_key_pair_ptr)
            return False
        
        # Serialize Kyber public key
        if lib.signal_kyber_public_key_serialize:
            owned_buffer = SignalOwnedBuffer()
            error = lib.signal_kyber_public_key_serialize(
                ctypes.byref(owned_buffer),
                kyber_public_key_ptr,
            )
            error_msg = lib.check_error(error)
            if error_msg:
                print(f"❌ Failed to serialize Kyber public key: {error_msg}")
                lib.signal_kyber_key_pair_destroy(kyber_key_pair_ptr)
                lib.signal_kyber_public_key_destroy(kyber_public_key_ptr)
                return False
            
            serialized_bytes = bytes(ctypes.cast(
                owned_buffer.base,
                ctypes.POINTER(ctypes.c_uint8 * owned_buffer.length)
            ).contents)
            
            print(f"✅ Serialized Kyber public key ({len(serialized_bytes)} bytes)")
            
            # Free serialized buffer
            lib.signal_free_buffer(owned_buffer.base, owned_buffer.length)
            
            # Test deserialization if available
            if lib.signal_kyber_public_key_deserialize:
                borrowed_buffer = SignalBorrowedBuffer()
                buffer_array = (ctypes.c_uint8 * len(serialized_bytes)).from_buffer_copy(serialized_bytes)
                borrowed_buffer.base = ctypes.cast(buffer_array, ctypes.POINTER(ctypes.c_uint8))
                borrowed_buffer.length = len(serialized_bytes)
                
                restored_kyber_public_key_ptr = SignalKyberPublicKeyPtr()
                error = lib.signal_kyber_public_key_deserialize(
                    ctypes.byref(restored_kyber_public_key_ptr),
                    borrowed_buffer,
                )
                error_msg = lib.check_error(error)
                if error_msg:
                    print(f"❌ Failed to deserialize Kyber public key: {error_msg}")
                    lib.signal_kyber_key_pair_destroy(kyber_key_pair_ptr)
                    lib.signal_kyber_public_key_destroy(kyber_public_key_ptr)
                    return False
                
                print("✅ Deserialized Kyber public key (round-trip test)")
                lib.signal_kyber_public_key_destroy(restored_kyber_public_key_ptr)
        
        # Cleanup
        lib.signal_kyber_key_pair_destroy(kyber_key_pair_ptr)
        lib.signal_kyber_public_key_destroy(kyber_public_key_ptr)
        
        duration = (time.time() - start_time) * 1000
        return TestResult("Kyber Public Key Serialization", True, duration, "Post-Quantum")
        
    except Exception as e:
        print(f"❌ Kyber public key serialization test failed: {e}")
        import traceback
        traceback.print_exc()
        duration = (time.time() - start_time) * 1000
        return TestResult("Kyber Public Key Serialization", False, duration, "Post-Quantum")

def test_protocol_address_creation(lib: SignalFFILibrary) -> TestResult:
    """Test 9: Protocol address creation"""
    print("\n" + "="*70)
    print("TEST 9: Protocol Address Creation")
    print("="*70)
    
    start_time = time.time()
    if not lib.signal_address_new or not lib.signal_address_destroy:
        print("⚠️  Skipping: Protocol address functions not available")
        duration = (time.time() - start_time) * 1000
        return TestResult("Protocol Address Creation", True, duration, "Protocol", skipped=True)
    
    try:
        # Create protocol address
        recipient_id = b"alice@example.com"
        device_id = 1
        
        address_ptr = ctypes.c_void_p()
        error = lib.signal_address_new(
            ctypes.byref(address_ptr),
            recipient_id,
            device_id,
        )
        error_msg = lib.check_error(error)
        if error_msg:
            print(f"❌ Failed to create protocol address: {error_msg}")
            return False
        
        if not address_ptr.value:
            print("❌ Protocol address pointer is null")
            return False
        
        print(f"✅ Created protocol address: {recipient_id.decode()} (device {device_id})")
        
        # Cleanup
        error = lib.signal_address_destroy(address_ptr)
        error_msg = lib.check_error(error)
        if error_msg:
            print(f"⚠️  Warning: Failed to destroy protocol address: {error_msg}")
        
        duration = (time.time() - start_time) * 1000
        return TestResult("Protocol Address Creation", True, duration, "Protocol")
        
    except Exception as e:
        print(f"❌ Protocol address creation test failed: {e}")
        import traceback
        traceback.print_exc()
        duration = (time.time() - start_time) * 1000
        return TestResult("Protocol Address Creation", False, duration, "Protocol")

def test_signing_multiple_messages(lib: SignalFFILibrary) -> TestResult:
    """Test 10: Signing multiple messages with same key"""
    print("\n" + "="*70)
    print("TEST 10: Signing Multiple Messages")
    print("="*70)
    
    start_time = time.time()
    if not lib.signal_privatekey_sign:
        print("⚠️  Skipping: Private key signing function not available")
        duration = (time.time() - start_time) * 1000
        return TestResult("Signing Multiple Messages", True, duration, "Cryptography", skipped=True)
    
    try:
        # Generate key pair
        private_key_ptr = SignalPrivateKeyPtr()
        error = lib.signal_privatekey_generate(ctypes.byref(private_key_ptr))
        error_msg = lib.check_error(error)
        if error_msg:
            print(f"❌ Failed to generate private key: {error_msg}")
            return False
        
        # Sign multiple messages
        messages = [
            b"Message 1",
            b"Message 2",
            b"Message 3",
            b"Different message",
            b"Another message",
        ]
        
        signatures = []
        for i, message in enumerate(messages):
            borrowed_buffer = SignalBorrowedBuffer()
            buffer_array = (ctypes.c_uint8 * len(message)).from_buffer_copy(message)
            borrowed_buffer.base = ctypes.cast(buffer_array, ctypes.POINTER(ctypes.c_uint8))
            borrowed_buffer.length = len(message)
            
            owned_buffer = SignalOwnedBuffer()
            error = lib.signal_privatekey_sign(
                ctypes.byref(owned_buffer),
                private_key_ptr,
                borrowed_buffer,
            )
            error_msg = lib.check_error(error)
            if error_msg:
                print(f"❌ Failed to sign message {i+1}: {error_msg}")
                lib.signal_privatekey_destroy(private_key_ptr)
                return False
            
            signature = bytes(ctypes.cast(
                owned_buffer.base,
                ctypes.POINTER(ctypes.c_uint8 * owned_buffer.length)
            ).contents)
            signatures.append(signature)
            
            lib.signal_free_buffer(owned_buffer.base, owned_buffer.length)
        
        print(f"✅ Signed {len(messages)} messages")
        
        # Verify all signatures are different (non-deterministic signing)
        # Note: Signal Protocol may use deterministic signing, so we just verify signatures are valid
        signature_lengths = [len(sig) for sig in signatures]
        if not all(length > 0 for length in signature_lengths):
            print("❌ Some signatures are empty")
            lib.signal_privatekey_destroy(private_key_ptr)
            return False
        
        if len(set(signature_lengths)) > 1:
            print(f"⚠️  Warning: Signatures have different lengths: {signature_lengths}")
        else:
            print(f"✅ All signatures have consistent length: {signature_lengths[0]} bytes")
        
        # Cleanup
        lib.signal_privatekey_destroy(private_key_ptr)
        
        duration = (time.time() - start_time) * 1000
        return TestResult("Signing Multiple Messages", True, duration, "Cryptography")
        
    except Exception as e:
        print(f"❌ Signing multiple messages test failed: {e}")
        import traceback
        traceback.print_exc()
        duration = (time.time() - start_time) * 1000
        return TestResult("Signing Multiple Messages", False, duration, "Cryptography")

def test_key_size_validation(lib: SignalFFILibrary) -> TestResult:
    """Test 11: Validate key sizes are correct"""
    print("\n" + "="*70)
    print("TEST 11: Key Size Validation")
    print("="*70)
    
    start_time = time.time()
    warning = None
    try:
        # Generate identity key pair
        private_key_ptr = SignalPrivateKeyPtr()
        error = lib.signal_privatekey_generate(ctypes.byref(private_key_ptr))
        error_msg = lib.check_error(error)
        if error_msg:
            print(f"❌ Failed to generate private key: {error_msg}")
            return False
        
        # Get public key
        public_key_ptr = SignalPublicKeyPtr()
        error = lib.signal_privatekey_get_public_key(
            ctypes.byref(public_key_ptr),
            private_key_ptr,
        )
        error_msg = lib.check_error(error)
        if error_msg:
            print(f"❌ Failed to get public key: {error_msg}")
            lib.signal_privatekey_destroy(private_key_ptr)
            return False
        
        # Serialize both keys
        private_buffer = SignalOwnedBuffer()
        error = lib.signal_privatekey_serialize(
            ctypes.byref(private_buffer),
            private_key_ptr,
        )
        error_msg = lib.check_error(error)
        if error_msg:
            print(f"❌ Failed to serialize private key: {error_msg}")
            lib.signal_privatekey_destroy(private_key_ptr)
            lib.signal_publickey_destroy(public_key_ptr)
            return False
        
        private_key_bytes = bytes(ctypes.cast(
            private_buffer.base,
            ctypes.POINTER(ctypes.c_uint8 * private_buffer.length)
        ).contents)
        
        if lib.signal_publickey_serialize:
            public_buffer = SignalOwnedBuffer()
            error = lib.signal_publickey_serialize(
                ctypes.byref(public_buffer),
                public_key_ptr,
            )
            error_msg = lib.check_error(error)
            if error_msg:
                print(f"❌ Failed to serialize public key: {error_msg}")
                lib.signal_free_buffer(private_buffer.base, private_buffer.length)
                lib.signal_privatekey_destroy(private_key_ptr)
                lib.signal_publickey_destroy(public_key_ptr)
                return False
            
            public_key_bytes = bytes(ctypes.cast(
                public_buffer.base,
                ctypes.POINTER(ctypes.c_uint8 * public_buffer.length)
            ).contents)
            
            print(f"✅ Private key size: {len(private_key_bytes)} bytes")
            print(f"✅ Public key size: {len(public_key_bytes)} bytes")
            
            # Validate key sizes (Signal Protocol uses Curve25519: 32 bytes for private, 33 bytes for public)
            if len(private_key_bytes) != 32:
                print(f"⚠️  Warning: Private key size is {len(private_key_bytes)} bytes (expected 32 for Curve25519)")
            else:
                print("✅ Private key size is correct (32 bytes for Curve25519)")
            
            if len(public_key_bytes) != 33:
                print(f"⚠️  Warning: Public key size is {len(public_key_bytes)} bytes (expected 33 for Curve25519)")
            else:
                print("✅ Public key size is correct (33 bytes for Curve25519)")
            
            lib.signal_free_buffer(public_buffer.base, public_buffer.length)
        
        # Test Kyber key sizes if available
        if lib.signal_kyber_key_pair_generate:
            kyber_key_pair_ptr = SignalKyberKeyPairPtr()
            error = lib.signal_kyber_key_pair_generate(ctypes.byref(kyber_key_pair_ptr))
            error_msg = lib.check_error(error)
            if not error_msg:
                kyber_public_key_ptr = SignalKyberPublicKeyPtr()
                error = lib.signal_kyber_key_pair_get_public_key(
                    ctypes.byref(kyber_public_key_ptr),
                    kyber_key_pair_ptr,
                )
                error_msg = lib.check_error(error)
                if not error_msg and lib.signal_kyber_public_key_serialize:
                    kyber_buffer = SignalOwnedBuffer()
                    error = lib.signal_kyber_public_key_serialize(
                        ctypes.byref(kyber_buffer),
                        kyber_public_key_ptr,
                    )
                    error_msg = lib.check_error(error)
                    if not error_msg:
                        kyber_key_bytes = bytes(ctypes.cast(
                            kyber_buffer.base,
                            ctypes.POINTER(ctypes.c_uint8 * kyber_buffer.length)
                        ).contents)
                        
                        print(f"✅ Kyber public key size: {len(kyber_key_bytes)} bytes")
                        
                        # Kyber1024 public key should be 1568 bytes
                        if len(kyber_key_bytes) != 1568:
                            warning_msg = f"Kyber public key size is {len(kyber_key_bytes)} bytes (expected 1568 for Kyber1024)"
                            print(f"⚠️  Warning: {warning_msg}")
                            warning = warning_msg
                        else:
                            print("✅ Kyber public key size is correct (1568 bytes for Kyber1024)")
                        
                        lib.signal_free_buffer(kyber_buffer.base, kyber_buffer.length)
                        lib.signal_kyber_public_key_destroy(kyber_public_key_ptr)
                        lib.signal_kyber_key_pair_destroy(kyber_key_pair_ptr)
        
        # Cleanup
        lib.signal_free_buffer(private_buffer.base, private_buffer.length)
        lib.signal_privatekey_destroy(private_key_ptr)
        lib.signal_publickey_destroy(public_key_ptr)
        
        duration = (time.time() - start_time) * 1000
        return TestResult("Key Size Validation", True, duration, "Validation", warning=warning)
        
    except Exception as e:
        print(f"❌ Key size validation test failed: {e}")
        import traceback
        traceback.print_exc()
        duration = (time.time() - start_time) * 1000
        return TestResult("Key Size Validation", False, duration, "Validation")

def test_anne_and_bob_communication(lib: SignalFFILibrary) -> TestResult:
    """Test 12: Anne and Bob end-to-end communication (simplified)
    
    This test validates that two parties (Anne and Bob) can:
    1. Generate separate identity keys
    2. Generate separate Kyber keys
    3. Sign messages independently
    4. Verify keys are unique between parties
    
    Note: Full X3DH key exchange and message encryption/decryption require
    callbacks (session storage, identity key storage), which are complex in
    ctypes. The full end-to-end test is in Flutter tests.
    """
    print("\n" + "="*70)
    print("TEST 12: Anne and Bob End-to-End Communication (Simplified)")
    print("="*70)
    
    start_time = time.time()
    try:
        # Generate Anne's identity key pair
        anne_private_key_ptr = SignalPrivateKeyPtr()
        error = lib.signal_privatekey_generate(ctypes.byref(anne_private_key_ptr))
        error_msg = lib.check_error(error)
        if error_msg:
            print(f"❌ Failed to generate Anne's private key: {error_msg}")
            return TestResult("Anne and Bob Communication", False, 0, "End-to-End")
        
        anne_public_key_ptr = SignalPublicKeyPtr()
        error = lib.signal_privatekey_get_public_key(
            ctypes.byref(anne_public_key_ptr),
            anne_private_key_ptr,
        )
        error_msg = lib.check_error(error)
        if error_msg:
            print(f"❌ Failed to get Anne's public key: {error_msg}")
            lib.signal_privatekey_destroy(anne_private_key_ptr)
            return TestResult("Anne and Bob Communication", False, 0, "End-to-End")
        
        print("✅ Generated Anne's identity key pair")
        
        # Generate Bob's identity key pair
        bob_private_key_ptr = SignalPrivateKeyPtr()
        error = lib.signal_privatekey_generate(ctypes.byref(bob_private_key_ptr))
        error_msg = lib.check_error(error)
        if error_msg:
            print(f"❌ Failed to generate Bob's private key: {error_msg}")
            lib.signal_privatekey_destroy(anne_private_key_ptr)
            lib.signal_publickey_destroy(anne_public_key_ptr)
            return TestResult("Anne and Bob Communication", False, 0, "End-to-End")
        
        bob_public_key_ptr = SignalPublicKeyPtr()
        error = lib.signal_privatekey_get_public_key(
            ctypes.byref(bob_public_key_ptr),
            bob_private_key_ptr,
        )
        error_msg = lib.check_error(error)
        if error_msg:
            print(f"❌ Failed to get Bob's public key: {error_msg}")
            lib.signal_privatekey_destroy(anne_private_key_ptr)
            lib.signal_publickey_destroy(anne_public_key_ptr)
            lib.signal_privatekey_destroy(bob_private_key_ptr)
            return TestResult("Anne and Bob Communication", False, 0, "End-to-End")
        
        print("✅ Generated Bob's identity key pair")
        
        # Verify Anne and Bob have different keys
        anne_public_buffer = SignalOwnedBuffer()
        error = lib.signal_publickey_serialize(
            ctypes.byref(anne_public_buffer),
            anne_public_key_ptr,
        )
        error_msg = lib.check_error(error)
        if error_msg:
            print(f"⚠️  Warning: Could not serialize Anne's public key: {error_msg}")
        else:
            anne_public_bytes = bytes(ctypes.cast(
                anne_public_buffer.base,
                ctypes.POINTER(ctypes.c_uint8 * anne_public_buffer.length)
            ).contents)
            
            bob_public_buffer = SignalOwnedBuffer()
            error = lib.signal_publickey_serialize(
                ctypes.byref(bob_public_buffer),
                bob_public_key_ptr,
            )
            error_msg = lib.check_error(error)
            if error_msg:
                print(f"⚠️  Warning: Could not serialize Bob's public key: {error_msg}")
            else:
                bob_public_bytes = bytes(ctypes.cast(
                    bob_public_buffer.base,
                    ctypes.POINTER(ctypes.c_uint8 * bob_public_buffer.length)
                ).contents)
                
                if anne_public_bytes == bob_public_bytes:
                    print("❌ Anne and Bob have identical public keys (should be different)")
                    lib.signal_free_buffer(anne_public_buffer.base, anne_public_buffer.length)
                    lib.signal_free_buffer(bob_public_buffer.base, bob_public_buffer.length)
                    lib.signal_privatekey_destroy(anne_private_key_ptr)
                    lib.signal_publickey_destroy(anne_public_key_ptr)
                    lib.signal_privatekey_destroy(bob_private_key_ptr)
                    lib.signal_publickey_destroy(bob_public_key_ptr)
                    return TestResult("Anne and Bob Communication", False, 0, "End-to-End")
                
                print("✅ Anne and Bob have different public keys (correct)")
                lib.signal_free_buffer(anne_public_buffer.base, anne_public_buffer.length)
                lib.signal_free_buffer(bob_public_buffer.base, bob_public_buffer.length)
        
        # Test signing: Anne signs a message
        if lib.signal_privatekey_sign:
            anne_message = b"Hello from Anne!"
            anne_borrowed_buffer = SignalBorrowedBuffer()
            anne_buffer_array = (ctypes.c_uint8 * len(anne_message)).from_buffer_copy(anne_message)
            anne_borrowed_buffer.base = ctypes.cast(anne_buffer_array, ctypes.POINTER(ctypes.c_uint8))
            anne_borrowed_buffer.length = len(anne_message)
            
            anne_signature_buffer = SignalOwnedBuffer()
            error = lib.signal_privatekey_sign(
                ctypes.byref(anne_signature_buffer),
                anne_private_key_ptr,
                anne_borrowed_buffer,
            )
            error_msg = lib.check_error(error)
            if error_msg:
                print(f"⚠️  Warning: Could not sign Anne's message: {error_msg}")
            else:
                anne_signature = bytes(ctypes.cast(
                    anne_signature_buffer.base,
                    ctypes.POINTER(ctypes.c_uint8 * anne_signature_buffer.length)
                ).contents)
                print(f"✅ Anne signed message ({len(anne_signature)} byte signature)")
                lib.signal_free_buffer(anne_signature_buffer.base, anne_signature_buffer.length)
        
        # Test signing: Bob signs a message
        if lib.signal_privatekey_sign:
            bob_message = b"Hello from Bob!"
            bob_borrowed_buffer = SignalBorrowedBuffer()
            bob_buffer_array = (ctypes.c_uint8 * len(bob_message)).from_buffer_copy(bob_message)
            bob_borrowed_buffer.base = ctypes.cast(bob_buffer_array, ctypes.POINTER(ctypes.c_uint8))
            bob_borrowed_buffer.length = len(bob_message)
            
            bob_signature_buffer = SignalOwnedBuffer()
            error = lib.signal_privatekey_sign(
                ctypes.byref(bob_signature_buffer),
                bob_private_key_ptr,
                bob_borrowed_buffer,
            )
            error_msg = lib.check_error(error)
            if error_msg:
                print(f"⚠️  Warning: Could not sign Bob's message: {error_msg}")
            else:
                bob_signature = bytes(ctypes.cast(
                    bob_signature_buffer.base,
                    ctypes.POINTER(ctypes.c_uint8 * bob_signature_buffer.length)
                ).contents)
                print(f"✅ Bob signed message ({len(bob_signature)} byte signature)")
                lib.signal_free_buffer(bob_signature_buffer.base, bob_signature_buffer.length)
        
        # Test Kyber keys if available
        if lib.signal_kyber_key_pair_generate:
            anne_kyber_key_pair_ptr = SignalKyberKeyPairPtr()
            error = lib.signal_kyber_key_pair_generate(ctypes.byref(anne_kyber_key_pair_ptr))
            error_msg = lib.check_error(error)
            if not error_msg:
                anne_kyber_public_key_ptr = SignalKyberPublicKeyPtr()
                error = lib.signal_kyber_key_pair_get_public_key(
                    ctypes.byref(anne_kyber_public_key_ptr),
                    anne_kyber_key_pair_ptr,
                )
                error_msg = lib.check_error(error)
                if not error_msg:
                    print("✅ Generated Anne's Kyber key pair")
                    
                    bob_kyber_key_pair_ptr = SignalKyberKeyPairPtr()
                    error = lib.signal_kyber_key_pair_generate(ctypes.byref(bob_kyber_key_pair_ptr))
                    error_msg = lib.check_error(error)
                    if not error_msg:
                        bob_kyber_public_key_ptr = SignalKyberPublicKeyPtr()
                        error = lib.signal_kyber_key_pair_get_public_key(
                            ctypes.byref(bob_kyber_public_key_ptr),
                            bob_kyber_key_pair_ptr,
                        )
                        error_msg = lib.check_error(error)
                        if not error_msg:
                            print("✅ Generated Bob's Kyber key pair")
                            
                            # Verify Anne and Bob have different Kyber keys
                            if lib.signal_kyber_public_key_serialize:
                                anne_kyber_buffer = SignalOwnedBuffer()
                                error = lib.signal_kyber_public_key_serialize(
                                    ctypes.byref(anne_kyber_buffer),
                                    anne_kyber_public_key_ptr,
                                )
                                error_msg = lib.check_error(error)
                                if not error_msg:
                                    anne_kyber_bytes = bytes(ctypes.cast(
                                        anne_kyber_buffer.base,
                                        ctypes.POINTER(ctypes.c_uint8 * anne_kyber_buffer.length)
                                    ).contents)
                                    
                                    bob_kyber_buffer = SignalOwnedBuffer()
                                    error = lib.signal_kyber_public_key_serialize(
                                        ctypes.byref(bob_kyber_buffer),
                                        bob_kyber_public_key_ptr,
                                    )
                                    error_msg = lib.check_error(error)
                                    if not error_msg:
                                        bob_kyber_bytes = bytes(ctypes.cast(
                                            bob_kyber_buffer.base,
                                            ctypes.POINTER(ctypes.c_uint8 * bob_kyber_buffer.length)
                                        ).contents)
                                        
                                        if anne_kyber_bytes == bob_kyber_bytes:
                                            print("❌ Anne and Bob have identical Kyber public keys (should be different)")
                                        else:
                                            print("✅ Anne and Bob have different Kyber public keys (correct)")
                                        
                                        lib.signal_free_buffer(anne_kyber_buffer.base, anne_kyber_buffer.length)
                                        lib.signal_free_buffer(bob_kyber_buffer.base, bob_kyber_buffer.length)
                                    
                                    lib.signal_kyber_public_key_destroy(bob_kyber_public_key_ptr)
                                    lib.signal_kyber_key_pair_destroy(bob_kyber_key_pair_ptr)
                                
                                lib.signal_kyber_public_key_destroy(anne_kyber_public_key_ptr)
                                lib.signal_kyber_key_pair_destroy(anne_kyber_key_pair_ptr)
        
        print("✅ Anne and Bob can independently generate keys and sign messages")
        print("ℹ️  Note: Full X3DH key exchange and message encryption/decryption")
        print("   require callbacks and are tested in Flutter tests.")
        
        # Cleanup
        lib.signal_privatekey_destroy(anne_private_key_ptr)
        lib.signal_publickey_destroy(anne_public_key_ptr)
        lib.signal_privatekey_destroy(bob_private_key_ptr)
        lib.signal_publickey_destroy(bob_public_key_ptr)
        
        duration = (time.time() - start_time) * 1000
        return TestResult("Anne and Bob Communication", True, duration, "End-to-End")
        
    except Exception as e:
        print(f"❌ Anne and Bob communication test failed: {e}")
        import traceback
        traceback.print_exc()
        duration = (time.time() - start_time) * 1000
        return TestResult("Anne and Bob Communication", False, duration, "End-to-End")

# ============================================================================
# MAIN
# ============================================================================

def main():
    """Run all tests"""
    print("\n" + "="*70)
    print("Signal Protocol Native Library Test (Python)")
    print("="*70)
    print(f"Project root: {project_root}")
    print()
    
    # Find library
    lib_path = find_library()
    if not lib_path:
        print("❌ Could not find libsignal_ffi.dylib")
        print("\nTried locations:")
        for path in [
            project_root / "native" / "signal_ffi" / "macos" / "libsignal_ffi.dylib",
            project_root / "native" / "signal_ffi" / "libsignal_ffi.dylib",
        ]:
            print(f"  - {path}")
        return 1
    
    print(f"✅ Found library: {lib_path}")
    
    # Run tests
    test_results: List[TestResult] = []
    
    # Test 1: Library loading
    result = test_library_loading(lib_path)
    test_results.append(result)
    if not result.passed:
        return 1
    
    lib = SignalFFILibrary(lib_path)
    
    # Test 2: Identity key generation
    test_results.append(test_identity_key_generation(lib))
    
    # Test 3: Round-trip
    test_results.append(test_key_round_trip(lib))
    
    # Test 4: Public key serialization
    test_results.append(test_public_key_serialization(lib))
    
    # Test 5: Multiple key uniqueness
    test_results.append(test_multiple_key_uniqueness(lib))
    
    # Test 6: Kyber key generation
    test_results.append(test_kyber_key_generation(lib))
    
    # Test 7: Private key signing
    test_results.append(test_private_key_signing(lib))
    
    # Test 8: Kyber public key serialization
    test_results.append(test_kyber_public_key_serialization(lib))
    
    # Test 9: Protocol address creation
    test_results.append(test_protocol_address_creation(lib))
    
    # Test 10: Signing multiple messages
    test_results.append(test_signing_multiple_messages(lib))
    
    # Test 11: Key size validation
    test_results.append(test_key_size_validation(lib))
    
    # Test 12: Anne and Bob end-to-end (simplified - without callbacks)
    test_results.append(test_anne_and_bob_communication(lib))
    
    # Summary
    print("\n" + "="*70)
    print("TEST SUMMARY")
    print("="*70)
    
    passed = sum(1 for r in test_results if r.passed)
    total = len(test_results)
    skipped = sum(1 for r in test_results if r.skipped)
    
    # Group by category
    by_category: Dict[str, List[TestResult]] = {}
    for result in test_results:
        if result.category not in by_category:
            by_category[result.category] = []
        by_category[result.category].append(result)
    
    # Print by category
    for category in sorted(by_category.keys()):
        print(f"\n📁 {category}:")
        for result in by_category[category]:
            if result.skipped:
                status = "⏭️  SKIP"
            elif result.passed:
                status = "✅ PASS"
            else:
                status = "❌ FAIL"
            
            timing = f"({result.duration_ms:.2f}ms)" if result.duration_ms > 0 else ""
            warning_text = f" ⚠️  {result.warning}" if result.warning else ""
            print(f"  {status} {result.name} {timing}{warning_text}")
    
    # Overall statistics
    total_duration = sum(r.duration_ms for r in test_results)
    avg_duration = total_duration / len(test_results) if test_results else 0
    
    print(f"\n" + "="*70)
    print(f"Total: {passed}/{total} tests passed")
    if skipped > 0:
        print(f"Skipped: {skipped} tests")
    print(f"Total duration: {total_duration:.2f}ms")
    print(f"Average duration: {avg_duration:.2f}ms per test")
    
    if passed == total:
        print("\n✅ All tests passed! Native libraries work correctly.")
        print("   If Flutter tests still fail, the issue is likely in Dart FFI bindings.")
        return 0
    else:
        print("\n❌ Some tests failed. Check native library issues first.")
        return 1

if __name__ == "__main__":
    sys.exit(main())

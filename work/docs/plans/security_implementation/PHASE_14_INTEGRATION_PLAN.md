# Phase 14: Signal Protocol Integration Plan

**Date:** December 28, 2025  
**Status:** 🚀 Integration Planning  
**Option:** Option 1 - libsignal-ffi via FFI

---

## 🎯 **Integration Strategy**

### **Approach: Gradual Migration**
1. **Phase 1:** Create Signal Protocol encryption service (implements `MessageEncryptionService`)
2. **Phase 2:** Add Signal Protocol option to `AI2AIProtocol` (feature flag)
3. **Phase 3:** Add Signal Protocol option to `AnonymousCommunicationProtocol`
4. **Phase 4:** Enable Signal Protocol by default (after testing)
5. **Phase 5:** Remove AES-256-GCM fallback (optional, keep for compatibility)

---

## 📋 **Integration Points**

### **1. AI2AIProtocol** (`lib/core/network/ai2ai_protocol.dart`)

**Current State:**
- Uses AES-256-GCM encryption (`_encrypt()` / `_decrypt()`)
- Single encryption key (`_encryptionKey`)

**Integration Plan:**
```dart
class AI2AIProtocol {
  final SignalProtocolService? _signalProtocol; // Optional Signal Protocol
  final Uint8List? _encryptionKey; // Fallback AES-256-GCM
  
  AI2AIProtocol({
    Uint8List? encryptionKey,
    SignalProtocolService? signalProtocol, // NEW
    UserAnonymizationService? anonymizationService,
  }) : _encryptionKey = encryptionKey,
       _signalProtocol = signalProtocol,
       _anonymizationService = anonymizationService;
  
  Uint8List _encrypt(Uint8List data, {String? recipientId}) {
    // Use Signal Protocol if available and recipientId provided
    if (_signalProtocol != null && recipientId != null) {
      // Signal Protocol encryption (async - needs refactoring)
      // For now, fallback to AES-256-GCM
    }
    
    // Fallback to AES-256-GCM
    return _encryptAES256GCM(data);
  }
}
```

**Challenges:**
- `_encrypt()` is currently synchronous, but Signal Protocol is async
- Need to refactor `encodeMessage()` to be async
- Need recipient ID for Signal Protocol

**Solution:**
- Make `encodeMessage()` async
- Pass `recipientNodeId` to `_encrypt()`
- Use Signal Protocol when available, fallback to AES-256-GCM

---

### **2. AnonymousCommunicationProtocol** (`lib/core/ai2ai/anonymous_communication.dart`)

**Current State:**
- Uses AES-256-GCM encryption (`_encryptPayload()`)
- Already async

**Integration Plan:**
```dart
class AnonymousCommunicationProtocol {
  final SignalProtocolService? _signalProtocol; // Optional Signal Protocol
  
  Future<String> _encryptPayload(
    Map<String, dynamic> payload,
    String keyBase64, // Currently used for AES-256-GCM
    {String? recipientAgentId}, // NEW: For Signal Protocol
  ) async {
    // Use Signal Protocol if available
    if (_signalProtocol != null && recipientAgentId != null) {
      final plaintext = jsonEncode(payload);
      final plaintextBytes = Uint8List.fromList(utf8.encode(plaintext));
      
      final encrypted = await _signalProtocol.encryptMessage(
        plaintext: plaintextBytes,
        recipientId: recipientAgentId,
      );
      
      return base64Encode(encrypted.toBytes());
    }
    
    // Fallback to AES-256-GCM
    return _encryptPayloadAES256GCM(payload, keyBase64);
  }
}
```

**Challenges:**
- Need `recipientAgentId` in `_encryptPayload()` calls
- Need to update all call sites

**Solution:**
- Add `recipientAgentId` parameter to `_encryptPayload()`
- Update call sites to pass `targetAgentId`

---

### **3. MessageEncryptionService Interface**

**Current State:**
- `AES256GCMEncryptionService` implements `MessageEncryptionService`
- Used by various services

**Integration Plan:**
- ✅ Created `SignalProtocolEncryptionService` (implements `MessageEncryptionService`)
- Services can switch between encryption types via DI

**Usage:**
```dart
// In injection_container.dart
// Option 1: Use Signal Protocol
sl.registerLazySingleton<MessageEncryptionService>(
  () => SignalProtocolEncryptionService(
    signalProtocol: sl<SignalProtocolService>(),
    agentId: sl<AgentIdService>().getAgentId(),
  ),
);

// Option 2: Use AES-256-GCM (fallback)
sl.registerLazySingleton<MessageEncryptionService>(
  () => AES256GCMEncryptionService(),
);
```

---

## 🔧 **Implementation Steps**

### **Step 1: Create Signal Protocol Encryption Service** ✅
- ✅ Created `SignalProtocolEncryptionService`
- ✅ Implements `MessageEncryptionService`
- ✅ Uses `SignalProtocolService` internally

### **Step 2: Update AI2AIProtocol** ⏳
- ⏳ Add `SignalProtocolService` as optional dependency
- ⏳ Make `encodeMessage()` async
- ⏳ Update `_encrypt()` to use Signal Protocol when available
- ⏳ Keep AES-256-GCM as fallback

### **Step 3: Update AnonymousCommunicationProtocol** ⏳
- ⏳ Add `SignalProtocolService` as optional dependency
- ⏳ Update `_encryptPayload()` to use Signal Protocol
- ⏳ Add `recipientAgentId` parameter
- ⏳ Keep AES-256-GCM as fallback

### **Step 4: Update Dependency Injection** ⏳
- ⏳ Register `SignalProtocolEncryptionService`
- ⏳ Add `SignalProtocolService` to `AI2AIProtocol`
- ⏳ Add `SignalProtocolService` to `AnonymousCommunicationProtocol`

### **Step 5: Testing** ⏳
- ⏳ Unit tests for integration
- ⏳ Integration tests
- ⏳ End-to-end tests

---

## ⚠️ **Important Notes**

### **Async Refactoring**
- `AI2AIProtocol.encodeMessage()` is currently synchronous
- Signal Protocol encryption is async
- Need to make `encodeMessage()` async (breaking change)

### **Backward Compatibility**
- Keep AES-256-GCM as fallback
- Support both encryption types during migration
- Feature flag to enable/disable Signal Protocol

### **Recipient ID Requirement**
- Signal Protocol requires recipient ID for key exchange
- Need to ensure recipient ID is available at encryption time
- May need to refactor message encoding flow

---

## 📝 **Next Steps**

1. ⏳ Refactor `AI2AIProtocol.encodeMessage()` to be async
2. ⏳ Add Signal Protocol integration to `AI2AIProtocol`
3. ⏳ Add Signal Protocol integration to `AnonymousCommunicationProtocol`
4. ⏳ Update dependency injection
5. ⏳ Create integration tests

---

**Last Updated:** December 28, 2025  
**Status:** Integration Planning Complete - Ready for Implementation

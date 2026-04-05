# Phase 14: Signal Protocol Integration Readiness

**Date:** December 28, 2025  
**Status:** ✅ Framework Ready - Protocols Need Update  
**Option:** Option 1 - libsignal-ffi via FFI

---

## 🔍 **Current State Analysis**

### **✅ Ready Components**

1. **Signal Protocol Services**
   - ✅ `SignalProtocolService` - High-level API
   - ✅ `SignalProtocolEncryptionService` - Implements `MessageEncryptionService`
   - ✅ `SignalProtocolInitializationService` - App startup initialization

2. **Integration Helpers**
   - ✅ `AI2AIProtocolSignalIntegration` - Helper for AI2AIProtocol
   - ✅ `AnonymousCommunicationSignalIntegration` - Helper for AnonymousCommunicationProtocol

3. **Infrastructure**
   - ✅ Database migration (`signal_prekey_bundles`)
   - ✅ Dependency injection configured
   - ✅ `MessageEncryptionService` interface ready

### **⏳ Protocols Need Update**

#### **AI2AIProtocol** (`lib/core/network/ai2ai_protocol.dart`)
**Current State:**
- Uses `Uint8List? _encryptionKey` directly
- Has `_encrypt()` and `_decrypt()` methods using AES-256-GCM
- Does NOT use `MessageEncryptionService`

**Needs:**
- Update constructor to accept `MessageEncryptionService`
- Replace `_encrypt()` calls with `encryptionService.encrypt()`
- Replace `_decrypt()` calls with `encryptionService.decrypt()`
- Use `AI2AIProtocolSignalIntegration` helper for Signal Protocol

**Integration Helper Ready:** ✅ `AI2AIProtocolSignalIntegration`

#### **AnonymousCommunicationProtocol** (`lib/core/ai2ai/anonymous_communication.dart`)
**Current State:**
- Uses internal `_encryptPayload()` and `_decryptPayload()` methods
- Does NOT use `MessageEncryptionService`

**Needs:**
- Update constructor to accept `MessageEncryptionService`
- Replace `_encryptPayload()` calls with `encryptionService.encrypt()`
- Replace `_decryptPayload()` calls with `encryptionService.decrypt()`
- Use `AnonymousCommunicationSignalIntegration` helper for Signal Protocol

**Integration Helper Ready:** ✅ `AnonymousCommunicationSignalIntegration`

---

## 📋 **Integration Steps (After FFI Bindings)**

### **Step 1: Update AI2AIProtocol**

1. **Update Constructor:**
```dart
AI2AIProtocol({
  MessageEncryptionService? encryptionService, // NEW
  UserAnonymizationService? anonymizationService,
}) : _encryptionService = encryptionService ?? AES256GCMEncryptionService(),
     _anonymizationService = anonymizationService;
```

2. **Update `encodeMessage()`:**
```dart
// Replace _encrypt() with:
final encryptedMessage = await _encryptionService.encrypt(
  json,
  recipientNodeId ?? senderNodeId,
);
encryptedBytes = encryptedMessage.encryptedContent;
```

3. **Update `decodeMessage()`:**
```dart
// Replace _decrypt() with:
final decryptedJson = await _encryptionService.decrypt(
  EncryptedMessage(
    encryptedContent: packet.data,
    encryptionType: _encryptionService.encryptionType,
  ),
  message.senderId,
);
decryptedBytes = Uint8List.fromList(utf8.encode(decryptedJson));
```

4. **Use Integration Helper:**
```dart
final signalIntegration = AI2AIProtocolSignalIntegration(
  signalProtocol: sl<SignalProtocolService>(),
);

if (signalIntegration.isAvailable) {
  // Use Signal Protocol
} else {
  // Use AES-256-GCM fallback
}
```

### **Step 2: Update AnonymousCommunicationProtocol**

1. **Update Constructor:**
```dart
AnonymousCommunicationProtocol({
  MessageEncryptionService? encryptionService, // NEW
  required SupabaseClient supabase,
  required AtomicClockService atomicClock,
  required UserAnonymizationService anonymizationService,
}) : _encryptionService = encryptionService ?? AES256GCMEncryptionService(),
     _supabase = supabase,
     _atomicClock = atomicClock,
     _anonymizationService = anonymizationService;
```

2. **Update `_encryptPayload()`:**
```dart
final payloadJson = jsonEncode(payload);
final encryptedMessage = await _encryptionService.encrypt(
  payloadJson,
  targetAgentId,
);
return encryptedMessage.encryptedData; // Base64 string
```

3. **Update `_decryptPayload()`:**
```dart
final decryptedPlaintext = await _encryptionService.decrypt(
  EncryptedMessage.fromBase64(
    encryptedBase64,
    _encryptionService.encryptionType,
  ),
  senderAgentId,
);
return jsonDecode(decryptedPlaintext) as Map<String, dynamic>;
```

4. **Use Integration Helper:**
```dart
final signalIntegration = AnonymousCommunicationSignalIntegration(
  signalProtocol: sl<SignalProtocolService>(),
);

if (signalIntegration.isAvailable) {
  // Use Signal Protocol
} else {
  // Use AES-256-GCM fallback
}
```

### **Step 3: Update Dependency Injection**

**Current:**
```dart
sl.registerLazySingleton(() => AI2AIProtocol());
```

**Update to:**
```dart
sl.registerLazySingleton(() => AI2AIProtocol(
  encryptionService: sl<MessageEncryptionService>(),
  anonymizationService: sl<UserAnonymizationService>(),
));
```

**For AnonymousCommunicationProtocol:**
```dart
sl.registerLazySingleton(() => AnonymousCommunicationProtocol(
  encryptionService: sl<MessageEncryptionService>(),
  supabase: sl<SupabaseClient>(),
  atomicClock: sl<AtomicClockService>(),
  anonymizationService: sl<UserAnonymizationService>(),
));
```

---

## ⚠️ **Important Notes**

1. **Backward Compatibility:**
   - Default to `AES256GCMEncryptionService` if no service provided
   - Signal Protocol will be used automatically when available
   - No breaking changes to existing code

2. **Async Methods:**
   - `encodeMessage()` and `decodeMessage()` may need to become async
   - Check all call sites before making changes

3. **Error Handling:**
   - Signal Protocol errors should fallback to AES-256-GCM
   - Integration helpers handle this automatically

4. **Testing:**
   - Test with AES-256-GCM first (current behavior)
   - Test with Signal Protocol after FFI bindings complete
   - Test fallback scenarios

---

## ✅ **Readiness Checklist**

- [x] Signal Protocol services created
- [x] Integration helpers created
- [x] `MessageEncryptionService` interface ready
- [x] Database migration complete
- [x] Dependency injection configured
- [ ] FFI bindings implemented (required first)
- [ ] `AI2AIProtocol` updated to use `MessageEncryptionService`
- [ ] `AnonymousCommunicationProtocol` updated to use `MessageEncryptionService`
- [ ] Dependency injection updated
- [ ] Tests written
- [ ] Integration tested

---

## 🎯 **Next Steps**

1. **Complete FFI Bindings** (Phase 14.3)
   - This is the prerequisite for protocol integration

2. **Update Protocols** (Phase 14.4-14.5)
   - Use integration helpers
   - Follow steps above

3. **Test Integration** (Phase 14.6)
   - Unit tests
   - Integration tests
   - End-to-end tests

---

**Last Updated:** December 28, 2025  
**Status:** Framework Ready - Protocols Need Update After FFI Bindings

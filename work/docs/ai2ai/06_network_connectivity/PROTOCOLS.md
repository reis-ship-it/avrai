# AI2AI Protocols

**Created:** December 8, 2025, 5:25 PM CST  
**Purpose:** Documentation for AI2AI communication protocols

---

## 🎯 **Overview**

The AI2AI protocol handles message encoding/decoding, encryption, and connection management for AI2AI network communication.

**Key Principle:** All messages must use anonymized data only. No UnifiedUser data allowed in payloads.

---

## 🏗️ **Protocol Structure**

### **Protocol Message**

```dart
class ProtocolMessage {
  final String version;
  final MessageType type;
  final String senderId;
  final String? recipientId;
  final DateTime timestamp;
  final Map<String, dynamic> payload;
}
```

**Code Reference:**
- `lib/core/network/ai2ai_protocol.dart` - Protocol implementation

---

## 🔒 **Security**

### **Encryption**

- Messages encrypted before transmission
- Encryption key derived from shared secret
- Checksum validation for integrity

### **Validation**

- **CRITICAL:** No UnifiedUser data in payloads
- All user data must be AnonymousUser
- Protocol validates before encoding

**Code Reference:**
```37:81:lib/core/network/ai2ai_protocol.dart
```

---

## 📋 **Message Types**

### **Connection Request**

- Request to establish AI2AI connection
- Includes anonymized personality data
- Includes compatibility score

### **Connection Response**

- Accept/reject connection request
- Includes compatibility assessment
- Includes connection parameters

### **Learning Exchange**

- Exchange learning insights
- Anonymized data only
- Privacy-preserving

---

## 🔗 **Related Documentation**

- **Device Discovery:** [`DEVICE_DISCOVERY.md`](./DEVICE_DISCOVERY.md)
- **BLE Implementation:** [`BLE_IMPLEMENTATION.md`](./BLE_IMPLEMENTATION.md)
- **Privacy Protection:** [`../07_privacy_security/PRIVACY_PROTECTION.md`](../07_privacy_security/PRIVACY_PROTECTION.md)

---

**Last Updated:** December 8, 2025, 5:25 PM CST  
**Status:** Protocols Documentation Complete


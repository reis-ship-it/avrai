# AI2AI Chat Architecture

**Date:** December 14, 2025  
**Status:** ✅ Implemented  
**Purpose:** Chat service routing through ai2ai network while showing real business/expert identities

---

## 🎯 **Overview**

The chat service routes messages through the **ai2ai network** (encrypted in transit) while displaying **real business and expert identities** in the chat UI. Messages are stored **locally in Sembast** for offline access.

---

## 🏗️ **Architecture**

### **Key Principles:**

1. **Routing:** Messages routed through ai2ai network (encrypted in transit)
2. **Identities:** Real business/expert names visible to participants in chat UI
3. **Storage:** All messages stored locally in Sembast (offline-first)
4. **Encryption:** Messages encrypted with MessageEncryptionService (AES-256-GCM, Signal Protocol ready)

### **Flow:**

```
Business/Expert → Encrypt Message → Route via AI2AI Network → Decrypt → Store Locally → Display in Chat UI
```

---

## 📦 **Components**

### **1. BusinessExpertChatServiceAI2AI**

**Location:** `lib/core/services/business_expert_chat_service_ai2ai.dart`

**Features:**
- Routes messages through `AnonymousCommunicationProtocol`
- Stores messages locally in Sembast
- Includes participant identities in message payload
- Encrypts messages with `MessageEncryptionService`
- Shows real business/expert names in chat UI

**Key Methods:**
- `sendMessage()` - Send message via ai2ai network
- `getMessageHistory()` - Get messages from local Sembast storage
- `subscribeToMessages()` - Real-time message subscription
- `markAsRead()` - Mark message as read
- `getUnreadCount()` - Get unread message count

### **2. Local Storage (Sembast)**

**Stores:**
- Messages: `business_expert_messages` store
- Conversations: `business_expert_conversations` store

**Benefits:**
- Fast local access
- Works offline
- No database dependency
- Privacy-preserving (data stays on device)

### **3. AI2AI Network Routing**

**Uses:** `AnonymousCommunicationProtocol`

**Message Payload Includes:**
- Message content (encrypted)
- Participant identities (business_id, expert_id)
- Business/expert names (for display)
- Message metadata (type, timestamp, etc.)

**Encryption:**
- Payload encrypted by ai2ai protocol in transit
- Additional encryption via MessageEncryptionService
- Signal Protocol ready (can swap encryption service)

---

## 🔐 **Security Model**

### **Encryption Layers:**

1. **MessageEncryptionService** (AES-256-GCM)
   - Encrypts message content
   - Can be swapped for Signal Protocol later

2. **AI2AI Protocol Encryption**
   - Encrypts entire payload in transit
   - Routes through privacy network

### **Identity Visibility:**

- **In Transit:** Encrypted (ai2ai network)
- **In Chat UI:** Real names visible to participants
- **In Storage:** Local only (Sembast)

---

## 📊 **Data Flow**

### **Sending a Message:**

1. User types message in chat UI
2. Service encrypts message with `MessageEncryptionService`
3. Creates message with participant identities
4. Stores message locally in Sembast
5. Routes message through ai2ai network (encrypted payload)
6. Recipient receives via ai2ai network
7. Recipient decrypts and stores locally
8. Chat UI displays message with real names

### **Receiving a Message:**

1. Message arrives via ai2ai network
2. Decrypt payload
3. Extract participant identities
4. Decrypt message content
5. Store locally in Sembast
6. Display in chat UI with real names

---

## 🎨 **Chat UI Display**

**Shows:**
- Real business name (e.g., "Third Coast Coffee")
- Real expert name (e.g., "Sarah Chen")
- Message content (decrypted)
- Timestamps
- Read receipts

**Does NOT Show:**
- Agent IDs (internal routing only)
- Encryption details (transparent to user)
- Network routing hops (internal)

---

## 🔄 **Migration from Database Approach**

**Old Approach:**
- Messages stored in Supabase database
- Real-time via Supabase Realtime
- Requires backend infrastructure

**New Approach:**
- Messages stored locally in Sembast
- Routing via ai2ai network
- No database dependency
- Privacy-preserving

**Migration Path:**
1. Use `BusinessExpertChatServiceAI2AI` for new chats
2. Keep `BusinessExpertChatService` for backward compatibility
3. Gradually migrate existing conversations

---

## 🚀 **Future Enhancements**

1. **Signal Protocol Integration**
   - Swap `AES256GCMEncryptionService` for `SignalProtocolEncryptionService`
   - No code changes needed (abstraction layer)

2. **Realtime Subscriptions**
   - Integrate with ai2ai realtime service
   - Replace polling with push notifications

3. **Offline Queue**
   - Queue messages when recipient offline
   - Deliver when recipient comes online

4. **Cross-Device Sync**
   - Sync messages across user's devices
   - Via ai2ai network

---

## 📝 **Usage Example**

```dart
final chatService = BusinessExpertChatServiceAI2AI(
  ai2aiProtocol: AnonymousCommunicationProtocol(),
  encryptionService: AES256GCMEncryptionService(),
  businessService: BusinessAccountService(),
);

// Send message
final message = await chatService.sendMessage(
  businessId: 'business-123',
  expertId: 'expert-456',
  content: 'Hello!',
  senderType: MessageSenderType.business,
  senderAgentId: 'agent_business_123',
  recipientAgentId: 'agent_expert_456',
);

// Get message history
final messages = await chatService.getMessageHistory('conv_business-123_expert-456');

// Subscribe to real-time messages
chatService.subscribeToMessages('conv_business-123_expert-456')
  .listen((message) {
    // Display message in chat UI
    print('New message from ${message.senderId}: ${message.content}');
  });
```

---

## ✅ **Benefits**

1. **Privacy:** Messages encrypted in transit, stored locally
2. **Offline-First:** Works without internet connection
3. **No Database:** No backend database required
4. **Real Identities:** Participants see real names in chat
5. **Signal Protocol Ready:** Easy migration to Signal Protocol
6. **AI2AI Aligned:** Uses existing ai2ai network infrastructure

---

**Status:** ✅ Ready for implementation and testing


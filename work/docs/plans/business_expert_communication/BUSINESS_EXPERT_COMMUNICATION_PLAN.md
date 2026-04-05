# Business-Expert Communication & Business Login System

**Date:** December 14, 2025  
**Status:** 📋 Planning  
**Priority:** HIGH  
**Purpose:** Enable bidirectional communication between businesses/companies and experts with vibe-based matching and separate business authentication

---

## 🚪 **Philosophy Alignment: Doors**

**What doors does this help users open?**
- Doors to meaningful business-expert partnerships
- Doors to collaboration opportunities
- Doors to expertise discovery
- Doors to community connections through business relationships

**When are users ready for these doors?**
- When vibe compatibility is high (70%+ threshold)
- When businesses need expertise
- When experts seek business partnerships
- When AI detects mutual benefit potential

**Is this being a good key?**
- Yes - enables authentic connections based on compatibility
- Respects user autonomy (opt-in communication)
- Facilitates meaningful relationships, not spam

**Is the AI learning with the user?**
- Yes - learns which business-expert connections lead to successful partnerships
- Tracks communication outcomes
- Improves matching over time

---

## 🎯 **Overview**

This plan implements:
1. **Business Login System** - Separate authentication for business accounts (similar to admin login)
2. **Business-Expert Chat Service** - Bidirectional messaging between businesses and experts (Signal Protocol ready)
3. **Business-Business Chat Service** - Messaging between businesses/companies for event partnerships
4. **Vibe-Based Outreach** - AI-powered matching that enables outreach when compatibility is high
5. **Outreach Management** - System for managing connection requests and communications
6. **Multi-Party Event Partnerships** - Business-to-business partnerships for creating events together

---

## 📋 **Requirements**

### **User Requirements:**
- Businesses should be able to reach out to experts (especially when vibe-matched)
- Experts should be able to reach out to businesses
- **Businesses should be able to partner with other businesses/companies to create events**
- Communication should be enabled when app matches vibes as a good fit
- Matching should consider: company, people at company, product, expertise, etc.
- Separate business login (similar to admin login)
- **Chat should be ready for Signal Protocol** (future-proofing for end-to-end encryption)

### **Technical Requirements:**
- Secure authentication system for businesses
- Real-time messaging infrastructure
- Vibe compatibility calculation (70%+ threshold)
- Message storage and history
- Notification system
- Integration with existing business/expert systems

---

## 🏗️ **Architecture**

### **1. Business Authentication System**

**Similar to AdminAuthService:**
- `BusinessAuthService` - Handles business login
- `BusinessLoginPage` - Login UI for businesses
- `BusinessSession` - Session management (8-hour sessions)
- Supabase Edge Function: `business-auth` - Server-side credential verification
- Database table: `business_credentials` - Stores business login credentials

**Key Differences from Admin:**
- Business accounts are tied to `BusinessAccount` model
- Multiple business accounts per user possible
- Business login grants access to business-specific features
- Can have both user session AND business session simultaneously

### **2. Business-Expert Communication System**

**Components:**
- `BusinessExpertChatService` - Core messaging service
- `BusinessExpertMessage` model - Message data structure
- `BusinessExpertChatPage` - Chat UI
- Supabase Realtime - Real-time message delivery
- Database table: `business_expert_messages` - Message storage

**Features:**
- Bidirectional messaging
- Message history
- Read receipts
- Typing indicators
- File attachments (future)
- Message search

### **3. Vibe-Based Outreach System**

**Components:**
- `BusinessExpertOutreachService` - Manages outreach requests
- `OutreachRequest` model - Connection request with vibe score
- Integration with `BusinessExpertMatchingService` - Uses existing matching
- Integration with `PartnershipService` - For vibe compatibility calculation

**Flow:**
1. AI calculates vibe compatibility (business ↔ expert)
2. If compatibility ≥ 70%, enable outreach option
3. Business/Expert can send connection request
4. Request includes vibe score and matching reasons
5. Recipient can accept/decline
6. If accepted, chat is unlocked

### **4. Integration Points**

**Existing Systems:**
- `BusinessAccountService` - Business account management
- `BusinessExpertMatchingService` - Expert matching (already exists)
- `PartnershipService` - Vibe compatibility calculation
- `UserVibe` / `PersonalityProfile` - Vibe data
- `ExpertiseService` - Expert expertise data

---

## 📐 **Implementation Plan**

### **Phase 1: Business Authentication System**

#### **1.1 Database Schema**

**Table: `business_credentials`**
```sql
CREATE TABLE business_credentials (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  business_id UUID NOT NULL REFERENCES business_accounts(id),
  username VARCHAR(255) UNIQUE NOT NULL,
  password_hash VARCHAR(255) NOT NULL,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW(),
  last_login_at TIMESTAMP,
  failed_login_attempts INT DEFAULT 0,
  locked_until TIMESTAMP
);
```

**Table: `business_sessions`**
```sql
CREATE TABLE business_sessions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  business_id UUID NOT NULL REFERENCES business_accounts(id),
  username VARCHAR(255) NOT NULL,
  login_time TIMESTAMP DEFAULT NOW(),
  expires_at TIMESTAMP NOT NULL,
  access_level VARCHAR(50) DEFAULT 'business',
  created_at TIMESTAMP DEFAULT NOW()
);
```

#### **1.2 BusinessAuthService**

**Location:** `lib/core/services/business_auth_service.dart`

**Key Methods:**
- `authenticate(username, password, twoFactorCode?)` - Business login
- `getCurrentBusinessSession()` - Get active session
- `logout()` - End session
- `isAuthenticated()` - Check if business is logged in

**Similar to AdminAuthService:**
- Lockout after 5 failed attempts (15 min)
- 8-hour session duration
- Supabase Edge Function verification
- Secure password hashing (SHA-256)

#### **1.3 BusinessLoginPage**

**Location:** `lib/presentation/pages/business/business_login_page.dart`

**Features:**
- Username/password fields
- 2FA support (optional)
- Error handling
- Lockout messaging
- Link to business account creation

#### **1.4 Supabase Edge Function**

**Function: `business-auth`**
- Verify credentials
- Check lockout status
- Return session info
- Track login attempts

---

### **Phase 2: Business-Expert Chat Service**

#### **2.1 Database Schema**

**Table: `business_expert_messages`** (Signal Protocol Ready)
```sql
CREATE TABLE business_expert_messages (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  conversation_id UUID NOT NULL,
  sender_type VARCHAR(20) NOT NULL, -- 'business' or 'expert'
  sender_id UUID NOT NULL, -- business_id or user_id
  recipient_type VARCHAR(20) NOT NULL,
  recipient_id UUID NOT NULL,
  content TEXT NOT NULL, -- Plaintext (for AES-256-GCM)
  encrypted_content BYTEA, -- Encrypted content (for Signal Protocol future)
  encryption_type VARCHAR(50) DEFAULT 'aes256gcm', -- 'aes256gcm' or 'signal_protocol'
  message_type VARCHAR(50) DEFAULT 'text', -- 'text', 'partnership_proposal', 'file'
  is_read BOOLEAN DEFAULT false,
  read_at TIMESTAMP,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_conversation_id ON business_expert_messages(conversation_id);
CREATE INDEX idx_sender ON business_expert_messages(sender_type, sender_id);
CREATE INDEX idx_recipient ON business_expert_messages(recipient_type, recipient_id);
```

**Table: `business_business_messages`** (NEW - Signal Protocol Ready)
```sql
CREATE TABLE business_business_messages (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  conversation_id UUID NOT NULL,
  sender_business_id UUID NOT NULL REFERENCES business_accounts(id),
  recipient_business_id UUID NOT NULL REFERENCES business_accounts(id),
  content TEXT NOT NULL, -- Plaintext (for AES-256-GCM)
  encrypted_content BYTEA, -- Encrypted content (for Signal Protocol future)
  encryption_type VARCHAR(50) DEFAULT 'aes256gcm', -- 'aes256gcm' or 'signal_protocol'
  message_type VARCHAR(50) DEFAULT 'text', -- 'text', 'event_partnership_proposal', 'file'
  is_read BOOLEAN DEFAULT false,
  read_at TIMESTAMP,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_bb_conversation_id ON business_business_messages(conversation_id);
CREATE INDEX idx_bb_sender ON business_business_messages(sender_business_id);
CREATE INDEX idx_bb_recipient ON business_business_messages(recipient_business_id);
```

**Table: `business_business_conversations`** (NEW)
```sql
CREATE TABLE business_business_conversations (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  business_1_id UUID NOT NULL REFERENCES business_accounts(id),
  business_2_id UUID NOT NULL REFERENCES business_accounts(id),
  vibe_compatibility_score DECIMAL(3,2), -- 0.00 to 1.00
  connection_status VARCHAR(50) DEFAULT 'pending', -- 'pending', 'connected', 'blocked'
  last_message_at TIMESTAMP,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW(),
  UNIQUE(business_1_id, business_2_id)
);
```

**Table: `multi_party_event_partnerships`** (NEW)
```sql
CREATE TABLE multi_party_event_partnerships (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  event_id UUID NOT NULL REFERENCES expertise_events(id),
  partnership_type VARCHAR(50) DEFAULT 'business_business', -- 'business_business', 'business_expert_business'
  business_ids UUID[] NOT NULL, -- Array of business IDs participating
  expert_ids UUID[], -- Array of expert IDs (if applicable)
  revenue_split JSONB, -- Revenue distribution among parties
  status VARCHAR(50) DEFAULT 'proposed', -- 'proposed', 'negotiating', 'approved', 'locked', 'active', 'completed'
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);
```

**Table: `business_expert_conversations`**
```sql
CREATE TABLE business_expert_conversations (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  business_id UUID NOT NULL REFERENCES business_accounts(id),
  expert_id UUID NOT NULL REFERENCES users(id),
  vibe_compatibility_score DECIMAL(3,2), -- 0.00 to 1.00
  connection_status VARCHAR(50) DEFAULT 'pending', -- 'pending', 'connected', 'blocked'
  last_message_at TIMESTAMP,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW(),
  UNIQUE(business_id, expert_id)
);
```

#### **2.2 BusinessExpertChatService**

**Location:** `lib/core/services/business_expert_chat_service.dart`

**Key Methods:**
- `sendMessage(businessId, expertId, content, messageType)` - Send message
- `getConversation(businessId, expertId)` - Get conversation
- `getMessageHistory(conversationId, limit, offset)` - Get messages
- `markAsRead(messageId)` - Mark message as read
- `getUnreadCount(businessId/expertId)` - Get unread count
- `createConversation(businessId, expertId, vibeScore)` - Create conversation

**Signal Protocol Ready:**
- Message model includes `encrypted_content` and `encryption_type` fields
- Service architecture supports encryption layer abstraction
- Can switch from AES-256-GCM to Signal Protocol without breaking changes
- Encryption handled via `MessageEncryptionService` abstraction

**Real-time:**
- Uses Supabase Realtime for live message delivery
- Subscribes to conversation channels
- Handles typing indicators
- Manages connection status

#### **2.2.1 BusinessBusinessChatService** (NEW)

**Location:** `lib/core/services/business_business_chat_service.dart`

**Key Methods:**
- `sendMessage(senderBusinessId, recipientBusinessId, content, messageType)` - Send message
- `getConversation(business1Id, business2Id)` - Get conversation
- `getMessageHistory(conversationId, limit, offset)` - Get messages
- `markAsRead(messageId)` - Mark message as read
- `getUnreadCount(businessId)` - Get unread count
- `createConversation(business1Id, business2Id, vibeScore)` - Create conversation

**Signal Protocol Ready:**
- Same encryption abstraction as BusinessExpertChatService
- Message model includes `encrypted_content` and `encryption_type` fields
- Ready for Signal Protocol upgrade

**Real-time:**
- Uses Supabase Realtime for live message delivery
- Subscribes to conversation channels
- Handles typing indicators

#### **2.3 BusinessExpertMessage Model**

**Location:** `lib/core/models/business_expert_message.dart`

```dart
class BusinessExpertMessage {
  final String id;
  final String conversationId;
  final MessageSenderType senderType; // business or expert
  final String senderId;
  final MessageRecipientType recipientType;
  final String recipientId;
  final String content; // Plaintext (for AES-256-GCM)
  final Uint8List? encryptedContent; // Encrypted content (for Signal Protocol future)
  final EncryptionType encryptionType; // aes256gcm or signal_protocol
  final MessageType type; // text, partnership_proposal, file
  final bool isRead;
  final DateTime? readAt;
  final DateTime createdAt;
  final DateTime updatedAt;
}

enum EncryptionType {
  aes256gcm, // Current default
  signalProtocol, // Future upgrade
}
```

#### **2.3.1 BusinessBusinessMessage Model** (NEW)

**Location:** `lib/core/models/business_business_message.dart`

```dart
class BusinessBusinessMessage {
  final String id;
  final String conversationId;
  final String senderBusinessId;
  final String recipientBusinessId;
  final String content; // Plaintext (for AES-256-GCM)
  final Uint8List? encryptedContent; // Encrypted content (for Signal Protocol future)
  final EncryptionType encryptionType; // aes256gcm or signal_protocol
  final MessageType type; // text, event_partnership_proposal, file
  final bool isRead;
  final DateTime? readAt;
  final DateTime createdAt;
  final DateTime updatedAt;
}
```

#### **2.3.2 MessageEncryptionService** (NEW - Signal Protocol Ready)

**Location:** `lib/core/services/message_encryption_service.dart`

**Purpose:** Abstraction layer for message encryption, ready for Signal Protocol upgrade

```dart
abstract class MessageEncryptionService {
  Future<EncryptedMessage> encrypt(String plaintext, String recipientId);
  Future<String> decrypt(EncryptedMessage encrypted, String senderId);
  EncryptionType get encryptionType;
}

class AES256GCMEncryptionService implements MessageEncryptionService {
  // Current implementation using AES-256-GCM
  // Can be swapped for SignalProtocolEncryptionService later
}

class SignalProtocolEncryptionService implements MessageEncryptionService {
  // Future implementation using Signal Protocol
  // Will be added when Signal Protocol is implemented
}
```

#### **2.4 BusinessExpertChatPage**

**Location:** `lib/presentation/pages/business/business_expert_chat_page.dart`

**Features:**
- Message list (scrollable)
- Message input field
- Send button
- Read receipts
- Typing indicators
- Vibe compatibility display
- Connection status indicator

---

### **Phase 3: Vibe-Based Outreach System**

#### **3.1 OutreachRequest Model**

**Location:** `lib/core/models/outreach_request.dart`

```dart
class OutreachRequest {
  final String id;
  final String businessId;
  final String expertId;
  final OutreachDirection direction; // business_to_expert or expert_to_business
  final double vibeCompatibilityScore;
  final Map<String, dynamic> matchingReasons; // Why they match
  final String? message; // Optional initial message
  final OutreachStatus status; // pending, accepted, declined, expired
  final DateTime createdAt;
  final DateTime? respondedAt;
}
```

#### **3.2 BusinessExpertOutreachService**

**Location:** `lib/core/services/business_expert_outreach_service.dart`

**Key Methods:**
- `canReachOut(businessId, expertId)` - Check if outreach is allowed (vibe ≥ 70%)
- `createOutreachRequest(businessId, expertId, direction, message?)` - Create request
- `getOutreachRequests(businessId/expertId)` - Get pending requests
- `acceptOutreachRequest(requestId)` - Accept request (unlocks chat)
- `declineOutreachRequest(requestId)` - Decline request
- `getSuggestedOutreach(businessId/expertId)` - Get AI-suggested outreach opportunities

**Vibe Calculation:**
- Uses `PartnershipService.calculateVibeCompatibility()`
- Requires 70%+ compatibility for outreach
- Includes matching reasons (expertise match, location match, vibe match)

#### **3.3 Outreach UI Components**

**BusinessExpertOutreachWidget**
- Shows suggested experts/businesses
- Displays vibe compatibility score
- Shows matching reasons
- "Reach Out" button (enabled if ≥ 70%)

**OutreachRequestCard**
- Shows pending requests
- Displays sender info
- Shows vibe score
- Accept/Decline buttons

---

### **Phase 4: Integration & UI**

#### **4.1 Business Dashboard Integration**

**Add to Business Dashboard:**
- "Messages" tab - Shows all conversations (experts + businesses)
- "Suggested Experts" tab - Shows vibe-matched experts
- "Business Partners" tab - Shows suggested businesses for partnerships (NEW)
- "Outreach Requests" tab - Shows pending requests (experts + businesses)
- "Connected Experts" tab - Shows connected experts
- "Connected Businesses" tab - Shows connected businesses (NEW)
- "Event Partnerships" tab - Shows multi-party event partnerships (NEW)

#### **4.2 Expert Dashboard Integration**

**Add to Expertise Dashboard:**
- "Business Messages" section - Shows business conversations
- "Business Opportunities" section - Shows suggested businesses
- "Outreach Requests" section - Shows business outreach requests

#### **4.3 Navigation Updates**

**Business Routes:**
- `/business/login` - Business login page
- `/business/dashboard` - Business dashboard
- `/business/chat/expert/:expertId` - Chat with expert
- `/business/chat/business/:businessId` - Chat with business (NEW)
- `/business/outreach` - Outreach management
- `/business/partners` - Business partners for events (NEW)

**Expert Routes:**
- `/expert/business-chat/:businessId` - Chat with business
- `/expert/business-opportunities` - Business opportunities

#### **4.4 Notification System**

**Notifications:**
- New message received
- Outreach request received
- Outreach request accepted/declined
- New suggested match (vibe ≥ 70%)

---

## 🔄 **User Flows**

### **Flow 1: Business Reaches Out to Expert**

```
1. Business logs in (BusinessLoginPage)
2. Navigates to Business Dashboard
3. Sees "Suggested Experts" tab
4. AI shows experts with vibe ≥ 70%
5. Business clicks "Reach Out" on expert
6. System creates OutreachRequest
7. Expert receives notification
8. Expert views request (vibe score + reasons)
9. Expert accepts → Chat unlocked
10. Business and Expert can now message
```

### **Flow 2: Expert Reaches Out to Business**

```
1. Expert (regular user) navigates to Expertise Dashboard
2. Sees "Business Opportunities" section
3. AI shows businesses with vibe ≥ 70%
4. Expert clicks "Reach Out" on business
5. System creates OutreachRequest
6. Business receives notification (if logged in)
7. Business views request
8. Business accepts → Chat unlocked
9. Expert and Business can now message
```

### **Flow 3: Vibe-Based Matching**

```
1. AI continuously calculates vibe compatibility
2. For each business-expert pair:
   - Calculate vibe compatibility (PartnershipService)
   - Check expertise match
   - Check location match
   - Check product/company match
3. If compatibility ≥ 70%:
   - Add to "Suggested" list
   - Enable "Reach Out" button
   - Show matching reasons
4. User can initiate outreach
```

### **Flow 4: Business-Business Event Partnership** (NEW)

```
1. Business A logs in (BusinessLoginPage)
2. Navigates to Business Dashboard
3. Sees "Business Partners" tab
4. AI shows businesses with vibe ≥ 70%
5. Business A clicks "Partner for Event" on Business B
6. System creates BusinessBusinessOutreachRequest
7. Business B receives notification
8. Business B views request (vibe score + reasons)
9. Business B accepts → Chat unlocked
10. Businesses can now message and create event partnership
11. Businesses create MultiPartyEventPartnership
12. Event created with both businesses as partners
```

### **Flow 5: Multi-Party Event Creation** (NEW)

```
1. Business A creates event proposal
2. Invites Business B (via chat or outreach)
3. Business B accepts partnership
4. System creates MultiPartyEventPartnership
5. Revenue split negotiated (via chat)
6. All parties approve → Partnership locked
7. Event goes live with multi-party partnership
8. Revenue automatically distributed after event
```

---

## 🗄️ **Database Schema Summary**

### **New Tables:**
1. `business_credentials` - Business login credentials
2. `business_sessions` - Business session management
3. `business_expert_messages` - Business-Expert chat messages (Signal Protocol ready)
4. `business_expert_conversations` - Business-Expert conversation metadata
5. `business_business_messages` - Business-Business chat messages (Signal Protocol ready) (NEW)
6. `business_business_conversations` - Business-Business conversation metadata (NEW)
7. `business_expert_outreach_requests` - Business-Expert outreach requests
8. `business_business_outreach_requests` - Business-Business outreach requests (NEW)
9. `multi_party_event_partnerships` - Multi-party event partnerships (NEW)

### **Modified Tables:**
- `business_accounts` - Add `hasLoginCredentials` flag
- `users` - No changes needed (experts are regular users)

---

## 🔐 **Security Considerations**

### **Business Authentication:**
- Secure password hashing (SHA-256)
- Lockout after failed attempts
- Session expiration (8 hours)
- Server-side credential verification
- 2FA support (optional)

### **Message Security:**
- End-to-end encryption (future enhancement)
- Message content validation
- Rate limiting on messages
- Spam detection
- Block functionality

### **Outreach Security:**
- Vibe threshold enforcement (70% minimum)
- Rate limiting on outreach requests
- Abuse reporting
- Auto-decline after expiration (7 days)

---

## 📊 **Success Metrics**

### **Communication Metrics:**
- Messages sent per day
- Conversation response rate
- Average messages per conversation
- Time to first response

### **Outreach Metrics:**
- Outreach requests created
- Acceptance rate
- Vibe score distribution
- Successful partnerships from outreach

### **Matching Metrics:**
- Vibe compatibility accuracy
- Suggested matches quality
- User satisfaction with suggestions

---

## 🚀 **Implementation Timeline**

### **Phase 1: Business Authentication (Week 1)**
- Database schema
- BusinessAuthService
- BusinessLoginPage
- Supabase Edge Function
- Testing

### **Phase 2: Chat Service (Week 2)**
- Database schema (Signal Protocol ready)
- BusinessExpertChatService
- BusinessBusinessChatService (NEW)
- Message models (Signal Protocol ready)
- MessageEncryptionService abstraction (NEW)
- Chat UI (Business-Expert)
- Business-Business Chat UI (NEW)
- Real-time integration
- Testing

### **Phase 3: Outreach System (Week 3)**
- OutreachRequest model (Business-Expert)
- BusinessBusinessOutreachRequest model (NEW)
- BusinessExpertOutreachService
- BusinessBusinessOutreachService (NEW)
- MultiPartyEventPartnershipService (NEW)
- Vibe calculation integration
- Outreach UI (Business-Expert)
- Business-Business Outreach UI (NEW)
- Testing

### **Phase 4: Integration & Polish (Week 4)**
- Dashboard integration
- Navigation updates
- Notification system
- UI polish
- End-to-end testing
- Documentation

**Total Estimated Time:** 4-5 weeks (added business-business features)

---

## 🔗 **Dependencies**

### **Existing Systems:**
- ✅ `BusinessAccountService` - Business account management
- ✅ `BusinessExpertMatchingService` - Expert matching
- ✅ `PartnershipService` - Vibe compatibility calculation
- ✅ `UserVibe` / `PersonalityProfile` - Vibe data
- ✅ `ExpertiseService` - Expert expertise data
- ✅ Supabase Realtime - Real-time messaging
- ✅ AdminAuthService - Reference implementation

### **New Dependencies:**
- None (uses existing infrastructure)

---

## 📝 **Next Steps**

1. **Review & Approval** - Get user approval on plan
2. **Database Setup** - Create Supabase tables
3. **Edge Function** - Create `business-auth` function
4. **Phase 1 Implementation** - Business authentication
5. **Phase 2 Implementation** - Chat service
6. **Phase 3 Implementation** - Outreach system
7. **Phase 4 Implementation** - Integration & polish

---

## 🎯 **Doors Questions (MANDATORY)**

✅ **What doors does this help users open?**
- Doors to meaningful business-expert partnerships
- Doors to business-business collaboration for events
- Doors to multi-party event partnerships
- Doors to collaboration opportunities
- Doors to expertise discovery
- Doors to community connections through business relationships

✅ **When are users ready for these doors?**
- When vibe compatibility is high (70%+ threshold)
- When businesses need expertise
- When experts seek business partnerships
- When AI detects mutual benefit potential

✅ **Is this being a good key?**
- Yes - enables authentic connections based on compatibility
- Respects user autonomy (opt-in communication)
- Facilitates meaningful relationships, not spam

✅ **Is the AI learning with the user?**
- Yes - learns which business-expert connections lead to successful partnerships
- Tracks communication outcomes
- Improves matching over time

---

**Status:** Ready for implementation  
**Last Updated:** December 14, 2025


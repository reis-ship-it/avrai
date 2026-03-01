# Business Multi-User Support & Onboarding Plan

**Date:** December 14, 2025  
**Status:** 📋 Planning  
**Priority:** HIGH  
**Purpose:** Enable business account creation, onboarding, and multi-user support with shared AI agents

---

## 🎯 **Overview**

This plan implements:
1. **Business Account Signup** - Standalone business account creation (no existing user required)
2. **Business Onboarding Flow** - Multi-step onboarding for new businesses
3. **Multi-User Support** - Multiple users per business account
4. **Shared Business AI Agent** - Neural network of agents where all business members feed into a shared agent
5. **Business Member Management** - Add/remove members, role management

---

## 🚪 **Philosophy Alignment: Doors**

**What doors does this help businesses open?**
- Doors to collaborative business operations
- Doors to shared AI intelligence across team members
- Doors to collective learning and improvement
- Doors to unified business personality in the network

**When are businesses ready for these doors?**
- When they want to scale operations with multiple team members
- When they need shared intelligence across the organization
- When they want a unified business presence in the ai2ai network

**Is this being a good key?**
- Yes - enables authentic business collaboration
- Respects business autonomy (who can join, what roles)
- Facilitates collective intelligence, not surveillance

**Is the AI learning with the business?**
- Yes - shared agent learns from all business members
- Creates neural network of agents (individual + shared)
- Improves business intelligence over time

---

## 📋 **Requirements**

### **User Requirements:**
- Businesses should be able to create accounts without existing user account
- Businesses should have onboarding flow (similar to user onboarding)
- Multiple users should be able to join a business account
- All business members should share the same AI agent
- Business AI agent should learn from all member interactions
- Business members should feed into shared agent (neural network)
- Role-based access control (owner, admin, member)

### **Technical Requirements:**
- Business signup flow
- Business onboarding system
- Multi-user business account model
- Shared business AI agent system
- Member management UI
- Role management system
- Neural network agent architecture

---

## 🏗️ **Architecture**

### **1. Business Account Model Updates**

**Add to BusinessAccount:**
```dart
class BusinessAccount {
  // ... existing fields ...
  
  // Multi-user support
  final List<BusinessMember> members; // All users in the business
  final String ownerId; // Primary owner (from createdBy)
  final Map<String, BusinessMemberRole> memberRoles; // userId -> role
  
  // Shared AI agent
  final String? sharedAgentId; // AI agent ID for the business
  final PersonalityProfile? sharedPersonalityProfile; // Shared personality
}
```

**BusinessMember Model:**
```dart
class BusinessMember {
  final String userId;
  final String businessId;
  final BusinessMemberRole role;
  final DateTime joinedAt;
  final String? invitedBy; // User ID who invited them
  final bool isActive;
}
```

**BusinessMemberRole Enum:**
```dart
enum BusinessMemberRole {
  owner,    // Full access, can delete business
  admin,    // Can manage members, settings
  member,   // Standard access
}
```

### **2. Business Signup Flow**

**Flow:**
1. Business Signup Page (`/business/signup`)
   - Business name
   - Email
   - Password
   - Business type
   - Basic info
2. Create business account
3. Create business credentials
4. Start onboarding flow

### **3. Business Onboarding Flow**

**Steps:**
1. **Welcome** - Welcome to business onboarding
2. **Business Info** - Complete business details
3. **Expert Preferences** - What experts you want to connect with
4. **Patron Preferences** - What customers you want
5. **Team Setup** - Invite team members (optional)
6. **AI Agent Setup** - Initialize shared business AI agent
7. **Complete** - Navigate to dashboard

### **4. Shared Business AI Agent System**

**Architecture:**
```
Individual Member Agents
    ↓
Feed Learning Data
    ↓
Shared Business Agent (Neural Network)
    ↓
Aggregates Learning
    ↓
Evolves Business Personality
    ↓
Used for Business Matching & Recommendations
```

**Components:**
- `BusinessSharedAgentService` - Manages shared business agent
- `BusinessAgentNeuralNetwork` - Neural network of member agents → shared agent
- `BusinessPersonalityAggregator` - Aggregates member personalities into business personality

**Learning Flow:**
1. Member performs action → Individual agent learns
2. Individual agent learning → Feeds into shared agent
3. Shared agent aggregates → Evolves business personality
4. Business personality → Used for matching, recommendations

### **5. Member Management**

**Features:**
- Invite members (via email/user ID)
- Remove members
- Change roles
- View member list
- Member activity tracking

---

## 🔄 **User Flows**

### **Flow 1: Business Signup & Onboarding**

```
1. User navigates to /business/signup
2. Fills out business signup form
3. Creates business account + credentials
4. Starts onboarding flow
5. Completes onboarding steps
6. Shared AI agent initialized
7. Navigate to business dashboard
```

### **Flow 2: Add Business Member**

```
1. Business owner/admin navigates to member management
2. Clicks "Invite Member"
3. Enters user email or ID
4. Selects role
5. Invitation sent
6. User accepts invitation
7. User added to business
8. User's agent starts feeding into shared business agent
```

### **Flow 3: Shared Agent Learning**

```
1. Business member performs action (e.g., chats with expert)
2. Member's individual agent learns from action
3. Learning data fed to shared business agent
4. Shared agent aggregates learning
5. Business personality evolves
6. Improved matching for all business members
```

---

## 📦 **Implementation Phases**

### **Phase 1: Business Signup & Onboarding**
- [ ] Create BusinessSignupPage
- [ ] Create BusinessOnboardingPage
- [ ] Update BusinessAccount model for multi-user
- [ ] Create BusinessMember model
- [ ] Update business authentication to support signup

### **Phase 2: Multi-User Support**
- [ ] Add members list to BusinessAccount
- [ ] Create BusinessMemberService
- [ ] Implement member invitation system
- [ ] Create member management UI

### **Phase 3: Shared Business AI Agent**
- [ ] Create BusinessSharedAgentService
- [ ] Implement agent aggregation logic
- [ ] Create BusinessAgentNeuralNetwork
- [ ] Integrate with PersonalityLearning
- [ ] Update matching to use shared agent

### **Phase 4: Neural Network Architecture**
- [ ] Implement member → shared agent feed
- [ ] Create aggregation algorithms
- [ ] Update personality learning to support shared agents
- [ ] Test neural network learning

---

## 🗄️ **Database Schema**

### **New Tables:**

**`business_members`**
```sql
CREATE TABLE business_members (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  business_id UUID NOT NULL REFERENCES business_accounts(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  role VARCHAR(50) NOT NULL DEFAULT 'member', -- 'owner', 'admin', 'member'
  invited_by UUID REFERENCES auth.users(id),
  joined_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(business_id, user_id)
);
```

**`business_shared_agents`**
```sql
CREATE TABLE business_shared_agents (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  business_id UUID NOT NULL UNIQUE REFERENCES business_accounts(id) ON DELETE CASCADE,
  agent_id TEXT NOT NULL UNIQUE, -- AI agent ID
  personality_profile JSONB, -- Shared personality profile
  learning_data JSONB, -- Aggregated learning data
  member_contributions JSONB, -- Contributions from each member
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

**`business_agent_contributions`**
```sql
CREATE TABLE business_agent_contributions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  business_id UUID NOT NULL REFERENCES business_accounts(id) ON DELETE CASCADE,
  member_user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  contribution_type VARCHAR(50) NOT NULL, -- 'action', 'interaction', 'learning'
  contribution_data JSONB NOT NULL,
  contributed_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

---

## 🔐 **Security Considerations**

### **Business Signup:**
- Email verification
- Password strength requirements
- Business name uniqueness check
- Rate limiting on signup

### **Member Management:**
- Only owners/admins can invite/remove members
- Role-based access control
- Audit log for member changes
- Member consent for data sharing

### **Shared Agent:**
- Privacy-preserving aggregation
- Anonymized learning data
- Member opt-out option
- Secure agent ID management

---

## 📊 **Success Metrics**

- Businesses can create accounts independently
- Onboarding completion rate
- Average members per business
- Shared agent learning effectiveness
- Business matching improvement

---

## 🚀 **Next Steps**

1. Create business signup page
2. Create business onboarding flow
3. Update BusinessAccount model
4. Implement member management
5. Create shared agent system
6. Implement neural network architecture


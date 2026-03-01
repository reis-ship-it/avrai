# Social Media Integration Plan

**Date:** December 4, 2025, 2:22 PM CST  
**Status:** 📋 **COMPREHENSIVE PLAN - AWAITING APPROVAL**  
**Purpose:** Enable users to connect social media accounts to enhance vibe understanding, share places, and discover connections

---

## 🚪 **DOORS PHILOSOPHY ALIGNMENT**

### **What Doors Does This Open?**

**1. Doors to Better Understanding**
- Social media reveals authentic interests, communities, and experiences
- AI learns which doors resonate by seeing what users share, follow, and engage with
- More accurate vibe matching = better door recommendations

**2. Doors to Sharing**
- Share saved places with friends on social platforms
- Share experiences at spots (photos, stories, check-ins)
- Share lists and discoveries with communities

**3. Doors to People**
- Discover friends who use SPOTS
- Find people who visit similar spots
- Connect with people who share similar interests (through social media overlap)

**4. Doors to Communities**
- Find communities on social media that align with your spots
- Discover events through social media connections
- Connect SPOTS communities with social media groups

### **When Are Users Ready for These Doors?**

**Progressive Disclosure:**
- **Onboarding:** Optional connection (not required)
- **After First Spot Saved:** "Want to share this with friends?"
- **After First List Created:** "Connect social media to find friends who use SPOTS"
- **After Multiple Visits:** "Connect to get better recommendations based on your interests"

**User Control:**
- Users choose which platforms to connect
- Users choose what data to share
- Users can disconnect at any time
- Users control privacy settings per platform

### **Is This Being a Good Key?**

**Yes, because:**
- ✅ Opens doors to better understanding (more accurate recommendations)
- ✅ Opens doors to sharing (authentic sharing, not forced)
- ✅ Opens doors to people (discover friends, not random matches)
- ✅ Opens doors to communities (real communities, not artificial)
- ✅ Respects user autonomy (they choose what to connect/share)
- ✅ Preserves privacy (data used for learning, not surveillance)

### **Is the AI Learning With the User?**

**Yes:**
- AI learns from social media interests (what they follow, share, engage with)
- AI learns from social connections (friends who use SPOTS, similar interests)
- AI learns from shared places (where friends go, what they save)
- AI adapts recommendations based on social context
- AI learns which doors resonate by seeing social engagement patterns

---

## 🎯 **EXECUTIVE SUMMARY**

**Goal:** Enable users to connect social media accounts to:
1. **Enhance Vibe Understanding** - Better personality learning from social interests
2. **Share Places** - Share saved places, lists, and experiences
3. **Discover Connections** - Find friends who use SPOTS
4. **Enrich Communities** - Connect SPOTS communities with social media groups

**Approach:** Privacy-first, user-controlled integration that enhances (not replaces) SPOTS functionality.

**Three-Tier Strategy:**
- **Option 1 (Primary):** User-consented OAuth integration (full social media connection)
- **Option 3 (Secondary):** User-provided handles opt-in (public profile analysis with consent)
- **Option 2 (Initial):** Archetype templates (see Archetype Template System Plan)

**Timeline:** 6-8 weeks (4 phases)

---

## 🏗️ **ARCHITECTURE PRINCIPLES**

### **1. Privacy-First**
- ✅ Social media data stored locally (offline-first)
- ✅ Only anonymized data used for AI2AI learning
- ✅ User controls what data is shared
- ✅ No social media data in AI2AI network (only derived insights)
- ✅ Encrypted storage for social media tokens

### **2. User Control**
- ✅ Users choose which platforms to connect
- ✅ Users choose what data to share
- ✅ Users can disconnect at any time
- ✅ Granular privacy controls per platform
- ✅ Clear consent for each data use

### **3. Offline-First**
- ✅ Social media data cached locally
- ✅ Works offline (cached data for recommendations)
- ✅ Syncs when online (background sync)
- ✅ No dependency on social media APIs for core functionality

### **4. AI2AI Alignment**
- ✅ Social media insights enhance personality learning (on-device)
- ✅ No social media data in AI2AI network (only derived personality insights)
- ✅ AI2AI connections based on personality, not social media
- ✅ Social media used for learning, not matching

### **5. Doors, Not Badges**
- ✅ Social media enhances door discovery (not gamification)
- ✅ Sharing is authentic (user-initiated, not forced)
- ✅ Connections are meaningful (friends, not random)
- ✅ Communities are real (social media groups, not artificial)

---

## 📋 **SUPPORTED PLATFORMS**

### **Phase 1: Core Platforms (Weeks 1-2)**
- **Instagram** - Photos, stories, saved places, interests
- **Facebook** - Friends, events, groups, interests
- **Twitter/X** - Interests, communities, trends

### **Phase 2: Extended Platforms (Weeks 3-4)**
- **TikTok** - Interests, trends, communities
- **LinkedIn** - Professional interests, communities
- **Pinterest** - Interests, saved places, boards

### **Phase 3: Specialized Platforms (Weeks 5-6)**
- **YouTube** - Interests, communities, watch history (optional)
- **Reddit** - Communities, interests, discussions
- **Discord** - Communities, servers (if API available)

### **Phase 4: Future Platforms**
- **Snapchat** - Stories, places (if API available)
- **Other platforms** - As APIs become available

---

## 🔧 **TECHNICAL ARCHITECTURE**

### **1. Data Models**

**⚠️ CRITICAL: All models use `agentId` (not `userId`) for internal tracking per Phase 7.3 Security Architecture.**

#### **SocialMediaConnection**
```dart
class SocialMediaConnection {
  final String id;
  final String agentId; // ✅ CRITICAL: Use agentId for internal tracking (Phase 7.3)
  final String platform; // 'instagram', 'facebook', 'twitter', etc.
  final String? accessToken; // Encrypted (AES-256-GCM)
  final String? refreshToken; // Encrypted (AES-256-GCM)
  final DateTime connectedAt;
  final DateTime? lastSyncedAt;
  final DateTime? tokenExpiresAt; // Token expiration time
  final SocialMediaPermissions permissions; // What user consented to
  final bool isActive;
  final Map<String, dynamic> metadata; // Platform-specific data
  final String? errorMessage; // Last error (if any)
  final int syncRetryCount; // Retry count for failed syncs
}
```

#### **SocialMediaProfile**
```dart
class SocialMediaProfile {
  final String connectionId; // References SocialMediaConnection.id
  final String agentId; // ✅ CRITICAL: Use agentId for internal tracking
  final String platform;
  final String? username;
  final String? displayName;
  final String? profileImageUrl;
  final List<String> interests; // Extracted interests
  final List<String> communities; // Groups, pages, etc.
  final List<String> friends; // Friend IDs (hashed with SHA-256)
  final DateTime lastUpdated;
  final Map<String, dynamic> rawData; // Raw platform data (encrypted, local only)
}
```

#### **SocialMediaInsights**
```dart
class SocialMediaInsights {
  final String agentId; // ✅ CRITICAL: Use agentId for internal tracking
  final Map<String, double> interestScores; // Interest → score
  final Map<String, double> communityScores; // Community → score
  final List<String> extractedInterests; // From posts, follows, etc.
  final List<String> extractedCommunities; // Groups, pages, etc.
  final PersonalityDimensionUpdates dimensionUpdates; // How this affects personality
  final DateTime lastAnalyzed;
  final double confidenceScore; // Confidence in insights (0.0-1.0)
  final Map<String, dynamic> metadata; // Analysis metadata
}
```

### **2. Services**

#### **SocialMediaConnectionService**
- Connect/disconnect platforms
- Manage tokens (encrypted storage)
- Handle OAuth flows
- Sync data (background sync)

#### **SocialMediaDataService**
- Fetch data from platforms
- Cache data locally
- Parse interests, communities, friends
- Extract personality insights

#### **SocialMediaInsightService**
- Analyze social media data for personality insights
- Map interests to personality dimensions
- Update personality profile (on-device)
- Generate recommendations based on insights

#### **SocialMediaSharingService**
- Share places to social platforms
- Share lists to social platforms
- Share experiences (photos, stories)
- Handle sharing permissions

#### **SocialMediaDiscoveryService**
- Find friends who use SPOTS
- Discover people with similar interests
- Find communities on social media
- Connect SPOTS communities with social media groups

### **3. Integration Points**

#### **Personality Learning System**
- Social media insights feed into personality learning
- Interests → personality dimensions
- Communities → community orientation
- Friends → social discovery style
- **Privacy:** Only derived insights, not raw data

#### **Vibe Analysis Engine**
- Social media interests enhance vibe compilation
- Social connections inform social dynamics
- Communities inform community engagement
- **Privacy:** Only anonymized insights

#### **Recommendation Engine**
- Social media interests inform spot recommendations
- Friends' places inform recommendations
- Communities inform event recommendations
- **Privacy:** Only derived insights, not raw data

#### **Sharing System**
- Share places to social platforms
- Share lists to social platforms
- Share experiences to social platforms
- **User Control:** User chooses what to share

---

## 🗄️ **DATABASE SCHEMA & MIGRATIONS**

### **Migration Dependencies**

**⚠️ CRITICAL: Must complete Phase 7.3 migrations first:**
- `001_user_agent_mappings` - Create user-agent mapping table
- `002_migrate_existing_users` - Generate agent IDs for existing users

**Social Media Integration migrations depend on:**
- `002_migrate_existing_users` (agentId must exist)
- Migration sequence: After Phase 7.3, before any features using social media data

### **Database Tables**

#### **1. social_media_connections**

**Purpose:** Store OAuth connections per user (agentId).

```sql
CREATE TABLE IF NOT EXISTS api.social_media_connections (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    agent_id UUID NOT NULL REFERENCES api.user_agent_mappings(agent_id) ON DELETE CASCADE,
    platform TEXT NOT NULL CHECK (platform IN ('instagram', 'facebook', 'twitter', 'tiktok', 'linkedin', 'pinterest', 'youtube', 'reddit', 'discord')),
    access_token_encrypted TEXT, -- Encrypted with AES-256-GCM
    refresh_token_encrypted TEXT, -- Encrypted with AES-256-GCM
    token_expires_at TIMESTAMP WITH TIME ZONE,
    connected_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    last_synced_at TIMESTAMP WITH TIME ZONE,
    permissions JSONB NOT NULL DEFAULT '{}', -- What user consented to
    is_active BOOLEAN DEFAULT true,
    metadata JSONB DEFAULT '{}', -- Platform-specific data
    error_message TEXT, -- Last error (if any)
    sync_retry_count INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(agent_id, platform) -- One connection per platform per user
);

-- Indexes
CREATE INDEX idx_social_media_connections_agent_id ON api.social_media_connections(agent_id);
CREATE INDEX idx_social_media_connections_platform ON api.social_media_connections(platform);
CREATE INDEX idx_social_media_connections_active ON api.social_media_connections(is_active) WHERE is_active = true;
CREATE INDEX idx_social_media_connections_token_expires ON api.social_media_connections(token_expires_at) WHERE token_expires_at IS NOT NULL;

-- RLS Policies
ALTER TABLE api.social_media_connections ENABLE ROW LEVEL SECURITY;

-- Users can only access their own connections
CREATE POLICY social_media_connections_select ON api.social_media_connections
    FOR SELECT
    USING (
        agent_id IN (
            SELECT agent_id FROM api.user_agent_mappings 
            WHERE user_id = auth.uid()
        )
    );

CREATE POLICY social_media_connections_insert ON api.social_media_connections
    FOR INSERT
    WITH CHECK (
        agent_id IN (
            SELECT agent_id FROM api.user_agent_mappings 
            WHERE user_id = auth.uid()
        )
    );

CREATE POLICY social_media_connections_update ON api.social_media_connections
    FOR UPDATE
    USING (
        agent_id IN (
            SELECT agent_id FROM api.user_agent_mappings 
            WHERE user_id = auth.uid()
        )
    );

CREATE POLICY social_media_connections_delete ON api.social_media_connections
    FOR DELETE
    USING (
        agent_id IN (
            SELECT agent_id FROM api.user_agent_mappings 
            WHERE user_id = auth.uid()
        )
    );
```

#### **2. social_media_profiles**

**Purpose:** Store profile data from social platforms (cached locally, encrypted).

```sql
CREATE TABLE IF NOT EXISTS api.social_media_profiles (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    connection_id UUID NOT NULL REFERENCES api.social_media_connections(id) ON DELETE CASCADE,
    agent_id UUID NOT NULL REFERENCES api.user_agent_mappings(agent_id) ON DELETE CASCADE,
    platform TEXT NOT NULL,
    username TEXT,
    display_name TEXT,
    profile_image_url TEXT,
    interests TEXT[] DEFAULT '{}', -- Extracted interests
    communities TEXT[] DEFAULT '{}', -- Groups, pages, etc.
    friends_hashed TEXT[] DEFAULT '{}', -- Friend IDs (hashed with SHA-256)
    raw_data_encrypted TEXT, -- Raw platform data (encrypted, local only)
    last_updated TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(connection_id) -- One profile per connection
);

-- Indexes
CREATE INDEX idx_social_media_profiles_agent_id ON api.social_media_profiles(agent_id);
CREATE INDEX idx_social_media_profiles_connection_id ON api.social_media_profiles(connection_id);
CREATE INDEX idx_social_media_profiles_platform ON api.social_media_profiles(platform);
CREATE INDEX idx_social_media_profiles_interests ON api.social_media_profiles USING GIN(interests);
CREATE INDEX idx_social_media_profiles_communities ON api.social_media_profiles USING GIN(communities);

-- RLS Policies
ALTER TABLE api.social_media_profiles ENABLE ROW LEVEL SECURITY;

-- Users can only access their own profiles
CREATE POLICY social_media_profiles_select ON api.social_media_profiles
    FOR SELECT
    USING (
        agent_id IN (
            SELECT agent_id FROM api.user_agent_mappings 
            WHERE user_id = auth.uid()
        )
    );

CREATE POLICY social_media_profiles_insert ON api.social_media_profiles
    FOR INSERT
    WITH CHECK (
        agent_id IN (
            SELECT agent_id FROM api.user_agent_mappings 
            WHERE user_id = auth.uid()
        )
    );

CREATE POLICY social_media_profiles_update ON api.social_media_profiles
    FOR UPDATE
    USING (
        agent_id IN (
            SELECT agent_id FROM api.user_agent_mappings 
            WHERE user_id = auth.uid()
        )
    );

CREATE POLICY social_media_profiles_delete ON api.social_media_profiles
    FOR DELETE
    USING (
        agent_id IN (
            SELECT agent_id FROM api.user_agent_mappings 
            WHERE user_id = auth.uid()
        )
    );
```

#### **3. social_media_insights**

**Purpose:** Store derived personality insights from social media (on-device analysis results).

```sql
CREATE TABLE IF NOT EXISTS api.social_media_insights (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    agent_id UUID NOT NULL REFERENCES api.user_agent_mappings(agent_id) ON DELETE CASCADE,
    interest_scores JSONB DEFAULT '{}', -- Interest → score mapping
    community_scores JSONB DEFAULT '{}', -- Community → score mapping
    extracted_interests TEXT[] DEFAULT '{}',
    extracted_communities TEXT[] DEFAULT '{}',
    dimension_updates JSONB DEFAULT '{}', -- Personality dimension updates
    confidence_score DOUBLE PRECISION DEFAULT 0.0 CHECK (confidence_score >= 0.0 AND confidence_score <= 1.0),
    metadata JSONB DEFAULT '{}', -- Analysis metadata
    last_analyzed TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(agent_id) -- One insight record per user
);

-- Indexes
CREATE INDEX idx_social_media_insights_agent_id ON api.social_media_insights(agent_id);
CREATE INDEX idx_social_media_insights_confidence ON api.social_media_insights(confidence_score);
CREATE INDEX idx_social_media_insights_last_analyzed ON api.social_media_insights(last_analyzed);

-- RLS Policies
ALTER TABLE api.social_media_insights ENABLE ROW LEVEL SECURITY;

-- Users can only access their own insights
CREATE POLICY social_media_insights_select ON api.social_media_insights
    FOR SELECT
    USING (
        agent_id IN (
            SELECT agent_id FROM api.user_agent_mappings 
            WHERE user_id = auth.uid()
        )
    );

CREATE POLICY social_media_insights_insert ON api.social_media_insights
    FOR INSERT
    WITH CHECK (
        agent_id IN (
            SELECT agent_id FROM api.user_agent_mappings 
            WHERE user_id = auth.uid()
        )
    );

CREATE POLICY social_media_insights_update ON api.social_media_insights
    FOR UPDATE
    USING (
        agent_id IN (
            SELECT agent_id FROM api.user_agent_mappings 
            WHERE user_id = auth.uid()
        )
    );

CREATE POLICY social_media_insights_delete ON api.social_media_insights
    FOR DELETE
    USING (
        agent_id IN (
            SELECT agent_id FROM api.user_agent_mappings 
            WHERE user_id = auth.uid()
        )
    );
```

### **Migration File**

**File:** `supabase/migrations/019_social_media_integration.sql`

**Dependencies:**
- `002_migrate_existing_users` (agentId must exist)

**Migration Order:**
- After Phase 7.3 migrations complete
- Before any features using social media data

**Content:** All three table definitions above.

---

## 📊 **DATA FLOW**

### **Connection Flow**
```
User initiates connection
  ↓
OAuth flow (platform-specific)
  ↓
Store encrypted tokens (local)
  ↓
Fetch initial data (interests, communities, friends)
  ↓
Analyze for personality insights (on-device)
  ↓
Update personality profile (on-device)
  ↓
Cache data locally (offline-first)
```

### **Learning Flow**
```
Social media data (cached locally)
  ↓
Extract interests, communities, friends
  ↓
Map to personality dimensions (on-device)
  ↓
Update personality profile (on-device)
  ↓
Enhance recommendations (on-device)
  ↓
NO raw data in AI2AI network (only derived insights)
```

### **Sharing Flow**
```
User chooses to share place/list/experience
  ↓
User selects platform(s)
  ↓
User reviews what will be shared
  ↓
Share to platform(s)
  ↓
Track sharing (optional analytics)
```

### **Discovery Flow**
```
User connects social media
  ↓
Find friends who use SPOTS (hashed friend IDs)
  ↓
Show friend suggestions (privacy-preserving)
  ↓
User chooses to connect
  ↓
Share places/lists (if both users consent)
```

---

## 🔐 **PRIVACY & SECURITY**

### **Data Storage**
- **Tokens:** Encrypted at rest (AES-256-GCM)
- **Profile Data:** Encrypted at rest
- **Insights:** Stored locally (on-device)
- **Raw Data:** Never stored in cloud (only locally)

### **Data Usage**
- **Personality Learning:** Only derived insights (not raw data)
- **AI2AI Network:** NO social media data (only personality insights)
- **Recommendations:** Only derived insights (not raw data)
- **Sharing:** User-controlled (user chooses what to share)

### **Data Sharing**
- **With Platforms:** Only what user explicitly shares
- **With Friends:** Only if both users consent
- **With AI2AI:** NO social media data (only personality insights)
- **With Cloud:** NO raw social media data (only anonymized insights)

### **User Controls**
- **Connect/Disconnect:** User can disconnect at any time
- **Permissions:** Granular control per platform
- **Data Deletion:** User can delete all social media data
- **Privacy Settings:** Per-platform privacy controls

---

## 🎨 **USER EXPERIENCE**

### **Connection Flow**
1. **Settings → Social Media**
   - List of available platforms
   - "Connect" button for each platform
   - Show connection status

2. **OAuth Flow**
   - Platform-specific OAuth
   - Request permissions (granular)
   - Show what data will be used
   - User consent

3. **Initial Sync**
   - "Analyzing your interests..."
   - Progress indicator
   - "Done! Your recommendations are now more personalized"

### **Sharing Flow**
1. **From Place/List/Experience**
   - "Share" button
   - Select platform(s)
   - Preview what will be shared
   - Share

2. **Sharing Options**
   - Share place (with photo, if available)
   - Share list (with description)
   - Share experience (photo, story)

### **Discovery Flow**
1. **Find Friends**
   - "Find friends who use SPOTS"
   - Show friend suggestions (privacy-preserving)
   - User chooses to connect

2. **Similar Interests**
   - "People with similar interests"
   - Show suggestions (privacy-preserving)
   - User chooses to connect

### **Privacy Settings**
1. **Per-Platform Controls**
   - What data to use (interests, communities, friends)
   - What to share (places, lists, experiences)
   - Who can see (friends, public, etc.)

2. **Global Controls**
   - Use social media for recommendations (on/off)
   - Share places automatically (on/off)
   - Find friends automatically (on/off)

---

## 📅 **IMPLEMENTATION PHASES**

### **Phase 1: Core Infrastructure (Weeks 1-2)**

#### **Week 1: Foundation**
- [ ] Data models (SocialMediaConnection, SocialMediaProfile, SocialMediaInsights)
- [ ] SocialMediaConnectionService (connect/disconnect, token management)
- [ ] Encrypted storage for tokens
- [ ] OAuth flow infrastructure
- [ ] Basic UI (connection settings page)

#### **Week 2: Instagram Integration**
- [ ] Instagram OAuth flow
- [ ] Instagram API integration
- [ ] Fetch interests, saved places, communities
- [ ] Parse Instagram data
- [ ] Cache Instagram data locally
- [ ] Basic personality insight extraction

**Deliverables:**
- ✅ Users can connect Instagram
- ✅ Instagram data cached locally
- ✅ Basic personality insights extracted
- ✅ **UI Integration Complete:** Onboarding and Settings pages connected to backend services

---

### **Phase 2: Facebook & Twitter (Weeks 3-4)**

#### **Week 3: Facebook Integration**
- [ ] Facebook OAuth flow
- [ ] Facebook API integration
- [ ] Fetch friends, events, groups, interests
- [ ] Parse Facebook data
- [ ] Cache Facebook data locally
- [ ] Personality insight extraction

#### **Week 4: Twitter Integration**
- [ ] Twitter OAuth flow
- [ ] Twitter API integration
- [ ] Fetch interests, communities, trends
- [ ] Parse Twitter data
- [ ] Cache Twitter data locally
- [ ] Personality insight extraction

**Deliverables:**
- ✅ Users can connect Facebook and Twitter
- ✅ Data cached locally for all platforms
- ✅ Personality insights extracted from all platforms

---

### **Phase 3: Personality Learning Integration (Weeks 5-6)**

#### **Week 5: Insight Analysis**
- [ ] SocialMediaInsightService (analyze social media data)
- [ ] Map interests to personality dimensions
- [ ] Map communities to community orientation
- [ ] Map friends to social discovery style
- [ ] Update personality profile (on-device)
- [ ] Enhance recommendations based on insights

#### **Week 6: Sharing System**
- [ ] SocialMediaSharingService
- [ ] Share places to platforms
- [ ] Share lists to platforms
- [ ] Share experiences (photos, stories)
- [ ] Sharing UI (from places, lists, experiences)

**Deliverables:**
- ✅ Social media insights enhance personality learning
- ✅ Users can share places, lists, experiences
- ✅ Recommendations improved by social media insights

---

### **Phase 4: Discovery & Extended Platforms (Weeks 7-8)**

#### **Week 7: Friend Discovery**
- [ ] SocialMediaDiscoveryService
- [ ] Find friends who use SPOTS (privacy-preserving)
- [ ] Show friend suggestions
- [ ] Connect with friends
- [ ] Share places/lists with friends

#### **Week 8: Extended Platforms & User-Provided Handles (Option 3)**
- [ ] TikTok integration
- [ ] LinkedIn integration
- [ ] Pinterest integration
- [ ] **User-Provided Handles Feature (Option 3):**
  - [ ] UI for users to optionally provide public social media handles
  - [ ] Consent flow for public profile analysis
  - [ ] Public profile analysis service (Instagram, TikTok, Twitter)
  - [ ] Extract interests from public posts (with explicit consent)
  - [ ] Use insights to refine personality profile
  - [ ] Privacy controls for handle-based analysis
- [ ] Polish and testing

**Deliverables:**
- ✅ Users can find friends who use SPOTS
- ✅ Extended platform support
- ✅ User-provided handles opt-in feature (Option 3)
- ✅ Complete social media integration

---

## 🔗 **INTEGRATION WITH EXISTING SYSTEMS**

### **Personality Learning System**
- **File:** `lib/core/ai/personality_learning.dart`
- **Integration:** Social media insights feed into personality learning
- **Changes:** Add social media insight processing
- **Privacy:** Only derived insights, not raw data

### **Vibe Analysis Engine**
- **File:** `lib/core/ai/vibe_analysis_engine.dart`
- **Integration:** Social media interests enhance vibe compilation
- **Changes:** Add social media interest analysis
- **Privacy:** Only anonymized insights

### **Recommendation Engine**
- **Files:** Various recommendation services
- **Integration:** Social media interests inform recommendations
- **Changes:** Add social media interest weighting
- **Privacy:** Only derived insights

### **User Model**
- **File:** `lib/core/models/user.dart`
- **Integration:** Add social media connections
- **Changes:** Add `socialMediaConnections` field (optional)

### **Settings UI**
- **Files:** Settings pages
- **Integration:** Add social media connection settings
- **Changes:** New settings section for social media

**⚠️ IMPORTANT: UI Pages Already Created (Pre-Phase 12)**
- **Onboarding Page:** `lib/presentation/pages/onboarding/social_media_connection_page.dart`
  - Already integrated into onboarding flow (optional step after "Friends & Respect")
  - Contains placeholder OAuth logic (marked with `// TODO`)
  - **Action Required:** Connect to `SocialMediaConnectionService.connectPlatform()` when Phase 12 backend is ready
  
- **Settings Page:** `lib/presentation/pages/settings/social_media_settings_page.dart`
  - Already accessible from Profile → Settings → Social Media
  - Contains placeholder connection/disconnection logic (marked with `// TODO`)
  - **Action Required:** Connect to `SocialMediaConnectionService` methods when Phase 12 backend is ready

**Integration Steps (When Phase 12 Backend is Ready):**
1. Replace placeholder `_connectPlatform()` method with actual `SocialMediaConnectionService.connectPlatform(platform)`
2. Replace placeholder `_disconnectPlatform()` method with actual `SocialMediaConnectionService.disconnectPlatform(platform)`
3. Replace placeholder `_loadConnections()` method with actual `SocialMediaConnectionService.getConnections(userId)`
4. Update UI to show actual connection status from service
5. Handle OAuth callbacks and token storage through service

---

## 📦 **DEPENDENCIES**

### **External Dependencies**
- **OAuth Libraries:** Platform-specific OAuth libraries
- **API Clients:** Instagram, Facebook, Twitter API clients
- **Encryption:** Existing encryption service (for token storage)

### **Internal Dependencies**
- **Personality Learning System:** Must be complete
- **Vibe Analysis Engine:** Must be complete
- **Recommendation Engine:** Must be complete
- **User Model:** Must support social media connections

---

## ⚠️ **RISKS & MITIGATION**

### **Risk 1: API Rate Limits**
- **Risk:** Social media APIs have rate limits
- **Mitigation:** Cache data locally, sync in background, respect rate limits
- **Details:** See "API Rate Limiting" section below

### **Risk 2: Privacy Concerns**
- **Risk:** Users concerned about privacy
- **Mitigation:** Clear privacy controls, transparent data usage, user control
- **Details:** See "Privacy Compliance" section below

### **Risk 3: Platform Changes**
- **Risk:** Social media APIs change frequently
- **Mitigation:** Abstract platform-specific code, version APIs, handle gracefully
- **Details:** See "Error Handling" section below

### **Risk 4: Token Expiration**
- **Risk:** OAuth tokens expire
- **Mitigation:** Refresh tokens, handle expiration gracefully, re-authenticate when needed
- **Details:** See "Token Refresh Flow" section below

### **Risk 5: Data Sync Issues**
- **Risk:** Data sync fails or is incomplete
- **Mitigation:** Retry logic, background sync, handle errors gracefully
- **Details:** See "Background Sync Implementation" section below

---

## ✅ **SUCCESS CRITERIA**

### **Phase 1: Core Infrastructure**
- ✅ Users can connect Instagram
- ✅ Instagram data cached locally
- ✅ Basic personality insights extracted

### **Phase 2: Facebook & Twitter**
- ✅ Users can connect Facebook and Twitter
- ✅ Data cached locally for all platforms
- ✅ Personality insights extracted from all platforms

### **Phase 3: Personality Learning Integration**
- ✅ Social media insights enhance personality learning
- ✅ Users can share places, lists, experiences
- ✅ Recommendations improved by social media insights

### **Phase 4: Discovery & Extended Platforms**
- ✅ Users can find friends who use SPOTS
- ✅ Extended platform support
- ✅ Complete social media integration

---

## 🔄 **OAUTH IMPLEMENTATION DETAILS**

### **OAuth Libraries**

**Flutter Packages:**
- **`flutter_appauth`** - OAuth 2.0 client for Flutter (supports Instagram, Facebook, Twitter)
- **`oauth2`** - OAuth 2.0 client library (for custom implementations)
- **Platform-specific:**
  - Instagram: `instagram_basic_display_api` (if available) or custom OAuth
  - Facebook: `flutter_facebook_auth` or `facebook_auth`
  - Twitter: `twitter_login` or custom OAuth 2.0

### **OAuth Flow Diagram**

```
User taps "Connect [Platform]"
  ↓
1. Generate OAuth state (CSRF protection)
2. Build authorization URL with:
   - Client ID
   - Redirect URI
   - Scopes (granular permissions)
   - State (CSRF token)
  ↓
3. Open OAuth URL in browser/webview
  ↓
4. User authenticates on platform
  ↓
5. Platform redirects to redirect URI with:
   - Authorization code (or access token)
   - State (verify CSRF)
  ↓
6. Exchange authorization code for tokens:
   - Access token
   - Refresh token (if available)
   - Expiration time
  ↓
7. Encrypt tokens (AES-256-GCM)
8. Store encrypted tokens locally
9. Store connection in database (agentId)
  ↓
10. Fetch initial data (interests, profile, etc.)
11. Cache data locally
12. Analyze for personality insights
```

### **Redirect URI Configuration**

**Format:** `spots://oauth/[platform]/callback`

**Examples:**
- Instagram: `spots://oauth/instagram/callback`
- Facebook: `spots://oauth/facebook/callback`
- Twitter: `spots://oauth/twitter/callback`

**Platform Configuration:**
- Register redirect URIs in each platform's developer console
- Use deep linking for mobile apps
- Handle web fallback if needed

### **Client ID/Secret Management**

**Storage:**
- **Client IDs:** Can be stored in app (public)
- **Client Secrets:** Store in Supabase Edge Function (server-side only)
- **Never:** Store secrets in client code

**Implementation:**
- Client ID in app config
- Client secret in Edge Function
- Token exchange happens server-side (Edge Function)

### **Token Storage Encryption**

**Method:** AES-256-GCM (Authenticated Encryption)

**Storage:**
- Use `flutter_secure_storage` (Keychain on iOS, Keystore on Android)
- Encrypt before storing
- Decrypt when needed
- Never store plaintext tokens

**Key Management:**
- Generate per-user encryption keys
- Store keys in secure storage
- Rotate keys periodically

### **Platform-Specific OAuth Requirements**

**Instagram:**
- Requires Instagram Basic Display API
- OAuth 2.0 flow
- Scopes: `user_profile`, `user_media`
- Token expiration: 60 days (refreshable)

**Facebook:**
- Facebook Login (OAuth 2.0)
- Scopes: `email`, `public_profile`, `user_posts`, `user_friends` (if available)
- Token expiration: 60 days (refreshable)

**Twitter:**
- OAuth 2.0 (new) or OAuth 1.0a (legacy)
- Scopes: `tweet.read`, `users.read`, `offline.access`
- Token expiration: Varies (refreshable with offline.access)

---

## 🔄 **TOKEN REFRESH FLOW**

### **Refresh Strategy**

**When to Refresh:**
- **Proactive:** Refresh 24 hours before expiration
- **Reactive:** Refresh when token expires (401 error)
- **Background:** Check token expiration daily, refresh if needed

### **Refresh Flow Diagram**

```
Token expires in < 24 hours OR API returns 401
  ↓
1. Check if refresh token exists
  ↓
2. If refresh token exists:
   - Call platform refresh endpoint
   - Get new access token
   - Get new refresh token (if provided)
   - Update expiration time
   - Encrypt and store new tokens
   - Update database
  ↓
3. If refresh token missing/invalid:
   - Mark connection as inactive
   - Show user notification: "Reconnect [Platform]"
   - User can reconnect from settings
  ↓
4. If refresh fails:
   - Retry with exponential backoff (3 attempts)
   - If all retries fail: Mark as inactive, notify user
```

### **Error Handling for Refresh Failures**

**Scenarios:**
1. **Refresh token expired:** User must re-authenticate
2. **Network error:** Retry with exponential backoff
3. **Platform API error:** Log error, mark connection inactive
4. **Invalid refresh token:** User must re-authenticate

**User Experience:**
- Show notification: "Your [Platform] connection expired. Reconnect to continue syncing."
- Provide "Reconnect" button in settings
- Don't block app usage (feature works offline with cached data)

### **Re-Authentication Flow**

```
User taps "Reconnect [Platform]"
  ↓
1. Clear old tokens (if any)
2. Start fresh OAuth flow
3. User authenticates
4. Get new tokens
5. Update connection status
6. Resume syncing
```

---

## 🔄 **BACKGROUND SYNC IMPLEMENTATION**

### **Sync Strategy**

**Sync Frequency:**
- **Initial sync:** Immediately after connection
- **Periodic sync:** Every 24 hours (when app is active)
- **Manual sync:** User can trigger from settings
- **Event-triggered:** After user shares/engages with platform

**Sync Triggers:**
1. **App launch:** Check if sync needed (last sync > 24 hours)
2. **User action:** After sharing to platform
3. **Scheduled:** Background task (if available)
4. **Manual:** User taps "Sync Now" in settings

### **Sync Queue Management**

**Queue Structure:**
- Priority queue (new connections first)
- Retry queue (failed syncs)
- Rate limit queue (wait for rate limit reset)

**Queue Processing:**
- Process one platform at a time
- Respect rate limits (wait if needed)
- Retry failed syncs with exponential backoff
- Remove successful syncs from queue

### **Conflict Resolution**

**Scenarios:**
1. **Local data newer:** Keep local, update cloud
2. **Cloud data newer:** Update local
3. **Both changed:** Merge (prefer local for user control)
4. **Data corruption:** Use cloud as source of truth

**Strategy:**
- Timestamp-based conflict resolution
- User preference: Local-first (user controls their data)
- Log conflicts for analysis

### **Offline Queue Handling**

**When Offline:**
- Queue sync requests
- Store in local database
- Process when online

**When Online:**
- Process queued syncs
- Respect rate limits
- Handle errors gracefully

### **Battery Optimization**

**Strategies:**
- Sync only when device is charging (optional)
- Batch syncs (multiple platforms together)
- Reduce sync frequency on low battery
- Use background tasks efficiently

### **Network Usage Optimization**

**Strategies:**
- Sync only on WiFi (optional, user setting)
- Compress data before sync
- Incremental sync (only changed data)
- Cache aggressively (reduce API calls)

---

## ⚠️ **ERROR HANDLING & EDGE CASES**

### **OAuth Flow Failures**

**Scenario 1: User Cancels OAuth**
- **Detection:** OAuth callback with error or user cancellation
- **Handling:** Show message: "Connection cancelled. You can try again anytime."
- **Recovery:** User can retry from settings

**Scenario 2: Network Error During OAuth**
- **Detection:** Network timeout or connection error
- **Handling:** Show error: "Connection failed. Check your internet and try again."
- **Recovery:** Retry OAuth flow

**Scenario 3: Invalid Client ID/Secret**
- **Detection:** OAuth error response
- **Handling:** Log error, show generic message: "Connection failed. Please contact support."
- **Recovery:** Check configuration, fix client ID/secret

### **Token Expiration Handling**

**Scenario 1: Token Expires During API Call**
- **Detection:** API returns 401 Unauthorized
- **Handling:** 
  1. Attempt token refresh
  2. Retry API call with new token
  3. If refresh fails: Mark connection inactive, notify user
- **Recovery:** User reconnects from settings

**Scenario 2: Refresh Token Expired**
- **Detection:** Refresh endpoint returns error
- **Handling:** Mark connection inactive, show notification: "Reconnect [Platform]"
- **Recovery:** User re-authenticates

### **API Rate Limiting**

**Scenario 1: Rate Limit Hit**
- **Detection:** API returns 429 Too Many Requests
- **Handling:**
  1. Extract retry-after header
  2. Queue request for later
  3. Show user: "Rate limit reached. Will sync when available."
  4. Retry after retry-after time
- **Recovery:** Automatic retry after rate limit reset

**Scenario 2: Rate Limit Approaching**
- **Detection:** API returns rate limit headers (X-RateLimit-Remaining)
- **Handling:** Reduce sync frequency, wait before next request
- **Recovery:** Automatic adjustment

### **Platform API Changes**

**Scenario 1: API Endpoint Deprecated**
- **Detection:** API returns 410 Gone or 404 Not Found
- **Handling:**
  1. Log error with endpoint
  2. Check for API version updates
  3. Update to new endpoint (if available)
  4. Mark connection inactive if no update available
- **Recovery:** Update app with new API version

**Scenario 2: API Response Format Changed**
- **Detection:** Parsing error or unexpected data structure
- **Handling:**
  1. Log error with response data
  2. Fallback to cached data
  3. Notify user: "Platform data format changed. Some features may be limited."
- **Recovery:** Update parsing logic in app update

### **User Disconnects Mid-Sync**

**Scenario:** User disconnects platform while sync in progress
- **Detection:** Connection marked inactive during sync
- **Handling:**
  1. Cancel in-progress sync
  2. Clean up partial data
  3. Remove connection from database
  4. Clear cached data
- **Recovery:** User can reconnect anytime

### **Partial Sync Failures**

**Scenario:** Some data syncs, some fails
- **Detection:** Partial success response or timeout
- **Handling:**
  1. Save successfully synced data
  2. Queue failed data for retry
  3. Log partial failure
  4. Retry failed items later
- **Recovery:** Automatic retry on next sync

### **Data Corruption Recovery**

**Scenario:** Cached data becomes corrupted
- **Detection:** Data validation fails or parsing error
- **Handling:**
  1. Delete corrupted data
  2. Re-sync from platform
  3. If re-sync fails: Use last known good data
- **Recovery:** Automatic re-sync

### **Network Failures During Sync**

**Scenario:** Network drops during sync
- **Detection:** Network timeout or connection error
- **Handling:**
  1. Save partial progress
  2. Queue remaining items
  3. Retry when network available
  4. Show user: "Sync paused. Will continue when online."
- **Recovery:** Automatic retry when online

---

## 📊 **API RATE LIMITING DETAILS**

### **Platform-Specific Rate Limits**

**Instagram:**
- **Basic Display API:** 200 requests/hour per user
- **Graph API:** Varies by endpoint (check documentation)
- **Strategy:** Cache aggressively, batch requests, respect limits

**Facebook:**
- **Graph API:** 200 requests/hour per user (default)
- **App-level:** 4,800 requests/hour (shared across users)
- **Strategy:** Use batch requests, cache data, respect user limits

**Twitter:**
- **API v2:** 300 requests/15 minutes per user
- **App-level:** Varies by tier
- **Strategy:** Implement exponential backoff, cache data

**TikTok:**
- **API:** Varies (check documentation)
- **Strategy:** Cache aggressively, respect limits

**LinkedIn:**
- **API:** 500 requests/day per user
- **Strategy:** Batch requests, cache data, respect daily limits

**Pinterest:**
- **API:** Varies (check documentation)
- **Strategy:** Cache aggressively, respect limits

### **Rate Limit Handling Strategy**

**Detection:**
- Monitor API response headers (X-RateLimit-Remaining, X-RateLimit-Reset)
- Track request counts per platform
- Detect 429 Too Many Requests responses

**Handling:**
1. **Proactive:** Reduce request frequency when approaching limits
2. **Reactive:** When limit hit:
   - Extract retry-after header
   - Queue requests for later
   - Wait for rate limit reset
   - Retry with exponential backoff

**Retry Logic:**
- Exponential backoff: 1s, 2s, 4s, 8s, 16s
- Maximum retries: 5 attempts
- Respect retry-after header if provided

### **Rate Limit Monitoring**

**Metrics to Track:**
- Requests per hour per platform
- Rate limit hits per platform
- Average time to rate limit reset
- Success rate after rate limit

**Alerts:**
- Rate limit approaching (80% of limit)
- Rate limit hit
- High rate limit frequency

### **User Messaging for Rate Limits**

**Messages:**
- "Rate limit reached. Will sync when available."
- "Syncing paused due to platform limits. Will resume automatically."
- "Some data may be delayed due to platform rate limits."

**User Actions:**
- Show sync status in settings
- Allow manual sync retry
- Show estimated time until next sync

### **Fallback Behavior**

**When Rate Limited:**
- Use cached data (if available)
- Show cached data to user
- Queue sync for later
- Don't block app functionality

---

## 🔐 **PRIVACY COMPLIANCE DETAILS**

### **GDPR Compliance**

#### **Right to Access (Article 15)**
**Implementation:**
- **Data Export:** User can export all social media data
- **Export Format:** JSON file with all connections, profiles, insights
- **Export Location:** Settings → Privacy → Export Social Media Data
- **Data Included:** Connections, profiles, insights, permissions

#### **Right to Deletion (Article 17)**
**Implementation:**
- **Data Deletion:** User can delete all social media data
- **Deletion Scope:**
  - Delete all connections
  - Delete all profiles
  - Delete all insights
  - Revoke all tokens
  - Clear all cached data
- **Deletion Location:** Settings → Privacy → Delete Social Media Data
- **Confirmation:** Require user confirmation before deletion
- **Irreversible:** Data cannot be recovered after deletion

#### **Right to Rectification (Article 16)**
**Implementation:**
- **Data Correction:** User can update social media connections
- **Update Method:** Disconnect and reconnect platform
- **Automatic Updates:** Sync updates profile data automatically

#### **Consent Management (Article 7)**
**Implementation:**
- **Granular Consent:** User consents to each permission separately
- **Consent Tracking:** Store consent per permission in database
- **Consent Withdrawal:** User can revoke consent anytime
- **Consent History:** Track consent changes over time

#### **Data Minimization (Article 5)**
**Implementation:**
- **Minimal Data:** Only collect data needed for features
- **Optional Features:** User can disable features that require data
- **Data Retention:** Delete data when no longer needed
- **Purpose Limitation:** Use data only for stated purposes

### **CCPA Compliance**

#### **Right to Know (Section 1798.100)**
**Implementation:**
- **Data Disclosure:** User can see what data is collected
- **Disclosure Location:** Settings → Privacy → Social Media Data
- **Data Categories:** Show categories of data collected
- **Data Sources:** Show which platforms provide data

#### **Right to Delete (Section 1798.105)**
**Implementation:**
- **Same as GDPR:** Use same deletion flow as GDPR
- **Verification:** Verify user identity before deletion
- **Confirmation:** Require user confirmation

#### **Right to Opt-Out (Section 1798.120)**
**Implementation:**
- **Opt-Out Option:** User can opt out of data collection
- **Opt-Out Location:** Settings → Privacy → Social Media Data → Opt Out
- **Opt-Out Effect:** Stop collecting new data, keep existing data
- **Opt-Out Reversal:** User can opt back in anytime

#### **Non-Discrimination (Section 1798.125)**
**Implementation:**
- **Equal Service:** All users receive same service regardless of privacy choices
- **No Penalties:** No penalties for privacy choices
- **Feature Access:** All features available regardless of privacy choices

### **Data Retention Policies**

**Retention Periods:**
- **Active Connections:** Retain while connection is active
- **Inactive Connections:** Delete after 90 days of inactivity
- **Insights:** Retain while connection is active
- **Cached Data:** Retain for 30 days, then refresh

**Deletion Triggers:**
- User disconnects platform
- User deletes account
- User requests deletion
- Connection inactive for 90 days

### **Data Minimization Strategies**

**Strategies:**
- Only collect data needed for features
- Delete data when no longer needed
- Anonymize data before AI2AI sharing
- Use derived insights, not raw data

### **Privacy Impact Assessment**

**Assessment Areas:**
- Data collection scope
- Data usage purposes
- Data sharing (AI2AI, cloud)
- Security measures
- User controls

**Documentation:**
- Document all data collection
- Document all data usage
- Document all data sharing
- Document security measures
- Document user controls

---

## 📈 **ANALYTICS & SUCCESS METRICS**

### **Metrics to Track**

#### **Connection Metrics**
- **Connection Success Rate:** % of OAuth flows that complete successfully
- **Connection Failure Rate:** % of OAuth flows that fail
- **Platform Distribution:** % of users connected to each platform
- **Average Connections per User:** Average number of platforms connected

#### **Sync Metrics**
- **Sync Success Rate:** % of syncs that complete successfully
- **Sync Failure Rate:** % of syncs that fail
- **Average Sync Duration:** Average time to complete sync
- **Sync Frequency:** How often users sync data

#### **Sharing Metrics**
- **Sharing Engagement:** % of users who share places/lists/experiences
- **Sharing Frequency:** Average shares per user per week
- **Platform Distribution:** Which platforms users share to most
- **Sharing Success Rate:** % of shares that complete successfully

#### **Friend Discovery Metrics**
- **Friend Discovery Rate:** % of users who find friends via social media
- **Friend Connection Rate:** % of friend suggestions that result in connections
- **Average Friends Found:** Average number of friends found per user

#### **Recommendation Improvement Metrics**
- **Recommendation Accuracy:** Improvement in recommendation accuracy with social media data
- **User Satisfaction:** User feedback on recommendations
- **Engagement Rate:** Increase in user engagement with recommendations

#### **Privacy Compliance Metrics**
- **Consent Rate:** % of users who consent to data collection
- **Opt-Out Rate:** % of users who opt out
- **Data Deletion Requests:** Number of data deletion requests
- **Privacy Settings Usage:** % of users who adjust privacy settings

#### **Error Rate Tracking**
- **OAuth Error Rate:** % of OAuth flows that error
- **Sync Error Rate:** % of syncs that error
- **API Error Rate:** % of API calls that error
- **Token Refresh Error Rate:** % of token refreshes that fail

### **Analytics Implementation**

**Tools:**
- **Firebase Analytics:** Track user events
- **Custom Analytics:** Track feature-specific metrics
- **Error Tracking:** Track errors and failures

**Events to Track:**
- `social_media_connect_started` - User starts OAuth flow
- `social_media_connect_succeeded` - OAuth flow completes successfully
- `social_media_connect_failed` - OAuth flow fails
- `social_media_sync_started` - Sync starts
- `social_media_sync_succeeded` - Sync completes successfully
- `social_media_sync_failed` - Sync fails
- `social_media_share` - User shares to platform
- `social_media_friend_found` - Friend discovered
- `social_media_friend_connected` - Friend connection made

### **Success Criteria**

**Phase 1:**
- Connection success rate > 80%
- Sync success rate > 90%

**Phase 2:**
- Connection success rate > 85%
- Sync success rate > 95%
- Platform distribution: Instagram 40%, Facebook 30%, Twitter 20%, Others 10%

**Phase 3:**
- Sharing engagement > 20%
- Recommendation accuracy improvement > 10%

**Phase 4:**
- Friend discovery rate > 15%
- Overall user satisfaction > 4.0/5.0

---

## 🎓 **USER ONBOARDING FLOW**

### **Onboarding Triggers**

**Trigger Points:**
1. **After First Spot Saved:** "Want to share this with friends?"
2. **After First List Created:** "Connect social media to find friends who use SPOTS"
3. **After Multiple Visits:** "Connect to get better recommendations based on your interests"
4. **Settings Discovery:** User navigates to Settings → Social Media

**Timing:**
- **Not on first app launch:** Don't overwhelm new users
- **After engagement:** Show value after user has engaged with app
- **Optional:** Never required, always optional

### **Onboarding UI/UX Design**

**Connection Prompt:**
- **Location:** In-app notification or settings page
- **Design:** 
  - Clear value proposition
  - Platform icons
  - "Connect" button
  - "Not now" / "Remind me later" options
- **Messaging:** "Connect [Platform] to discover friends and get better recommendations"

**Progressive Disclosure:**
- **Step 1:** Show value proposition
- **Step 2:** Show what data will be used
- **Step 3:** Show privacy controls
- **Step 4:** Request permissions
- **Step 5:** Complete connection

### **Value Proposition Messaging**

**Messages:**
- "Connect [Platform] to discover friends who use SPOTS"
- "Get better recommendations based on your interests"
- "Share your favorite places with friends"
- "Find communities that match your vibe"

**Personalization:**
- Use user's name
- Reference their activity (spots saved, lists created)
- Show social proof (friends already connected)

### **Permission Request Timing**

**Strategy:**
- **Request after value:** Show value before requesting permissions
- **Granular permissions:** Request each permission separately
- **Explain why:** Explain why each permission is needed
- **User control:** User can deny permissions and still use app

### **Skip/Remind Later Options**

**Options:**
- **"Not now":** Dismiss prompt, don't show again for 7 days
- **"Remind me later":** Dismiss prompt, show again in 3 days
- **"Skip":** Dismiss prompt permanently (user can connect manually later)

**Reminder Logic:**
- Show reminder after 3 days (if "Remind me later")
- Show reminder after 7 days (if "Not now")
- Don't show reminder if "Skip" selected
- User can connect manually from settings anytime

---

## 🔄 **DATA MIGRATION FOR EXISTING USERS**

### **Migration Strategy**

**For Existing Users:**
- **No automatic migration:** Users must manually connect social media
- **Opt-in only:** Feature is optional, users choose to connect
- **Backward compatible:** App works without social media connections

### **Migration Flow**

**When Feature Launches:**
1. **Existing users:** See onboarding prompt (optional)
2. **New users:** See onboarding prompt during onboarding
3. **Manual connection:** Users can connect anytime from settings

**No Data Migration Needed:**
- No existing social media data to migrate
- Users start fresh when they connect
- No backward compatibility issues

### **Rollout Strategy**

**Phased Rollout:**
- **Phase 1:** Beta users (10% of users)
- **Phase 2:** Gradual rollout (25%, 50%, 100%)
- **Phase 3:** Full release

**Monitoring:**
- Track connection rates
- Monitor error rates
- Collect user feedback
- Adjust rollout based on metrics

### **Backward Compatibility**

**Compatibility:**
- App works without social media connections
- All features available without connections
- Social media enhances features, doesn't replace them
- Users can disconnect anytime

---

## 🔧 **BACKEND REQUIREMENTS**

### **Backend API Endpoints**

**No New Endpoints Required:**
- All data stored locally (offline-first)
- Social media APIs called directly from client
- No backend proxy needed

**Optional Endpoints (Future):**
- **Token Exchange Endpoint:** Exchange authorization code for tokens (server-side)
- **Friend Discovery Endpoint:** Find friends who use SPOTS (privacy-preserving)
- **Analytics Endpoint:** Track social media feature usage

### **Edge Functions**

**Optional Edge Functions:**
- **Token Exchange:** Exchange OAuth authorization code for tokens (if client secret needed)
- **Friend Discovery:** Privacy-preserving friend matching (if needed)
- **Analytics:** Track feature usage (if needed)

**Implementation:**
- Use Supabase Edge Functions
- Store client secrets in environment variables
- Implement rate limiting
- Log all requests

### **Database Changes**

**Required:**
- See "Database Schema & Migrations" section above
- Three new tables: `social_media_connections`, `social_media_profiles`, `social_media_insights`
- RLS policies for privacy
- Indexes for performance

### **Authentication Changes**

**No Changes Required:**
- Use existing authentication system
- Use existing agentId system (Phase 7.3)
- No new authentication flows needed

### **Privacy Compliance Backend**

**Required:**
- **Data Export:** API endpoint to export user's social media data
- **Data Deletion:** API endpoint to delete user's social media data
- **Consent Tracking:** Store consent in database
- **Audit Logging:** Log all data access and changes

---

## 📱 **PLATFORM-SPECIFIC REQUIREMENTS**

### **Instagram**

**API:** Instagram Basic Display API / Instagram Graph API

**Requirements:**
- OAuth 2.0 flow
- Client ID and Client Secret
- Redirect URI: `spots://oauth/instagram/callback`
- Scopes: `user_profile`, `user_media`

**Rate Limits:**
- Basic Display: 200 requests/hour per user
- Graph API: Varies by endpoint

**Data Available:**
- Profile (username, display name, profile image)
- Media (photos, saved posts)
- Interests (from posts, follows)

**Permissions:**
- `user_profile` - Basic profile info
- `user_media` - User's media

### **Facebook**

**API:** Facebook Graph API

**Requirements:**
- Facebook Login (OAuth 2.0)
- App ID and App Secret
- Redirect URI: `spots://oauth/facebook/callback`
- Scopes: `email`, `public_profile`, `user_posts`, `user_friends` (if available)

**Rate Limits:**
- 200 requests/hour per user (default)
- 4,800 requests/hour app-level (shared)

**Data Available:**
- Profile (name, email, profile image)
- Posts (interests, activities)
- Friends (if permission granted)
- Events (if permission granted)
- Groups (if permission granted)

**Permissions:**
- `email` - User's email
- `public_profile` - Basic profile info
- `user_posts` - User's posts
- `user_friends` - User's friends (limited availability)

### **Twitter/X**

**API:** Twitter API v2

**Requirements:**
- OAuth 2.0 (preferred) or OAuth 1.0a
- Client ID and Client Secret
- Redirect URI: `spots://oauth/twitter/callback`
- Scopes: `tweet.read`, `users.read`, `offline.access`

**Rate Limits:**
- 300 requests/15 minutes per user
- Varies by endpoint and tier

**Data Available:**
- Profile (username, display name, profile image)
- Tweets (interests, communities)
- Follows (interests, communities)
- Likes (interests)

**Permissions:**
- `tweet.read` - Read user's tweets
- `users.read` - Read user's profile
- `offline.access` - Refresh token access

### **TikTok**

**API:** TikTok API (check current documentation)

**Requirements:**
- OAuth 2.0 flow
- Client Key and Client Secret
- Redirect URI: `spots://oauth/tiktok/callback`
- Scopes: Varies (check documentation)

**Rate Limits:**
- Varies (check documentation)

**Data Available:**
- Profile (username, display name, profile image)
- Videos (interests, trends)
- Follows (interests, communities)

### **LinkedIn**

**API:** LinkedIn API v2

**Requirements:**
- OAuth 2.0 flow
- Client ID and Client Secret
- Redirect URI: `spots://oauth/linkedin/callback`
- Scopes: `r_liteprofile`, `r_emailaddress`, `r_basicprofile`

**Rate Limits:**
- 500 requests/day per user

**Data Available:**
- Profile (name, email, profile image)
- Connections (professional network)
- Interests (from posts, follows)

### **Pinterest**

**API:** Pinterest API (check current documentation)

**Requirements:**
- OAuth 2.0 flow
- App ID and App Secret
- Redirect URI: `spots://oauth/pinterest/callback`
- Scopes: Varies (check documentation)

**Rate Limits:**
- Varies (check documentation)

**Data Available:**
- Profile (username, display name, profile image)
- Boards (interests, saved places)
- Pins (interests, saved places)

---

## 🧪 **TESTING STRATEGY**

### **Test Coverage Requirements**

**Target Coverage:**
- **Unit Tests:** > 80% coverage for services
- **Integration Tests:** All OAuth flows
- **Widget Tests:** All UI components
- **End-to-End Tests:** Complete user flows
- **Privacy Tests:** All privacy features

### **Unit Tests**

**Services to Test:**
- `SocialMediaConnectionService`
- `SocialMediaDataService`
- `SocialMediaInsightService`
- `SocialMediaSharingService`
- `SocialMediaDiscoveryService`

**Test Scenarios:**
- Connect/disconnect platforms
- Token management (encryption, storage, retrieval)
- Data fetching and parsing
- Insight extraction
- Sharing functionality
- Friend discovery

### **Integration Tests**

**OAuth Flows:**
- Instagram OAuth flow
- Facebook OAuth flow
- Twitter OAuth flow
- Token refresh flow
- Error handling in OAuth flows

**API Integration:**
- API calls to each platform
- Rate limit handling
- Error responses
- Data parsing

### **Widget Tests**

**UI Components:**
- Connection settings page
- OAuth flow UI
- Sharing UI
- Friend discovery UI
- Privacy settings UI

**Test Scenarios:**
- UI renders correctly
- User interactions work
- Error states display correctly
- Loading states display correctly

### **End-to-End Tests**

**User Flows:**
- Complete connection flow (OAuth → Sync → Insights)
- Complete sharing flow (Select → Share → Confirm)
- Complete friend discovery flow (Connect → Discover → Connect)
- Complete disconnection flow (Disconnect → Confirm → Cleanup)

### **Privacy Tests**

**Privacy Features:**
- Data encryption (tokens, profiles)
- Data anonymization (AI2AI sharing)
- Data deletion (GDPR compliance)
- Consent management
- Privacy settings

**Test Scenarios:**
- Tokens encrypted at rest
- No personal data in AI2AI network
- Data deletion removes all data
- Consent tracked correctly
- Privacy settings respected

### **Error Handling Tests**

**Error Scenarios:**
- OAuth flow failures
- Token expiration
- API rate limiting
- Network failures
- Data corruption
- Platform API changes

**Test Scenarios:**
- Errors handled gracefully
- User sees appropriate error messages
- Recovery mechanisms work
- No data loss on errors

### **Token Refresh Tests**

**Test Scenarios:**
- Token refresh before expiration
- Token refresh after expiration
- Refresh token expiration
- Network failure during refresh
- Invalid refresh token

### **Background Sync Tests**

**Test Scenarios:**
- Sync triggers correctly
- Sync completes successfully
- Sync handles errors
- Sync respects rate limits
- Sync works offline

---

## 📋 **MASTER PLAN INTEGRATION**

### **Master Plan Tracker Entry**

**Entry to Add:**
```markdown
| Social Media Integration | 2025-12-04 | 🟢 Active | HIGH (P2) | 6-8 weeks | [`plans/social_media_integration/SOCIAL_MEDIA_INTEGRATION_PLAN.md`](./plans/social_media_integration/SOCIAL_MEDIA_INTEGRATION_PLAN.md) |
```

### **Master Plan Integration Analysis**

**Dependencies:**
- **Phase 7.3 (Security):** Must complete before social media integration (agentId required)
- **Personality Learning System:** Must be complete (for insight integration)
- **Vibe Analysis Engine:** Must be complete (for insight integration)
- **Recommendation Engine:** Must be complete (for recommendation enhancement)

**Optimal Placement:**
- **After Phase 7.3:** Security architecture must be in place
- **After Personality Learning:** Must be able to process insights
- **Can run in parallel with:** Phase 8 (Model Deployment), Phase 9 (Reservations)

**Priority:**
- **P2 (HIGH VALUE):** Enhances core functionality but not blocking
- **Not P0:** Not critical path, can be done after core features

### **Conflicts with Existing Plans**

**No Conflicts Identified:**
- No overlapping features
- No conflicting requirements
- No competing priorities

### **Dependency Mapping**

**Depends On:**
- Phase 7.3: Security architecture (agentId system)
- Personality Learning System: Insight processing
- Vibe Analysis Engine: Vibe compilation
- Recommendation Engine: Recommendation enhancement

**Blocks:**
- None (feature is enhancement, not blocker)

**Can Run In Parallel With:**
- Phase 8: Model Deployment
- Phase 9: Reservations
- Other enhancement features

---

## 📚 **RELATED DOCUMENTATION**

### **Philosophy & Architecture**
- `docs/plans/philosophy_implementation/SPOTS_PHILOSOPHY_AND_ARCHITECTURE.md`
- `docs/plans/philosophy_implementation/DOORS.md`
- `OUR_GUTS.md`

### **Existing Systems**
- `lib/core/ai/personality_learning.dart`
- `lib/core/ai/vibe_analysis_engine.dart`
- `lib/core/models/user.dart`

### **Privacy & Security**
- `docs/security/SECURITY_ARCHITECTURE.md`
- `docs/compliance/GDPR_COMPLIANCE.md`
- `docs/compliance/CCPA_COMPLIANCE.md`

### **Related Plans**
- `docs/plans/personality_initialization/ARCHETYPE_TEMPLATE_SYSTEM_PLAN.md` (Option 2 - Initial templates)

### **Related Plans**
- `docs/plans/personality_initialization/ARCHETYPE_TEMPLATE_SYSTEM_PLAN.md` (Option 2 - Initial templates)

---

## 🎯 **NEXT STEPS**

1. **Review Updated Plan** - Review plan with all gaps fixed
2. **Review & Approval** - Get approval for implementation
3. **Add to Master Plan Tracker** - Add entry to `docs/MASTER_PLAN_TRACKER.md`
4. **Master Plan Integration** - Integrate into Master Plan execution sequence
5. **Begin Implementation** - Start Phase 1 when ready

---

## ✅ **GAP FIXES COMPLETE**

**All 15 gaps have been addressed:**

### **Critical Gaps - FIXED ✅**
1. ✅ **Database Schema & Migrations** - Complete schema with 3 tables, migrations, RLS policies, indexes
2. ✅ **agentId vs userId** - All data models updated to use `agentId` (security architecture compliant)
3. ✅ **Testing Strategy** - Comprehensive testing section with unit, integration, widget, E2E, and privacy tests
4. ✅ **Master Plan Integration** - Integration analysis complete, ready for Master Plan Tracker

### **High Priority Gaps - FIXED ✅**
5. ✅ **Error Handling & Edge Cases** - Detailed error handling section with all scenarios and recovery strategies
6. ✅ **OAuth Implementation Details** - Complete OAuth section with libraries, flows, configuration, security
7. ✅ **Background Sync Implementation** - Complete sync strategy with frequency, triggers, queue management, optimization
8. ✅ **Privacy Compliance Details** - Complete GDPR/CCPA compliance section with all requirements

### **Medium Priority Gaps - FIXED ✅**
9. ✅ **Analytics & Success Metrics** - Complete analytics section with metrics, implementation, success criteria
10. ✅ **User Onboarding Flow** - Complete onboarding section with triggers, UI/UX, messaging, progressive disclosure
11. ✅ **API Rate Limiting Details** - Complete rate limiting section with platform limits, handling, monitoring
12. ✅ **Token Refresh Flow** - Complete token refresh section with strategy, flow diagram, error handling

### **Low Priority Gaps - FIXED ✅**
13. ✅ **Data Migration for Existing Users** - Complete migration section with strategy, rollout, compatibility
14. ✅ **Backend Requirements** - Complete backend section with endpoints, edge functions, database changes
15. ✅ **Platform-Specific Requirements** - Complete platform section with API requirements, permissions, rate limits for all platforms

**All gaps addressed. Plan is ready for implementation.**

---

**Status:** ✅ **COMPREHENSIVE PLAN - ALL GAPS FIXED - READY FOR APPROVAL**  
**Last Updated:** December 11, 2025 (UI pages created - ready for backend integration)  
**Gap Analysis:** See `GAP_ANALYSIS.md` (all gaps now fixed in plan)  
**Three-Tier Strategy:** Option 1 (OAuth) + Option 3 (User-Provided Handles) + Option 2 (Archetype Templates - see related plan)

**⚠️ UI PAGES ALREADY CREATED (Pre-Phase 12):**
- Onboarding page: `lib/presentation/pages/onboarding/social_media_connection_page.dart` (integrated into onboarding flow)
- Settings page: `lib/presentation/pages/settings/social_media_settings_page.dart` (accessible from Profile → Settings)
- **Action Required:** Connect these pages to `SocialMediaConnectionService` when Phase 12 backend is implemented (see "Integration with Existing Systems" section for details)


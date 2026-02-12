# White-Label & VPN/Proxy Support - Implementation Plan

> **Historical:** This document may contain legacy domain references; current product uses avrai.app.

**Created:** December 2, 2025  
**Status:** 🎯 Ready for Implementation  
**Priority:** HIGH  
**Philosophy Alignment:** "Doors, not badges" - Opens doors to partnerships while preserving user control  
**Context:** Enable white-label SPOTS instances for industry partnerships with account/agent portability

---

## 🎯 Executive Summary

This plan enables:
1. **VPN/Proxy Support** - Users can route backend connections through VPN or proxy
2. **White-Label Architecture** - Partners can deploy branded SPOTS instances
3. **Account Portability** - Users can connect their personal SPOTS account to white-label instances
4. **Agent Portability** - AI personality agents work across white-label instances
5. **Federation** - Secure cross-instance authentication and data sync
6. **Location Inference** - Uses agent network to determine actual location when VPN/proxy masks IP geolocation
7. **VPN/Proxy Compatibility** - Fixes all features that break with VPN/proxy (rate limiting, fraud detection, external APIs, payments, analytics)

**Key Principles:**
1. Users own their account and agent. They can use it across any white-label instance while maintaining privacy and control.
2. **Agent portability is bidirectional** - users can start on white-label or personal account and move between them seamlessly.
3. **AgentId is persistent** - once created, the agentId remains the same regardless of instance or transfer.
4. **All features work seamlessly with VPN/proxy** - No functionality is broken or degraded when using VPN/proxy.
5. **Location determined by agent network** - If all nearby agents are in NYC, user is in NYC (even if VPN shows France).

---

## 🔑 Core Requirements

### **1. Account Portability**
- ✅ User can authenticate with personal SPOTS account on white-label instance
- ✅ Session tokens work across instances (federation)
- ✅ User preferences and data sync across instances
- ✅ Personal agent/personality travels with account

### **2. Agent Portability (Bidirectional)**
- ✅ AI personality agent (agentId) is tied to user account
- ✅ Agent compatibility and learning history preserved
- ✅ Agent can learn from interactions on white-label instance
- ✅ Agent data syncs back to personal account
- ✅ **Agent can be transferred from white-label to personal account**
- ✅ **User who starts on white-label can claim agentId when creating personal account**
- ✅ **AgentId remains consistent regardless of instance origin**

### **3. VPN/Proxy Support**
- ✅ Configurable HTTP proxy for backend connections
- ✅ SOCKS5 proxy support
- ✅ VPN-friendly (works when user has VPN enabled)
- ✅ White-label instances can require proxy/VPN
- ✅ Proxy configuration per instance

### **4. Location Inference via Agent Network** (NEW)
- ✅ **Detect VPN/Proxy usage** - Identify when IP geolocation is unreliable
- ✅ **Use agent proximity for location** - Infer location from connected agents
- ✅ **Consensus-based locality** - Determine location from majority of connected agents
- ✅ **Bluetooth/WiFi proximity accuracy** - Physical proximity is location-accurate regardless of VPN
- ✅ **Location from agent network** - If all nearby agents are in NYC, user is in NYC (even if VPN shows France)

---

## 🏗️ Architecture Overview

### **Multi-Tenant Federation Architecture**

```
┌─────────────────────────────────────────────────────────┐
│                 SPOTS Main Instance                      │
│  (api.avrai.app - User's personal account)              │
└─────────────────────────────────────────────────────────┘
                         ↕ Federation Protocol
┌─────────────────────────────────────────────────────────┐
│            White-Label Instance A                        │
│  (branded.avrai.app - Partner branded)                  │
│  → Routes through VPN/Proxy if configured               │
└─────────────────────────────────────────────────────────┘
                         ↕ Federation Protocol
┌─────────────────────────────────────────────────────────┐
│            White-Label Instance B                        │
│  (another-partner.avrai.app)                            │
└─────────────────────────────────────────────────────────┘
```

### **User Account & Agent Flow**

#### **Flow 1: Personal Account → White-Label Instance**

```
User's Personal Account (Main Instance)
├─ userId: "user_123"
├─ email: "user@example.com"
├─ agentId: "agent_abc" (tied to user account)
├─ PersonalityProfile (travels with account)
└─ Preferences & Data

     ↓ User connects to White-Label Instance ↓

White-Label Instance Authentication
├─ User enters: email + password
├─ White-Label Instance → Federation API → Main Instance
├─ Main Instance validates credentials
├─ Returns federation token (signed JWT)
├─ White-Label Instance creates local session
└─ User's agentId and personality profile synced
```

#### **Flow 2: White-Label Instance → Personal Account** (NEW)

```
User Starts on White-Label Instance
├─ Creates account on white-label instance
├─ agentId: "agent_xyz" (created on white-label)
├─ PersonalityProfile (learning on white-label)
└─ Preferences & Data

     ↓ User creates Personal Account ↓

Personal Account Creation/Migration
├─ User creates account on main instance (not on VPN)
├─ User claims existing agentId from white-label instance
├─ Migration Service transfers agentId ownership
├─ Agent profile and learning history migrated
└─ Agent continues with same agentId on personal account

     ↓ User can now use agent on either instance ↓

Agent Continuity
├─ Same agentId works on both instances
├─ Learning syncs between instances
├─ User can switch instances seamlessly
└─ Agent evolution continues across all instances
```

**Key Point:** AgentId is **portable in both directions** - user can start anywhere and move to anywhere while keeping the same agent.

---

## 📋 Implementation Plan

### **Phase 1: VPN/Proxy Support & Critical Fixes** (Week 1-2)

**Goal:** Add proxy/VPN configuration to network layer AND fix features that break with VPN/proxy

**Reference:** See `VPN_PROXY_FEATURE_IMPACT_ANALYSIS.md` for complete impact analysis

#### **1.1 Network Configuration Service**

Create: `lib/core/services/network_config_service.dart`

```dart
class NetworkConfigService {
  // Proxy configuration
  ProxyConfig? proxyConfig;
  
  // VPN detection
  bool isVpnEnabled();
  
  // Proxy configuration
  Future<void> configureProxy(ProxyConfig config);
  Future<void> clearProxy();
  
  // HTTP client factory
  http.Client createHttpClient({ProxyConfig? proxy});
}
```

#### **1.2 Proxy Configuration Model**

Create: `lib/core/models/proxy_config.dart`

```dart
class ProxyConfig {
  final ProxyType type; // http, socks5
  final String host;
  final int port;
  final String? username;
  final String? password;
  final bool enabled;
  
  // White-label instance requirement
  final bool required;
  
  // Proxy test
  Future<bool> testConnection();
}
```

#### **1.3 Enhanced API Client**

Update: `packages/spots_network/lib/clients/api_client.dart`

Add proxy support:
- Accept `ProxyConfig` in constructor
- Create HTTP client with proxy configuration
- Support SOCKS5 and HTTP proxies
- Handle proxy authentication

#### **1.4 White-Label Configuration**

Create: `lib/core/models/white_label_config.dart`

```dart
class WhiteLabelConfig {
  final String instanceId;
  final String instanceName;
  final String baseUrl;
  final String? branding;
  
  // Network requirements
  final bool requiresProxy;
  final ProxyConfig? defaultProxy;
  final bool requiresVpn;
  
  // Federation settings
  final String federationEndpoint;
  final bool allowAccountPortability;
}
```

---

### **Phase 2: Federation Authentication** (Week 2-3)

**Goal:** Enable account portability across instances

#### **2.1 Federation Service**

Create: `lib/core/services/federation_service.dart`

```dart
class FederationService {
  // Authenticate with main instance credentials
  Future<FederationToken> authenticateWithMainInstance({
    required String email,
    required String password,
    required String whiteLabelInstanceId,
  });
  
  // Validate federation token
  Future<User> validateFederationToken(String token);
  
  // Sync user data from main instance
  Future<UserData> syncUserData(String federationToken);
  
  // Sync agent/personality profile
  Future<PersonalityProfile> syncAgentProfile(String userId);
}
```

#### **2.2 Federation Token Model**

Create: `lib/core/models/federation_token.dart`

```dart
class FederationToken {
  final String token; // JWT signed by main instance
  final String userId;
  final String agentId;
  final String whiteLabelInstanceId;
  final DateTime expiresAt;
  final List<String> permissions;
  
  // Token validation
  bool isValid();
  bool isExpired();
}
```

#### **2.3 Backend Federation API**

Create federation endpoints on main instance:

```
POST /api/federation/authenticate
  → Validates user credentials
  → Returns federation token

GET /api/federation/user/{userId}
  → Returns user data (with federation token)

GET /api/federation/agent/{agentId}
  → Returns personality profile (with federation token)
```

---

### **Phase 3: Account Portability UI** (Week 3-4)

**Goal:** Users can connect their personal account to white-label instances AND transfer from white-label to personal

#### **3.1 Account Connection Screen**

Create: `lib/presentation/pages/auth/connect_personal_account_page.dart`

Features:
- Input for email/password (main instance credentials)
- Option to use VPN/proxy
- Display white-label instance branding
- Show what data will sync
- Connect button → federation authentication

#### **3.2 Agent Transfer Screen** (NEW)

Create: `lib/presentation/pages/auth/transfer_agent_from_whitelabel_page.dart`

Features:
- Input for white-label instance credentials
- List available agents on white-label instance
- Select agentId to transfer
- Verification code input (sent to white-label email)
- Transfer button → agent transfer process
- Show transfer progress and confirmation

#### **3.3 Account Management**

Create: `lib/presentation/pages/settings/account_portability_page.dart`

Features:
- List connected white-label instances
- List agents and their origin instances
- Transfer agent from white-label to personal
- Disconnect from instance
- View sync status
- Manage proxy/VPN settings per instance

---

### **Phase 4: Agent Portability** (Week 4-5)

**Goal:** AI personality agent travels with user account

#### **4.1 Agent Sync Service**

Create: `lib/core/services/agent_sync_service.dart`

```dart
class AgentSyncService {
  // Sync agent to white-label instance
  Future<void> syncAgentToInstance({
    required String agentId,
    required String instanceId,
    required FederationToken token,
  });
  
  // Sync agent learning from instance
  Future<void> syncAgentLearningFromInstance({
    required String agentId,
    required String instanceId,
  });
  
  // Get agent from main instance
  Future<PersonalityProfile> getAgentFromMainInstance(String agentId);
}
```

#### **4.2 Agent Sync on Login**

When user authenticates on white-label instance:
1. Fetch agent profile from main instance (via federation)
2. Store locally on white-label instance
3. Agent participates in AI2AI learning on instance
4. Sync learning back to main instance periodically

#### **4.3 Learning Sync**

Create: `lib/core/services/agent_learning_sync_service.dart`

- Periodically sync agent learning from white-label instances
- Merge learning history intelligently
- Preserve personality evolution timeline

#### **4.4 Agent Transfer from White-Label to Personal Account** (NEW)

**Goal:** Enable users who start on white-label to transfer their agent to personal account

Create: `lib/core/services/agent_transfer_service.dart`

```dart
class AgentTransferService {
  // Transfer agent ownership from white-label to personal account
  Future<TransferResult> transferAgentToPersonalAccount({
    required String whiteLabelAgentId,
    required String whiteLabelInstanceId,
    required String personalAccountEmail,
    required String personalAccountPassword,
  });
  
  // Claim existing agentId when creating personal account
  Future<ClaimResult> claimAgentId({
    required String agentId,
    required String sourceInstanceId,
    required String newPersonalAccountEmail,
    required String verificationCode, // Sent to white-label account
  });
  
  // Verify agent ownership before transfer
  Future<bool> verifyAgentOwnership({
    required String agentId,
    required String instanceId,
    required String userEmail,
  });
}
```

**Transfer Process:**

1. **User initiates transfer:**
   - User creates personal account on main instance (not on VPN)
   - User provides white-label instance credentials/verification
   - User selects agentId to transfer

2. **Verification:**
   - System verifies user owns agentId on white-label instance
   - Sends verification code to white-label account email
   - User confirms transfer

3. **Transfer execution:**
   - Agent profile and learning history copied to personal account
   - AgentId ownership transferred to personal account
   - White-label instance updated with new ownership link
   - Agent continues with same agentId on personal account

4. **Continuity:**
   - Same agentId works on both instances
   - Learning syncs bidirectionally
   - User can use agent on either instance

**Implementation Details:**

```dart
// Example transfer flow
class AgentTransferService {
  Future<TransferResult> transferAgentToPersonalAccount({
    required String whiteLabelAgentId,
    required String whiteLabelInstanceId,
    required String personalAccountEmail,
    required String personalAccountPassword,
  }) async {
    // 1. Authenticate with white-label instance
    final whiteLabelAuth = await _authenticateWithWhiteLabel(
      instanceId: whiteLabelInstanceId,
      email: personalAccountEmail, // Same email used on white-label
    );
    
    // 2. Verify agent ownership
    final ownsAgent = await verifyAgentOwnership(
      agentId: whiteLabelAgentId,
      instanceId: whiteLabelInstanceId,
      userEmail: personalAccountEmail,
    );
    
    if (!ownsAgent) {
      return TransferResult.error('Agent ownership verification failed');
    }
    
    // 3. Create/authenticate personal account
    final personalAuth = await _createOrAuthenticatePersonalAccount(
      email: personalAccountEmail,
      password: personalAccountPassword,
    );
    
    // 4. Get agent profile from white-label instance
    final agentProfile = await _getAgentFromWhiteLabel(
      agentId: whiteLabelAgentId,
      instanceId: whiteLabelInstanceId,
      token: whiteLabelAuth.token,
    );
    
    // 5. Transfer agentId to personal account
    final transferResult = await _transferAgentIdOwnership(
      agentId: whiteLabelAgentId,
      fromInstance: whiteLabelInstanceId,
      toUserId: personalAuth.userId,
      agentProfile: agentProfile,
    );
    
    // 6. Link instances for bidirectional sync
    await _linkInstancesForSync(
      agentId: whiteLabelAgentId,
      whiteLabelInstanceId: whiteLabelInstanceId,
      personalAccountUserId: personalAuth.userId,
    );
    
    return TransferResult.success(
      agentId: whiteLabelAgentId,
      personalAccountUserId: personalAuth.userId,
    );
  }
}
```

**AgentId Consistency:**

- AgentId is **generated once** and **never changes**
- AgentId can be **claimed/transferred** but remains the same
- Ownership can change, but agentId identity persists
- Learning history and personality evolution are preserved

---

### **Phase 5: Location Inference via Agent Network** (Week 5-6)

**Goal:** Use agent connections to infer actual location when VPN/proxy masks IP geolocation

#### **5.1 Location Inference Service**

Create: `lib/core/services/location_inference_service.dart`

```dart
class LocationInferenceService {
  final NetworkConfigService _networkConfig;
  final DeviceDiscoveryService _deviceDiscovery;
  final ConnectionOrchestrator _orchestrator;
  
  // Infer location from connected agents
  Future<InferredLocation?> inferLocationFromAgentNetwork({
    required String userId,
    required String agentId,
  }) async {
    // 1. Check if VPN/proxy is enabled
    final isVpnEnabled = await _networkConfig.isVpnEnabled();
    final proxyConfig = await _networkConfig.getProxyConfig();
    final isUsingProxy = proxyConfig != null && proxyConfig.enabled;
    
    if (!isVpnEnabled && !isUsingProxy) {
      // No VPN/proxy - use standard IP geolocation
      return null; // Use default location service
    }
    
    // 2. Get connected agents via proximity (Bluetooth/WiFi)
    final connectedAgents = await _getConnectedAgentsViaProximity(agentId);
    
    if (connectedAgents.isEmpty) {
      // No agents nearby - cannot infer location
      return null;
    }
    
    // 3. Extract locations from connected agents
    final agentLocations = <String, int>{}; // location -> count
    for (final agent in connectedAgents) {
      final location = agent.obfuscatedLocation?.city;
      if (location != null) {
        agentLocations[location] = (agentLocations[location] ?? 0) + 1;
      }
    }
    
    // 4. Determine location by consensus
    final inferredLocation = _determineLocationByConsensus(agentLocations);
    
    return inferredLocation;
  }
  
  // Get agents connected via physical proximity
  Future<List<AgentLocationData>> _getConnectedAgentsViaProximity(String agentId) async {
    // Use device discovery to find nearby agents
    final devices = _deviceDiscovery.getDiscoveredDevices();
    final agents = <AgentLocationData>[];
    
    for (final device in devices) {
      if (!device.isSpotsEnabled) continue;
      
      // Extract location from agent's obfuscated location
      final personalityData = await _deviceDiscovery.extractPersonalityData(device);
      if (personalityData?.location != null) {
        agents.add(AgentLocationData(
          agentId: device.deviceId,
          city: personalityData!.location!.city,
          proximityScore: device.proximityScore,
        ));
      }
    }
    
    // Filter by proximity (only nearby agents count)
    return agents.where((a) => a.proximityScore > 0.5).toList();
  }
  
  // Determine location by majority consensus
  InferredLocation? _determineLocationByConsensus(Map<String, int> agentLocations) {
    if (agentLocations.isEmpty) return null;
    
    // Sort by count (most common location)
    final sorted = agentLocations.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    final topLocation = sorted.first;
    final totalAgents = agentLocations.values.reduce((a, b) => a + b);
    final confidence = topLocation.value / totalAgents;
    
    // Require at least 60% consensus for high confidence
    if (confidence >= 0.6) {
      return InferredLocation(
        city: topLocation.key,
        confidence: confidence,
        agentCount: topLocation.value,
        totalAgents: totalAgents,
        source: LocationSource.agentNetwork,
      );
    }
    
    return null;
  }
}

class InferredLocation {
  final String city;
  final double confidence; // 0.0-1.0
  final int agentCount;
  final int totalAgents;
  final LocationSource source;
  
  InferredLocation({
    required this.city,
    required this.confidence,
    required this.agentCount,
    required this.totalAgents,
    required this.source,
  });
}

enum LocationSource {
  ipGeolocation, // Standard IP-based location
  agentNetwork,  // Inferred from connected agents
  gps,           // GPS coordinates
}

class AgentLocationData {
  final String agentId;
  final String city;
  final double proximityScore; // 0.0-1.0
}
```

#### **5.2 Integration with Location Services**

Update: `lib/core/services/` location services

- Check for VPN/proxy before using IP geolocation
- Fall back to agent network inference when VPN/proxy detected
- Combine multiple location sources for accuracy

#### **5.3 Location Priority System**

Location determination priority:

1. **GPS/Device Location** (if available and accurate)
2. **Agent Network Inference** (if VPN/proxy detected)
3. **IP Geolocation** (if no VPN/proxy)

**Logic:**
```
if (hasGpsLocation && gpsAccuracy < 100m) {
  return gpsLocation;
} else if (isVpnEnabled || isUsingProxy) {
  return inferFromAgentNetwork();
} else {
  return ipGeolocation();
}
```

---

### **Phase 6: VPN/Proxy Compatibility Fixes** (Week 6-7)

**Goal:** Fix all features that break or are affected by VPN/proxy usage

**Reference:** See `VPN_PROXY_FEATURE_IMPACT_ANALYSIS.md` for complete impact analysis

#### **6.1 User-Based Rate Limiting**

**Problem:** IP-based rate limiting blocks VPN users who share IP addresses

Create: `lib/core/services/user_based_rate_limiter.dart`

```dart
class UserBasedRateLimiter {
  // Rate limit by userId, not IP address
  Future<bool> checkRateLimit({
    required String userId,
    required String endpoint,
  }) async {
    final userLimit = await _getUserRateLimit(userId, endpoint);
    return userLimit.canMakeRequest();
  }
  
  // VPN/proxy users get same limits as regular users
  // Limits are per-user, not per-IP
}
```

Update: All rate limiting services to use user-based instead of IP-based

- Update `packages/spots_network/lib/clients/api_client.dart`
- Update MCP rate limiting (if implemented)
- Update backend rate limiting middleware

#### **6.2 Fraud Detection Adjustments**

**Problem:** IP-based fraud signals incorrectly flag VPN users

Update: `lib/core/services/fraud_detection_service.dart`

```dart
class FraudDetectionService {
  Future<FraudScore> analyzeEvent(String eventId) async {
    final signals = <FraudSignal>[];
    
    // Check for VPN/proxy usage
    final isVpnEnabled = await _networkConfig.isVpnEnabled();
    final isUsingProxy = await _networkConfig.isProxyEnabled();
    
    // Only check IP location-based fraud if NOT on VPN/proxy
    if (!isVpnEnabled && !isUsingProxy) {
      if (await _hasInvalidLocation(event)) {
        signals.add(FraudSignal.invalidLocation);
      }
    } else {
      // Use agent network location or skip location checks
      final inferredLocation = await _locationInference.inferLocationFromAgentNetwork(
        userId: event.hostId,
        agentId: await _getAgentId(event.hostId),
      );
      
      if (inferredLocation == null) {
        // Cannot verify location - skip location-based fraud check
        // Focus on behavior-based signals instead
      }
    }
    
    // Always check behavior-based fraud signals:
    // - Rapid event creation
    // - Stock photos
    // - Duplicate events
    // - Account age/verification
  }
}
```

#### **6.3 External APIs - Explicit Location Parameters**

**Problem:** External APIs may block VPN IPs or return wrong regional data

Update: `lib/data/datasources/remote/google_places_datasource_new_impl.dart`

- Always pass explicit location parameters (from agent network or GPS)
- Never rely on IP geolocation
- Handle API errors gracefully with fallbacks

Update: `lib/data/datasources/remote/openstreetmap_datasource_impl.dart`

- Pass explicit location parameters
- Use agent network location when available

Update: `lib/core/services/google_place_id_finder_service_new.dart`

- Use explicit location for place ID lookup
- Fall back to agent network location if GPS unavailable

**Implementation:**
```dart
class GooglePlacesDataSource {
  Future<List<Spot>> searchPlaces({
    required String query,
    double? latitude,  // Explicit location from agent network/GPS
    double? longitude, // Not from IP geolocation
    int radius = 5000,
  }) async {
    // Always require explicit location parameters
    // Never rely on IP geolocation
    
    if (latitude == null || longitude == null) {
      // Try to get location from agent network or GPS
      final location = await _locationInference.getCurrentLocation();
      latitude = location.latitude;
      longitude = location.longitude;
    }
    
    return await _placesApi.searchNearby(
      query: query,
      location: LatLng(latitude, longitude), // Explicit coordinates
      radius: radius,
    );
  }
}
```

#### **6.4 Payment Processing - Explicit Billing Information**

**Problem:** Stripe may flag VPN IPs or have regional restrictions

Update: `lib/core/services/payment_service.dart`

- Use explicit billing address (not IP geolocation)
- Provide billing country/region explicitly
- Handle Stripe Radar VPN detection gracefully

**Implementation:**
```dart
class PaymentService {
  Future<PaymentResult> processPayment({
    required String userId,
    required double amount,
    required String currency,
    BillingAddress? billingAddress, // Explicit billing address
  }) async {
    // Use explicit billing address for regional restrictions
    // Not IP geolocation
    
    // Get user's billing information (stored in account)
    final billing = billingAddress ?? await _getUserBillingAddress(userId);
    
    // Stripe Radar handles VPN detection automatically
    // Provide explicit billing information for accuracy
    final paymentIntent = await _stripeService.createPaymentIntent(
      amount: amount,
      currency: currency,
      billingAddress: billing, // Explicit address
    );
  }
}
```

#### **6.5 Analytics - Explicit Location Tracking**

**Problem:** IP-based location tracking inaccurate with VPN/proxy

Update: Analytics tracking to use explicit location

- Use agent network location for analytics
- Track by userId, not IP address
- Include location source in analytics events

**Implementation:**
```dart
class AnalyticsService {
  Future<void> trackEvent(String eventName, Map<String, dynamic> properties) async {
    // Get explicit location (not IP-based)
    final location = await _locationInference.getCurrentLocation();
    
    // Add location to analytics with source
    properties['location_city'] = location.city;
    properties['location_source'] = location.source.name;
    properties['user_id'] = userId; // Track by userId, not IP
    
    await _analytics.logEvent(eventName, properties);
  }
}
```

#### **6.6 Real-Time Sync - Adaptive Frequency**

**Problem:** VPN/proxy adds latency to real-time sync

Update: `packages/spots_network/lib/backends/supabase/supabase_realtime_backend.dart`

- Detect connection quality
- Adjust sync frequency based on latency
- Warn users if connection is slow

**Implementation:**
```dart
class RealtimeService {
  Future<void> syncWithAdaptiveFrequency() async {
    final connectionQuality = await _measureConnectionQuality();
    
    if (connectionQuality.isSlow || connectionQuality.hasHighLatency) {
      // Reduce sync frequency for VPN/proxy users
      await _syncLessFrequently(duration: Duration(seconds: 30));
    } else {
      // Normal sync frequency
      await _syncNormally(duration: Duration(seconds: 5));
    }
  }
  
  Future<ConnectionQuality> _measureConnectionQuality() async {
    final start = DateTime.now();
    try {
      await _testConnection();
      final latency = DateTime.now().difference(start);
      return ConnectionQuality(
        isSlow: latency.inMilliseconds > 500,
        hasHighLatency: latency.inMilliseconds > 1000,
        latency: latency,
      );
    } catch (e) {
      return ConnectionQuality(
        isSlow: true,
        hasHighLatency: true,
        latency: Duration(seconds: 5), // Assume slow
      );
    }
  }
}
```

#### **6.7 Geographic Scope Services**

**Problem:** Geographic scope may be incorrect with VPN

Update: `lib/core/services/geographic_scope_service.dart`

- Use agent network location (already covered in Phase 5)
- Allow manual locality selection as fallback
- Use GPS coordinates when available

**Implementation:**
```dart
class GeographicScopeService {
  Future<GeographicScope> getGeographicScope(String userId) async {
    // Get location from agent network inference
    final location = await _locationInference.getCurrentLocation();
    
    if (location != null) {
      return GeographicScope.fromLocation(location.city);
    }
    
    // Fallback: Allow manual selection
    return await _getUserSelectedLocality(userId);
  }
}
```

---

### **Phase 7: White-Label Configuration** (Week 7-8)

**Goal:** Enable partners to deploy white-label instances

#### **5.1 White-Label Instance Setup**

Configuration file: `white_label_config.json`

```json
{
  "instanceId": "partner_brand",
  "instanceName": "Partner Brand SPOTS",
"baseUrl": "https://partner.avrai.app",
    "federationEndpoint": "https://api.avrai.app/api/federation",
  "branding": {
    "logo": "https://partner.avrai.app/logo.png",
    "colors": { ... },
    "appName": "Partner Brand"
  },
  "network": {
    "requiresProxy": false,
    "requiresVpn": false,
    "defaultProxy": null
  },
  "features": {
    "allowAccountPortability": true,
    "allowAgentPortability": true
  }
}
```

#### **5.2 Instance Registration**

White-label instances register with main instance:
- Partner credentials
- Instance configuration
- Federation keys for token signing

---

## 🔧 Technical Implementation

### **Proxy Configuration for HTTP Client**

**Dart HTTP Package Support:**

Dart's `http` package doesn't natively support proxies. Options:

1. **Use `http_proxy` package** (recommended)
   ```yaml
   dependencies:
     http_proxy: ^1.0.0
   ```

2. **Custom HTTP client with proxy** (more control)
   - Use `io.HttpClient` with proxy configuration
   - Wrap in adapter for `http.Client` interface

**Implementation:**

```dart
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart' as http_io;

http.Client createHttpClientWithProxy(ProxyConfig? proxy) {
  if (proxy == null || !proxy.enabled) {
    return http.Client();
  }
  
  final httpClient = HttpClient();
  
  if (proxy.type == ProxyType.http || proxy.type == ProxyType.https) {
    httpClient.findProxy = (uri) {
      return 'PROXY ${proxy.host}:${proxy.port}';
    };
    
    if (proxy.username != null && proxy.password != null) {
      httpClient.authenticate = (url, scheme, realm) {
        if (url.host == proxy.host) {
          httpClient.addCredentials(
            url,
            realm,
            HttpClientBasicCredentials(
              proxy.username!,
              proxy.password!,
            ),
          );
          return true;
        }
        return false;
      };
    }
  }
  
  return http_io.IOClient(httpClient);
}
```

### **SOCKS5 Proxy Support**

For SOCKS5, use `socks_proxy` package:

```dart
import 'package:socks_proxy/socks_proxy.dart';

http.Client createSocks5Client(ProxyConfig proxy) {
  // SOCKS5 proxy implementation
  // Requires additional package or custom implementation
}
```

---

## 🔐 Security Considerations

### **Federation Token Security**

1. **JWT Signing**
   - Main instance signs federation tokens
   - White-label instances validate signature
   - Tokens expire (e.g., 24 hours)

2. **Token Scope**
   - Limited permissions per token
   - Can only access user's own data
   - Cannot modify account settings

3. **Rate Limiting**
   - Limit federation authentication attempts
   - Limit data sync requests

### **Proxy Security**

1. **Proxy Authentication**
   - Support username/password
   - Encrypted storage of credentials

2. **Proxy Verification**
   - Test proxy connection before use
   - Monitor proxy health

---

## 📱 User Experience

### **Connecting to White-Label Instance**

1. User opens white-label branded app
2. Sees "Connect Your SPOTS Account" option
3. Enters email/password (main instance credentials)
4. Optionally configures proxy/VPN
5. Account and agent sync automatically
6. User can use white-label instance with their personal data

### **Proxy Configuration**

1. Settings → Network → Proxy Configuration
2. User can configure:
   - HTTP/HTTPS proxy
   - SOCKS5 proxy
   - Authentication credentials
3. Test connection
4. Enable/disable per instance

### **Location Inference (Automatic)**

**Scenario:** User on VPN showing France, but connected to agents in NYC

1. User has VPN enabled (shows location: France)
2. SPOTS detects VPN/proxy usage
3. System checks nearby agents via Bluetooth/WiFi proximity
4. Finds 5 agents all in NYC (via proximity discovery)
5. System infers: User is actually in NYC (not France)
6. Location is set to NYC based on agent network
7. Recommendations and discovery use NYC location

**User sees:**
- "Location detected from nearby SPOTS users: NYC"
- Recommendations for NYC spots (not France)
- Connects with NYC community

**Benefits:**
- ✅ Accurate location despite VPN
- ✅ No user action required (automatic)
- ✅ Works with existing proximity detection
- ✅ Privacy-preserving (no exact coordinates)

---

## 🚀 Deployment Strategy

### **Main Instance (api.avrai.app)**

1. Deploy federation API endpoints
2. Token signing service
3. User data sync API
4. Agent profile sync API

### **White-Label Instance**

1. Configure `white_label_config.json`
2. Register with main instance
3. Deploy with federation support
4. Optional: Require proxy/VPN

---

## ✅ Success Criteria

### **Core Features:**
- [ ] Users can authenticate with personal account on white-label instance
- [ ] Agent/personality profile syncs across instances
- [ ] Proxy/VPN configuration works for backend connections
- [ ] White-label instances can require proxy/VPN
- [ ] Federation tokens are secure and validated
- [ ] Learning sync preserves agent evolution
- [ ] User can disconnect from white-label instances

### **Agent Portability:**
- [ ] **Users can transfer agentId from white-label to personal account**
- [ ] **Users who start on white-label can claim same agentId on personal account**
- [ ] **AgentId remains consistent regardless of transfer direction**
- [ ] **Agent learning and personality evolution preserved during transfer**

### **Location Inference:**
- [ ] **Location inference from agent network when VPN/proxy detected**
- [ ] **User location determined by connected agents, not IP geolocation when on VPN**
- [ ] **Consensus-based location (if all nearby agents in NYC, user is in NYC)**
- [ ] **Location inference works with existing proximity detection (Bluetooth/WiFi)**

### **VPN/Proxy Compatibility Fixes:**
- [ ] **Rate limiting is user-based (not IP-based) - VPN users not blocked**
- [ ] **Fraud detection skips IP-based signals when VPN/proxy detected**
- [ ] **External APIs (Google Places, OpenWeatherMap) use explicit location parameters**
- [ ] **Payment processing uses explicit billing address (not IP geolocation)**
- [ ] **Analytics use explicit location from agent network (not IP-based)**
- [ ] **Real-time sync adjusts frequency based on connection quality**
- [ ] **Geographic scope services use agent network location**
- [ ] **All location-based features work correctly with VPN/proxy**

---

## 📚 Related Documentation

- **VPN/Proxy Impact Analysis:** `docs/plans/white_label/VPN_PROXY_FEATURE_IMPACT_ANALYSIS.md` - Complete analysis of all features affected by VPN/proxy
- Network Architecture: `docs/plans/architecture/`
- Authentication: `packages/spots_network/lib/interfaces/auth_backend.dart`
- AI2AI Protocol: `lib/core/network/ai2ai_protocol.dart`
- Personality Profile: `lib/core/models/personality_profile.dart`

---

## 🎯 Next Steps

1. **Start with Phase 1:** Add proxy support to HTTP client
2. **Test with VPN:** Verify VPN compatibility
3. **Implement Federation:** Build authentication and sync
4. **UI for Portability:** Make it easy for users
5. **White-Label Setup:** Enable partner deployments

This plan enables SPOTS to support industry partnerships while preserving user control and account portability. Users own their data and agent, and can use them across any white-label instance.

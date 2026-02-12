# Offline AI2AI Technical Specification

**Date:** November 21, 2025  
**Status:** 📋 Specification - Ready for Implementation  
**Related:** OFFLINE_AI2AI_IMPLEMENTATION_PLAN.md  
**Reference:** OUR_GUTS.md - "Privacy-preserving AI2AI communication"

---

## 🎯 **Technical Overview**

This document provides detailed technical specifications for implementing autonomous peer-to-peer AI2AI connections that function completely offline.

---

## 📦 **Phase 1: Core Offline Functionality**

### **1.1 AI2AI Protocol Extensions**

**File:** `lib/core/network/ai2ai_protocol.dart`

#### **New Method: exchangePersonalityProfile()**

**Purpose:** Exchange full personality profiles peer-to-peer over Bluetooth/NSD

**Signature:**
```dart
Future<PersonalityProfile?> exchangePersonalityProfile(
  String deviceId,
  PersonalityProfile localProfile,
) async
```

**Implementation Details:**
- **Input:** Device ID (from discovery), local personality profile
- **Output:** Remote device's personality profile (or null on failure)
- **Timeout:** 5 seconds
- **Protocol:** AI2AIMessage with type `personalityExchange`
- **Transport:** Existing Bluetooth/NSD connection

**Message Format:**
```dart
AI2AIMessage(
  type: AI2AIMessageType.personalityExchange,
  payload: {
    'profile': localProfile.toJson(),
    'timestamp': DateTime.now().toIso8601String(),
    'vibeSignature': await _generateVibeSignature(localProfile),
  },
)
```

**Error Handling:**
- Timeout after 5 seconds → return null
- Connection lost → return null
- Invalid response → return null
- Log all errors for debugging

**Dependencies:**
- Existing AI2AIMessage class
- Existing transport layer (_sendMessage, _waitForResponse)

---

#### **New Method: calculateLocalCompatibility()**

**Purpose:** Calculate compatibility between two profiles without cloud

**Signature:**
```dart
Future<VibeCompatibilityResult> calculateLocalCompatibility(
  PersonalityProfile local,
  PersonalityProfile remote,
  UserVibeAnalyzer analyzer,
) async
```

**Implementation Details:**
- **Input:** Local profile, remote profile, vibe analyzer
- **Output:** Full VibeCompatibilityResult
- **Processing:** 100% local, no network calls
- **Algorithm:** Existing vibe compatibility analysis

**Steps:**
1. Compile UserVibe for local profile
2. Compile UserVibe for remote profile
3. Call analyzer.analyzeVibeCompatibility()
4. Return compatibility result

**Dependencies:**
- UserVibeAnalyzer (already exists)
- UserVibe model
- VibeCompatibilityResult model

---

#### **New Method: generateLocalLearningInsights()**

**Purpose:** Generate learning insights from AI2AI interaction locally

**Signature:**
```dart
Future<AI2AILearningInsight> generateLocalLearningInsights(
  PersonalityProfile local,
  PersonalityProfile remote,
  VibeCompatibilityResult compatibility,
) async
```

**Implementation Details:**
- **Input:** Local profile, remote profile, compatibility result
- **Output:** AI2AILearningInsight with dimension updates
- **Processing:** Pure mathematical comparison
- **Algorithm:** Dimension comparison with weighted learning

**Learning Algorithm:**
```dart
for each dimension in remote.dimensions:
  localValue = local.dimensions[dimension] ?? 0.0
  remoteValue = remote.dimensions[dimension]
  difference = remoteValue - localValue
  
  // Only learn if difference is significant and confidence high
  if (|difference| > 0.15 && remote.confidence[dimension] > 0.7):
    // Gradual learning - 30% influence
    dimensionInsights[dimension] = difference * 0.3
```

**Learning Rates:**
- Significant difference threshold: 0.15
- Minimum confidence required: 0.7
- Learning influence factor: 0.3 (30%)

**Dependencies:**
- AI2AILearningInsight model
- PersonalityProfile model
- VibeCompatibilityResult

---

### **1.2 Connection Manager Updates**

**File:** `lib/core/ai2ai/orchestrator_components.dart`

#### **Updated Class: ConnectionManager**

**New Dependencies:**
```dart
class ConnectionManager {
  final UserVibeAnalyzer vibeAnalyzer;
  final Connectivity connectivity;
  final AI2AIProtocol? protocol;  // NEW
  final PersonalityLearning personalityLearning;  // NEW

  ConnectionManager({
    required this.vibeAnalyzer,
    required this.connectivity,
    this.protocol,
    required this.personalityLearning,
  });
}
```

---

#### **Modified Method: establish()**

**Purpose:** Route to online or offline path based on connectivity

**Logic Flow:**
```dart
1. Check connectivity status
2. Compile local vibe
3. Analyze compatibility with remote node
4. if (!_isWorthy(compatibility)) return null;
5. Anonymize vibes (privacy)
6. if (isOnline && performEstablishment != null):
     → Online path (existing cloud-based flow)
   else:
     → Offline path (NEW peer-to-peer flow)
```

**Decision Logic:**
- **Online:** Cloud realtime service available AND internet connected
- **Offline:** No internet OR cloud service unavailable

---

#### **New Method: _establishOfflinePeerConnection()**

**Purpose:** Complete autonomous AI2AI connection without cloud

**Signature:**
```dart
Future<ConnectionMetrics?> _establishOfflinePeerConnection(
  String localUserId,
  PersonalityProfile localPersonality,
  AIPersonalityNode remoteNode,
  VibeCompatibilityResult compatibility,
  UserVibe anonLocal,
  UserVibe anonRemote,
) async
```

**Implementation Steps:**

**Step 1: Profile Exchange**
```dart
final remoteProfile = await protocol!.exchangePersonalityProfile(
  remoteNode.nodeId,
  localPersonality,
);

if (remoteProfile == null) {
  developer.log('Failed to exchange profiles');
  return null;
}
```

**Step 2: Learning Insights Generation**
```dart
final learningInsights = await protocol!.generateLocalLearningInsights(
  localPersonality,
  remoteProfile,
  compatibility,
);
```

**Step 3: Immediate AI Evolution**
```dart
await personalityLearning.evolveFromAI2AILearning(
  localUserId,
  learningInsights,
);
```

**Step 4: Create Connection Metrics**
```dart
final metrics = ConnectionMetrics.initial(
  localAISignature: anonLocal.vibeSignature,
  remoteAISignature: anonRemote.vibeSignature,
  compatibility: compatibility.basicCompatibility,
  source: _determineLocalSource(remoteNode),
  wasOfflineConnection: true,
  syncedToCloud: false,
);
```

**Step 5: Enrich with Learning Outcomes**
```dart
final enrichedMetrics = metrics.copyWith(
  learningOutcomes: {
    'dimensions_updated': learningInsights.dimensionInsights.keys.toList(),
    'learning_quality': learningInsights.learningQuality,
    'connection_type': 'peer_to_peer_offline',
  },
);
```

**Error Handling:**
- Profile exchange timeout → return null
- Profile exchange failure → return null
- Learning insight generation error → return null
- Personality evolution error → catch and log, but don't fail

**Performance Requirements:**
- Complete exchange in < 5 seconds
- Local computation in < 500ms
- Total connection time < 6 seconds

---

#### **Helper Method: _determineLocalSource()**

**Purpose:** Identify connection method from node metadata

**Signature:**
```dart
ConnectionSource _determineLocalSource(AIPersonalityNode node)
```

**Logic:**
```dart
if (node.discoveryMethod == 'bluetooth') return ConnectionSource.localBluetooth;
if (node.discoveryMethod == 'nsd') return ConnectionSource.localNSD;
return ConnectionSource.localWifi;
```

---

### **1.3 Connection Orchestrator Updates**

**File:** `lib/core/ai2ai/connection_orchestrator.dart`

#### **Constructor Changes**

**Add PersonalityLearning parameter:**
```dart
VibeConnectionOrchestrator({
  required UserVibeAnalyzer vibeAnalyzer,
  required Connectivity connectivity,
  AI2AIRealtimeService? realtimeService,
  DeviceDiscoveryService? deviceDiscovery,
  AI2AIProtocol? protocol,
  PersonalityAdvertisingService? advertisingService,
  required PersonalityLearning personalityLearning,  // NEW
})
```

**Update ConnectionManager initialization:**
```dart
_connectionManager = ConnectionManager(
  vibeAnalyzer: vibeAnalyzer,
  connectivity: connectivity,
  protocol: protocol,  // Pass protocol
  personalityLearning: personalityLearning,  // Pass learning engine
),
```

---

### **1.4 Injection Container Updates**

**File:** `lib/injection_container.dart`

#### **Registration Order:**

**1. Ensure PersonalityLearning registered:**
```dart
gh.lazySingleton<PersonalityLearning>(
  () => PersonalityLearning.withPrefs(gh<SharedPreferences>()),
);
```

**2. Update VibeConnectionOrchestrator:**
```dart
gh.lazySingleton<VibeConnectionOrchestrator>(
  () => VibeConnectionOrchestrator(
    vibeAnalyzer: gh<UserVibeAnalyzer>(),
    connectivity: gh<Connectivity>(),
    realtimeService: gh.isRegistered<AI2AIRealtimeService>() 
        ? gh<AI2AIRealtimeService>() 
        : null,
    deviceDiscovery: gh<DeviceDiscoveryService>(),
    protocol: gh<AI2AIProtocol>(),
    advertisingService: gh<PersonalityAdvertisingService>(),
    personalityLearning: gh<PersonalityLearning>(),  // NEW
  ),
);
```

---

## 📦 **Phase 2: Optional Cloud Enhancement**

### **2.1 Connection Log Queue**

**New File:** `lib/core/ai2ai/connection_log_queue.dart`

#### **Class: ConnectionLogQueue**

**Purpose:** Queue AI2AI connection logs for optional cloud sync

**Storage:** Sembast database (local NoSQL)

**Store Name:** `'ai2ai_connection_logs'`

**Record Structure:**
```dart
{
  'metrics': ConnectionMetrics.toJson(),
  'timestamp': ISO8601 string,
  'synced': boolean,
  'type': 'autonomous_peer_connection',
}
```

#### **Methods:**

**logConnection()**
```dart
Future<void> logConnection(ConnectionMetrics metrics) async
```
- Store connection metrics in local database
- Mark as unsynced
- Non-blocking operation

**getUnsyncedLogs()**
```dart
Future<List<ConnectionMetrics>> getUnsyncedLogs() async
```
- Query all records where synced = false
- Sort by timestamp
- Return list of metrics

**markSynced()**
```dart
Future<void> markSynced(String connectionId) async
```
- Update record synced = true
- Add syncedAt timestamp

**getStats()**
```dart
Future<Map<String, dynamic>> getStats() async
```
- Return total connections, unsynced count
- Used for UI display

---

### **2.2 Cloud Intelligence Sync**

**New File:** `lib/core/ai2ai/cloud_intelligence_sync.dart`

#### **Class: CloudIntelligenceSync**

**Purpose:** Sync connection logs to cloud for network-wide intelligence

**Dependencies:**
- ConnectionLogQueue
- AI2AIRealtimeService (optional)
- Connectivity
- PersonalityLearning

#### **Methods:**

**startAutoSync()**
```dart
void startAutoSync()
```
- Listen to connectivity changes
- Auto-trigger sync when online
- Non-blocking background process

**syncToCloudIntelligence()**
```dart
Future<CloudSyncResult> syncToCloudIntelligence() async
```

**Steps:**
1. Check if realtimeService available
2. Get unsynced logs from queue
3. Upload each log to cloud
4. Mark synced in queue
5. Request network insights from cloud
6. Apply insights to local AI
7. Return sync result

**Upload Format:**
```dart
await realtimeService.uploadConnectionLog({
  'connectionId': metrics.connectionId,
  'timestamp': metrics.startTime,
  'compatibility': metrics.initialCompatibility,
  'learningOutcomes': metrics.learningOutcomes,
  'source': metrics.source,
  'anonymized': true,  // Never send personal data
});
```

**Network Insights Request:**
```dart
final insights = await realtimeService.requestNetworkInsights();
// Returns AI2AILearningInsight with aggregate patterns
```

---

### **2.3 AI2AI Realtime Service Extensions**

**File:** `lib/core/services/ai2ai_realtime_service.dart`

#### **New Methods Required:**

**uploadConnectionLog()**
```dart
Future<void> uploadConnectionLog(ConnectionMetrics metrics) async
```
- Send connection log to Supabase
- Channel: 'ai2ai-network'
- Table: 'connection_logs'
- Anonymized data only

**requestNetworkInsights()**
```dart
Future<AI2AILearningInsight?> requestNetworkInsights() async
```
- Request aggregated patterns from cloud AI
- Supabase Edge Function: 'network-intelligence'
- Returns enhanced learning insights

---

## 📦 **Phase 3: UI Indicators**

### **3.1 Device Discovery Page Updates**

**File:** `lib/presentation/pages/network/device_discovery_page.dart`

#### **Offline Connection Badge:**

**Widget:**
```dart
if (connection.wasOfflineConnection) {
  Chip(
    avatar: Icon(Icons.bluetooth, size: 16, color: Colors.white),
    label: Text('Peer Connection', style: TextStyle(fontSize: 12)),
    backgroundColor: AppColors.success,
  )
}
```

**Placement:** Connection card header, next to compatibility score

---

#### **Sync Status Indicator:**

**Widget:**
```dart
FutureBuilder<Map<String, dynamic>>(
  future: logQueue.getStats(),
  builder: (context, snapshot) {
    if (!snapshot.hasData) return SizedBox.shrink();
    
    final stats = snapshot.data!;
    final unsynced = stats['unsyncedConnections'] as int;
    
    if (unsynced == 0) return SizedBox.shrink();
    
    return Card(
      color: AppColors.infoBackground,
      child: ListTile(
        leading: Icon(Icons.cloud_upload, color: AppColors.info),
        title: Text('Network Enhancement Available'),
        subtitle: Text(
          '$unsynced connections ready to sync for collective intelligence'
        ),
        trailing: ElevatedButton(
          onPressed: () async {
            final result = await cloudSync.syncToCloudIntelligence();
            // Show result snackbar
          },
          child: Text('Sync Now'),
        ),
      ),
    );
  },
)
```

**Placement:** Top of device discovery page, above discovered devices list

---

## 🧪 **Testing Strategy**

### **Unit Tests:**

**Test: AI2AI Protocol**
- `test/unit/network/ai2ai_protocol_offline_test.dart`
- Mock Bluetooth connections
- Test profile exchange
- Test compatibility calculation
- Test learning insights generation

**Test: Connection Manager**
- `test/unit/ai2ai/connection_manager_offline_test.dart`
- Test online/offline routing
- Test offline connection flow
- Test personality learning integration
- Test error handling

**Test: Connection Log Queue**
- `test/unit/ai2ai/connection_log_queue_test.dart`
- Test log storage
- Test sync status tracking
- Test queue statistics

---

### **Integration Tests:**

**Test: End-to-End Offline Connection**
- `test/integration/ai2ai_offline_connection_test.dart`
- Simulate two devices
- Test full connection flow
- Verify personality updates on both
- Verify connection metrics

**Test: Cloud Sync**
- `test/integration/ai2ai_cloud_sync_test.dart`
- Test offline → online transition
- Test log upload
- Test network insights retrieval
- Verify enhanced learning application

---

### **Widget Tests:**

**Test: UI Indicators**
- `test/widget/pages/network/device_discovery_offline_test.dart`
- Test offline badge display
- Test sync status indicator
- Test sync button functionality

---

## 🔒 **Security & Privacy**

### **Data Privacy:**
- ✅ Personality profiles are already anonymized (PrivacyProtection)
- ✅ No personal identifiers in peer exchange
- ✅ Vibe signatures are cryptographic hashes
- ✅ Connection logs contain no personal data

### **Connection Security:**
- ✅ Bluetooth pairing required (OS-level)
- ✅ NSD on local network only
- ✅ Encrypted AI2AIMessage protocol
- ✅ Timeout protection

### **Cloud Sync Security:**
- ✅ Only anonymized logs uploaded
- ✅ HTTPS/WSS for all cloud communication
- ✅ Supabase Row Level Security (RLS)
- ✅ User consent required (settings)

---

## ⚡ **Performance Considerations**

### **Battery Impact:**
- BLE scanning: Low impact (already implemented)
- Connection duration: < 6 seconds per connection
- Mitigation: Throttle scanning frequency, limit simultaneous connections

### **Memory Usage:**
- Profile exchange: < 10KB per profile
- Connection metrics: < 5KB per connection
- Queue storage: Minimal (Sembast efficient)

### **Processing Time:**
- Profile exchange: 2-3 seconds
- Compatibility calculation: < 100ms
- Learning insights: < 200ms
- Personality update: < 200ms
- **Total:** < 6 seconds per connection

---

## 📊 **Metrics & Monitoring**

### **Track:**
- Offline connection success rate
- Average connection duration
- Profile exchange failures
- Learning insight quality
- Cloud sync success rate
- Network intelligence impact

### **Logging:**
```dart
developer.log('Offline peer connection established', name: 'AI2AI', extra: {
  'connectionId': metrics.connectionId,
  'compatibility': compatibility.basicCompatibility,
  'duration': connectionDuration.inSeconds,
  'dimensionsUpdated': learningInsights.dimensionInsights.length,
});
```

---

## ✅ **Acceptance Criteria**

### **Phase 1:**
- [ ] Airplane mode: Two devices can connect and learn
- [ ] Profile exchange completes in < 5 seconds
- [ ] Both AIs update personalities immediately
- [ ] Connection metrics stored locally
- [ ] Zero network calls during offline connection
- [ ] Battery impact < 5% during active scanning

### **Phase 2:**
- [ ] Connection logs queue locally when offline
- [ ] Logs sync automatically when connectivity restored
- [ ] Network insights received from cloud
- [ ] Enhanced learning applied to local AI
- [ ] Sync status visible in UI

### **Phase 3:**
- [ ] Offline connection badges display correctly
- [ ] Sync status updates in real-time
- [ ] Manual sync button functional
- [ ] Statistics show accurate counts

---

**Status:** Ready for implementation  
**Blockers:** None  
**Dependencies:** All in place  

*This specification enables truly autonomous AI that never stops learning.*


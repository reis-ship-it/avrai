# Collaborative Activity Analytics - Specification

**Created:** November 21, 2025  
**Target Implementation:** Phase 3.2 - Advanced Analytics UI  
**Estimated Effort:** 2 days  
**Priority:** 🟢 MEDIUM (Polish/Enhancement)

---

## 📋 Overview

### **Problem Statement**

The SPOTS app has robust collaborative list features (curator/collaborator/follower roles, approval systems, permission controls), but there's **no visibility** into:
- How collaborative lists are being used
- Whether AI2AI conversations lead to collaborative outcomes
- Group chat vs. DM collaboration patterns
- Conversation → Collaboration conversion rates

This gap makes it impossible to:
- Measure social feature engagement
- Validate if AI2AI conversations drive real-world collaboration
- Understand community collaboration patterns
- Optimize features for collaborative success

### **Solution**

Add privacy-safe collaborative activity tracking to the AI2AI learning system and expose aggregate metrics in god-mode admin dashboard.

---

## 🎯 Goals

### **Primary Goals:**
1. Track list creation during/after AI2AI conversations
2. Distinguish group chat (3+ people) vs. DM (2 people) collaboration
3. Show aggregate metrics in god-mode (counts only, zero user data)
4. Maintain full privacy (no user IDs, no content, aggregates only)

### **Success Metrics:**
- Visibility into collaborative list creation rates
- Group vs. DM collaboration breakdown
- Conversation → Collaboration conversion rate
- Time-to-collaboration after AI2AI chat

### **Non-Goals:**
- ❌ Tracking individual user behavior (privacy violation)
- ❌ Exposing list names or content
- ❌ Identifying who collaborated with whom
- ❌ Real-time monitoring of specific conversations

---

## 🔒 Privacy Requirements

### **Strict Privacy Constraints:**

**✅ ALLOWED:**
- Aggregate counts (e.g., "247 collaborative lists created")
- Percentages (e.g., "34% in group chats, 66% in DMs")
- Averages (e.g., "8.3 spots per collaborative list")
- Time patterns (e.g., "peak collaboration 7-9pm")
- Group size distribution (e.g., "2-person: 66%, 3-person: 22%")

**❌ FORBIDDEN:**
- User IDs or usernames
- List names or descriptions
- Spot names or locations
- Conversation content
- Who collaborated with whom
- Specific timestamps (only aggregates like "7-9pm")

### **Privacy Level:** 
**FULLY ANONYMOUS** - Same standard as existing AI2AI learning metrics

---

## 📊 Data to Track

### **1. Collaborative List Metrics**

```dart
class CollaborativeActivityMetrics {
  // List creation counts
  final int totalCollaborativeLists;
  final int groupChatLists;              // 3+ participants
  final int dmLists;                     // 2 participants
  final double avgListSize;              // Average spots per list
  final double avgCollaboratorCount;     // Average collaborators per list
  
  // Activity context
  final Map<int, int> groupSizeDistribution; // {2: 823, 3: 298, 4: 95, 5+: 31}
  final double collaborationRate;         // % of conversations with outcomes
  final int totalPlanningSessions;        // Conversations with planning keywords
  
  // Engagement patterns
  final double avgSessionDuration;        // Average planning session length
  final double followThroughRate;         // % lists with spots actually added
  final Map<int, int> activityByHour;     // {7: 45, 8: 67, ...} - hour distribution
  
  // Temporal data
  final DateTime collectionStart;
  final DateTime lastUpdated;
  final Duration measurementWindow;
  
  // Privacy metadata
  final int totalUsersContributing;       // Count only, no IDs
  final bool containsUserData;            // Always false
  final bool isAnonymized;                // Always true
}
```

### **2. Pattern Detection**

Track when these actions occur during/after AI2AI conversations:
- `CreateListIntent` execution
- `AddSpotToListIntent` execution  
- Collaborator additions to lists
- Time delta between conversation and list creation

### **3. Context Tracking**

For each collaborative event:
- Chat context: group size (2, 3, 4, 5+)
- Chat type: group chat vs. DM
- Conversation duration before list creation
- Number of messages in conversation
- Time of day (hour bucket)

**Note:** No conversation content, no user identities

---

## 🏗️ Technical Implementation

### **Phase 1: Backend Tracking (Day 1)**

#### **1.1: Add New Method to AI2AI Learning**

**File:** `lib/core/ai/ai2ai_learning.dart`

```dart
/// Analyze collaborative activity patterns from AI2AI conversations
Future<CrossPersonalityLearningPattern?> _analyzeCollaborativeActivity(
  String userId,
  List<AI2AIChatEvent> chats,
) async {
  if (chats.isEmpty) return null;
  
  // Track collaborative list creation
  int totalCollaborativeLists = 0;
  int groupChatLists = 0;
  int dmLists = 0;
  final groupSizes = <int, int>{};
  
  for (final chat in chats) {
    // Check if this chat led to list creation
    final hasListCreation = await _detectListCreation(chat);
    if (!hasListCreation) continue;
    
    totalCollaborativeLists++;
    
    // Categorize by group size
    final groupSize = chat.participants.length;
    groupSizes[groupSize] = (groupSizes[groupSize] ?? 0) + 1;
    
    if (groupSize >= 3) {
      groupChatLists++;
    } else {
      dmLists++;
    }
  }
  
  if (totalCollaborativeLists == 0) return null;
  
  final collaborationRate = totalCollaborativeLists / chats.length;
  
  return CrossPersonalityLearningPattern(
    patternType: 'collaborative_activity',
    characteristics: {
      'total_collaborative_lists': totalCollaborativeLists,
      'group_chat_lists': groupChatLists,
      'dm_lists': dmLists,
      'group_size_distribution': groupSizes,
      'collaboration_rate': collaborationRate,
    },
    strength: collaborationRate,
    confidence: min(1.0, chats.length / 10.0),
    identified: DateTime.now(),
  );
}

/// Detect if a chat event led to list creation
Future<bool> _detectListCreation(AI2AIChatEvent chat) async {
  // Check action history for CreateListIntent or AddSpotToListIntent
  // within timeWindow of this chat
  // Implementation depends on ActionHistoryService integration
  return false; // Placeholder
}
```

#### **1.2: Integrate with Action History**

**File:** `lib/core/services/action_history_service.dart`

Add method to query actions by time window and type:

```dart
/// Get actions of specific type within time window
Future<List<ActionHistoryEntry>> getActionsByTypeInWindow({
  required ActionType type,
  required DateTime start,
  required DateTime end,
}) async {
  // Query stored actions
  // Return matching actions
}
```

#### **1.3: Add to Collective Knowledge**

Update `buildCollectiveKnowledge()` to include collaborative activity patterns in the analysis.

---

### **Phase 2: God-Mode Visualization (Day 2)**

#### **2.1: Service Layer**

**File:** `lib/core/services/admin_god_mode_service.dart`

```dart
/// Get collaborative activity metrics
Future<CollaborativeActivityMetrics> getCollaborativeActivityMetrics() async {
  if (!isAuthorized) {
    throw UnauthorizedException('God-mode access required');
  }
  
  try {
    // Aggregate data from AI2AI learning patterns
    // Calculate metrics
    // Return anonymous aggregates
    
    return CollaborativeActivityMetrics(
      totalCollaborativeLists: 1247,
      groupChatLists: 423,
      dmLists: 824,
      avgListSize: 8.3,
      avgCollaboratorCount: 2.7,
      groupSizeDistribution: {2: 823, 3: 298, 4: 95, 5: 31},
      collaborationRate: 0.37,
      totalPlanningSessions: 2150,
      avgSessionDuration: 12.5,
      followThroughRate: 0.68,
      activityByHour: {/* hour distribution */},
      collectionStart: DateTime.now().subtract(Duration(days: 30)),
      lastUpdated: DateTime.now(),
      measurementWindow: Duration(days: 30),
      totalUsersContributing: 456, // Count only
      containsUserData: false,
      isAnonymized: true,
    );
  } catch (e) {
    developer.log('Error getting collaborative metrics: $e', name: _logName);
    throw Exception('Failed to fetch collaborative metrics');
  }
}
```

#### **2.2: Widget**

**File:** `lib/presentation/widgets/admin/admin_collaborative_activity_widget.dart`

```dart
/// Widget displaying collaborative activity analytics
class AdminCollaborativeActivityWidget extends StatefulWidget {
  final AdminGodModeService godModeService;
  
  const AdminCollaborativeActivityWidget({
    super.key,
    required this.godModeService,
  });
  
  @override
  State<AdminCollaborativeActivityWidget> createState() =>
      _AdminCollaborativeActivityWidgetState();
}

class _AdminCollaborativeActivityWidgetState
    extends State<AdminCollaborativeActivityWidget> {
  CollaborativeActivityMetrics? _metrics;
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    _loadMetrics();
  }
  
  Future<void> _loadMetrics() async {
    // Fetch and display metrics
  }
  
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            _buildOverallStats(),
            _buildGroupVsDM(),
            _buildGroupSizeDistribution(),
            _buildEngagementMetrics(),
            _buildActivityPattern(),
            _buildPrivacyBadge(),
          ],
        ),
      ),
    );
  }
}
```

#### **2.3: Dashboard Integration**

Add new tab or section to `god_mode_dashboard_page.dart`:

```dart
Tab(icon: Icon(Icons.groups), text: 'Collaboration'),
```

---

## 📈 UI Mockup

### **God-Mode Collaborative Activity Tab**

```
┌─────────────────────────────────────────────────────────────┐
│ 🤝 Collaborative Activity Analytics                         │
│                                                             │
│ ┌─────────────────────────────────────────────────────────┐ │
│ │ Overall Collaboration                                   │ │
│ │ ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ │ │
│ │ Total Collaborative Lists: 1,247                       │ │
│ │ Collaboration Rate: 37% of conversations               │ │
│ │ Average List Size: 8.3 spots                          │ │
│ └─────────────────────────────────────────────────────────┘ │
│                                                             │
│ ┌─────────────────────────────────────────────────────────┐ │
│ │ Context Breakdown                                       │ │
│ │ ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ │ │
│ │                                                         │ │
│ │   Group Chats (3+)    DMs (2 people)                  │ │
│ │   ┌───────────┐       ┌───────────┐                   │ │
│ │   │    423    │       │    824    │                   │ │
│ │   │   (34%)   │       │   (66%)   │                   │ │
│ │   └───────────┘       └───────────┘                   │ │
│ └─────────────────────────────────────────────────────────┘ │
│                                                             │
│ ┌─────────────────────────────────────────────────────────┐ │
│ │ Group Size Distribution                                 │ │
│ │ ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ │ │
│ │ 2 people: ████████████████████████████ 66%            │ │
│ │ 3 people: ██████████ 22%                              │ │
│ │ 4 people: ████ 9%                                     │ │
│ │ 5+ people: █ 3%                                       │ │
│ └─────────────────────────────────────────────────────────┘ │
│                                                             │
│ ┌─────────────────────────────────────────────────────────┐ │
│ │ Engagement Metrics                                      │ │
│ │ ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ │ │
│ │ • Planning Sessions: 2,150                            │ │
│ │ • Avg Session Duration: 12.5 minutes                  │ │
│ │ • Follow-Through Rate: 68%                            │ │
│ │ • Peak Activity: 7-9pm                                │ │
│ └─────────────────────────────────────────────────────────┘ │
│                                                             │
│ 🔒 Privacy: All metrics are anonymous aggregates          │
│    No user data, content, or identities exposed           │
└─────────────────────────────────────────────────────────────┘
```

---

## ✅ Acceptance Criteria

### **Functional Requirements:**
- [ ] Track list creation during/after AI2AI conversations
- [ ] Distinguish group chat (3+) vs. DM (2) contexts
- [ ] Calculate collaboration rate (% conversations with outcomes)
- [ ] Show group size distribution
- [ ] Display engagement metrics (duration, follow-through)
- [ ] Identify peak activity times (hour distribution)
- [ ] Widget renders in god-mode dashboard
- [ ] Real-time or near-real-time updates

### **Privacy Requirements:**
- [ ] Zero user identifiable information
- [ ] No conversation content exposed
- [ ] No list names or spot names
- [ ] Only aggregate counts and percentages
- [ ] Privacy badge displayed on widget
- [ ] Compliance with OUR_GUTS.md privacy principles

### **Technical Requirements:**
- [ ] Integration with `AI2AIChatAnalyzer`
- [ ] Integration with `ActionHistoryService`
- [ ] New method: `_analyzeCollaborativeActivity()`
- [ ] New widget: `AdminCollaborativeActivityWidget`
- [ ] God-mode service method: `getCollaborativeActivityMetrics()`
- [ ] Data model: `CollaborativeActivityMetrics`
- [ ] Tests for new methods
- [ ] No linter errors
- [ ] 100% AppColors compliance

---

## 🧪 Testing Strategy

### **Unit Tests:**
- `_analyzeCollaborativeActivity()` with various chat patterns
- Collaborative metrics calculation accuracy
- Privacy constraint validation (no user data leakage)
- Group size distribution correctness

### **Integration Tests:**
- Action history → AI2AI learning pipeline
- God-mode service data flow
- Widget rendering with real data

### **Manual Testing:**
- Create collaborative lists in test environment
- Verify metrics appear in god-mode
- Validate privacy (inspect data payloads)
- Check real-time updates

---

## 📋 Implementation Checklist

### **Day 1: Backend** (8 hours)
- [ ] Add `_analyzeCollaborativeActivity()` to `AI2AIChatAnalyzer`
- [ ] Implement `_detectListCreation()` helper
- [ ] Add action history query by time window
- [ ] Create `CollaborativeActivityMetrics` data model
- [ ] Integrate with `buildCollectiveKnowledge()`
- [ ] Add method to `AdminGodModeService`
- [ ] Write unit tests
- [ ] Verify privacy compliance

### **Day 2: Frontend** (8 hours)
- [ ] Create `AdminCollaborativeActivityWidget`
- [ ] Implement all visualization components
- [ ] Add privacy badge
- [ ] Add to god-mode dashboard (new tab or section)
- [ ] Test rendering with mock data
- [ ] Test rendering with real data
- [ ] Fix any linter errors
- [ ] Final privacy audit

---

## 🔗 Dependencies

### **Required Services:**
- `AI2AIChatAnalyzer` (exists)
- `ActionHistoryService` (exists, may need query method)
- `AdminGodModeService` (exists, needs new method)

### **Required Data:**
- AI2AI chat events (exists)
- Action history (exists)
- List metadata (exists)

### **No Blocking Dependencies** ✅

---

## 📊 Success Metrics

After implementation, we'll be able to answer:

**Engagement Questions:**
- ✅ What % of AI2AI conversations lead to collaborative outcomes?
- ✅ Are group chats or DMs more effective for collaboration?
- ✅ What group sizes collaborate most effectively?
- ✅ When do users collaborate most (time patterns)?

**Product Questions:**
- ✅ Is the AI2AI feature driving real-world value (list creation)?
- ✅ Should we optimize for group or DM experiences?
- ✅ What's the follow-through rate (planning → execution)?

**Community Health:**
- ✅ Are users actually using collaborative features?
- ✅ Is collaboration growing or declining?
- ✅ What's the average collaboration session quality?

---

## 🚀 Future Enhancements

**Out of Scope for Phase 3.2, but Could Add Later:**

1. **Trend Analysis:** Track metrics over time (week-over-week, month-over-month)
2. **Cohort Analysis:** Compare collaboration rates across user cohorts
3. **Correlation Analysis:** Link collaboration to other engagement metrics
4. **A/B Testing Support:** Compare different AI2AI features
5. **Export Functionality:** CSV/JSON export for further analysis
6. **Alerts:** Notify admins of significant pattern changes

---

## 📝 Notes

### **Why This Matters:**
- Validates social features are working
- Shows AI2AI has real-world impact
- Helps optimize for collaborative success
- Privacy-safe community health metrics

### **Privacy Philosophy:**
Per OUR_GUTS.md: "Privacy and Control Are Non-Negotiable"
- This spec maintains full privacy
- Only aggregates, never individual data
- Users remain anonymous
- No conversation content exposed

### **Alignment with SPOTS Vision:**
- Self-improving network: Learn what collaboration patterns work
- AI2AI ecosystem: Measure cross-AI collaboration effectiveness
- Community-driven: Understand how community collaborates

---

**Specification Status:** ✅ READY FOR IMPLEMENTATION  
**Phase:** 3.2 - Advanced Analytics UI  
**Created By:** AI Assistant  
**Date:** November 21, 2025


# Phase 2: Knot Weaving - Implementation Plan

**Date:** December 16, 2025  
**Status:** ✅ **READY TO START**  
**Phase:** KT.2 - Knot Weaving  
**Priority:** P1 - High Priority Feature  
**Timeline:** 2-3 weeks

---

## 🎯 Executive Summary

Implement knot weaving system that creates braided knots when two personalities connect, showing the topological structure of their relationship. This phase enables visualization of how personalities intertwine and creates unique relationship representations.

**Core Innovation:**
- **Braided Knots:** Two personality knots woven together into a single braided structure
- **Relationship Types:** Different braiding patterns for different relationship types (friendship, mentorship, romantic, collaborative)
- **Weaving Compatibility:** Calculate how well two knots can be woven together
- **Braiding Previews:** Preview braiding before creating connection
- **AI2AI Integration:** Automatically create braided knots when AI2AI connections form

---

## ✅ Prerequisites

### Dependencies Met
- ✅ Phase 1 (KT.1) - Core Knot System (Complete)
- ✅ AI2AI Connection System (Complete)
- ✅ ConnectionOrchestrator (Complete)
- ✅ PersonalityKnotService (Complete)
- ✅ Rust FFI bindings (Complete)

### Required Services
- `PersonalityKnotService` - For loading personality knots
- `ConnectionOrchestrator` - For AI2AI connection management
- `KnotStorageService` - For storing braided knots
- Rust FFI - For braid group mathematics

---

## 📋 Implementation Tasks

### Task 1: Braided Knot Model

**File:** `lib/core/models/knot/braided_knot.dart`

**Components:**
```dart
class BraidedKnot {
  final String id;
  final PersonalityKnot knotA;
  final PersonalityKnot knotB;
  final BraidSequence braidSequence;
  final double complexity;
  final double stability;
  final double harmonyScore;
  final RelationshipType relationshipType;
  final DateTime createdAt;
  final DateTime? updatedAt;
  
  // JSON serialization
  Map<String, dynamic> toJson();
  factory BraidedKnot.fromJson(Map<String, dynamic> json);
}

class BraidingPreview {
  final BraidedKnot braidedKnot;
  final double complexity;
  final double stability;
  final double harmony;
  final double compatibility;
  final String relationshipType;
  
  BraidingPreview({
    required this.braidedKnot,
    required this.complexity,
    required this.stability,
    required this.harmony,
    required this.compatibility,
    required this.relationshipType,
  });
}

enum RelationshipType {
  friendship,
  mentorship,
  romantic,
  collaborative,
  professional,
}
```

**Acceptance Criteria:**
- [ ] BraidedKnot model created with all fields
- [ ] JSON serialization/deserialization working
- [ ] BraidingPreview model created
- [ ] RelationshipType enum defined
- [ ] Unit tests for model (serialization, equality)

---

### Task 2: Knot Weaving Service

**File:** `lib/core/services/knot/knot_weaving_service.dart`

**Core Methods:**
```dart
class KnotWeavingService {
  /// Create braided knot from two personality knots
  Future<BraidedKnot> weaveKnots({
    required PersonalityKnot knotA,
    required PersonalityKnot knotB,
    required RelationshipType relationshipType,
  }) async {
    // 1. Get braid sequences from both knots
    // 2. Apply relationship-specific braiding pattern
    // 3. Create combined braid sequence
    // 4. Calculate complexity, stability, harmony
    // 5. Return BraidedKnot
  }
  
  /// Calculate weaving compatibility
  Future<double> calculateWeavingCompatibility({
    required PersonalityKnot knotA,
    required PersonalityKnot knotB,
  }) async {
    // 1. Calculate topological compatibility (from Rust FFI)
    // 2. Calculate quantum compatibility (from QuantumCompatibilityService)
    // 3. Combine: 40% topological, 60% quantum
    // 4. Return compatibility score
  }
  
  /// Preview braiding before connection
  Future<BraidingPreview> previewBraiding({
    required PersonalityKnot knotA,
    required PersonalityKnot knotB,
    RelationshipType relationshipType = RelationshipType.friendship,
  }) async {
    // 1. Create temporary braided knot
    // 2. Calculate all metrics
    // 3. Return preview
  }
  
  /// Create friendship braid (balanced interweaving)
  BraidSequence _createFriendshipBraid(
    PersonalityKnot knotA,
    PersonalityKnot knotB,
  ) {
    // Intertwine strands from both knots
    // Friendship = balanced interweaving
    // Use alternating pattern
  }
  
  /// Create mentorship braid (asymmetric structure)
  BraidSequence _createMentorshipBraid(
    PersonalityKnot knotA, // mentor
    PersonalityKnot knotB, // mentee
  ) {
    // Mentor's knot wraps around mentee's knot
    // Asymmetric structure
    // More crossings from mentor side
  }
  
  /// Create romantic braid (deep interweaving)
  BraidSequence _createRomanticBraid(
    PersonalityKnot knotA,
    PersonalityKnot knotB,
  ) {
    // Deep interweaving, complex structure
    // Symmetric or complementary patterns
    // High crossing count
  }
  
  /// Create collaborative braid (parallel with periodic crossings)
  BraidSequence _createCollaborativeBraid(
    PersonalityKnot knotA,
    PersonalityKnot knotB,
  ) {
    // Parallel strands with periodic crossings
    // Balanced collaboration pattern
    // Regular crossing intervals
  }
}
```

**Acceptance Criteria:**
- [ ] KnotWeavingService class created
- [ ] All relationship type braiding methods implemented
- [ ] Weaving compatibility calculation working
- [ ] Braiding preview functionality working
- [ ] Integration with Rust FFI for braid operations
- [ ] Integration with QuantumCompatibilityService
- [ ] Unit tests for all methods (15+ tests)

---

### Task 3: AI2AI Integration

**File:** `lib/core/ai2ai/connection_orchestrator.dart` (modify existing)

**Changes:**
```dart
class ConnectionOrchestrator {
  final KnotWeavingService _knotWeavingService;
  final PersonalityKnotService _personalityKnotService;
  
  Future<ConnectionResult> createConnection({
    required String agentIdA,
    required String agentIdB,
    RelationshipType? relationshipType,
  }) async {
    // ... existing connection logic ...
    
    // NEW: Create knot weaving
    final knotA = await _personalityKnotService.getKnotForAgent(agentIdA);
    final knotB = await _personalityKnotService.getKnotForAgent(agentIdB);
    
    if (knotA != null && knotB != null) {
      final braidedKnot = await _knotWeavingService.weaveKnots(
        knotA: knotA,
        knotB: knotB,
        relationshipType: relationshipType ?? RelationshipType.friendship,
      );
      
      // Store braided knot with connection
      await _saveBraidedKnot(connectionId, braidedKnot);
      
      // Add to connection metadata
      connectionResult.braidedKnotId = braidedKnot.id;
    }
    
    return connectionResult;
  }
  
  /// Get braided knot for connection
  Future<BraidedKnot?> getBraidedKnot(String connectionId) async {
    // Load braided knot from storage
    return await _knotStorageService.getBraidedKnot(connectionId);
  }
  
  /// Get braiding preview before connection
  Future<BraidingPreview?> previewBraiding({
    required String agentIdA,
    required String agentIdB,
    RelationshipType relationshipType = RelationshipType.friendship,
  }) async {
    final knotA = await _personalityKnotService.getKnotForAgent(agentIdA);
    final knotB = await _personalityKnotService.getKnotForAgent(agentIdB);
    
    if (knotA == null || knotB == null) return null;
    
    return await _knotWeavingService.previewBraiding(
      knotA: knotA,
      knotB: knotB,
      relationshipType: relationshipType,
    );
  }
}
```

**Acceptance Criteria:**
- [ ] KnotWeavingService injected into ConnectionOrchestrator
- [ ] Braided knots created automatically on connection
- [ ] Braided knot stored with connection
- [ ] getBraidedKnot() method working
- [ ] previewBraiding() method working
- [ ] Integration tests for connection + braiding workflow

---

### Task 4: Braided Knot Storage

**File:** `lib/core/services/knot/knot_storage_service.dart` (extend existing)

**New Methods:**
```dart
class KnotStorageService {
  /// Save braided knot for connection
  Future<void> saveBraidedKnot({
    required String connectionId,
    required BraidedKnot braidedKnot,
  }) async {
    // Store braided knot in storage
    // Key: "braided_knot:$connectionId"
  }
  
  /// Get braided knot for connection
  Future<BraidedKnot?> getBraidedKnot(String connectionId) async {
    // Load braided knot from storage
  }
  
  /// Get all braided knots for agent
  Future<List<BraidedKnot>> getBraidedKnotsForAgent(String agentId) async {
    // Load all braided knots where agent is part of connection
  }
  
  /// Delete braided knot (when connection deleted)
  Future<void> deleteBraidedKnot(String connectionId) async {
    // Remove braided knot from storage
  }
}
```

**Acceptance Criteria:**
- [ ] saveBraidedKnot() method implemented
- [ ] getBraidedKnot() method implemented
- [ ] getBraidedKnotsForAgent() method implemented
- [ ] deleteBraidedKnot() method implemented
- [ ] Storage integration tests passing

---

### Task 5: Visualization Widget

**File:** `lib/presentation/widgets/knot/braided_knot_widget.dart`

**Components:**
```dart
class BraidedKnotWidget extends StatelessWidget {
  final BraidedKnot braidedKnot;
  final double size;
  final bool animated;
  final Color? colorA;
  final Color? colorB;
  
  const BraidedKnotWidget({
    required this.braidedKnot,
    this.size = 200.0,
    this.animated = false,
    this.colorA,
    this.colorB,
  });
  
  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: BraidedKnotPainter(
        braidedKnot: braidedKnot,
        animated: animated,
        colorA: colorA ?? AppColors.primary,
        colorB: colorB ?? AppColors.secondary,
      ),
    );
  }
}

class BraidedKnotPainter extends CustomPainter {
  final BraidedKnot braidedKnot;
  final bool animated;
  final Color colorA;
  final Color colorB;
  
  BraidedKnotPainter({
    required this.braidedKnot,
    required this.animated,
    required this.colorA,
    required this.colorB,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    // Draw braided knot diagram
    // 1. Draw strands from knotA (colorA)
    // 2. Draw strands from knotB (colorB)
    // 3. Draw crossings (over/under based on braid sequence)
    // 4. Color-code by relationship type
    // 5. Add complexity/stability indicators
  }
  
  @override
  bool shouldRepaint(BraidedKnotPainter oldDelegate) {
    return animated || oldDelegate.braidedKnot != braidedKnot;
  }
}
```

**Acceptance Criteria:**
- [ ] BraidedKnotWidget created
- [ ] BraidedKnotPainter implemented
- [ ] Visualization renders correctly
- [ ] Animation support (optional)
- [ ] Color customization working
- [ ] Widget tests passing

---

### Task 6: Braiding Animation Widget

**File:** `lib/presentation/widgets/knot/braiding_animation_widget.dart`

**Components:**
```dart
class BraidingAnimationWidget extends StatefulWidget {
  final PersonalityKnot knotA;
  final PersonalityKnot knotB;
  final RelationshipType relationshipType;
  final double size;
  final VoidCallback? onComplete;
  
  const BraidingAnimationWidget({
    required this.knotA,
    required this.knotB,
    required this.relationshipType,
    this.size = 200.0,
    this.onComplete,
  });
  
  @override
  State<BraidingAnimationWidget> createState() => _BraidingAnimationWidgetState();
}

class _BraidingAnimationWidgetState extends State<BraidingAnimationWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
    _controller.forward().then((_) => widget.onComplete?.call());
  }
  
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        // Render braiding animation frame
        // Show progressive interweaving
      },
    );
  }
}
```

**Acceptance Criteria:**
- [ ] BraidingAnimationWidget created
- [ ] Animation shows progressive braiding
- [ ] Animation completes smoothly
- [ ] onComplete callback working
- [ ] Performance optimized (60fps)

---

### Task 7: Dependency Injection

**File:** `lib/injection_container.dart` (modify existing)

**Registration:**
```dart
// Register KnotWeavingService
sl.registerLazySingleton<KnotWeavingService>(() => KnotWeavingService(
  personalityKnotService: sl<PersonalityKnotService>(),
  quantumCompatibilityService: sl<QuantumCompatibilityService>(),
  knotStorageService: sl<KnotStorageService>(),
));
```

**Acceptance Criteria:**
- [ ] KnotWeavingService registered
- [ ] Dependencies properly injected
- [ ] Registration order correct (dependencies before dependents)

---

### Task 8: Unit Tests

**Files:**
- `test/core/models/knot/braided_knot_test.dart`
- `test/core/services/knot/knot_weaving_service_test.dart`
- `test/core/services/knot/knot_storage_service_test.dart` (extend existing)
- `test/presentation/widgets/knot/braided_knot_widget_test.dart`

**Test Coverage:**
- [ ] BraidedKnot model tests (serialization, equality, validation)
- [ ] KnotWeavingService tests (all relationship types, compatibility, preview)
- [ ] KnotStorageService tests (save, load, delete braided knots)
- [ ] Widget tests (rendering, animation)
- [ ] **Target:** 20+ unit tests, 5+ widget tests

---

### Task 9: Integration Tests

**File:** `test/integration/knot_weaving_integration_test.dart`

**Test Scenarios:**
- [ ] Create connection → braided knot created automatically
- [ ] Preview braiding before connection
- [ ] Load braided knot for existing connection
- [ ] Different relationship types create different braids
- [ ] Braided knot deleted when connection deleted
- [ ] Get all braided knots for agent

**Acceptance Criteria:**
- [ ] All integration tests passing
- [ ] End-to-end workflow tested
- [ ] Error handling tested

---

## 📊 Success Metrics

### Functional Requirements
- ✅ Braided knots created for all AI2AI connections
- ✅ All relationship types supported
- ✅ Weaving compatibility calculated correctly
- ✅ Braiding previews working
- ✅ Visualization renders correctly

### Performance Requirements
- ✅ Braided knot creation: < 100ms
- ✅ Compatibility calculation: < 50ms
- ✅ Preview generation: < 150ms
- ✅ Visualization rendering: 60fps

### Quality Requirements
- ✅ All unit tests passing (20+ tests)
- ✅ All integration tests passing (6+ tests)
- ✅ Code coverage: > 80%
- ✅ Zero linter errors
- ✅ Documentation complete

---

## 🔗 Integration Points

### Existing Services
- **PersonalityKnotService:** Load personality knots for agents
- **QuantumCompatibilityService:** Calculate quantum compatibility
- **ConnectionOrchestrator:** Create connections and trigger braiding
- **KnotStorageService:** Store and retrieve braided knots
- **Rust FFI:** Braid group mathematics operations

### Future Integration
- **Phase 3:** Use braided knots in onboarding groups
- **Phase 4:** Dynamic braided knots based on mood/energy
- **Phase 5:** Include braided knots in community fabric
- **Phase 6:** Use braided knots in recommendations

---

## 📝 Documentation Requirements

### Code Documentation
- [ ] All public methods documented
- [ ] Complex algorithms explained
- [ ] Relationship type patterns documented
- [ ] Integration examples provided

### User Documentation
- [ ] What braided knots represent
- [ ] How to view braided knots
- [ ] Relationship type meanings
- [ ] Visualization guide

### Technical Documentation
- [ ] Braiding algorithm details
- [ ] Compatibility calculation formula
- [ ] Storage schema
- [ ] Performance characteristics

---

## 🚪 Doors Philosophy Alignment

### What Doors Does This Open?

**1. Doors to Relationship Understanding**
- Visual representation of how personalities connect
- See the topological structure of relationships
- Understand relationship complexity and harmony

**2. Doors to Connection Preview**
- Preview how personalities will braid before connecting
- Understand compatibility before committing
- Make informed connection decisions

**3. Doors to Unique Identity**
- Each relationship has a unique braided knot
- Share braided knots as relationship representations
- Visual history of connections

### When Are Users Ready?

**Progressive Disclosure:**
- **After First Connection:** Show braided knot automatically
- **Before Connection:** Offer preview option
- **After Multiple Connections:** Show braided knot gallery
- **When Exploring:** Show relationship type options

**User Control:**
- Users can view/hide braided knots
- Users can choose relationship type
- Users can share braided knots (opt-in)

### Is This Being a Good Key?

✅ **Yes** - This:
- Opens doors to deeper relationship understanding
- Enhances connection experience with visual representation
- Respects user autonomy (preview before commit)
- Provides unique value (topological relationship structure)

### Is the AI Learning With the User?

✅ **Yes** - The AI:
- Learns which braiding patterns lead to successful connections
- Adapts relationship type suggestions based on outcomes
- Tracks braided knot metrics (complexity, stability, harmony)
- Refines compatibility calculations from connection results

---

## 📅 Timeline

### Week 1: Core Implementation
- Day 1-2: BraidedKnot model + KnotWeavingService skeleton
- Day 3-4: Relationship type braiding algorithms
- Day 5: Compatibility calculation + preview

### Week 2: Integration & Storage
- Day 1-2: AI2AI integration
- Day 3: Storage service extension
- Day 4-5: Dependency injection + unit tests

### Week 3: Visualization & Polish
- Day 1-3: Visualization widget
- Day 4: Animation widget
- Day 5: Integration tests + documentation

---

## ✅ Acceptance Criteria Summary

**Must Have:**
- [ ] BraidedKnot model created
- [ ] KnotWeavingService implemented (all relationship types)
- [ ] AI2AI integration complete
- [ ] Storage working
- [ ] Basic visualization widget
- [ ] All unit tests passing (20+)
- [ ] All integration tests passing (6+)

**Nice to Have:**
- [ ] Braiding animation widget
- [ ] Advanced visualization features
- [ ] Performance optimizations
- [ ] Extended documentation

---

## 🎯 Next Steps After Phase 2

1. **Phase 3:** Onboarding Integration (use braided knots in groups)
2. **Phase 6:** Integrated Recommendations (use braided knots in recommendations)
3. **Phase 4:** Dynamic Knots (make braided knots evolve)

---

**Last Updated:** December 16, 2025  
**Status:** ✅ **READY TO START**

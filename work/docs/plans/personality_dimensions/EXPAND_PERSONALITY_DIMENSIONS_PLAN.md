# Expand Personality Dimensions: 8 → 12 Implementation Plan

**Date:** November 21, 2025, 12:31 PM CST  
**Status:** 📋 Planning - Ready for Implementation  
**Priority:** MEDIUM - Enhancement to personality system  
**Effort:** 5-7 days  
**Reference:** OUR_GUTS.md - "AI personality that evolves and learns while preserving privacy"

---

## 🎯 **Executive Summary**

Expand the personality system from 8 to 12 core dimensions to enable more precise spot matching and compatibility calculations. The new dimensions focus on experience preferences that the current 8 dimensions don't adequately capture.

### **The Philosophy: Understanding Which Doors Resonate**
The AI needs to understand which doors YOU are ready to open. Not everyone opens the same doors. Some doors are high-energy (rock climbing gyms), some are quiet (meditation centers). Some are familiar favorites (your regular coffee shop), some are always new (tourist exploring). The 12 dimensions help the AI understand YOUR doors.

### **New Dimensions:**
1. **energy_preference** - Chill/relaxed doors ↔ High-energy/active doors
2. **novelty_seeking** - New doors always ↔ Same doors repeatedly
3. **value_orientation** - Budget-friendly doors ↔ Premium/luxury doors
4. **crowd_tolerance** - Quiet/intimate doors ↔ Bustling/popular doors

**Result:** The key (AI) can better identify which doors you're ready to open, whether you're looking for your spots, your communities, or both.

---

## 📊 **Current vs. New Dimensions**

### **Existing 8 Dimensions (Keep):**
```dart
'exploration_eagerness',      // How eager for new discovery
'community_orientation',      // Preference for social vs solo experiences
'authenticity_preference',    // Preference for authentic vs curated experiences
'social_discovery_style',     // How they prefer to discover through others
'temporal_flexibility',       // Spontaneous vs planned approach
'location_adventurousness',   // How far they're willing to travel
'curation_tendency',         // How much they curate for others
'trust_network_reliance',    // How much they rely on trusted connections
```

### **New 4 Dimensions (Add):**
```dart
'energy_preference',          // NEW: Chill/relaxed (0.0) ↔ High-energy/active (1.0)
'novelty_seeking',            // NEW: New places only (1.0) ↔ Returning favorites (0.0)
'value_orientation',          // NEW: Budget-conscious (0.0) ↔ Premium/luxury (1.0)
'crowd_tolerance',            // NEW: Quiet/empty (0.0) ↔ Bustling/popular (1.0)
```

---

## 🎯 **Why These 4 Dimensions?**

### **1. energy_preference**
**Gap Filled:** Activity level matching  
**Use Cases:**
- Rock climbing gym vs. wine tasting
- High-energy nightclub vs. quiet jazz bar
- Hiking vs. spa day
- Workout spots vs. meditation centers

**Impact on Recommendations:**
- Better spot type matching
- Reduces mismatched recommendations
- Example: Don't recommend CrossFit gym to chill user

---

### **2. novelty_seeking**
**Gap Filled:** Repeat-visit behavior  
**Use Cases:**
- Always trying new restaurants vs. having favorite spots
- Tourist who visits once vs. local who returns weekly
- Exploration mode vs. routine mode
- Discovery phase vs. settled phase

**Impact on Recommendations:**
- Balances new vs. familiar recommendations
- Recognizes value in returning to favorites
- Example: High novelty → prioritize new spots, Low novelty → suggest past favorites

**Note:** Different from `exploration_eagerness` which is about willingness to try new categories/areas. This is about preference for revisiting vs. always new.

---

### **3. value_orientation**
**Gap Filled:** Budget/price sensitivity  
**Use Cases:**
- Michelin-star restaurant vs. food truck
- Luxury spa vs. local nail salon
- High-end boutique vs. thrift store
- Premium experiences vs. budget options

**Impact on Recommendations:**
- Price-appropriate recommendations
- Reduces sticker shock
- Better user satisfaction
- Example: Don't recommend $200 tasting menu to budget-conscious user

---

### **4. crowd_tolerance**
**Gap Filled:** Crowd comfort level  
**Use Cases:**
- Popular tourist spots vs. hidden gems (different from authenticity_preference)
- Peak hours vs. off-hours
- Busy festivals vs. quiet galleries
- Packed bars vs. intimate lounges

**Impact on Recommendations:**
- Time-of-day suggestions
- Popularity-aware recommendations
- Better experience fit
- Example: Recommend busy brunch spot to high crowd tolerance, quiet cafe to low

---

## 🔍 **Impact Analysis**

### **Affected Components:**

| Component | Impact Level | Changes Required | Migration Needed |
|-----------|-------------|------------------|------------------|
| **VibeConstants** | HIGH | Add 4 dimensions | No |
| **PersonalityProfile** | HIGH | Initialize 4 new dimensions | Yes - existing profiles |
| **VibeAnalysisEngine** | HIGH | Add compilation logic | No |
| **PersonalityLearning** | MEDIUM | Learning algorithms extend automatically | No |
| **Compatibility Calculation** | LOW | Automatically includes new dimensions | No |
| **Archetypes** | MEDIUM | Update archetype definitions | No |
| **User Data Storage** | HIGH | Migrate existing profiles | Yes - critical |
| **Tests** | HIGH | Update all dimension tests | No |
| **Supabase Functions** | LOW | May need personality context updates | Maybe |
| **UI/Admin** | LOW | Admin personality viewer needs update | No |

---

## 📁 **Files That Will Be Modified**

### **Core Files (Critical):**

#### **1. `/lib/core/constants/vibe_constants.dart`**
**Changes:**
- Add 4 dimensions to `coreDimensions` list
- Update archetypes to include new dimensions (optional initially)
- Update documentation comments

**Impact:** HIGH - Foundation of personality system  
**Risk:** LOW - Additive change, doesn't break existing  
**Test Coverage:** Extensive

---

#### **2. `/lib/core/models/personality_profile.dart`**
**Changes:**
- Update documentation from "8 core dimensions" → "12 core dimensions"
- No code changes needed (dynamically uses VibeConstants.coreDimensions)

**Impact:** LOW - Documentation only  
**Risk:** NONE  
**Test Coverage:** Automatic via VibeConstants

---

#### **3. `/lib/core/ai/vibe_analysis_engine.dart`**
**Changes:**
- Add compilation logic for 4 new dimensions
- Map behavioral signals to new dimensions
- Update `_compileVibeDimensions()` method

**Impact:** HIGH - Must define how to calculate new dimensions  
**Risk:** MEDIUM - Logic must be correct for good matching  
**Test Coverage:** New tests required

**Example Implementation:**
```dart
// Add to _compileVibeDimensions()

// Compile energy preference
vibeDimensions['energy_preference'] = (
  behavioral.activityLevel * 0.7 +
  temporal.timeOfDayPattern * 0.3
).clamp(0.0, 1.0);

// Compile novelty seeking  
vibeDimensions['novelty_seeking'] = (
  behavioral.repeatVisitTendency * -1.0 + 1.0  // Invert: low repeat = high novelty
).clamp(0.0, 1.0);

// Compile value orientation
vibeDimensions['value_orientation'] = (
  behavioral.priceRangePreference * 0.8 +
  behavioral.luxuryIndicators * 0.2
).clamp(0.0, 1.0);

// Compile crowd tolerance
vibeDimensions['crowd_tolerance'] = (
  behavioral.popularityPreference * 0.6 +
  temporal.peakHoursTendency * 0.4
).clamp(0.0, 1.0);
```

---

#### **4. `/lib/core/ai/personality_learning.dart`**
**Changes:**
- **None required** - dynamically uses VibeConstants.coreDimensions
- Automatically includes new dimensions in learning
- Evolution logic extends naturally

**Impact:** NONE - Automatic extension  
**Risk:** NONE  
**Test Coverage:** Existing tests cover

---

#### **5. `/lib/core/models/user_vibe.dart`**
**Changes:**
- May need to add behavioral signals if not present:
  - `activityLevel`
  - `repeatVisitTendency`
  - `priceRangePreference`
  - `popularityPreference`
  - `luxuryIndicators`

**Impact:** MEDIUM - Depends on existing signals  
**Risk:** MEDIUM - May need new data collection  
**Test Coverage:** New signals need tests

---

### **Test Files (Update Required):**

#### **6. All Test Files Using Dimensions:**
**Files:**
- `test/unit/models/personality_profile_test.dart`
- `test/unit/ai2ai/personality_learning_system_test.dart`
- `test/unit/ai2ai/personality_learning_test.dart`
- `test/unit/ai/vibe_analysis_engine_test.dart`
- `test/fixtures/model_factories.dart`
- All integration tests

**Changes:**
- Update expectations: `8` → `12` dimensions
- Add test cases for new dimensions
- Update mock data to include 4 new dimensions

**Impact:** HIGH - Many tests to update  
**Risk:** LOW - Mechanical updates  
**Test Coverage:** Tests validate themselves

---

### **Documentation Files (Update):**

#### **7. `/docs/_archive/vibe_coding/VIBE_CODING/DIMENSIONS/core_dimensions.md`**
**Changes:**
- Add detailed descriptions of 4 new dimensions
- Include examples and impact on behavior
- Update "8 core dimensions" → "12 core dimensions"

**Impact:** LOW - Documentation  
**Risk:** NONE

---

#### **8. `/docs/CONTEXTUAL_PERSONALITY_SYSTEM.md`**
**Changes:**
- Update references to dimension count
- Ensure new dimensions work with contextual layers

**Impact:** LOW  
**Risk:** NONE

---

### **Optional Updates (Enhancement):**

#### **9. `/lib/core/constants/vibe_constants.dart` - Archetypes**
**Changes:**
- Update 5 existing archetypes with new dimensions
- Add 2-3 new archetypes that leverage new dimensions

**Examples:**
```dart
'chill_local': {
  'energy_preference': 0.2,          // Low energy
  'novelty_seeking': 0.3,            // Loves favorites
  'crowd_tolerance': 0.3,            // Prefers quiet
  'authenticity_preference': 0.9,    // Authentic spots
},
'luxury_explorer': {
  'value_orientation': 0.9,          // Premium experiences
  'exploration_eagerness': 0.8,      // Adventurous
  'energy_preference': 0.6,          // Moderate energy
  'authenticity_preference': 0.7,    // Quality matters
},
```

**Impact:** LOW - Enhancement only  
**Risk:** NONE

---

#### **10. Supabase Functions**
**Files:**
- `supabase/functions/llm-chat/index.ts`
- `supabase/functions/llm-chat-stream/index.ts`

**Changes:**
- May need to update personality context prompts
- Include new dimensions in AI chat context

**Impact:** LOW - Optional enhancement  
**Risk:** LOW

---

## 🔄 **Migration Strategy**

### **The Challenge:**
Existing users have 8-dimensional personality profiles stored. We need to add 4 new dimensions without losing existing data.

### **Migration Approach: Gradual Fill**

#### **Step 1: Deploy Code (Backward Compatible)**
```dart
// PersonalityProfile.initial() already handles this!
factory PersonalityProfile.initial(String userId) {
  final initialDimensions = <String, double>{};
  final initialConfidence = <String, double>{};
  
  for (final dimension in VibeConstants.coreDimensions) {
    initialDimensions[dimension] = VibeConstants.defaultDimensionValue;
    initialConfidence[dimension] = 0.0;
  }
  
  return PersonalityProfile(...);
}
```

**Result:** New users automatically get 12 dimensions.

---

#### **Step 2: Backfill Existing Users (Automatic)**
When existing profiles load, add missing dimensions:

```dart
// Add to PersonalityProfile.fromJson()
factory PersonalityProfile.fromJson(Map<String, dynamic> json) {
  final dimensions = Map<String, double>.from(json['dimensions']);
  final confidence = Map<String, double>.from(json['dimensionConfidence']);
  
  // MIGRATION: Add missing dimensions with defaults
  for (final dimension in VibeConstants.coreDimensions) {
    if (!dimensions.containsKey(dimension)) {
      dimensions[dimension] = VibeConstants.defaultDimensionValue;
      confidence[dimension] = 0.0;
    }
  }
  
  return PersonalityProfile(
    dimensions: dimensions,
    dimensionConfidence: confidence,
    // ... other fields
  );
}
```

**Result:** Existing profiles automatically upgraded on load.

---

#### **Step 3: Learn New Dimensions Naturally**
As users interact with the app:
- Behavioral signals feed into new dimensions
- VibeAnalysisEngine calculates values
- PersonalityLearning evolves dimensions
- Confidence scores build over time

**Timeline:** 1-2 weeks for confidence > 0.6

---

### **No Data Loss:**
✅ Existing 8 dimensions preserved  
✅ New 4 dimensions added with defaults  
✅ Confidence starts at 0.0 (uncertain)  
✅ Learning happens automatically  
✅ No user action required  

---

## 🧪 **Testing Strategy**

### **Phase 1: Unit Tests (2 days)**

#### **Test New Dimension Constants:**
```dart
test('should have 12 core dimensions', () {
  expect(VibeConstants.coreDimensions.length, equals(12));
  expect(VibeConstants.coreDimensions, contains('energy_preference'));
  expect(VibeConstants.coreDimensions, contains('novelty_seeking'));
  expect(VibeConstants.coreDimensions, contains('value_orientation'));
  expect(VibeConstants.coreDimensions, contains('crowd_tolerance'));
});
```

#### **Test Profile Initialization:**
```dart
test('should initialize with 12 dimensions', () {
  final profile = PersonalityProfile.initial('test-user');
  expect(profile.dimensions.length, equals(12));
  expect(profile.dimensions['energy_preference'], equals(0.5));
  expect(profile.dimensionConfidence['energy_preference'], equals(0.0));
});
```

#### **Test Migration:**
```dart
test('should backfill missing dimensions from old profiles', () {
  // Create old 8-dimension profile
  final oldJson = {
    'userId': 'test-user',
    'dimensions': {
      'exploration_eagerness': 0.7,
      // ... only 8 dimensions
    },
    'dimensionConfidence': {
      'exploration_eagerness': 0.8,
      // ... only 8 dimensions
    },
  };
  
  final profile = PersonalityProfile.fromJson(oldJson);
  
  // Should now have 12 dimensions
  expect(profile.dimensions.length, equals(12));
  expect(profile.dimensions['energy_preference'], equals(0.5)); // Default
  expect(profile.dimensionConfidence['energy_preference'], equals(0.0)); // Uncertain
  
  // Old dimensions preserved
  expect(profile.dimensions['exploration_eagerness'], equals(0.7));
  expect(profile.dimensionConfidence['exploration_eagerness'], equals(0.8));
});
```

#### **Test Vibe Compilation:**
```dart
test('should compile all 12 dimensions', () async {
  final vibeDimensions = await vibeAnalyzer._compileVibeDimensions(...);
  expect(vibeDimensions.length, equals(12));
  expect(vibeDimensions.containsKey('energy_preference'), isTrue);
  expect(vibeDimensions['energy_preference'], inInclusiveRange(0.0, 1.0));
});
```

#### **Test Compatibility:**
```dart
test('should calculate compatibility with 12 dimensions', () {
  final profile1 = PersonalityProfile.initial('user1');
  final profile2 = PersonalityProfile.initial('user2');
  
  // Manually set all 12 dimensions with confidence
  // ... 
  
  final compatibility = profile1.calculateCompatibility(profile2);
  expect(compatibility, inInclusiveRange(0.0, 1.0));
});
```

---

### **Phase 2: Integration Tests (1 day)**

#### **Test End-to-End Profile Evolution:**
```dart
test('should evolve new dimensions through user actions', () async {
  final profile = await personalityLearning.initializePersonality('user');
  
  // Simulate user actions that affect new dimensions
  await personalityLearning.evolveFromUserAction(
    'user',
    UserAction(type: UserActionType.spotVisit, metadata: {
      'energy_level': 'high',      // → energy_preference
      'is_repeat_visit': false,    // → novelty_seeking
      'price_range': 'premium',    // → value_orientation
      'crowd_level': 'busy',       // → crowd_tolerance
    }),
  );
  
  final updated = await personalityLearning.getCurrentPersonality('user');
  
  // New dimensions should have evolved
  expect(updated!.dimensions['energy_preference'], isNot(equals(0.5)));
  expect(updated.dimensionConfidence['energy_preference'], greaterThan(0.0));
});
```

#### **Test AI2AI Learning with New Dimensions:**
```dart
test('should learn new dimensions from AI2AI connections', () async {
  // Create two profiles with different new dimension values
  final localProfile = PersonalityProfile.initial('local');
  final remoteProfile = PersonalityProfile.initial('remote');
  
  // Set remote with high energy, local with low
  // ...
  
  // Perform AI2AI learning
  final insight = await protocol.generateLocalLearningInsights(
    localProfile,
    remoteProfile,
    compatibility,
  );
  
  // Should include new dimensions
  expect(insight.dimensionInsights.containsKey('energy_preference'), isTrue);
});
```

---

### **Phase 3: Manual Testing (1 day)**

#### **Test Migration:**
1. Load app with existing 8-dimension profile
2. Verify 4 new dimensions added with defaults
3. Verify existing 8 dimensions unchanged
4. Perform actions that affect new dimensions
5. Verify learning occurs correctly

#### **Test Recommendations:**
1. Create profile with extreme new dimension values
2. Verify spot recommendations reflect preferences
3. Example: High energy preference → fitness/activity spots
4. Example: Low crowd tolerance → quiet, off-peak suggestions

---

## 📅 **Implementation Timeline**

### **Day 1: Core Updates**
- [ ] Update `VibeConstants.coreDimensions` to include 4 new dimensions
- [ ] Update documentation in `PersonalityProfile`
- [ ] Add migration logic to `PersonalityProfile.fromJson()`
- [ ] Update unit tests for constants and models

**Deliverables:**
- 12 dimensions defined
- Migration logic in place
- Tests passing

---

### **Day 2: Vibe Analysis Logic**
- [ ] Add compilation logic for 4 new dimensions in `VibeAnalysisEngine`
- [ ] Add behavioral signals if missing in `UserVibe`
- [ ] Test vibe compilation

**Deliverables:**
- New dimensions calculated from behavior
- Vibe analysis tests passing

---

### **Day 3: Test Updates**
- [ ] Update all test files with 12-dimension expectations
- [ ] Add tests for new dimensions
- [ ] Update test fixtures and factories
- [ ] Ensure all tests pass

**Deliverables:**
- All tests updated and passing
- New dimension tests added

---

### **Day 4: Integration & Migration**
- [ ] Test migration with real profile data
- [ ] Test AI2AI learning with new dimensions
- [ ] Test compatibility calculation
- [ ] Manual testing

**Deliverables:**
- Migration validated
- Integration tests passing
- Manual testing complete

---

### **Day 5: Documentation & Optional Enhancements**
- [ ] Update `docs/_archive/vibe_coding/VIBE_CODING/DIMENSIONS/core_dimensions.md`
- [ ] Update `CONTEXTUAL_PERSONALITY_SYSTEM.md`
- [ ] Optional: Update archetypes
- [ ] Optional: Update Supabase functions
- [ ] Create migration guide

**Deliverables:**
- Documentation complete
- Optional enhancements done
- Migration guide published

---

## ⚠️ **Risks & Mitigation**

### **Risk 1: Behavioral Signals Missing**
**Risk:** New dimensions need signals that don't exist yet  
**Impact:** HIGH - Can't calculate dimensions  
**Mitigation:**
- Audit existing behavioral signals first
- Add missing signals if needed
- Use proxy signals initially (e.g., time-of-day as energy proxy)
- Gradually refine signals over time

---

### **Risk 2: Compatibility Calculation Changes**
**Risk:** Adding dimensions might change existing compatibility scores  
**Impact:** MEDIUM - User matches might change  
**Mitigation:**
- Compatibility algorithm uses confidence-weighted averaging
- New dimensions start with 0.0 confidence
- Initially have minimal impact
- Impact grows as confidence builds
- Gradual, not sudden change

---

### **Risk 3: Test Coverage Gaps**
**Risk:** Miss updating some tests  
**Impact:** MEDIUM - Flaky tests  
**Mitigation:**
- Comprehensive grep for dimension count references
- Update all at once
- Run full test suite multiple times

---

### **Risk 4: Performance Impact**
**Risk:** 50% more dimensions = more computation  
**Impact:** LOW - Modern devices handle easily  
**Mitigation:**
- Profile performance before/after
- Optimize if needed (unlikely)
- Dimensions processed in parallel already

---

## ✅ **Success Criteria**

### **Functional:**
- [ ] 12 dimensions defined in VibeConstants
- [ ] New profiles initialize with 12 dimensions
- [ ] Old profiles migrate to 12 dimensions automatically
- [ ] Vibe analysis compiles all 12 dimensions
- [ ] Compatibility calculation includes new dimensions
- [ ] Personality learning evolves all 12 dimensions
- [ ] AI2AI learning transfers all 12 dimensions

### **Technical:**
- [ ] All unit tests passing
- [ ] All integration tests passing
- [ ] No compilation errors
- [ ] No linter warnings
- [ ] Test coverage > 80% for new code
- [ ] Performance impact < 10%

### **Data:**
- [ ] No data loss during migration
- [ ] Existing 8 dimensions preserved
- [ ] New 4 dimensions added with defaults
- [ ] Confidence scores start at 0.0
- [ ] Learning occurs over 1-2 weeks

### **Quality:**
- [ ] Better spot matching (subjective)
- [ ] More precise compatibility (measurable)
- [ ] No user-facing errors
- [ ] Smooth migration experience

---

## 📊 **Expected Outcomes**

### **For Users:**
✅ Better door recommendations (energy, price, crowd level match YOU)  
✅ More accurate people matching (find others who open similar doors)  
✅ Seamless migration (no action required)  
✅ Richer personality expression (12 dimensions = more precise)  
✅ AI adapts to YOUR usage (community discovery vs. quick recommendations)  
✅ Spots → Community → Life journey works better  

### **For System:**
✅ More sophisticated door-matching algorithm  
✅ Better understanding of usage patterns  
✅ Foundation for future dimensions  
✅ Maintains backward compatibility  
✅ Scalable architecture  

### **For Business:**
✅ Better doors shown → higher engagement  
✅ More precise matching → more connections → more community  
✅ Competitive advantage (understanding individual door preferences)  
✅ Foundation for life enrichment features  

---

## 🔍 **Backward Compatibility**

### **Guaranteed:**
✅ **No breaking changes** - Additive only  
✅ **Existing profiles work** - Automatic migration  
✅ **No API changes** - Internal only  
✅ **Tests update easily** - Mechanical changes  
✅ **No user action required** - Transparent  

### **Version Compatibility:**
```dart
// Old profile (8 dimensions) loading in new code (12 dimensions)
{
  "dimensions": {
    "exploration_eagerness": 0.7,
    // ... 7 more dimensions
    // 4 new dimensions MISSING
  }
}

// Automatically becomes:
{
  "dimensions": {
    "exploration_eagerness": 0.7,     // PRESERVED
    // ... 7 more preserved dimensions
    "energy_preference": 0.5,         // ADDED with default
    "novelty_seeking": 0.5,           // ADDED with default
    "value_orientation": 0.5,         // ADDED with default
    "crowd_tolerance": 0.5,           // ADDED with default
  },
  "dimensionConfidence": {
    "exploration_eagerness": 0.8,     // PRESERVED
    // ... 7 more preserved
    "energy_preference": 0.0,         // ADDED (uncertain)
    "novelty_seeking": 0.0,           // ADDED (uncertain)
    "value_orientation": 0.0,         // ADDED (uncertain)
    "crowd_tolerance": 0.0,           // ADDED (uncertain)
  }
}
```

---

## 📚 **Related Documentation**

- `docs/_archive/vibe_coding/VIBE_CODING/DIMENSIONS/core_dimensions.md` - Dimension definitions
- `docs/CONTEXTUAL_PERSONALITY_SYSTEM.md` - Contextual layers
- `docs/OFFLINE_AI2AI_IMPLEMENTATION_PLAN.md` - AI2AI system
- `lib/core/constants/vibe_constants.dart` - Current constants
- `lib/core/models/personality_profile.dart` - Profile model

---

## 🚀 **Next Steps**

1. ✅ Review this plan with team
2. ✅ Decide on implementation timing
3. ✅ Assign developer
4. ✅ Create feature branch: `feature/12-personality-dimensions`
5. ✅ Follow day-by-day timeline
6. 🚀 Implement, test, deploy

---

**Status:** Ready for implementation  
**Blockers:** None  
**Dependencies:** None (standalone enhancement)  
**Estimated Effort:** 5-7 days  
**Risk Level:** LOW (backward compatible)  

*This expansion enables more precise door matching—the key works better to help users find the spots, communities, and experiences that truly resonate with them. Whether they're looking for a quick restaurant recommendation or discovering their third place community, the 12 dimensions help the key open the right doors at the right time. Full backward compatibility maintained.*

---

## 🔗 **Cross-References to Other Plans**

**This plan connects to:**

### **→ Easy Event Hosting Plan**
**Why:** Events attended reveal personality dimensions

**Examples:**
- 🎵 **User attends indie concert** → Update `energy_preference` (venue vibe), `crowd_tolerance` (festival vs. small venue), `value_orientation` (ticket price)
- 🎨 **User hosts gallery opening** → Update `social_discovery_style` (curation), `authenticity_preference` (art style)
- ⚽ **User attends sports event** → Update `energy_preference` (active participation), `crowd_tolerance` (stadium atmosphere)

**Action Item:** Event attendance/hosting should trigger vibe updates in these 4 new dimensions.

### **→ Contextual Personality Plan**
**Why:** Dimensions can vary by context

**Example:**
- Work context: Lower `energy_preference`, higher `crowd_tolerance`
- Social context: Higher `energy_preference`, variable `crowd_tolerance`
- Exploration context: Higher `novelty_seeking`, lower `value_orientation`

**Action Item:** Track how dimensions shift across contexts.

### **→ Offline AI2AI Plan**
**Why:** Offline learning needs to work with 12 dimensions

**Dependency:** Ensure offline learning algorithm handles 12 dimensions correctly.

**Action Item:** Test offline AI2AI with 12-dimension profiles.


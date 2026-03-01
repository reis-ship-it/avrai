# Archetype Template System Plan

**Date:** December 4, 2025  
**Status:** 🟢 **ACTIVE - READY FOR IMPLEMENTATION**  
**Purpose:** Create archetype templates for initial personality profile initialization to improve loading process and initial vibe quality

---

## 🚪 **DOORS PHILOSOPHY ALIGNMENT**

### **What Doors Does This Open?**

**1. Doors to Better Initial Understanding**
- Users get better initial personality profiles based on onboarding data
- AI has context about different personality archetypes when creating first vibe profiles
- Faster, more accurate initial recommendations

**2. Doors to Authentic Self-Expression**
- Users start with profiles that better match their interests
- Less "cold start" problem - users see value immediately
- Better initial AI2AI connections from the start

**3. Doors to Learning**
- AI learns from example archetypes what makes good profiles
- Central AI agent has reference profiles to guide creation
- System improves as it learns from real user patterns

### **When Are Users Ready for These Doors?**

**During Onboarding:**
- After user provides homebase, favorite places, preferences
- Before first vibe profile is created
- Template selection happens automatically based on onboarding data

**Progressive Enhancement:**
- Initial profile uses template as starting point
- Profile evolves naturally from there
- Templates are guides, not constraints

### **Is This Being a Good Key?**

**Yes, because:**
- ✅ Opens doors to better initial understanding (faster value)
- ✅ Opens doors to authentic self-expression (better matches)
- ✅ Opens doors to learning (AI improves)
- ✅ Respects user autonomy (templates guide, don't constrain)
- ✅ Preserves privacy (templates are general patterns, not user data)

### **Is the AI Learning With the User?**

**Yes:**
- AI learns from template patterns
- AI learns from how users evolve from templates
- AI learns which templates work best for which onboarding patterns
- System improves over time

---

## 🎯 **EXECUTIVE SUMMARY**

**Goal:** Create archetype template system that provides reference personality profiles for the central AI agent to use when creating initial vibe profiles, improving loading process and initial profile quality.

**Approach:** 
- **Option 2 (Primary):** Archetype templates based on general patterns (no external data scraping)
- **Option 1 (Future):** User-consented social media integration (as app learns and grows)
- **Option 3 (Future):** User-provided handles opt-in (in the mix)

**Timeline:** 1-2 weeks (can be done in parallel with other work)

---

## 🏗️ **ARCHITECTURE PRINCIPLES**

### **1. Privacy-First**
- ✅ Templates are general patterns, not user-specific data
- ✅ No external data scraping
- ✅ Templates based on general personality archetypes
- ✅ No personal information in templates

### **2. User Control**
- ✅ Templates guide, don't constrain
- ✅ Users can evolve beyond templates
- ✅ Templates are starting points, not destinations
- ✅ User data drives evolution, not templates

### **3. AI Learning**
- ✅ AI learns from template patterns
- ✅ AI learns from user evolution
- ✅ AI improves template matching over time
- ✅ Templates enhance, don't replace learning

### **4. Doors, Not Badges**
- ✅ Templates open doors to better initial understanding
- ✅ Templates enable authentic self-expression
- ✅ Templates support learning, not gamification
- ✅ Templates are tools, not goals

---

## 📋 **ARCHETYPE TEMPLATES**

### **Core Archetypes**

Based on existing test patterns and personality dimensions:

#### **1. Explorer Archetype**
- **Description:** High exploration, adventure-seeking, location-flexible
- **Dimensions:**
  - `exploration_eagerness`: 0.9
  - `community_orientation`: 0.6
  - `authenticity_preference`: 0.8
  - `social_discovery_style`: 0.7
  - `temporal_flexibility`: 0.8
  - `location_adventurousness`: 0.9
  - `curation_tendency`: 0.4
  - `trust_network_reliance`: 0.5
- **Onboarding Indicators:**
  - Multiple favorite places across different areas
  - Diverse preferences
  - Travel-related interests

#### **2. Community-Oriented Archetype**
- **Description:** High community engagement, social discovery, trust in networks
- **Dimensions:**
  - `exploration_eagerness`: 0.5
  - `community_orientation`: 0.9
  - `authenticity_preference`: 0.9
  - `social_discovery_style`: 0.8
  - `temporal_flexibility`: 0.6
  - `location_adventurousness`: 0.4
  - `curation_tendency`: 0.8
  - `trust_network_reliance`: 0.9
- **Onboarding Indicators:**
  - Strong local homebase preference
  - Community-focused preferences
  - Social activities emphasis

#### **3. Curator Archetype**
- **Description:** High curation, authenticity preference, careful selection
- **Dimensions:**
  - `exploration_eagerness`: 0.6
  - `community_orientation`: 0.7
  - `authenticity_preference`: 0.95
  - `social_discovery_style`: 0.5
  - `temporal_flexibility`: 0.4
  - `location_adventurousness`: 0.6
  - `curation_tendency`: 0.9
  - `trust_network_reliance`: 0.7
- **Onboarding Indicators:**
  - Specific, curated favorite places
  - Quality-focused preferences
  - Authentic experiences emphasis

#### **4. Balanced Archetype**
- **Description:** Moderate values across all dimensions (default fallback)
- **Dimensions:**
  - All dimensions: 0.5 (default)
- **Onboarding Indicators:**
  - No clear pattern
  - Mixed preferences
  - Default when no match

#### **5. Social Explorer Archetype**
- **Description:** High exploration + high social discovery
- **Dimensions:**
  - `exploration_eagerness`: 0.8
  - `community_orientation`: 0.7
  - `authenticity_preference`: 0.7
  - `social_discovery_style`: 0.9
  - `temporal_flexibility`: 0.7
  - `location_adventurousness`: 0.8
  - `curation_tendency`: 0.5
  - `trust_network_reliance`: 0.6
- **Onboarding Indicators:**
  - Social activities + exploration interests
  - Group-oriented preferences

#### **6. Local Expert Archetype**
- **Description:** High curation + high community orientation
- **Dimensions:**
  - `exploration_eagerness`: 0.5
  - `community_orientation`: 0.8
  - `authenticity_preference`: 0.9
  - `social_discovery_style`: 0.6
  - `temporal_flexibility`: 0.5
  - `location_adventurousness`: 0.5
  - `curation_tendency`: 0.9
  - `trust_network_reliance`: 0.8
- **Onboarding Indicators:**
  - Strong local focus
  - Deep knowledge interests
  - Quality curation emphasis

---

## 🔧 **TECHNICAL ARCHITECTURE**

### **1. Data Models**

#### **PersonalityArchetypeTemplate**
```dart
class PersonalityArchetypeTemplate {
  final String archetypeId; // 'explorer', 'community', 'curator', etc.
  final String name; // Display name
  final String description; // Archetype description
  final Map<String, double> dimensionDefaults; // Default dimension values
  final Map<String, double> dimensionConfidence; // Initial confidence (low)
  final List<String> onboardingIndicators; // Keywords/patterns that match
  final Map<String, double> indicatorWeights; // How much each indicator matters
  final DateTime createdAt;
  final DateTime lastUpdated;
  final int usageCount; // How many times used (for learning)
  final double successScore; // How well this template works (0.0-1.0)
}
```

### **2. Services**

#### **ArchetypeTemplateService**
- Load archetype templates
- Match onboarding data to templates
- Create initial profile from template
- Track template usage and success
- Learn from user evolution patterns

#### **TemplateMatchingService**
- Analyze onboarding data (homebase, favorite places, preferences)
- Score each template against onboarding data
- Select best matching template
- Adjust template based on specific user data

### **3. Integration Points**

#### **Personality Learning System**
- **File:** `lib/core/ai/personality_learning.dart`
- **Integration:** Use template when initializing new personality
- **Changes:** Add template selection in `initializePersonality()`
- **Privacy:** Templates are general patterns, not user data

#### **AI Loading Page**
- **File:** `lib/presentation/pages/onboarding/ai_loading_page.dart`
- **Integration:** Select template during loading process
- **Changes:** Add template selection before personality initialization
- **User Experience:** Seamless - happens automatically

#### **Vibe Analysis Engine**
- **File:** `lib/core/ai/vibe_analysis_engine.dart`
- **Integration:** Templates provide context for vibe compilation
- **Changes:** No changes needed (templates already in personality profile)
- **Privacy:** Templates are general patterns

---

## 📊 **TEMPLATE MATCHING ALGORITHM**

### **Matching Process**

```
Onboarding Data (homebase, favorite places, preferences)
  ↓
1. Extract keywords/patterns from onboarding data
2. Score each template against extracted patterns
3. Select template with highest score
4. Adjust template dimensions based on specific user data
5. Create initial personality profile from adjusted template
6. Initialize vibe profile from personality profile
```

### **Scoring Algorithm**

**For each template:**
1. **Keyword Matching:** Count matching keywords from onboarding data
2. **Pattern Matching:** Score based on preference patterns
3. **Location Analysis:** Score based on homebase characteristics
4. **Weighted Score:** Combine all factors with weights
5. **Confidence:** Calculate confidence in match (0.0-1.0)

**Formula:**
```
score = (keywordMatch * 0.3) + (patternMatch * 0.3) + (locationMatch * 0.2) + (preferenceMatch * 0.2)
```

### **Template Adjustment**

**After selecting template:**
1. Use template dimensions as base
2. Adjust based on specific user data:
   - Favorite places → location_adventurousness
   - Preferences → community_orientation, curation_tendency
   - Homebase → location preferences
3. Keep confidence low initially (0.0-0.3)
4. Let user actions evolve profile naturally

---

## 🗄️ **DATA STORAGE**

### **Template Storage**

**Option 1: Hardcoded (Initial)**
- Templates defined in code
- Easy to update
- No database needed
- Fast access

**Option 2: Database (Future)**
- Store templates in database
- Allow dynamic updates
- Track usage and success
- Learn from patterns

### **Template Usage Tracking**

**Track:**
- Which template was selected for each user
- How well template matched (initial score)
- How user evolved from template
- Template success metrics

**Use for:**
- Improving template matching
- Learning which templates work best
- Refining template dimensions
- Creating new templates

---

## 📅 **IMPLEMENTATION PHASES**

### **Phase 1: Core Template System (Week 1)**

#### **Day 1-2: Template Definitions**
- [ ] Define archetype templates (6 core archetypes)
- [ ] Create `PersonalityArchetypeTemplate` model
- [ ] Create template data structures
- [ ] Add template constants

#### **Day 3-4: Template Service**
- [ ] Create `ArchetypeTemplateService`
- [ ] Implement template loading
- [ ] Implement template matching algorithm
- [ ] Add template selection logic

#### **Day 5: Integration**
- [ ] Integrate with `PersonalityLearning.initializePersonality()`
- [ ] Integrate with `AILoadingPage`
- [ ] Add template selection to loading flow
- [ ] Test template matching

**Deliverables:**
- ✅ Template system functional
- ✅ Templates integrated into initialization
- ✅ Template matching working

---

### **Phase 2: Template Learning & Refinement (Week 2)**

#### **Day 1-2: Usage Tracking**
- [ ] Add template usage tracking
- [ ] Track template selection per user
- [ ] Track template success metrics
- [ ] Store tracking data

#### **Day 3-4: Template Refinement**
- [ ] Analyze template usage patterns
- [ ] Refine template dimensions based on usage
- [ ] Improve matching algorithm
- [ ] Add new templates if needed

#### **Day 5: Testing & Polish**
- [ ] Test template matching accuracy
- [ ] Test profile evolution from templates
- [ ] Polish user experience
- [ ] Documentation

**Deliverables:**
- ✅ Template learning system functional
- ✅ Templates refined based on usage
- ✅ Improved matching accuracy

---

## 🔗 **INTEGRATION WITH EXISTING SYSTEMS**

### **Personality Learning System**
- **File:** `lib/core/ai/personality_learning.dart`
- **Method:** `initializePersonality()`
- **Change:** Add template selection before creating initial profile
- **Flow:**
  ```
  Check for existing profile
    ↓
  If new user:
    Get onboarding data
    Select template
    Create profile from template
    Save profile
  ```

### **AI Loading Page**
- **File:** `lib/presentation/pages/onboarding/ai_loading_page.dart`
- **Integration:** Template selection happens during loading
- **User Experience:** Seamless - no user interaction needed
- **Timing:** After onboarding data collected, before personality initialization

### **Vibe Analysis Engine**
- **File:** `lib/core/ai/vibe_analysis_engine.dart`
- **Integration:** No changes needed
- **Benefit:** Better initial personality = better initial vibe
- **Privacy:** Templates are general patterns

---

## 🔄 **FUTURE ENHANCEMENTS**

### **Option 1: Social Media Integration (Future)**
- User-consented social media connection
- Use social media interests to refine template selection
- Enhance template matching with social data
- **Timeline:** After social media integration plan (Phase 12)

### **Option 3: User-Provided Handles (Future)**
- User can optionally provide public social media handles
- Analyze public posts (with consent) to refine template
- Enhance initial profile quality
- **Timeline:** After social media integration plan (Phase 12)

### **Template Learning System**
- Learn from user evolution patterns
- Automatically refine templates
- Create new templates based on patterns
- Improve matching algorithm over time

---

## ✅ **SUCCESS CRITERIA**

### **Phase 1: Core Template System**
- ✅ Templates defined and functional
- ✅ Template matching algorithm working
- ✅ Integration with personality initialization complete
- ✅ Initial profiles use templates

### **Phase 2: Template Learning & Refinement**
- ✅ Template usage tracking functional
- ✅ Template refinement working
- ✅ Improved matching accuracy
- ✅ Better initial profile quality

---

## 📚 **RELATED DOCUMENTATION**

### **Philosophy & Architecture**
- `docs/plans/philosophy_implementation/SPOTS_PHILOSOPHY_AND_ARCHITECTURE.md`
- `docs/plans/philosophy_implementation/DOORS.md`
- `OUR_GUTS.md`

### **Existing Systems**
- `lib/core/ai/personality_learning.dart`
- `lib/core/ai/vibe_analysis_engine.dart`
- `lib/presentation/pages/onboarding/ai_loading_page.dart`
- `lib/core/models/personality_profile.dart`

### **Related Plans**
- `docs/plans/social_media_integration/SOCIAL_MEDIA_INTEGRATION_PLAN.md` (Option 1 & 3)

---

## 🎯 **NEXT STEPS**

1. **Review Plan** - Review and approve implementation approach
2. **Add to Master Plan Tracker** - Add entry to `docs/MASTER_PLAN_TRACKER.md`
3. **Master Plan Integration** - Integrate into Master Plan execution sequence
4. **Begin Implementation** - Start Phase 1 when ready

---

**Status:** ✅ **PLAN COMPLETE - READY FOR IMPLEMENTATION**  
**Last Updated:** December 4, 2025  
**Priority:** HIGH (improves initial user experience)


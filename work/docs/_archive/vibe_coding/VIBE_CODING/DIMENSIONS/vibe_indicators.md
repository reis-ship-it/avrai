# Vibe Indicators

## 🎯 **OVERVIEW**

Vibe Indicators are aggregated metrics that provide high-level insights into user vibe. These indicators compile information from personality dimensions, social dynamics, relationship patterns, and behavioral data into key vibe characteristics.

## 📊 **CORE VIBE INDICATORS**

### **Primary Indicators**

1. **Overall Energy** - Overall energy level and activity
2. **Social Preference** - Preference for social vs solo experiences
3. **Exploration Tendency** - Tendency to explore and discover
4. **Vibe Archetype** - Personality archetype classification

### **Vibe Metrics**

```dart
class UserVibe {
  final double overallEnergy;
  final double socialPreference;
  final double explorationTendency;
  final String temporalContext;
  // ... other metrics
}
```

## ⚡ **OVERALL ENERGY**

### **Energy Calculation**

```dart
overallEnergy = _calculateOverallEnergy(anonymizedDimensions);
```

**Factors:**
- **Exploration Eagerness** - High exploration = high energy
- **Temporal Flexibility** - Flexibility indicates energy
- **Activity Level** - Recent activity levels
- **Temporal Context** - Time of day, day of week

### **Energy Levels**

- **0.0-0.3** - Low energy, relaxed pace
- **0.3-0.6** - Moderate energy, balanced
- **0.6-0.8** - High energy, active
- **0.8-1.0** - Very high energy, very active

### **Energy Indicators**

- **Activity Frequency** - How often user is active
- **Spot Visit Frequency** - Frequency of spot visits
- **Exploration Rate** - Rate of new discoveries
- **Temporal Patterns** - Energy patterns over time

## 👥 **SOCIAL PREFERENCE**

### **Preference Calculation**

```dart
socialPreference = _calculateSocialPreference(anonymizedDimensions);
```

**Factors:**
- **Community Orientation** - Primary factor
- **Social Discovery Style** - Strong influence
- **Relationship Patterns** - Connection depth
- **Behavioral Patterns** - Solo vs group behavior

### **Preference Spectrum**

- **0.0** - Strongly prefer solo experiences
- **0.5** - Balanced, comfortable with both
- **1.0** - Strongly prefer group experiences

## 🗺️ **EXPLORATION TENDENCY**

### **Tendency Calculation**

```dart
explorationTendency = _calculateExplorationTendency(anonymizedDimensions);
```

**Factors:**
- **Exploration Eagerness** - Primary factor
- **Location Adventurousness** - Strong influence
- **Temporal Flexibility** - Spontaneity factor
- **Behavioral Patterns** - Exploration behavior

### **Tendency Levels**

- **0.0-0.3** - Low exploration, prefers familiar
- **0.3-0.6** - Moderate exploration, balanced
- **0.6-0.8** - High exploration, seeks new experiences
- **0.8-1.0** - Very high exploration, always exploring

## 🎭 **VIBE ARCHETYPE**

### **Archetype Classification**

Vibe archetypes classify users into personality types:

- **The Explorer** - High exploration, moderate social
- **The Socialite** - High social, moderate exploration
- **The Authentic Seeker** - High authenticity, moderate exploration
- **The Curator** - High curation, moderate social
- **The Balanced** - Balanced across dimensions
- **The Specialist** - Strong preferences in specific areas

### **Archetype Calculation**

```dart
String getVibeArchetype() {
  // Analyze dimension patterns
  // Classify into archetype
  // Return archetype name
}
```

## ⏰ **TEMPORAL CONTEXT**

### **Context Factors**

- **Time of Day** - Morning, afternoon, evening, night
- **Day of Week** - Weekday vs weekend
- **Season** - Seasonal patterns
- **Current Energy** - Current energy level

### **Context Influence**

Temporal context influences:
- **Energy Levels** - Energy varies by time
- **Social Preference** - Social preferences by time
- **Exploration Tendency** - Exploration varies by context
- **Overall Vibe** - Vibe adapts to context

## 🔐 **PRIVACY-PRESERVING INDICATORS**

### **Anonymized Indicators**

All indicators are anonymized:
- **No Personal Data** - No identifiers in indicators
- **Aggregated Metrics** - Only aggregated metrics
- **Hashed Signatures** - Hashed vibe signatures
- **Temporal Expiration** - Indicators expire over time

### **Privacy Protection**

- **Differential Privacy** - Noise added to indicators
- **Temporal Windows** - Time-based anonymization
- **No Re-identification** - Cannot identify users
- **Secure Hashing** - SHA-256 hashing

## 🎯 **VIBE COMPILATION**

### **Compilation Process**

```dart
final vibe = UserVibe.fromPersonalityProfile(
  userId,
  personalityDimensions,
  contextualSalt: salt,
);
```

**Steps:**
1. **Anonymize Dimensions** - Apply privacy protection
2. **Calculate Indicators** - Compute vibe indicators
3. **Create Signature** - Generate hashed signature
4. **Set Expiration** - Set temporal expiration
5. **Return Vibe** - Return compiled vibe

## 🛠️ **IMPLEMENTATION**

### **Code Location**

- **Models:** `lib/core/models/user_vibe.dart`
- **Analysis:** `lib/core/ai/vibe_analysis_engine.dart`

### **Key Methods**

```dart
// Create vibe from personality
factory UserVibe.fromPersonalityProfile(
  String userId,
  Map<String, double> personalityDimensions,
  {String? contextualSalt}
)

// Calculate compatibility
double calculateVibeCompatibility(UserVibe other)

// Calculate AI pleasure potential
double calculateAIPleasurePotential(UserVibe other)

// Get vibe archetype
String getVibeArchetype()
```

## 📋 **USAGE EXAMPLES**

### **Compile User Vibe**

```dart
// Compile vibe from personality
final vibe = await vibeAnalyzer.compileUserVibe(userId, personality);

// Access vibe indicators
print('Energy: ${(vibe.overallEnergy * 100).round()}%');
print('Social Preference: ${(vibe.socialPreference * 100).round()}%');
print('Exploration: ${(vibe.explorationTendency * 100).round()}%');
print('Archetype: ${vibe.getVibeArchetype()}');
```

### **Calculate Compatibility**

```dart
// Calculate compatibility between vibes
final compatibility = localVibe.calculateVibeCompatibility(remoteVibe);
print('Compatibility: ${(compatibility * 100).round()}%');
```

## 🔮 **FUTURE ENHANCEMENTS**

- **Predictive Indicators** - Predict future vibe indicators
- **Contextual Indicators** - Context-aware indicators
- **Multi-Modal Indicators** - Indicators from multiple sources
- **Real-Time Indicators** - Real-time vibe indicator updates
- **Indicator Clustering** - Group users by indicator patterns

---

*Part of SPOTS AI2AI Personality Learning Network Dimensions*


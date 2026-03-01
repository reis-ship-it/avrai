# Spot Type Preferences

## 🎯 **OVERVIEW**

Spot Type Preferences analyze user preferences for different types of spots (restaurants, cafes, museums, etc.). These preferences are extracted from user behavior and used to enhance personality understanding and improve recommendations.

## 📊 **SPOT TYPES**

### **Supported Spot Types**

- **Restaurants** - Dining establishments
- **Cafes** - Coffee shops and cafes
- **Museums** - Museums and galleries
- **Movies** - Movie theaters
- **Shows** - Live shows and performances
- **Plays** - Theater productions
- **Music** - Music venues and concerts
- **Events** - Special events and gatherings
- **Outdoor Activities** - Parks, trails, outdoor spaces
- **Shopping** - Shopping venues
- **Wellness** - Spas, gyms, wellness centers
- **Nightlife** - Bars, clubs, nightlife venues

## 🔍 **PREFERENCE ANALYSIS**

### **Analysis Factors**

Preferences calculated from:

1. **Visit Frequency** - How often user visits this spot type
2. **Rating Patterns** - User ratings for this spot type
3. **Cuisine Preferences** - Specific cuisine preferences (for restaurants)
4. **Time Patterns** - When user visits this spot type
5. **Social Context** - Solo vs group visits

### **Preference Calculation**

```dart
preference = (
  visitFrequency * 0.4 +
  ratingPatterns * 0.4 +
  otherFactors * 0.2
)
```

### **Preference Range**

- **0.0-0.3** - Low preference, rarely visits
- **0.3-0.6** - Moderate preference, occasional visits
- **0.6-0.8** - High preference, frequent visits
- **0.8-1.0** - Very high preference, favorite type

## 🎯 **USAGE IN VIBE ANALYSIS**

### **Integration with Vibe**

Spot type preferences contribute to:
- **Exploration Eagerness** - High preferences indicate exploration
- **Social Discovery Style** - Group vs solo preferences
- **Authenticity Preference** - Popular vs authentic spots
- **Temporal Flexibility** - Time-based preferences

### **Vibe Compilation**

Preferences compiled into vibe dimensions:
- Used to understand user discovery patterns
- Helps predict future spot preferences
- Enhances compatibility matching
- Improves recommendation quality

## 📈 **PREFERENCE EVOLUTION**

### **Dynamic Preferences**

Preferences evolve based on:
- **New Visits** - Visits to new spot types
- **Feedback** - User feedback on experiences
- **Learning** - Learning from other AIs
- **Trends** - Emerging trends in preferences

### **Preference Confidence**

Each preference has confidence:
- **High Confidence** - Strong, consistent pattern
- **Medium Confidence** - Developing pattern
- **Low Confidence** - New or inconsistent pattern

## 🛠️ **IMPLEMENTATION**

### **Code Location**

- **Analysis:** `lib/core/ai/vibe_analysis_engine.dart`
- **Models:** `lib/core/models/user_vibe.dart`

### **Analysis Methods**

```dart
// Analyze spot type preferences (conceptual)
Future<Map<String, double>> analyzeSpotTypePreferences(String userId) {
  // Analyze visit frequency
  // Analyze rating patterns
  // Calculate preferences
  // Return preference map
}
```

## 📋 **USAGE EXAMPLES**

### **Get Preferences**

```dart
// Preferences are integrated into vibe analysis
final vibe = await vibeAnalyzer.compileUserVibe(userId, personality);

// Preferences influence vibe dimensions
final explorationEagerness = vibe.anonymizedDimensions['exploration_eagerness'];
// High exploration eagerness may indicate diverse spot preferences
```

## 🔮 **FUTURE ENHANCEMENTS**

- **Sub-Category Preferences** - More granular preferences
- **Seasonal Preferences** - Preferences by season
- **Contextual Preferences** - Preferences by context
- **Predictive Preferences** - Predict future preferences
- **Preference Clustering** - Group similar preferences

---

*Part of SPOTS AI2AI Personality Learning Network Dimensions*


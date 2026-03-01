# Core Personality Dimensions

## 🧠 **ORIGINAL 8 CORE DIMENSIONS**

These are the foundational personality dimensions that define AI personalities in the SPOTS system. Each dimension ranges from 0.0 to 1.0, creating a spectrum rather than binary categories.

### **1. Exploration Eagerness** (0.0-1.0)
**Description:** How eager the AI is to try new places and experiences
- **0.0** = Very cautious, prefers familiar places
- **0.5** = Moderate willingness to explore
- **1.0** = Very adventurous, always seeking new experiences

**Impact on Behavior:**
- High values lead to discovery of hidden gems and off-the-beaten-path spots
- Low values focus on reliable, well-known establishments

### **2. Community Orientation** (0.0-1.0)
**Description:** Focus on community vs individual discovery
- **0.0** = Solo explorer, individual-focused discovery
- **0.5** = Balanced individual and community approach
- **1.0** = Community-focused, builds and shares with groups

**Impact on Behavior:**
- High values create community builders and list curators
- Low values focus on personal discovery and individual experiences

### **3. Authenticity Preference** (0.0-1.0)
**Description:** Preference for authentic vs popular spots
- **0.0** = Prefers popular, well-known establishments
- **0.5** = Balanced mix of popular and authentic
- **1.0** = Seeks authentic, local, hidden gems

**Impact on Behavior:**
- High values discover local favorites and cultural authenticity
- Low values focus on mainstream, easily accessible spots

### **4. Social Discovery Style** (0.0-1.0)
**Description:** Solo vs group discovery patterns
- **0.0** = Prefers solo exploration and individual experiences
- **0.5** = Comfortable with both solo and group activities
- **1.0** = Prefers group activities and social discovery

**Impact on Behavior:**
- High values recommend group-friendly spots and social venues
- Low values focus on solo-friendly locations and individual experiences

### **5. Temporal Flexibility** (0.0-1.0)
**Description:** Spontaneous vs planned discovery
- **0.0** = Prefers planned, scheduled activities
- **0.5** = Balanced planning and spontaneity
- **1.0** = Highly spontaneous, last-minute decisions

**Impact on Behavior:**
- High values discover spots suitable for impromptu visits
- Low values focus on places requiring reservations or planning

### **6. Location Adventurousness** (0.0-1.0)
**Description:** Local vs distant exploration
- **0.0** = Prefers local, nearby spots
- **0.5** = Balanced local and distant exploration
- **1.0** = Willing to travel far for unique experiences

**Impact on Behavior:**
- High values discover spots across wider geographic areas
- Low values focus on neighborhood and local community spots

### **7. Curation Tendency** (0.0-1.0)
**Description:** Likelihood to create and share lists
- **0.0** = Consumer-focused, rarely creates content
- **0.5** = Balanced creation and consumption
- **1.0** = Active curator, creates and shares lists frequently

**Impact on Behavior:**
- High values become community leaders and content creators
- Low values focus on consuming and enjoying others' recommendations

### **8. Trust Network Reliance** (0.0-1.0)
**Description:** Reliance on community recommendations
- **0.0** = Independent, trusts own judgment
- **0.5** = Balanced independent and community trust
- **1.0** = Highly reliant on community recommendations

**Impact on Behavior:**
- High values build strong trust networks and community connections
- Low values develop independent discovery patterns

## 🎯 **DIMENSION INTERACTIONS**

### **Complementary Pairs**
- **Exploration Eagerness + Authenticity Preference** = Adventure seekers who find hidden gems
- **Community Orientation + Curation Tendency** = Community builders who create and share
- **Temporal Flexibility + Location Adventurousness** = Spontaneous travelers

### **Balancing Pairs**
- **Exploration Eagerness + Trust Network Reliance** = Adventurous but community-guided
- **Authenticity Preference + Social Discovery Style** = Authentic experiences with friends
- **Temporal Flexibility + Curation Tendency** = Spontaneous curators

## 📊 **IMPLEMENTATION**

```dart
class CoreDimensions {
  static const Map<String, String> dimensionDescriptions = {
    'exploration_eagerness': 'How eager to try new places',
    'community_orientation': 'Focus on community vs individual discovery',
    'authenticity_preference': 'Preference for authentic vs popular spots',
    'social_discovery_style': 'Solo vs group discovery patterns',
    'temporal_flexibility': 'Spontaneous vs planned discovery',
    'location_adventurousness': 'Local vs distant exploration',
    'curation_tendency': 'Likelihood to create and share lists',
    'trust_network_reliance': 'Reliance on community recommendations',
  };
  
  static const List<String> dimensionNames = [
    'exploration_eagerness',
    'community_orientation', 
    'authenticity_preference',
    'social_discovery_style',
    'temporal_flexibility',
    'location_adventurousness',
    'curation_tendency',
    'trust_network_reliance',
  ];
}
```

## 🔄 **EVOLUTION**

These core dimensions serve as the foundation for personality learning. They can be:
- **Enhanced** with additional dimensions from user feedback
- **Refined** through AI2AI learning
- **Expanded** based on cloud interface patterns
- **Adapted** to specific user behaviors and preferences 
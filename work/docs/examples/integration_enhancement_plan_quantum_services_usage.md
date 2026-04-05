# Integration and Enhancement Plan - Quantum Services Usage Examples

**Plan ID:** `integration_and_enhancement_plan_a81ba5e1`  
**Purpose:** Complete usage examples for all newly implemented quantum and knot services from the Integration and Enhancement Plan  
**Last Updated:** January 27, 2026  
**Status:** ✅ Complete  
**Related Plan:** `/Users/reisgordon/.cursor/plans/integration_and_enhancement_plan_a81ba5e1.plan.md`

---

## 📚 **Overview**

This document provides practical usage examples for all quantum and knot services implemented in the Integration and Enhancement Plan. These services enhance the SPOTS platform with advanced quantum matching, error correction, multi-scale state generation, temporal interference detection, and knot theory-based analytics.

---

## 🔬 **Quantum Services**

### **1. QuantumMLOptimizer**

**Purpose:** Optimizes quantum superposition weights, measurement thresholds, and basis selection using ML models.

**Basic Usage:**
```dart
import 'package:get_it/get_it.dart';
import 'package:avrai/core/ai/quantum/quantum_ml_optimizer.dart';
import 'package:avrai_core/models/quantum_entity_state.dart';

// Get service from DI
final optimizer = GetIt.instance<QuantumMLOptimizer>();

// Optimize superposition weights
final entityState = QuantumEntityState(
  entityId: 'user_123',
  entityType: QuantumEntityType.user,
  personalityState: {'openness': 0.8, 'conscientiousness': 0.6, ...},
  quantumVibeAnalysis: {},
  entityCharacteristics: {},
  location: null,
  timing: null,
  tAtomic: atomicTimestamp,
);

final optimizedWeights = await optimizer.optimizeSuperpositionWeights(
  entityState: entityState,
  useCase: QuantumUseCase.matching,
);

// Use optimized weights in superposition
// weights.shortTermWeight, weights.longTermWeight, etc.
```

**Optimize Measurement Threshold:**
```dart
final threshold = await optimizer.optimizeMeasurementThreshold(
  entityState: entityState,
  useCase: QuantumUseCase.matching,
);

// Use threshold for compatibility calculations
if (compatibilityScore > threshold) {
  // High compatibility
}
```

**Optimize Measurement Basis:**
```dart
final basisScores = await optimizer.optimizeMeasurementBasis(
  entityState: entityState,
  useCase: QuantumUseCase.matching,
);

// Use basis scores to select optimal measurement basis
final bestBasis = basisScores.entries
    .reduce((a, b) => a.value > b.value ? a : b)
    .key;
```

**Error Handling:**
```dart
try {
  final weights = await optimizer.optimizeSuperpositionWeights(
    entityState: entityState,
    useCase: QuantumUseCase.matching,
  );
} on MLModelNotAvailableException {
  // Fallback to default weights
  final defaultWeights = ScaleWeights(
    shortTermWeight: 0.3,
    longTermWeight: 0.4,
    contextualWeight: 0.3,
  );
} catch (e) {
  // Handle other errors
  print('Optimization failed: $e');
}
```

---

### **2. QuantumErrorCorrectionService**

**Purpose:** Applies quantum error correction codes to protect quantum states from decoherence.

**Basic Usage:**
```dart
import 'package:avrai/core/ai/quantum/quantum_error_correction_service.dart';
import 'package:avrai_core/models/quantum_error_correction_code.dart';

final errorCorrection = GetIt.instance<QuantumErrorCorrectionService>();

// Encode quantum state with error correction
final encodedState = await errorCorrection.encodeWithErrorCorrection(
  state: entityState,
  code: QuantumErrorCorrectionCode.threeQubitBitFlip,
);

// Decode and correct errors
final correctedState = await errorCorrection.decodeWithErrorCorrection(
  encodedState: encodedState,
  code: QuantumErrorCorrectionCode.threeQubitBitFlip,
);
```

**Using Different Codes:**
```dart
// Three-qubit bit flip code (detects and corrects bit flips)
final bitFlipEncoded = await errorCorrection.encodeWithErrorCorrection(
  state: entityState,
  code: QuantumErrorCorrectionCode.threeQubitBitFlip,
);

// Three-qubit phase flip code (detects and corrects phase flips)
final phaseFlipEncoded = await errorCorrection.encodeWithErrorCorrection(
  state: entityState,
  code: QuantumErrorCorrectionCode.threeQubitPhaseFlip,
);

// Shor code (detects and corrects both bit and phase flips)
final shorEncoded = await errorCorrection.encodeWithErrorCorrection(
  state: entityState,
  code: QuantumErrorCorrectionCode.shor,
);
```

**Error Detection:**
```dart
final hasError = await errorCorrection.detectErrors(
  encodedState: encodedState,
  code: QuantumErrorCorrectionCode.threeQubitBitFlip,
);

if (hasError) {
  print('Errors detected, correcting...');
  final corrected = await errorCorrection.decodeWithErrorCorrection(
    encodedState: encodedState,
    code: QuantumErrorCorrectionCode.threeQubitBitFlip,
  );
}
```

---

### **3. MultiScaleQuantumStateService**

**Purpose:** Generates quantum states at different temporal and contextual scales.

**Basic Usage:**
```dart
import 'package:avrai/core/ai/quantum/multi_scale_quantum_state_service.dart';
import 'package:avrai_core/models/personality_profile.dart';
import 'package:avrai_core/models/multi_scale_quantum_state.dart';

final multiScaleService = GetIt.instance<MultiScaleQuantumStateService>();

// Generate multi-scale states
final multiScaleState = await multiScaleService.generateMultiScaleStates(
  profile: userProfile,
  historicalData: historicalProfiles, // Optional
  contextualData: {
    ContextualScale.work: workProfile,
    ContextualScale.social: socialProfile,
  }, // Optional
);

// Access different scales
final shortTerm = multiScaleState.shortTerm;
final longTerm = multiScaleState.longTerm;
final workContext = multiScaleState.getStateForContext(ContextualScale.work);
```

**Combining Scales:**
```dart
// Combine scales with custom weights
final weights = ScaleWeights(
  shortTermWeight: 0.3,
  longTermWeight: 0.4,
  contextualWeight: 0.3,
);

final combinedState = await multiScaleService.combineScales(
  multiScaleState: multiScaleState,
  weights: weights,
  context: ContextualScale.work,
);
```

**Getting State for Specific Context:**
```dart
// Get state for specific context
final workState = await multiScaleService.getStateForContext(
  multiScaleState: multiScaleState,
  context: ContextualScale.work,
  weights: weights, // Optional
);
```

**Performance Optimization:**
```dart
// The service automatically generates states in parallel
// No additional configuration needed - uses Future.wait() internally

// Cache management
final stats = multiScaleService.getCacheStats();
print('Cache usage: ${stats['usage']}');

// Clear cache if needed
multiScaleService.clearCache();
```

---

### **4. TemporalInterferenceService**

**Purpose:** Detects and corrects temporal interference in quantum compatibility calculations.

**Basic Usage:**
```dart
import 'package:avrai/core/ai/quantum/temporal_interference_service.dart';
import 'package:avrai_core/models/quantum_temporal_state.dart';

final interferenceService = GetIt.instance<TemporalInterferenceService>();

// Create temporal states
final state1 = QuantumTemporalState(
  entityState: entityState1,
  timestamp: DateTime.now().subtract(Duration(days: 1)),
  tAtomic: atomicTimestamp1,
);

final state2 = QuantumTemporalState(
  entityState: entityState2,
  timestamp: DateTime.now(),
  tAtomic: atomicTimestamp2,
);

// Detect interference
final interference = await interferenceService.detectInterference(
  state1: state1,
  state2: state2,
);

if (interference.hasInterference) {
  print('Interference detected: ${interference.interferenceType}');
  print('Strength: ${interference.strength}');
}
```

**Correcting Interference:**
```dart
// Calculate interference-corrected compatibility
final correctedCompatibility = await interferenceService
    .calculateInterferenceCorrectedCompatibility(
  state1: state1,
  state2: state2,
  originalCompatibility: 0.75,
);

// Use corrected compatibility in matching
if (correctedCompatibility > 0.7) {
  // High compatibility after interference correction
}
```

**Interference Types:**
```dart
// Check interference type
if (interference.interferenceType == 'constructive') {
  // Constructive interference - enhances compatibility
} else if (interference.interferenceType == 'destructive') {
  // Destructive interference - reduces compatibility
}
```

---

## 🪢 **Knot Services**

### **5. WorldsheetComparisonService**

**Purpose:** Compares worldsheets and detects common patterns.

**Basic Usage:**
```dart
import 'package:avrai_knot/services/knot/worldsheet_comparison_service.dart';
import 'package:avrai_knot/models/knot/knot_worldsheet.dart';

final comparisonService = GetIt.instance<WorldsheetComparisonService>();

// Compare two worldsheets
final similarity = await comparisonService.compareWorldsheets(
  ws1: worldsheet1,
  ws2: worldsheet2,
);

print('Overall similarity: ${similarity.overallSimilarity}');
print('Stability similarity: ${similarity.stabilitySimilarity}');
print('Density similarity: ${similarity.densitySimilarity}');
print('User overlap: ${similarity.userOverlap}');
```

**Getting Similarity Metrics:**
```dart
final metrics = await comparisonService.calculateSimilarityMetrics(
  ws1: worldsheet1,
  ws2: worldsheet2,
);

// Access individual metrics
print('Overall: ${metrics['overall']}');
print('Stability: ${metrics['stability']}');
print('Evolution rate: ${metrics['evolutionRate']}');
```

**Detecting Common Patterns:**
```dart
final patterns = await comparisonService.detectCommonPatterns(
  worldsheets: [worldsheet1, worldsheet2, worldsheet3],
);

for (final pattern in patterns) {
  print('Pattern: ${pattern.patternType}');
  print('Description: ${pattern.description}');
  print('Confidence: ${pattern.confidence}');
}
```

**Performance Optimization (Caching):**
```dart
// Caching is automatic - results are cached for performance
// Check cache statistics
final stats = comparisonService.getCacheStats();
print('Cache size: ${stats['size']}/${stats['maxSize']}');

// Clear cache if needed
comparisonService.clearCache();

// Disable cache for specific comparison
final similarity = await comparisonService.compareWorldsheets(
  ws1: worldsheet1,
  ws2: worldsheet2,
  useCache: false, // Skip cache
);
```

---

### **6. WorldsheetAnalyticsService**

**Purpose:** Analyzes worldsheet evolution for patterns, cycles, and trends.

**Basic Usage:**
```dart
import 'package:avrai_knot/services/knot/worldsheet_analytics_service.dart';

final analyticsService = GetIt.instance<WorldsheetAnalyticsService>();

// Analyze worldsheet
final analytics = await analyticsService.analyzeWorldsheet(
  worldsheet: worldsheet,
);

// Access results
print('Patterns: ${analytics.patterns}');
print('Cycles: ${analytics.cycles.length}');
print('Average evolution rate: ${analytics.averageEvolutionRate}');
print('Stability trend: ${analytics.stabilityTrend.direction}');
```

**Accessing Trends:**
```dart
// Stability trend
final stabilityTrend = analytics.stabilityTrend;
print('Direction: ${stabilityTrend.direction}'); // 'increasing', 'decreasing', 'stable'
print('Strength: ${stabilityTrend.strength}');
print('Rate: ${stabilityTrend.rate}');

// Density trend
final densityTrend = analytics.densityTrend;
print('Density trend: ${densityTrend.direction}');
```

**Detected Cycles:**
```dart
for (final cycle in analytics.cycles) {
  print('Cycle type: ${cycle.type}');
  print('Period: ${cycle.period}');
  print('Amplitude: ${cycle.amplitude}');
  print('Confidence: ${cycle.confidence}');
}
```

**Performance Optimization (Sampling):**
```dart
// Service automatically samples large datasets (>1000 snapshots)
// Results are cached for performance

// Check cache statistics
final stats = analyticsService.getCacheStats();
print('Cache usage: ${stats['usage']}');

// Clear cache if needed
analyticsService.clearCache();
```

---

### **7. StringExportService**

**Purpose:** Exports string evolution data to JSON, CSV, and analytics formats.

**Basic Usage:**
```dart
import 'package:avrai_knot/services/knot/string_export_service.dart';
import 'package:avrai_knot/models/knot/knot_string.dart';

final exportService = GetIt.instance<StringExportService>();

// Export to JSON
final jsonPath = await exportService.exportStringToJSON(
  string: knotString,
  filename: 'user_string_export.json', // Optional
);

print('Exported to: $jsonPath');
```

**Export to CSV:**
```dart
// Export trajectory to CSV
final csvPath = await exportService.exportStringToCSV(
  string: knotString,
  timeStep: Duration(hours: 1), // Optional, default: 1 hour
  filename: 'string_trajectory.csv', // Optional
);

print('Exported to: $csvPath');
```

**Streaming for Large Exports:**
```dart
// Service automatically uses streaming for large time ranges (>10,000 points)
// No additional configuration needed

// Manually enable/disable streaming
final csvPath = await exportService.exportStringToCSV(
  string: knotString,
  timeStep: Duration(minutes: 30),
  useStreaming: true, // Force streaming
);
```

**Export Analytics:**
```dart
// Export string analytics
final analyticsPath = await exportService.exportStringAnalytics(
  string: knotString,
  filename: 'string_analytics.json', // Optional
);

print('Analytics exported to: $analyticsPath');
```

---

### **8. Worldsheet4DVisualizationService**

**Purpose:** Prepares 4D worldsheet data for visualization (3D space + time).

**Basic Usage:**
```dart
import 'package:avrai_knot/services/knot/worldsheet_4d_visualization_service.dart';
import 'package:avrai_knot/models/knot/worldsheet_4d_data.dart';

final visualizationService = GetIt.instance<Worldsheet4DVisualizationService>();

// Convert worldsheet to 4D data
final worldsheet4d = await visualizationService.convertTo4DData(
  worldsheet: worldsheet,
  timeStep: Duration(hours: 1), // Optional, for interpolation
);

// Access time points
print('Time range: ${worldsheet4d.startTime} to ${worldsheet4d.endTime}');
print('Time points: ${worldsheet4d.timePoints.length}');

// Get fabric at specific time
final fabric3d = worldsheet4d.getFabricAtTime(DateTime.now());
if (fabric3d != null) {
  print('Strands: ${fabric3d.strandPositions.length}');
  print('Stability: ${fabric3d.invariants.stability}');
}
```

---

## 🎨 **Widget Usage**

### **9. Worldsheet4DWidget**

**Purpose:** Interactive 4D visualization widget for worldsheet evolution.

**Basic Usage:**
```dart
import 'package:avrai/presentation/widgets/knot/worldsheet_4d_widget.dart';

Worldsheet4DWidget(
  worldsheet: worldsheet,
  size: 400.0, // Optional, default: 400.0
  showControls: true, // Optional, default: true
  visualizationService: visualizationService, // Optional
)
```

**Features:**
- Interactive 3D view (rotation, zoom, pan)
- Time scrubbing (slider to navigate through time)
- Animation mode (play/pause timeline)
- Multiple strand visualization (one per user)
- Color coding based on fabric invariants
- **Performance optimized:** LOD, caching, strand limiting for 100+ users

**Performance Optimization:**
The widget automatically:
- Limits visible strands to 100 (configurable)
- Applies LOD based on zoom level
- Caches projected coordinates
- Samples strand points when zoomed out

---

### **10. StringEvolutionWidget**

**Purpose:** Visualizes knot string evolution over time.

**Basic Usage:**
```dart
import 'package:avrai/presentation/widgets/knot/string_evolution_widget.dart';

StringEvolutionWidget(
  string: knotString,
  size: 300.0, // Optional
  selectedProperty: KnotProperty.crossingNumber, // Optional
  showControls: true, // Optional
)
```

**Features:**
- Animated evolution visualization
- Property selection (crossing number, density, etc.)
- Time scrubbing
- Interactive controls

---

## 🔗 **Integration Examples**

### **Using Services in Compatibility Calculations**

```dart
// Example: Enhanced compatibility with multi-scale states
final multiScaleService = GetIt.instance<MultiScaleQuantumStateService>();
final compatibilityService = GetIt.instance<VibeCompatibilityService>();

// Generate multi-scale states
final userMultiScale = await multiScaleService.generateMultiScaleStates(
  profile: userProfile,
);

final businessMultiScale = await multiScaleService.generateMultiScaleStates(
  profile: businessProfile,
);

// Calculate compatibility (service automatically uses multi-scale if available)
final compatibility = await compatibilityService.calculateUserBusinessVibe(
  userProfile: userProfile,
  business: business,
);
```

### **Using Services in Group Matching**

```dart
// Example: Group matching with worldsheet analytics
final groupMatchingService = GetIt.instance<GroupMatchingService>();
final analyticsService = GetIt.instance<WorldsheetAnalyticsService>();

// Group matching automatically uses worldsheet analytics
final matches = await groupMatchingService.matchGroupAgainstSpots(
  session: groupSession,
  spots: availableSpots,
);

// Analytics are used internally for compatibility calculations
```

### **Using Services in Knot Evolution**

```dart
// Example: Knot evolution with automatic export
final orchestratorService = GetIt.instance<KnotOrchestratorService>();

// Create user string (automatically exports to JSON)
final string = await orchestratorService.createUserString(
  userId: userId,
  initialKnot: initialKnot,
);

// String is automatically exported for analytics
```

---

## ⚠️ **Error Handling Best Practices**

**Always handle errors gracefully:**
```dart
try {
  final result = await service.performOperation();
} on ServiceNotAvailableException {
  // Fallback to default behavior
  final fallback = getDefaultResult();
} catch (e, stackTrace) {
  // Log error
  developer.log(
    'Service operation failed: $e',
    error: e,
    stackTrace: stackTrace,
    name: 'ServiceName',
  );
  // Provide user feedback
  showError('Operation failed. Please try again.');
}
```

---

## 📊 **Performance Tips**

1. **Caching:** Services automatically cache results - check cache stats and clear if needed
2. **Sampling:** Analytics service samples large datasets automatically
3. **Streaming:** Export service streams large exports automatically
4. **Parallel Generation:** Multi-scale service generates states in parallel
5. **LOD:** 4D widget applies level-of-detail automatically based on zoom

---

## 🔗 **Related Documentation**

- [Integration Guide](./integration/medium_low_priority_services_integration.md) - Complete integration guide
- [Service Architecture](../architecture/) - Architecture documentation
- [API Reference](../api/) - Complete API reference

---

**Last Updated:** January 27, 2026  
**Status:** ✅ Complete

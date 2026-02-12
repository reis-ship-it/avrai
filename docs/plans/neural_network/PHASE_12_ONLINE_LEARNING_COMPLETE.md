# Phase 12: Online Learning Implementation - Complete

> **Historical:** This document may contain legacy domain references; current product uses avrai.app.

**Date:** December 28, 2025  
**Status:** ✅ Complete  
**Section:** 3.2.1: Continuous Learning

---

## ✅ **Implementation Complete**

### **Core Component Created**

**`OnlineLearningService`** (`lib/core/services/online_learning_service.dart`)
- Manages periodic retraining of neural network models
- Collects new training data from outcomes
- Triggers retraining based on time or data thresholds
- Auto-registers new model versions after retraining
- Tracks model performance metrics over time

---

## 📋 **Features Implemented**

### **1. Scheduled Retraining**
- ✅ Weekly retraining interval (configurable)
- ✅ Daily checks for retraining triggers
- ✅ Automatic retraining when enough new data available
- ✅ Manual retraining trigger support

### **2. Data Collection**
- ✅ Counts new training data since last retraining
- ✅ Exports training data for Python retraining scripts
- ✅ Filters for records with outcomes (required for training)
- ✅ Minimum threshold: 1,000 new samples

### **3. Version Management Integration**
- ✅ Auto-registers new model versions after retraining
- ✅ Integrates with `ModelVersionManager`
- ✅ Sets new versions to `staging` status
- ✅ Starts with low weight (0.1) for safety

### **4. Performance Tracking**
- ✅ Daily performance tracking for all active versions
- ✅ Calculates metrics from A/B test outcomes:
  - Positive outcome rate
  - Average calling score
  - Average outcome score
  - Sample count
- ✅ Caches performance metrics per version

### **5. State Management**
- ✅ Tracks last retraining date
- ✅ Tracks last performance tracking date
- ✅ Prevents concurrent retraining
- ✅ Graceful error handling

---

## 🔧 **Configuration**

### **Retraining Settings**
```dart
static const int minSamplesForRetraining = 1000; // Minimum new samples
static const Duration retrainingInterval = Duration(days: 7); // Weekly
static const Duration performanceTrackingInterval = Duration(hours: 24); // Daily
```

### **Retraining Triggers**
1. **Time-based**: Retrain every 7 days (weekly)
2. **Data-based**: Retrain when 1,000+ new samples available
3. **Manual**: Trigger retraining programmatically

---

## 🔗 **Integration**

### **Dependency Injection**
- ✅ Registered in `injection_container.dart`
- ✅ Dependencies: `SupabaseClient`, `CallingScoreDataCollector`, `ModelVersionManager`, `AgentIdService`

### **Data Sources**
- ✅ `calling_score_training_data` table (training data with outcomes)
- ✅ `calling_score_ab_test_outcomes` table (A/B test results for performance tracking)

### **Model Versioning**
- ✅ Integrates with `ModelVersionManager` for version registration
- ✅ Uses `ModelVersionRegistry` for version lookup
- ✅ Auto-creates new versions after retraining

---

## 🚀 **Usage Examples**

### **Initialize Service**
```dart
final onlineLearning = sl<OnlineLearningService>();
await onlineLearning.initialize();
// Service automatically starts scheduled retraining and performance tracking
```

### **Manual Retraining Trigger**
```dart
final success = await onlineLearning.triggerRetraining(
  modelType: 'calling_score',
  reason: 'manual',
);
```

### **Check Retraining Status**
```dart
if (onlineLearning.isRetraining) {
  print('Retraining in progress...');
}

final lastRetrain = onlineLearning.lastRetrainingDate;
print('Last retraining: ${lastRetrain ?? "never"}');
```

### **Get Performance Metrics**
```dart
final metrics = onlineLearning.getPerformanceMetrics('v1.1-hybrid');
if (metrics != null) {
  print('Positive outcome rate: ${(metrics.positiveOutcomeRate * 100).toStringAsFixed(1)}%');
  print('Sample count: ${metrics.sampleCount}');
}
```

### **Register New Model After Training**
```dart
// After Python training script completes and generates new ONNX model
await onlineLearning.registerNewModelVersion(
  version: 'v1.2-hybrid',
  modelPath: 'assets/models/calling_score_model_v1_2_hybrid.onnx',
  modelType: 'calling_score',
  trainingMetrics: {
    'test_loss': 0.0234,
    'val_loss': 0.0256,
    'training_samples': 15000,
  },
);
```

---

## 📊 **Workflow**

### **Automatic Retraining Flow**
```
1. Service checks daily for retraining triggers
   ↓
2. If 7 days passed OR 1000+ new samples:
   ↓
3. Export new training data
   ↓
4. Trigger Python retraining script (TODO: backend integration)
   ↓
5. After training completes:
   ↓
6. Register new model version (v1.2, v1.3, etc.)
   ↓
7. Update last retraining date
   ↓
8. New version available for A/B testing
```

### **Performance Tracking Flow**
```
1. Service tracks performance daily
   ↓
2. Query A/B test outcomes for last 7 days
   ↓
3. Calculate metrics:
   - Positive outcome rate
   - Average calling score
   - Average outcome score
   ↓
4. Cache metrics per version
   ↓
5. Update version performance metrics
```

---

## 🔄 **Retraining Process**

### **Step 1: Data Collection**
- Service queries `calling_score_training_data` table
- Filters for records with outcomes since last retraining
- Exports to JSON format for Python scripts

### **Step 2: Training Trigger**
- Currently logs the trigger (TODO: backend integration)
- In production, would call:
  - Backend API endpoint
  - Cloud function (Firebase, AWS Lambda)
  - Local script execution (development)

### **Step 3: Model Registration**
- After training completes, call `registerNewModelVersion()`
- New version automatically registered in `ModelVersionRegistry`
- Status set to `staging` for A/B testing

### **Step 4: A/B Testing**
- Use `ModelVersionManager` to start A/B test
- Gradually increase traffic (10% → 50% → 100%)
- Monitor performance metrics

---

## 📈 **Performance Metrics Tracked**

### **Per Version Metrics**
- **Sample Count**: Number of outcomes tracked
- **Positive Outcome Rate**: % of positive outcomes
- **Average Calling Score**: Mean calling score
- **Average Outcome Score**: Mean outcome score
- **Tracking Period**: Days of data (default: 7)

### **Usage**
```dart
final metrics = onlineLearning.getPerformanceMetrics('v1.1-hybrid');
// Use metrics to:
// - Compare versions
// - Make deployment decisions
// - Adjust model weights
```

---

## 🚨 **TODO: Backend Integration**

The service currently logs retraining triggers. For production, integrate with:

### **Option 1: Backend API**
```dart
// Call backend API to trigger retraining
await http.post(
  Uri.parse('https://api.avrai.app/ml/retrain'),
  body: jsonEncode({
    'model_type': 'calling_score',
    'data_export_path': 'path/to/exported/data.json',
  }),
);
```

### **Option 2: Cloud Function**
```dart
// Trigger cloud function (Firebase, AWS Lambda, etc.)
await cloudFunctions.httpsCallable('triggerRetraining').call({
  'modelType': 'calling_score',
  'dataPath': 'path/to/data.json',
});
```

### **Option 3: Local Script (Development)**
```dart
// Execute Python script locally
final process = await Process.start(
  'python3',
  ['scripts/ml/train_calling_score_model.py', '--data-path', dataPath],
);
```

---

## ✅ **Success Criteria**

- [x] Online learning service created
- [x] Scheduled retraining implemented
- [x] Data collection and export implemented
- [x] Performance tracking implemented
- [x] Version management integration complete
- [x] Dependency injection configured
- [ ] Backend integration for actual retraining (TODO)
- [ ] Automated model deployment after retraining (TODO)

---

## 🎯 **Next Steps**

### **Immediate**
1. **Backend Integration**: Connect retraining trigger to actual Python script execution
2. **Automated Deployment**: Auto-deploy new models after successful retraining
3. **Testing**: Test retraining workflow end-to-end

### **Future Enhancements**
1. **Incremental Learning**: Update model weights without full retraining
2. **Adaptive Thresholds**: Adjust retraining thresholds based on data quality
3. **Multi-Model Support**: Retrain both calling score and outcome models
4. **Performance-Based Retraining**: Retrain when performance degrades
5. **Rollback Automation**: Auto-rollback if new version performs worse

---

## 📝 **Notes**

- **Retraining Frequency**: Weekly by default, adjustable via configuration
- **Data Threshold**: 1,000 new samples minimum (prevents overfitting on small datasets)
- **Version Naming**: Auto-increments (v1.1 → v1.2 → v1.3, etc.)
- **Safety**: New versions start with low weight (0.1) and `staging` status
- **Performance Tracking**: Daily tracking provides continuous monitoring

---

**Last Updated:** December 28, 2025  
**Status:** ✅ Complete - Ready for Backend Integration

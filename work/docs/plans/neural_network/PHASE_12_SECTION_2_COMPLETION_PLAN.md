# Phase 12 Section 2: Completion Plan

**Date:** December 28, 2025  
**Status:** Infrastructure Complete, Training Pending  
**Based on:** Brief conversation review

---

## ✅ **What's Already Complete**

### **Section 2.1: Calling Score Prediction Model** ✅
- ✅ Model architecture defined (39 → 128 → 64 → 1 MLP)
- ✅ `CallingScoreNeuralModel` service created
- ✅ `CallingScoreTrainingDataPreparer` service created
- ✅ Feature extraction implemented
- ✅ Data normalization pipeline
- ✅ Training data splitting (train/val/test)

### **Section 2.2: Model Integration** ✅
- ✅ Hybrid calling score calculation implemented
- ✅ Formula: `Final Score = Formula Score × 0.7 + Neural Network Score × 0.3`
- ✅ Fallback mechanism (formula-based if neural fails)
- ✅ Feature preparation integrated
- ✅ Error handling implemented

### **Section 2.3: A/B Testing Framework** ✅
- ✅ `CallingScoreABTestingService` implemented
- ✅ User group assignment (50/50 split)
- ✅ Outcome logging
- ✅ Metrics calculation
- ✅ Database migration created

---

## ❌ **What's Missing**

### **1. ONNX Runtime Integration** ❌
- ❌ `onnxruntime` package not in `pubspec.yaml`
- ❌ Actual ONNX model loading not implemented
- ❌ `CallingScoreNeuralModel` uses rule-based fallback (not real ONNX)
- ❌ `OnnxDimensionScorer` uses rule-based fallback (not real ONNX)

### **2. Python Training Script** ❌
- ❌ No Python script to train the model
- ❌ No data export mechanism (Supabase or JSON)
- ❌ No model training pipeline
- ❌ No ONNX conversion script

### **3. Model Training & Deployment** ❌
- ❌ No trained ONNX model file
- ❌ No model in `assets/models/` directory
- ❌ Model loading code not connected to real ONNX runtime

---

## 🎯 **Completion Plan**

### **Step 1: Add ONNX Runtime Package** (15 minutes)
- [ ] Add `onnxruntime: ^1.4.1` to `pubspec.yaml`
- [ ] Run `flutter pub get`
- [ ] Verify package installs correctly

### **Step 2: Implement ONNX Model Loading** (1-2 hours)
- [ ] Update `CallingScoreNeuralModel.loadModel()` to use ONNX runtime
- [ ] Implement actual ONNX session creation
- [ ] Update `CallingScoreNeuralModel.predict()` to use ONNX inference
- [ ] Add error handling for ONNX failures
- [ ] Test with placeholder model (if available)

### **Step 3: Create Python Training Script** (2-3 hours)
- [ ] Create `scripts/ml/train_calling_score_model.py`
- [ ] Implement data loading (from Supabase or JSON export)
- [ ] Define PyTorch/TensorFlow model (39 → 128 → 64 → 1)
- [ ] Implement training loop with validation
- [ ] Add model checkpointing
- [ ] Implement ONNX export (`torch.onnx.export()` or `tf2onnx`)

### **Step 4: Generate/Export Training Data** (30 minutes)
- [ ] Option A: Use `CallingScoreTrainingDataPreparer.exportToJson()` to export data
- [ ] Option B: Connect Python script directly to Supabase
- [ ] Option C: Generate synthetic data for initial testing
- [ ] Verify data format matches training script expectations

### **Step 5: Train Initial Model** (1-2 hours)
- [ ] Run training script with available data (synthetic or real)
- [ ] Monitor training metrics (loss, accuracy)
- [ ] Validate model performance
- [ ] Export trained model to ONNX format
- [ ] Test ONNX model inference speed (<100ms target)

### **Step 6: Deploy ONNX Model** (30 minutes)
- [ ] Place ONNX model in `assets/models/calling_score_model.onnx`
- [ ] Update `CallingScoreNeuralModel.loadModel()` to load from assets
- [ ] Test model loading and inference
- [ ] Verify hybrid calculation works with real ONNX model
- [ ] Test fallback mechanism if model fails

### **Step 7: Validate & Test** (1 hour)
- [ ] Test calling score calculation with ONNX model
- [ ] Verify inference speed (<100ms)
- [ ] Test A/B testing framework with real model
- [ ] Monitor error rates and fallback frequency
- [ ] Compare hybrid vs formula-based performance

---

## 📊 **Data Requirements**

### **For Training:**
- **Minimum:** 1,000 records (for initial testing)
- **Recommended:** 10,000+ records (for production)
- **Coverage:** At least 50% with outcomes

### **Data Sources:**
1. **Real Data** (preferred for production)
   - From `calling_score_training_data` table
   - Requires actual user interactions

2. **Synthetic Data** (acceptable for development/testing)
   - Generate realistic feature vectors
   - Use existing formula to create baseline scores
   - Add realistic correlations and noise
   - Can start training immediately

### **Data Export Options:**
- **Option A:** JSON export via `CallingScoreTrainingDataPreparer`
- **Option B:** Direct Supabase connection from Python
- **Option C:** Synthetic data generator (for testing)

---

## 🔧 **Technical Requirements**

### **Python Environment:**
- Python 3.8+
- PyTorch or TensorFlow
- ONNX export library (`torch.onnx` or `tf2onnx`)
- NumPy, Pandas
- Supabase Python client (if using direct connection)

### **Flutter/Dart:**
- `onnxruntime: ^1.4.1` package
- ONNX model file in `assets/models/`
- Model loading code updated

### **Model Specifications:**
- **Input:** 39 features (12D user + 12D spot + 10 context + 5 timing)
- **Architecture:** MLP (39 → 128 → 64 → 1)
- **Output:** Calling score (0.0-1.0)
- **Format:** ONNX
- **Target Speed:** <100ms inference

---

## ⏱️ **Estimated Timeline**

- **Step 1:** 15 minutes
- **Step 2:** 1-2 hours
- **Step 3:** 2-3 hours
- **Step 4:** 30 minutes
- **Step 5:** 1-2 hours (depends on data availability)
- **Step 6:** 30 minutes
- **Step 7:** 1 hour

**Total:** ~6-9 hours of focused work

**Note:** Training time depends on:
- Data availability (synthetic = immediate, real = may need to collect)
- Model complexity
- Hardware (CPU vs GPU)

---

## 🚀 **Quick Start Path**

### **For Immediate Testing (Synthetic Data):**
1. Add ONNX runtime package
2. Implement ONNX model loading
3. Create Python training script
4. Generate synthetic training data
5. Train model and export to ONNX
6. Deploy and test

### **For Production (Real Data):**
1. Collect real training data (10K+ interactions)
2. Follow steps 1-7 above
3. Use real data instead of synthetic
4. Validate with A/B testing
5. Monitor and iterate

---

## 📝 **Key Decisions Made**

1. **Synthetic Data is Acceptable** for development/testing
   - Can start training immediately
   - No privacy concerns
   - Reproducible experiments
   - Real data preferred for production

2. **ONNX Runtime Not Fully Integrated**
   - Framework exists but needs actual implementation
   - Package needs to be added
   - Model loading code needs to be written

3. **Hybrid Approach Maintained**
   - 70% formula, 30% neural network
   - Gradual transition as model improves
   - Fallback always available

---

## ✅ **Success Criteria**

Phase 2 is complete when:
- [x] ONNX runtime package installed ✅
- [x] ONNX model loading framework implemented ✅
- [x] Python training script created ✅
- [x] Synthetic data generator created ✅
- [x] Data export utility created ✅
- [ ] Model trained and exported to ONNX ⏳ (Ready - requires user action)
- [ ] ONNX model deployed to assets ⏳ (Ready - requires trained model)
- [ ] Hybrid calculation uses real ONNX model ⏳ (Ready - requires trained model)
- [ ] Inference speed <100ms ⏳ (Ready - requires trained model)
- [ ] A/B testing framework working with real model ⏳ (Ready - requires trained model)
- [x] Fallback mechanism implemented ✅

---

## 🎯 **Next Steps After Phase 2**

- **Section 3:** Outcome Prediction Model
- **Section 4:** Individual Trajectory Prediction
- **Section 5:** Advanced Models
- **Section 6:** Production Deployment

---

**Last Updated:** December 28, 2025  
**Status:** Ready for Implementation

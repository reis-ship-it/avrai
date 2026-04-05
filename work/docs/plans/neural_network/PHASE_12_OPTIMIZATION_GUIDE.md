# Phase 12: Model Optimization Guide

**Date:** December 28, 2025  
**Status:** ✅ Ready to Use  
**Based on:** v1.0-hybrid baseline

---

## 🎯 **Overview**

This guide explains how to optimize new model version variants based on the v1.0-hybrid baseline. The optimization script systematically tests different hyperparameters and architectures to find the best configuration.

---

## 🚀 **Quick Start**

### **Run Full Optimization**

```bash
# Tests ~15 variants (takes ~2-4 hours on CPU)
python scripts/ml/optimize_calling_score_model.py \
  --data-path data/calling_score_training_data_v1_hybrid.json \
  --output-dir assets/models/optimized/
```

### **Quick Test (First 5 Variants)**

```bash
# Quick test (takes ~30-60 minutes)
python scripts/ml/optimize_calling_score_model.py \
  --data-path data/calling_score_training_data_v1_hybrid.json \
  --output-dir assets/models/optimized/ \
  --max-variants 5
```

---

## 📊 **What Gets Tested**

### **1. Learning Rate Variants** (5 variants)
- `0.0001` - Conservative (slower, more stable)
- `0.0005` - Lower than baseline
- `0.001` - Baseline (v1.0-hybrid)
- `0.002` - Higher than baseline
- `0.005` - Aggressive (faster, may overshoot)

### **2. Batch Size Variants** (3 variants)
- `16` - Smaller batches (more updates, slower)
- `32` - Baseline (v1.0-hybrid)
- `64` - Larger batches (fewer updates, faster, more stable)
- `128` - Very large batches

### **3. Architecture Variants** (4 variants)
- `[256, 128]` - Wider network (more capacity)
- `[128, 64, 32]` - Deeper network (more layers)
- `[96, 48]` - Smaller network (faster inference)
- `[256, 128, 64]` - Wide and deep

### **4. Dropout Variants** (3 variants)
- `0.1` - Less regularization (may overfit)
- `0.2` - Baseline (v1.0-hybrid)
- `0.3` - More regularization (may underfit)
- `0.4` - Very high regularization

**Total: ~15 variants** (including baseline)

---

## 📈 **Results**

### **Output Files**

1. **Optimized Models**: `assets/models/optimized/calling_score_model_*.onnx`
   - One model file per variant
   - Named by variant (e.g., `calling_score_model_v1_1_lr_0.0005.onnx`)

2. **Results JSON**: `assets/models/optimized/optimization_results.json`
   - Complete results for all variants
   - Includes test loss, validation loss, training time, model size
   - Comparison against baseline

### **Summary Output**

The script prints a summary showing:
- Top 5 variants by test loss
- Best variant with full configuration
- Improvement percentage vs baseline
- Failed variants (if any)

Example output:
```
🏆 BEST VARIANT: v1_1_lr_0.0005
Test Loss: 0.0234 (improvement: +12.36%)
Val Loss: 0.0256
Training Time: 245.3s
Model Size: 12.3 KB
Parameters: 13,441

Configuration:
  Learning Rate: 0.0005
  Batch Size: 32
  Architecture: [128, 64]
  Dropout: 0.2
```

---

## 🔧 **Manual Training with Custom Hyperparameters**

You can also train individual variants manually:

```bash
# Custom learning rate
python scripts/ml/train_calling_score_model.py \
  --data-path data/calling_score_training_data_v1_hybrid.json \
  --output-path assets/models/calling_score_model_custom.onnx \
  --learning-rate 0.0005 \
  --batch-size 64 \
  --hidden-sizes "256,128,64" \
  --dropout 0.3
```

### **Available Parameters**

- `--learning-rate`: Learning rate (default: 0.001)
- `--batch-size`: Batch size (default: 32)
- `--epochs`: Number of epochs (default: 100)
- `--hidden-sizes`: Architecture as comma-separated (e.g., "256,128,64")
- `--dropout`: Dropout rate (default: 0.2)

---

## 📋 **Optimization Workflow**

### **Step 1: Run Optimization**

```bash
python scripts/ml/optimize_calling_score_model.py \
  --data-path data/calling_score_training_data_v1_hybrid.json \
  --output-dir assets/models/optimized/
```

### **Step 2: Review Results**

```bash
# View results JSON
cat assets/models/optimized/optimization_results.json | python -m json.tool
```

### **Step 3: Register Best Variant**

```dart
// In Dart code
final bestVariant = ModelVersionInfo(
  version: 'v1.1-hybrid',
  modelPath: 'assets/models/optimized/calling_score_model_v1_1_lr_0.0005.onnx',
  defaultWeight: 0.1, // Start low
  dataSource: 'hybrid_big_five',
  trainedDate: DateTime.now(),
  status: ModelStatus.staging,
  description: 'v1.1 optimized (lr=0.0005, improved test loss by 12.36%)',
  trainingMetrics: {
    'test_loss': 0.0234,
    'val_loss': 0.0256,
    'improvement_vs_baseline': 12.36,
  },
);

await versionManager.registerVersion(bestVariant, modelType: 'calling_score');
```

### **Step 4: A/B Test**

```dart
// Start with 10% traffic
await versionManager.startABTest('v1.1-hybrid', 0.1);

// Monitor for 1-2 weeks
// If performance improves, increase to 50%, then 100%
// If performance degrades, rollback
await versionManager.rollbackCallingScoreVersion();
```

### **Step 5: Deploy**

```dart
// Switch to new version
await versionManager.switchCallingScoreVersion('v1.1-hybrid');
```

---

## 🎯 **Expected Improvements**

Based on typical hyperparameter optimization:

- **Learning Rate Tuning**: 2-10% improvement
- **Batch Size Optimization**: 1-5% improvement
- **Architecture Changes**: 5-15% improvement
- **Dropout Tuning**: 1-5% improvement
- **Combined Optimizations**: 10-30% improvement

**Note**: Actual improvements depend on your specific dataset and problem.

---

## ⚠️ **Best Practices**

1. **Start with Baseline**: Always include baseline (v1.0-hybrid) in comparison
2. **One Change at a Time**: When manually testing, change one parameter at a time
3. **Use Validation Set**: Don't optimize on test set (script handles this)
4. **Track Everything**: All results saved to JSON for later analysis
5. **A/B Test**: Always A/B test before full deployment
6. **Rollback Plan**: Keep previous versions for quick rollback

---

## 🔍 **Interpreting Results**

### **Test Loss**
- **Lower is better**
- Compare against baseline (v1.0-hybrid: 0.0267)
- Improvement = `(baseline - new) / baseline * 100%`

### **Validation Loss**
- Should track closely with test loss
- Large gap indicates overfitting

### **Training Time**
- Consider for production deployment
- Faster training = faster iteration

### **Model Size**
- Smaller models = faster inference
- Balance between size and performance

---

## 📝 **Next Steps After Optimization**

1. **Register Best Variant**: Add to ModelVersionRegistry
2. **A/B Test**: Start with 1-10% traffic
3. **Monitor**: Track performance metrics for 1-2 weeks
4. **Gradual Rollout**: Increase traffic if performance improves
5. **Full Deployment**: Switch active version if successful
6. **Iterate**: Use real data for next optimization round (v2.0+)

---

## 🚨 **Troubleshooting**

### **All Variants Fail**
- Check data file exists and is valid
- Verify Python dependencies installed
- Check disk space for model outputs

### **No Improvement Over Baseline**
- Try more aggressive hyperparameters
- Consider different architectures
- May need more training data

### **Optimization Takes Too Long**
- Use `--max-variants` to limit tests
- Use GPU if available (`--device cuda`)
- Reduce epochs for quick tests

---

**Last Updated:** December 28, 2025  
**Status:** ✅ Ready to Use

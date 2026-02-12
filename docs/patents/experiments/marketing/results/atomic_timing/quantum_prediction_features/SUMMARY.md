# quantum_prediction_features - Results Summary

**Date:** 2025-12-23 22:29:50  
**Experiment:** quantum_prediction_features  
**Test Pairs:** 1000  
**Random Seed:** 42

---

## 📊 Results Summary

### Control Group (Standard Timestamps)
- **prediction:** 0.5081
- **accuracy:** 0.9438
- **error:** 0.0562

### Test Group (Atomic Timing)
- **prediction:** 0.5544
- **accuracy:** 0.9501
- **error:** 0.0499

### Improvements
- **prediction:** 9.12% improvement (1.09x)
- **accuracy:** 0.67% improvement (1.01x)
- **error:** -11.19% improvement (0.89x)

### Statistical Validation

**prediction:**
- p-value: 0.000000 ✅
- Cohen's d: 0.2609 ❌
- Control 95% CI: [0.4953, 0.5208]
- Test 95% CI: [0.5454, 0.5634]

**accuracy:**
- p-value: 0.000026 ✅
- Cohen's d: 0.1884 ❌
- Control 95% CI: [0.9414, 0.9462]
- Test 95% CI: [0.9485, 0.9517]

**error:**
- p-value: 0.000026 ✅
- Cohen's d: -0.1884 ❌
- Control 95% CI: [0.0538, 0.0586]
- Test 95% CI: [0.0483, 0.0515]

---

**Status:** ✅ Experiment Complete
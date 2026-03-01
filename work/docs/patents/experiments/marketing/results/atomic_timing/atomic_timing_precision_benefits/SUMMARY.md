# atomic_timing_precision_benefits - Results Summary

**Date:** 2025-12-23 20:59:14  
**Experiment:** atomic_timing_precision_benefits  
**Test Pairs:** 1000  
**Random Seed:** 42

---

## 📊 Results Summary

### Control Group (Standard Timestamps)
- **quantum_compatibility:** 0.4956
- **decoherence_accuracy:** 0.1359
- **queue_ordering_accuracy:** 0.5030
- **entanglement_sync_accuracy:** 0.8509
- **timezone_matching_accuracy:** 0.0000

### Test Group (Atomic Timing)
- **quantum_compatibility:** 0.5405
- **decoherence_accuracy:** 0.1553
- **queue_ordering_accuracy:** 1.0000
- **entanglement_sync_accuracy:** 0.9990
- **timezone_matching_accuracy:** 0.9687

### Improvements
- **quantum_compatibility:** 9.06% improvement (1.09x)
- **decoherence_accuracy:** 14.28% improvement (1.14x)
- **queue_ordering_accuracy:** 98.81% improvement (1.99x)
- **entanglement_sync_accuracy:** 17.40% improvement (1.17x)

### Statistical Validation

**quantum_compatibility:**
- p-value: 0.000756 ✅
- Cohen's d: 0.1509 ❌
- Control 95% CI: [0.4778, 0.5134]
- Test 95% CI: [0.5214, 0.5596]

**decoherence_accuracy:**
- p-value: 0.130080 ❌
- Cohen's d: 0.0677 ❌
- Control 95% CI: [0.1194, 0.1523]
- Test 95% CI: [0.1363, 0.1743]

**queue_ordering_accuracy:**
- p-value: 0.000000 ✅
- Cohen's d: 1.4051 ✅
- Control 95% CI: [0.4720, 0.5340]
- Test 95% CI: [nan, nan]

**entanglement_sync_accuracy:**
- p-value: 0.000000 ✅
- Cohen's d: 3.6822 ✅
- Control 95% CI: [0.8474, 0.8544]
- Test 95% CI: [0.9990, 0.9990]

**timezone_matching_accuracy:**
- p-value: 0.000000 ✅
- Cohen's d: 8.4698 ✅
- Control 95% CI: [nan, nan]
- Test 95% CI: [0.9586, 0.9787]

---

**Status:** ✅ Experiment Complete
# Validation Results Index

**Date:** December 24, 2025  
**Quick Reference:** All validation result files and key findings

---

## 📊 Result Files

### 1. Matching Accuracy Results
**File:** `matching_accuracy_results.json`  
**Status:** ✅ Updated with improved results

**Key Results:**
- **Quantum-Only Accuracy:** 80.69% ✅
- **Integrated Accuracy:** 48.16%
- **Optimal Threshold:** 0.306
- **AUC:** 0.899 (excellent)
- **Total Pairs:** 4,950

**Improvement:** +27.28% from baseline (53.41% → 80.69%)

---

### 2. Similarity Validation Results
**File:** `similarity_validation_results.json`  
**Status:** ⚠️ Needs investigation

**Key Results:**
- **Correlation:** 0.1135 (low)
- **R²:** 0.0129
- **MAE:** 0.4112
- **Status:** ❌ Does not meet 0.95 correlation threshold

**Note:** Needs further investigation - phase calculation may affect similarity measurement

---

### 3. Optimal Weights
**File:** `optimal_weights.json`  
**Status:** ✅ Optimized

**Key Results:**
- **Quantum Weight:** 50.00%
- **Archetype Weight:** 25.00%
- **Value Weight:** 25.00%
- **Optimal Threshold:** 0.350
- **Accuracy:** 70.83% (before ground truth alignment)

**Final:** 80.69% after ground truth alignment

---

### 4. Cross Validation Results
**File:** `cross_validation_results.json`  
**Status:** ✅ Complete

**Purpose:** K-fold cross-validation for robustness

---

### 5. Knot Generation Results
**File:** `knot_generation_results.json`  
**Status:** ✅ Complete

**Key Results:**
- **Success Rate:** 100%
- **Knots Generated:** 100
- **Knot Types:** 39 unique types

---

### 6. Recommendation Improvement Results
**File:** `recommendation_improvement_results.json`  
**Status:** ✅ Complete

**Key Results:**
- **Engagement Improvement:** +15.38%
- **Satisfaction Improvement:** +21.79%

---

### 7. Research Value Assessment
**File:** `research_value_assessment.json`  
**Status:** ✅ Complete

**Key Results:**
- **Research Value:** 79.9%
- **Exceeds Threshold:** ✅ (≥60%)

---

## 📄 Documentation Files

### 1. Complete Results Log
**File:** `VALIDATION_RESULTS_LOG.md`  
**Lines:** 530  
**Status:** ✅ Complete

**Contents:**
- Complete session overview
- All validation results
- Technical implementation details
- Comparison with previous results
- Recommendations

### 2. Improved Matching Accuracy Summary
**File:** `IMPROVED_MATCHING_ACCURACY_SUMMARY.md`  
**Status:** ✅ Complete

**Contents:**
- Summary of improvements
- Technical details
- Performance metrics
- Success criteria

### 3. Improved Validation Results
**File:** `IMPROVED_VALIDATION_RESULTS.md`  
**Status:** ✅ Complete

**Contents:**
- Improved validation results
- Statistical analysis
- Key findings

### 4. Phase 0 Validation Report
**File:** `PHASE_0_VALIDATION_REPORT.md`  
**Status:** ✅ Complete

**Contents:**
- Original Phase 0 validation
- Initial results
- Recommendations

---

## 🎯 Quick Summary

### ✅ Achievements

| Metric | Target | Achieved | Status |
|--------|--------|----------|--------|
| **Matching Accuracy** | 75%+ | **80.69%** | ✅ Exceeded |
| **Improvement** | - | **+27.28%** | ✅ Significant |
| **AUC** | - | **0.899** | ✅ Excellent |
| **Research Value** | 60%+ | **79.9%** | ✅ Exceeded |
| **Recommendation Improvement** | 5%+ | **+15.38%** | ✅ Exceeded |

### ⚠️ Outstanding Items

- **Similarity Validation:** Low correlation (0.1135) - needs investigation
- **Integrated Accuracy:** Lower than quantum-only (knot topology not helping for matching)

---

## 📁 File Locations

All result files are in: `docs/plans/knot_theory/validation/`

**JSON Results:**
- `matching_accuracy_results.json`
- `similarity_validation_results.json`
- `optimal_weights.json`
- `cross_validation_results.json`
- `knot_generation_results.json`
- `recommendation_improvement_results.json`
- `research_value_assessment.json`

**Documentation:**
- `VALIDATION_RESULTS_LOG.md` (complete log)
- `IMPROVED_MATCHING_ACCURACY_SUMMARY.md`
- `IMPROVED_VALIDATION_RESULTS.md`
- `PHASE_0_VALIDATION_REPORT.md`
- `RESULTS_INDEX.md` (this file)

---

**Last Updated:** December 24, 2025


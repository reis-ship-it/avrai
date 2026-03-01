# Experiment Script Template Guide

**Date:** December 21, 2025  
**Purpose:** Guide for creating thorough and correct experiment scripts for all patents

---

## 📋 **Template Overview**

The `EXPERIMENT_SCRIPT_TEMPLATE.py` provides a standardized structure for creating experiment scripts that ensure:

1. **Thorough Testing:** All required experiments are implemented
2. **Correct Implementation:** Patent algorithms match patent documents exactly
3. **Comprehensive Metrics:** Standard metrics calculated for all experiments
4. **Proper Validation:** Results validated against patent claims
5. **Consistent Structure:** All scripts follow the same pattern

---

## 🔧 **Customization Checklist**

When creating a new experiment script from the template, you MUST customize:

### **1. Configuration Section**
- [ ] `PATENT_NUMBER`: Set to patent number (e.g., "10", "13", "15")
- [ ] `PATENT_NAME`: Set to full patent name
- [ ] `PATENT_FOLDER`: Set to appropriate folder name
- [ ] `NUM_SAMPLES`: Adjust based on patent requirements (1000+ recommended)

### **2. Data Generation (`generate_synthetic_data()`)**
- [ ] Generate patent-specific data structures
- [ ] Include ground truth values for validation
- [ ] Ensure sufficient data volume
- [ ] Save data to JSON/CSV files

### **3. Data Loading (`load_data()`)**
- [ ] Load patent-specific data structures
- [ ] Handle missing data (generate if needed)
- [ ] Return data in format expected by experiments

### **4. Patent Algorithm (`patent_algorithm()`)**
- [ ] Implement core algorithm from patent document
- [ ] Use exact weights, thresholds, and parameters from patent
- [ ] Follow mathematical formulas exactly
- [ ] Return results in standardized format

### **5. Experiment Functions (4 required)**
- [ ] `experiment_1_[name]()`: Implement first required experiment
- [ ] `experiment_2_[name]()`: Implement second required experiment
- [ ] `experiment_3_[name]()`: Implement third required experiment
- [ ] `experiment_4_[name]()`: Implement fourth required experiment

For each experiment:
- [ ] Implement experiment logic
- [ ] Calculate accuracy metrics (MAE, RMSE, correlation, R²)
- [ ] Compare against ground truth or baseline
- [ ] Print results summary
- [ ] Save results to CSV with descriptive filename

### **6. Validation (`validate_patent_claims()`)**
- [ ] Check results meet patent's claimed performance
- [ ] Validate mathematical formulas produce expected results
- [ ] Verify thresholds and parameters work as specified
- [ ] Return validation report

### **7. Main Function**
- [ ] Call all required experiments
- [ ] Run validation
- [ ] Print final summary

---

## 📊 **Required Metrics**

Each experiment MUST calculate and report:

### **For Regression/Continuous Values:**
- Mean Absolute Error (MAE)
- Root Mean Squared Error (RMSE)
- Pearson Correlation Coefficient
- R² Score
- Mean and Standard Deviation

### **For Classification/Binary Values:**
- Accuracy
- Precision
- Recall
- F1 Score
- Confusion Matrix (if applicable)

### **For Validation:**
- Percentage of valid results
- Range checks (values within expected bounds)
- Threshold checks (meets patent-specified thresholds)

---

## ✅ **Quality Standards**

### **Code Quality:**
- [ ] All functions have docstrings
- [ ] Code follows PEP 8 style guide
- [ ] Variable names are descriptive
- [ ] Comments explain complex logic
- [ ] Error handling for edge cases

### **Data Quality:**
- [ ] Sufficient sample size (1000+ recommended)
- [ ] Ground truth values included where possible
- [ ] Data saved in standardized format
- [ ] Data can be regenerated (reproducible)

### **Result Quality:**
- [ ] All results saved to CSV files
- [ ] Results include all calculated metrics
- [ ] Results validated against patent claims
- [ ] Results documented in summary

### **Testing Quality:**
- [ ] Script runs without errors
- [ ] All experiments execute successfully
- [ ] Results are reasonable and validated
- [ ] Performance is acceptable (< 5 minutes per experiment)

---

## 📝 **Experiment Requirements by Patent**

### **Patent #10: AI2AI Chat Learning System**
- Experiment 1: Conversation Pattern Analysis Accuracy
- Experiment 2: Shared Insight Extraction Effectiveness
- Experiment 3: Federated Learning Convergence
- Experiment 4: Personality Evolution from Conversations

### **Patent #13: Multi-Path Dynamic Expertise System**
- Experiment 1: Multi-Path Expertise Calculation Accuracy (6-path weighted: 40%, 25%, 20%, 25%, 15%, varies)
- Experiment 2: Dynamic Threshold Scaling Effectiveness (platform phase: 0.6, 0.7, 0.8)
- Experiment 3: Automatic Check-In System Accuracy (geofencing, dwell time)
- Experiment 4: Category Saturation Detection (6-factor algorithm)

### **Patent #15: N-Way Revenue Distribution System**
- Experiment 1: N-Way Split Calculation Accuracy (3-10 parties)
- Experiment 2: Percentage Validation Accuracy (±0.01 tolerance)
- Experiment 3: Pre-Event Locking Effectiveness
- Experiment 4: Payment Distribution Accuracy (2-day delay)

### **Patent #16: Exclusive Long-Term Partnerships**
- Experiment 1: Exclusivity Constraint Checking Accuracy
- Experiment 2: Schedule Compliance Tracking (minimum events)
- Experiment 3: Automated Breach Detection
- Experiment 4: Partnership Lifecycle Management

### **Patent #17: Multi-Path Expertise + Quantum Matching + Partnership Ecosystem**
- Experiment 1: Integrated System Accuracy (expertise + quantum + partnerships)
- Experiment 2: Recursive Feedback Loop Effectiveness
- Experiment 3: Expertise-Weighted Matching Accuracy (`(vibe × 0.5) + (expertise × 0.3) + (location × 0.2)`)
- Experiment 4: Ecosystem Equilibrium Analysis

### **Patent #18: 6-Factor Saturation Algorithm**
- Experiment 1: 6-Factor Saturation Score Accuracy (25% + 20% + 20% + 15% + 10% + 10%)
- Experiment 2: Dynamic Threshold Adjustment (1.0x-3.0x multiplier)
- Experiment 3: Saturation Detection Accuracy
- Experiment 4: Geographic Distribution Analysis

### **Patent #19: 12-Dimensional Personality Multi-Factor**
- Experiment 1: 12-Dimensional Model Accuracy (8 discovery + 4 experience)
- Experiment 2: Weighted Multi-Factor Compatibility (60% + 20% + 20%)
- Experiment 3: Confidence-Weighted Scoring
- Experiment 4: Recommendation Accuracy

### **Patent #20: Hyper-Personalized Recommendation Fusion**
- Experiment 1: Multi-Source Fusion Accuracy (40% + 30% + 20% + 10%)
- Experiment 2: Hyper-Personalization Effectiveness
- Experiment 3: Diversity Preservation
- Experiment 4: Recommendation Quality

### **Patent #22: Calling Score Calculation**
- Experiment 1: Unified Calling Score Accuracy (40% + 30% + 15% + 10% + 5%)
- Experiment 2: Outcome-Based Learning Effectiveness (2x learning rate)
- Experiment 3: 70% Threshold Accuracy
- Experiment 4: Life Betterment Factor Calculation

---

## 🎯 **Validation Checklist**

Before marking an experiment script as complete:

- [ ] All 4 required experiments implemented
- [ ] All experiments run without errors
- [ ] Results saved to CSV files
- [ ] Metrics calculated correctly
- [ ] Results validated against patent claims
- [ ] Code follows template structure
- [ ] Documentation complete
- [ ] Script tested and verified

---

## 📚 **Reference Documents**

- **Template:** `scripts/EXPERIMENT_SCRIPT_TEMPLATE.py`
- **Example:** `scripts/run_patent_1_experiments.py`
- **Plan:** `FULL_ECOSYSTEM_INTEGRATION_PLAN.md`
- **Log Template:** `EXPERIMENT_LOG_TEMPLATE.md`

---

**Last Updated:** December 21, 2025


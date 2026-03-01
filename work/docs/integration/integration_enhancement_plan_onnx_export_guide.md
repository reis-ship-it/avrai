# ONNX Export Guide for Quantum Models

**Plan ID:** `integration_and_enhancement_plan_a81ba5e1`  
**Date:** January 27, 2026  
**Status:** ⚠️ Workaround Required  
**Related Plan:** `/Users/reisgordon/.cursor/plans/integration_and_enhancement_plan_a81ba5e1.plan.md`

---

## ⚠️ **ONNX Export Issue**

**Problem:** PyTorch 2.10.0 has a compatibility issue with ONNX export that causes Union type errors when exporting models with conditional logic or multi-task outputs.

**Error:**
```
TypeError: Expecting a type not f<class 'typing.Union'> for typeinfo.
```

**Root Cause:**
- PyTorch 2.10.0's ONNX exporter has issues with certain model structures
- Multi-task models with conditional logic trigger Union type detection
- This is a known issue in PyTorch 2.10.0

---

## ✅ **Workaround Solutions**

### **Option 1: Use PyTorch 2.0.0 (Recommended)**

The most reliable solution is to use PyTorch 2.0.0 for ONNX export:

```bash
# Create a separate virtual environment for ONNX export
python3 -m venv venv_onnx_export
source venv_onnx_export/bin/activate

# Install PyTorch 2.0.0
pip install torch==2.0.0 onnx onnxruntime

# Export models
python scripts/ml/export_quantum_models_to_onnx.py \
  --model optimization \
  --pth-path assets/models/quantum_optimization_model.pth \
  --onnx-path assets/models/quantum_optimization_model.onnx

python scripts/ml/export_quantum_models_to_onnx.py \
  --model entanglement \
  --pth-path assets/models/entanglement_model.pth \
  --onnx-path assets/models/entanglement_model.onnx
```

### **Option 2: Wait for PyTorch Fix**

PyTorch may fix this issue in a future release. Monitor:
- PyTorch GitHub issues: https://github.com/pytorch/pytorch/issues
- PyTorch release notes for ONNX export improvements

### **Option 3: Use PyTorch Models Directly**

Models are saved as PyTorch state dicts (`.pth` files) and can be used directly:
- Load models in Python backend
- Run inference in Python
- Send results to Dart/Flutter via API

---

## 📊 **Model Output Format**

### **Quantum Optimization Model**

**Input:** 13 values (12 SPOTS dimensions + 1 use case encoding)  
**Output:** 18 values combined:
- Indices 0-4: Weights (5 values, one per data source)
- Index 5: Threshold (1 value)
- Indices 6-17: Basis importance (12 values, one per dimension)

**Dart Integration:**
- The `QuantumMLOptimizer` service has been updated to parse the combined output
- Output is cached to avoid multiple model calls
- Each method extracts the relevant portion of the combined output

### **Entanglement Detection Model**

**Input:** 12 values (12 SPOTS dimensions)  
**Output:** 66 values (one per dimension pair: 12*11/2 = 66)

**Dart Integration:**
- The `QuantumEntanglementMLService` expects 66 correlation values
- Values are parsed into entanglement map by dimension pairs

---

## 🔧 **Export Script**

A dedicated export script is available:

```bash
python scripts/ml/export_quantum_models_to_onnx.py \
  --model [optimization|entanglement] \
  --pth-path <path_to_pth_file> \
  --onnx-path <path_to_output_onnx_file>
```

**Script Location:** `scripts/ml/export_quantum_models_to_onnx.py`

---

## ✅ **Current Status**

### **Training:**
- ✅ Quantum optimization model: Trained (50 epochs)
- ✅ Entanglement model: Trained (100 epochs)
- ✅ Models saved as PyTorch state dicts (`.pth` files)

### **ONNX Export:**
- ⚠️ ONNX export fails with PyTorch 2.10.0 (Union type error)
- ✅ Workaround available (PyTorch 2.0.0)
- ✅ Export script created
- ✅ Dart services updated to handle combined output format

### **Dart Integration:**
- ✅ `QuantumMLOptimizer` updated to parse combined output
- ✅ Output caching implemented to avoid multiple calls
- ✅ `QuantumEntanglementMLService` ready for ONNX model

---

## 📝 **Next Steps**

1. **Export ONNX Models:**
   ```bash
   # Use PyTorch 2.0.0 environment
   source venv_onnx_export/bin/activate
   python scripts/ml/export_quantum_models_to_onnx.py --model optimization ...
   python scripts/ml/export_quantum_models_to_onnx.py --model entanglement ...
   ```

2. **Verify Models:**
   - Place ONNX models in `assets/models/`
   - Models will be automatically loaded by Dart services
   - Services will use ML predictions instead of defaults

3. **Test Integration:**
   - Run app and verify models load
   - Test quantum optimization features
   - Test entanglement detection features
   - Verify fallback behavior when models unavailable

---

## 📚 **References**

- **Training Scripts:** `scripts/ml/train_quantum_optimization_model.py`, `scripts/ml/train_entanglement_model.py`
- **Export Script:** `scripts/ml/export_quantum_models_to_onnx.py`
- **Dart Services:** `lib/core/ai/quantum/quantum_ml_optimizer.dart`, `lib/core/ai/quantum/quantum_entanglement_ml_service.dart`
- **PyTorch ONNX Export Docs:** https://pytorch.org/docs/stable/onnx.html

---

**Last Updated:** January 27, 2026

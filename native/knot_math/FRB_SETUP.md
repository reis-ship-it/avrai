# Flutter Rust Bridge Setup Guide

**Status:** ⏳ Configuration in Progress

---

## Current Status

The FFI API functions are defined in `src/api.rs` with proper types. However, the full flutter_rust_bridge codegen setup requires additional configuration.

---

## Next Steps for Complete FFI Setup

### Option 1: Manual FFI Setup (Simpler for now)

For Week 2, we can use manual FFI bindings or defer full flutter_rust_bridge setup to Week 4 when integrating with Dart.

**Current API Functions (Ready for FFI):**
- `generate_knot_from_braid()` - Generate knot from braid data
- `calculate_jones_polynomial()` - Calculate Jones polynomial
- `calculate_alexander_polynomial()` - Calculate Alexander polynomial
- `calculate_topological_compatibility()` - Calculate compatibility between knots
- `calculate_writhe_from_braid()` - Calculate writhe
- `calculate_crossing_number_from_braid()` - Calculate crossing number
- `evaluate_polynomial()` - Evaluate polynomial at point
- `polynomial_distance()` - Calculate distance between polynomials

### Option 2: Complete flutter_rust_bridge Setup

1. **Create `frb.yaml` configuration file:**
   ```yaml
   rust:
     crate: "knot_math"
     path: "native/knot_math"
   
   dart:
     path: "lib/core/services/knot/bridge"
   ```

2. **Run codegen manually:**
   ```bash
   flutter_rust_bridge_codegen generate
   ```

3. **Or use build.rs with correct API:**
   - Check flutter_rust_bridge 2.0 documentation for exact API
   - May require different configuration format

---

## Recommendation

For Week 2 completion, we can:
1. ✅ Keep API functions defined (done)
2. ✅ Ensure all types are FFI-compatible (done)
3. ⏳ Complete flutter_rust_bridge setup in Week 4 during Dart integration

This allows us to:
- Complete Week 2 core math work
- Test all Rust functions independently
- Set up FFI properly when integrating with Dart in Week 4

---

**Note:** The API functions are ready and FFI-compatible. The codegen setup can be completed when we integrate with Dart in Week 4.

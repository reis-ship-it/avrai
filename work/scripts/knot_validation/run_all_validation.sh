#!/bin/bash
# Master validation script for Phase 0 - Patent #31
# Runs all validation scripts and generates comprehensive report

set -e

echo "=========================================="
echo "Phase 0 Validation - Patent #31"
echo "Knot Theory Integration Validation"
echo "=========================================="
echo ""

# Configuration
VALIDATION_DIR="docs/plans/knot_theory/validation"
SCRIPTS_DIR="scripts/knot_validation"

# Create validation directory
mkdir -p "$VALIDATION_DIR"

echo "Step 1: Generating knots from personality profiles..."
python3 "$SCRIPTS_DIR/generate_knots_from_profiles.py"
echo "✓ Knot generation complete"
echo ""

echo "Step 2: Comparing matching accuracy..."
python3 "$SCRIPTS_DIR/compare_matching_accuracy.py"
echo "✓ Matching accuracy comparison complete"
echo ""

echo "Step 3: Analyzing recommendation improvement..."
python3 "$SCRIPTS_DIR/analyze_recommendation_improvement.py"
echo "✓ Recommendation analysis complete"
echo ""

echo "Step 4: Assessing research value..."
python3 "$SCRIPTS_DIR/assess_research_value.py"
echo "✓ Research value assessment complete"
echo ""

echo "Step 5: Running edge case tests..."
python3 "$SCRIPTS_DIR/test_edge_cases.py"
echo "✓ Edge case testing complete"
echo ""

echo "Step 6: Performing cross-validation..."
python3 "$SCRIPTS_DIR/cross_validate.py"
echo "✓ Cross-validation complete"
echo ""

echo "=========================================="
echo "VALIDATION COMPLETE"
echo "=========================================="
echo ""
echo "Results saved to: $VALIDATION_DIR"
echo ""
echo "Next Steps:"
echo "  1. Review validation results"
echo "  2. Review edge case test results"
echo "  3. Review cross-validation results"
echo "  4. Create Phase 0 Validation Report"
echo "  5. Make go/no-go decision"
echo ""


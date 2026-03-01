# Test Refactoring Documentation

This directory contains documentation and tools for refactoring the SPOTS test suite to follow best practices.

## Files

- **`TEST_REFACTORING_PLAN.md`** - Comprehensive refactoring plan with patterns and examples
- **`test_quality_analysis_report.txt`** - Generated analysis report (run script to create)
- **`test_quality_analysis.json`** - JSON export of analysis results (run script to create)

## Quick Start

### 1. Run Analysis Script

```bash
# Analyze model tests (default)
python3 scripts/analyze_test_quality.py

# Analyze specific directory
python3 scripts/analyze_test_quality.py test/unit/services/

# Analyze all unit tests
python3 scripts/analyze_test_quality.py test/unit/
```

### 2. Review Report

The script generates:
- **Text Report**: `docs/plans/test_refactoring/test_quality_analysis_report.txt`
- **JSON Export**: `docs/plans/test_refactoring/test_quality_analysis.json`

### 3. Start Refactoring

Follow the plan in `TEST_REFACTORING_PLAN.md`, starting with the highest priority files.

## What the Script Identifies

1. **Property Assignment Tests** - Tests that only check if properties are set correctly
2. **Trivial Checks** - Tests for null/empty/single item that test language features
3. **JSON Field Tests** - Tests that check JSON fields individually instead of round-trip
4. **Granular Edge Cases** - Multiple similar tests that could be consolidated

## Refactoring Patterns

See `TEST_REFACTORING_PLAN.md` for detailed patterns and examples of:
- What to remove
- What to consolidate
- What to keep
- How to refactor

## Success Metrics

- 40-50% reduction in test count
- Faster test execution
- Same or better coverage
- All tests still pass

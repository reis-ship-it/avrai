# Test Failure Fix Automation Guide

**Created:** December 7, 2025  
**Purpose:** Guide for automating and fixing test failures

## Overview

This document explains how to fix the 75 remaining test failures in the services directory. Most failures fall into three categories:

1. **Compilation Errors** (~10-15 failures) - Can be mostly automated
2. **Runtime Errors** (~542 failures - platform channel issues) - Requires infrastructure changes
3. **Test Logic Errors** (~9 failures) - Requires manual review

## Automation Strategy

### ✅ What CAN Be Automated

1. **Compilation Errors:**
   - Missing parameters (add default values)
   - Wrong parameter names (fix based on mappings)
   - Missing imports (add automatically)
   - Import conflicts (use aliases)
   - Constant evaluation errors (remove const keyword)
   - Missing mock file generation

2. **Common Patterns:**
   - `UnifiedUser(name:)` → `UnifiedUser(displayName:)`
   - `ExpertiseEvent` missing `category` parameter
   - `ModelFactories.createTestUser(location:)` → remove location
   - `PersonalityProfile.initial(agentId:)` → positional parameter
   - `const 'A' * 1000` → remove const

### ❌ What CANNOT Be Fully Automated

1. **Runtime Errors:**
   - Platform channel issues (542 failures) require mock infrastructure
   - Null safety violations need code analysis
   - Type mismatches need understanding of data flow

2. **Test Logic Errors:**
   - Wrong expectations need domain knowledge
   - Missing test setup requires understanding dependencies
   - Assertion failures need code review

## Scripts Available

### 1. Test Compilation Error Fixer

**Script:** `scripts/fix_test_compilation_errors.py`

**What it fixes:**
- UnifiedUser parameter name fixes
- ExpertiseEvent missing category
- Constant evaluation errors
- Location parameter removal
- PersonalityProfile initial fixes

**Usage:**
```bash
# Dry run
python3 scripts/fix_test_compilation_errors.py --dry-run

# Apply fixes
python3 scripts/fix_test_compilation_errors.py

# Generate mocks
python3 scripts/fix_test_compilation_errors.py --generate-mocks
```

### 2. Test Failure Analyzer

**Script:** `scripts/analyze_test_failures.py`

**What it does:**
- Analyzes test failures
- Categorizes errors
- Identifies fixable patterns
- Generates fix recommendations

**Usage:**
```bash
python3 scripts/analyze_test_failures.py test/unit/services/
```

## Manual Fix Process

### Step 1: Fix Compilation Errors First

These block all other tests from running:

```bash
# Run analysis
python3 scripts/analyze_test_failures.py

# Apply automated fixes
python3 scripts/fix_test_compilation_errors.py --dry-run
python3 scripts/fix_test_compilation_errors.py

# Generate missing mocks
dart run build_runner build --delete-conflicting-outputs
```

### Step 2: Fix Runtime Errors

Most runtime errors are platform channel issues. Solutions:

1. **Use Mock Storage** (recommended)
2. **Dependency Injection** (long-term)
3. **Test Helpers** (short-term)

### Step 3: Fix Test Logic

Review and fix assertion mismatches manually.

## Common Error Patterns & Fixes

### Pattern 1: Missing Parameter

**Error:**
```
Error: Required named parameter 'category' must be provided.
```

**Fix:**
```dart
// Before
ExpertiseEvent(
  id: 'event-1',
  host: host,
  title: 'Test Event',
)

// After
ExpertiseEvent(
  id: 'event-1',
  host: host,
  title: 'Test Event',
  category: 'General', // Add missing parameter
)
```

### Pattern 2: Wrong Parameter Name

**Error:**
```
Error: No named parameter with the name 'name'.
```

**Fix:**
```dart
// Before
UnifiedUser(
  id: 'user-1',
  name: 'Test User',
)

// After
UnifiedUser(
  id: 'user-1',
  displayName: 'Test User',
)
```

### Pattern 3: Missing Mock File

**Error:**
```
Error when reading 'test/unit/services/test.mocks.dart': No such file or directory
```

**Fix:**
```bash
# Generate mocks
dart run build_runner build --delete-conflicting-outputs
```

### Pattern 4: Import Conflict

**Error:**
```
Error: 'EventRecommendation' is imported from both 'package:...' and 'package:...'
```

**Fix:**
```dart
// Use alias
import 'package:spots/core/services/event_recommendation_service.dart' as service;
import 'package:spots/core/models/event_recommendation.dart';

// Use qualified name
service.EventRecommendationService(...)
```

### Pattern 5: Constant Evaluation Error

**Error:**
```
Error: Constant evaluation error: The method '*' can't be invoked on '"A"' in a const expression.
```

**Fix:**
```dart
// Before
const content = 'A' * 1000;

// After
final content = 'A' * 1000; // Remove const
```

## Priority Order

1. **Compilation Errors** (blocks everything)
2. **Missing Mock Files** (blocks tests)
3. **Runtime Errors** (platform channel infrastructure)
4. **Test Logic Errors** (manual review)

## Status

**Current:** 75 test failures  
**Target:** 0 failures (99%+ pass rate)  
**Automation:** Partial (compilation errors can be automated)


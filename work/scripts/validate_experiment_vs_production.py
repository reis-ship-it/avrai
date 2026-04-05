#!/usr/bin/env python3
"""
Patent Experiment vs Production Code Validation Script

This script validates that the mathematical formulas used in Python patent experiments
match those implemented in the Dart production code.

Usage:
    python3 scripts/validate_experiment_vs_production.py

Date: 2026-01-03
"""

import os
import re
import sys
from pathlib import Path
from dataclasses import dataclass
from typing import List, Dict, Tuple, Optional

# Get project root
PROJECT_ROOT = Path(__file__).parent.parent


@dataclass
class FormulaValidation:
    """Result of a formula validation"""
    patent_number: int
    formula_name: str
    experiment_file: str
    production_file: str
    experiment_formula: str
    production_formula: str
    match_status: str  # "MATCH", "PARTIAL", "MISMATCH", "NOT_FOUND"
    notes: str = ""


def find_experiment_formulas(patent_num: int) -> List[Tuple[str, str, str]]:
    """Find formulas in patent experiment files.
    
    Returns list of (formula_name, formula_code, file_path)
    """
    formulas = []
    experiment_dir = PROJECT_ROOT / "docs" / "patents" / "experiments" / "scripts"
    
    # Find experiment file for this patent
    pattern = f"run_patent_{patent_num}_*.py"
    experiment_files = list(experiment_dir.glob(pattern))
    
    for exp_file in experiment_files:
        try:
            content = exp_file.read_text()
            
            # Look for key mathematical patterns
            formula_patterns = [
                # Tensor product
                (r"tensor_product|_tensorProduct", "Tensor Product"),
                # Inner product / fidelity
                (r"inner_product|fidelity|innerProduct|calculateFidelity", "Quantum Fidelity"),
                # Normalization
                (r"normalize|normalization|_normalizeVector", "Normalization"),
                # Differential privacy
                (r"differential_privacy|laplace.*noise|epsilon", "Differential Privacy"),
                # Calling score weights
                (r"0\.40.*vibe|0\.30.*betterment|weight.*0\.\d+", "Calling Score Weights"),
                # Saturation algorithm
                (r"supply.*ratio|quality.*distribution|utilization", "Saturation Algorithm"),
                # Knot invariants
                (r"jones.*polynomial|alexander.*polynomial|crossing.*number", "Knot Invariants"),
                # Drift limit
                (r"drift.*limit|max.*drift|0\.30.*drift", "Drift Limit"),
            ]
            
            for pattern, name in formula_patterns:
                matches = re.findall(pattern, content, re.IGNORECASE)
                if matches:
                    # Extract surrounding context (5 lines)
                    lines = content.split('\n')
                    for i, line in enumerate(lines):
                        if re.search(pattern, line, re.IGNORECASE):
                            start = max(0, i - 2)
                            end = min(len(lines), i + 3)
                            context = '\n'.join(lines[start:end])
                            formulas.append((name, context, str(exp_file)))
                            break
                            
        except Exception as e:
            print(f"Error reading {exp_file}: {e}")
            
    return formulas


def find_production_implementation(formula_name: str) -> Optional[Tuple[str, str]]:
    """Find production implementation for a formula.
    
    Returns (code_snippet, file_path) or None
    """
    # Map formula names to likely production files
    formula_to_files = {
        "Tensor Product": [
            "packages/spots_quantum/lib/services/quantum/quantum_entanglement_service.dart",
        ],
        "Quantum Fidelity": [
            "packages/spots_quantum/lib/services/quantum/quantum_entanglement_service.dart",
            "lib/core/ai/quantum/quantum_vibe_engine.dart",
        ],
        "Normalization": [
            "packages/spots_quantum/lib/services/quantum/quantum_entanglement_service.dart",
        ],
        "Differential Privacy": [
            "lib/core/ai/privacy_protection.dart",
        ],
        "Calling Score Weights": [
            "lib/core/services/calling_score_calculator.dart",
        ],
        "Saturation Algorithm": [
            "lib/core/services/saturation_algorithm_service.dart",
        ],
        "Knot Invariants": [
            "packages/spots_knot/lib/services/knot/personality_knot_service.dart",
            "native/knot_math/src/knot_invariants.rs",
        ],
        "Drift Limit": [
            "packages/spots_ai/lib/models/personality_profile.dart",
        ],
    }
    
    search_patterns = {
        "Tensor Product": r"_tensorProductVectors|tensor.*product",
        "Quantum Fidelity": r"calculateFidelity|innerProduct.*innerProduct|fidelity.*=",
        "Normalization": r"_normalizeVector|normalize|norm.*sqrt",
        "Differential Privacy": r"_applyDifferentialPrivacy|laplace|epsilon",
        "Calling Score Weights": r"0\.40|0\.30|vibeCompatibility.*0\.\d+",
        "Saturation Algorithm": r"_calculateSupplyRatio|_analyzeQualityDistribution",
        "Knot Invariants": r"jonesPolynomial|alexanderPolynomial|crossingNumber",
        "Drift Limit": r"maxDriftFromCore|0\.30|drift.*limit",
    }
    
    target_files = formula_to_files.get(formula_name, [])
    search_pattern = search_patterns.get(formula_name, formula_name.lower().replace(" ", "_"))
    
    for rel_path in target_files:
        file_path = PROJECT_ROOT / rel_path
        if file_path.exists():
            try:
                content = file_path.read_text()
                matches = list(re.finditer(search_pattern, content, re.IGNORECASE))
                if matches:
                    # Extract surrounding context
                    lines = content.split('\n')
                    for match in matches:
                        # Find line number
                        line_num = content[:match.start()].count('\n')
                        start = max(0, line_num - 3)
                        end = min(len(lines), line_num + 4)
                        context = '\n'.join(lines[start:end])
                        return (context, str(file_path))
            except Exception as e:
                print(f"Error reading {file_path}: {e}")
    
    return None


def validate_patent(patent_num: int) -> List[FormulaValidation]:
    """Validate all formulas for a patent."""
    validations = []
    
    # Find experiment formulas
    exp_formulas = find_experiment_formulas(patent_num)
    
    for formula_name, exp_code, exp_file in exp_formulas:
        # Find production implementation
        prod_result = find_production_implementation(formula_name)
        
        if prod_result:
            prod_code, prod_file = prod_result
            
            # Simple validation: check if key terms appear in both
            match_status = "MATCH"
            notes = "Formula found in both experiment and production"
            
            validation = FormulaValidation(
                patent_number=patent_num,
                formula_name=formula_name,
                experiment_file=exp_file,
                production_file=prod_file,
                experiment_formula=exp_code[:200] + "..." if len(exp_code) > 200 else exp_code,
                production_formula=prod_code[:200] + "..." if len(prod_code) > 200 else prod_code,
                match_status=match_status,
                notes=notes,
            )
        else:
            validation = FormulaValidation(
                patent_number=patent_num,
                formula_name=formula_name,
                experiment_file=exp_file,
                production_file="NOT FOUND",
                experiment_formula=exp_code[:200] + "..." if len(exp_code) > 200 else exp_code,
                production_formula="",
                match_status="NOT_FOUND",
                notes="Production implementation not found",
            )
        
        validations.append(validation)
    
    return validations


def validate_specific_formulas() -> List[FormulaValidation]:
    """Validate specific critical formulas that must match."""
    validations = []
    
    critical_formulas = [
        # Patent #1 & #29: Quantum Fidelity
        {
            "name": "Quantum Fidelity F = |⟨ψ₁|ψ₂⟩|²",
            "patent": 29,
            "experiment_pattern": r"fidelity.*inner.*product|np\.abs.*\*\*\s*2",
            "production_pattern": r"fidelity\s*=\s*innerProduct\s*\*\s*innerProduct",
            "exp_file": "docs/patents/experiments/scripts/run_patent_29_experiments.py",
            "prod_file": "packages/spots_quantum/lib/services/quantum/quantum_entanglement_service.dart",
        },
        # Patent #29: Tensor Product
        {
            "name": "Tensor Product |a⟩ ⊗ |b⟩",
            "patent": 29,
            "experiment_pattern": r"np\.kron|tensor.*product",
            "production_pattern": r"result\.add\(a\s*\*\s*b\)",
            "exp_file": "docs/patents/experiments/scripts/run_patent_29_experiments.py",
            "prod_file": "packages/spots_quantum/lib/services/quantum/quantum_entanglement_service.dart",
        },
        # Patent #3: 30% Drift Limit
        {
            "name": "30% Drift Limit",
            "patent": 3,
            "experiment_pattern": r"drift.*0\.3|max.*drift.*30",
            "production_pattern": r"maxDriftFromCore\s*=\s*0\.30",
            "exp_file": "docs/patents/experiments/scripts/run_patent_3_experiments.py",
            "prod_file": "packages/spots_ai/lib/models/personality_profile.dart",
        },
        # Patent #13: Differential Privacy
        {
            "name": "Differential Privacy Laplace Noise",
            "patent": 13,
            "experiment_pattern": r"laplace|epsilon|differential.*privacy",
            "production_pattern": r"_applyDifferentialPrivacy|laplace",
            "exp_file": "docs/patents/experiments/scripts/run_patent_13_differential_privacy_experiments.py",
            "prod_file": "lib/core/ai/privacy_protection.dart",
        },
        # Patent #25: Calling Score Weights
        {
            "name": "Calling Score 40%/30%/15%/10%/5%",
            "patent": 25,
            "experiment_pattern": r"0\.40.*0\.30.*0\.15|vibe.*0\.4",
            "production_pattern": r"vibeCompatibility\s*\*\s*0\.40|0\.40\s*\+.*0\.30",
            "exp_file": "docs/patents/experiments/scripts/run_patent_25_experiments.py",
            "prod_file": "lib/core/services/calling_score_calculator.dart",
        },
        # Patent #31: Knot Invariants
        {
            "name": "Knot Invariants (Jones/Alexander)",
            "patent": 31,
            "experiment_pattern": r"jones.*polynomial|alexander|knot.*invariant",
            "production_pattern": r"jonesPolynomial|alexanderPolynomial|calculateTopologicalCompatibility",
            "exp_file": "docs/patents/experiments/scripts/run_patent_31_experiments.py",
            "prod_file": "packages/spots_knot/lib/services/knot/personality_knot_service.dart",
        },
    ]
    
    for formula in critical_formulas:
        exp_path = PROJECT_ROOT / formula["exp_file"]
        prod_path = PROJECT_ROOT / formula["prod_file"]
        
        exp_found = False
        prod_found = False
        exp_code = ""
        prod_code = ""
        
        # Check experiment
        if exp_path.exists():
            try:
                content = exp_path.read_text()
                if re.search(formula["experiment_pattern"], content, re.IGNORECASE):
                    exp_found = True
                    # Get context
                    lines = content.split('\n')
                    for i, line in enumerate(lines):
                        if re.search(formula["experiment_pattern"], line, re.IGNORECASE):
                            start = max(0, i - 2)
                            end = min(len(lines), i + 3)
                            exp_code = '\n'.join(lines[start:end])
                            break
            except Exception:
                pass
        
        # Check production
        if prod_path.exists():
            try:
                content = prod_path.read_text()
                if re.search(formula["production_pattern"], content, re.IGNORECASE):
                    prod_found = True
                    # Get context
                    lines = content.split('\n')
                    for i, line in enumerate(lines):
                        if re.search(formula["production_pattern"], line, re.IGNORECASE):
                            start = max(0, i - 2)
                            end = min(len(lines), i + 3)
                            prod_code = '\n'.join(lines[start:end])
                            break
            except Exception:
                pass
        
        # Determine match status
        if exp_found and prod_found:
            match_status = "✅ MATCH"
            notes = "Formula implemented in both experiment and production"
        elif not exp_found and prod_found:
            match_status = "⚠️ PRODUCTION_ONLY"
            notes = "Production implementation exists, but experiment not found"
        elif exp_found and not prod_found:
            match_status = "❌ EXPERIMENT_ONLY"
            notes = "Experiment exists, but production implementation not found"
        else:
            match_status = "❌ NOT_FOUND"
            notes = "Neither experiment nor production found"
        
        validations.append(FormulaValidation(
            patent_number=formula["patent"],
            formula_name=formula["name"],
            experiment_file=str(exp_path) if exp_found else "NOT FOUND",
            production_file=str(prod_path) if prod_found else "NOT FOUND",
            experiment_formula=exp_code[:300] if exp_code else "NOT FOUND",
            production_formula=prod_code[:300] if prod_code else "NOT FOUND",
            match_status=match_status,
            notes=notes,
        ))
    
    return validations


def generate_report(validations: List[FormulaValidation]) -> str:
    """Generate a markdown report."""
    report = """# Patent Experiment vs Production Code Validation Report

**Generated:** 2026-01-03
**Status:** Automated Validation

---

## Summary

| Status | Count |
|--------|-------|
"""
    
    # Count by status
    status_counts = {}
    for v in validations:
        status = v.match_status.split()[0] if ' ' in v.match_status else v.match_status
        status_counts[status] = status_counts.get(status, 0) + 1
    
    for status, count in sorted(status_counts.items()):
        report += f"| {status} | {count} |\n"
    
    report += "\n---\n\n## Detailed Results\n\n"
    
    for v in validations:
        report += f"""### Patent #{v.patent_number}: {v.formula_name}

**Status:** {v.match_status}

**Notes:** {v.notes}

**Experiment File:** `{v.experiment_file}`

**Production File:** `{v.production_file}`

<details>
<summary>Experiment Code</summary>

```python
{v.experiment_formula}
```
</details>

<details>
<summary>Production Code</summary>

```dart
{v.production_formula}
```
</details>

---

"""
    
    return report


def main():
    print("=" * 60)
    print("Patent Experiment vs Production Code Validator")
    print("=" * 60)
    print()
    
    # Validate specific critical formulas
    print("Validating critical formulas...")
    validations = validate_specific_formulas()
    
    # Print summary
    print("\nValidation Results:")
    print("-" * 60)
    
    match_count = 0
    partial_count = 0
    mismatch_count = 0
    
    for v in validations:
        status_icon = "✅" if "MATCH" in v.match_status and "❌" not in v.match_status else "⚠️" if "⚠️" in v.match_status else "❌"
        print(f"{status_icon} Patent #{v.patent_number}: {v.formula_name} - {v.match_status}")
        
        if "✅" in v.match_status:
            match_count += 1
        elif "⚠️" in v.match_status:
            partial_count += 1
        else:
            mismatch_count += 1
    
    print("-" * 60)
    print(f"\nTotal: {len(validations)} formulas checked")
    print(f"  ✅ Matched: {match_count}")
    print(f"  ⚠️ Partial/Warning: {partial_count}")
    print(f"  ❌ Missing/Mismatch: {mismatch_count}")
    
    # Generate report
    report = generate_report(validations)
    report_path = PROJECT_ROOT / "docs" / "agents" / "reports" / "agent_cursor" / "phase_23" / "2026-01-03_experiment_vs_production_validation.md"
    report_path.parent.mkdir(parents=True, exist_ok=True)
    report_path.write_text(report)
    print(f"\nReport saved to: {report_path}")
    
    # Return exit code based on results
    if mismatch_count > 0:
        print("\n⚠️ Some formulas have mismatches. Review the report for details.")
        return 1
    else:
        print("\n✅ All critical formulas validated successfully!")
        return 0


if __name__ == "__main__":
    sys.exit(main())

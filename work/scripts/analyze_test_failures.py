#!/usr/bin/env python3
"""
Test Failure Analysis Script

Analyzes test failures and categorizes them for automated fixing.

Usage:
    python scripts/analyze_test_failures.py [test_path]
"""

import re
import subprocess
import sys
from pathlib import Path
from typing import List, Dict, Tuple
from dataclasses import dataclass, field
from collections import defaultdict

@dataclass
class TestError:
    """Represents a test error"""
    file_path: str
    line_number: int
    error_type: str
    error_message: str
    error_context: str = ""


@dataclass
class ErrorCategory:
    """Category of errors"""
    category_name: str
    errors: List[TestError] = field(default_factory=list)
    fixable: bool = False
    fix_description: str = ""


class TestFailureAnalyzer:
    """Analyzes test failures and categorizes them"""
    
    def __init__(self):
        self.errors: List[TestError] = []
        self.categories: Dict[str, ErrorCategory] = {}
        
    def run_tests(self, test_path: str = "test/unit/services/") -> str:
        """Run tests and capture output"""
        print(f"Running tests in: {test_path}")
        print("This may take a few minutes...")
        
        result = subprocess.run(
            ["flutter", "test", test_path],
            capture_output=True,
            text=True,
            cwd=Path.cwd()
        )
        
        return result.stdout + result.stderr
    
    def parse_compilation_errors(self, output: str) -> List[TestError]:
        """Parse compilation errors from test output"""
        errors = []
        
        # Pattern: Compilation failed for testPath=...: file:line: Error: message
        pattern = re.compile(
            r'Compilation failed for testPath=(.+?):\s*(.+?):(\d+):(\d+):\s*Error:\s*(.+?)\n',
            re.MULTILINE
        )
        
        for match in pattern.finditer(output):
            file_path = match.group(1)
            error_file = match.group(2)
            line = int(match.group(3))
            message = match.group(5)
            
            errors.append(TestError(
                file_path=error_file,
                line_number=line,
                error_type="compilation",
                error_message=message,
                error_context=file_path
            ))
        
        return errors
    
    def categorize_errors(self, errors: List[TestError]) -> Dict[str, ErrorCategory]:
        """Categorize errors by type"""
        categories = defaultdict(lambda: ErrorCategory(category_name="", errors=[], fixable=False))
        
        for error in errors:
            category_name = self._determine_category(error)
            if category_name not in categories:
                categories[category_name] = ErrorCategory(
                    category_name=category_name,
                    errors=[],
                    fixable=self._is_fixable(category_name),
                    fix_description=self._get_fix_description(category_name)
                )
            categories[category_name].errors.append(error)
        
        return dict(categories)
    
    def _determine_category(self, error: TestError) -> str:
        """Determine error category from error message"""
        msg = error.error_message.lower()
        
        if "no named parameter" in msg:
            return "missing_parameter"
        elif "member not found" in msg or "isn't defined" in msg or "getter" in msg and "isn't defined" in msg:
            return "missing_member"
        elif "too few.*arguments" in msg or "too many.*arguments" in msg:
            return "wrong_arguments"
        elif "imported from both" in msg:
            return "import_conflict"
        elif "no such file" in msg or "error when reading" in msg:
            return "missing_file"
        elif "mock" in msg and "isn't a type" in msg:
            return "missing_mock"
        elif "constant evaluation error" in msg:
            return "constant_error"
        elif "type.*can't be assigned" in msg:
            return "type_mismatch"
        else:
            return "other"
    
    def _is_fixable(self, category: str) -> bool:
        """Determine if category is automatically fixable"""
        fixable_categories = [
            "missing_parameter",
            "missing_member",
            "wrong_arguments",
            "import_conflict",
            "constant_error",
        ]
        return category in fixable_categories
    
    def _get_fix_description(self, category: str) -> str:
        """Get description of how to fix this category"""
        descriptions = {
            "missing_parameter": "Add missing parameter or remove invalid parameter",
            "missing_member": "Fix method/getter name or add missing member",
            "wrong_arguments": "Fix argument count or types",
            "import_conflict": "Use import alias to resolve conflict",
            "missing_file": "Create missing file or fix import path",
            "missing_mock": "Generate mock files using build_runner",
            "constant_error": "Fix constant expression",
            "type_mismatch": "Fix type mismatch in assignment",
            "other": "Manual review required"
        }
        return descriptions.get(category, "Manual review required")
    
    def generate_report(self, categories: Dict[str, ErrorCategory]) -> str:
        """Generate analysis report"""
        report = []
        report.append("=" * 80)
        report.append("TEST FAILURE ANALYSIS REPORT")
        report.append("=" * 80)
        report.append("")
        
        total_errors = sum(len(cat.errors) for cat in categories.values())
        report.append(f"Total Errors Found: {total_errors}")
        report.append("")
        
        # Sort by error count (descending)
        sorted_categories = sorted(
            categories.items(),
            key=lambda x: len(x[1].errors),
            reverse=True
        )
        
        for category_name, category in sorted_categories:
            error_count = len(category.errors)
            fixable_icon = "✅" if category.fixable else "⚠️"
            
            report.append(f"{fixable_icon} {category_name.upper().replace('_', ' ')} ({error_count} errors)")
            report.append(f"   Fixable: {category.fixable}")
            report.append(f"   Fix: {category.fix_description}")
            report.append("")
            
            # Show first 3 errors as examples
            for error in category.errors[:3]:
                report.append(f"   - {error.file_path}:{error.line_number}")
                report.append(f"     {error.error_message[:100]}...")
            
            if error_count > 3:
                report.append(f"   ... and {error_count - 3} more")
            
            report.append("")
        
        return "\n".join(report)
    
    def analyze(self, test_path: str = "test/unit/services/") -> str:
        """Run complete analysis"""
        print("Running tests and analyzing failures...")
        output = self.run_tests(test_path)
        
        print("Parsing compilation errors...")
        errors = self.parse_compilation_errors(output)
        
        print(f"Found {len(errors)} compilation errors")
        
        print("Categorizing errors...")
        categories = self.categorize_errors(errors)
        
        print("Generating report...")
        report = self.generate_report(categories)
        
        return report


def main():
    test_path = sys.argv[1] if len(sys.argv) > 1 else "test/unit/services/"
    
    analyzer = TestFailureAnalyzer()
    report = analyzer.analyze(test_path)
    
    print("\n" + report)
    
    # Save report
    report_path = Path("docs/test_failure_analysis_report.md")
    report_path.parent.mkdir(parents=True, exist_ok=True)
    report_path.write_text(report)
    print(f"\nReport saved to: {report_path}")


if __name__ == '__main__':
    main()


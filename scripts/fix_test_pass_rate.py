#!/usr/bin/env python3
"""
Test Pass Rate Fix Automation Script
Purpose: Automate fixes for common test failure patterns to achieve 99%+ pass rate
Date: December 7, 2025
"""

import re
import subprocess
import sys
from pathlib import Path
from typing import List, Dict, Tuple
from dataclasses import dataclass
from collections import defaultdict

@dataclass
class TestFailure:
    """Represents a test failure"""
    file_path: str
    test_name: str
    error_type: str
    error_message: str
    line_number: int = 0
    fixable: bool = False
    fix_suggestion: str = ""

class TestFailureAnalyzer:
    """Analyzes and fixes test failures"""
    
    def __init__(self, project_dir: str = "/Users/reisgordon/SPOTS"):
        self.project_dir = Path(project_dir)
        self.failures: List[TestFailure] = []
        self.patterns = {
            'mock_setup': [
                r"Cannot call `when` within a stub response",
                r"MissingStubError",
                r"NoSuchMethodError.*when",
            ],
            'numeric_precision': [
                r"differs by",
                r"Expected:.*Actual:",
            ],
            'compilation': [
                r"Error:.*isn't a type",
                r"Error:.*isn't defined",
                r"Error:.*not found",
            ],
            'business_logic': [
                r"Payment not found",
                r"Event not found",
                r"Permission.*denied",
                r"geographic restriction",
            ],
        }
    
    def run_tests(self, test_path: str = "test/unit") -> str:
        """Run tests and capture output"""
        print(f"Running tests in: {test_path}...")
        result = subprocess.run(
            ["flutter", "test", test_path],
            capture_output=True,
            text=True,
            cwd=self.project_dir
        )
        return result.stdout + result.stderr
    
    def parse_failures(self, output: str) -> List[TestFailure]:
        """Parse test failures from output"""
        failures = []
        
        # Pattern: test/file.dart: Test Name [E]
        test_pattern = re.compile(
            r'(\S+\.dart):\s+(.+?)\s+\[E\]',
            re.MULTILINE
        )
        
        # Pattern: Error message
        error_pattern = re.compile(
            r'Error:\s*(.+?)(?:\n|$)',
            re.MULTILINE
        )
        
        current_file = None
        current_test = None
        
        for line in output.split('\n'):
            # Match test failure
            test_match = test_pattern.search(line)
            if test_match:
                current_file = test_match.group(1)
                current_test = test_match.group(2)
                continue
            
            # Match error
            error_match = error_pattern.search(line)
            if error_match and current_file:
                error_msg = error_match.group(1)
                error_type = self._categorize_error(error_msg)
                
                failure = TestFailure(
                    file_path=current_file,
                    test_name=current_test or "Unknown",
                    error_type=error_type,
                    error_message=error_msg,
                    fixable=self._is_fixable(error_type, error_msg)
                )
                failures.append(failure)
        
        return failures
    
    def _categorize_error(self, error_msg: str) -> str:
        """Categorize error type"""
        for category, patterns in self.patterns.items():
            for pattern in patterns:
                if re.search(pattern, error_msg, re.IGNORECASE):
                    return category
        return "unknown"
    
    def _is_fixable(self, error_type: str, error_msg: str) -> bool:
        """Determine if error can be auto-fixed"""
        fixable_types = ['mock_setup', 'numeric_precision', 'compilation']
        return error_type in fixable_types
    
    def fix_mock_setup(self, file_path: str) -> bool:
        """Fix mock setup issues in a file"""
        file = self.project_dir / file_path
        
        if not file.exists():
            return False
        
        content = file.read_text()
        original = content
        
        # Pattern: when() called inside stub response
        # Fix: Move when() calls outside
        
        # This is complex and requires understanding the structure
        # For now, provide a template fix
        if "Cannot call `when` within a stub response" in content:
            print(f"  ⚠️  Mock setup issue in {file_path} requires manual restructuring")
            print(f"     Pattern: Move when() calls outside of stub responses")
            return False
        
        return content != original
    
    def fix_numeric_precision(self, file_path: str) -> bool:
        """Fix numeric precision issues"""
        file = self.project_dir / file_path
        
        if not file.exists():
            return False
        
        content = file.read_text()
        original = content
        
        # Pattern: closeTo(0.01) when difference is larger
        # Fix: Increase tolerance
        
        # Find closeTo patterns with small tolerances
        pattern = r'closeTo\(0\.0?1\)'
        matches = list(re.finditer(pattern, content))
        
        if matches:
            print(f"  Found {len(matches)} potential precision issues in {file_path}")
            print(f"  Consider adjusting tolerance values")
            # Don't auto-fix, require manual review
            return False
        
        return content != original
    
    def fix_compilation_errors(self, file_path: str) -> bool:
        """Fix compilation errors"""
        file = self.project_dir / file_path
        
        if not file.exists():
            return False
        
        content = file.read_text()
        original = content
        
        # Fix: UnifiedUser import
        if "UnifiedUser" in content and "import.*unified_user" not in content:
            # Add import at top
            import_line = "import 'package:spots/core/models/unified_user.dart';"
            if import_line not in content:
                # Find last import
                import_pattern = r'(import\s+[\'"].*?[\'"];\s*\n)'
                imports = list(re.finditer(import_pattern, content))
                if imports:
                    last_import = imports[-1]
                    insert_pos = last_import.end()
                    content = content[:insert_pos] + import_line + "\n" + content[insert_pos:]
                    print(f"  ✅ Added UnifiedUser import to {file_path}")
        
        # Fix: PaymentStatus import
        if "PaymentStatus" in content and "import.*payment" not in content:
            # Try to find payment-related import
            if "import.*payment" not in content.lower():
                print(f"  ⚠️  PaymentStatus may need import in {file_path}")
        
        if content != original:
            file.write_text(content)
            return True
        
        return False
    
    def generate_report(self, failures: List[TestFailure]) -> str:
        """Generate analysis report"""
        by_category = defaultdict(list)
        for failure in failures:
            by_category[failure.error_type].append(failure)
        
        report = f"""# Test Failure Analysis Report

**Generated:** {subprocess.check_output(['date']).decode().strip()}
**Total Failures:** {len(failures)}

---

## Summary by Category

"""
        
        for category, category_failures in sorted(by_category.items()):
            fixable = sum(1 for f in category_failures if f.fixable)
            report += f"### {category.title()} ({len(category_failures)} failures, {fixable} fixable)\n\n"
            
            # Group by file
            by_file = defaultdict(list)
            for f in category_failures:
                by_file[f.file_path].append(f)
            
            for file_path, file_failures in sorted(by_file.items()):
                report += f"- **{file_path}**: {len(file_failures)} failures\n"
            
            report += "\n"
        
        return report
    
    def run_analysis(self, test_path: str = "test/unit") -> Dict:
        """Run full analysis"""
        print("=" * 60)
        print("Test Failure Analysis")
        print("=" * 60)
        
        # Run tests
        output = self.run_tests(test_path)
        
        # Parse failures
        print("\nParsing failures...")
        failures = self.parse_failures(output)
        
        print(f"\nFound {len(failures)} failures")
        
        # Categorize
        by_category = defaultdict(list)
        for failure in failures:
            by_category[failure.error_type].append(failure)
        
        print("\nBreakdown:")
        for category, category_failures in sorted(by_category.items()):
            fixable = sum(1 for f in category_failures if f.fixable)
            print(f"  {category}: {len(category_failures)} ({fixable} fixable)")
        
        # Generate report
        report = self.generate_report(failures)
        report_file = self.project_dir / "docs" / "reports" / "test_fixes" / f"analysis_{subprocess.check_output(['date', '+%Y%m%d_%H%M%S']).decode().strip()}.md"
        report_file.parent.mkdir(parents=True, exist_ok=True)
        report_file.write_text(report)
        
        print(f"\n✅ Report saved to: {report_file}")
        
        return {
            'failures': failures,
            'by_category': dict(by_category),
            'report_file': str(report_file)
        }

def main():
    import argparse
    
    parser = argparse.ArgumentParser(description="Fix test failures to achieve 99%+ pass rate")
    parser.add_argument('--analyze', action='store_true', help='Analyze test failures')
    parser.add_argument('--fix-all', action='store_true', help='Apply all automated fixes')
    parser.add_argument('--test-path', default='test/unit', help='Test path to analyze')
    
    args = parser.parse_args()
    
    analyzer = TestFailureAnalyzer()
    
    if args.analyze or not any(vars(args).values()):
        result = analyzer.run_analysis(args.test_path)
        print(f"\n✅ Analysis complete. {len(result['failures'])} failures found.")
    
    if args.fix_all:
        print("\nApplying automated fixes...")
        # This would apply fixes based on analysis
        print("⚠️  Automated fixes require manual review for safety")

if __name__ == "__main__":
    main()


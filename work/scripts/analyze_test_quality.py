#!/usr/bin/env python3
"""
Test Quality Analysis Script

Analyzes test files to identify low-value tests that should be refactored.
Identifies:
- Property assignment tests
- Trivial null/empty checks
- Over-granular edge case tests
- Redundant JSON serialization tests

Usage:
    python3 scripts/analyze_test_quality.py [test_directory]
    
    Default: analyzes entire test/ directory (all test files)
    
    Examples:
        python3 scripts/analyze_test_quality.py                    # All tests
        python3 scripts/analyze_test_quality.py test/unit/models/   # Just models
        python3 scripts/analyze_test_quality.py test/unit/services/ # Just services
        python3 scripts/analyze_test_quality.py test/widget/       # Just widgets
"""

import os
import re
import sys
from pathlib import Path
from collections import defaultdict
from dataclasses import dataclass, field
from typing import List, Dict, Tuple
import json

@dataclass
class TestIssue:
    """Represents a test quality issue"""
    file_path: str
    line_number: int
    test_name: str
    issue_type: str
    severity: str  # 'high', 'medium', 'low'
    description: str
    suggestion: str

@dataclass
class FileAnalysis:
    """Analysis results for a single test file"""
    file_path: str
    total_tests: int
    issues: List[TestIssue] = field(default_factory=list)
    property_assignment_tests: int = 0
    trivial_checks: int = 0
    granular_edge_cases: int = 0
    json_field_tests: int = 0
    business_logic_tests: int = 0
    
    @property
    def total_issues(self) -> int:
        return len(self.issues)
    
    @property
    def low_value_percentage(self) -> float:
        if self.total_tests == 0:
            return 0.0
        low_value = (self.property_assignment_tests + 
                     self.trivial_checks + 
                     self.granular_edge_cases + 
                     self.json_field_tests)
        return (low_value / self.total_tests) * 100

class TestQualityAnalyzer:
    """Analyzes test files for quality issues"""
    
    def __init__(self):
        self.issues: List[TestIssue] = []
        self.file_analyses: Dict[str, FileAnalysis] = {}
        
    def analyze_file(self, file_path: Path) -> FileAnalysis:
        """Analyze a single test file"""
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()
            lines = content.split('\n')
        
        analysis = FileAnalysis(
            file_path=str(file_path),
            total_tests=0
        )
        
        # Find all test declarations
        test_pattern = re.compile(r'test\(|testWidgets\(')
        test_matches = list(test_pattern.finditer(content))
        analysis.total_tests = len(test_matches)
        
        # Analyze each test
        for i, match in enumerate(test_matches):
            start_line = content[:match.start()].count('\n') + 1
            test_end = self._find_test_end(content, match.start())
            test_content = content[match.start():test_end]
            test_lines = test_content.split('\n')
            
            # Extract test name
            test_name_match = re.search(r'test\([\'"]((?:[^\'"]|\\.)*)[\'"]', test_content)
            test_name = test_name_match.group(1) if test_name_match else f"test_{i+1}"
            
            # Analyze test content
            self._analyze_test(test_name, test_content, test_lines, start_line, file_path, analysis)
        
        self.file_analyses[str(file_path)] = analysis
        return analysis
    
    def _find_test_end(self, content: str, start_pos: int) -> int:
        """Find the end of a test function"""
        depth = 0
        in_string = False
        string_char = None
        i = start_pos
        
        while i < len(content):
            char = content[i]
            
            # Handle string literals
            if char in ('"', "'") and (i == 0 or content[i-1] != '\\'):
                if not in_string:
                    in_string = True
                    string_char = char
                elif char == string_char:
                    in_string = False
                    string_char = None
            
            if not in_string:
                if char == '{':
                    depth += 1
                elif char == '}':
                    depth -= 1
                    if depth == 0:
                        return i + 1
            
            i += 1
        
        return len(content)
    
    def _analyze_test(self, test_name: str, test_content: str, test_lines: List[str], 
                     line_number: int, file_path: Path, analysis: FileAnalysis):
        """Analyze a single test for quality issues"""
        
        # Pattern 1: Property assignment tests
        # Looks for: expect(spot.property, equals(value))
        property_pattern = re.compile(r'expect\([^,]+\.\w+,\s*(equals|isA|isNotNull|isNull)')
        property_matches = property_pattern.findall(test_content)
        
        if len(property_matches) >= 3:  # Multiple property checks
            # Check if it's just property assignment (no business logic)
            has_business_logic = any(keyword in test_content.lower() for keyword in [
                'calculate', 'validate', 'reject', 'throw', 'error', 'exception',
                'distance', 'contains', 'filter', 'sort', 'transform'
            ])
            
            if not has_business_logic:
                analysis.property_assignment_tests += 1
                analysis.issues.append(TestIssue(
                    file_path=str(file_path),
                    line_number=line_number,
                    test_name=test_name,
                    issue_type='property_assignment',
                    severity='high',
                    description=f'Test only checks property assignment ({len(property_matches)} checks)',
                    suggestion='Remove - tests Dart constructor, not business logic'
                ))
        
        # Pattern 2: Trivial null/empty checks
        trivial_patterns = [
            (r'should handle null \w+', 'null check'),
            (r'should handle empty \w+', 'empty check'),
            (r'should handle single \w+', 'single item check'),
        ]
        
        for pattern, check_type in trivial_patterns:
            if re.search(pattern, test_name, re.IGNORECASE):
                # Check if it's just a trivial check
                if re.search(r'expect\([^,]+,\s*(isNull|isEmpty|isNotNull)', test_content):
                    analysis.trivial_checks += 1
                    analysis.issues.append(TestIssue(
                        file_path=str(file_path),
                        line_number=line_number,
                        test_name=test_name,
                        issue_type='trivial_check',
                        severity='medium',
                        description=f'Trivial {check_type} - tests language feature',
                        suggestion='Consolidate with other edge cases into single test'
                    ))
                    break
        
        # Pattern 3: Over-granular edge cases
        # Multiple similar tests in same group
        if 'should handle' in test_name.lower():
            # This is a heuristic - would need context of other tests
            # For now, flag if there are many similar tests
            pass
        
        # Pattern 4: Field-by-field JSON tests
        json_field_pattern = re.compile(r'json\[[\'"]\w+[\'"]\]')
        json_matches = json_field_pattern.findall(test_content)
        
        if len(json_matches) >= 5:  # Testing many fields individually
            has_roundtrip = 'fromJson' in test_content and 'toJson' in test_content
            if not has_roundtrip:
                analysis.json_field_tests += 1
                analysis.issues.append(TestIssue(
                    file_path=str(file_path),
                    line_number=line_number,
                    test_name=test_name,
                    issue_type='json_field_test',
                    severity='medium',
                    description=f'Tests JSON fields individually ({len(json_matches)} fields)',
                    suggestion='Replace with round-trip test using TestHelpers.validateJsonRoundtrip'
                ))
        
        # Pattern 5: Business logic indicators (keep these)
        business_logic_keywords = [
            'calculate', 'validate', 'reject', 'throw', 'error', 'exception',
            'distance', 'contains', 'filter', 'sort', 'transform', 'compute',
            'permission', 'authorize', 'constraint', 'rule', 'policy'
        ]
        
        if any(keyword in test_name.lower() or keyword in test_content.lower() 
               for keyword in business_logic_keywords):
            analysis.business_logic_tests += 1
    
    def analyze_directory(self, directory: Path) -> Dict[str, FileAnalysis]:
        """Analyze all test files in a directory (recursively)"""
        # Find all test files recursively
        test_files = list(directory.rglob('*_test.dart'))
        
        # Also check for test files in integration_test/ directory (common Flutter pattern)
        if directory.name == 'test' or 'test' in str(directory):
            # Look for integration_test directory at project root
            project_root = directory if directory.name == 'test' else directory.parent
            integration_test_dir = project_root / 'integration_test'
            if integration_test_dir.exists():
                test_files.extend(integration_test_dir.rglob('*_test.dart'))
        
        # Remove duplicates and sort
        test_files = sorted(set(test_files))
        
        print(f"Analyzing {len(test_files)} test files in {directory}...")
        print(f"  Found test files in: {len(set(f.parent for f in test_files))} directories")
        
        for test_file in test_files:
            try:
                self.analyze_file(test_file)
            except Exception as e:
                print(f"Error analyzing {test_file}: {e}", file=sys.stderr)
        
        return self.file_analyses
    
    def generate_report(self, output_file: str = None) -> str:
        """Generate analysis report"""
        report_lines = []
        report_lines.append("=" * 80)
        report_lines.append("TEST QUALITY ANALYSIS REPORT")
        report_lines.append("=" * 80)
        report_lines.append("")
        
        # Summary statistics
        total_files = len(self.file_analyses)
        total_tests = sum(a.total_tests for a in self.file_analyses.values())
        total_issues = sum(a.total_issues for a in self.file_analyses.values())
        total_property_tests = sum(a.property_assignment_tests for a in self.file_analyses.values())
        total_trivial = sum(a.trivial_checks for a in self.file_analyses.values())
        total_json = sum(a.json_field_tests for a in self.file_analyses.values())
        
        report_lines.append("SUMMARY")
        report_lines.append("-" * 80)
        report_lines.append(f"Total Files Analyzed: {total_files}")
        report_lines.append(f"Total Tests: {total_tests}")
        report_lines.append(f"Total Issues Found: {total_issues}")
        report_lines.append("")
        report_lines.append("Issue Breakdown:")
        report_lines.append(f"  - Property Assignment Tests: {total_property_tests}")
        report_lines.append(f"  - Trivial Checks: {total_trivial}")
        report_lines.append(f"  - JSON Field Tests: {total_json}")
        report_lines.append("")
        
        # Group files by directory for better organization
        files_by_dir = defaultdict(list)
        for file_path, analysis in self.file_analyses.items():
            dir_path = str(Path(file_path).parent)
            files_by_dir[dir_path].append((file_path, analysis))
        
        # Files sorted by low-value percentage
        sorted_files = sorted(
            self.file_analyses.items(),
            key=lambda x: x[1].low_value_percentage,
            reverse=True
        )
        
        report_lines.append("FILES BY PRIORITY (Highest Low-Value Percentage First)")
        report_lines.append("-" * 80)
        report_lines.append("")
        report_lines.append(f"Showing top 30 files (out of {total_files} total files)")
        report_lines.append("")
        
        for file_path, analysis in sorted_files[:30]:  # Top 30
            report_lines.append("")
            report_lines.append(f"File: {file_path}")
            report_lines.append(f"  Total Tests: {analysis.total_tests}")
            report_lines.append(f"  Low-Value Percentage: {analysis.low_value_percentage:.1f}%")
            report_lines.append(f"  Issues: {analysis.total_issues}")
            report_lines.append(f"    - Property Assignment: {analysis.property_assignment_tests}")
            report_lines.append(f"    - Trivial Checks: {analysis.trivial_checks}")
            report_lines.append(f"    - JSON Field Tests: {analysis.json_field_tests}")
            report_lines.append(f"    - Granular Edge Cases: {analysis.granular_edge_cases}")
            report_lines.append(f"  Business Logic Tests: {analysis.business_logic_tests}")
            report_lines.append(f"  Estimated Refactoring Time: {self._estimate_time(analysis)} minutes")
        
        # Summary by directory
        report_lines.append("")
        report_lines.append("=" * 80)
        report_lines.append("SUMMARY BY DIRECTORY")
        report_lines.append("=" * 80)
        
        dir_summaries = []
        for dir_path, files in files_by_dir.items():
            dir_total_tests = sum(a.total_tests for _, a in files)
            dir_total_issues = sum(a.total_issues for _, a in files)
            dir_property = sum(a.property_assignment_tests for _, a in files)
            dir_trivial = sum(a.trivial_checks for _, a in files)
            dir_json = sum(a.json_field_tests for _, a in files)
            
            if dir_total_tests > 0:
                dir_summaries.append({
                    'path': dir_path,
                    'files': len(files),
                    'tests': dir_total_tests,
                    'issues': dir_total_issues,
                    'property': dir_property,
                    'trivial': dir_trivial,
                    'json': dir_json,
                    'percentage': (dir_total_issues / dir_total_tests * 100) if dir_total_tests > 0 else 0
                })
        
        dir_summaries.sort(key=lambda x: x['percentage'], reverse=True)
        
        for summary in dir_summaries:
            report_lines.append("")
            report_lines.append(f"Directory: {summary['path']}")
            report_lines.append(f"  Files: {summary['files']}")
            report_lines.append(f"  Total Tests: {summary['tests']}")
            report_lines.append(f"  Issues: {summary['issues']} ({summary['percentage']:.1f}%)")
            report_lines.append(f"    - Property Assignment: {summary['property']}")
            report_lines.append(f"    - Trivial Checks: {summary['trivial']}")
            report_lines.append(f"    - JSON Field Tests: {summary['json']}")
        
        # Detailed issues for top 10 files
        report_lines.append("")
        report_lines.append("=" * 80)
        report_lines.append("DETAILED ISSUES (Top 10 Files)")
        report_lines.append("=" * 80)
        
        for file_path, analysis in sorted_files[:10]:
            report_lines.append("")
            report_lines.append(f"File: {file_path}")
            report_lines.append("-" * 80)
            
            for issue in analysis.issues[:15]:  # Top 15 issues per file
                report_lines.append(f"  Line {issue.line_number}: {issue.test_name}")
                report_lines.append(f"    Type: {issue.issue_type} ({issue.severity})")
                report_lines.append(f"    Issue: {issue.description}")
                report_lines.append(f"    Suggestion: {issue.suggestion}")
                report_lines.append("")
        
        report = "\n".join(report_lines)
        
        if output_file:
            with open(output_file, 'w') as f:
                f.write(report)
            print(f"\nReport saved to: {output_file}")
        
        return report
    
    def _estimate_time(self, analysis: FileAnalysis) -> int:
        """Estimate refactoring time in minutes"""
        # Rough estimate: 2-3 minutes per issue
        base_time = 5  # File setup/verification
        issue_time = analysis.total_issues * 2
        return base_time + issue_time
    
    def export_json(self, output_file: str):
        """Export analysis results as JSON"""
        results = {
            'summary': {
                'total_files': len(self.file_analyses),
                'total_tests': sum(a.total_tests for a in self.file_analyses.values()),
                'total_issues': sum(a.total_issues for a in self.file_analyses.values()),
            },
            'files': {}
        }
        
        for file_path, analysis in self.file_analyses.items():
            results['files'][file_path] = {
                'total_tests': analysis.total_tests,
                'low_value_percentage': analysis.low_value_percentage,
                'property_assignment_tests': analysis.property_assignment_tests,
                'trivial_checks': analysis.trivial_checks,
                'json_field_tests': analysis.json_field_tests,
                'business_logic_tests': analysis.business_logic_tests,
                'issues': [
                    {
                        'line_number': issue.line_number,
                        'test_name': issue.test_name,
                        'issue_type': issue.issue_type,
                        'severity': issue.severity,
                        'description': issue.description,
                        'suggestion': issue.suggestion,
                    }
                    for issue in analysis.issues
                ]
            }
        
        with open(output_file, 'w') as f:
            json.dump(results, f, indent=2)
        
        print(f"JSON export saved to: {output_file}")


def main():
    """Main entry point"""
    # Default to entire test/ directory if no argument provided
    if len(sys.argv) > 1:
        test_dir = Path(sys.argv[1])
    else:
        # Get project root (assuming script is in scripts/)
        script_dir = Path(__file__).parent
        project_root = script_dir.parent
        test_dir = project_root / 'test'
    
    if not test_dir.exists():
        print(f"Error: Directory not found: {test_dir}", file=sys.stderr)
        sys.exit(1)
    
    analyzer = TestQualityAnalyzer()
    analyzer.analyze_directory(test_dir)
    
    # Generate report
    script_dir = Path(__file__).parent
    report_file = script_dir.parent / 'docs' / 'plans' / 'test_refactoring' / 'test_quality_analysis_report.txt'
    report_file.parent.mkdir(parents=True, exist_ok=True)
    
    report = analyzer.generate_report(str(report_file))
    print(report)
    
    # Export JSON
    json_file = script_dir.parent / 'docs' / 'plans' / 'test_refactoring' / 'test_quality_analysis.json'
    analyzer.export_json(str(json_file))
    
    print("\n" + "=" * 80)
    print("Analysis complete!")
    print(f"Report: {report_file}")
    print(f"JSON: {json_file}")
    print("=" * 80)


if __name__ == '__main__':
    main()

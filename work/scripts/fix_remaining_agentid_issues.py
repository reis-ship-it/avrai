#!/usr/bin/env python3
"""
Fix Remaining agentId Issues in SPOTS Codebase

This script finds and fixes remaining PersonalityProfile instances that haven't been
updated to use agentId as the primary key (Phase 8.3 migration).

Patterns it fixes:
1. PersonalityProfile.initial(userId) -> PersonalityProfile.initial('agent_$userId', userId: userId)
2. PersonalityProfile(userId: '...') -> PersonalityProfile(agentId: 'agent_...', userId: '...')
3. PersonalityProfile(userId: variable) -> PersonalityProfile(agentId: 'agent_$variable', userId: variable)

Usage:
    python3 scripts/fix_remaining_agentid_issues.py [--dry-run] [--file <path>]
"""

import re
import sys
import os
from pathlib import Path
from typing import List, Tuple, Optional
import argparse


def find_dart_files(root_dir: str = '.') -> List[Path]:
    """Find all Dart files in the codebase."""
    dart_files = []
    for path in Path(root_dir).rglob('*.dart'):
        # Skip test files (they should already be fixed)
        if 'test' not in str(path):
            dart_files.append(path)
    return dart_files


def extract_variable_name(expression: str) -> Optional[str]:
    """Extract variable name from an expression like 'userId', 'test_user', etc."""
    # Remove quotes
    expression = expression.strip().strip("'").strip('"').strip('`')
    # If it's a variable (no quotes), return it
    if not (expression.startswith("'") or expression.startswith('"')):
        return expression
    return None


def fix_personality_profile_initial(match: re.Match, file_content: str, line_num: int) -> Tuple[str, int]:
    """
    Fix PersonalityProfile.initial(userId) pattern.
    
    Returns: (replacement_string, number_of_changes)
    """
    full_match = match.group(0)
    arg = match.group(1) if match.group(1) else match.group(2)
    
    # Skip if already has agentId parameter
    if 'agentId:' in full_match or 'agent_' in arg:
        return full_match, 0
    
    # Extract the userId argument
    arg = arg.strip()
    
    # Determine if it's a string literal or variable
    is_string_literal = arg.startswith("'") or arg.startswith('"') or arg.startswith('`')
    
    if is_string_literal:
        # String literal: 'test_user' -> 'agent_test_user'
        user_id_value = arg.strip("'\"`")
        agent_id_value = f"'agent_{user_id_value}'"
        replacement = f"PersonalityProfile.initial({agent_id_value}, userId: {arg})"
    else:
        # Variable: userId -> 'agent_$userId'
        agent_id_value = f"'agent_\${arg}'"
        replacement = f"PersonalityProfile.initial({agent_id_value}, userId: {arg})"
    
    # Add comment
    replacement = f"// Phase 8.3: Use agentId for privacy protection\n        {replacement}"
    
    return replacement, 1


def fix_personality_profile_constructor(match: re.Match, file_content: str, line_num: int) -> Tuple[str, int]:
    """
    Fix PersonalityProfile(userId: ...) constructor pattern.
    
    Returns: (replacement_string, number_of_changes)
    """
    full_match = match.group(0)
    
    # Skip if already has agentId
    if 'agentId:' in full_match:
        return full_match, 0
    
    # Extract userId value
    userId_match = re.search(r'userId:\s*([^,}\n]+)', full_match)
    if not userId_match:
        return full_match, 0
    
    userId_value = userId_match.group(1).strip()
    
    # Determine if it's a string literal or variable
    is_string_literal = userId_value.startswith("'") or userId_value.startswith('"') or userId_value.startswith('`')
    
    # Find the position to insert agentId (right after opening brace or after PersonalityProfile)
    # Insert agentId before userId
    if is_string_literal:
        user_id_clean = userId_value.strip("'\"`")
        agent_id_value = f"'agent_{user_id_clean}'"
    else:
        agent_id_value = f"'agent_\${userId_value}'"
    
    # Insert agentId parameter before userId
    replacement = full_match.replace(
        f'userId: {userId_value}',
        f'agentId: {agent_id_value},\n        userId: {userId_value}'
    )
    
    # Add comment if not already present
    if 'Phase 8.3' not in replacement:
        # Find the line before this match
        lines = file_content[:match.start()].split('\n')
        prev_line = lines[-1] if lines else ''
        if 'Phase 8.3' not in prev_line:
            replacement = f"        // Phase 8.3: Use agentId for privacy protection\n{replacement}"
    
    return replacement, 1


def fix_file(file_path: Path, dry_run: bool = False) -> Tuple[int, List[str]]:
    """
    Fix agentId issues in a single file.
    
    Returns: (number_of_fixes, list_of_changes)
    """
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()
    except Exception as e:
        print(f"Error reading {file_path}: {e}", file=sys.stderr)
        return 0, []
    
    original_content = content
    changes = []
    total_fixes = 0
    
    # Pattern 1: PersonalityProfile.initial(userId)
    # Matches: PersonalityProfile.initial('test') or PersonalityProfile.initial(userId)
    pattern1 = re.compile(
        r'PersonalityProfile\.initial\s*\(\s*([\'"]?[^\'",)]+[\'"]?|[^,)]+)\s*\)',
        re.MULTILINE
    )
    
    def replace_initial(match):
        nonlocal total_fixes
        replacement, num_changes = fix_personality_profile_initial(match, content, 0)
        total_fixes += num_changes
        if num_changes > 0:
            changes.append(f"Line ~{content[:match.start()].count(chr(10)) + 1}: Fixed PersonalityProfile.initial()")
        return replacement
    
    content = pattern1.sub(replace_initial, content)
    
    # Pattern 2: PersonalityProfile(userId: ...)
    # This is more complex - we need to match the full constructor call
    # We'll look for PersonalityProfile( followed by userId: and capture until closing paren
    pattern2 = re.compile(
        r'PersonalityProfile\s*\(\s*userId:\s*([^,}\n]+)',
        re.MULTILINE
    )
    
    def replace_constructor(match):
        nonlocal total_fixes
        # Find the full constructor call (from opening to closing paren/brace)
        start_pos = match.start()
        paren_count = 0
        brace_count = 0
        in_string = False
        string_char = None
        pos = start_pos
        
        # Find the matching closing
        while pos < len(content):
            char = content[pos]
            
            if char in ['"', "'", '`'] and (pos == 0 or content[pos-1] != '\\'):
                if not in_string:
                    in_string = True
                    string_char = char
                elif char == string_char:
                    in_string = False
                    string_char = None
            elif not in_string:
                if char == '(':
                    paren_count += 1
                elif char == ')':
                    paren_count -= 1
                    if paren_count == 0:
                        end_pos = pos + 1
                        break
                elif char == '{':
                    brace_count += 1
                elif char == '}':
                    brace_count -= 1
            
            pos += 1
        else:
            # Didn't find closing, skip this match
            return match.group(0)
        
        # Extract the full match
        full_match = content[start_pos:end_pos]
        
        replacement, num_changes = fix_personality_profile_constructor(
            type('Match', (), {'group': lambda self, n=0: full_match, 'start': lambda: start_pos})(),
            content,
            0
        )
        
        if num_changes > 0:
            total_fixes += num_changes
            changes.append(f"Line ~{content[:start_pos].count(chr(10)) + 1}: Fixed PersonalityProfile() constructor")
            return replacement
        
        return full_match
    
    # For constructor, we need a more careful approach
    # Let's find all matches and replace them one by one
    matches = list(pattern2.finditer(content))
    for match in reversed(matches):  # Process from end to start to preserve positions
        replacement, num_changes = fix_personality_profile_constructor(match, content, 0)
        if num_changes > 0:
            total_fixes += num_changes
            changes.append(f"Line ~{content[:match.start()].count(chr(10)) + 1}: Fixed PersonalityProfile() constructor")
            # For now, we'll do a simpler replacement
            # Find the userId: part and insert agentId before it
            start = match.start()
            # Find the start of PersonalityProfile(
            profile_start = content.rfind('PersonalityProfile(', 0, start)
            if profile_start == -1:
                continue
            
            # Find where userId: starts
            userId_start = match.start() + match.group(0).find('userId:')
            userId_value = match.group(1).strip()
            
            # Determine agentId value
            is_string_literal = userId_value.startswith("'") or userId_value.startswith('"') or userId_value.startswith('`')
            if is_string_literal:
                user_id_clean = userId_value.strip("'\"`")
                agent_id_value = f"'agent_{user_id_clean}'"
            else:
                agent_id_value = f"'agent_\${userId_value}'"
            
            # Insert agentId before userId
            before_userid = content[:userId_start]
            after_userid = content[userId_start:]
            
            # Check if there's already a comment
            needs_comment = 'Phase 8.3' not in before_userid[max(0, before_userid.rfind('\n', max(0, profile_start-100), userId_start)):userId_start]
            
            if needs_comment:
                # Find the indentation
                indent_start = before_userid.rfind('\n', profile_start, userId_start) + 1
                indent = before_userid[indent_start:userId_start]
                agent_id_line = f"{indent}agentId: {agent_id_value},\n"
            else:
                # Use same indentation as userId
                indent_start = before_userid.rfind('\n', max(0, profile_start-50), userId_start) + 1
                indent = before_userid[indent_start:userId_start]
                agent_id_line = f"{indent}agentId: {agent_id_value},\n"
            
            content = before_userid + agent_id_line + after_userid
    
    if total_fixes > 0 and not dry_run:
        try:
            with open(file_path, 'w', encoding='utf-8') as f:
                f.write(content)
        except Exception as e:
            print(f"Error writing {file_path}: {e}", file=sys.stderr)
            return 0, []
    
    return total_fixes, changes


def main():
    parser = argparse.ArgumentParser(description='Fix remaining agentId issues in SPOTS codebase')
    parser.add_argument('--dry-run', action='store_true', help='Show what would be changed without making changes')
    parser.add_argument('--file', type=str, help='Fix a specific file instead of scanning all files')
    args = parser.parse_args()
    
    if args.file:
        files = [Path(args.file)]
    else:
        files = find_dart_files()
    
    total_fixes = 0
    files_changed = 0
    
    print(f"Scanning {len(files)} Dart files...")
    print("=" * 60)
    
    for file_path in files:
        fixes, changes = fix_file(file_path, dry_run=args.dry_run)
        if fixes > 0:
            files_changed += 1
            total_fixes += fixes
            print(f"\n{file_path}:")
            for change in changes:
                print(f"  - {change}")
    
    print("\n" + "=" * 60)
    print(f"Summary:")
    print(f"  Files scanned: {len(files)}")
    print(f"  Files with fixes: {files_changed}")
    print(f"  Total fixes: {total_fixes}")
    if args.dry_run:
        print(f"  Mode: DRY RUN (no files were modified)")
    else:
        print(f"  Mode: LIVE (files were modified)")
    
    return 0 if total_fixes == 0 else 1


if __name__ == '__main__':
    sys.exit(main())


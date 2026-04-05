#!/bin/bash
# Debug script to test git commands that Agent Review might use

echo "=== Testing Git Commands for Agent Review ==="
echo ""

cd "$(dirname "$0")"

echo "1. Current branch:"
git rev-parse --abbrev-ref HEAD
echo ""

echo "2. Current commit:"
git rev-parse HEAD
echo ""

echo "3. Remote tracking:"
git rev-parse --abbrev-ref --symbolic-full-name @{u} 2>&1
echo ""

echo "4. Recent commits:"
git log --oneline -5
echo ""

echo "5. Diff stats:"
git diff --stat HEAD~1 HEAD 2>&1 | head -10
echo ""

echo "6. Remote branch exists:"
git ls-remote --heads origin last-updates 2>&1
echo ""

echo "7. Git LFS status:"
command -v git-lfs >/dev/null 2>&1 && echo "Git LFS installed" || echo "Git LFS not found"
echo ""

echo "8. Testing git log with format:"
git log -1 --format="%H|%an|%ae|%s" 2>&1
echo ""

echo "9. Testing git show:"
git show --stat --oneline HEAD 2>&1 | head -5
echo ""

echo "=== All tests complete ==="


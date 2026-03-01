# SPOTS Bug & Issue Tracker

| ID  | Date       | Area         | Description                                 | Severity | Status   | Notes |
|-----|------------|--------------|---------------------------------------------|----------|----------|-------|
| 1   | 2025-07-19 | Onboarding   | Duplicate starter lists created after onboarding | Major    | Fixed    | Fixed - Remote data source was generating new IDs instead of preserving original IDs, causing repository to create duplicates |
| 2   | 2025-07-19 | UI/Onboarding| UI overflow on Friends Respect page         | Minor    | Fixed    | Fixed RenderFlex overflow by using Wrap widget |
| 3   | 2025-07-21 | Connect & Discover | Respect counts not updating | Minor | Fixed | Fixed - counts now increment/decrement when respecting/unrespecting lists |
| 4   | 2025-07-21 | Onboarding   | Suggested cities/neighborhoods popup stays on screen after navigation | Minor | Fixed | Fixed - Added ScaffoldMessenger.of(context).clearSnackBars() in Next button when on favorite places page |
| 5   | 2025-07-21 | Onboarding   | Search should auto-expand matching vibe categories | Enhancement | Open | Added auto-expansion logic but needs testing - search should auto-expand categories containing matches |
| 6   | 2025-07-29 | Respected Lists | Respected lists not showing up after onboarding | Major | Fixed | Fixed - Updated SpotsSembastDataSource to use actual user ID instead of hardcoded demo user ID |

*Add new issues as you find them. Update status and notes as you work through bugs.*

**⚠️ IMPORTANT: Do not mark any bugs as "Fixed" unless manual testing has already proved it to be true.**

## Testing Rules
- **NEVER mark a bug as "Fixed" until it has been tested and confirmed working**
- **DO NOT mark any bugs as fixed unless manual testing has already proved it to be true**
- Always test with a clean database when investigating data-related bugs
- Document the exact steps to reproduce and verify fixes
- Manual testing must include the exact steps that originally reproduced the bug
- For UI bugs: Test on multiple screen sizes and orientations
- For data bugs: Test with fresh data and verify persistence
- For navigation bugs: Test all entry/exit points and edge cases 
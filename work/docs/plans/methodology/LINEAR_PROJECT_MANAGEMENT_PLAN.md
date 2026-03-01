# Linear Project Management Integration Plan

**Created:** December 23, 2025  
**Status:** 📋 Planning Phase  
**Purpose:** Complete plan for integrating Linear for SPOTS project management and progress tracking  
**Master Plan Status:** Not ready yet (will sync when ready)

---

## 🎯 **Overview**

This plan outlines how to use Linear as the project management and progress tracking system for SPOTS development. Linear will serve as:

1. **Progress Tracking Dashboard** - Visual representation of Master Plan progress
2. **Task Organization** - Organize work by Phase.Section.Subsection structure
3. **Timeline Visualization** - Roadmap view of all phases
4. **Analytics** - Progress metrics and completion tracking
5. **Future Integration** - Foundation for agent automation (when ready)

---

## 📋 **Phase 1: Initial Setup (Day 1)**

### **1.1 Linear Workspace Setup**

**Tasks:**
- [ ] Create Linear workspace: "SPOTS"
- [ ] Set timezone to local timezone
- [ ] Configure workspace settings
- [ ] Add yourself as team member

**Time:** 10 minutes

---

### **1.2 Team Structure**

**Decision:** Single team approach (recommended)

**Setup:**
- [ ] Create team: "SPOTS Development"
- [ ] Add yourself to team
- [ ] Configure team settings

**Why Single Team:**
- You're working solo (or small team)
- "Agents" are work categories, not separate people
- Use labels for categorization instead

**Time:** 5 minutes

---

### **1.3 API Setup**

**Tasks:**
- [ ] Generate Linear API key
  - Settings → API → Personal API Keys
  - Create key: "SPOTS Sync"
  - Copy and store securely
- [ ] Test API connection
  - Run test script to verify access
  - Confirm team ID retrieval

**Time:** 10 minutes

**API Key Storage:**
- Store in environment variable: `LINEAR_API_KEY`
- Add to `.env` file (gitignored)
- Or use secrets manager

---

## 📋 **Phase 2: Structure Setup (Day 1-2)**

### **2.1 Custom Fields**

Create custom fields to match Master Plan structure:

**Fields to Create:**
1. **Phase Number** (Number)
   - Type: Number
   - Required: Yes
   - Example: `7`

2. **Section Number** (Text)
   - Type: Text
   - Required: Yes
   - Example: `51-52` or `7.6.1-2`

3. **Subsection Number** (Text)
   - Type: Text
   - Required: No
   - Example: `1` or `7.6.1.1`

4. **Master Plan Status** (Select)
   - Type: Select
   - Options: Unassigned, In Progress, Complete
   - Required: Yes

5. **Priority** (Select)
   - Type: Select
   - Options: P0, P1, P2, P3
   - Required: Yes

6. **Progress %** (Number)
   - Type: Number (0-100)
   - Required: No
   - For tracking completion percentage

**Time:** 15 minutes

---

### **2.2 Labels Setup**

Create labels for categorization:

**Work Type Labels:**
- `backend` - Backend/Service work
- `frontend` - Frontend/UI work
- `testing` - Testing/QA work
- `integration` - Integration work
- `documentation` - Documentation work

**Priority Labels:**
- `p0-critical` - Critical blockers
- `p1-high` - High priority
- `p2-medium` - Medium priority
- `p3-low` - Low priority

**Status Labels:**
- `blocked` - Blocked on dependency
- `in-review` - Code review
- `doors-compliant` - Philosophy verified

**Time:** 10 minutes

---

### **2.3 Workflow States**

Configure workflow states to match Master Plan:

**States:**
1. **Unassigned** (Backlog) - Default for new issues
2. **In Progress** - Work actively being done
3. **Review** - Code review/testing
4. **Blocked** - Waiting on dependency
5. **Complete** - Finished and verified

**State Colors:**
- Unassigned: Gray
- In Progress: Blue
- Review: Yellow
- Blocked: Red
- Complete: Green

**Time:** 10 minutes

---

## 📋 **Phase 3: Master Plan Sync (When Ready)**

### **3.1 Sync Script Development**

**Create sync script structure:**

```
scripts/
  linear_sync/
    sync_master_plan.py      # Main sync script
    linear_client.py          # Linear API client wrapper
    master_plan_parser.py     # Parse Master Plan markdown
    config.py                 # Configuration (API keys, team IDs)
    requirements.txt          # Python dependencies
```

**Script Features:**
1. Parse `docs/MASTER_PLAN.md`
2. Extract Phase.Section.Subsection structure
3. Create/update Linear Projects (Phases)
4. Create/update Linear Issues (Sections)
5. Update status from Master Plan
6. Handle existing issues (update vs create)

**Time:** 2-3 hours

---

### **3.2 Mapping Structure**

**Master Plan → Linear Mapping:**

```
Master Plan Structure          →  Linear Structure
─────────────────────────────────────────────────────
Phase X                        →  Project (e.g., "Phase 7: Feature Matrix")
Section Y                      →  Issue (e.g., "Section 51-52: Comprehensive Testing")
Subsection Z                   →  Issue Description/Checklist (or sub-issue if needed)
```

**Issue Title Format:**
```
[Phase.Section] - [Section Name]
Example: [7.6.1-2] - Comprehensive Testing & Production Readiness
```

**Issue Description Template:**
```markdown
## Phase.Section: [7.6.1-2]

### Section Details
- **Phase:** 7
- **Section:** 51-52
- **Subsection:** 7.6.1-2
- **Status:** In Progress
- **Priority:** P1

### Description
[Section description from Master Plan]

### Master Plan Reference
- File: `docs/MASTER_PLAN.md`
- Location: Phase 7, Section 51-52

### Acceptance Criteria
- [ ] All work completed
- [ ] Tests passing
- [ ] Zero linter errors
- [ ] Documentation complete
```

---

### **3.3 Initial Sync Process**

**When Master Plan is ready:**

1. **Run initial sync:**
   ```bash
   python scripts/linear_sync/sync_master_plan.py
   ```

2. **Verify sync:**
   - Check all phases created as Projects
   - Check all sections created as Issues
   - Verify custom fields populated
   - Verify labels applied

3. **Review in Linear:**
   - Check Projects view
   - Check Roadmap view
   - Verify structure matches Master Plan

**Time:** 30 minutes (after script ready)

---

## 📋 **Phase 4: Progress Tracking Setup (Day 2-3)**

### **4.1 Dashboard Creation**

**Create Linear Dashboard:**

1. Go to Insights → Create Dashboard
2. Add widgets:
   - **Progress by Phase** - Completion percentage per phase
   - **Issues by Status** - Count of issues in each state
   - **Completion Timeline** - Timeline of completed work
   - **Blocker Count** - Number of blocked issues
   - **Velocity** - Issues completed per week

**Time:** 20 minutes

---

### **4.2 Roadmap Setup**

**Create Roadmap View:**

1. Go to Roadmaps → Create Roadmap
2. Add all Phase projects
3. Set dates based on Master Plan estimates
4. Add milestones for major completions
5. Configure dependencies between phases

**Time:** 30 minutes

---

### **4.3 Saved Filters**

**Create useful filters:**

1. **Active Work**
   - Status: In Progress
   - Not Blocked

2. **Blocked Issues**
   - Status: Blocked
   - Or Label: blocked

3. **Phase 7** (Current Phase)
   - Project: Phase 7
   - Any status

4. **This Week**
   - Due date: This week
   - Or created: This week

5. **High Priority**
   - Priority: P0 or P1
   - Or Label: p0-critical, p1-high

**Time:** 15 minutes

---

## 📋 **Phase 5: Workflow Integration (Day 3-4)**

### **5.1 Daily Workflow**

**Morning Routine:**
1. Check Linear dashboard
2. Review blocked issues
3. Update status from overnight work
4. Assign new work

**During Work:**
1. Update issue status as you work
2. Add comments with progress
3. Link PRs to issues (via GitHub integration)
4. Mark dependencies complete

**End of Day:**
1. Update issue status
2. Mark completed work
3. Update blockers
4. Sync to Master Plan (optional)

---

### **5.2 GitHub Integration**

**Setup GitHub Integration:**

1. Linear Settings → Integrations → GitHub
2. Connect SPOTS repository
3. Enable:
   - Auto-link PRs to issues
   - Update Linear from commits
   - Create issues from PRs (optional)

**Benefits:**
- PRs automatically link to Linear issues
- Commit messages can update Linear status
- Better traceability

**Time:** 10 minutes

---

### **5.3 Status Update Automation**

**Option 1: Manual Updates**
- Update Linear manually as you complete work
- Simple, direct control

**Option 2: Git-Based Updates**
- Parse commit messages for status updates
- Auto-update Linear from git
- Example: `[7.6.1-2] Complete` → Mark issue complete

**Option 3: Hybrid**
- Manual for major milestones
- Auto-update for routine status changes

**Recommendation:** Start with manual, add automation later

---

## 📋 **Phase 6: Master Plan Sync (When Master Plan Ready)**

### **6.1 Sync Script Requirements**

**Script must:**
1. Parse Master Plan markdown format
2. Extract Phase.Section.Subsection notation
3. Handle status indicators (✅, 🟡, ⏳)
4. Create/update Projects (Phases)
5. Create/update Issues (Sections)
6. Preserve existing Linear data
7. Handle conflicts gracefully

**Script Structure:**
```python
# sync_master_plan.py
def main():
    # 1. Parse Master Plan
    master_plan = parse_master_plan("docs/MASTER_PLAN.md")
    
    # 2. Get existing Linear data
    linear_projects = get_linear_projects()
    linear_issues = get_linear_issues()
    
    # 3. Sync Projects (Phases)
    sync_projects(master_plan.phases, linear_projects)
    
    # 4. Sync Issues (Sections)
    sync_issues(master_plan.sections, linear_issues)
    
    # 5. Update status
    update_statuses(master_plan, linear_issues)
    
    # 6. Report
    print_sync_report()
```

---

### **6.2 Sync Frequency**

**Options:**
1. **One-time sync** - When Master Plan is ready
2. **Daily sync** - Automated daily sync
3. **On-demand** - Manual sync when needed
4. **Bidirectional** - Sync Linear → Master Plan (advanced)

**Recommendation:** Start with one-time sync, add daily sync later

---

### **6.3 Conflict Resolution**

**When Linear and Master Plan differ:**

1. **Linear has updates Master Plan doesn't:**
   - Keep Linear updates
   - Optionally sync back to Master Plan

2. **Master Plan has updates Linear doesn't:**
   - Update Linear from Master Plan
   - Preserve Linear-specific data (comments, etc.)

3. **Both have conflicting updates:**
   - Prefer Master Plan (source of truth)
   - Log conflicts for review

---

## 📋 **Phase 7: Advanced Features (Future)**

### **7.1 Agent Integration (When Ready)**

**Future Setup:**
- Create Linear agent application
- Set up agent sessions
- Enable agent delegation
- Connect to Cursor AI

**Not needed for progress tracking only**

---

### **7.2 Slack Integration (When Ready)**

**Future Setup:**
- Install Linear Slack app
- Enable slash commands
- Set up notifications
- Enable delegation from Slack

**Not needed for progress tracking only**

---

### **7.3 Automated Reporting**

**Future Features:**
- Weekly progress reports
- Phase completion summaries
- Blocker analysis
- Velocity tracking

---

## 📊 **Success Metrics**

### **Phase 1-2 (Setup):**
- ✅ Linear workspace created
- ✅ Team and custom fields configured
- ✅ API connection working
- ✅ Structure matches Master Plan format

### **Phase 3-4 (Tracking):**
- ✅ Master Plan synced to Linear
- ✅ Dashboard showing progress
- ✅ Roadmap visualizing timeline
- ✅ Filters working correctly

### **Phase 5-6 (Integration):**
- ✅ Daily workflow established
- ✅ GitHub integration working
- ✅ Status updates flowing
- ✅ Progress accurately tracked

---

## 🚀 **Quick Start Checklist**

### **Immediate (Today):**
- [ ] Create Linear workspace
- [ ] Create team "SPOTS Development"
- [ ] Generate API key
- [ ] Create custom fields
- [ ] Create labels
- [ ] Configure workflow states

### **This Week:**
- [ ] Create dashboard
- [ ] Set up roadmap
- [ ] Create saved filters
- [ ] Test API connection
- [ ] Create sync script structure

### **When Master Plan Ready:**
- [ ] Complete sync script
- [ ] Run initial sync
- [ ] Verify all data imported
- [ ] Set up daily sync (optional)
- [ ] Configure GitHub integration

---

## 📝 **Next Steps**

1. **Complete Phase 1-2** (Setup) - Do this today
2. **Wait for Master Plan** - Don't sync until ready
3. **Complete Phase 3** (Sync Script) - When Master Plan ready
4. **Complete Phase 4** (Tracking) - After sync
5. **Complete Phase 5** (Integration) - Ongoing

---

## 🔗 **Resources**

- **Linear API Docs:** https://linear.app/docs/api-and-webhooks
- **Linear GraphQL Schema:** https://linear.app/docs/api-and-webhooks/graphql-schema
- **Linear TypeScript SDK:** https://linear.app/developers/sdk
- **Master Plan Format:** `docs/plans/methodology/PHASE_SECTION_SUBSECTION_FORMAT.md`

---

**Last Updated:** December 23, 2025  
**Status:** 📋 Ready for Implementation


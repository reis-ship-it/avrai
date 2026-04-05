# SPOTS Development Guide

## 🚨 For AI Assistants: MANDATORY Protocol 🚨

### Starting a New Task

**When you receive ANY of these trigger phrases:**

### Implementation Triggers:
- "implement [feature]"
- "create [component]"
- "build [feature]"
- "add [functionality]"
- "start working on [task]"
- "proceed with [phase]"
- "continue with [feature]"
- "let's do [task]"

### Status/Progress Triggers (READ ALL DOCS):
- "where are we with [topic]"
- "what's the status of [topic]"
- "how far along is [topic]"
- "what's complete in [topic]"
- "show me progress on [topic]"
- "update me on [topic]"

⚠️ **For status queries: Find and read ALL related documents (plan + complete + progress + status), not just one!**

**YOU MUST:**

1. **FIRST** → Read `docs/START_HERE_NEW_TASK.md`
2. **THEN** → Follow the 40-minute context protocol
3. **THEN** → Communicate your plan
4. **THEN** → Get user approval
5. **FINALLY** → Begin implementation

**DO NOT skip to implementation. Context gathering is mandatory.**

---

## 📋 The Protocol (Summary)

### Implementation Task Protocol:
```
New Task Received
    ↓
🔴 STOP - Read START_HERE_NEW_TASK.md
    ↓
📚 Discover ALL plans (5 min)
    ↓
🔍 Filter by recency + relevance (5 min)
    ↓
📖 Read high-priority plans (10 min)
    ↓
🔎 Search existing implementations (5 min)
    ↓
📝 Create implementation plan (8 min)
    ↓
💬 Communicate to user (2 min)
    ↓
✅ Get approval
    ↓
⚙️ Begin implementation
```

### Status/Progress Query Protocol:
```
Status Query Received
    ↓
🔴 STOP - Read START_HERE_NEW_TASK.md
    ↓
🔍 Find ALL documents about topic
    ├─ Plan documents
    ├─ Completion documents  
    ├─ Progress documents
    ├─ Status documents
    └─ Summary documents
    ↓
📖 Read ALL found documents (not just one!)
    ↓
📊 Synthesize complete picture
    ├─ What was planned?
    ├─ What's complete?
    ├─ What's in progress?
    ├─ What's remaining?
    ├─ Timeline status?
    └─ Next steps?
    ↓
💬 Present comprehensive answer
```

**Total context time: 40 minutes**  
**Time saved: 50-90% of implementation**

---

## 🎯 Success Rate

**Following this protocol:**
- Phase 1 Integration: 40 min context → Saved 5 days (99%)
- Optional Enhancements: 30 min context → Saved 3 days (85%)
- Phase 2.1: 20 min context → Saved 11 days (99.5%)

**Not following this protocol:**
- Risk of duplicating existing work
- Risk of wrong architecture
- Risk of missing conflicts
- Risk of incomplete integration
- 2-10x longer implementation time

---

## 📚 Documentation Structure

```
docs/
├── START_HERE_NEW_TASK.md ← 🚨 START HERE for every task
├── SESSION_START_CHECKLIST.md ← Quick reference
├── DEVELOPMENT_METHODOLOGY.md ← Full methodology
├── FEATURE_MATRIX_COMPLETION_PLAN.md ← Master plan
└── [other plans and completion docs]
```

---

## 🔑 Key Files

| File | Purpose | When to Use |
|------|---------|-------------|
| `START_HERE_NEW_TASK.md` | Entry point | **Every new task** |
| `SESSION_START_CHECKLIST.md` | Quick reference | During context gathering |
| `DEVELOPMENT_METHODOLOGY.md` | Complete guide | Reference as needed |
| `FEATURE_MATRIX_COMPLETION_PLAN.md` | Master plan | Always check |

---

## ⚠️ What NOT to Do

**❌ DON'T:**
- Start coding immediately
- Skip context gathering to "save time"
- Ignore existing plans
- Miss existing implementations
- Assume you know the architecture
- Skip the protocol "just this once"

**✅ DO:**
- Always read START_HERE_NEW_TASK.md first
- Complete the 40-minute protocol
- Discover ALL plans
- Search for existing work
- Communicate before coding
- Follow the methodology

---

## 🎓 For Developers

If you're onboarding an AI assistant for SPOTS development:

1. **Add to system instructions:**
   ```
   At the start of EVERY new task:
   1. Read docs/START_HERE_NEW_TASK.md
   2. Follow the 40-minute context protocol
   3. Complete all 7 steps before coding
   4. Get approval before proceeding
   
   Trigger phrases: "implement", "build", "create", "add", 
   "start", "proceed with", "continue with"
   ```

2. **Include in project README**
3. **Reference in first message** of new conversations
4. **Remind if protocol is skipped**

---

## 📊 Quality Standards

**Code is not "done" until:**
- ✅ Zero linter errors
- ✅ Zero compilation errors
- ✅ Fully integrated (users can access it)
- ✅ Tests written
- ✅ Documentation complete
- ✅ No known blockers

---

## 🚀 Quick Commands

```bash
# Start new task (AI assistant)
read_file('docs/START_HERE_NEW_TASK.md')

# Discover all plans
glob_file_search('**/*plan*.md')

# Check recency
run_terminal_cmd('ls -lht docs/*plan*.md | head -20')

# Search existing work
glob_file_search('**/*[feature]*.dart')

# Read master plan
read_file('docs/FEATURE_MATRIX_COMPLETION_PLAN.md')
```

---

## ✅ Confirmation Checklist

**Before implementing any task, confirm:**

- [ ] I have read START_HERE_NEW_TASK.md
- [ ] I have discovered ALL relevant plans
- [ ] I have filtered plans intelligently
- [ ] I have searched for existing work
- [ ] I understand the architecture
- [ ] I have created a TODO list
- [ ] I have communicated my plan
- [ ] User has approved

**All boxes must be checked before proceeding.**

---

## 📞 Questions?

- **Full methodology:** `docs/DEVELOPMENT_METHODOLOGY.md`
- **Quick reference:** `docs/SESSION_START_CHECKLIST.md`
- **Start protocol:** `docs/START_HERE_NEW_TASK.md`

---

**Last Updated:** November 21, 2025  
**Status:** Active - Mandatory for all development work


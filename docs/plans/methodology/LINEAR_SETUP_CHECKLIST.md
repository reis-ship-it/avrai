# Linear Setup Checklist - Quick Reference

**Created:** December 23, 2025  
**Purpose:** Quick checklist for setting up Linear for SPOTS project management  
**Full Plan:** See `LINEAR_PROJECT_MANAGEMENT_PLAN.md`

---

## ✅ **Phase 1: Initial Setup (30 minutes)**

### **Workspace & Team**
- [ ] Create Linear workspace: "SPOTS"
- [ ] Set timezone
- [ ] Create team: "SPOTS Development"
- [ ] Add yourself to team

### **API Setup**
- [ ] Generate API key (Settings → API → Personal API Keys)
- [ ] Name: "SPOTS Sync"
- [ ] Store securely (add to `.env` or secrets)
- [ ] Test API connection

**Get Team ID:**
```python
query = """
query {
  teams {
    nodes {
      id
      name
    }
  }
}
"""
```

---

## ✅ **Phase 2: Structure Setup (35 minutes)**

### **Custom Fields**
- [ ] Phase Number (Number)
- [ ] Section Number (Text)
- [ ] Subsection Number (Text)
- [ ] Master Plan Status (Select: Unassigned, In Progress, Complete)
- [ ] Priority (Select: P0, P1, P2, P3)
- [ ] Progress % (Number: 0-100)

### **Labels**
- [ ] `backend`, `frontend`, `testing`, `integration`, `documentation`
- [ ] `p0-critical`, `p1-high`, `p2-medium`, `p3-low`
- [ ] `blocked`, `in-review`, `doors-compliant`

### **Workflow States**
- [ ] Unassigned (Gray)
- [ ] In Progress (Blue)
- [ ] Review (Yellow)
- [ ] Blocked (Red)
- [ ] Complete (Green)

---

## ✅ **Phase 3: Progress Tracking (1 hour)**

### **Dashboard**
- [ ] Create dashboard (Insights → Create Dashboard)
- [ ] Add widget: Progress by Phase
- [ ] Add widget: Issues by Status
- [ ] Add widget: Completion Timeline
- [ ] Add widget: Blocker Count

### **Roadmap**
- [ ] Create roadmap (Roadmaps → Create Roadmap)
- [ ] Add all Phase projects (when created)
- [ ] Set dates from Master Plan estimates
- [ ] Add milestones

### **Saved Filters**
- [ ] "Active Work" (In Progress, Not Blocked)
- [ ] "Blocked Issues" (Status: Blocked)
- [ ] "Phase 7" (Current phase)
- [ ] "High Priority" (P0 or P1)
- [ ] "This Week" (Due this week)

---

## ✅ **Phase 4: Integration (30 minutes)**

### **GitHub Integration**
- [ ] Linear Settings → Integrations → GitHub
- [ ] Connect SPOTS repository
- [ ] Enable: Auto-link PRs to issues
- [ ] Enable: Update Linear from commits

### **Daily Workflow**
- [ ] Morning: Check dashboard, review blockers
- [ ] During work: Update issue status, add comments
- [ ] End of day: Mark completed work, update status

---

## ✅ **Phase 5: Master Plan Sync (When Ready)**

### **Script Setup**
- [ ] Create `scripts/linear_sync/` directory
- [ ] Create `sync_master_plan.py`
- [ ] Create `linear_client.py`
- [ ] Create `master_plan_parser.py`
- [ ] Create `config.py`
- [ ] Create `requirements.txt`

### **Initial Sync**
- [ ] Run sync script: `python scripts/linear_sync/sync_master_plan.py`
- [ ] Verify all phases created as Projects
- [ ] Verify all sections created as Issues
- [ ] Check custom fields populated
- [ ] Review in Linear UI

---

## 📋 **Quick Commands**

### **Test API Connection**
```python
python -c "
import requests
headers = {'Authorization': 'YOUR_API_KEY', 'Content-Type': 'application/json'}
query = 'query { viewer { id name } }'
response = requests.post('https://api.linear.app/graphql', json={'query': query}, headers=headers)
print(response.json())
"
```

### **Get Team ID**
```python
python -c "
import requests
headers = {'Authorization': 'YOUR_API_KEY', 'Content-Type': 'application/json'}
query = 'query { teams { nodes { id name } } }'
response = requests.post('https://api.linear.app/graphql', json={'query': query}, headers=headers)
print(response.json())
"
```

---

## 🎯 **Priority Order**

1. **Do First:** Phase 1 (Workspace & API) - 30 min
2. **Do Second:** Phase 2 (Structure) - 35 min
3. **Do Third:** Phase 3 (Tracking) - 1 hour
4. **Do Fourth:** Phase 4 (Integration) - 30 min
5. **Do When Ready:** Phase 5 (Master Plan Sync)

**Total Setup Time:** ~2.5 hours (before Master Plan sync)

---

**Reference:** See `LINEAR_PROJECT_MANAGEMENT_PLAN.md` for detailed instructions


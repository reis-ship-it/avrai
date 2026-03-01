# In-App Admin System Design

**Date:** January 2025  
**Status:** Design Proposal  
**Reference:** OUR_GUTS.md - "Community, Not Just Places"

---

## 🎯 **WHAT SPOTS ACTUALLY IS**

SPOTS is an **offline-first social platform** focused on location-based community:
- **Social Discovery** - Connect with people through places and shared interests
- **Community Building** - Users create communities, host events, build followings
- **Location-Based Social** - Social interactions centered around places and experiences
- **Data Quality** - Accurate place information enables better social connections
- **Event Hosting** - Users host events, build communities, earn trust

**Admin Role:** Community leadership + data quality. Trusted community members who host events and build followings can become admins to help manage communities and maintain platform quality.

---

## 🎯 **CORE PRINCIPLES**

1. **Community First** - Trusted users who build communities can become admins
2. **Data Quality** - Ensure location data is accurate and trustworthy
3. **Social Trust** - Event hosting and followings demonstrate community leadership
4. **Efficiency** - Quick actions for common tasks, bulk operations where appropriate
5. **Safety** - Remove spam, fake places, inappropriate content
6. **Audit Trail** - All admin actions are logged and traceable
7. **Business Integrity** - Verify real businesses, prevent fake listings

---

## 📋 **ADMIN MODULE STRUCTURE**

### **1. Dashboard Overview**
**Purpose:** Data quality and system health monitoring

**Metrics Display:**
- Pending business verification requests
- Duplicate spot detection queue
- Location accuracy issues flagged
- Spam/fake place reports
- System health indicators
- Data sync status
- AI2AI network status (already implemented)

**Quick Actions:**
- Review next 5 verification requests
- Process duplicate merges
- Fix location accuracy issues
- System status overview

---

### **2. Data Quality & Verification**

#### **2.1 Business Verification Queue**
**Priority Logic:**
```
Priority = f(verificationType, businessSize, locationAccuracy, documentQuality)

High Priority:
- Large businesses (100+ employees)
- Chain locations requiring verification
- Businesses with location discrepancies
- High-traffic areas

Medium Priority:
- Small businesses with complete documents
- Standard verification requests
- Clear location matches

Low Priority:
- Auto-verified (Google Places match)
- Repeat locations already verified
- Low-traffic areas
```

**Actions Available:**
- ✅ **Approve** - Business verified, mark as verified
- ❌ **Reject** - Fake/spam business, remove listing
- 📧 **Request Info** - Need more documents/information
- 🔍 **Investigate** - Deep dive into business details
- 📝 **Edit** - Fix business info (name, category, location)
- 🔗 **Link to Google Places** - Connect to Google Place ID

**Bulk Operations:**
- Approve/reject multiple verifications
- Filter by category, location, verification type
- Export verification log

#### **2.2 Spot Quality Management**
**Report Types:**
- Fake/non-existent place
- Incorrect location
- Wrong category
- Spam/duplicate
- Inappropriate content
- Business closed/permanently closed
- Other

**Report Review Flow:**
1. View report details (who reported, when, why)
2. View reported content in context
3. Check reporter history (legitimate vs. abuse)
4. Check content creator history
5. Make decision
6. Apply action
7. Notify relevant parties

**Auto-Actions:**
- Auto-flag if 3+ reports in <24 hours
- Auto-suspend if user has 3+ violations in 30 days
- Auto-escalate if contains banned keywords

---

### **3. Community Management**

#### **3.1 Community Creation**
**Who Can Create:**
- Community Admins (unlocked)
- Users with event hosting pins
- Users with 50+ followers
- Application-based approval

**Community Types:**
- **Geographic** - "Brooklyn Coffee Community", "NYC Foodies"
- **Interest-Based** - "Vintage Shop Lovers", "Bookstore Explorers"
- **Event-Based** - Communities around recurring events
- **Expertise-Based** - Communities for specific expertise areas

**Community Features:**
- Member approval (admin-controlled)
- Community-specific lists
- Community events
- Community spots
- Member directory
- Community analytics

#### **3.2 Event Hosting**
**Event Hosting Requirements:**
- Earned pins in relevant category
- Community admin status OR curator with following
- Application approval for first-time hosts

**Event Management:**
- Create events at specific spots
- Set event details (date, time, description)
- Manage attendees
- Post-event follow-up
- Event analytics

**Path to Community Admin:**
- Host 5+ successful events
- Build 50+ followers
- Earn community respect
- Apply for community admin status

#### **3.3 Spot & Location Management**

**3.3.1 Duplicate Detection**
**Auto-Detection:**
- Same name + similar location (<50m)
- Same Google Place ID
- Similar names + same coordinates
- User-reported duplicates

**Actions:**
- 🔗 **Merge** - Combine duplicates, keep best data
- ❌ **Delete** - Remove duplicate, keep original
- 📝 **Edit** - Fix name/location to differentiate
- ✅ **Keep Both** - Legitimate separate places

**3.3.2 Location Accuracy**
**Issues to Fix:**
- Coordinates don't match address
- Place is in wrong city/neighborhood
- Coordinates point to wrong building
- Address doesn't exist
- Place moved/relocated

**Actions:**
- 📍 **Correct Location** - Fix coordinates/address
- 🔍 **Verify on Map** - Check against satellite imagery
- 📧 **Request User Info** - Ask creator for clarification
- ❌ **Remove** - If location can't be verified

#### **3.4 User Management**
**Community Admin Powers:**
- Approve/remove community members
- View member activity within community
- Suspend members from their community
- Promote active members

**Super Admin Powers:**
- Platform-wide user management
- Suspend spam accounts
- Ban repeat offenders
- Promote users to Community Admin
- View all user activity

---

### **4. Spot & List Quality Control**

#### **4.1 Spot Management**
**Primary Focus: Data Accuracy**

**Spot Actions:**
- View spot details with map verification
- Edit spot (name, description, category, location)
- Delete spot (fake/spam/closed)
- Merge duplicate spots
- Link to Google Place ID
- Verify location accuracy
- Correct category misclassification
- View all lists containing spot
- View spot analytics

**Quality Checks:**
- ✅ Location matches address
- ✅ Place actually exists
- ✅ Category is correct
- ✅ Not a duplicate
- ✅ Not spam/fake
- ✅ Business still open (if applicable)

#### **4.2 List Quality**
**List Actions:**
- View list details
- Edit list (title, description, category) - Fix typos/errors
- Delete list (spam/inappropriate)
- View all spots in list
- Check for spam spots in list
- View list analytics

**Quality Focus:**
- Lists contain real, accurate spots
- No spam or fake places
- Proper categorization
- Helpful descriptions

---

### **5. Business Verification**

#### **5.1 Verification Queue**
**Pending Requests:**
- Business name, category, location
- Submitted documents
- Verification method (automatic vs. manual)
- Submission date
- Previous attempts

**Actions:**
- ✅ **Approve** - Mark as verified business
- ❌ **Reject** - Request more info or deny
- 📧 **Request Info** - Ask for additional documents
- 🔍 **Investigate** - Deep dive into business details

**Auto-Verification:**
- If business matches Google Places API
- If documents are valid
- If no red flags detected

#### **5.2 Verified Business Management**
- View all verified businesses
- Revoke verification
- Update business info
- View business analytics

---

### **6. Analytics & Insights**

#### **6.1 Community Health**
**Metrics:**
- Daily active users
- New registrations
- Content creation rate
- Report rate (reports per 1000 users)
- Moderation queue size
- Average time to resolution

**Trends:**
- User growth
- Content quality trends
- Report trends by type
- Moderation efficiency

#### **6.2 Content Analytics**
- Most respected lists
- Most viewed spots
- Popular categories
- Geographic distribution
- User engagement metrics

#### **6.3 System Health**
- API response times
- Error rates
- Database performance
- Sync status
- AI2AI network health (already implemented)

---

### **7. System Settings**

#### **7.1 Moderation Settings**
**Auto-Moderation Rules:**
- Keyword filters (banned words)
- Auto-flag thresholds
- Auto-suspend thresholds
- Age-restriction enforcement
- Spam detection sensitivity

**Moderation Levels:**
- Relaxed - Minimal intervention
- Standard - Balanced approach
- Strict - Aggressive moderation
- Maximum - Zero tolerance

#### **7.2 Feature Flags**
- Enable/disable features
- A/B test configurations
- Beta feature access

#### **7.3 Notification Settings**
- Email alerts for critical issues
- Dashboard notifications
- Report thresholds

---

### **8. Audit Log**

#### **8.1 Action History**
**Logged Actions:**
- All moderation decisions
- User role changes
- Account suspensions/bans
- Content edits/deletions
- System setting changes
- Admin logins

**Log Details:**
- Who performed action
- When it was performed
- What was changed
- Reason/notes
- IP address (for security)

**Search & Filter:**
- By admin user
- By action type
- By date range
- By affected user/content
- Export logs

---

## 🔐 **SECURITY & ACCESS CONTROL**

### **Admin Role Hierarchy**
```
Super Admin (Level 5) - SPOTS Employees
├── Full system access
├── Can manage other admins
├── System settings
├── Business verification
├── Community creation approval
└── Audit log access

Community Admin (Level 4) - Trusted Community Members
├── Created/manage communities
├── Host events (unlocked via pins/expertise)
├── Moderate their communities
├── Spot quality control (within their communities)
├── Approve community members
├── Business verification (for their community area)
├── Analytics access (community-level)
└── Earned through: Event hosting + following + expertise

Admin (Level 4) - SPOTS Employees/Contractors
├── Business verification
├── Spot quality control (platform-wide)
├── Duplicate management
├── Location accuracy fixes
├── Spam/fake detection
├── Community oversight
├── Analytics access
└── Cannot manage other admins

Curator (Level 3) - Community Users
├── List management
├── Can host events (with pins)
└── Path to Community Admin
```

### **Path to Community Admin**

**Requirements:**
1. **Event Hosting** - Successfully hosted X events (e.g., 5+ events)
2. **Following** - Built a following (e.g., 50+ followers)
3. **Expertise** - Earned pins in relevant categories
4. **Community Respect** - Lists/events have high respect counts
5. **Application** - Apply to become community admin
6. **Approval** - Reviewed and approved by Super Admin

**Community Admin Powers:**
- Create and manage communities (geographic or interest-based)
- Host events within their communities
- Moderate content within their communities
- Approve/remove community members
- Verify businesses in their community area
- Access community analytics

### **Permission Matrix**

| Action | Super Admin | Community Admin | Admin (Employee) | Curator |
|--------|------------|----------------|-----------------|---------|
| Create Communities | ✅ | ✅ (their own) | ❌ | ❌ |
| Host Events | ✅ | ✅ | ❌ | ✅ (with pins) |
| Moderate Communities | ✅ | ✅ (their own) | ✅ (all) | ❌ |
| Business Verification | ✅ | ✅ (their area) | ✅ | ❌ |
| Approve/Reject Spots | ✅ | ✅ (their area) | ✅ | ❌ |
| Merge Duplicates | ✅ | ✅ | ✅ | ❌ |
| Fix Location Accuracy | ✅ | ✅ | ✅ | ❌ |
| Suspend Spam Accounts | ✅ | ✅ (their area) | ✅ | ❌ |
| System Settings | ✅ | ❌ | ❌ | ❌ |
| View Audit Logs | ✅ | ✅ (their actions) | ✅ | ❌ |
| Analytics Access | ✅ | ✅ (community) | ✅ | ❌ |
| Manage Lists | ✅ | ✅ | ✅ | ✅ (own) |

---

## 🎨 **UI/UX DESIGN**

### **Dashboard Layout**
```
┌─────────────────────────────────────┐
│  Admin Dashboard                    │
├─────────────────────────────────────┤
│  [Quick Stats Cards]                │
│  ┌─────┐ ┌─────┐ ┌─────┐ ┌─────┐  │
│  │ 12  │ │ 5   │ │ 3   │ │ 2   │  │
│  │Pending│ │Reports│ │Susp│ │Verify│ │
│  └─────┘ └─────┘ └─────┘ └─────┘  │
├─────────────────────────────────────┤
│  [Priority Queue]                   │
│  • High priority items              │
│  • Quick actions                    │
├─────────────────────────────────────┤
│  [Recent Activity]                  │
│  • Last 10 admin actions           │
└─────────────────────────────────────┘
```

### **Moderation Queue View**
```
┌─────────────────────────────────────┐
│  Moderation Queue          [Filters]│
├─────────────────────────────────────┤
│  Priority | Type | Content | Actions│
│  ─────────────────────────────────  │
│  🔴 High  | List | "Best..." | [✅][❌]│
│  🟡 Med   | Spot | "Coffee..." | [✅][❌]│
│  🟢 Low   | List | "Parks..." | [✅][❌]│
└─────────────────────────────────────┘
```

### **User Management View**
```
┌─────────────────────────────────────┐
│  User Management         [Search]    │
├─────────────────────────────────────┤
│  User | Role | Status | Actions     │
│  ─────────────────────────────────  │
│  John | Curator | Active | [View][⚠️]│
│  Jane | Follower | Susp | [View][✅]│
└─────────────────────────────────────┘
```

---

## 🚀 **IMPLEMENTATION PRIORITY**

### **Phase 1: Core Community Features (MVP)**
1. ✅ Community creation (for Community Admins)
2. ✅ Event hosting system
3. ✅ Community member management
4. ✅ Business verification queue
5. ✅ Basic audit log

### **Phase 2: Community Admin System**
1. Path to Community Admin (event hosting + following requirements)
2. Community Admin application process
3. Community moderation tools
4. Community analytics
5. Event management tools

### **Phase 3: Data Quality & Verification**
1. Duplicate spot detection
2. Location accuracy tools
3. Bulk operations
4. Google Places ID linking
5. Category validation

### **Phase 4: Advanced Features**
1. Auto-verification rules
2. ML-based duplicate detection
3. Location accuracy scoring
4. Spam detection algorithms
5. Community health metrics

### **Phase 5: Optimization**
1. Predictive quality scoring
2. Automated location fixes
3. Advanced reporting
4. Performance optimization

---

## 📊 **METRICS & KPIs**

### **Moderation Efficiency**
- Average time to resolution
- Queue size over time
- False positive rate
- User satisfaction with moderation

### **Community Health**
- Report rate per 1000 users
- Repeat offender rate
- Content quality score
- User retention after moderation

### **System Performance**
- Admin dashboard load time
- Search performance
- Bulk operation speed

---

## 🔄 **WORKFLOW EXAMPLES**

### **Example 1: Verifying a Business**
```
1. Business submits verification → Added to queue
2. Admin views request → Checks documents, location, Google Places match
3. Admin verifies:
   - Documents are valid
   - Location matches address
   - Business exists in Google Places
   - No red flags
4. Admin decision:
   - If verified → Approve, mark as verified, link Google Place ID
   - If needs info → Request additional documents
   - If fake → Reject, remove listing
5. Action logged → Audit trail created
6. Business notified → Verification status updated
```

### **Example 2: Merging Duplicate Spots**
```
1. Duplicate detected → Auto-flagged (same name + <50m apart)
2. Admin reviews → Checks both spots, user reports
3. Admin verifies:
   - Same place? (check address, coordinates, photos)
   - Which has better data?
   - Which was created first?
4. Admin decision:
   - Merge → Combine data, keep best info, delete duplicate
   - Keep separate → Different places, fix names/locations
5. Action logged → Audit trail created
6. Users notified → If their spots were merged
```

### **Example 3: Fixing Location Accuracy**
```
1. User reports wrong location → Added to queue
2. Admin views spot → Checks coordinates vs address
3. Admin verifies:
   - Opens map view
   - Checks satellite imagery
   - Verifies address exists
4. Admin fixes:
   - Corrects coordinates
   - Updates address if needed
   - Links to Google Place ID if available
5. Action logged → Audit trail created
```

---

## 🛡️ **SAFETY MEASURES**

### **Prevent Abuse**
- Admin actions require confirmation for destructive operations
- Cannot ban other admins (requires super admin)
- All actions logged and auditable
- Rate limiting on admin actions
- IP logging for security

### **Data Protection**
- Admin access requires 2FA (future)
- Session timeout after inactivity
- Encrypted audit logs
- Regular security audits

---

## 📝 **SPOTS AS OFFLINE-FIRST SOCIAL PLATFORM**

### **SPOTS Community Admins Are:**
- ✅ **Community Leaders** - Build and manage communities around places/interests
- ✅ **Event Hosts** - Organize events, bring people together
- ✅ **Trusted Members** - Earned trust through hosting, following, expertise
- ✅ **Location Experts** - Understand their community's places
- ✅ **Quality Maintainers** - Ensure accurate data within their communities

### **SPOTS Community Admins:**
- ✅ **Create Communities** - Geographic or interest-based communities
- ✅ **Host Events** - Organize community events at spots
- ✅ **Moderate Communities** - Manage members, content within their communities
- ✅ **Build Followings** - Grow community through quality curation
- ✅ **Earn Trust** - Path to admin through demonstrated leadership

### **Admin Focus:**
- **Community Building** - Bring people together around places
- **Event Hosting** - Create experiences and connections
- **Social Trust** - Earned through actions, not assigned
- **Location-Based Social** - Social interactions centered on places
- **Data Quality** - Maintain accurate place data for better connections

---

## 📝 **NOTES**

- All admin actions should respect OUR_GUTS.md principles
- Privacy-preserving analytics only
- Focus on data accuracy and quality
- Help maintain trustworthy place information
- Ensure users can trust the data they're discovering

---

## 🎯 **COMMUNITY CREATION FUNCTION**

### **How Users Become Community Admins**

**Step 1: Build Trust**
- Host events (requires pins/expertise)
- Create respected lists
- Build a following (50+ followers)
- Earn community respect

**Step 2: Apply for Community Admin**
- Submit application
- Show event hosting history
- Demonstrate community leadership
- Reference respected lists/events

**Step 3: Community Admin Powers**
- Create communities (geographic or interest-based)
- Host events within communities
- Approve/remove community members
- Moderate community content
- Verify businesses in community area
- Access community analytics

**Step 4: Community Growth**
- Grow community through events
- Curate quality lists
- Build community reputation
- Maintain data quality

### **Community Types**

**Geographic Communities:**
- "Brooklyn Coffee Community"
- "NYC Food Explorers"
- "SF Tech Spots"

**Interest-Based Communities:**
- "Vintage Shop Lovers"
- "Bookstore Explorers"
- "Outdoor Adventure Seekers"

**Event-Based Communities:**
- Communities around recurring events
- Event series communities
- Seasonal event communities

---

**Next Steps:**
1. Review and approve design
2. Create implementation plan
3. Build Phase 1 MVP (Community creation + event hosting)
4. Build Community Admin application system
5. Test with real community scenarios
6. Iterate based on feedback


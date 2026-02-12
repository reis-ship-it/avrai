# Professional & Local Expertise - Final Enhancements

**Created:** November 21, 2025  
**Status:** ✅ Complete System Design  
**Main Plan:** [`DYNAMIC_EXPERTISE_THRESHOLDS_PLAN.md`](./DYNAMIC_EXPERTISE_THRESHOLDS_PLAN.md)

---

## 🎯 Two Final Critical Features

### **1. Professional Expertise Recognition**
**Problem:** Qualified professionals (chefs, writers, professors) excluded  
**Solution:** Professional experience with proof of work counts as expertise

### **2. Locality-Based Expertise**
**Problem:** Sheer quantity ignores geographic concentration  
**Solution:** Expertise is location-specific; host events where you're expert

---

## 👨‍🍳 Feature 1: Professional Expertise

### **Who Qualifies as Professional Expert:**

**Culinary Professionals:**
- ✅ Chefs (head chef, sous chef, executive chef)
- ✅ Baristas (professional, competition-level)
- ✅ Sommeliers (certified)
- ✅ Bartenders (professional, mixologists)
- ✅ Pastry chefs
- ✅ Restaurant owners/operators

**Writers & Critics:**
- ✅ Food writers/critics
- ✅ Art critics
- ✅ Music journalists
- ✅ Authors (published)
- ✅ Editors (magazines, publications)

**Educators:**
- ✅ Professors (university)
- ✅ Teachers (K-12, specialized)
- ✅ Instructors (professional training)
- ✅ Coaches (certified)
- ✅ Mentors (verified programs)

**Consultants & Advisors:**
- ✅ Industry consultants
- ✅ Specialists (verified expertise)
- ✅ Analysts (professional)

**Arts & Culture:**
- ✅ Curators (museum, gallery)
- ✅ Gallerists (gallery owners)
- ✅ Museum directors
- ✅ Professional artists

**Healthcare:**
- ✅ Doctors (licensed)
- ✅ Nurses (RN, licensed)
- ✅ Therapists (licensed)
- ✅ Nutritionists (certified)

---

## 📋 Professional Verification Requirements

### **Proof of Work Needed:**

```dart
class ProfessionalExperience {
  // Basic info
  final ProfessionalRole role;        // "Head Chef"
  final String workplace;             // "Alinea Restaurant"
  final String? specialization;       // "Modern American Cuisine"
  final DateTime startDate;
  final DateTime? endDate;            // null = current
  
  // Verification (REQUIRED)
  final bool verified;
  final VerificationMethod method;
  final String verificationProof;
  
  // Proof of Work (RECOMMENDED)
  final List<String>? portfolioLinks;  // Photos, articles, menus
  final List<String>? awards;          // "Michelin Star 2023"
  final List<String>? mediaFeatures;   // "Featured in NY Times"
  final List<String>? testimonials;    // From employers, clients
}
```

### **Verification Methods:**

**Method 1: LinkedIn Cross-Reference**
```
User connects LinkedIn account
├─ Job title matches
├─ Employment dates match
├─ Company verification
└─ Auto-verified ✅
```

**Method 2: Employer Letter**
```
Upload letter on company letterhead
├─ Admin reviews
├─ Contacts employer if needed
├─ Photo of letter
└─ Verified ✅
```

**Method 3: License/Certification**
```
Upload professional license
├─ Doctor: Medical license
├─ Nurse: RN license
├─ Sommelier: Certification card
├─ Admin verifies with registry
└─ Verified ✅
```

**Method 4: Portfolio Review**
```
Submit portfolio of work
├─ Chef: Menu photos, food photos
├─ Writer: Published articles (with links)
├─ Artist: Gallery exhibitions
├─ Admin reviews quality and authenticity
└─ Verified ✅
```

**Method 5: Peer Endorsement**
```
3+ verified professionals in field endorse
├─ Must be existing verified experts
├─ Write testimonial
├─ Stake their reputation
└─ Verified ✅
```

---

## 💼 Professional Expertise Examples

### **Example 1: Head Chef**

```
Marcus Rivera - Head Chef at Alinea (Chicago)

Professional Experience:
├─ Role: Head Chef
├─ Workplace: Alinea Restaurant
├─ Specialization: Modern American Cuisine
├─ Tenure: 7 years (2017-present)
├─ Verification: ✅ LinkedIn + Employer Letter
│
├─ Awards:
│   • Michelin 3-Star (2020-2024)
│   • James Beard Finalist (2022)
│   • Chef of the Year, Chicago (2023)
│
├─ Portfolio:
│   • Menu photos (seasonal collections)
│   • Featured in Food & Wine Magazine
│   • Guest chef appearances
│
└─ Proof of Work Score: 0.95 / 1.0

Expertise Calculation:
├─ Exploration: 15 visits (0.35 × 40%) = 0.14
├─ Professional: 0.95 score (× 25%) = 0.24
├─ Influence: Local food scene (× 20%) = 0.08
├─ Community: Mentors young chefs (× 15%) = 0.12
└─ TOTAL: 0.58 / 1.0

Status: Expert level
With 5 more local visits → City-level (0.60) ✅
Can host: Italian Food events in Chicago
```

### **Example 2: Food Writer**

```
Jessica Chen - Food Critic, NY Times

Professional Experience:
├─ Role: Food Journalist
├─ Workplace: The New York Times
├─ Specialization: Restaurant Reviews
├─ Tenure: 5 years (2019-present)
├─ Verification: ✅ Published articles + LinkedIn
│
├─ Portfolio:
│   • 200+ published restaurant reviews
│   • James Beard Award: Food Journalism (2023)
│   • Weekly column: "NYC Eats"
│   • Book: "Hidden Gems of NYC" (2024)
│
└─ Proof of Work Score: 0.92 / 1.0

Expertise Calculation:
├─ Exploration: 45 visits (0.75 × 40%) = 0.30
├─ Professional: 0.92 score (× 25%) = 0.23
├─ Influence: 15K followers (× 20%) = 0.10
├─ Community: Answers questions (× 15%) = 0.08
└─ TOTAL: 0.71 / 1.0

Status: City-level ✅
Can host: Food events in Manhattan
```

### **Example 3: Coffee Science Professor**

```
Dr. Sarah Williams - Professor of Food Science

Academic + Professional:
├─ Education:
│   • PhD in Food Science (UC Davis)
│   • Specialization: Coffee Chemistry
│   • Published: 12 peer-reviewed papers on coffee
│
├─ Professional:
│   • Role: Professor
│   • Institution: Columbia University
│   • Courses: "Science of Coffee" (8 years)
│   • Tenure: 8 years
│   • Verification: ✅ University website + LinkedIn
│
└─ Combined Score: 0.98 / 1.0

Expertise Calculation:
├─ Exploration: 20 visits (0.45 × 40%) = 0.18
├─ Academic: PhD + Publications (× 25%) = 0.25
├─ Professional: Professor (× 25% overlap) = —
├─ Influence: Academic citations (× 20%) = 0.12
├─ Community: Teaches students (× 15%) = 0.15
└─ TOTAL: 0.70 / 1.0

Status: City-level ✅
Can host: Coffee education events in NYC
Note: High credibility despite moderate visit count
```

### **Example 4: Fitness Coach**

```
Mike Thompson - Certified Personal Trainer

Professional Experience:
├─ Role: Personal Training Coach
├─ Specialization: Strength Training
├─ Certifications:
│   • NASM-CPT (National Academy of Sports Medicine)
│   • Precision Nutrition Level 1
│   • 150+ clients trained
│
├─ Tenure: 6 years (2018-present)
├─ Verification: ✅ Cert card photos + Testimonials
│
├─ Portfolio:
│   • Client transformation photos (with permission)
│   • Video content (proper form demonstrations)
│   • Testimonials from 25+ clients
│
└─ Proof of Work Score: 0.78 / 1.0

Expertise Calculation:
├─ Exploration: 30 gym visits (0.60 × 40%) = 0.24
├─ Professional: 0.78 score (× 25%) = 0.20
├─ Influence: 5K fitness followers (× 20%) = 0.06
├─ Community: Coaches group classes (× 15%) = 0.13
└─ TOTAL: 0.63 / 1.0

Status: City-level ✅
Can host: Fitness events locally
```

---

## 🌍 Feature 2: Locality-Based Expertise

### **The Core Concept:**

```
Expertise is Geographic:
├─ Deep local knowledge > Shallow broad knowledge
├─ Quality concentration > Quantity spread
└─ Can host where you're truly expert
```

### **How It Works:**

```dart
User visits are automatically analyzed by location:

Sarah's Coffee Visits:
├─ Williamsburg (Brooklyn): 25 visits
├─ Park Slope (Brooklyn): 12 visits
├─ Dumbo (Brooklyn): 8 visits
├─ Manhattan (various): 5 visits
└─ Queens: 2 visits

Geographic Scopes Calculated:
├─ Brooklyn: 45 visits (87%) → City-level ✅
├─ Manhattan: 5 visits (10%) → Enthusiast
└─ Queens: 2 visits (3%) → Novice

Can Host Events In:
✅ Brooklyn (City-level expertise)
❌ Manhattan (not enough expertise yet)
❌ Queens (not enough expertise yet)
```

---

## 📍 Local Expertise Examples

### **Example 1: Brooklyn Coffee Expert**

```
Sarah Martinez - Coffee Expert

Geographic Analysis:
┌─────────────────────────────────────────┐
│  Brooklyn Coffee Expertise              │
├─────────────────────────────────────────┤
│  Visits: 45 spots (87% of total)        │
│  Quality: 4.6★ average                  │
│  Reviews: 35 (highly detailed)          │
│  Events hosted: 5 (all successful)      │
│  Time span: 18 months                   │
│  Last visit: 3 days ago (active)        │
│                                         │
│  Level: City-level ✅                   │
│  Can host events: YES                   │
└─────────────────────────────────────────┘

┌─────────────────────────────────────────┐
│  Manhattan Coffee Expertise             │
├─────────────────────────────────────────┤
│  Visits: 5 spots (10% of total)         │
│  Quality: 4.4★ average                  │
│  Reviews: 3                             │
│  Events hosted: 0                       │
│  Last visit: 45 days ago                │
│                                         │
│  Level: Enthusiast                      │
│  Can host events: NO (needs 20+ visits) │
│  Progress: 25% to City-level            │
└─────────────────────────────────────────┘

Profile Display:
"Coffee Expert in Brooklyn 🎯"
"Can host events in: Williamsburg, Park Slope, Dumbo"
```

### **Example 2: Multi-City Expert**

```
David Park - Pizza Expert

Chicago (Lincoln Park):
├─ Visits: 28 restaurants
├─ Professional: Food blogger (verified)
├─ Events hosted: 8
├─ Level: City-level ✅
└─ Can host in Chicago

New York (Manhattan):
├─ Visits: 35 restaurants
├─ Professional: Same food blog
├─ Events hosted: 6
├─ Level: City-level ✅
└─ Can host in NYC

Los Angeles:
├─ Visits: 12 restaurants
├─ Level: Knowledgeable
└─ Cannot host yet

Profile Display:
"Pizza Expert in Chicago & NYC 🍕"
"Can host events in: Chicago, Manhattan"
```

### **Example 3: Neighborhood Specialist**

```
Emma Rodriguez - Williamsburg Art Expert

Williamsburg (Brooklyn):
├─ Visits: 42 galleries
├─ Professional: Gallery curator (verified)
├─ Highly concentrated expertise
├─ Level: City-level ✅
└─ Can host in Williamsburg

Rest of Brooklyn:
├─ Visits: 8 galleries
├─ Level: Enthusiast
└─ Cannot host yet

Profile Display:
"Art Expert in Williamsburg 🎨"
"Deep local knowledge, 42 galleries visited"
"Can host events in: Williamsburg"

Why This Works:
✅ Emma knows Williamsburg art scene deeply
✅ Better than someone with 50 visits spread thin
✅ Can give authentic, detailed tours
✅ Quality > Quantity
```

---

## 📊 Combined Professional + Local System

### **Example: The Perfect Local Expert**

```
Chef Antonio Russo - Italian Food Expert

Professional Background:
├─ Head Chef at "Nonna's Kitchen" (Chicago)
├─ 15 years experience
├─ Trained in Bologna, Italy
├─ James Beard nominee
└─ Professional Score: 0.90

Geographic Expertise:
├─ Chicago (Little Italy): 22 restaurants (visited)
├─ Professional venue: Nonna's Kitchen
├─ Events hosted: 12 (all in Little Italy)
└─ Local Score: City-level ✅

Combined Expertise:
├─ Professional: 0.90 × 25% = 0.23
├─ Local Exploration: 0.75 × 40% = 0.30
├─ Influence: Local food scene × 20% = 0.12
├─ Community: Mentors chefs × 15% = 0.14
└─ TOTAL: 0.79 / 1.0

Status: City-level Expert ⭐
Location: Little Italy, Chicago
Can host: Italian Food events in Little Italy

Why This Is Perfect:
✅ Professional credentials (actual chef)
✅ Local knowledge (knows neighborhood deeply)
✅ Active community member (hosts events)
✅ Geographic concentration (doesn't need to know all of Chicago)
✅ Authentic expertise (lives and works there)
```

---

## 🎯 Benefits of Combined System

### **1. Inclusivity**

**Before:**
- ❌ Chef with 10 years experience: Not expert (only 10 visits logged)
- ❌ Professor with PhD: Not expert (only 15 visits)
- ❌ Local with deep knowledge: Not expert (wrong neighborhood)

**After:**
- ✅ Chef: Expert via professional path
- ✅ Professor: Expert via academic path
- ✅ Local: Expert via geographic concentration

### **2. Quality Over Quantity**

**Before:**
```
User A: 50 visits across entire city
└─ Shallow knowledge everywhere

User B: 30 visits concentrated in one area
└─ Not enough total visits
```

**After:**
```
User A: 50 visits spread thin
├─ No local expertise designation
└─ Cannot host (no deep knowledge)

User B: 30 visits concentrated (Brooklyn)
├─ City-level in Brooklyn ✅
└─ Can host Brooklyn events
```

### **3. Authentic Hosting**

**Events hosted by:**
- ✅ Local experts who know the area
- ✅ Professionals who work there
- ✅ People with concentrated knowledge
- ❌ Not tourists who visited once

---

## 📊 Real-World Scenarios

### **Scenario 1: New Chef in Town**

```
Marco moves to Chicago, starts as head chef:

Week 1:
├─ Uploads professional experience
├─ Head Chef at Michelin restaurant (verified) ✅
├─ 10 years experience
└─ Status: Expert nationally

Week 4:
├─ Visits 8 local restaurants (learning area)
├─ Geographic: Chicago (learning)
└─ Status: Expert, but cannot host locally yet

Week 8:
├─ Total visits: 18 in Chicago
├─ All concentrated in West Loop
├─ Professional + Local = City-level ✅
└─ Status: Can host in West Loop

Combined Score:
├─ Professional: 0.90 (strong credentials)
├─ Local: 0.45 (18 visits in West Loop)
├─ Total with weighting: 0.62
└─ City-level achieved ✅
```

### **Scenario 2: Food Blogger Expanding**

```
Jessica has 50K followers, writes about food:

Start:
├─ NYC Manhattan: 40 visits → City-level ✅
├─ Can host in Manhattan
└─ Wants to expand to Brooklyn

3 Months Later:
├─ Manhattan: Still City-level (maintained)
├─ Brooklyn: 25 visits → City-level ✅
├─ Combined professional + local
└─ Can now host in Manhattan AND Brooklyn

Profile:
"Food Expert in Manhattan & Brooklyn"
Multi-location expertise recognized
```

### **Scenario 3: University Professor**

```
Dr. Williams teaches coffee science:

Academic Credentials:
├─ PhD in Food Science ✅
├─ 12 published papers on coffee
├─ Professor at Columbia (8 years)
└─ Credential score: 0.95

Local Activity (NYC):
├─ Visits: 20 coffee shops (concentrated in Morningside Heights)
├─ Near campus, daily patterns
├─ Quality engagement
└─ Local score: 0.50

Combined:
├─ Academic: 0.95 × 25% = 0.24
├─ Local: 0.50 × 40% = 0.20
├─ Professional: Overlap with academic
├─ Community: Teaches students = 0.12
└─ Total: 0.66 / 1.0

Status: City-level ✅
Can host: Coffee education events near Columbia campus
Note: High credibility despite moderate visit count
```

---

## 🏅 Golden Local Expert - 25+ Year Residents

### **The Ultimate Local Authority**

**The Concept:**
> 25+ continuous years living in one place = Golden Local Expert status

**Why This Matters:**
- **Irreplaceable historical knowledge**
- Seen businesses come and go
- Understands community deeply
- Knows what works (and doesn't)
- **Keepers of local culture**

### **Qualification:**

```
Requirements:
├─ 25+ years continuous residency ✅
├─ Same neighborhood/area
├─ Still living there (current resident)
├─ Verified proof of residency
└─ Community recognition

Proof Needed (3+ spanning 25 years):
├─ Property deed/tax records
├─ Utility bills (25+ years)
├─ Voter registration history
├─ Driver's license records
├─ School records (if applicable)
└─ Community attestations (3+ residents)
```

### **Special Powers:**

**1. Event Curation**
```
Can review and advise on local events:
├─ Recommend or raise concerns
├─ Provide historical context
├─ Suggest improvements
└─ Community fit assessment (0-1 score)
```

**2. Advisory Board**
```
Automatic membership in neighborhood board:
├─ Review event trends
├─ Community guideline input
├─ Business verification help
├─ Dispute resolution
└─ Preserve neighborhood character
```

**3. Event Priority**
```
Events they endorse get visibility boost:
├─ 1.5x relevance score
├─ Special "Golden Expert Endorsed" badge
├─ Featured in local discovery
└─ Increased community trust
```

**4. Community Guide**
```
Featured as local expert:
├─ Appear in area discovery
├─ Users can ask questions
├─ Mentorship opportunities
└─ Cultural preservation role
```

### **Real Examples:**

**Maria Rodriguez - Williamsburg, Brooklyn**
```
🏅 Golden Local Expert

Residency:
├─ 32 years in Williamsburg (1992-present)
├─ Owns Maria's Cafe (28 years)
├─ Property owner since 1995
├─ Raised 3 children here
└─ Former neighborhood association VP

Verification:
├─ Property deed ✅
├─ Business license (28 years) ✅
├─ Voter registration (continuous) ✅
├─ 12 community attestations ✅

Advisory Work:
├─ Reviewed 47 events
├─ 31 strong recommendations
├─ 8 concerns raised (all addressed)
├─ Trusted by 890 residents

Specializes In:
├─ Coffee shops (owns one)
├─ Family-friendly spots
├─ Neighborhood history
└─ Community character

Profile Quote:
"I've watched Williamsburg transform over 32 years.
Change is inevitable, but I help preserve what makes
our neighborhood special and ensure new events respect
our community's character."

Event Review Example:
Event: "Late Night Electronic Music Festival"
├─ Recommendation: Not Recommended
├─ Reasoning: "Residential area, families, elderly.
│   Similar event in 1998 caused lasting friction."
├─ Suggestion: "Move to industrial zone 3 blocks south"
├─ Community Fit: 0.2 / 1.0
└─ Impact: Event organizer moved location, success!
```

**James Chen - Lincoln Park, Chicago**
```
🏅 Golden Local Expert

Residency:
├─ 28 years in Lincoln Park (1996-present)
├─ Same house since 1998
├─ Children attended local schools (20 years)
└─ Former neighborhood association president

Verification:
├─ Property tax records (26 years) ✅
├─ School records (1998-2018) ✅
├─ Voter registration ✅
├─ 8 community attestations ✅

Advisory Focus:
├─ Art & culture events
├─ Music venue history
├─ Restaurant evolution
└─ Development impact

Contributions:
├─ Verified 15 historic businesses
├─ Provided context for 60+ events
├─ Resolved 3 community disputes
├─ Mentored 12 new event hosts

Historical Knowledge:
"This area had 3 jazz clubs, now just 1. Let's not
lose the last one. Events should honor that musical
heritage."
```

### **Golden + Other Expertise:**

**Combination 1: Golden + Low Activity**
```
Golden Local Expert: 30 years ✅
Spot visits: 8 logged
Exploration score: 0.30
Total: 0.30

Can:
✅ Review events (historical context)
✅ Serve on advisory board
✅ Provide community guidance
Cannot:
❌ Host events (needs 0.60 City-level)

Role: Advisor, not host
Value: Historical wisdom, community fit assessment
```

**Combination 2: Golden + Professional**
```
Golden Local Expert: 28 years ✅
Restaurant owner: Verified
Spot visits: 15
Professional score: 0.85
Total: 0.62 ✅ City-level

Can:
✅ Host events (City-level reached)
✅ Review events (Golden status)
✅ Advisory board (Golden status)
✅ Verify businesses

Role: Host AND Advisor
Value: Perfect combination of both authority types
```

**Combination 3: Golden + High Exploration**
```
Golden Local Expert: 32 years ✅
Spot visits: 55 (highly active)
Reviews: 45 (4.7★ avg)
Exploration score: 0.88
Total: 0.78 ✅ State-level

Can:
✅ Host events (State-level)
✅ Review events (Golden status)
✅ Advisory board (Golden status)
✅ Regional influence

Role: Ultimate Local Authority
Value: Deep residency + active exploration = ideal
```

### **UI Display:**

**Profile Badge:**
```
┌────────────────────────────────────────┐
│  Maria Rodriguez                       │
│  🏅 Golden Local Expert                │
│  32 years in Williamsburg, Brooklyn    │
├────────────────────────────────────────┤
│  "Keeper of neighborhood history and   │
│   community character."                │
│                                        │
│  Advisory Board Member                 │
│  47 events reviewed                    │
│  890 community followers               │
│                                        │
│  [Follow] [Ask Question] [View Events] │
└────────────────────────────────────────┘
```

**Event Endorsement:**
```
┌────────────────────────────────────────┐
│  Coffee Walk Through Williamsburg      │
│  by @sarah_coffee                      │
├────────────────────────────────────────┤
│                                        │
│  🏅 Endorsed by Golden Local Expert    │
│  Maria Rodriguez (32 years resident)   │
│                                        │
│  "Sarah's tour perfectly captures our  │
│   neighborhood's coffee culture and    │
│   respects community character."       │
│                                        │
│  Community Fit: ⭐⭐⭐⭐⭐ (5/5)         │
│                                        │
│  [Register] [View Details]             │
└────────────────────────────────────────┘
```

**Discovery Feature:**
```
┌────────────────────────────────────────┐
│  🏅 Golden Local Experts               │
│  in Williamsburg                       │
├────────────────────────────────────────┤
│                                        │
│  Meet the keepers of local knowledge:  │
│                                        │
│  Maria Rodriguez (32 yrs)              │
│  Coffee, family spots, history         │
│  [Follow]                              │
│                                        │
│  James Thompson (27 yrs)               │
│  Art galleries, music venues           │
│  [Follow]                              │
│                                        │
│  Sophie Chen (40 yrs)                  │
│  Restaurants, hidden gems              │
│  [Follow]                              │
│                                        │
│  💡 These residents know the area's    │
│     history and culture deeply         │
│                                        │
└────────────────────────────────────────┘
```

### **Benefits:**

**For Community:**
- ✅ Preserves neighborhood character
- ✅ Historical context for changes
- ✅ Quality control for events
- ✅ Cultural continuity
- ✅ Welcoming but authentic

**For Event Hosts:**
- ✅ Expert feedback before launch
- ✅ Community fit assessment
- ✅ Historical context
- ✅ Endorsement boosts visibility
- ✅ Learn from long-term wisdom

**For Golden Experts:**
- ✅ Recognition for lifetime commitment
- ✅ Voice in community changes
- ✅ Preserve what they love
- ✅ Mentor newcomers
- ✅ Legacy beyond themselves

**For SPOTS:**
- ✅ Community-driven quality control
- ✅ Authentic local curation
- ✅ Cultural preservation
- ✅ Reduced admin burden
- ✅ Trust and authenticity

---

## ✅ Summary

### **Professional Expertise:**

**Who Qualifies:**
- Chefs, baristas, sommeliers, bartenders
- Writers, critics, journalists, authors
- Teachers, professors, coaches, mentors
- Consultants, advisors, specialists
- Curators, gallery owners, museum staff
- Doctors, nurses, therapists, nutritionists

**Verification Required:**
- LinkedIn cross-reference, OR
- Employer letter, OR
- Professional license/certification, OR
- Portfolio review, OR
- Peer endorsements (3+)

**Impact:**
- 25% weight in expertise calculation
- Can reach expert status with fewer visits
- Credibility boost for hosting events

### **Local Expertise:**

**How It Works:**
- Expertise is location-specific
- Geographic scopes automatically calculated
- Can host events where you have City-level
- Quality concentration > sheer quantity

**Examples:**
- Brooklyn expert (45 visits) → Can host in Brooklyn
- Multi-city expert → Can host in multiple cities
- Neighborhood specialist → Deep local knowledge

**Impact:**
- Authentic local hosting
- Prevents tourist-led events
- Rewards concentrated knowledge

### **Combined Power:**

```
Best Expert = Professional + Local + Active

Example:
├─ Chef working in neighborhood ✅
├─ Lives there, knows it deeply ✅
├─ Hosts events regularly ✅
└─ Perfect combination
```

### **Golden Local Expert (NEW):**

**Requirements:**
- 25+ continuous years in one location
- Verified proof of residency
- Still living there (current resident)
- Community recognition

**Powers:**
- Event curation and review
- Neighborhood advisory board
- Event visibility boost (1.5x)
- Community guide designation
- Historical context provider

**Impact:**
- Preserves neighborhood character
- Quality control for events
- Cultural continuity
- Mentorship opportunities
- Legacy recognition

**Status:** 🟢 Complete system design  
**Timeline:** Included in 3.5-week plan  
**Files:** All integrated into Dynamic Expertise Thresholds Plan

---

**These features ensure SPOTS recognizes ALL forms of genuine expertise—from visitors to professionals to lifelong residents—while maintaining quality through geographic authenticity and community wisdom.** 👨‍🍳🌍🏅✨

---

**Last Updated:** November 21, 2025  
**Related Plans:**
- Dynamic Expertise Thresholds Plan (main implementation)
- Expertise System Enhancements (auto check-ins + multi-path)
- Vibe Matching & Expertise Quality (partnership matching)


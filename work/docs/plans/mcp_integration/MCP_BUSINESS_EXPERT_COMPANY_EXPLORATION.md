# MCP Integration for Businesses, Companies & Experts

**Date:** November 21, 2025  
**Status:** Exploration & Feasibility Analysis  
**Purpose:** Evaluate MCP server integration for business accounts, expert users, and company sponsors

---

## 🎯 **OVERVIEW**

This document explores extending the MCP server beyond admin functionality to serve:
1. **Business Accounts** - Venues, restaurants, shops that partner with experts
2. **Expert Users** - Users with expertise who host events and connect with businesses
3. **Company Sponsors** - Brands (wine, oil, etc.) that sponsor events

**Key Question:** Can MCP provide natural language interfaces for these stakeholders to manage partnerships, events, revenue, and connections?

---

## 💼 **USE CASES BY STAKEHOLDER**

### **1. Business Accounts (Venues, Restaurants, Shops)**

#### **Partnership Management**
- "Show me all experts who want to partner with my venue"
- "What partnership requests are pending?"
- "Find experts in coffee who match my vibe preferences"
- "Show me my connected experts and their expertise levels"

#### **Event Management**
- "What events are happening at my venue this month?"
- "Show me upcoming events I'm partnered with"
- "What's the revenue from last month's events?"
- "Which events need my approval?"

#### **Revenue & Analytics**
- "What's my total revenue this quarter?"
- "Show me revenue breakdown by event"
- "What's my average revenue per event?"
- "Show me revenue trends over the last 6 months"

#### **Expert Discovery**
- "Find experts in Brooklyn who could host wine tastings"
- "Show me experts with city-level expertise in food"
- "Find experts who match my business preferences"
- "What experts are available for partnerships?"

#### **Business Operations**
- "Update my business preferences for expert matching"
- "Show me my verification status"
- "What's my business profile completion?"
- "Show me pending invitations to join events"

---

### **2. Expert Users**

#### **Business Discovery**
- "Find businesses in Brooklyn looking for coffee experts"
- "Show me businesses that match my vibe"
- "What businesses are accepting partnership requests?"
- "Find venues that could host my workshop"

#### **Event Management**
- "Show me my upcoming events"
- "What events need my attention?"
- "Show me events I'm partnered with businesses on"
- "What's my event schedule for next month?"

#### **Revenue & Earnings**
- "What's my total earnings this month?"
- "Show me revenue breakdown by event"
- "What's my average earnings per event?"
- "Show me my referral bonuses"

#### **Partnership Management**
- "Show me my connected businesses"
- "What partnership requests are pending?"
- "Show me businesses I've invited to SPOTS"
- "What's my partnership success rate?"

#### **Expertise & Growth**
- "What's my expertise level in coffee?"
- "Show me my expertise progress across categories"
- "What expertise do I need to reach city-level?"
- "Show me my expertise network"

---

### **3. Company Sponsors (Wine, Oil, Brands)**

#### **Event Discovery**
- "Find events in Brooklyn that match my brand"
- "Show me events looking for sponsors"
- "What events have high vibe compatibility with my brand?"
- "Find food events that could feature my products"

#### **Sponsorship Management**
- "Show me my active sponsorships"
- "What sponsorship requests are pending?"
- "Show me my sponsorship history"
- "What events have I sponsored this quarter?"

#### **ROI & Analytics**
- "What's my ROI on sponsorships this year?"
- "Show me engagement metrics for my sponsored events"
- "What's the average attendance at events I sponsor?"
- "Show me brand visibility metrics"

#### **Brand Matching**
- "Find events that match my brand values"
- "Show me experts who align with my brand"
- "What businesses could I partner with?"
- "Find high-engagement events in my target markets"

---

## 🏗️ **TECHNICAL FEASIBILITY**

### **✅ STRENGTHS**

1. **Existing Infrastructure**
   - ✅ Business account system (`BusinessAccount` model)
   - ✅ Expert matching services (`BusinessExpertMatchingService`)
   - ✅ Event partnership system
   - ✅ Revenue tracking (Stripe integration)
   - ✅ Analytics services (`BehaviorAnalysisService`, `PredictiveAnalysisService`)

2. **Data Access Patterns**
   - ✅ Business accounts have preferences (`BusinessExpertPreferences`)
   - ✅ Expert profiles with expertise levels
   - ✅ Event data with partnerships
   - ✅ Revenue data from Stripe

3. **Authentication Ready**
   - ✅ Business account authentication
   - ✅ User authentication (for experts)
   - ✅ Role-based access control

4. **API Foundation**
   - ✅ Supabase backend
   - ✅ Data access interfaces
   - ✅ Service layer architecture

---

### **⚠️ CHALLENGES**

1. **Multi-Stakeholder Complexity**
   - ⚠️ Different access levels (business, expert, company)
   - ⚠️ **Solution**: Role-based MCP tools, separate namespaces
   - ⚠️ **Impact**: More complex tool organization

2. **Data Privacy**
   - ⚠️ Business data vs. expert data vs. company data
   - ⚠️ **Solution**: Strict data filtering, role-based access
   - ⚠️ **Impact**: Additional security layer

3. **Revenue Data Sensitivity**
   - ⚠️ Financial data requires extra security
   - ⚠️ **Solution**: Encrypted communication, audit logging
   - ⚠️ **Impact**: Enhanced security requirements

4. **Real-Time Updates**
   - ⚠️ Partnerships, events, revenue change frequently
   - ⚠️ **Solution**: Caching with TTL, real-time refresh options
   - ⚠️ **Impact**: Performance considerations

---

## 🚀 **IMPLEMENTATION APPROACH**

### **Phase 1: Business Account MCP Tools**

**Goal:** Basic business account functionality via MCP

**Tools:**
1. `business_find_experts` - Find experts matching business preferences
2. `business_view_partnerships` - View connected and pending partnerships
3. `business_view_events` - View events at business venue
4. `business_view_revenue` - View revenue analytics
5. `business_update_preferences` - Update expert matching preferences

**UI Resources:**
- `ui://business/expert-matching` - Expert discovery interface
- `ui://business/partnerships` - Partnership management dashboard
- `ui://business/revenue` - Revenue analytics dashboard
- `ui://business/events` - Event calendar and management

**Timeline:** 5-7 days

---

### **Phase 2: Expert User MCP Tools**

**Goal:** Expert functionality via MCP

**Tools:**
1. `expert_find_businesses` - Find businesses looking for experts
2. `expert_view_partnerships` - View business partnerships
3. `expert_view_events` - View expert's events
4. `expert_view_earnings` - View earnings and revenue
5. `expert_view_expertise` - View expertise progress

**UI Resources:**
- `ui://expert/business-discovery` - Business discovery interface
- `ui://expert/partnerships` - Partnership management
- `ui://expert/earnings` - Earnings dashboard
- `ui://expert/expertise` - Expertise progress visualization

**Timeline:** 5-7 days

---

### **Phase 3: Company Sponsor MCP Tools**

**Goal:** Company sponsor functionality via MCP

**Tools:**
1. `company_find_events` - Find events matching brand
2. `company_view_sponsorships` - View active sponsorships
3. `company_view_roi` - View sponsorship ROI analytics
4. `company_propose_sponsorship` - Propose sponsorship to event
5. `company_view_brand_matching` - View brand compatibility scores

**UI Resources:**
- `ui://company/event-discovery` - Event discovery interface
- `ui://company/sponsorships` - Sponsorship management
- `ui://company/roi` - ROI analytics dashboard
- `ui://company/brand-matching` - Brand matching visualization

**Timeline:** 5-7 days

---

## 📋 **TOOL DEFINITIONS**

### **Business Account Tools**

```typescript
// tools/business_tools.ts
export const businessTools = [
  {
    name: "business_find_experts",
    description: "Find experts matching business preferences. Returns experts with expertise levels, compatibility scores, and partnership history.",
    inputSchema: {
      type: "object",
      properties: {
        businessId: { type: "string", required: true },
        category: { type: "string", description: "Expertise category filter" },
        location: { type: "string", description: "Location filter" },
        minExpertLevel: { type: "number", description: "Minimum expertise level (0-5)" }
      }
    },
    _meta: {
      "ui/resourceUri": "ui://business/expert-matching"
    }
  },
  {
    name: "business_view_partnerships",
    description: "View all partnerships (connected and pending) for a business account. Shows expert details, partnership status, and event history.",
    inputSchema: {
      type: "object",
      properties: {
        businessId: { type: "string", required: true },
        status: { type: "string", enum: ["connected", "pending", "all"] }
      }
    },
    _meta: {
      "ui/resourceUri": "ui://business/partnerships"
    }
  },
  {
    name: "business_view_revenue",
    description: "View revenue analytics for business account. Shows total revenue, revenue by event, trends, and breakdowns.",
    inputSchema: {
      type: "object",
      properties: {
        businessId: { type: "string", required: true },
        period: { type: "string", enum: ["week", "month", "quarter", "year"] },
        startDate: { type: "string", format: "date" },
        endDate: { type: "string", format: "date" }
      }
    },
    _meta: {
      "ui/resourceUri": "ui://business/revenue"
    }
  },
  {
    name: "business_view_events",
    description: "View events at business venue. Shows upcoming events, past events, and event details.",
    inputSchema: {
      type: "object",
      properties: {
        businessId: { type: "string", required: true },
        status: { type: "string", enum: ["upcoming", "past", "all"] },
        startDate: { type: "string", format: "date" },
        endDate: { type: "string", format: "date" }
      }
    },
    _meta: {
      "ui/resourceUri": "ui://business/events"
    }
  },
  {
    name: "business_update_preferences",
    description: "Update business expert matching preferences. Changes what types of experts the business wants to connect with.",
    inputSchema: {
      type: "object",
      properties: {
        businessId: { type: "string", required: true },
        requiredExpertise: { type: "array", items: { type: "string" } },
        preferredLocation: { type: "string" },
        minExpertLevel: { type: "number" }
      }
    }
  }
]
```

---

### **Expert User Tools**

```typescript
// tools/expert_tools.ts
export const expertTools = [
  {
    name: "expert_find_businesses",
    description: "Find businesses looking for experts. Returns businesses with compatibility scores, location, and partnership opportunities.",
    inputSchema: {
      type: "object",
      properties: {
        expertId: { type: "string", required: true },
        category: { type: "string", description: "Expertise category" },
        location: { type: "string", description: "Location filter" },
        minCompatibility: { type: "number", description: "Minimum vibe compatibility (0-1)" }
      }
    },
    _meta: {
      "ui/resourceUri": "ui://expert/business-discovery"
    }
  },
  {
    name: "expert_view_partnerships",
    description: "View all business partnerships for expert. Shows connected businesses, pending requests, and partnership history.",
    inputSchema: {
      type: "object",
      properties: {
        expertId: { type: "string", required: true },
        status: { type: "string", enum: ["connected", "pending", "all"] }
      }
    },
    _meta: {
      "ui/resourceUri": "ui://expert/partnerships"
    }
  },
  {
    name: "expert_view_earnings",
    description: "View earnings and revenue for expert. Shows total earnings, earnings by event, referral bonuses, and trends.",
    inputSchema: {
      type: "object",
      properties: {
        expertId: { type: "string", required: true },
        period: { type: "string", enum: ["week", "month", "quarter", "year"] },
        startDate: { type: "string", format: "date" },
        endDate: { type: "string", format: "date" }
      }
    },
    _meta: {
      "ui/resourceUri": "ui://expert/earnings"
    }
  },
  {
    name: "expert_view_events",
    description: "View expert's events. Shows upcoming events, past events, and event details including partnerships.",
    inputSchema: {
      type: "object",
      properties: {
        expertId: { type: "string", required: true },
        status: { type: "string", enum: ["upcoming", "past", "all"] }
      }
    },
    _meta: {
      "ui/resourceUri": "ui://expert/events"
    }
  },
  {
    name: "expert_view_expertise",
    description: "View expertise progress for expert. Shows expertise levels by category, progress toward next level, and expertise network.",
    inputSchema: {
      type: "object",
      properties: {
        expertId: { type: "string", required: true },
        category: { type: "string", description: "Specific category to view" }
      }
    },
    _meta: {
      "ui/resourceUri": "ui://expert/expertise"
    }
  }
]
```

---

### **Company Sponsor Tools**

```typescript
// tools/company_tools.ts
export const companyTools = [
  {
    name: "company_find_events",
    description: "Find events matching company brand. Returns events with vibe compatibility scores, location, and sponsorship opportunities.",
    inputSchema: {
      type: "object",
      properties: {
        companyId: { type: "string", required: true },
        location: { type: "string", description: "Location filter" },
        category: { type: "string", description: "Event category" },
        minCompatibility: { type: "number", description: "Minimum vibe compatibility (0-1)" }
      }
    },
    _meta: {
      "ui/resourceUri": "ui://company/event-discovery"
    }
  },
  {
    name: "company_view_sponsorships",
    description: "View all sponsorships for company. Shows active sponsorships, pending requests, and sponsorship history.",
    inputSchema: {
      type: "object",
      properties: {
        companyId: { type: "string", required: true },
        status: { type: "string", enum: ["active", "pending", "all"] }
      }
    },
    _meta: {
      "ui/resourceUri": "ui://company/sponsorships"
    }
  },
  {
    name: "company_view_roi",
    description: "View ROI analytics for company sponsorships. Shows ROI by event, engagement metrics, and brand visibility.",
    inputSchema: {
      type: "object",
      properties: {
        companyId: { type: "string", required: true },
        period: { type: "string", enum: ["month", "quarter", "year"] },
        startDate: { type: "string", format: "date" },
        endDate: { type: "string", format: "date" }
      }
    },
    _meta: {
      "ui/resourceUri": "ui://company/roi"
    }
  },
  {
    name: "company_propose_sponsorship",
    description: "Propose sponsorship to an event. Creates sponsorship request with terms and contribution details.",
    inputSchema: {
      type: "object",
      properties: {
        companyId: { type: "string", required: true },
        eventId: { type: "string", required: true },
        contributionType: { type: "string", enum: ["cash", "product", "both"] },
        amount: { type: "number", description: "Cash contribution amount" },
        productDetails: { type: "object", description: "Product contribution details" }
      }
    }
  },
  {
    name: "company_view_brand_matching",
    description: "View brand compatibility scores with events and experts. Shows vibe matching and brand alignment metrics.",
    inputSchema: {
      type: "object",
      properties: {
        companyId: { type: "string", required: true },
        entityType: { type: "string", enum: ["events", "experts", "businesses"] }
      }
    },
    _meta: {
      "ui/resourceUri": "ui://company/brand-matching"
    }
  }
]
```

---

## 🎨 **UI RESOURCE EXAMPLES**

### **1. Business Expert Matching Dashboard**

**Tool:** `business_find_experts`  
**UI Resource:** `ui://business/expert-matching`

**Features:**
- Expert search interface with filters
- Compatibility scores visualization
- Expert profiles with expertise levels
- Partnership history indicators
- "Request Partnership" actions
- Map view of expert locations

**Visualization:**
- Compatibility heatmap
- Expertise level indicators
- Partnership success rate charts
- Location-based expert distribution

---

### **2. Expert Business Discovery**

**Tool:** `expert_find_businesses`  
**UI Resource:** `ui://expert/business-discovery`

**Features:**
- Business search with vibe matching
- Compatibility scores
- Business profiles with preferences
- Partnership opportunities
- "Request Partnership" actions
- Location-based business map

**Visualization:**
- Vibe compatibility scores
- Business preference alignment
- Partnership opportunity indicators
- Geographic business distribution

---

### **3. Revenue Analytics Dashboard**

**Tool:** `business_view_revenue` / `expert_view_earnings`  
**UI Resource:** `ui://business/revenue` / `ui://expert/earnings`

**Features:**
- Revenue/earnings charts (line, bar, pie)
- Period selection (week, month, quarter, year)
- Event-by-event breakdown
- Trend analysis
- Export functionality

**Visualization:**
- Revenue over time (line chart)
- Revenue by event (bar chart)
- Revenue breakdown by category (pie chart)
- Comparison periods
- Growth indicators

---

### **4. Partnership Management**

**Tool:** `business_view_partnerships` / `expert_view_partnerships`  
**UI Resource:** `ui://business/partnerships` / `ui://expert/partnerships`

**Features:**
- Connected partnerships list
- Pending requests
- Partnership history
- Event collaboration timeline
- Partnership success metrics

**Visualization:**
- Partnership status indicators
- Event collaboration timeline
- Success rate metrics
- Partnership network graph

---

### **5. Company Event Discovery**

**Tool:** `company_find_events`  
**UI Resource:** `ui://company/event-discovery`

**Features:**
- Event search with brand matching
- Vibe compatibility scores
- Event details and organizers
- Sponsorship opportunities
- "Propose Sponsorship" actions
- Calendar view

**Visualization:**
- Brand compatibility heatmap
- Event location map
- Sponsorship opportunity indicators
- ROI potential estimates

---

## 🔐 **SECURITY & AUTHENTICATION**

### **Authentication Flow**

```
1. User authenticates with AI assistant (ChatGPT/Claude)
2. User provides SPOTS credentials (business/expert/company)
3. MCP server validates credentials
4. MCP server checks role and permissions
5. Tools filtered by role (business tools, expert tools, company tools)
6. Data filtered to user's own data only
7. Audit log entry created
```

### **Role-Based Access Control**

**Business Accounts:**
- ✅ Access to own business data
- ✅ View own partnerships
- ✅ View own revenue
- ✅ Update own preferences
- ❌ Cannot access other businesses' data
- ❌ Cannot access expert personal data (only expertise/public data)

**Expert Users:**
- ✅ Access to own expert data
- ✅ View own partnerships
- ✅ View own earnings
- ✅ View own expertise progress
- ❌ Cannot access other experts' personal data
- ❌ Cannot access business financial data (only public info)

**Company Sponsors:**
- ✅ Access to own company data
- ✅ View own sponsorships
- ✅ View own ROI analytics
- ✅ Propose sponsorships
- ❌ Cannot access other companies' data
- ❌ Cannot access event financial details (only public info)

### **Data Privacy**

**Business Data:**
- ✅ Business name, location, categories (public)
- ✅ Expert preferences (private to business)
- ✅ Revenue data (private to business)
- ✅ Partnership details (private to business)

**Expert Data:**
- ✅ Expertise levels, categories (public)
- ✅ Earnings data (private to expert)
- ✅ Partnership details (private to expert)
- ❌ Personal information (name, email) - not exposed via MCP

**Company Data:**
- ✅ Company name, brand info (public)
- ✅ Sponsorship data (private to company)
- ✅ ROI analytics (private to company)

---

## 📊 **BENEFITS ANALYSIS**

### **For Businesses**

1. **Efficiency**
   - Quick expert discovery via natural language
   - Instant partnership management
   - Revenue insights without opening app

2. **Better Decision Making**
   - Visual compatibility scores
   - Partnership success metrics
   - Revenue trend analysis

3. **Accessibility**
   - Access from any MCP-compatible AI assistant
   - No need for separate business dashboard app
   - Works from desktop, mobile, anywhere

---

### **For Experts**

1. **Business Discovery**
   - Natural language business search
   - Vibe matching visualization
   - Partnership opportunity discovery

2. **Earnings Tracking**
   - Quick earnings queries
   - Revenue breakdowns
   - Trend analysis

3. **Expertise Growth**
   - Progress visualization
   - Level advancement tracking
   - Network insights

---

### **For Companies**

1. **Event Discovery**
   - Brand-matched event search
   - Compatibility visualization
   - Sponsorship opportunity identification

2. **ROI Tracking**
   - Sponsorship ROI analytics
   - Engagement metrics
   - Brand visibility tracking

3. **Strategic Planning**
   - Market analysis
   - Event trend identification
   - Brand alignment insights

---

## ⚠️ **CONSIDERATIONS**

### **Philosophy Alignment**

**Question:** Does MCP for businesses/experts/companies align with "Doors" philosophy?

**Analysis:**
- ✅ **Business/Expert/Company tools**: These are operational tools, not user "doors"
- ✅ **Separate from user experience**: MCP is for stakeholders managing their business/expertise, not replacing user discovery
- ✅ **Enhances platform**: Makes it easier for businesses/experts/companies to participate
- ✅ **Preserves user "doors"**: User mobile app remains the primary "doors" experience

**Conclusion:** MCP for stakeholders is acceptable - it's operational tooling, not a replacement for user experience.

---

### **Architecture Alignment**

**Question:** Does MCP conflict with offline-first architecture?

**Analysis:**
- ✅ **Stakeholder tools**: Businesses/experts/companies typically work online
- ✅ **Cloud-based**: Stakeholder MCP tools can be cloud-only
- ✅ **Separate concern**: MCP server is separate from mobile app
- ✅ **No impact on users**: Mobile app remains offline-first

**Conclusion:** MCP for stakeholders is cloud-based operational tooling, doesn't conflict with offline-first mobile app.

---

## 🎯 **RECOMMENDATION**

### **✅ PROCEED WITH STAKEHOLDER MCP SERVER**

**Rationale:**
1. **Clear Use Cases**: Natural language interfaces for businesses/experts/companies
2. **Existing Infrastructure**: Business accounts, expert matching, event partnerships ready
3. **High Value**: Efficiency gains for key stakeholders
4. **Low Risk**: Stakeholder-only, doesn't affect user experience
5. **Future-Proof**: Standardized protocol, extensible

**Implementation Priority:**
1. **Phase 1** (5-7 days): Business account MCP tools
2. **Phase 2** (5-7 days): Expert user MCP tools
3. **Phase 3** (5-7 days): Company sponsor MCP tools

**Total Timeline:** 15-21 days for full stakeholder implementation

**Combined with Admin MCP:** 30-43 days for complete MCP server (admin + stakeholders)

---

## 📚 **INTEGRATION WITH ADMIN MCP**

### **Unified MCP Server Architecture**

```
MCP Server (SPOTS)
├── Admin Tools (God-Mode Admin)
│   ├── System health
│   ├── User management
│   ├── Business verification
│   └── Analytics
│
├── Business Tools (Business Accounts)
│   ├── Expert discovery
│   ├── Partnership management
│   ├── Revenue analytics
│   └── Event management
│
├── Expert Tools (Expert Users)
│   ├── Business discovery
│   ├── Partnership management
│   ├── Earnings tracking
│   └── Expertise progress
│
└── Company Tools (Sponsors)
    ├── Event discovery
    ├── Sponsorship management
    ├── ROI analytics
    └── Brand matching
```

**Benefits:**
- Single MCP server endpoint
- Role-based tool filtering
- Unified authentication
- Shared UI components
- Consistent patterns

---

## 🚀 **NEXT STEPS**

1. **Review Admin MCP Exploration**
   - Understand admin MCP implementation
   - Identify shared patterns

2. **Prototype Business Tools**
   - Implement 2-3 business tools
   - Create one UI resource
   - Test with business account

3. **Validate Use Cases**
   - Test with real business users
   - Gather feedback
   - Refine tool definitions

4. **Expand to Experts & Companies**
   - Implement expert tools
   - Implement company tools
   - Build UI resources

5. **Production Deployment**
   - Deploy unified MCP server
   - Document for stakeholders
   - Provide onboarding

---

## 📝 **NOTES**

- **Stakeholder-Only**: MCP server is for businesses/experts/companies, not end users
- **Cloud-Based**: Requires network connectivity (acceptable for stakeholder tools)
- **Separate Codebase**: HTML/JS UI components, separate from Flutter app
- **Privacy-First**: Strict data filtering, role-based access
- **Security-Critical**: Financial data requires enhanced security
- **Future Expansion**: Could add more tools based on stakeholder needs

---

**Status:** Ready for implementation  
**Priority:** Medium-High (stakeholder efficiency enhancement)  
**Dependencies:** Admin MCP server (can build in parallel)  
**Risk:** Low (stakeholder-only, doesn't affect user experience)


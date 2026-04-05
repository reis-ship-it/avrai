# Itinerary Calendar Lists Implementation Plan

**Date:** December 15, 2025  
**Status:** 📋 Ready  
**Priority:** HIGH  
**Timeline:** 3-4 weeks  
**Feature Area:** Lists Enhancement

---

## 🚪 **Doors Philosophy Alignment**

### **What Doors Does This Help Users Open?**

**This feature opens doors to:**
- **Trip Planning & Organization** - Users can plan trips and visualize their journey through time
- **Experience Discovery** - Calendar visualization helps users discover spots they want to visit on specific days
- **Community Connection** - Shared itineraries help users find others planning similar trips
- **Life Enrichment** - Organized trip planning leads to better experiences and more meaningful travel

### **When Are Users Ready for These Doors?**

**Users are ready when:**
- They want to plan trips (vacations, weekend getaways, business travel)
- They need to organize spots by time/date
- They want to visualize their journey across days/nights/weeks/months
- They're planning events or activities with specific dates

**The feature shows doors:**
- When users create lists (option to add calendar element)
- When viewing lists (calendar view option)
- When planning trips (suggested feature)
- When organizing spots by time

### **Is This Being a Good Key?**

**Yes, because:**
- ✅ **Respects User Autonomy** - Users choose when to use calendar features (optional enhancement)
- ✅ **Enhances Real World Experience** - Helps users plan real trips, not just digital organization
- ✅ **Opens Doors to Experiences** - Visualizing trips helps users discover spots they might visit
- ✅ **Community Connection** - Shared itineraries help users find travel companions or local guides
- ✅ **No Gamification** - Pure utility feature, not badge-chasing

### **Is the AI Learning With the User?**

**Yes, because:**
- AI learns which spots users plan to visit (trip planning patterns)
- AI learns travel preferences (destinations, trip duration, travel style)
- AI learns timing preferences (when users like to travel, how far in advance they plan)
- AI can suggest spots for specific dates based on user's itinerary
- AI can connect users planning similar trips (AI2AI connections)

---

## 📋 **Executive Summary**

This plan adds calendar/time-based visualization to the existing lists system, enabling users to create itinerary lists for trips with visualizations by days/nights, weeks, or months. This enhances the lists feature to support trip planning while maintaining all existing list functionality.

### **Key Features:**
- Calendar element for lists (optional enhancement)
- Multiple visualization modes (days/nights, weeks, months)
- Trip itinerary support
- Time-based spot organization
- Calendar integration (export to external calendars)

### **Philosophy Alignment:**
- ✅ Opens doors to trip planning and experience discovery
- ✅ Enhances real-world travel experiences
- ✅ Enables community connection through shared itineraries
- ✅ AI learns travel patterns and preferences

---

## 🎯 **Goals & Objectives**

### **Primary Goals:**
1. Enable users to create lists with calendar/time elements
2. Provide multiple visualization modes (days/nights, weeks, months)
3. Support trip itinerary planning
4. Maintain backward compatibility with existing lists

### **Secondary Goals:**
1. Export itineraries to external calendars
2. Share itineraries with others
3. AI suggestions for spots based on itinerary dates
4. Integration with events system (add events to itineraries)

---

## 🏗️ **Architecture Overview**

### **Current State:**
- ✅ Lists system exists (`SpotList` model)
- ✅ Lists have spots, categories, metadata
- ✅ Lists UI exists (create, view, edit, delete)
- ✅ Calendar integration exists for events (external calendar export)

### **What's Missing:**
- ❌ Calendar/time elements in lists
- ❌ Itinerary-specific list type
- ❌ Time-based visualization
- ❌ Date assignment for spots in lists
- ❌ Trip duration tracking

### **Design Approach:**
- **Extend existing `SpotList` model** (add optional calendar fields)
- **Create new `ItineraryList` type** (specialized list with calendar features)
- **Add calendar visualization widgets** (days/nights, weeks, months views)
- **Maintain backward compatibility** (existing lists work without calendar features)

---

## 📐 **Technical Specifications**

### **Data Models**

#### **1. Extended SpotList Model**

**File:** `lib/core/models/list.dart`

**New Fields (Optional):**
```dart
class SpotList {
  // ... existing fields ...
  
  // Calendar/Itinerary fields (optional)
  final bool isItinerary;              // Is this an itinerary list?
  final DateTime? startDate;           // Trip start date
  final DateTime? endDate;             // Trip end date
  final ItineraryViewMode? viewMode;   // Preferred view mode
  final Map<String, DateTime>? spotDates; // Spot ID -> Date assignment
  final Map<String, String>? spotNotes;    // Spot ID -> Date-specific notes
}
```

**New Enum:**
```dart
enum ItineraryViewMode {
  daysNights,  // Days and nights view
  weeks,       // Weekly view
  months,      // Monthly view
}
```

#### **2. ItinerarySpotEntry Model**

**File:** `lib/core/models/itinerary_spot_entry.dart` (NEW)

```dart
class ItinerarySpotEntry {
  final String spotId;
  final DateTime date;
  final TimeOfDay? time;           // Optional time
  final String? note;               // Date-specific note
  final int? dayNumber;             // Day number in trip (1, 2, 3...)
  final bool isNight;               // Is this a night activity?
  
  const ItinerarySpotEntry({
    required this.spotId,
    required this.date,
    this.time,
    this.note,
    this.dayNumber,
    this.isNight = false,
  });
}
```

### **Services**

#### **1. ItineraryService**

**File:** `lib/core/services/itinerary_service.dart` (NEW)

**Purpose:** Manage itinerary-specific logic

**Methods:**
```dart
class ItineraryService {
  // Calculate trip duration
  int calculateTripDuration(DateTime start, DateTime end);
  
  // Get days/nights breakdown
  Map<String, int> getDaysNightsBreakdown(DateTime start, DateTime end);
  
  // Assign spot to date
  Future<void> assignSpotToDate(String listId, String spotId, DateTime date);
  
  // Get spots for specific date
  List<String> getSpotsForDate(String listId, DateTime date);
  
  // Validate itinerary dates
  bool validateItineraryDates(DateTime start, DateTime end);
  
  // Export to calendar format
  Future<String> exportToCalendarFormat(SpotList itinerary);
}
```

#### **2. CalendarExportService**

**File:** `lib/core/services/calendar_export_service.dart` (NEW)

**Purpose:** Export itineraries to external calendars

**Methods:**
```dart
class CalendarExportService {
  // Export to Google Calendar
  Future<void> exportToGoogleCalendar(SpotList itinerary);
  
  // Export to Apple Calendar
  Future<void> exportToAppleCalendar(SpotList itinerary);
  
  // Export to iCal format
  Future<String> exportToICal(SpotList itinerary);
  
  // Generate calendar event for spot
  Map<String, dynamic> generateCalendarEvent(Spot spot, DateTime date, TimeOfDay? time);
}
```

### **UI Components**

#### **1. Itinerary Calendar View Widget**

**File:** `lib/presentation/widgets/lists/itinerary_calendar_view.dart` (NEW)

**Features:**
- Days/nights view (horizontal timeline)
- Weeks view (calendar grid)
- Months view (full calendar)
- Drag-and-drop spot assignment
- Date picker for spot assignment

#### **2. Itinerary List Creation Page**

**File:** `lib/presentation/pages/lists/create_itinerary_page.dart` (NEW)

**Features:**
- Trip name and description
- Start date picker
- End date picker
- View mode selection
- Calendar visualization preview

#### **3. Itinerary Details Page**

**File:** `lib/presentation/pages/lists/itinerary_details_page.dart` (NEW)

**Features:**
- Calendar visualization (switchable modes)
- Spot list by date
- Add spots to specific dates
- Edit date assignments
- Export to calendar
- Share itinerary

#### **4. Date Assignment Dialog**

**File:** `lib/presentation/widgets/lists/date_assignment_dialog.dart` (NEW)

**Features:**
- Date picker
- Time picker (optional)
- Day/night toggle
- Note field
- Save/cancel

---

## 📅 **Implementation Phases**

### **Phase 1: Foundation - Models & Services (Week 1)**

#### **1.1 Extend SpotList Model (Days 1-2)**

**Tasks:**
- Add optional calendar fields to `SpotList` model
- Create `ItinerarySpotEntry` model
- Create `ItineraryViewMode` enum
- Update JSON serialization
- Add migration logic for existing lists
- Write model tests

**Files:**
- `lib/core/models/list.dart` (modify)
- `lib/core/models/itinerary_spot_entry.dart` (new)
- `test/core/models/list_test.dart` (update)
- `test/core/models/itinerary_spot_entry_test.dart` (new)

**Estimated Effort:** 8-10 hours

#### **1.2 Create ItineraryService (Days 3-4)**

**Tasks:**
- Create `ItineraryService` class
- Implement trip duration calculation
- Implement days/nights breakdown
- Implement spot date assignment
- Implement date-based spot retrieval
- Implement date validation
- Write service tests

**Files:**
- `lib/core/services/itinerary_service.dart` (new)
- `test/core/services/itinerary_service_test.dart` (new)

**Estimated Effort:** 8-10 hours

#### **1.3 Create CalendarExportService (Day 5)**

**Tasks:**
- Create `CalendarExportService` class
- Implement Google Calendar export
- Implement Apple Calendar export
- Implement iCal format export
- Implement calendar event generation
- Write service tests

**Files:**
- `lib/core/services/calendar_export_service.dart` (new)
- `test/core/services/calendar_export_service_test.dart` (new)

**Estimated Effort:** 6-8 hours

**Phase 1 Total:** 22-28 hours (3-4 days)

---

### **Phase 2: Repository & Data Layer (Week 2)**

#### **2.1 Update ListsRepository (Days 1-2)**

**Tasks:**
- Add itinerary-specific methods to repository interface
- Update repository implementation
- Add date assignment persistence
- Update local data source
- Update remote data source
- Write repository tests

**Files:**
- `lib/domain/repositories/lists_repository.dart` (modify)
- `lib/data/repositories/lists_repository_impl.dart` (modify)
- `lib/data/datasources/local/lists_sembast_datasource.dart` (modify)
- `lib/data/datasources/remote/lists_remote_datasource.dart` (modify)
- `test/data/repositories/lists_repository_test.dart` (update)

**Estimated Effort:** 10-12 hours

#### **2.2 Database Schema Updates (Days 3-4)**

**Tasks:**
- Update Supabase schema (if using remote)
- Add migration scripts
- Update local database schema
- Test data migration
- Verify backward compatibility

**Files:**
- `supabase/migrations/[timestamp]_add_itinerary_fields.sql` (new)
- Database migration scripts

**Estimated Effort:** 6-8 hours

**Phase 2 Total:** 16-20 hours (2-3 days)

---

### **Phase 3: UI Components (Week 3)**

#### **3.1 Itinerary Calendar View Widget (Days 1-3)**

**Tasks:**
- Create calendar view widget
- Implement days/nights view
- Implement weeks view
- Implement months view
- Add view mode switching
- Add drag-and-drop support
- Write widget tests

**Files:**
- `lib/presentation/widgets/lists/itinerary_calendar_view.dart` (new)
- `test/widget/lists/itinerary_calendar_view_test.dart` (new)

**Estimated Effort:** 16-20 hours

#### **3.2 Itinerary List Creation Page (Days 4-5)**

**Tasks:**
- Create itinerary creation page
- Add date pickers
- Add view mode selection
- Add calendar preview
- Integrate with ListsBloc
- Write page tests

**Files:**
- `lib/presentation/pages/lists/create_itinerary_page.dart` (new)
- `test/pages/lists/create_itinerary_page_test.dart` (new)

**Estimated Effort:** 10-12 hours

#### **3.3 Itinerary Details Page (Days 6-7)**

**Tasks:**
- Create itinerary details page
- Integrate calendar view
- Add spot management by date
- Add export functionality
- Add share functionality
- Write page tests

**Files:**
- `lib/presentation/pages/lists/itinerary_details_page.dart` (new)
- `test/pages/lists/itinerary_details_page_test.dart` (new)

**Estimated Effort:** 14-16 hours

#### **3.4 Date Assignment Dialog (Day 8)**

**Tasks:**
- Create date assignment dialog
- Add date/time pickers
- Add day/night toggle
- Add note field
- Integrate with itinerary service
- Write dialog tests

**Files:**
- `lib/presentation/widgets/lists/date_assignment_dialog.dart` (new)
- `test/widget/lists/date_assignment_dialog_test.dart` (new)

**Estimated Effort:** 6-8 hours

**Phase 3 Total:** 46-56 hours (6-7 days)

---

### **Phase 4: Integration & Polish (Week 4)**

#### **4.1 Update ListsBloc (Days 1-2)**

**Tasks:**
- Add itinerary-specific events
- Add itinerary-specific states
- Update event handlers
- Integrate with ItineraryService
- Write bloc tests

**Files:**
- `lib/presentation/blocs/lists/lists_bloc.dart` (modify)
- `test/bloc/lists/lists_bloc_test.dart` (update)

**Estimated Effort:** 8-10 hours

#### **4.2 Navigation Integration (Day 3)**

**Tasks:**
- Add routes for itinerary pages
- Update lists page (add "Create Itinerary" option)
- Add navigation from regular lists
- Test navigation flow

**Files:**
- `lib/presentation/routes/app_router.dart` (modify)
- `lib/presentation/pages/lists/lists_page.dart` (modify)

**Estimated Effort:** 4-6 hours

#### **4.3 Calendar Export Integration (Day 4)**

**Tasks:**
- Integrate CalendarExportService
- Add export buttons to UI
- Test export functionality
- Handle export errors

**Files:**
- `lib/presentation/pages/lists/itinerary_details_page.dart` (modify)
- `lib/presentation/widgets/lists/calendar_export_button.dart` (new)

**Estimated Effort:** 6-8 hours

#### **4.4 Testing & Bug Fixes (Days 5-7)**

**Tasks:**
- Integration testing
- Widget testing
- Service testing
- Bug fixes
- Performance optimization
- Accessibility improvements

**Estimated Effort:** 16-20 hours

**Phase 4 Total:** 34-44 hours (4-5 days)

---

## 📊 **Total Timeline**

| Phase | Duration | Effort |
|-------|----------|--------|
| Phase 1: Foundation | 3-4 days | 22-28 hours |
| Phase 2: Repository & Data | 2-3 days | 16-20 hours |
| Phase 3: UI Components | 6-7 days | 46-56 hours |
| Phase 4: Integration & Polish | 4-5 days | 34-44 hours |
| **TOTAL** | **15-19 days** | **118-148 hours** |

**Estimated Timeline:** 3-4 weeks (assuming 40 hours/week)

---

## 🔗 **Dependencies**

### **Required:**
- ✅ Lists system (exists)
- ✅ Spots system (exists)
- ✅ Calendar integration for events (exists - can reuse patterns)
- ✅ Navigation system (exists)

### **Optional (Future Enhancements):**
- Events system integration (add events to itineraries)
- AI suggestions (suggest spots for specific dates)
- AI2AI connections (connect users with similar itineraries)
- Weather integration (show weather for trip dates)

---

## 🎨 **UI/UX Design Considerations**

### **Design Principles:**
- **Optional Enhancement** - Calendar features are optional, existing lists work without them
- **Visual Clarity** - Calendar views should be clear and easy to understand
- **Flexible Views** - Multiple view modes accommodate different planning styles
- **Real-World Focus** - Design emphasizes actual trip planning, not digital organization

### **View Modes:**

#### **Days/Nights View:**
- Horizontal timeline
- Each day/night as a column
- Spots displayed in day columns
- Visual distinction between days and nights

#### **Weeks View:**
- Calendar grid (7 days per row)
- Spots displayed in date cells
- Week navigation
- Month indicator

#### **Months View:**
- Full calendar month view
- Spots displayed in date cells
- Month navigation
- Year indicator

### **Color Scheme:**
- Use `AppColors` or `AppTheme` (MANDATORY - no direct `Colors.*`)
- Days: Light background
- Nights: Slightly darker background
- Selected dates: Primary color highlight
- Spots: Category-based colors

---

## 🧪 **Testing Strategy**

### **Unit Tests:**
- Model serialization/deserialization
- Service logic (date calculations, assignments)
- Repository methods

### **Widget Tests:**
- Calendar view rendering
- View mode switching
- Date assignment dialog
- Itinerary creation page

### **Integration Tests:**
- Full itinerary creation flow
- Spot assignment to dates
- Calendar export
- Navigation flow

### **Test Coverage Target:** >80%

---

## 📚 **Documentation Requirements**

### **Code Documentation:**
- All public APIs documented
- Complex logic explained
- Usage examples in comments

### **User Documentation:**
- How to create itinerary lists
- How to assign spots to dates
- How to use different view modes
- How to export to calendar

### **Developer Documentation:**
- Architecture decisions
- Extension points
- Future enhancement opportunities

---

## 🚀 **Future Enhancements**

### **Phase 5 (Future):**
1. **AI Suggestions**
   - Suggest spots for specific dates based on itinerary
   - Suggest optimal visit times
   - Suggest nearby spots for dates

2. **Events Integration**
   - Add events to itineraries
   - Show events in calendar view
   - Link events to spots

3. **AI2AI Connections**
   - Connect users with similar itineraries
   - Share itinerary recommendations
   - Find travel companions

4. **Weather Integration**
   - Show weather forecasts for trip dates
   - Suggest indoor alternatives for bad weather
   - Weather-based spot recommendations

5. **Collaborative Itineraries**
   - Multiple users editing same itinerary
   - Real-time collaboration
   - Conflict resolution

---

## ✅ **Success Criteria**

### **Functional:**
- ✅ Users can create itinerary lists with start/end dates
- ✅ Users can assign spots to specific dates
- ✅ Users can view itineraries in multiple modes (days/nights, weeks, months)
- ✅ Users can export itineraries to external calendars
- ✅ Existing lists continue to work without calendar features

### **Quality:**
- ✅ Zero linter errors
- ✅ >80% test coverage
- ✅ All tests passing
- ✅ Documentation complete

### **User Experience:**
- ✅ Intuitive calendar views
- ✅ Smooth date assignment
- ✅ Easy export functionality
- ✅ Backward compatibility maintained

---

## 📖 **References**

### **Philosophy:**
- `docs/plans/philosophy_implementation/DOORS.md` - Doors philosophy
- `OUR_GUTS.md` - Core values
- `docs/plans/philosophy_implementation/SPOTS_PHILOSOPHY_AND_ARCHITECTURE.md` - Complete philosophy guide

### **Methodology:**
- `docs/plans/methodology/DEVELOPMENT_METHODOLOGY.md` - Development methodology
- `docs/plans/methodology/START_HERE_NEW_TASK.md` - Context gathering protocol

### **Related Features:**
- Lists system (existing)
- Events system (calendar integration patterns)
- Spots system (existing)

---

**Status:** 📋 Ready for Implementation  
**Last Updated:** December 15, 2025


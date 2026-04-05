# SPOTS UI/UX Design Navigation Guide

**Generated:** August 12, 2025 at 23:26:17 CDT  
**Status:** Complete Design System Implementation

## Table of Contents
1. [Design Philosophy](#design-philosophy)
2. [Color Palette & Theming](#color-palette--theming)
3. [Navigation Architecture](#navigation-architecture)
4. [User Flow Diagrams](#user-flow-diagrams)
5. [Component Library](#component-library)
6. [File Structure & Locations](#file-structure--locations)
7. [Design Tokens](#design-tokens)
8. [Platform Consistency](#platform-consistency)

---

## Design Philosophy

### Core Principles
- **Minimalist Aesthetic**: Clean, uncluttered interfaces with purposeful whitespace
- **Consistent Tokenization**: All colors, spacing, and typography use centralized tokens
- **Platform Agnostic**: Single codebase ensuring identical experience across iOS, Web, and Android
- **Accessibility First**: High contrast ratios and clear visual hierarchy
- **Electric Green Focus**: Single accent color for brand recognition and call-to-actions

### Design Goals
- **Consistency**: Uniform appearance across all screens and components
- **Responsiveness**: Adaptive layouts that work on all screen sizes
- **Intuitiveness**: Clear navigation patterns and predictable interactions
- **Performance**: Smooth animations and fast loading times

---

## Color Palette & Theming

### Primary Palette
```
Electric Green (Accent): #00FF66
Black: #000000
White: #FFFFFF
```

### Greyscale Ramp
```
Grey 50:  #FAFAFA  (Lightest backgrounds)
Grey 100: #F5F5F5  (Input backgrounds)
Grey 200: #E5E5E5  (Button backgrounds)
Grey 300: #CCCCCC  (Borders)
Grey 400: #B3B3B3  (Hint text)
Grey 500: #8A8A8A  (Offline indicator)
Grey 600: #6E6E6E  (Secondary text)
Grey 700: #4D4D4D  (Dark mode surfaces)
Grey 800: #1F1F1F  (Dark backgrounds)
Grey 900: #0B0B0B  (Darkest)
```

### Semantic Colors
```
Success: #00FF66 (Electric Green)
Error: #FF4D4D
Warning: #FFC107
```

### Theme Implementation
**Location:** `lib/core/theme/`
- `app_theme.dart` - Main theme configuration
- `colors.dart` - Color token definitions
- `map_themes.dart` - Map-specific styling
- `category_colors.dart` - Category-specific colors and icons

---

## Navigation Architecture

### Route Structure
```
/ (Root)
├── /login
├── /signup
├── /onboarding
├── /home (Main App)
│   ├── /spots
│   ├── /lists
│   ├── /map
│   ├── /profile
│   ├── /hybrid-search
│   └── /ai-loading
└── /supabase-test (Development)
```

### Navigation Flow
```
┌─────────────────┐
│   App Launch    │
└─────────┬───────┘
          │
          ▼
┌─────────────────┐
│  Auth Check     │
└─────────┬───────┘
          │
    ┌─────┴─────┐
    │           │
    ▼           ▼
┌─────────┐ ┌─────────┐
│ Login   │ │Signup   │
└────┬────┘ └────┬────┘
     │           │
     └─────┬─────┘
           │
           ▼
┌─────────────────┐
│  Onboarding     │
└─────────┬───────┘
          │
          ▼
┌─────────────────┐
│   Home Page     │
│  (Tab Nav)      │
└─────────┬───────┘
          │
    ┌─────┴─────┐
    │           │
    ▼           ▼
┌─────────┐ ┌─────────┐
│  Map    │ │ Spots   │
└────┬────┘ └────┬────┘
     │           │
     ▼           ▼
┌─────────┐ ┌─────────┐
│ Explore │ │Profile  │
└─────────┘ └─────────┘
```

### Tab Navigation (Home Page)
```
┌─────────────────────────────────────┐
│              App Bar                │
├─────────────────────────────────────┤
│                                     │
│           Content Area              │
│                                     │
├─────────────────────────────────────┤
│ [Map] [Spots] [Explore] [Profile]   │
└─────────────────────────────────────┘
```

---

## User Flow Diagrams

### Authentication Flow
```
┌─────────────┐
│ App Start   │
└─────┬───────┘
      │
      ▼
┌─────────────┐    No    ┌─────────────┐
│Authenticated│ ────────▶│ Login Page  │
└─────┬───────┘          └─────┬───────┘
      │ Yes                     │
      ▼                         │
┌─────────────┐    No    ┌─────────────┐
│Onboarding   │ ────────▶│Onboarding   │
│Complete?    │          │  Flow       │
└─────┬───────┘          └─────┬───────┘
      │ Yes                     │
      ▼                         │
┌─────────────┐                │
│ Home Page   │◀───────────────┘
└─────────────┘
```

### Spot Creation Flow
```
┌─────────────┐
│ Spots Tab   │
└─────┬───────┘
      │
      ▼
┌─────────────┐
│  + Button   │
└─────┬───────┘
      │
      ▼
┌─────────────┐
│Create Spot  │
│   Form      │
└─────┬───────┘
      │
      ▼
┌─────────────┐
│ Location    │
│ Selection   │
└─────┬───────┘
      │
      ▼
┌─────────────┐
│ Category    │
│ Selection   │
└─────┬───────┘
      │
      ▼
┌─────────────┐
│ Save Spot   │
└─────────────┘
```

### Map Interaction Flow
```
┌─────────────┐
│   Map Tab   │
└─────┬───────┘
      │
      ▼
┌─────────────┐
│ View Spots  │
│  on Map     │
└─────┬───────┘
      │
      ▼
┌─────────────┐
│ Tap Spot    │
│  Marker     │
└─────┬───────┘
      │
      ▼
┌─────────────┐
│ Spot Detail │
│   Card      │
└─────┬───────┘
      │
      ▼
┌─────────────┐
│ View Full   │
│  Details    │
└─────────────┘
```

---

## Component Library

### Core Components

#### Buttons
**Location:** Global theme in `app_theme.dart`
- **Elevated Button**: Light grey background, black text
- **Text Button**: Transparent with primary text color
- **Outlined Button**: Border with primary text color

#### Input Fields
**Location:** Global theme in `app_theme.dart`
- **Text Input**: Grey background, rounded corners
- **Search Bar**: Consistent styling across all search components

#### Cards
**Location:** Global theme in `app_theme.dart`
- **Standard Card**: White background, subtle shadow
- **Spot Card**: Custom styling for spot information

#### Navigation
**Location:** `lib/presentation/pages/home/home_page.dart`
- **Bottom Navigation**: 4 tabs with electric green accent
- **App Bar**: Black background, white text

### Custom Components

#### AI Chat Bar
**Location:** `lib/presentation/widgets/common/ai_chat_bar.dart`
- Input field with send button
- Adaptive background colors

#### Search Components
**Location:** `lib/presentation/widgets/common/`
- `search_bar.dart` - Generic search input
- `universal_ai_search.dart` - AI-powered search with suggestions

#### Map Components
**Location:** `lib/presentation/widgets/map/`
- `map_view.dart` - Main map display
- `spot_marker.dart` - Custom spot markers

#### Spot Components
**Location:** `lib/presentation/widgets/spots/`
- `spot_card.dart` - Spot information display
- Category-specific styling

---

## File Structure & Locations

### Core Theme Files
```
lib/core/theme/
├── app_theme.dart          # Main theme configuration
├── colors.dart             # Color token definitions
├── map_themes.dart         # Map styling themes
├── category_colors.dart    # Category-specific colors/icons
├── responsive.dart         # Responsive layout helpers
└── text_styles.dart        # Typography definitions
```

### Page Structure
```
lib/presentation/pages/
├── auth/
│   ├── auth_wrapper.dart   # Authentication wrapper
│   ├── login_page.dart     # Login screen
│   └── signup_page.dart    # Signup screen
├── home/
│   └── home_page.dart      # Main tab navigation
├── onboarding/
│   ├── onboarding_page.dart
│   ├── ai_loading_page.dart
│   ├── homebase_selection_page.dart
│   ├── preference_survey_page.dart
│   ├── friends_respect_page.dart
│   ├── favorite_places_page.dart
│   └── baseline_lists_page.dart
├── spots/
│   ├── spots_page.dart     # Spots list
│   ├── spot_details_page.dart
│   ├── create_spot_page.dart
│   └── edit_spot_page.dart
├── lists/
│   ├── lists_page.dart     # Lists overview
│   ├── list_details_page.dart
│   ├── create_list_page.dart
│   └── edit_list_page.dart
├── map/
│   └── map_page.dart       # Map view
├── profile/
│   └── profile_page.dart   # User profile
├── search/
│   └── hybrid_search_page.dart
└── settings/
    ├── about_page.dart
    ├── help_support_page.dart
    ├── notifications_settings_page.dart
    └── privacy_settings_page.dart
```

### Widget Structure
```
lib/presentation/widgets/
├── common/
│   ├── ai_chat_bar.dart
│   ├── search_bar.dart
│   ├── universal_ai_search.dart
│   ├── chat_message.dart
│   └── offline_indicator.dart
├── map/
│   ├── map_view.dart
│   └── spot_marker.dart
├── spots/
│   └── spot_card.dart
├── lists/
│   └── list_card.dart
├── search/
│   └── hybrid_search_results.dart
└── validation/
    └── community_validation_widget.dart
```

### Navigation & Routing
```
lib/presentation/routes/
└── app_router.dart         # GoRouter configuration
```

---

## Design Tokens

### Color Usage Guidelines

#### Primary Actions
- **Electric Green (#00FF66)**: Primary buttons, important CTAs, success states
- **Black Text**: On light backgrounds for maximum readability

#### Secondary Actions
- **Grey 200 Background**: Secondary buttons, form inputs
- **Grey 600 Text**: Secondary text, labels, hints

#### Information Hierarchy
- **Black**: Primary text, headings
- **Grey 600**: Secondary text, descriptions
- **Grey 400**: Hint text, placeholders

#### Status Indicators
- **Electric Green**: Success, completion
- **Red**: Errors, destructive actions
- **Yellow**: Warnings, attention needed

### Spacing System
```
4px   - Extra small spacing
8px   - Small spacing
12px  - Medium spacing
16px  - Standard spacing
24px  - Large spacing
32px  - Extra large spacing
48px  - Section spacing
```

### Typography
**Font Family:** Inter (Google Fonts)
- **Headings**: Bold, various sizes
- **Body Text**: Regular weight
- **Captions**: Smaller, secondary color

---

## Platform Consistency

### Cross-Platform Implementation
- **Single Codebase**: Flutter ensures identical behavior across platforms
- **Material 3**: Modern design system with platform adaptations
- **Responsive Design**: Adaptive layouts for different screen sizes

### Platform-Specific Considerations

#### iOS
- Native navigation patterns
- iOS-style animations
- Platform-specific icons

#### Android
- Material Design guidelines
- Android navigation patterns
- Platform-specific interactions

#### Web
- Keyboard navigation support
- Responsive breakpoints
- Web-specific optimizations

### Testing Strategy
- **Visual Testing**: Screenshot comparisons across platforms
- **Interaction Testing**: Touch, mouse, and keyboard interactions
- **Accessibility Testing**: Screen reader compatibility

---

## Implementation Notes

### Recent Updates (August 12, 2025)
- ✅ **100% Color Tokenization**: All hardcoded colors replaced with `AppColors.*` tokens
- ✅ **Consistent Theming**: Global Material 3 theme with minimalist palette
- ✅ **Button Standardization**: Light grey buttons with black text, minimal electric green highlights
- ✅ **Component Cleanup**: Removed local color overrides, using global theme
- ✅ **Category System**: Centralized category colors and icons

### Best Practices
1. **Always use design tokens** - Never hardcode colors, spacing, or typography
2. **Follow the component hierarchy** - Use existing components before creating new ones
3. **Test across platforms** - Ensure consistency on iOS, Android, and Web
4. **Maintain accessibility** - Use semantic colors and proper contrast ratios
5. **Keep it minimal** - Avoid unnecessary visual complexity

### Future Considerations
- **Dark Mode**: Theme already supports dark mode switching
- **Customization**: User preferences for accent colors
- **Animations**: Smooth transitions between states
- **Accessibility**: Enhanced screen reader support

---

*This guide serves as the definitive reference for SPOTS UI/UX design decisions and implementation details. Update as the design system evolves.*

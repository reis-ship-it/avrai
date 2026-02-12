
# SPOTS — Offline-First Social Discovery App

SPOTS is a mobile-first, offline-capable app for discovering, saving, and sharing meaningful places through personalized lists and maps. It uses contextual AI and social trust to recommend spots and recognizes user expertise in specific domains (like cafés, bookstores, cuisine) — all without gamification.

---

## 🧩 Core Features

### 🧑‍💼 User Accounts
- User profiles with name, location, interest tags
- Friends/following relationships
- Displays niche-based expertise levels (e.g., “Expert in Thai Food – City Level”)

### 📋 Lists
- Users create public or private spot lists (e.g., "Best Thai Food in NYC")
- Each list is tied to a category and visualized on a map
- Other users can "Respect" a list to show trust/influence AI

### 📍 Spots
- Includes name, lat/lng, category, and optional free-text feedback
- Can be reused across multiple lists

### 🔍 Explore
- Publicly shared lists from unconnected users
- Users can Respect or Friend others
- Profile view includes curated lists and expertise areas

---

## 🧠 AI & Personalization

### Suggested for You
- AI-driven spot recommendations based on:
  - Respected lists
  - Friend networks
  - Personal tags and feedback patterns

### Refine AI
- Panel for adjusting content preferences
- Influences visibility of categories, social graph strength, and diversity

> 🧭 “Anyone can become an expert — not by grinding, but by caring.”

---

## 🧭 Expertise System

- No gamification. No icons or points.
- Expertise is listed on profiles:
  - Local / City / Regional / National / Global / Universal
- Based on real contributions, trusted feedback, and curation quality
- Users can become experts in niches like:
  - Bookstores, Thai food, Vintage shops, etc.

> 🗣️ “Feedback is context.”  
> 🤝 “Trust is the pathway to recognition.”

---

## 💸 Monetization (Minimalist Ethos)

- Host-powered event ticketing (e.g., curated walks)
- Paid spot promotion to expert-tier users (no general ads)
- Sponsored placements in expert-curated lists (user-controlled)
- Anonymous AI-powered market insights (no user data sold)
- Free downloadable archives of user’s lists & journeys

---

## 📶 Offline Support

- Offline caching of spot data and list content
- Downloadable map tiles (Mapbox or equivalent)
- On-device AI using TensorFlow Lite / ONNX
- Syncing queued edits once online

---

## 🗂 Data Structure

| Table       | Fields |
|-------------|--------|
| `Users`     | id, name, location, tags, expertise, friends |
| `Lists`     | id, title, description, category, user_id |
| `Spots`     | id, name, lat, lng, category, list_id |
| `Respects`  | user_id, list_id |
| `Feedback`  | user_id, spot_id, text |
| `Suggestions` | user_id, spot_id, reason |

CSV samples available: [Download here](./spots_data_export.zip)

---

## 🔧 Current Prototype
- Built in Glide (mobile-first)
- Includes:
  - Thai Food list
  - Suggested for You section
  - Refine AI tuning panel
  - Explore tab, Respect system, feedback fields
- Status: Private, shared with `reisjgordon@gmail.com`

---

## 🧑‍💻 Next Steps for Development

**Recommended Stack:**
- Flutter or React Native (mobile-first)
- Realm or SQLite (offline DB)
- Mapbox for offline maps
- Lightweight backend (Firebase, Supabase, or custom Node.js)
- On-device ML with TensorFlow Lite or ONNX

---

Built to help people discover their world — thoughtfully, offline, and together.

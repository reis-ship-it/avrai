# AVRAI Consumer Beta Page Atlas Scope

Date: 2026-03-11

This file is the source-of-truth capture list for the consumer beta page atlas and its Figma artifact. It includes consumer-facing routes from the main router and excludes business, admin, debug, and test/operator surfaces.

FigJam route atlas: https://www.figma.com/online-whiteboard/create-diagram/0eb5a8e0-05b0-4065-b0ab-1399157e5946?utm_source=other&utm_content=edit_in_figjam&oai_id=&request_id=82809819-51ec-43cc-b09b-afe22e511f4f

FigJam design section map: https://www.figma.com/online-whiteboard/create-diagram/3af4e69d-790b-4012-b753-5aae69f972ed?utm_source=other&utm_content=edit_in_figjam&oai_id=&request_id=cb27d3ef-37cd-4803-9896-da04aded7c87

Figma visual atlas: https://www.figma.com/design/Xne07RKIIUavxiLEBeNPR9?node-id=2-2

Visual atlas capture source: `work/docs/reports/consumer_beta_visual_atlas.html`

Automated live screenshot capture blocker: the current Flutter app does not build for web because runtime modules import `dart:ffi`-backed code paths, so the FigJam artifact for this pass is a route-atlas board rather than a page-by-page live screenshot file.

## Included Lanes

### Auth
- `/`
- `/login`
- `/signup`

### Onboarding
- `/onboarding`
- `/ai-loading`
- `/onboarding/walkthrough`
- `/knot-birth`
- `/knot-discovery`

### Core Discovery
- `/home`
- `/spots`
- `/lists`
- `/map`
- `/explore` via the Home shell tab state
- `/device-discovery`
- `/ai2ai-connections`
- `/discovery-settings`
- `/federated-learning`
- `/on-device-ai`
- `/ai-improvement`
- `/ai2ai-learning-methods`
- `/continuous-learning`
- `/hybrid-search`
- `/group/formation`
- `/group/results`
- `/group/results/:sessionId`

### Objects
- `/spot/:id`
- `/spot/create`
- `/spot/:id/edit`
- `/list/:id`
- `/list/create`
- `/list/:id/edit`
- `/event/create`
- `/event/:id`
- `/community/:id`
- `/community/create`
- `/communities/discover`
- `/club/:id`
- `/club/create`
- `/reservations`
- `/reservations/create`
- `/reservations/:id`
- `/reservations/analytics`

### Chat And Social
- `/chat`
- `/chat/agent`
- `/chat/admin`
- `/chat/friend/:friendId`
- `/chat/community/:communityId`
- `/chat/event/:eventId`
- `/chat/announcement/:scope/:scopeId`
- `/friends/discover`
- `/friends/qr/add`
- `/friends/qr/scan`

### Profile And Settings
- `/profile`
- `/settings`
- `/profile/beta-feedback`
- `/profile/ai-status`
- `/profile/receipts`
- `/profile/receipts/:id`
- `/profile/expertise-dashboard`
- `/profile/partnerships`
- `/settings/public-handles`

### Legal And Support
- In-profile legal surfaces opened from Profile:
  - Terms of Service
  - Privacy Policy
  - Help & Support
- Onboarding legal acceptance entry points
- About page
- Privacy Settings legal link

## Excluded From The Atlas
- Admin handoff routes under `/admin/...`
- Business routes under `/business/...`
- Debug/test/operator routes:
  - `/proof-run`
  - `/geo-area-debug`
  - `/supabase-test`
- Feature-flagged experimental route:
  - `/world-planes`

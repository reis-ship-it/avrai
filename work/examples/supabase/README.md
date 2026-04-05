Supabase Examples
=================

This folder contains standalone examples showing direct Supabase usage.

Files
- main_supabase_example.dart: Minimal Flutter app bootstrapping Supabase.
- supabase_initializer.dart: Helper used by the example app.
- supabase_integration_example.dart: UI demonstrating basic DB operations.
- supabase_config.dart: Example-only config. Do not commit secrets.

Notes
- The production app uses `spots_network` as the single integration boundary, configured via DI. These examples are for learning and manual verification only.
- Prefer setting credentials via Dart defines when running locally.

Run
```bash
flutter run -t examples/supabase/main_supabase_example.dart \
  --dart-define=SUPABASE_URL=... \
  --dart-define=SUPABASE_ANON_KEY=...
```



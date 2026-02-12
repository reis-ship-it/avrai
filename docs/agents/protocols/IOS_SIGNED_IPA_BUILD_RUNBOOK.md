## iOS signed IPA build runbook (AVRAI)

This runbook captures the exact blockers and steps discovered while trying to produce an **installable iOS IPA** from this repo.

### What you can produce today (no Apple Developer Program)
- **Simulator builds** (run on Mac): `flutter run -d <simulator>`
- **Unsigned iOS device build artifacts** (not installable on real devices):
  - `build/ios/iphoneos/Runner.app`
  - `build/ios/Runner-unsigned.ipa`

### What you can ship today (Android)
- **Release APK**: `build/app/outputs/flutter-apk/app-release.apk`
- **Release AAB**: `build/app/outputs/bundle/release/app-release.aab`

---

## Requirements for a signed, installable iOS IPA

### 1) Apple Developer Program (paid)
You need an active Apple Developer Program membership (not just an Apple ID).

**Symptoms when missing:**
- Xcode/Flutter cannot generate provisioning profiles.
- Build errors similar to:
  - “No profiles for '<bundle id>' were found…”
  - “Communication with Apple failed…”

### 2) Xcode signed into an Apple account
Xcode must have an account added under:
- **Xcode → Settings → Accounts**

### 3) A unique bundle identifier
The bundle id must be **available under your team**.

**Example**
  - ✅ `com.reisgordon.avrai`
  - ❌ `com.avra.app` (was not available; already claimed by another team)

### 4) Device registration (for Development/Ad Hoc)
For development-style IPAs, your device must be registered to the team.

**Common missing piece on newer iOS versions**
- Enable **Developer Mode** on the iPhone:
  - Settings → Privacy & Security → Developer Mode → ON
  - reboot and confirm

---

## Recommended signing path (fastest)

### A) Development IPA (direct install on your phone)
1. Enroll in Apple Developer Program
2. Sign into Xcode Accounts
3. Plug in iPhone, trust computer, enable Developer Mode
4. In `ios/Runner.xcworkspace`:
   - Runner → Signing & Capabilities
   - Automatically manage signing ✅
   - Team: your team
   - Bundle Identifier: unique id (e.g. `com.reisgordon.avrai`)
5. Build:

```bash
flutter build ipa --release --export-method development
```

Output:
- `build/ios/ipa/*.ipa`

### B) TestFlight / App Store
Requires Apple Distribution certs/profiles (managed via Xcode or portal).

```bash
flutter build ipa --release --export-method app-store
```

---

## Repo-specific notes (what we changed during packaging)

- iOS team id is set in `ios/Runner.xcodeproj/project.pbxproj` for automatic signing.
- iOS bundle identifier is set to `com.avrai.app` (already configured).
- Android release packaging is produced successfully; release minification (R8) was disabled to avoid missing-class failures from optional SDK components.


# Mac Admin Device Onboarding

## Purpose

This is the shortest path for getting the AVRAI admin console onto a new work Mac.

Use this only for approved admin devices.
Do not use this for consumer beta phones or personal non-admin devices.

## Before You Start

All of these must already be true:

1. the private admin control-plane VM is running
2. the VM is on Tailscale
3. the control-plane stack is deployed and healthy
4. you know the private control-plane URL

Current local-lab example:

- VM Tailscale IP: `100.83.143.46`
- example control-plane URL: `http://100.83.143.46:7443/`

If you later add private HTTPS ingress in front of the gateway, use that private `https://...` URL instead.

## Option A: Recommended

Build the admin app once on your main machine, then copy the signed app bundle to each approved work Mac.

### Step 1: Put The Work Mac On Tailscale

On the work Mac:

1. install Tailscale
2. sign in with the approved AVRAI admin account
3. confirm the work Mac appears in the tailnet

### Step 2: Build The Admin App With The Private URL

On your main AVRAI machine:

```bash
cd /Users/reisgordon/AVRAI/apps/admin_app
flutter pub get
flutter build macos --release \
  --dart-define=ADMIN_CONTROL_PLANE_URL=http://100.83.143.46:7443/ \
  --dart-define=ADMIN_CONTROL_PLANE_POLL_INTERVAL_SECONDS=5
```

Resulting app bundle:

```text
/Users/reisgordon/AVRAI/apps/admin_app/build/macos/Build/Products/Release/avrai_admin_app.app
```

### Step 3: Copy The App To The Work Mac

Copy `avrai_admin_app.app` to the work Mac using a method you trust.

Examples:

- AirDrop
- Tailscale file transfer
- an encrypted USB drive

### Step 4: Launch And Verify

On the work Mac:

1. open `avrai_admin_app.app`
2. confirm it reaches the private backend
3. confirm the research/admin surfaces load
4. confirm the app does not fall back to local mock state

If you want a quick network check first:

```bash
curl http://100.83.143.46:7443/health
```

## Option B: Build On Each Work Mac

Use this only if you want each work Mac to build from source.

On the work Mac:

```bash
git clone <your-avrai-repo-url>
cd AVRAI/apps/admin_app
flutter pub get
flutter build macos --release \
  --dart-define=ADMIN_CONTROL_PLANE_URL=http://100.83.143.46:7443/ \
  --dart-define=ADMIN_CONTROL_PLANE_POLL_INTERVAL_SECONDS=5
```

The built app bundle will be in:

```text
AVRAI/apps/admin_app/build/macos/Build/Products/Release/avrai_admin_app.app
```

## Device Rules

Every admin Mac should be:

1. on Tailscale
2. approved for admin use
3. desktop or laptop only
4. used only by an authorized admin operator

## Do Not Do This

- do not install the admin app on consumer beta phones
- do not point consumer builds at `ADMIN_CONTROL_PLANE_URL`
- do not use a public URL for the admin control plane
- do not share the `.env` file with work Macs
- do not put the Supabase service-role key on work Macs

## When A New Work Mac Is Ready

Repeat this order:

1. join the work Mac to Tailscale
2. verify private reachability to the control-plane VM
3. install or copy the admin app build that already has the private URL baked in
4. launch and verify admin access

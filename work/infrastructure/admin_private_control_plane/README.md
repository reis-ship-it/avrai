# Admin Private Control Plane

This stack is the private beta infrastructure boundary for governed autoresearch.

## Services

- `admin-control-plane-gateway`
  - Private gateway for admin sessions, research control actions, audit access, and evidence-pack issuance.
  - Talks to Supabase with the service-role key.
  - Fails closed unless OPA authorizes the action.
- `broker`
  - Dedicated outbound-only evidence broker.
  - Enforces host allowlists, content-type caps, timeout caps, size caps, and quarantine metadata writes.
- `opa`
  - Policy engine for session issuance and sensitive-action enforcement.

## Expected network posture

- Expose this stack only on private subnets or private mesh routes.
- Do not publish `admin-control-plane-gateway` on public ingress.
- Terminate mTLS and OIDC in the private ingress layer in front of the gateway.
- Route the admin desktop app to `ADMIN_CONTROL_PLANE_URL`, not directly to Supabase.

## Required environment

Copy `.env.example` to `.env` and set real values for:

- `SUPABASE_URL`
- `SUPABASE_SERVICE_ROLE_KEY`
- `ADMIN_CONTROL_PLANE_EVIDENCE_SIGNING_SECRET`
- `RESEARCH_EGRESS_BROKER_SHARED_KEY`

Adjust allowlists before deployment:

- `RESEARCH_EGRESS_BROKER_ALLOWED_HOSTS`
- `RESEARCH_EGRESS_BROKER_ALLOWED_CONTENT_TYPES`

## Local deployment

```bash
cd work/infrastructure/admin_private_control_plane
cp .env.example .env
docker compose up --build -d
```

## Health checks

- Gateway: `GET /health`
- Broker: `GET /health`
- OPA: `GET /health?plugins`

Use `work/scripts/deploy/deploy_admin_private_control_plane.sh` and `work/scripts/verify_admin_private_control_plane.sh` for rollout and readiness checks.

## Runbooks

- [LOCAL_MAC_UBUNTU_VM_RUNBOOK.md](./LOCAL_MAC_UBUNTU_VM_RUNBOOK.md)
- [SECRETS_AND_GO_LIVE_CHECKLIST.md](./SECRETS_AND_GO_LIVE_CHECKLIST.md)
- [DEPLOYMENT_MODEL.md](./DEPLOYMENT_MODEL.md)
- [MAC_ADMIN_DEVICE_ONBOARDING.md](./MAC_ADMIN_DEVICE_ONBOARDING.md)

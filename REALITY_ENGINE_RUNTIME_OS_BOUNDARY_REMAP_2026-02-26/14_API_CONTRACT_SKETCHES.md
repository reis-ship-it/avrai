# 14 - API Contract Sketches (Draft)

## 1) Engine Runtime Contract (Pseudo-schema)

```json
{
  "engine_input_envelope": {
    "contract_version": "1.0",
    "state_snapshot": {},
    "event_batch": [],
    "capability_profile": {
      "tier": "C0|C1|C2|C3",
      "transport": {},
      "scheduler": {},
      "security": {}
    },
    "policy_context": {
      "policy_pack_id": "...",
      "constraints": []
    },
    "trust_context": {
      "identity_state": "...",
      "attestation_state": "..."
    }
  }
}
```

## 2) Engine Decision Response

```json
{
  "engine_decision_response": {
    "contract_version": "1.0",
    "decision_id": "...",
    "ranked_actions": [
      {
        "action_type": "...",
        "score": 0.0,
        "required_capabilities": [],
        "confidence": 0.0,
        "risk": 0.0,
        "assumptions": []
      }
    ],
    "alternatives": [],
    "policy_flags": [],
    "recourse_options": [],
    "trace": {
      "engine_version": "...",
      "policy_pack_version": "...",
      "provenance_id": "..."
    }
  }
}
```

## 3) Runtime Execution Envelope to Product

```json
{
  "host_action_envelope": {
    "decision_id": "...",
    "execution_mode": "direct|pilot|conservative|blocked",
    "display_payload": {
      "primary_recommendation": "...",
      "why": [],
      "uncertainty": {},
      "challenge_controls": []
    },
    "telemetry_keys": {
      "engine_version": "...",
      "runtime_version": "...",
      "host_adapter_version": "...",
      "policy_pack_version": "..."
    }
  }
}
```

## 4) Outcome Ingestion Contract

```json
{
  "outcome_record": {
    "contract_version": "1.0",
    "decision_id": "...",
    "actual_action": "...",
    "outcome_type": "positive|negative|neutral|deferred",
    "delayed_window": "7d|30d|90d",
    "context": {},
    "consent_scope": "...",
    "trace": {}
  }
}
```

## 5) Capability Change Event

```json
{
  "runtime_capability_event": {
    "event_id": "...",
    "from_tier": "C2",
    "to_tier": "C1",
    "reason": "background_restriction|permission_revoked|transport_unavailable",
    "effective_at": "..."
  }
}
```

## 6) Compatibility Rules

1. Breaking changes require major version bump.
2. Runtime must support `N` and `N-1` contract versions.
3. Engine must reject unknown required fields in critical control paths.
4. Product adapters must declare supported version ranges.


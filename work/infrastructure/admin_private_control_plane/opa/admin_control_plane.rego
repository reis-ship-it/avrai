package admin.control_plane

default allow = false

default reason = "Denied by default."

decision = {
  "allow": allow,
  "reason": reason,
}

allowed_groups = {group | group := lower(input.request.allowedGroups[_])}

step_up_present {
  proof := input.request.stepUpProof.proof
  proof != ""
}

second_operator_present {
  alias := input.request.secondOperatorApproval.actorAlias
  alias != ""
  lower(alias) != lower(input.actorAlias)
}

mesh_provider_allowed {
  provider := lower(input.deviceAttestation.privateMeshProvider)
  provider != ""
  allowed := {lower(value) | value := input.allowedMeshProviders[_]}
  allowed[provider]
}

device_posture_ok {
  input.deviceAttestation.managedDevice == true
  input.deviceAttestation.signedDesktopBinary == true
  input.deviceAttestation.diskEncryptionEnabled == true
  input.deviceAttestation.osPatchBaselineSatisfied == true
  input.deviceAttestation.meshIdentity != ""
  input.deviceAttestation.clientCertificateFingerprint != ""
}

allowed_admin_group {
  group := allowed_groups[_]
  group == "admin_operator"
}

allowed_admin_group {
  group := allowed_groups[_]
  group == "admin-operators"
}

allow {
  input.action == "create_session"
  input.request.oidcAssertion != ""
  input.request.mfaProof != ""
  device_posture_ok
  mesh_provider_allowed
  allowed_admin_group
}

reason = "Session creation requires OIDC, MFA, admin_operator group membership, and compliant managed-device posture." {
  input.action == "create_session"
  not allow
}

allow {
  input.action == "list_runs"
  input.session.id != ""
}

allow {
  input.action == "list_alerts"
  input.session.id != ""
}

allow {
  input.action == "watch_run"
  input.session.id != ""
}

step_up_actions = {
  "stop_run",
  "redirect_run",
  "approve_open_web",
  "review_candidate",
  "trigger_kill_switch",
  "download_evidence_pack",
}

dual_actions = {
  "approve_open_web",
  "trigger_kill_switch",
}

allow {
  input.session.id != ""
  not step_up_actions[input.action]
  input.action != "create_session"
}

allow {
  input.session.id != ""
  step_up_actions[input.action]
  step_up_present
  not dual_actions[input.action]
}

allow {
  input.session.id != ""
  dual_actions[input.action]
  step_up_present
  second_operator_present
}

reason = "Sensitive action requires a fresh step-up proof." {
  step_up_actions[input.action]
  not dual_actions[input.action]
  not step_up_present
}

reason = "Dual-control action requires a distinct second admin_operator approval." {
  dual_actions[input.action]
  not second_operator_present
}

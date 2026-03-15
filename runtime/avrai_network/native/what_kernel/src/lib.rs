mod affordance;
mod errors;
mod evolution;
mod ffi;
mod models;
mod ontology;
mod persistence;
mod projection;
mod sync;
mod syscalls;

use ffi::{free_c_string, into_c_string, parse_request};
use libc::c_char;
use models::NativeResponse;

#[no_mangle]
pub extern "C" fn avrai_what_kernel_invoke_json(request_ptr: *const c_char) -> *mut c_char {
    let response = match parse_request(request_ptr).and_then(syscalls::handle_request) {
        Ok(response) => response,
        Err(error) => NativeResponse {
            ok: false,
            handled: false,
            payload: serde_json::Value::Null,
            error: Some(error),
        },
    };
    into_c_string(response)
}

#[no_mangle]
pub extern "C" fn avrai_what_kernel_free_string(ptr: *mut c_char) {
    free_c_string(ptr);
}

#[cfg(test)]
mod tests {
    use super::syscalls::handle_request;
    use crate::models::NativeRequest;
    use serde_json::{json, Map, Value};

    #[test]
    fn resolve_what_classifies_cafe() {
        let mut payload = Map::<String, Value>::new();
        payload.insert("agentId".to_string(), json!("agent_1"));
        payload.insert("entityRef".to_string(), json!("spot:cafe"));
        payload.insert("observedAtUtc".to_string(), json!("2026-03-07T00:00:00Z"));
        payload.insert("candidateLabels".to_string(), json!(["coffee shop"]));

        let response = handle_request(NativeRequest {
            syscall: "resolve_what".to_string(),
            payload,
        })
        .expect("request should succeed");

        assert!(response.handled);
        assert_eq!(response.payload["canonical_type"], json!("cafe"));
        assert_eq!(response.payload["place_type"], json!("cafe"));
    }

    #[test]
    fn unsupported_syscall_returns_unhandled() {
        let response = handle_request(NativeRequest {
            syscall: "unknown".to_string(),
            payload: Map::new(),
        })
        .expect("request should succeed");

        assert!(!response.handled);
        assert!(response.ok);
    }

    #[test]
    fn observe_does_not_regress_known_type_to_generic() {
        let mut resolve_payload = Map::<String, Value>::new();
        resolve_payload.insert("agentId".to_string(), json!("agent_1"));
        resolve_payload.insert("entityRef".to_string(), json!("spot:cafe"));
        resolve_payload.insert("observedAtUtc".to_string(), json!("2026-03-07T00:00:00Z"));
        resolve_payload.insert("candidateLabels".to_string(), json!(["coffee shop"]));
        handle_request(NativeRequest {
            syscall: "resolve_what".to_string(),
            payload: resolve_payload,
        })
        .expect("resolve should succeed");

        let mut observe_payload = Map::<String, Value>::new();
        observe_payload.insert("agentId".to_string(), json!("agent_1"));
        observe_payload.insert("entityRef".to_string(), json!("spot:cafe"));
        observe_payload.insert("observedAtUtc".to_string(), json!("2026-03-07T01:00:00Z"));
        observe_payload.insert("observationKind".to_string(), json!("visit"));
        observe_payload.insert("activityHint".to_string(), json!("deep_work"));
        let response = handle_request(NativeRequest {
            syscall: "observe_what".to_string(),
            payload: observe_payload,
        })
        .expect("observe should succeed");

        assert_eq!(response.payload["state"]["canonical_type"], json!("cafe"));
    }

    #[test]
    fn project_sync_and_recover_are_handled() {
        let mut resolve_payload = Map::<String, Value>::new();
        resolve_payload.insert("agentId".to_string(), json!("agent_2"));
        resolve_payload.insert("entityRef".to_string(), json!("spot:park"));
        resolve_payload.insert("observedAtUtc".to_string(), json!("2026-03-07T00:00:00Z"));
        resolve_payload.insert("candidateLabels".to_string(), json!(["park"]));
        handle_request(NativeRequest {
            syscall: "resolve_what".to_string(),
            payload: resolve_payload,
        })
        .expect("resolve should succeed");

        let project_response = handle_request(NativeRequest {
            syscall: "project_what".to_string(),
            payload: Map::from_iter(vec![
                ("agentId".to_string(), json!("agent_2")),
                ("entityRef".to_string(), json!("spot:park")),
            ]),
        })
        .expect("project should succeed");
        assert!(project_response.handled);

        let sync_response = handle_request(NativeRequest {
            syscall: "sync_what".to_string(),
            payload: Map::from_iter(vec![
                ("agentId".to_string(), json!("agent_2")),
                ("peerRuntimeId".to_string(), json!("peer-1")),
                ("deltas".to_string(), json!([])),
                ("observedAtUtc".to_string(), json!("2026-03-07T00:10:00Z")),
            ]),
        })
        .expect("sync should succeed");
        assert!(sync_response.handled);

        let recover_response = handle_request(NativeRequest {
            syscall: "recover_what".to_string(),
            payload: Map::from_iter(vec![("agentId".to_string(), json!("agent_2"))]),
        })
        .expect("recover should succeed");
        assert!(recover_response.handled);
    }
}

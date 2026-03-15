use chrono::Utc;
use libc::c_char;
use serde::{Deserialize, Serialize};
use serde_json::{json, Map, Value};
use std::collections::HashMap;
use std::ffi::{CStr, CString};
use std::sync::{Mutex, OnceLock};

static JOURNALS: OnceLock<Mutex<HashMap<String, Vec<TrajectoryMutationRecord>>>> = OnceLock::new();
static CHECKPOINTS: OnceLock<Mutex<HashMap<String, TrajectoryHydrationCheckpoint>>> = OnceLock::new();

#[derive(Debug, Deserialize)]
struct NativeRequest {
    syscall: String,
    payload: Map<String, Value>,
}

#[derive(Debug, Serialize)]
struct NativeResponse {
    ok: bool,
    handled: bool,
    payload: Value,
    #[serde(skip_serializing_if = "Option::is_none")]
    error: Option<String>,
}

#[derive(Clone, Debug, Serialize, Deserialize)]
struct VibeSubjectRef {
    subject_id: String,
    kind: String,
    #[serde(default)]
    entity_type: Option<String>,
    #[serde(default)]
    display_label: Option<String>,
}

#[derive(Clone, Debug, Serialize, Deserialize)]
struct TrajectoryMutationRecord {
    record_id: String,
    subject_ref: VibeSubjectRef,
    category: String,
    occurred_at_utc: String,
    #[serde(default = "default_true")]
    accepted: bool,
    #[serde(default)]
    reason_codes: Vec<String>,
    #[serde(default = "default_governance_scope")]
    governance_scope: String,
    #[serde(default)]
    evidence_summary: Option<String>,
    #[serde(default)]
    snapshot_updated_at_utc: Option<String>,
    #[serde(default)]
    metadata: Map<String, Value>,
}

#[derive(Clone, Debug, Serialize, Deserialize)]
struct TrajectoryHydrationCheckpoint {
    checkpoint_id: String,
    subject_ref: VibeSubjectRef,
    snapshot: Value,
    recorded_at_utc: String,
    #[serde(default)]
    source_record_ids: Vec<String>,
    #[serde(default)]
    metadata: Map<String, Value>,
}

#[no_mangle]
pub extern "C" fn avrai_trajectory_kernel_invoke_json(request_ptr: *const c_char) -> *mut c_char {
    let response = match parse_request(request_ptr).and_then(handle_request) {
        Ok(response) => response,
        Err(error) => NativeResponse {
            ok: false,
            handled: false,
            payload: Value::Null,
            error: Some(error),
        },
    };
    into_c_string(response)
}

#[no_mangle]
pub extern "C" fn avrai_trajectory_kernel_free_string(ptr: *mut c_char) {
    if ptr.is_null() {
        return;
    }
    unsafe {
        let _ = CString::from_raw(ptr);
    }
}

fn parse_request(request_ptr: *const c_char) -> Result<NativeRequest, String> {
    if request_ptr.is_null() {
        return Err("request pointer was null".to_string());
    }
    let request_json = unsafe { CStr::from_ptr(request_ptr) }
        .to_str()
        .map_err(|error| format!("request utf8 decode failed: {error}"))?;
    serde_json::from_str::<NativeRequest>(request_json)
        .map_err(|error| format!("request json decode failed: {error}"))
}

fn handle_request(request: NativeRequest) -> Result<NativeResponse, String> {
    let payload = match request.syscall.as_str() {
        "append_mutation" => serde_json::to_value(append_mutation(&request.payload)?),
        "replay_subject" => serde_json::to_value(replay_subject(&request.payload)?),
        "hydrate_vibe_snapshot" => serde_json::to_value(hydrate_vibe_snapshot(&request.payload)?),
        "export_journal_window" => serde_json::to_value(export_journal_window(&request.payload)?),
        "import_journal_window" => serde_json::to_value(import_journal_window(&request.payload)?),
        "diagnostics" => Ok(diagnostics()),
        _ => {
            return Ok(NativeResponse {
                ok: true,
                handled: false,
                payload: Value::Null,
                error: None,
            })
        }
    }
    .map_err(|error| format!("trajectory payload encode failed: {error}"))?;

    Ok(NativeResponse {
        ok: true,
        handled: true,
        payload,
        error: None,
    })
}

fn append_mutation(payload: &Map<String, Value>) -> Result<Value, String> {
    let record: TrajectoryMutationRecord =
        deserialize_required(payload.get("record").cloned(), "missing record")?;
    let key = subject_key(&record.subject_ref);
    JOURNALS
        .get_or_init(|| Mutex::new(HashMap::new()))
        .lock()
        .expect("trajectory journal lock")
        .entry(key)
        .or_default()
        .push(record.clone());

    if let Some(snapshot) = payload.get("checkpoint_snapshot").cloned() {
        let checkpoint = TrajectoryHydrationCheckpoint {
            checkpoint_id: format!("checkpoint:{}", record.record_id),
            subject_ref: record.subject_ref.clone(),
            snapshot,
            recorded_at_utc: now_iso(),
            source_record_ids: vec![record.record_id.clone()],
            metadata: Map::new(),
        };
        put_checkpoint(checkpoint);
    }

    Ok(json!({
        "record_id": record.record_id,
        "subject_id": record.subject_ref.subject_id,
        "accepted": true,
    }))
}

fn replay_subject(payload: &Map<String, Value>) -> Result<Vec<TrajectoryMutationRecord>, String> {
    let subject_ref: VibeSubjectRef =
        deserialize_required(payload.get("subject_ref").cloned(), "missing subject_ref")?;
    let limit = payload.get("limit").and_then(Value::as_u64).unwrap_or(256) as usize;
    let key = subject_key(&subject_ref);
    let records = JOURNALS
        .get_or_init(|| Mutex::new(HashMap::new()))
        .lock()
        .expect("trajectory journal lock")
        .get(&key)
        .cloned()
        .unwrap_or_default();
    Ok(take_tail(records, limit))
}

fn hydrate_vibe_snapshot(
    payload: &Map<String, Value>,
) -> Result<Option<TrajectoryHydrationCheckpoint>, String> {
    let subject_ref: VibeSubjectRef =
        deserialize_required(payload.get("subject_ref").cloned(), "missing subject_ref")?;
    let key = subject_key(&subject_ref);
    Ok(CHECKPOINTS
        .get_or_init(|| Mutex::new(HashMap::new()))
        .lock()
        .expect("trajectory checkpoint lock")
        .get(&key)
        .cloned())
}

fn export_journal_window(payload: &Map<String, Value>) -> Result<Vec<TrajectoryMutationRecord>, String> {
    let limit = payload.get("limit").and_then(Value::as_u64).unwrap_or(512) as usize;
    if let Some(subject_value) = payload.get("subject_ref").cloned() {
        let subject_ref: VibeSubjectRef =
            deserialize_required(Some(subject_value), "missing subject_ref")?;
        return replay_subject(&Map::from_iter(vec![
            ("subject_ref".to_string(), serde_json::to_value(subject_ref).unwrap()),
            ("limit".to_string(), Value::from(limit as u64)),
        ]));
    }

    let mut records = JOURNALS
        .get_or_init(|| Mutex::new(HashMap::new()))
        .lock()
        .expect("trajectory journal lock")
        .values()
        .flat_map(|entries| entries.clone())
        .collect::<Vec<_>>();
    records.sort_by(|left, right| left.occurred_at_utc.cmp(&right.occurred_at_utc));
    Ok(take_tail(records, limit))
}

fn import_journal_window(payload: &Map<String, Value>) -> Result<Value, String> {
    let reset_existing = payload
        .get("reset_existing")
        .and_then(Value::as_bool)
        .unwrap_or(true);
    let records: Vec<TrajectoryMutationRecord> = deserialize_required(
        payload.get("records").cloned(),
        "missing records",
    )?;
    let count = records.len();
    if reset_existing {
        JOURNALS
            .get_or_init(|| Mutex::new(HashMap::new()))
            .lock()
            .expect("trajectory journal lock")
            .clear();
        CHECKPOINTS
            .get_or_init(|| Mutex::new(HashMap::new()))
            .lock()
            .expect("trajectory checkpoint lock")
            .clear();
    }
    for record in records {
        let key = subject_key(&record.subject_ref);
        JOURNALS
            .get_or_init(|| Mutex::new(HashMap::new()))
            .lock()
            .expect("trajectory journal lock")
            .entry(key)
            .or_default()
            .push(record);
    }
    Ok(json!({
        "imported": count,
    }))
}

fn diagnostics() -> Value {
    let journal_subject_count = JOURNALS
        .get()
        .and_then(|store| store.lock().ok())
        .map(|store| store.len())
        .unwrap_or(0);
    let mutation_count = JOURNALS
        .get()
        .and_then(|store| store.lock().ok())
        .map(|store| store.values().map(|entries| entries.len()).sum::<usize>())
        .unwrap_or(0);
    let checkpoint_count = CHECKPOINTS
        .get()
        .and_then(|store| store.lock().ok())
        .map(|store| store.len())
        .unwrap_or(0);
    json!({
        "status": "ok",
        "kernel": "trajectory",
        "native_only": true,
        "journal_subject_count": journal_subject_count,
        "mutation_count": mutation_count,
        "checkpoint_count": checkpoint_count,
    })
}

fn put_checkpoint(checkpoint: TrajectoryHydrationCheckpoint) {
    let key = subject_key(&checkpoint.subject_ref);
    CHECKPOINTS
        .get_or_init(|| Mutex::new(HashMap::new()))
        .lock()
        .expect("trajectory checkpoint lock")
        .insert(key, checkpoint);
}

fn subject_key(subject_ref: &VibeSubjectRef) -> String {
    format!("{}::{}", subject_ref.kind, subject_ref.subject_id)
}

fn take_tail<T>(mut records: Vec<T>, limit: usize) -> Vec<T> {
    if records.len() <= limit {
        return records;
    }
    records.drain(records.len() - limit..).collect()
}

fn default_true() -> bool {
    true
}

fn default_governance_scope() -> String {
    "personal".to_string()
}

fn now_iso() -> String {
    Utc::now().to_rfc3339()
}

fn deserialize_required<T>(value: Option<Value>, missing_message: &str) -> Result<T, String>
where
    T: for<'de> Deserialize<'de>,
{
    serde_json::from_value(value.ok_or_else(|| missing_message.to_string())?)
        .map_err(|error| format!("trajectory decode failed: {error}"))
}

fn into_c_string(response: NativeResponse) -> *mut c_char {
    let json = serde_json::to_string(&response).unwrap_or_else(|error| {
        format!(
            r#"{{"ok":false,"handled":false,"payload":null,"error":"response encode failed: {error}"}}"#
        )
    });
    CString::new(json).expect("response CString").into_raw()
}

#[cfg(test)]
mod tests {
    use super::*;

    fn reset_state() {
        if let Some(store) = JOURNALS.get() {
            store.lock().expect("journal reset lock").clear();
        }
        if let Some(store) = CHECKPOINTS.get() {
            store.lock().expect("checkpoint reset lock").clear();
        }
    }

    fn subject_ref(subject_id: &str) -> VibeSubjectRef {
        VibeSubjectRef {
            subject_id: subject_id.to_string(),
            kind: "personal_agent".to_string(),
            entity_type: None,
            display_label: None,
        }
    }

    fn record(record_id: &str, subject_id: &str) -> TrajectoryMutationRecord {
        TrajectoryMutationRecord {
            record_id: record_id.to_string(),
            subject_ref: subject_ref(subject_id),
            category: "test".to_string(),
            occurred_at_utc: now_iso(),
            accepted: true,
            reason_codes: vec!["test".to_string()],
            governance_scope: "personal".to_string(),
            evidence_summary: Some("summary".to_string()),
            snapshot_updated_at_utc: Some(now_iso()),
            metadata: Map::new(),
        }
    }

    #[test]
    fn append_and_replay_records() {
        reset_state();
        let payload = Map::from_iter(vec![(
            "record".to_string(),
            serde_json::to_value(record("rec-1", "agent-1")).unwrap(),
        )]);
        append_mutation(&payload).expect("append");
        let replay = replay_subject(&Map::from_iter(vec![(
            "subject_ref".to_string(),
            serde_json::to_value(subject_ref("agent-1")).unwrap(),
        )]))
        .expect("replay");
        assert_eq!(replay.len(), 1);
        assert_eq!(replay[0].record_id, "rec-1");
    }

    #[test]
    fn checkpoint_hydrates_from_snapshot() {
        reset_state();
        append_mutation(&Map::from_iter(vec![
            (
                "record".to_string(),
                serde_json::to_value(record("rec-2", "agent-2")).unwrap(),
            ),
            (
                "checkpoint_snapshot".to_string(),
                json!({
                    "subject_id": "agent-2",
                    "subject_kind": "personal_agent",
                }),
            ),
        ]))
        .expect("append with checkpoint");

        let checkpoint = hydrate_vibe_snapshot(&Map::from_iter(vec![(
            "subject_ref".to_string(),
            serde_json::to_value(subject_ref("agent-2")).unwrap(),
        )]))
        .expect("hydrate")
        .expect("checkpoint");
        assert_eq!(checkpoint.subject_ref.subject_id, "agent-2");
    }
}

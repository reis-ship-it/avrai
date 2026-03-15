pub fn unsupported_syscall_response() -> crate::models::NativeResponse {
    crate::models::NativeResponse {
        ok: true,
        handled: false,
        payload: serde_json::Value::Null,
        error: None,
    }
}

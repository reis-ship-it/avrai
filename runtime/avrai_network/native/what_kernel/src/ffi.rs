use crate::models::{NativeRequest, NativeResponse};
use libc::c_char;
use std::ffi::{CStr, CString};

pub fn parse_request(request_ptr: *const c_char) -> Result<NativeRequest, String> {
    if request_ptr.is_null() {
        return Err("request pointer was null".to_string());
    }

    let request_json = unsafe { CStr::from_ptr(request_ptr) }
        .to_str()
        .map_err(|error| format!("request utf8 decode failed: {error}"))?;

    serde_json::from_str::<NativeRequest>(request_json)
        .map_err(|error| format!("request json decode failed: {error}"))
}

pub fn into_c_string(response: NativeResponse) -> *mut c_char {
    let encoded = serde_json::to_string(&response).unwrap_or_else(|error| {
        format!(
            "{{\"ok\":false,\"handled\":false,\"payload\":null,\"error\":\"response encode failed: {}\"}}",
            error
        )
    });
    CString::new(encoded).expect("response json cannot contain nulls").into_raw()
}

pub fn free_c_string(ptr: *mut c_char) {
    if ptr.is_null() {
        return;
    }
    unsafe {
        let _ = CString::from_raw(ptr);
    }
}

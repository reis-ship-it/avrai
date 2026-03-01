// Build script for flutter_rust_bridge code generation
use std::process::Command;

fn main() {
    // Tell Cargo to rerun this build script if these files change
    println!("cargo:rerun-if-changed=src/api.rs");
    
    // Generate bindings using flutter_rust_bridge_codegen command-line tool
    // Using the new module-based syntax (crate::api instead of file paths)
    let output = Command::new("flutter_rust_bridge_codegen")
        .arg("generate")
        .arg("--rust-input")
        .arg("crate::api")
        .arg("--rust-root")
        .arg(".")
        .arg("--dart-output")
        .arg("../../packages/spots_knot/lib/services/knot/bridge/knot_math_bridge.dart")
        .current_dir(".")
        .output()
        .expect("Failed to execute flutter_rust_bridge_codegen. Make sure it's installed: cargo install flutter_rust_bridge_codegen");
    
    if !output.status.success() {
        eprintln!("stdout: {}", String::from_utf8_lossy(&output.stdout));
        eprintln!("stderr: {}", String::from_utf8_lossy(&output.stderr));
        panic!("flutter_rust_bridge_codegen failed with status: {:?}", output.status);
    }
    
    println!("✅ flutter_rust_bridge bindings generated successfully");
}

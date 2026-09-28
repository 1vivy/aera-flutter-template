//! What Dart calls on native targets. `lib/native/native_io.dart` hands
//! these to `SurfaceConfig` as the core binding and the ops transport; on
//! the web the same core runs as `core.wasm` and ops go to the worker.
//!
//! Add typed functions of your own next to this file; run
//! `flutter_rust_bridge_codegen generate` after changing them.

use std::sync::LazyLock;

use surfaces_ops::local::Runner;

static OPS: LazyLock<Runner> = LazyLock::new(|| Runner::new(app_core::AppOps));

#[flutter_rust_bridge::frb(init)]
pub fn init_app() {
    flutter_rust_bridge::setup_default_user_utils();
}

#[flutter_rust_bridge::frb(sync)]
pub fn core_call(request: String) -> String {
    surfaces_core::abi::call_json(&request, app_core::call)
}

#[flutter_rust_bridge::frb(sync)]
pub fn core_bytes(request: String) -> Vec<u8> {
    surfaces_core::abi::call_bytes(&request, app_core::bytes)
}

#[flutter_rust_bridge::frb(sync)]
pub fn ops_call(request: String) -> String {
    OPS.call(&request)
}

#[flutter_rust_bridge::frb(sync)]
pub fn ops_start(request: String) -> String {
    OPS.start(&request)
}

#[flutter_rust_bridge::frb(sync)]
pub fn ops_poll(id: String) -> String {
    OPS.poll(&id)
}

#[flutter_rust_bridge::frb(sync)]
pub fn ops_cancel(id: String) -> String {
    OPS.cancel(&id)
}

//! The app's own Rust, shared by every target.
//!
//! - [`call`] and [`bytes`] are the **core**: fast, pure work Dart calls
//!   synchronously as `Surface.instance.core.call('greet', {...})`. Natively
//!   through flutter_rust_bridge, on the web as `core.wasm`.
//! - [`AppOps`] is the **ops** handler: privileged or long work, run as root
//!   by the worker on WebUI and in-process on AERA and desktop. Dart calls it
//!   as `Surface.instance.ops.call('app.count', {...})` or `.start(...)` for
//!   a job with progress.

use serde::Deserialize;
use serde_json::{json, Value};
use surfaces_core::{OpError, Request};
use surfaces_ops::{builtin, input, Handler, JobCtx};

/// The core's JSON calls.
pub fn call(request: &Request) -> Result<Value, OpError> {
    match request.op.as_str() {
        "greet" => {
            #[derive(Deserialize)]
            struct Greet {
                name: String,
            }
            let args: Greet = serde_json::from_value(request.input.clone())
                .map_err(|e| OpError::new("input", e.to_string()))?;
            Ok(json!(format!("Hello, {}! (from Rust)", args.name)))
        }
        "sha256" => {
            let text = request.input.as_str().unwrap_or_default();
            Ok(json!(surfaces_core::hash::sha256_hex(text.as_bytes())))
        }
        other => Err(OpError::new("unknown-op", format!("The core has no {other}"))),
    }
}

/// The core's binary calls.
pub fn bytes(request: &Request) -> Result<Vec<u8>, OpError> {
    Err(OpError::new("unknown-op", format!("The core has no {}", request.op)))
}

#[cfg(target_family = "wasm")]
surfaces_core::export_wasm_core!(crate::call, crate::bytes);

/// The app's ops. Unknown ops fall through to the built-ins (`sys.info`,
/// `fs.stat`, `fs.list`, `fs.hash`, `sys.wait`).
pub struct AppOps;

#[derive(Deserialize)]
struct Count {
    #[serde(default = "five")]
    to: u32,
}

fn five() -> u32 {
    5
}

impl Handler for AppOps {
    fn call(&self, request: &Request, job: &JobCtx) -> Result<Value, OpError> {
        match request.op.as_str() {
            // A sample job: counts, reporting progress, and stops when asked.
            "app.count" => {
                let args: Count = input(request)?;
                for i in 0..args.to {
                    job.check()?;
                    job.progress(i as f64 / args.to as f64, format!("{i} of {}", args.to));
                    #[cfg(not(target_family = "wasm"))]
                    std::thread::sleep(std::time::Duration::from_millis(500));
                }
                Ok(json!({ "counted": args.to }))
            }
            _ => builtin::call(request, job),
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn core_and_ops() {
        let greeting = call(&Request::new("greet", json!({"name": "Ada"}))).unwrap();
        assert_eq!(greeting, "Hello, Ada! (from Rust)");
        assert!(call(&Request::new("nope", Value::Null)).is_err());
        let counted = AppOps.call(&Request::new("app.count", json!({"to": 1})), &JobCtx::none()).unwrap();
        assert_eq!(counted["counted"], 1);
        let info = AppOps.call(&Request::new("sys.info", Value::Null), &JobCtx::none()).unwrap();
        assert!(info["os"].is_string());
    }
}

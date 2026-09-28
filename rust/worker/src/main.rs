//! The ops worker a WebUI module runs as root over `ksu.exec`
//! (`$MODDIR/bin/worker`). All the work is in `app_core::AppOps`; the same
//! handler runs in-process on AERA and desktop.

fn main() {
    surfaces_ops::worker::main(app_core::AppOps)
}

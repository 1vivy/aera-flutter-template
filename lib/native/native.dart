/// The app's Rust on native targets (AERA, desktop, Android), through
/// flutter_rust_bridge. On the web the core is `core.wasm` and ops go to the
/// module's worker, so there is nothing to load here.
library;

export 'native_web.dart' if (dart.library.io) 'native_io.dart';

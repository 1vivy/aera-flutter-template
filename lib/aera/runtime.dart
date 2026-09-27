import 'dart:io';

import 'package:flutter_rust_bridge/flutter_rust_bridge_for_generated.dart';

import '../src/rust/frb_generated.dart';

/// Loads the app's Rust library and starts flutter_rust_bridge.
///
/// The library sits at `usr/lib/libaera_app_core.so` in the app's payload,
/// which AERA (and `aera-host-sim` on a PC) names in `AERA_PLUGIN_ROOT`. With
/// `flutter run -d linux` neither exists and flutter_rust_bridge's own
/// loader finds the library that cargokit built.
Future<void> initAera() async {
  final root = Platform.environment['AERA_PLUGIN_ROOT'] ?? '/';
  final bundled = File('$root/usr/lib/libaera_app_core.so');
  await RustLib.init(
    externalLibrary: bundled.existsSync()
        ? ExternalLibrary.open(bundled.path)
        : null,
  );
}

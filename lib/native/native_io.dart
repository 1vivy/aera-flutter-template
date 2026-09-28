import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_rust_bridge/flutter_rust_bridge_for_generated.dart';
import 'package:surfaces/surfaces.dart';

import '../src/rust/api/surfaces.dart';
import '../src/rust/frb_generated.dart';

/// Loads the app's Rust library and hands its core and ops to surfaces.
///
/// Inside AERA the library is `/usr/lib/libapp_native.so` in the app's
/// payload; under the AERA simulator the payload's root is in
/// `AERA_FLUTTER_ROOT`. Elsewhere flutter_rust_bridge finds the library
/// cargokit built. Without it (a plain `flutter test`) the app runs with no
/// core and no ops, and says so.
Future<SurfaceConfig> withNative(SurfaceConfig config) async {
  final root = Platform.environment['AERA_FLUTTER_ROOT'] ?? '/';
  final bundled = File('$root/usr/lib/libapp_native.so');
  try {
    await RustLib.init(
      externalLibrary: bundled.existsSync() ? ExternalLibrary.open(bundled.path) : null,
    );
  } catch (error) {
    debugPrint('No Rust library: $error');
    return config;
  }
  return SurfaceConfig(
    appId: config.appId,
    appName: config.appName,
    workerName: config.workerName,
    coreWasm: config.coreWasm,
    nativeCore: FunctionCoreBinding(
      call: (request) => coreCall(request: request),
      bytes: (request) => coreBytes(request: request),
    ),
    nativeOps: FunctionOpsTransport(
      call: (request) => opsCall(request: request),
      start: (request) => opsStart(request: request),
      poll: (id) => opsPoll(id: id),
      cancel: (id) => opsCancel(id: id),
    ),
  );
}

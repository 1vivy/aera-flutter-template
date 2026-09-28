import 'package:surfaces/surfaces.dart';

/// On the web `package:surfaces_webui` finds the core and the worker itself.
Future<SurfaceConfig> withNative(SurfaceConfig config) async => config;

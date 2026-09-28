# surfaces template-app

The smallest [surfaces](https://github.com/1vivy/aera-flutter-sdk) app: one
Flutter app with a Rust core that builds for every target surfaces has.

| Target | Command | Output |
| --- | --- | --- |
| KernelSU / SukiSU / KernelSU Next / APatch / WebUI X module | `dart run surfaces_cli:surfaces build webui` | `build/webui/<id>-<version>.zip` |
| Hosted web page (bottom rung of the WebUI ladder) | `dart run surfaces_cli:surfaces build web` | `build/web/`, `build/<id>-<version>-web.zip` |
| AERA Recovery app slot | `dart run surfaces_cli:surfaces build aera` | `build/aera/<name>-<version>.aerap` |
| Linux desktop | `dart run surfaces_cli:surfaces build linux` | `build/<id>-<version>-linux-x64.tar.gz` |
| Android | `flutter build apk` | the usual APK |
| Everything but Android | `dart run surfaces_cli:surfaces build all` | all of the above |

Try a WebUI build on a PC before installing it:

```sh
dart run surfaces_cli:surfaces serve                 # as WebUI X, commands run in .dart_tool/surfaces/device
dart run surfaces_cli:surfaces serve --host kernelsu # or next, apatch, standalone, browser
dart run surfaces_cli:surfaces serve --adb           # commands run on a rooted phone over adb
dart run surfaces_cli:surfaces sim                   # the AERA simulator; frames land in build/aera/frames
dart run surfaces_cli:surfaces doctor                # which tools each target needs
```

## Make it yours

1. Pick an id (letters, digits, `.`, `_`, `-`) and put it in `surfaces.yaml`
   and in `SurfaceConfig(appId: ...)` in `lib/main.dart`. On WebUI hosts it is
   the module id.
2. Rename the package in `pubspec.yaml`, `linux/CMakeLists.txt` and
   `android/app/build.gradle.kts` if you like.
3. Write the UI in `lib/`. `Surface.instance` is the host: window, Back,
   storage, files, toasts, theme, apps, shell, ops and the Rust core, each
   with a fallback where the host lacks it. Check `Surface.instance.info.has(Cap.x)`
   to show what is missing.

## Where things go

- `lib/main.dart`: `Surface.init(...)` with the backends this app targets
  (`WebUiBackend`, `AeraBackend`; desktop and tests fall back to `dart:io`).
- `lib/native/`: loads the Rust library on native targets.
- `rust/core/` (`app_core`): the app's Rust. `call`/`bytes` are the **core**
  (sync, pure; `core.wasm` on the web). `AppOps` is the **ops** handler
  (privileged or long work: the root worker on WebUI, in-process elsewhere).
- `rust/worker/`: the WebUI module's root worker, a static musl binary.
- `rust/src/api/`: the flutter_rust_bridge API for native targets. Run
  `flutter_rust_bridge_codegen generate` after changing it.
- `web/`: the page. It works on every WebUI host: no CDN, no service worker,
  an ES5 fallback page for ancient WebViews.
- `webui/`: the module files around the web build (see its README).

## What you need

- Flutter 3.47.5 (AERA's kits are tied to this release)
- Rust with `wasm32-unknown-unknown` and the `*-linux-musl` targets (the CLI
  adds them), `zip`; for AERA also `xz` and `aarch64-linux-gnu-gcc`
- `flutter_rust_bridge_codegen` 2.13.0 when you change `rust/src/api`

The surfaces packages come from git, pinned to one commit in `pubspec.yaml`.
To work on surfaces itself next to this app, add a `pubspec_overrides.yaml`
(ignored by git) with path overrides.

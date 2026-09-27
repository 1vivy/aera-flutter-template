# AERA Flutter template

A Flutter app with a Rust core (flutter_rust_bridge) that runs **inside AERA
Recovery**, drawn with the phone's GPU.

AERA gives the GPU only to its browser slot, so the app is packaged as an
unofficial plugin with the `browser` ID. Installing it replaces AERA Browser
on that phone until the official browser is reinstalled. AERA shows its own
address bar and dock around the app.

## What you need

- Flutter 3.47.5 (the kits' engine is tied to this exact release)
- Rust with the `aarch64-unknown-linux-gnu` target and `aarch64-linux-gnu-gcc`
  (`sudo apt install gcc-aarch64-linux-gnu`, `rustup target add aarch64-unknown-linux-gnu`)
- `flutter_rust_bridge_codegen` 2.13.0 when you change the Rust API
- For the PC simulator: Mesa's EGL (`libegl1`, `libgles2`)

## Use it

```sh
tool/aera.sh sim                  # run on this PC in AERA's bridge; frames land in build/aera/frames
tool/aera.sh sim --until 5000 --tap 180,190@1000 --save-at 3000
tool/aera.sh package              # build/aera/<name>-<version>.aerap
AERA_RENDERER=impeller tool/aera.sh package   # build/aera/<name>-<version>-impeller.aerap
AERA_MODE=debug tool/aera.sh package          # build/aera/<name>-<version>-debug.aerap
```

`package` makes a release build: the Dart code is AOT-compiled into
`libapp.so` (`tool/build_aot_app.sh`) and runs on the release engine from the
kits release. `AERA_MODE=profile` or `debug` makes the others; `sim` always
runs a debug build.

`AERA_RENDERER` picks how the app draws: `gl` (the default, Skia on OpenGL
ES through Zink), `vulkan` (Skia straight on the phone's Vulkan driver) or
`impeller` (Impeller on Vulkan). All three use the GPU.

The build is baked into the app: `String.fromEnvironment('AERA_APP_VERSION')`,
`'AERA_APP_BUILD'` (commit and time) and `'AERA_RENDERER'`. Showing them
helps on the phone, because AERA keeps the app running after a reinstall
until you clear it from Recents.

Copy the `.aerap` to the phone and install it from AERA's plugin screen. Name,
version and description come from `aera.json`. For fast UI work,
`flutter run -d linux` also works; AERA-only features then report that they
are unavailable.

## Where things go

- `lib/` Dart UI. `lib/aera/runtime.dart` loads the Rust library.
- `rust/src/api/` Rust functions Dart can call. After changing them run
  `flutter_rust_bridge_codegen generate`.
- `aera-sdk` (from [aera-flutter-sdk](https://github.com/1vivy/aera-flutter-sdk))
  is what reaches AERA: storage, device info, speaker audio, recovery language.

## Inside AERA

The app runs in AERA's browser jail: its own payload as `/`, no root, network
but no listening sockets, `/profile` for private files, `/downloads` for
`/sdcard/AERA/Downloads`, 512 MB of `/tmp`, about 1.5 GB of memory. The screen
is 1080x2100 at 3x (360x700 logical pixels). The Back button pops the
navigator.

Packaged builds are release (AOT) by default; the kits and engines come from
[aera-flutter-embedder](https://github.com/1vivy/aera-flutter-embedder)
releases.

# AERA Flutter template

A Flutter app with a Rust core (flutter_rust_bridge) that runs **inside AERA
Recovery**, drawn with the phone's GPU, full screen under its own plugin ID.

> **This branch targets AERA's generic pixel + GPU plugin host, which is
> not released yet.** An AERA maintainer is adding it; until it ships, the
> interface here is assumed and `.aerap` files from this branch will not
> install on current nightlies. What we need from the host is tracked in
> [aera-flutter-demo#1](https://github.com/1vivy/aera-flutter-demo/issues/1).
> The `main` branch keeps the working stopgap that borrows AERA Browser's slot.

## What you need

- Flutter 3.47.5 (the kits' engine is tied to this exact release)
- Rust with the `aarch64-unknown-linux-gnu` target and `aarch64-linux-gnu-gcc`
  (`sudo apt install gcc-aarch64-linux-gnu`, `rustup target add aarch64-unknown-linux-gnu`)
- `flutter_rust_bridge_codegen` 2.13.0 when you change the Rust API
- For the PC simulator: Mesa's EGL (`libegl1`, `libgles2`)

## Use it

```sh
tool/aera.sh sim                  # run on this PC against a simulated AERA host; frames land in build/aera/frames
tool/aera.sh sim --until 5000 --tap 180,190@1000 --save-at 3000
tool/aera.sh package              # build/aera/<name>-<version>.aerap
```

Copy the `.aerap` to the phone and install it from AERA's plugin screen. ID,
name, version and description come from `aera.json`. Pick your own `id`
(lowercase letters, digits, `-` and `.`). Set `"privileged": true` only if the
app needs recovery's own access (partitions, `/data`, `/sys`); it is an opt-in
the user has to grant. For fast UI work,
`flutter run -d linux` also works; AERA-only features then report that they
are unavailable.

## Where things go

- `lib/` Dart UI. `lib/aera/runtime.dart` loads the Rust library.
- `rust/src/api/` Rust functions Dart can call. After changing them run
  `flutter_rust_bridge_codegen generate`.
- `aera-sdk` (from [aera-flutter-sdk](https://github.com/1vivy/aera-flutter-sdk))
  is what reaches AERA: storage, device info, speaker audio, recovery language.

## Inside AERA

AERA starts the app's `usr/bin/aera-plugin`, which runs the Flutter embedder
on a full-screen pixel surface. AERA tells the app the surface size and scale
at start, so don't assume a fixed screen. The Back gesture pops the navigator,
and popping the last route closes the app. Storage and audio paths come from
`aera-sdk`, which follows whatever the host hands out.

Builds are debug (JIT) for now; the kits come from
[aera-flutter-embedder](https://github.com/1vivy/aera-flutter-embedder)
releases.

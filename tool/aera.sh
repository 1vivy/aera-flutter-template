#!/usr/bin/env bash
# Build and run this app for AERA Recovery.
#
#   tool/aera.sh sim [simulator options]   run it on this PC against a simulated AERA host
#   tool/aera.sh package                   build build/aera/<name>-<version>.aerap
#   tool/aera.sh fetch                     only download the kits
#
# The kits come from github.com/1vivy/aera-flutter-embedder generic-host
# releases (built for AERA's upcoming pixel + GPU host) and must
# match your Flutter release, because the engine inside them is a debug (JIT)
# engine. Set AERA_KIT_DIR to a folder holding the .tar.xz files to skip the
# download. `sim` passes its options to aera-host-sim, for example
# `--until 5000 --tap 180,350@1000 --save-at 3000 --size 1080x2400`.
set -euo pipefail

root=$(cd "$(dirname "$0")/.." && pwd)
cd "$root"
crate=aera_app_core
out=build/aera

flutter_version=$(flutter --version --machine | python3 -c 'import json,sys; print(json.load(sys.stdin)["frameworkVersion"])')
kits=.aera/$flutter_version
release=${AERA_KIT_URL:-https://github.com/1vivy/aera-flutter-embedder/releases/download/generic-host-flutter-$flutter_version}

manifest() { python3 -c "import json; print(json.load(open('aera.json')).get('$1', ''))"; }

fetch_kit() { # kit-name -> extracted directory
    local name=$1 dir=$kits/$1
    if [ ! -f "$dir/flutter-version" ]; then
        local file=aera-flutter-$name-$flutter_version.tar.xz
        mkdir -p "$kits"
        if [ -n "${AERA_KIT_DIR:-}" ] && [ -f "$AERA_KIT_DIR/$file" ]; then
            cp "$AERA_KIT_DIR/$file" "$kits/$file"
        else
            echo "Downloading $file" >&2
            curl -fL --retry 3 -o "$kits/$file" "$release/$file" || {
                echo "No $name kit for Flutter $flutter_version. Use the Flutter release a kit exists for." >&2
                exit 1
            }
        fi
        rm -rf "$dir.new" && mkdir -p "$dir.new"
        tar -C "$dir.new" -xJf "$kits/$file"
        rm -f "$kits/$file"
        mv "$dir.new" "$dir"
    fi
    if [ "$(cat "$dir/flutter-version")" != "$flutter_version" ]; then
        echo "$dir was made for Flutter $(cat "$dir/flutter-version"), not $flutter_version" >&2
        exit 1
    fi
    echo "$dir"
}

bundle() {
    flutter build bundle --debug >&2
}

case ${1:-} in
fetch)
    fetch_kit runtime-arm64 >/dev/null
    fetch_kit simkit-x64 >/dev/null
    ;;

sim)
    shift
    kit=$(fetch_kit simkit-x64)
    bundle
    cargo build --release --manifest-path rust/Cargo.toml >&2
    stage=$out/sim
    rm -rf "$stage" && mkdir -p "$stage/usr/bin" "$stage/usr/lib" "$stage/usr/share/flutter"
    cp "$kit/bin/aera-plugin" "$kit/bin/aera-flutter" "$stage/usr/bin/"
    cp "$kit/usr/lib/libflutter_engine.so" "rust/target/release/lib$crate.so" "$stage/usr/lib/"
    cp "$kit/usr/share/flutter/icudtl.dat" "$stage/usr/share/flutter/"
    cp -r build/flutter_assets "$stage/usr/share/flutter/flutter_assets"
    mkdir -p "$out/frames"
    # llvmpipe's threads crash under the embedder on some PCs; softpipe is
    # slow but steady. On the phone AERA uses Zink on the GPU instead.
    GALLIUM_DRIVER=${GALLIUM_DRIVER:-softpipe} "$kit/bin/aera-host-sim" \
        --plugin "$stage/usr/bin/aera-plugin" --root "$(pwd)/$stage" --out "$out/frames" "$@"
    echo "Frames are in $out/frames" >&2
    ;;

package)
    kit=$(fetch_kit runtime-arm64)
    bundle
    cargo build --release --target aarch64-unknown-linux-gnu --manifest-path rust/Cargo.toml >&2
    library=rust/target/aarch64-unknown-linux-gnu/release/lib$crate.so
    stage=$out/stage
    rm -rf "$stage" && cp -a "$kit" "$stage"
    rm -f "$stage/flutter-version" "$stage/engine-revision"
    cp -r build/flutter_assets "$stage/usr/share/flutter/flutter_assets"
    cp "$library" "$stage/usr/lib/"
    # Anything the Rust library links must already be in the runtime.
    readelf=$(command -v aarch64-linux-gnu-readelf || command -v readelf)
    for lib in $("$readelf" -d "$library" | sed -n 's/.*(NEEDED).*\[\(.*\)\]/\1/p'); do
        if [ ! -e "$stage/usr/lib/$lib" ] && [ ! -e "$stage/lib/$lib" ]; then
            echo "lib$crate.so needs $lib, which the AERA runtime does not ship" >&2
            exit 1
        fi
    done
    name=$(manifest name) version=$(manifest version)
    privileged=()
    [ "$(manifest privileged)" = True ] && privileged=(--privileged)
    python3 tool/make_aerap.py --stage "$stage" --id "$(manifest id)" --name "$name" --version "$version" \
        --description "$(manifest description)" "${privileged[@]}" --out "$out/${name// /-}-$version.aerap"
    ;;

*)
    sed -n '2,13p' "$0" | sed 's/^# \{0,1\}//'
    exit 2
    ;;
esac

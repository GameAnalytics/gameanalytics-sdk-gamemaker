#!/bin/bash
#
# Builds libGameAnalytics.dylib for the GameMaker extension: the C++ SDK as a
# static library, linked together with GameAnalyticsGM.cpp into one universal
# dynamic library.
#
# Dynamic is not a choice here — GameMaker loads desktop extension libraries at
# runtime (dlopen/LoadLibrary), so a static archive cannot be used. Linking the
# SDK in statically keeps it to a single file with no install-name or search
# path to get wrong, which is how the extension has always shipped.
#
# Usage: ./build_macos.sh [path-to-gameanalytics-sdk-cpp] [output-dir]
#
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SDK_DIR="${1:-$HERE/../../../../../gameanalytics-sdk-cpp}"
OUT_DIR="${2:-$HERE/..}"
BUILD_DIR="${BUILD_DIR:-$(mktemp -d)/ga-build}"

if [ ! -f "$SDK_DIR/CMakeLists.txt" ]; then
    echo "error: C++ SDK not found at $SDK_DIR" >&2
    echo "usage: $0 [path-to-gameanalytics-sdk-cpp] [output-dir]" >&2
    exit 1
fi

SDK_DIR="$(cd "$SDK_DIR" && pwd)"
OUT_DIR="$(cd "$OUT_DIR" && pwd)"

echo "SDK sources : $SDK_DIR"
echo "build dir   : $BUILD_DIR"
echo "output      : $OUT_DIR/libGameAnalytics.dylib"

# 1. Static, universal build of the SDK. GA_HTTP_USE_CURL=OFF keeps it to
#    system frameworks only, so the result has no third-party dependencies.
cmake -S "$SDK_DIR" -B "$BUILD_DIR" \
    -DCMAKE_BUILD_TYPE=Release \
    -DGA_SHARED_LIB=OFF \
    -DGA_BUILD_SAMPLE=OFF \
    -DUSE_VCPKG=OFF \
    -DGA_HTTP_USE_CURL=OFF \
    -DCMAKE_OSX_ARCHITECTURES="x86_64;arm64" \
    -DCMAKE_OSX_DEPLOYMENT_TARGET=11.0

cmake --build "$BUILD_DIR" --target GameAnalytics -j "$(sysctl -n hw.ncpu)"

STATIC_LIB="$BUILD_DIR/Release/libGameAnalytics.a"
[ -f "$STATIC_LIB" ] || STATIC_LIB="$BUILD_DIR/libGameAnalytics.a"

# 2. The GameMaker entry points, linked against it.
clang++ -std=c++17 -O2 -dynamiclib \
    -arch x86_64 -arch arm64 \
    -mmacosx-version-min=11.0 \
    -install_name "@rpath/libGameAnalytics.dylib" \
    -I "$SDK_DIR/include" \
    -I "$HERE" \
    -I "$SDK_DIR/source/gameanalytics" \
    -I "$SDK_DIR/source/dependencies" \
    -o "$OUT_DIR/libGameAnalytics.dylib" \
    "$HERE/GameAnalyticsGM.cpp" \
    "$HERE/GameAnalyticsHttpGM.cpp" \
    -Wl,-force_load,"$STATIC_LIB" \
    -framework CoreFoundation \
    -framework Foundation \
    -framework CoreServices \
    -framework SystemConfiguration \
    -framework Metal \
    -framework MetalKit \
    -lz -lc++

echo
lipo -info "$OUT_DIR/libGameAnalytics.dylib"
echo "exported GameMaker entry points: $(nm -gU "$OUT_DIR/libGameAnalytics.dylib" | grep -c ' T _')"

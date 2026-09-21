#!/bin/bash
#
# Builds libGameAnalytics.so for the GameMaker extension. Run on Linux (or in a
# Linux container); requires cmake, a C++17 compiler and zlib headers
# (apt: build-essential cmake zlib1g-dev).
#
# Usage: ./build_linux.sh [path-to-gameanalytics-sdk-cpp]
#
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SDK_DIR="${1:-$HERE/../../../../../gameanalytics-sdk-cpp}"
BUILD_DIR="${BUILD_DIR:-$HERE/build-linux}"

cmake -S "$HERE" -B "$BUILD_DIR" -DCMAKE_BUILD_TYPE=Release -DGA_SDK_DIR="$SDK_DIR"
cmake --build "$BUILD_DIR" -j "$(nproc)"

echo
echo "built: $HERE/../libGameAnalytics.so"
nm -D --defined-only "$HERE/../libGameAnalytics.so" | grep -c " T " || true

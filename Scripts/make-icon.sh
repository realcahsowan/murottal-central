#!/usr/bin/env bash
#
# Membuat Resources/AppIcon.icns dari ikon yang digambar oleh
# Scripts/GenerateIcon.swift.
#
# Pemakaian: Scripts/make-icon.sh

set -euo pipefail

cd "$(dirname "$0")/.."

BUILD_DIR="build"
ICONSET="$BUILD_DIR/AppIcon.iconset"
SOURCE_PNG="$BUILD_DIR/icon-1024.png"

mkdir -p "$BUILD_DIR"
rm -rf "$ICONSET"
mkdir -p "$ICONSET"

echo "→ Menggambar ikon 1024×1024…"
swift Scripts/GenerateIcon.swift "$SOURCE_PNG"

echo "→ Membuat ukuran iconset…"
for size in 16 32 128 256 512; do
    sips -z "$size" "$size" "$SOURCE_PNG" --out "$ICONSET/icon_${size}x${size}.png" >/dev/null
    double=$((size * 2))
    sips -z "$double" "$double" "$SOURCE_PNG" --out "$ICONSET/icon_${size}x${size}@2x.png" >/dev/null
done

echo "→ Menyusun AppIcon.icns…"
mkdir -p Resources
iconutil -c icns "$ICONSET" -o Resources/AppIcon.icns

echo "✓ Selesai: Resources/AppIcon.icns"

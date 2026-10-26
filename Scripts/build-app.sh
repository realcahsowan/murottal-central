#!/usr/bin/env bash
#
# Membangun MurottalCentral.app dari Swift Package.
#
# Pemakaian:
#   Scripts/build-app.sh                 # release, ad-hoc sign (dev lokal)
#   CONFIG=debug Scripts/build-app.sh    # debug
#
#   # Distribusi (butuh Developer ID):
#   CODESIGN_IDENTITY="Developer ID Application: Nama (TEAMID)" \
#   ENTITLEMENTS_FILE="Resources/MurottalCentral.entitlements" \
#   Scripts/build-app.sh
#
# Hasil: build/MurottalCentral.app

set -euo pipefail

cd "$(dirname "$0")/.."

CONFIG="${CONFIG:-release}"
APP_NAME="MurottalCentral"
BUNDLE="build/${APP_NAME}.app"
SIGN_ID="${CODESIGN_IDENTITY:--}"
ENTITLEMENTS_FILE="${ENTITLEMENTS_FILE:-}"
ARCHS="${ARCHS:-arm64 x86_64}"

ARCH_FLAGS=()
for arch in $ARCHS; do
    ARCH_FLAGS+=(--arch "$arch")
done

echo "→ Membangun (${CONFIG}, arch: ${ARCHS})…"
swift build -c "$CONFIG" "${ARCH_FLAGS[@]}" --product "$APP_NAME"
BIN_PATH="$(swift build -c "$CONFIG" "${ARCH_FLAGS[@]}" --product "$APP_NAME" --show-bin-path)/${APP_NAME}"

if [ ! -x "$BIN_PATH" ]; then
    echo "✗ Biner tidak ditemukan: $BIN_PATH" >&2
    exit 1
fi

echo "→ Menyusun bundle…"
rm -rf "$BUNDLE"
mkdir -p "$BUNDLE/Contents/MacOS" "$BUNDLE/Contents/Resources"

cp "$BIN_PATH" "$BUNDLE/Contents/MacOS/$APP_NAME"
cp Resources/Info.plist "$BUNDLE/Contents/Info.plist"

# Salin resource bundle SwiftPM (font Qur'an) agar Bundle.module menemukannya.
BIN_DIR="$(dirname "$BIN_PATH")"
for bundle in "$BIN_DIR"/*.bundle; do
    if [ -d "$bundle" ]; then
        cp -R "$bundle" "$BUNDLE/Contents/Resources/"
    fi
done

if [ -f Resources/AppIcon.icns ]; then
    cp Resources/AppIcon.icns "$BUNDLE/Contents/Resources/AppIcon.icns"
else
    echo "  (catatan: Resources/AppIcon.icns belum ada — jalankan Scripts/make-icon.sh)"
fi

echo "→ Menandatangani (identity: ${SIGN_ID})…"
SIGN_ARGS=(--force --sign "$SIGN_ID")
if [ -n "$ENTITLEMENTS_FILE" ] && [ -f "$ENTITLEMENTS_FILE" ]; then
    SIGN_ARGS+=(--entitlements "$ENTITLEMENTS_FILE")
fi
if [ "$SIGN_ID" != "-" ]; then
    SIGN_ARGS+=(--options runtime --timestamp)
fi
codesign "${SIGN_ARGS[@]}" "$BUNDLE"

echo "→ Verifikasi tanda tangan…"
codesign --verify --deep --strict --verbose=2 "$BUNDLE" 2>&1 | tail -3 || true

echo "→ Arsitektur biner:"
lipo -info "$BUNDLE/Contents/MacOS/$APP_NAME"

echo "✓ Selesai: $BUNDLE"

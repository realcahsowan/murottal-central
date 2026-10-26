#!/usr/bin/env bash
#
# Membuat installer .dmg dari bundle .app.
#
# Pemakaian:
#   Scripts/build-app.sh && Scripts/package-dmg.sh
#
# Hasil: build/MurottalCentral-<versi>.dmg

set -euo pipefail

cd "$(dirname "$0")/.."

APP_NAME="MurottalCentral"
APP="build/${APP_NAME}.app"

if [ ! -d "$APP" ]; then
    echo "✗ $APP tidak ada. Jalankan Scripts/build-app.sh dulu." >&2
    exit 1
fi

VERSION="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$APP/Contents/Info.plist" 2>/dev/null || echo "0.0.0")"
DMG="build/${APP_NAME}-${VERSION}.dmg"

echo "→ Menyiapkan isi DMG…"
STAGE="$(mktemp -d)"
cp -R "$APP" "$STAGE/"
ln -s /Applications "$STAGE/Applications"

echo "→ Membuat DMG…"
rm -f "$DMG"
hdiutil create \
    -volname "Murottal Central" \
    -srcfolder "$STAGE" \
    -ov -format UDZO \
    "$DMG" >/dev/null

rm -rf "$STAGE"

echo "✓ Selesai: $DMG"

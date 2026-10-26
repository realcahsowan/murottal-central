#!/usr/bin/env bash
#
# Mengirim DMG ke Apple untuk notarization dan men-staple hasilnya.
#
# Prasyarat:
#   1. Akun Apple Developer Program.
#   2. Sertifikat "Developer ID Application".
#   3. Kredensial notarytool tersimpan di keychain:
#
#        xcrun notarytool store-credentials "murottal-notary" \
#          --apple-id "you@example.com" \
#          --team-id "TEAMID" \
#          --password "app-specific-password"
#
# Pemakaian:
#   Scripts/build-app.sh && Scripts/package-dmg.sh && Scripts/notarize.sh
#
# Variabel opsional:
#   NOTARY_PROFILE  (default: murottal-notary)

set -euo pipefail

cd "$(dirname "$0")/.."

APP_NAME="MurottalCentral"
APP="build/${APP_NAME}.app"
NOTARY_PROFILE="${NOTARY_PROFILE:-murottal-notary}"

if [ ! -d "$APP" ]; then
    echo "✗ $APP tidak ada. Jalankan Scripts/build-app.sh dulu." >&2
    exit 1
fi

VERSION="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$APP/Contents/Info.plist" 2>/dev/null || echo "0.0.0")"
DMG="build/${APP_NAME}-${VERSION}.dmg"

if [ ! -f "$DMG" ]; then
    echo "✗ $DMG tidak ada. Jalankan Scripts/package-dmg.sh dulu." >&2
    exit 1
fi

echo "→ Mengirim $DMG ke Apple…"
xcrun notarytool submit "$DMG" --keychain-profile "$NOTARY_PROFILE" --wait

echo "→ Men-staple tiket ke DMG…"
xcrun stapler staple "$DMG"

echo "→ Verifikasi Gatekeeper…"
spctl --assess --type open --context context:primary-signature -v "$DMG" || true

echo "✓ Selesai: $DMG siap didistribusikan"

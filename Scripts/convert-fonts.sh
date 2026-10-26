#!/usr/bin/env bash
#
# Menyiapkan font Qur'an yang dibundel:
#   1. Amiri Quran (OFL 1.1) — untuk teks Uthmani.
#   2. IndoPak Nastaleeq (dari Quran Central, WOFF2 → TTF) — untuk teks IndoPak.
#
# Pemakaian: Scripts/convert-fonts.sh
# Hasil: Sources/MurottalCentralCore/Resources/Fonts/*.ttf
#
# Butuh: curl, python3 (venv), fonttools, brotli.
#
# Catatan: font KFGQPC Uthmanic Hafs **tidak dipakai** karena memetakan
# U+06DF dan U+0672 ke glyph `uni0600` (bulatan besar). Lihat docs/07 §3.1.

set -euo pipefail

cd "$(dirname "$0")/.."

OUT_DIR="Sources/MurottalCentralCore/Resources/Fonts"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

UA="Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0 Safari/537.36"

mkdir -p "$OUT_DIR"

echo "→ Mengunduh Amiri Quran (OFL)…"
curl -sL -A "$UA" \
    "https://raw.githubusercontent.com/google/fonts/main/ofl/amiriquran/AmiriQuran-Regular.ttf" \
    -o "$OUT_DIR/AmiriQuran-Regular.ttf"
curl -sL -A "$UA" \
    "https://raw.githubusercontent.com/google/fonts/main/ofl/amiriquran/OFL.txt" \
    -o "$OUT_DIR/AmiriQuran-OFL.txt"

echo "→ Mengunduh font IndoPak (WOFF2)…"
curl -sL -A "$UA" -H "Origin: https://qurancentral.com" -H "Referer: https://qurancentral.com/" \
    "https://data.qurancentral.com/fonts/indopak-nastaleeq-waqf-lazim-v4.2.1.woff2" \
    -o "$TMP_DIR/IndoPakNastaleeq.woff2"

echo "→ Menyiapkan fonttools…"
python3 -m venv "$TMP_DIR/venv" >/dev/null 2>&1
"$TMP_DIR/venv/bin/pip" install --quiet --disable-pip-version-check fonttools brotli

echo "→ Mengonversi WOFF2 → TTF…"
"$TMP_DIR/venv/bin/python" - "$TMP_DIR" "$OUT_DIR" <<'PY'
import sys
from pathlib import Path
from fontTools.ttLib import TTFont

tmp = Path(sys.argv[1])
out = Path(sys.argv[2])

font = TTFont(tmp / "IndoPakNastaleeq.woff2")
font.flavor = None
target = out / "IndoPakNastaleeq.ttf"
font.save(target)
print(f"  {target} ({target.stat().st_size} bytes)")
PY

echo "✓ Selesai. Font tersedia di $OUT_DIR"

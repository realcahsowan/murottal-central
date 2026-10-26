# 06 — Distribusi

Cara memaketkan, menandatangani, dan mendistribusikan Murottal Central.

## Ringkasan: agar bisa dipakai di Mac lain

Ada dua jalur.

### Jalur A — tanpa akun Apple (cepat, masih ada peringatan Gatekeeper)

1. Build **universal** (Apple Silicon + Intel) lalu buat DMG:
   ```bash
   Scripts/build-app.sh      # default ARCHS="arm64 x86_64"
   Scripts/package-dmg.sh
   ```
2. Salin `build/MurottalCentral-<versi>.dmg` ke Mac lain, buka, dan seret app
   ke **Applications**.
3. Karena ditandatangani **ad-hoc** dan belum dinotarisasi, macOS akan menolak
   saat pertama dibuka. Pilih salah satu:
   - **Klik kanan app → Open → Open**, atau
   - **System Settings → Privacy & Security → Open Anyway**, atau
   - Terminal:
     ```bash
     xattr -dr com.apple.quarantine /Applications/MurottalCentral.app
     ```
4. Syarat di Mac tujuan: **macOS 14.0+**.

Cocok untuk: komputer sendiri, keluarga, atau tester terbatas.

### Jalur B — distribusi resmi (Developer ID + notarization)

1. Ikut **Apple Developer Program** (USD 99/tahun).
2. Buat sertifikat **Developer ID Application** di *Certificates, Identifiers &
   Profiles*, unduh, lalu pasang di Keychain.
3. Build + sign dengan identity tersebut:
   ```bash
   CODESIGN_IDENTITY="Developer ID Application: Nama Anda (TEAMID)" \
   ENTITLEMENTS_FILE="Resources/MurottalCentral.entitlements" \
   Scripts/build-app.sh

   Scripts/package-dmg.sh
   ```
4. Simpan kredensial notarytool sekali:
   ```bash
   xcrun notarytool store-credentials "murottal-notary" \
     --apple-id "you@example.com" --team-id "TEAMID" \
     --password "app-specific-password"
   ```
5. Notarisasi + staple:
   ```bash
   Scripts/notarize.sh
   ```
6. Verifikasi:
   ```bash
   spctl --assess --type execute -vv /Applications/MurottalCentral.app
   # → accepted
   ```

Keuntungan: pengguna cukup **double-click**, tanpa peringatan Gatekeeper.

### Yang sudah disiapkan aplikasi

| Item | Status |
| --- | --- |
| Biner **universal** (arm64 + x86_64) | ✅ `build-app.sh` (default) |
| Ikon aplikasi | ✅ `Resources/AppIcon.icns` |
| `Info.plist` + versi | ✅ |
| Entitlements sandbox | ✅ opsional (`ENTITLEMENTS_FILE`) |
| Skrip notarization | ✅ `Scripts/notarize.sh` |
| Tidak bergantung path build developer | ✅ font dicari lewat beberapa kandidat path |

## 1. Alur singkat

```bash
Scripts/make-icon.sh      # sekali saja (atau saat ikon berubah)
Scripts/build-app.sh      # → build/MurottalCentral.app
Scripts/package-dmg.sh    # → build/MurottalCentral-<versi>.dmg
Scripts/notarize.sh       # butuh akun Apple Developer
```

| Skrip | Fungsi |
| --- | --- |
| `Scripts/GenerateIcon.swift` | Menggambar ikon 1024×1024 (CoreGraphics). |
| `Scripts/make-icon.sh` | Ikon → `Resources/AppIcon.icns`. |
| `Scripts/build-app.sh` | Build release + susun `.app` + codesign. |
| `Scripts/package-dmg.sh` | Bungkus `.app` jadi `.dmg`. |
| `Scripts/notarize.sh` | Kirim ke Apple, staple tiket. |

## 2. Berkas pendukung

| Berkas | Isi |
| --- | --- |
| `Resources/Info.plist` | Bundle ID (`com.murottalcentral.app`), versi, `LSMinimumSystemVersion` 14.0, ikon, kategori. |
| `Resources/MurottalCentral.entitlements` | Sandbox + `network.client`. |
| `Resources/AppIcon.icns` | Ikon (dihasilkan skrip). |

## 3. Build lokal (tanpa akun Apple)

```bash
Scripts/build-app.sh
Scripts/package-dmg.sh
open build/MurottalCentral.app
```

`build-app.sh` membangun **universal binary** (`arm64` + `x86_64`) secara
default. Untuk membatasi arsitektur:

```bash
ARCHS="arm64" Scripts/build-app.sh      # Apple Silicon saja
ARCHS="x86_64" Scripts/build-app.sh     # Intel saja
```

Skrip memakai **ad-hoc signing** (`--sign -`). Aplikasi bisa dijalankan di mesin
sendiri, tapi pengguna lain akan melihat peringatan Gatekeeper (lihat jalur A di
ringkasan atas).

## 4. Build untuk distribusi

Butuh **Apple Developer Program** dan sertifikat **Developer ID Application**.

```bash
CODESIGN_IDENTITY="Developer ID Application: Nama Anda (TEAMID)" \
ENTITLEMENTS_FILE="Resources/MurottalCentral.entitlements" \
Scripts/build-app.sh

Scripts/package-dmg.sh
```

`build-app.sh` akan menambahkan `--options runtime` (Hardened Runtime) dan
`--timestamp` saat identity bukan ad-hoc.

## 5. Notarization

Simpan kredensial sekali:

```bash
xcrun notarytool store-credentials "murottal-notary" \
  --apple-id "you@example.com" \
  --team-id "TEAMID" \
  --password "app-specific-password"
```

Lalu:

```bash
Scripts/notarize.sh
```

Skrip mengirim DMG, menunggu hasil, dan men-staple tiket. Setelah itu DMG bisa
dibuka di Mac mana pun tanpa peringatan.

## 6. Sandbox

Entitlements yang dipakai:

| Entitlement | Alasan |
| --- | --- |
| `com.apple.security.app-sandbox` | Wajib untuk Mac App Store; disarankan untuk distribusi luar. |
| `com.apple.security.network.client` | Mengambil JSON, artwork, dan audio. |

Aplikasi **tidak** memerlukan akses berkas pengguna: unduhan disimpan di
`Application Support` (otomatis berada di dalam container saat sandbox aktif).

> ⚠️ Saat dijalankan lewat `swift run`, aplikasi **tidak** di-sandbox. Sandbox
> hanya berlaku pada bundle `.app` yang ditandatangani dengan entitlements.

## 7. Versi

Naikkan versi di **dua** tempat:

1. `Resources/Info.plist` → `CFBundleShortVersionString` (mis. `0.2.0`) dan
   `CFBundleVersion` (naikkan setiap rilis).
2. `Sources/MurottalCentralApp/Views/AboutView.swift` → konstanta `version`.

## 8. Checklist sebelum rilis

- [ ] `swift build` tanpa warning
- [ ] `swift test` hijau
- [ ] `MUROTTAL_LIVE=1 swift test --filter LiveIntegrationTests` hijau
- [ ] Versi dinaikkan di Info.plist & AboutView
- [ ] Ikon terbaru (`Scripts/make-icon.sh`)
- [ ] Biner **universal** (`lipo -info` menunjukkan `x86_64 arm64`)
- [ ] `LSMinimumSystemVersion` sesuai (saat ini 14.0)
- [ ] Uji manual: jelajah qari, putar, favorit, unduh (jeda/lanjut), sleep timer, pengaturan
- [ ] Uji fitur baca: font Uthmani/IndoPak, terjemahan, audio per ayat
- [ ] Uji offline: matikan Wi-Fi, putar trek yang sudah diunduh
- [ ] DMG diuji di **Mac lain** (bukan mesin build), minimal satu Apple Silicon
- [ ] Notarization sukses (`spctl --assess` lulus)

## 9. Tinjauan legalitas (WAJIB sebelum distribusi) ⚠️

Ringkasan dari [`01-riset-sumber-data.md`](01-riset-sumber-data.md) §7:

- Katalog & audio diambil dari **endpoint publik Quran Central**; berkas audio
  berasal dari **Muslim Central**.
- **Tidak ditemukan lisensi terbuka eksplisit** untuk rekaman tersebut.
- Hak cipta tiap rekaman umumnya milik qari dan/atau label.

| Rencana | Tindakan |
| --- | --- |
| Pemakaian pribadi / internal | Tidak ada tindakan tambahan; sertakan atribusi (sudah ada di layar Tentang). |
| Distribusi publik / App Store | **Minta izin tertulis** ke Muslim Central / Quran Central, atau ganti sumber. |
| Bundling audio di installer | **Jangan** tanpa izin. Aplikasi ini tidak membundel audio — semua diambil saat runtime. |

### Menyiapkan jalur alternatif

Aplikasi sudah memakai protokol `QuranDataSource`. Untuk berpindah sumber:

1. Buat implementasi baru, mis. `Mp3QuranClient: QuranDataSource`.
2. Tukar di `AppState.init()`:
   ```swift
   let client = Mp3QuranClient()   // sebelumnya QuranCentralClient()
   ```
3. Sesuaikan `AudioTrack.streamURL` bila skema URL audio berbeda.

Sumber alternatif: **mp3quran.net API**, **Quran.com API v4**, **EveryAyah**,
**Tanzil** (teks).

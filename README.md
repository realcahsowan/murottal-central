# Murottal Central

Aplikasi desktop **macOS (SwiftUI)** untuk mendengarkan, mengunduh, dan menjelajahi
murottal (rekaman tilawah Al-Qur'an) dari ratusan qari.

Proyek ini adalah **klien pihak ketiga** yang memakai sumber data publik dari
Quran Central (`qurancentral.com`) — lihat catatan legalitas di
[`docs/01-riset-sumber-data.md`](docs/01-riset-sumber-data.md).

## Status

| Tahap | Status |
| --- | --- |
| 1. Riset sumber data & API | ✅ selesai |
| 2. Arsitektur & struktur data | ✅ selesai |
| 3. Desain & tampilan | ✅ selesai |
| 4. Rencana pengembangan | ✅ selesai |
| 5. Scaffold kode (core + UI) | ✅ selesai |
| 6. Fase 0–5 (fitur inti) | ✅ selesai |
| 7. Verifikasi (build + tes) | ✅ `swift build` & 103 tes lolos (+14 tes live) |
| 8. Fase 6 (polesan & distribusi) | ✅ selesai (`.app` + `.dmg` bisa dibangun) |
| 9. Perbaikan crash Now Playing (v0.1.1) | ✅ diperbaiki & dikunci tes regresi |
| 10. Fase 7 (baca + audio per ayat) | ✅ selesai (sumber EveryAyah) |
| 11. Terjemahan Indonesia (v0.3.0) | ✅ Quran.com id 33 (Kemenag) |

## Dokumentasi

| Dokumen | Isi |
| --- | --- |
| [`docs/01-riset-sumber-data.md`](docs/01-riset-sumber-data.md) | Hasil riset endpoint, skema JSON, CDN audio/artwork, CORS, legalitas |
| [`docs/02-arsitektur-dan-struktur-data.md`](docs/02-arsitektur-dan-struktur-data.md) | Arsitektur layer, model data Swift, caching, unduhan |
| [`docs/03-desain-dan-tampilan.md`](docs/03-desain-dan-tampilan.md) | Peta layar, wireframe, design token, state UI |
| [`docs/04-rencana-pengembangan.md`](docs/04-rencana-pengembangan.md) | Roadmap bertahap (fase 0–6) + checklist |
| [`docs/05-panduan-pengguna.md`](docs/05-panduan-pengguna.md) | Panduan pemakaian + pintasan keyboard |
| [`docs/06-distribusi.md`](docs/06-distribusi.md) | Packaging, signing, notarization, checklist rilis |
| [`docs/07-fitur-baca-dan-audio-ayat.md`](docs/07-fitur-baca-dan-audio-ayat.md) | Riset EveryAyah + rencana fitur baca & audio per ayat |

## Struktur paket

```
murottal-central/
├── Package.swift
├── Sources/
│   ├── MurottalCentralCore/     # model, networking, audio (tanpa UI)
│   │   ├── Models/
│   │   ├── Networking/
│   │   ├── Audio/
│   │   ├── Persistence/
│   │   ├── Settings/
│   │   └── Utilities/
│   └── MurottalCentralApp/      # aplikasi SwiftUI (executable)
│       ├── App/
│       ├── State/
│       └── Views/
├── Resources/                   # Info.plist, entitlements, AppIcon.icns
├── Scripts/                     # make-icon / build-app / package-dmg / notarize
├── Tests/
│   └── MurottalCentralCoreTests/
└── docs/
```

## Menjalankan

Butuh Xcode 16+ / Swift 6 (dites dengan Xcode 26.3, Swift 6.2, macOS 15).

```bash
# build
swift build

# jalankan aplikasi
swift run MurottalCentral

# tes offline (cepat)
swift test

# tes integrasi ke API nyata (butuh internet)
MUROTTAL_LIVE=1 swift test --filter LiveIntegrationTests
```

Atau buka `Package.swift` langsung di Xcode, pilih scheme **MurottalCentral**,
lalu Run.

### Membuat aplikasi `.app` / `.dmg`

```bash
Scripts/make-icon.sh        # sekali saja (ikon)
Scripts/build-app.sh        # → build/MurottalCentral.app (universal: arm64 + x86_64)
Scripts/package-dmg.sh      # → build/MurottalCentral-<versi>.dmg
```

Agar bisa dipakai di Mac lain (Gatekeeper / notarization), lihat ringkasan di
[`docs/06-distribusi.md`](docs/06-distribusi.md).

> **Penting:** API Quran Central mewajibkan header `Origin:
> https://qurancentral.com` pada setiap request JSON (Cloudflare membalas 403
> tanpa header itu). Hal ini sudah ditangani di `QuranCentralClient`. Lihat
> [`docs/01-riset-sumber-data.md`](docs/01-riset-sumber-data.md) §2.

## Yang sudah bisa dilakukan sekarang

- Menelusuri 701 qari (grid + pencarian + filter negara/dialek)
- Membuka detail qari (playlist 114 surah + tab Info + cari di playlist)
- Menelusuri 114 surah dan melihat semua rekaman untuk surah tsb.
- Menelusuri 30 **Juz** dan surah yang tercakup di dalamnya
- **Haramain** — qari Masjidil Haram & Masjid Nabawi
- **Mencari** qari & surah dari satu layar (tab Qari / Surah)
- **Baca** per surah/juz: teks Arab + terjemahan (**English / Bahasa Indonesia**),
  audio **per ayat** (45 qari), **font Uthmani/IndoPak**, highlight ayat aktif,
  auto-scroll, dan **Putar halaman**
- Memutar audio (queue, next/prev, seek, kecepatan, repeat, shuffle)
- **Now Playing & media keys** macOS (judul, qari, artwork, geser posisi)
- **Sleep timer** (5–60 menit atau berhenti di akhir trek)
- Favorit trek, qari berbintang, riwayat putar
- **Mengunduh dengan progres**, jeda/lanjut/batal, dan resume antar sesi
- **Pengaturan** (tema, sembunyikan foto qari, kelola unduhan & cache) dan
  layar **Tentang** dengan atribusi sumber
- **Packaging**: `Scripts/build-app.sh` → `.app`, `Scripts/package-dmg.sh` → `.dmg`

> Aplikasi ini **hanya menampilkan qari laki-laki**. Fitur baca menampilkan teks
> per ayat beserta audio per ayat; aplikasi tetap bukan penampil mushaf.

# 04 — Rencana Pengembangan (Roadmap)

Pendekatan: **bertahap, tiap fase menghasilkan aplikasi yang bisa dijalankan.**

> **Status scaffold saat ini (lihat `Sources/`):** Fase 0–7 **selesai
> diimplementasikan** — lihat tanda `[x]` di bawah. `swift build` sukses tanpa
> warning, 94 tes (offline) + 12 tes live lolos, dan bundle `.app` + `.dmg` bisa
> dibangun lewat skrip di `Scripts/`.

---

## Fase 0 — Fondasi proyek
**Tujuan:** kerangka yang bisa di-build & dijalankan.

- [x] Inisialisasi Swift Package (`MurottalCentralCore` + `MurottalCentralApp`)
- [x] Target macOS 14+, Swift 6
- [x] Set `Package.swift`, konfigurasi target, `.gitignore`
- [x] Skema build di Xcode (buka `Package.swift`)
- [x] Struktur folder sesuai dok. 02

**Keluaran:** `swift run` menampilkan jendela kosong.

---

## Fase 1 — Lapisan data (Core)
**Tujuan:** bisa mengambil & mem-parse seluruh data Quran Central.

- [x] Model `Codable` lengkap (dok. 02 §4)
- [x] `QCEndpoints` + `ArtworkResolver` + `DurationParser`
- [x] `QuranDataSource` (protokol) & `QuranCentralClient` (actor, URLSession + URLCache)
- [x] De-duplikasi request (`inFlight`) + normalisasi error
- [x] Unit test parsing dengan **fixture JSON nyata** (simpan sampel ke `Tests/.../Fixtures`)
- [x] Header `Origin` + `User-Agent` (wajib, jika tidak → 403)
- [x] Toleransi `url: null` & filter trek promosi/donasi

**Keluaran:** `swift test` hijau; CLI kecil bisa cetak 701 qari.

---

## Fase 2 — Daftar & detail qari (UI pertama)
**Tujuan:** menelusuri katalog.

- [x] `AppState` (@MainActor @Observable) memuat reciters & surahs
- [x] `RootView` (NavigationSplitView) + `SidebarView`
- [x] `ReciterGridView` + pencarian + filter (negara, dialek)
- [x] `ReciterDetailView` (tab Playlist/Info) → ambil `categories/{slug}.json`
- [x] `SurahListView` + `SurahDetailView` → `tags/{slug}.json`
- [x] Komponen `AsyncContentView` (loading/empty/error)
- [x] Artwork async + fallback gender

**Keluaran:** bisa menjelajah qari → daftar surah; belum ada audio.

---

## Fase 3 — Pemutar audio
**Tujuan:** mendengarkan.

- [x] `AudioPlayer` (AVPlayer) + queue, next/prev, seek
- [x] `PlayerBar` terikat state global
- [x] Resume posisi per trek (`UserDefaults`)
- [x] `MPNowPlayingInfoCenter` + `MPRemoteCommandCenter` (media keys)
- [x] Kecepatan putar 0.25×–4×, repeat, shuffle
- [x] Sleep timer (durasi 5–60 menit & "akhir trek ini")
- [x] Fallback ke berkas lokal bila sudah diunduh

**Keluaran:** app fungsional untuk mendengarkan.

---

## Fase 4 — Koleksi & unduhan offline
**Tujuan:** personalisasi + offline.

- [x] `FavoritesStore` (favorit trek & qari berbintang)
- [x] `PlaybackHistoryStore` (200 entri terakhir)
- [x] `DownloadManager` (URLSession download, manifest, hapus, ukuran tersimpan)
- [x] `FavoritesView`, `StarredRecitersView`, `PlaybackHistoryView`, `DownloadsView`
- [x] Indikator status unduhan per trek (progress bar)
- [x] Jeda/lanjut/batal unduhan
- [x] Resume unduhan via `resumeData` (dipersist di `.resume/`, bertahan antar sesi)

**Keluaran:** pemakaian offline & koleksi pribadi.

---

## Fase 5 — Pencarian, Juz, Haramain, Pengaturan
- [x] Pencarian global (qari, surah) — filter klien (`CatalogSearch`)
- [x] Pencarian di dalam playlist qari (`CatalogSearch.tracks`)
- [x] `JuzListView` (30 juz → daftar surah terkait)
- [x] `HaramainView` (Makkah/Madinah, daftar qari dari `HaramainData`)
- [x] `SettingsView`: tema, sembunyikan foto perempuan/laki-laki, hapus unduhan, hapus cache
- [x] Layar *About* + atribusi sumber

**Keluaran:** paritas fitur utama dengan web.

---

## Fase 6 — Polesan & distribusi
- [x] Ikon app (`Scripts/make-icon.sh`), `Info.plist`, sandbox + entitlements (network client)
- [x] Notarization & packaging `.dmg` (`Scripts/build-app.sh`, `package-dmg.sh`, `notarize.sh`)
- [x] Optimasi: prefetch artwork, lazy list, batasi konkurensi request
- [x] Aksesibilitas + keyboard shortcut (⌘1–⌘7, Space, ⌘←/→, menu Pemutaran)
- [x] Dokumentasi pengguna ([`05-panduan-pengguna.md`](05-panduan-pengguna.md))
- [x] Tinjauan legalitas & panduan distribusi ([`06-distribusi.md`](06-distribusi.md))
- [x] Jalur alternatif provider disiapkan (`QuranDataSource`)

> Teks Qur'an bertajwid **sengaja tidak diimplementasikan** — aplikasi ini
> berfokus pada audio murottal, bukan mushaf.

---

## Fase 7 — Baca & audio per ayat (EveryAyah)
**Tujuan:** membaca teks per ayat dan memutar audio ayat terpilih / halaman.

- [x] Riset teknik audio per ayat ([`07-fitur-baca-dan-audio-ayat.md`](07-fitur-baca-dan-audio-ayat.md))
- [x] `AyahReciter`, `EveryAyah` (URL `SSSAAA.mp3`), `QuranTextSanitizer`
- [x] Endpoint `list-reciters.json` (45 qari per ayat) + teks Arab & Inggris
- [x] `AudioTrack` mendukung URL absolut + artwork opsional
- [x] `AppState`: filter ayat per surah/juz, queue per ayat, deteksi ayat aktif
- [x] `ReadingHomeView` + `ReadingView` (surah & juz, highlight, auto-scroll)
- [x] Qari picker, toggle terjemahan, **Putar halaman**
- [x] Tes unit + live (audio `206 Partial Content`)
- [ ] Unduhan per ayat (Fase 7b)
- [ ] Transliterasi (bentuk JSON berbeda)
- [ ] Bookmark per ayat & mode "Arab saja"

> Audio per ayat memakai **sumber berbeda** (EveryAyah) dari audio per surah
> (Quran Central). Berkas tidak identik dan tidak bisa saling menggantikan.

---

## Prioritas MVP

MVP = **Fase 0–3**. Setelah itu app sudah berguna (jelajah + putar).
Fase 4 (offline) dan 5 (fitur lengkap) menyusul.

## Risiko & mitigasi

| Risiko | Dampak | Mitigasi |
| --- | --- | --- |
| Cloudflare 403 / rate limit | Data gagal dimuat | Set User-Agent; batasi konkurensi; cache agresif |
| Legalitas audio | App ditolak / ditakedown | Abstraksi provider; minta izin; siap ganti sumber |
| Skema JSON berubah | Parsing rusak | Model `Codable` toleran; tes fixture; pantau versi |
| Ukuran katalog besar (39.738 trek) | Memori | Muat per-kategori, jangan gabung semua |
| Font `.woff2` | Teks Arab tidak tampil | Fallback font sistem; konversi font di fase lanjut |

## Definisi "selesai" per fase

Setiap fase dianggap selesai bila: **kode ter-build tanpa warning**, **ada tes
untuk logika inti**, dan **bisa dijalankan manual** sesuai "Keluaran"-nya.

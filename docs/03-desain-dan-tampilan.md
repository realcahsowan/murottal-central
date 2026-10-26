# 03 — Desain & Tampilan

## 1. Prinsip desain

- **Fokus ke mendengarkan.** Player selalu terlihat di bawah, tidak pernah
  tertutup navigasi.
- **Native macOS.** `NavigationSplitView` + toolbar + search bawaan, mendukung
  keyboard, jendela yang bisa di-resize, dan mode gelap otomatis.
- **Tenang & bersih.** Aksen hijau (tema Quran Central `#009688`), banyak ruang
  kosong, tipografi jelas, tanpa iklan.
- **Dua mode utama**: *Jelajahi* (per qari / per surah / per juz) dan *Putar*.

## 2. Peta layar

```
Window (NavigationSplitView)
├── Sidebar
│   ├── Jelajahi
│   │   ├── Qari            → ReciterGridView
│   │   ├── Haramain        → HaramainView
│   │   └── Baca            → ReadingHomeView → ReadingView
│   ├── Koleksi Saya
│   │   ├── Favorit         → FavoritesView
│   │   ├── Qari Berbintang → StarredRecitersView
│   │   ├── Riwayat         → PlaybackHistoryView
│   │   └── Unduhan         → DownloadsView
│   └── Lainnya
│       ├── Pengaturan      → SettingsView
│       └── Tentang         → AboutView
├── Detail (kolom tengah + kanan)
│   ├── ReciterDetailView   (Playlist | Info)
│   ├── SurahDetailView     (daftar qari untuk surah tsb.)
│   └── ReadingView         (teks Qur'an, opsional fase 5)
└── PlayerBar (selalu di bawah, full width)
```

## 3. Wireframe

### 3.1 Daftar qari (grid)

```
┌───────────────┬────────────────────────────────────────────────────────┐
│ ▸ Jelajahi    │  Qari                                     [🔍 Cari qari]│
│   Qari     ◀  │  ┌──────────────────────────────────────────────────┐  │
│   Surah       │  │ Semua negara ▾   Dialek: Hafs Warsh …            │  │
│   Juz         │  │ Gaya: Semua Tarteel Mujawwad Juz   Gender: …     │  │
│ ▸ Koleksi     │  └──────────────────────────────────────────────────┘  │
│   Favorit     │  ┌───────┐ ┌───────┐ ┌───────┐ ┌───────┐ ┌───────┐     │
│   Riwayat     │  │ img   │ │ img   │ │ img   │ │ img   │ │ img   │     │
│   Unduhan     │  │Alafasy│ │Sudais │ │Minsh. │ │…      │ │…      │     │
│               │  │ 114 ▸ │ │ 114 ▸ │ │ 114 ▸ │ │       │ │       │     │
│               │  └───────┘ └───────┘ └───────┘ └───────┘ └───────┘     │
│               │  … (Load more / infinite scroll)                       │
├───────────────┴────────────────────────────────────────────────────────┤
│ ▶  Mishary Rashid Alafasy · 002 Al-Baqara    ──────●──── 12:04/2:06:16  │
│    ⏮  ⏯  ⏭    1×  🔁  ⬇  ⏱                                            │
└────────────────────────────────────────────────────────────────────────┘
```

### 3.2 Detail qari

```
┌────────────────────────────────────────────────────────────────────────┐
│  ◀ Qari                                                                │
│  ┌──────┐  Mishary Rashid Alafasy            ★  Star                   │
│  │ img  │  114 berkas audio                                           │
│  └──────┘  [ Playlist ] [ Info ]                                       │
│  ────────────────────────────────────────────────────────────────────  │
│  001 Al-Fatiha                              0:52   ♡   ⬇   ▶         │
│  002 Al-Baqara                           2:06:16   ♡   ⬇   ▶         │
│  003 Aal-i-Imraan                           1:32:10 ♡   ⬇   ▶         │
│  …                                                                     │
├────────────────────────────────────────────────────────────────────────┤
│ ▶  PlayerBar …                                                         │
└────────────────────────────────────────────────────────────────────────┘
```

### 3.3 Detail surah (semua qari)

```
┌────────────────────────────────────────────────────────────────────────┐
│  ◀ Surah                                                               │
│  001 — Al Faatiha  (الفاتحة)   "The Opener"                            │
│  421 rekaman · [Urutkan: Qari ▾] [Cari]                                │
│  ────────────────────────────────────────────────────────────────────  │
│  Ahmed Abdelrazek Nasr                       28:09   ♡  ⬇  ▶          │
│  Abdurrahmaan Sadien                          6:38   ♡  ⬇  ▶          │
│  …                                                                     │
└────────────────────────────────────────────────────────────────────────┘
```

### 3.4 PlayerBar (komponen kunci)

```
┌────────────────────────────────────────────────────────────────────────┐
│ [img] 002 Al-Baqara                    ⏮   ⏯   ⏭   🔁  1×  🔀  ⏱  ⬇   │
│       Mishary Rashid Alafasy      ─────────●──────────  12:04 / 2:06:16│
└────────────────────────────────────────────────────────────────────────┘
```

Interaksi: klik judul → buka konteks playlist; slider bisa di-drag (seek);
tombol ⏱ = sleep timer; ⬇ = unduh trek ini; badge kecil saat memutar versi
offline.

## 4. Design token

| Token | Nilai |
| --- | --- |
| Aksen (primary) | `#009688` (teal) |
| Latar terang / gelap | `#FFFFFF` / `#121212` |
| Sudut kartu | 12 pt |
| Jarak grid | 16 pt, lebar kartu min 150 pt |
| Tipografi judul | `.title2.semibold` |
| Tipografi Arab | `.system(size:)` + font Qur'an bila tersedia |
| Baris daftar | tinggi 56 pt, hover highlight |

Gunakan `Color.accentColor` yang dipetakan ke teal agar otomatis selaras
dengan kontrol sistem.

## 5. State UI (wajib konsisten)

Komponen generik:

```swift
struct AsyncContentView<Value, Content: View>: View {
    let phase: LoadPhase<Value>
    @ViewBuilder var content: (Value) -> Content
}
```

`LoadPhase` = `.idle / .loading / .empty / .failed(Error) / .loaded(Value)`.
Setiap layar memakai ini agar tampilan loading (skeleton), kosong ("Belum ada
favorit"), dan error ("Gagal memuat — Coba lagi") seragam.

## 6. Aksesibilitas & keyboard

- Semua tombol punya `accessibilityLabel` (mis. "Putar 002 Al-Baqara").
- Shortcut: `Space` putar/jeda, `⌘→/⌘←` berikutnya/sebelumnya, `⌘F` cari,
  `⌘L` buka daftar putar.
- Dukung Dynamic Type & VoiceOver.
- Hormati preferensi "kurangi gerakan" (hindari animasi berlebih).

## 7. Alur navigasi utama

```
Buka app
  → Sidebar "Qari" (default)
  → klik qari → ReciterDetailView
  → klik trek → PlayerBar mulai memutar + masuk Riwayat
  → ♡ → tersimpan di Favorit
  → ⬇ → unduhan; saat offline, putar dari berkas lokal
```

## 8. Pencarian

`SearchView` meniru `/audio/search` di web: satu kolom cari + dua tab.

```
┌────────────────────────────────────────────────────────────────────────┐
│  Cari                                              [🔍 Cari qari…    ] │
│  ┌──────────────┬──────────────┐                                       │
│  │     Qari     │    Surah     │   ← segmented                         │
│  └──────────────┴──────────────┘                                       │
│  12 qari                                                               │
│  ┌───────┐ ┌───────┐ ┌───────┐ ┌───────┐                              │
│  │ img   │ │ img   │ │ img   │ │ img   │                              │
│  └───────┘ └───────┘ └───────┘ └───────┘                              │
└────────────────────────────────────────────────────────────────────────┘
```

Logika filter ada di `CatalogSearch` (Core, teruji):
- Qari: cocokkan nama/slug + filter negara + filter dialek.
- Surah: cocokkan nomor (`2`, `002`), nama latin, arti, dan nama Arab.

Grid qari (`ReciterGridView`) memakai fungsi yang sama sehingga perilakunya
konsisten.

## 9. Now Playing & media keys

`AudioPlayer` terintegrasi dengan `MPNowPlayingInfoCenter` dan
`MPRemoteCommandCenter`:

| Aksi | Handler |
| --- | --- |
| Play / Pause / Toggle | `playCommand`, `pauseCommand`, `togglePlayPauseCommand` |
| Berikutnya / Sebelumnya | `nextTrackCommand`, `previousTrackCommand` |
| Geser posisi | `changePlaybackPositionCommand` |

Info yang dipublikasikan: judul trek, nama qari (artist), durasi, posisi,
kecepatan putar, dan **artwork** (diunduh async dari
`artwork.qurancentral.com`, lalu di-cache per trek). Dengan ini, widget
*Now Playing* macOS dan tombol media di keyboard berfungsi.

### Sleep timer

Ikon 🌙 di player bar (juga menu **Pemutaran → Sleep Timer**):

| Mode | Perilaku |
| --- | --- |
| `5 … 60 menit` | Menghitung mundur; sisa waktu tampil di samping ikon. Saat habis, pemutaran dijeda. |
| `Akhir trek ini` | Berhenti saat trek aktif selesai (tidak lanjut ke berikutnya). |
| `Nonaktif` | Membatalkan timer. |

Implementasi: `AudioPlayer.sleepTimerMode` (`.off` / `.duration` /
`.endOfTrack`) dengan `Task` penghitung mundur; mode `.endOfTrack` ditangani di
observer akhir trek.

## 10. Status unduhan

`DownloadManager` memakai `URLSessionDownloadDelegate` untuk melaporkan
progres, yang disimpan di `DownloadStatusStore` (`@MainActor @Observable`).

```swift
enum DownloadState {
    case notDownloaded
    case downloading(progress: Double)   // < 0 = indeterminate
    case downloaded
    case failed(String)
}
```

- **TrackRow**: tombol unduh berubah menjadi cincin progres → centang hijau →
  tombol hapus. Bila gagal, muncul tombol coba lagi oranye.
- **DownloadsView**: dua bagian — "Sedang Diunduh" (dengan bar progres + persen)
  dan "Selesai" (dengan total ukuran dan tombol *Hapus Semua*).

## 11. Juz, Haramain, Pengaturan, Tentang

**Juz** — `JuzListView` memuat 30 juz dari `list-juz.json`. Tiap baris
menampilkan rentang ayat, mis. `Al Faatiha 1:1 → Al Baqara 2:141`. Membuka satu
juz menampilkan daftar surah yang tercakup (`JuzDetailView`) yang bisa
dinavigasi ke detail surah.

**Haramain** — `HaramainView` menampilkan dua grup statis dari `HaramainData`
(Makkah 14 qari, Madinah 12 qari; semua slug sudah diverifikasi ada di katalog).
Kartu qari langsung menuju detail qari.

**Pengaturan** — `SettingsView` (`Form` bergaya grouped):
- Tema: Ikuti Sistem / Terang / Gelap (langsung diterapkan lewat `preferredColorScheme`)
- Sembunyikan foto qari (mengganti ke artwork netral)
- Tampilkan badge gaya (Mujawwad) pada kartu qari
- Ukuran & lokasi penyimpanan unduhan, hapus semua unduhan, kosongkan cache
- Kembalikan pengaturan awal

**Tentang** — `AboutView` menampilkan versi, statistik katalog (jumlah qari,
surah, berkas), tautan sumber (Quran Central, Muslim Central), tombol dukungan,
dan catatan legal.

## 12. Kebijakan katalog: hanya qari laki-laki

Aplikasi **hanya menampilkan qari laki-laki**, di semua layar (grid, pencarian,
qari berbintang, Haramain). Kebijakan ini diterapkan sekali di lapisan data:

```swift
// AppState.reloadCatalog()
reciters = ReciterFilter.malesOnly(try await recitersTask)
```

`ReciterFilter.malesOnly` (Core) menyaring `female == true`. Field `female`
yang absen dianggap laki-laki. Daftar qari berbintang juga disaring terhadap
katalog aktif, sehingga qari yang tidak ditampilkan tidak muncul.

Untuk mengubah kebijakan, cukup ubah pemanggilan di `AppState` — tidak ada
logika penyaringan lain yang tersebar di view.

## 13. Di luar cakupan (bukan sekadar ditunda)

## 13. Layar Baca & audio per ayat

`ReadingHomeView` (sidebar **Baca**) punya dua tab: **Surah** dan **Juz**. Memilih
salah satu membuka `ReadingView` untuk cakupan tersebut.

```
┌──────────────────────────────────────────────────────────────┐
│  Baca                                          [Terjemahan]  │
│  ┌──────────┬──────────┐                        [Qari ▾]     │
│  │  Surah   │   Juz    │                        [▶ Halaman]  │
│  └──────────┴──────────┘                                     │
│  004:148                                       ▶             │
│  ─────────────────────────────────────────────────────────   │
│                              يَٰٓأَيُّهَا ٱلَّذِينَ آمَنُوا۟ …   │
│  ─────────────────────────────────────────────────────────   │
│  O you who have believed, …                                  │
└──────────────────────────────────────────────────────────────┘
```

- Kartu ayat: badge nomor, tombol putar, teks Arab (**RTL**, 26 pt), terjemahan
  opsional.
- Penting: teks Arab memakai `.environment(\.layoutDirection, .rightToLeft)` dan
  alignment `.leading` (dalam RTL `.leading` = kanan; `.trailing` justru = kiri).
- Ayat aktif disorot (latar + border aksen) dan daftar menggulir otomatis.
- Toolbar: **menu bahasa terjemahan** (Off / English / Indonesia), tombol qari
  yang membuka **modal dengan pencarian** (45 qari), dan **Putar halaman**.
- Font Arab bisa dipilih di **Pengaturan → Teks Qur'an**: Uthmani (Amiri Quran),
  IndoPak (Nastaleeq), atau font sistem — lengkap dengan pengatur ukuran dan
  pratinjau.
- Modal qari menampilkan nama + bitrate, mendukung pencarian (nama/subfolder/
  bitrate), menandai pilihan aktif, dan `Esc` untuk menutup.
- Terjemahan Indonesia memakai Quran.com (Kemenag); Inggris dari Quran Central.
- Sumber audio per ayat: EveryAyah (`everyayah.com/data/{subfolder}/{SSS}{AAA}.mp3`) —
  lihat [`07-fitur-baca-dan-audio-ayat.md`](07-fitur-baca-dan-audio-ayat.md).
- Queue berisi seluruh ayat halaman, jadi pemutaran berlanjut otomatis
  (web berhenti per ayat).

## 14. Di luar cakupan (bukan sekadar ditunda)
- **Mushaf / teks Qur'an** — aplikasi ini fokus audio murottal; tidak
  menampilkan teks Arab, terjemahan, atau tajwid berwarna. (Data teks memang
  tersedia di API, tapi sengaja tidak dipakai.)
- **Video** — endpoint terpisah, di luar fokus.

## 14. Ditunda (mungkin nanti)
- Sinkronisasi iCloud antar perangkat.
- Hafalan/memorize dengan pengulangan ayat.
- Dukungan Warsh/riwayat lain di UI (katalog sudah memuatnya).

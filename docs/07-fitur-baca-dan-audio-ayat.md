# 07 — Fitur Baca & Audio Per Ayat

> Riset: 21 Oktober 2026 · Halaman acuan: `https://qurancentral.com/read-quran/juz/6`

## 1. Ringkasan jawaban

**Audio per ayat memakai sumber yang BERBEDA dari audio yang sudah ada di
aplikasi.**

| Aspek | Audio yang sudah ada (per surah) | Audio per ayat (halaman baca) |
| --- | --- | --- |
| Katalog | `data.qurancentral.com/categories/{slug}.json` | `.../features/read-quran/data/list-reciters.json` |
| Host berkas | `podcasts.qurancentral.com` | **`everyayah.com/data`** |
| Granularitas | 1 berkas = **1 surah** | 1 berkas = **1 ayat** |
| Pola URL | `{folder}/{nama}.mp3` | `{subfolder}/{SSS}{AAA}.mp3` |
| Jumlah qari | 701 | **45** |
| Ukuran berkas | besar (1–200 MB) | kecil (±30 KB–1 MB) |
| Artwork | `artwork.qurancentral.com/{slug}-300x300.jpg` | tidak ada padanan langsung |
| Unduhan di app | ✅ sudah | ❌ belum (perlu pipeline terpisah) |

Jadi berkas per ayat **tidak bisa** diturunkan dari berkas per surah yang sudah
bisa diunduh, dan sebaliknya. Keduanya perlu jalur unduhan/cache sendiri.

## 2. Teknik yang dipakai web (hasil bedah bundle)

Bundle saat riset: `assets/index-C6ql5MKy.js` → `SettingsProvider-DLWbTSvI.js`.

### 2.1 Konstruksi URL

```js
// SettingsProvider-DLWbTSvI.js
let n = sura.toString().padStart(3, "0");   // "004"
let r = ayah.toString().padStart(3, "0");   // "148"
let a = reciters[reciterID];                // { subfolder, name, bitrate }
let url = `${BASEURL}${a.subfolder}/${n}${r}.mp3?t=${Date.now()}`;
```

dengan `BASEURL = "https://everyayah.com/data/"`.

Contoh nyata (juz 6, ayat pertama):

```
https://everyayah.com/data/Husary_128kbps/004148.mp3
```

- `SSS` = nomor surah 3 digit, `AAA` = nomor ayat 3 digit.
- `?t=<epoch>` hanyalah **cache-buster**; aplikasi kita tidak memakainya agar
  audio bisa di-cache.
- Sebagian `subfolder` memuat sub-path, mis.
  `warsh/warsh_ibrahim_aldosary_128kbps`.

### 2.2 Daftar qari

`https://data.qurancentral.com/features/read-quran/data/list-reciters.json`
berbentuk **objek** dengan key ID numerik:

```json
{
  "2":  { "subfolder": "Abdul_Basit_Murattal_192kbps", "name": "Abdul Basit As-Samad (Murattal)", "bitrate": "192kbps" },
  "20": { "subfolder": "Husary_128kbps", "name": "Mahmoud Khalil Al-Husary", "bitrate": "128kbps" },
  "60": { "subfolder": "warsh/warsh_ibrahim_aldosary_128kbps", "name": "Ibrahim Al-Dosary (Warsh)", "bitrate": "128kbps" }
}
```

Default web: `DefaultReciterID: 20` (Al-Husary).

### 2.3 Perilaku pemutar di web

Tombol ▶ pada tiap ayat memanggil `setAudioURL(sura, ayah)` dan memutar **satu
ayat saja** (`onEnded` hanya menyembunyikan kontrol). **Tidak ada auto-advance**
ke ayat berikutnya. Aplikasi kita bisa lebih baik: seluruh halaman masuk queue.

### 2.4 Bukti berkas berbeda

Perbandingan Surah Al-Fatiha, Abdul Basit:

| Metrik | Berkas per surah | Jumlah berkas per ayat |
| --- | --- | --- |
| Ukuran | 1.382.983 byte | 1.003.998 byte |
| Durasi | 46,79 detik | 41,8 detik |
| Bitrate | 192 kbps | 192 kbps |

Bitrate sama, tetapi durasi & ukuran berbeda → **master/penyuntingan berbeda**
(walau qarinya sama). Jadi tidak identik.

### 2.5 Karakteristik CDN EveryAyah

Diuji langsung:

| Header | Nilai |
| --- | --- |
| `content-type` | `audio/mpeg` |
| `accept-ranges` | `bytes` (dukung seek & resume) |
| `access-control-allow-origin` | `*` |
| `cache-control` | `max-age=25600000` (±296 hari) |

## 3. Data teks Qur'an

| Berkas | Bentuk | Jumlah | Ukuran |
| --- | --- | --- | --- |
| `quran-arabic-uthmani-tajweed.json` | flat `[{sura,ayah,text}]` + tag `<tajweed>` | 6.236 | ±4,0 MB |
| `quran-english-sahih.json` | flat `[{sura,ayah,text}]` | 6.236 | ±1,2 MB |
| `quran_transliteration.json` | **nested per surah** `[{name,tl,verses:[{tl}]}]` | 114 surah | ±0,8 MB |

> ⚠️ **Teks Uthmani tidak dipakai untuk tampilan.** Teks tajweed Quran Central
> memakai **U+0672** untuk sebagian alif madd. Di font KFGQPC, U+0672
> dipetakan ke komposit `uni0600` (tanda angka Arab) sehingga tampil sebagai
> **bulatan hitam** (mis. pada kata الحياة dan سموات).
>
> Karena itu teks Uthmani diambil dari Quran.com
> (`/quran/verses/uthmani`, ±1,65 MB) yang memakai **U+0670** (superscript
> alef) dan tampil benar dengan font KFGQPC. Teks **IndoPak** tetap dari Quran
> Central (`quran-arabic-indopak.json`) karena memang memakai U+0670.
>
> Regresi ini dikunci tes live `testUthmaniUsesSuperscriptAlefNotWavyHamza`.

**Terjemahan Indonesia tidak tersedia di Quran Central.** Ditambahkan dari
Quran.com API v4 (resource `33` = Kemenag):

```
GET https://api.quran.com/api/v4/quran/translations/33
→ { "translations": [ { "resource_id": 33, "text": "…" }, … ] }   // 6.236 ayat
```

- Urutan **kanonik** (indeks 0 = 1:1, indeks 7 = 2:1, indeks 6235 = 114:6),
  sehingga dipetakan langsung ke `quranArabicVerses` dengan `zip`.
- 825 ayat memuat footnote `<sup foot_note=…>1</sup>` → dibersihkan
  `QuranTextSanitizer`.
- Ukuran ±1,29 MB, `cache-control: public, max-age=691200`, CORS `*`.

Catatan penting: transliterasi **tidak** berformat flat seperti dua lainnya,
jadi perlu decoder terpisah (belum diimplementasikan).

Teks Arab memuat markup `<tajweed class=…>` dan `<span class=end>٣</span>`.
`QuranTextSanitizer` membuang keduanya; nomor ayat ditampilkan sebagai badge
sendiri.

## 3.1 Font Qur'an

Web memakai dua font WOFF2:

| Font web | Pemakaian | Ukuran WOFF2 |
| --- | --- | --- |
| `UthmanicHafs1Ver18.woff2` | Teks Uthmani | ±86 KB |
| `indopak-nastaleeq-waqf-lazim-v4.2.1.woff2` | Teks IndoPak (Nastaleeq) | ±82 KB |

### ⚠️ Mengapa font KFGQPC tidak dipakai

Font `UthmanicHafs1Ver18` (versi 0.18, juga yang dipakai Quran.com) memetakan
dua tanda penting ke glyph yang salah:

| Karakter | Nama | Dipetakan ke |
| --- | --- | --- |
| **U+06DF** | ARABIC SMALL HIGH ROUNDED ZERO | komposit `uni0600` (bulatan besar) |
| **U+0672** | ARABIC ALEF WITH WAVY HAMZA ABOVE | komposit `uni0600` |

`uni0600` adalah ARABIC NUMBER SIGN — glyph bulatan. Itulah penyebab **bulatan
hitam** pada kata seperti `كَفَرُوا۟`, `أُلْقُوا۟`, `سَمِعُوا۟`, `الْحَيَوٰة`, dan
`سَمَٰوَٰت`. Jadi ini bukan karakter hilang, melainkan glyph yang salah di font.

### Font yang dipakai aplikasi

| Opsi | Font | PostScript | Berkas | Lisensi |
| --- | --- | --- | --- | --- |
| **Uthmani** (default) | **Amiri Quran** | `AmiriQuran-Regular` | 134 KB | **OFL 1.1** |
| IndoPak | AlQuran IndoPak by QuranWBW | `AlQuran-IndoPak-by-QuranWBW` | 327 KB | lihat di bawah |
| Sistem | — | — | — | — |

Amiri Quran merender **U+0670**, **U+06DF**, dan **U+06D6** dengan benar
(terverifikasi lewat render Core Text), mendukung seluruh 70 codepoint yang
dipakai teks Uthmani. Font IndoPak dari Quran Central dikonversi WOFF2 → TTF
dengan `Scripts/convert-fonts.sh`.

Alur di aplikasi:

```
Sources/MurottalCentralCore/Resources/Fonts/*.ttf
        │  (SwiftPM resource bundle)
        ▼
QuranFontRegistry.registerBundledFonts()   ← dipanggil di App.init()
        │
        ▼
QuranFont.uthmani / .indopak → Font.custom(postScriptName, size:)
```

- `QuranFont.recommendedLineSpacing` menyesuaikan jarak baris (Nastaleeq lebih
  besar).
- Font dicari lewat beberapa kandidat path (bukan `Bundle.module`) agar aman di
  `swift run`, test, dan `.app`.

### Lisensi

| Font | Ketentuan |
| --- | --- |
| **Amiri Quran** | SIL Open Font License 1.1 — bebas dipakai, dibundel, dan didistribusikan dengan atribusi. |
| **IndoPak (QuranWBW)** | Tidak untuk distribusi/development tanpa izin tertulis dari QuranWBW.com. |

## 4. Arsitektur implementasi

```
ReadingHomeView (Surah | Juz)
        │
        ▼
ReadingView(scope: .surah(Surah) | .juz(Juz))
        │
        ├── verses  ← AppState.quranArabicVerses (difilter per scope)
        ├── terjemahan ← AppState.englishIndex["4:148"]
        ├── qari     ← AppState.ayahReciters (45)
        └── audio    ← AudioTrack.ayah(...) → EveryAyah URL absolut
                          │
                          ▼
                     AudioPlayer (queue seluruh halaman)
```

### 4.1 Model & utilitas baru (Core)

```swift
public struct AyahReciter: Identifiable, Hashable, Sendable {
    public let id: Int
    public let subfolder: String
    public let name: String
    public let bitrate: String
}

public enum EveryAyah {
    public static func fileName(surah: Int, ayah: Int) -> String     // "004148.mp3"
    public static func audioURL(subfolder: String, surah: Int, ayah: Int) -> URL
}

public enum QuranTextSanitizer {
    public static func plain(_ text: String) -> String
}
```

### 4.2 `AudioTrack` mendukung URL absolut

Audio per ayat memakai URL absolut, sedangkan audio per surah memakai path
relatif. Perubahan:

```swift
public var isAbsoluteURL: Bool
public var streamURL: URL          // absolut dipakai apa adanya, selain itu → podcasts.qurancentral.com
public let artworkSlug: String?    // artwork opsional (per ayat: nil)
public var artworkIdentifier: String?  // nil → tampilkan artwork fallback
public var downloadFolder: String  // aman untuk URL absolut ("ayah-everyayah")
```

Backward-compatible: `artworkSlug` memakai `decodeIfPresent`, sehingga
favorit/riwayat lama tetap terbaca.

### 4.3 Queue & "putar halaman"

`AppState.playVerse(_:in:)` membangun **satu queue berisi seluruh ayat pada
cakupan**, lalu memulai dari ayat yang diklik:

```swift
let tracks = verses.map { AudioTrack.ayah(surah: $0.sura, ayah: $0.ayah, reciter: reciter) }
player.play(tracks, startingAt: index)
```

Karena `AudioPlayer` sudah punya `next()` otomatis saat trek selesai, ayat
berlanjut sendiri — inilah peningkatan dibanding web (yang berhenti per ayat).

### 4.4 Highlight & auto-scroll

`AppState.currentReadingVerseID` menurunkan `"4:148"` dari URL trek yang sedang
diputar (`004148.mp3`). `ReadingView` memakai `ScrollViewReader` untuk
menggulir ke ayat aktif saat trek berganti.

## 5. Desain tampilan

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
│                                                              │
│  004:149                                       ▶             │
│  …                                                           │
└──────────────────────────────────────────────────────────────┘
```

- Kartu ayat: badge nomor, tombol putar, teks Arab (RTL, 26 pt), terjemahan.
- Ayat aktif: latar & border aksen + ikon speaker.
- Toolbar: menu bahasa terjemahan, tombol qari (membuka **modal pencarian**),
  dan tombol **Putar halaman**.
- Modal qari: cari berdasarkan nama/subfolder/bitrate, penanda pilihan aktif,
  `Esc` menutup, `Return` memilih hasil pertama.
- Titik masuk: sidebar **Baca**, tombol **Baca** di detail surah, dan
  **Baca Juz** di detail juz.

## 6. Rencana bertahap

### Fase 1 — Fondasi & pemutaran (✅ selesai)

- [x] `AyahReciter`, `EveryAyah`, `QuranTextSanitizer`
- [x] Endpoint `list-reciters.json`, teks Arab & Inggris
- [x] `AudioTrack` mendukung URL absolut
- [x] `AppState`: muat data baca, filter per surah/juz, queue per ayat
- [x] `ReadingHomeView`, `ReadingView`, kartu ayat, highlight, auto-scroll
- [x] Tes unit + tes live (45 qari, 6.236 ayat, audio 206 Partial Content)

### Fase 2 — Unduhan per ayat

- [ ] `DownloadManager` menyimpan per ayat ke `ayah-{reciter}/SSSAAA.mp3`
      (folder sudah aman lewat `downloadFolder`).
- [ ] Indikator unduhan per ayat + "unduh halaman ini".
- [ ] Estimasi ukuran halaman sebelum mengunduh.

### Fase 3 — Teks & kontrol lanjutan

- [x] **Terjemahan Indonesia** (Quran.com resource 33, Kemenag)
- [x] Pemilih bahasa terjemahan: Off / English / Indonesia (tersimpan di Pengaturan)
- [x] Sanitasi footnote `<sup …>…</sup>`
- [ ] Transliterasi (decoder nested yang berbeda).
- [x] Pilihan font (**Uthmani KFGQPC / IndoPak Nastaleeq / Sistem**) + ukuran font
- [ ] Bookmark per ayat + lanjut dari ayat terakhir.
- [ ] Mode "Arab saja" (baca menyambung) seperti web.

### Fase 4 — Hafalan (opsional)

- [ ] Rentang ayat + ulangi N kali.
- [ ] Jeda antar ayat.
- [ ] Loop ayat/halaman.

## 7. Risiko & catatan

| Risiko | Mitigasi |
| --- | --- |
| EveryAyah pihak ketiga, bisa berubah | Abstraksi `EveryAyah`; cache audio yang sudah diputar |
| 45 qari ≠ 701 qari katalog | Menu terpisah; jangan campur dengan daftar qari per surah |
| Tidak ada artwork per-ayat | `artworkSlug = nil` → artwork fallback generik |
| Teks Arab 4 MB | Dimuat sekali & di-cache di memori; hanya saat menu Baca dibuka |
| Transliterasi beda bentuk | Ditunda ke Fase 3 dengan decoder khusus |
| Legalitas | EveryAyah juga menampilkan atribusi; tinjau ulang sebelum distribusi (lihat dok. 06 §9) |

## 8. Ringkas: apa yang berubah di aplikasi

| Berkas | Perubahan |
| --- | --- |
| `Models/AyahReciter.swift` | baru |
| `Utilities/EveryAyah.swift` | baru |
| `Utilities/QuranTextSanitizer.swift` | baru |
| `Models/AudioTrack.swift` | URL absolut, `artworkSlug`, `downloadFolder` |
| `Models/Juz.swift` | `QuranVerse: Identifiable` |
| `Networking/*` | `QuranTextSource`, 3 endpoint baru |
| `State/AppState.swift` | data baca, filter scope, queue per ayat |
| `Views/ReadingView.swift` | baru (home + layar baca + kartu ayat) |
| `Views/Navigation.swift` | `SidebarItem.reading`, `ReadingScope`, `Route.reading` |
| `Views/ArtworkView.swift` | slug opsional (fallback) |

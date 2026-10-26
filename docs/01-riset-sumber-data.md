# 01 — Riset Sumber Data: Quran Central

> Tanggal riset: 18 Oktober 2026
> Target: `https://qurancentral.com/audio` dan `https://qurancentral.com/audio/mishary-rashid-alafasy`

## 1. Ringkasan singkat

`qurancentral.com` adalah **Single Page Application (React + Vite)**. HTML yang
dikirim server hampir kosong (`<div id="root">`), jadi seluruh data diambil
runtime lewat API JSON. Dari bundle JS-nya kita bisa membaca seluruh endpoint.

Tiga host yang dipakai:

| Host | Fungsi |
| --- | --- |
| `https://data.qurancentral.com` | Data JSON (daftar qari, surah, teks Qur'an, katalog audio) |
| `https://podcasts.qurancentral.com` | File audio `.mp3` |
| `https://artwork.qurancentral.com` | Gambar/artwork qari (`{slug}-300x300.jpg`) |

Endpoint **publik, tanpa API key, tanpa login**. `robots.txt` isinya `Allow: /`.

## 2. Catatan penting: User-Agent & header `Origin` (Cloudflare)

Situs dilindungi Cloudflare. Request harus menyertakan **dua hal**:

1. `User-Agent` yang wajar (bukan kosong / bukan `curl` polos).
2. Header **`Origin: https://qurancentral.com`** — ini **wajib**.

Hasil uji isolasi:

| Header | Hasil |
| --- | --- |
| (tanpa User-Agent) | `403` |
| `User-Agent` saja | `403` |
| `User-Agent` + `Referer` | `403` |
| **`User-Agent` + `Origin`** | **`200`** |
| `Origin` + `Referer` + `User-Agent` | `200` |

```bash
# 200
curl -A "MurottalCentral/0.1 (macOS)" \
     -H "Origin: https://qurancentral.com" \
     -H "Referer: https://qurancentral.com/" \
     https://data.qurancentral.com/reciters.json
```

**Implikasi untuk app Swift:** set header tersebut pada
`URLSessionConfiguration.httpAdditionalHeaders`. Tanpa `Origin`, semua request
JSON akan dibalas `403` (CDN audio `podcasts.qurancentral.com` sendiri tidak
memerlukan ini). Selain itu, jangan spam request paralel besar — riset dengan 8
koneksi paralel sempat diblokir, sedangkan request berurutan normal.

## 3. Daftar endpoint

### 3.1 Katalog qari & surah

| Endpoint | Isi | Ukuran |
| --- | --- | --- |
| `GET /reciters.json` | Semua qari (701 item) | ±143 KB |
| `GET /surahs.json` | 114 surah + deskripsi panjang | ±173 KB |
| `GET /categories/{slug}.json` | Detail 1 qari + daftar audionya | 2–200 KB |
| `GET /tags/{surah-slug}.json` | 1 surah dari semua qari | ±50 KB |

### 3.2 Teks Qur'an (fitur baca)

| Endpoint | Isi |
| --- | --- |
| `GET /features/read-quran/data/list-surah.json` | 114 surah versi ringkas |
| `GET /features/read-quran/data/list-juz.json` | 30 juz + rentang ayat |
| `GET /features/read-quran/data/list-reciters.json` | 45 qari murattal (per-ayat) |
| `GET /features/read-quran/data/quran-arabic-indopak.json` | Teks Arab IndoPak |
| `GET /features/read-quran/data/quran-arabic-uthmani-tajweed.json` | Teks Uthmani + markup tajwid |
| `GET /features/read-quran/data/quran-english-sahih.json` | Terjemahan Inggris (Sahih Intl.) |
| `GET /features/read-quran/data/quran_transliteration.json` | Transliterasi Latin |

### 3.3 Font

```
https://data.qurancentral.com/fonts/UthmanicHafs1Ver18.woff2
https://data.qurancentral.com/fonts/indopak-nastaleeq-waqf-lazim-v4.2.1.woff2
```

> ⚠️ `.woff2` **tidak bisa dipakai langsung** oleh Core Text / SwiftUI di macOS.
> Perlu dikonversi ke `.ttf`/`.otf` saat build, atau pakai font Arab sistem
> (`Geeza Pro`, `Al Nile`, `KFGQPC`) sebagai fallback. Lihat §8.

### 3.4 Audio & artwork

```
Audio    : https://podcasts.qurancentral.com/{url-relatif-dari-katalog}
Artwork  : https://artwork.qurancentral.com/{slug}-300x300.jpg
Fallback : https://data.qurancentral.com/images/artwork-fallback.jpg
           https://data.qurancentral.com/images/artwork-fallback-female.jpg
```

Field `url` pada katalog **relatif**, contoh:
`mishary-rashid-alafasy/mishary-rashid-alafasy-001-muslimcentral.com.mp3`.

Server audio mendukung **HTTP Range** (`accept-ranges: bytes`) → penting untuk
seek/scrubbing dan resume unduhan.

## 4. Skema JSON (hasil verifikasi)

### 4.1 `reciters.json` → `[Reciter]` (701 item)

```json
{
  "id": 2612,
  "slug": "aaar-al-hudhoudi",
  "name": "Aaar Al Hudhoudi",
  "post_count": 111,
  "country": "Saudi Arabia",
  "dialect": "Abu al Haarith",
  "female": true,        // opsional, hanya qari perempuan
  "mujawwad": true       // opsional, penanda gaya mujawwad
}
```

Distribusi: 191 Arab Saudi, 172 Mesir, 34 Maroko, 31 Kuwait, … Total
`post_count` = **39.738** berkas audio. Dialek: Hafs 676, Warsh 11, lainnya.

> `post_count` = jumlah audio. `0` → badge "Coming Soon" di web.

### 4.2 `surahs.json` → `[Surah]` (114 item)

```json
{
  "ID": 1,
  "Trans": "Al Faatiha",
  "Arabic": "الفاتحة",
  "Translation": "The Opener",
  "homepage": true,
  "slug": "001-al-fatiha",
  "description": "Al-Fatiha is the first surah ... (panjang)"
}
```

### 4.3 `categories/{slug}.json` → `ReciterCategory`

```json
{
  "title": "Mishary Rashid Alafasy",
  "description": "Mishary Rashid Alafasy is born on ... (HTML)",
  "image": null,
  "female": false,
  "link": "audio/mishary-rashid-alafasy/",
  "items": [
    {
      "title": "001 Al-Fatiha",
      "description": "<p>Surah 001 Al-Fatiha recited by ...</p>",
      "duration": "52",
      "url": "mishary-rashid-alafasy/mishary-rashid-alafasy-001-muslimcentral.com.mp3"
    }
  ]
}
```

Semua 701 slug di `reciters.json` punya file kategori (diverifikasi: 701/701
HTTP 200).

### 4.4 `tags/{surah-slug}.json` → `SurahTag`

Bentuk sama dengan kategori, tapi `items` berisi rekaman surah tsb. dari
**berbagai qari**. Contoh `tags/001-al-fatiha.json` punya **421 item**:

```json
{
  "title": "...",
  "items": [
    { "title": "Ahmed Abdelrazek Nasr", "duration": "28:09",
      "url": "ahmed-abdelrazek-nasr/001.mp3" }
  ]
}
```

### 4.5 `list-juz.json` → `[Juz]` (30 item)

```json
{ "index": 1,
  "start": { "surah": 1, "verse": 1 },
  "end":   { "surah": 2, "verse": 141 } }
```

### 4.6 Teks Qur'an → `[QuranVerse]` (6.236 item)

```json
{ "sura": 91, "ayah": 3,
  "text": "وَ<tajweed class=ham_wasl>ٱ</tajweed>لنّ ... <span class=end>٣</span>" }
```

Versi *tajweed* memuat markup `<tajweed class=...>` dan `<span class=end>`.
Untuk tahap awal, ambil versi IndoPak/plain dulu, atau strip tag-nya.

### 4.7 Format `duration`

Bervariasi: `"52"` (detik), `"28:09"` (mm:ss), `"2:06:16"` (h:mm:ss).
Perlu parser khusus (lihat `DurationParser`).

## 5. Alur data aplikasi web (referensi perilaku)

```
/audio                     → daftar qari (reciters.json) + grid + filter
/audio/search              → filter klien (fuse.js) atas reciters.json / surahs.json
/audio/{reciterSlug}       → categories/{slug}.json → playlist
/audio/surah/{surahSlug}   → tags/{surah-slug}.json → daftar qari utk surah itu
/audio/haramain            → daftar qari Makkah/Madinah (hardcoded di app)
/read-quran/surah/{n}      → teks Qur'an + audio per-ayat
```

Fitur web yang perlu ditiru: **favorit** (audio & qari), **riwayat putar**,
**unduh offline** (Cache API), **sleep timer**, **kecepatan putar** (0.25×–4×),
**resume posisi** per trek.

## 6. CORS

CDN audio mengirim `access-control-allow-origin: https://qurancentral.com`
(hanya origin web mereka). **Untuk aplikasi macOS native, CORS tidak berlaku** —
`URLSession` bebas mengambil file audio. Jadi hambatan CORS hanya relevan kalau
kita membuat klien berbasis browser/webview.

## 7. Legalitas & etika ⚠️

Yang **fakta** dari riset:

- Data & audio disajikan **publik tanpa autentikasi**, `robots.txt` mengizinkan.
- Nama berkas audio mengandung `muslimcentral.com` → sumber aslinya
  **Muslim Central**, bukan milik Quran Central sendiri.
- **Tidak ditemukan** lisensi terbuka eksplisit (Creative Commons / public
  domain) maupun halaman Terms of Service di bundle aplikasi.

Yang **tidak bisa** saya pastikan: status hak cipta tiap rekaman (biasanya milik
qari dan/atau label). Karena itu:

| Skenario | Rekomendasi |
| --- | --- |
| Pengembangan & pemakaian pribadi | Wajar, tapi tetap batasi laju request & sertakan atribusi |
| Distribusi publik / App Store | **Wajib** minta izin ke Muslim Central / Quran Central, atau pindah ke sumber berlisensi |
| Redistribusi berkas audio | Jangan bundel audio ke dalam installer tanpa izin |

**Alternatif sumber resmi/berlisensi** (untuk produksi):

| Sumber | Kelebihan | Catatan |
| --- | --- | --- |
| **mp3quran.net API** | API publik terdokumentasi, ratusan qari, per-surah & per-ayat | Punya syarat pemakaian |
| **Quran.com API v4** (`api.quran.com`) | Teks + terjemahan + audio per-ayat, terstruktur | Perlu daftar/atribusi |
| **EveryAyah.com** | Audio per-ayat rapi | Minta izin utk komersial |
| **Tanzil.net** | Teks Qur'an akurat (dengan atribusi) | — |

**Kesimpulan:** secara **teknis bisa** dipakai di app macOS Swift (tidak ada
blokir teknis untuk klien native). Secara **legal**, untuk app yang
*didistribusikan* sebaiknya jangan mengandalkan sumber ini tanpa izin — rancang
lapisan data agar **mudah diganti provider** (lihat dok. 02, `AudioProvider`).

## 8. Catatan teknis untuk implementasi

1. **User-Agent** wajib diset di `URLSessionConfiguration.httpAdditionalHeaders`.
2. **Cache**: `URLCache` besar (mis. 100 MB) untuk JSON & artwork; simpan
   unduhan audio di `~/Library/Application Support/`.
3. **Range request** dipakai untuk resume unduhan dan seek mulus.
4. **Konversi font** `.woff2` → `.otf` diperlukan bila ingin teks Arab persis
   seperti web (opsional, fase lanjut).
5. **Atribusi**: tampilkan sumber data & tombol dukung Muslim Central di layar
   *About*.
6. **Rate limiting**: batasi konkurensi (≤4) saat mengambil banyak kategori.

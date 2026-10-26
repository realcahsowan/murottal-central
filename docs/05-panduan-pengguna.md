# 05 — Panduan Pengguna

Panduan singkat memakai aplikasi **Murottal Central** (macOS).

## Menjalankan

```bash
# dari source
swift run MurottalCentral

# atau paket .app
Scripts/build-app.sh
open build/MurottalCentral.app
```

## Tata letak jendela

```
┌──────────────┬──────────────────────────────────────────────┐
│  Sidebar     │  Konten                                      │
│              │                                              │
│  Jelajahi    │  (grid qari / daftar surah / juz / dll.)     │
│  Koleksi     │                                              │
│  Lainnya     │                                              │
├──────────────┴──────────────────────────────────────────────┤
│  Player bar (selalu tampil)                                 │
└─────────────────────────────────────────────────────────────┘
```

## Menjelajahi katalog

| Menu | Isi |
| --- | --- |
| **Qari** | Grid qari. Ada pencarian, filter negara, dan filter dialek. |
| **Surah** | Daftar 114 surah. Membuka satu surah menampilkan semua rekamannya dari berbagai qari. |
| **Juz** | 30 juz. Membuka satu juz menampilkan surah-surah yang tercakup. |
| **Haramain** | Qari Masjidil Haram (Makkah) & Masjid Nabawi (Madinah). |
| **Cari** | Pencarian gabungan qari & surah (tab Qari / Surah). |

> Aplikasi ini **hanya menampilkan qari laki-laki**.

Membuka satu qari menampilkan playlist (bisa dicari lewat kolom pencarian di
toolbar) dan tab **Info** berisi deskripsi qari.

## Memutar audio

- Klik sebuah trek, atau tekan tombol ▶ di barisnya.
- **Player bar** di bawah: ⏮ ⏯ ⏭, geser posisi, kecepatan (0.75×–2×), acak,
  ulangi, dan sleep timer.
- Posisi putar disimpan otomatis per trek — melanjutkan dari tempat terakhir.
- Widget **Now Playing** macOS dan tombol media di keyboard berfungsi
  (judul, nama qari, artwork).

### Sleep timer

Klik ikon 🌙 di player bar (atau menu **Pemutaran → Sleep Timer**):

- **5 / 10 / 15 / 30 / 45 / 60 menit** — berhenti otomatis setelah durasi itu.
  Sisa waktu tampil di samping ikon.
- **Akhir trek ini** — berhenti setelah trek yang sedang diputar selesai.
- **Nonaktif** — membatalkan.

## Koleksi pribadi

| Menu | Isi |
| --- | --- |
| **Favorit** | Trek yang ditandai ♡. |
| **Qari Berbintang** | Qari yang ditandai ★ dari halaman detail. |
| **Riwayat** | 200 trek terakhir yang diputar (bisa dibersihkan). |
| **Unduhan** | Trek yang tersedia offline. |

## Unduhan (offline)

- Klik ikon ⬇ pada sebuah trek untuk mengunduh.
- Selama mengunduh muncul cincin progres; klik ⏸ untuk **jeda** dan ▶ untuk
  **lanjut**. Unduhan yang dijeda **bisa dilanjutkan** bahkan setelah aplikasi
  ditutup.
- Setelah selesai, trek ditandai centang hijau dan diputar dari berkas lokal
  (tanpa internet).
- Bila gagal, muncul ikon oranye — klik untuk mencoba lagi.
- Berkas disimpan di
  `~/Library/Application Support/MurottalCentral/Audio/`.

## Pengaturan

Menu **Pengaturan**:

- **Tema**: Ikuti Sistem / Terang / Gelap.
- **Foto qari**: sembunyikan foto (memakai artwork netral), tampilkan badge
  gaya (Mujawwad).
- **Teks Qur'an**: pilih font (Uthmani / IndoPak / Sistem) dan ukuran teks Arab.
- **Terjemahan**: Off / English / Bahasa Indonesia (Kemenag).
- **Penyimpanan**: ukuran & lokasi unduhan, hapus semua unduhan, kosongkan
  cache.
- **Kembalikan pengaturan awal**.

## Pintasan keyboard

| Pintasan | Aksi |
| --- | --- |
| `Space` | Putar / jeda |
| `⌘→` / `⌘←` | Trek berikutnya / sebelumnya |
| `⇧⌘S` | Acak |
| `⇧⌘L` | Ulangi |
| `⌘1` … `⌘5` | Qari · Haramain · Baca · Favorit · Unduhan |
| `⌘,` | Pengaturan |
| `⇧⌘R` | Muat ulang katalog |

## Pemecahan masalah

| Gejala | Penyebab & solusi |
| --- | --- |
| "Gagal Memuat" saat membuka aplikasi | Koneksi internet bermasalah, atau server membatasi. Tekan **⇧⌘R** untuk mencoba lagi. |
| Audio tidak berbunyi | Pastikan koneksi aktif, atau unduh treknnya untuk mode offline. Cek volume sistem. |
| Artwork tidak muncul | Server artwork sedang lambat; akan muncul otomatis. |
| Unduhan gagal terus | Coba lagi; kalau perlu hapus cache di Pengaturan. |

## Atribusi

Data katalog & audio berasal dari **Quran Central** dan **Muslim Central**.
Silakan dukung mereka lewat tautan di layar **Tentang**.

import Foundation

/// Pembentuk URL audio **per ayat** dari EveryAyah.
///
/// Pola yang dipakai Quran Central (terverifikasi dari bundle web):
///
/// ```
/// https://everyayah.com/data/{subfolder}/{SSS}{AAA}.mp3
/// ```
///
/// - `SSS` = nomor surah 3 digit (`004`)
/// - `AAA` = nomor ayat 3 digit (`148`)
///
/// Contoh: juz 6 dimulai di 4:148 → `.../Husary_128kbps/004148.mp3`.
///
/// Catatan: web menambahkan `?t=<timestamp>` sebagai cache-buster. Aplikasi ini
/// **tidak** melakukannya agar audio bisa di-cache.
public enum EveryAyah {

    public static let baseURL = URL(string: "https://everyayah.com/data")!

    /// Nama berkas, mis. `004148.mp3`.
    public static func fileName(surah: Int, ayah: Int) -> String {
        String(format: "%03d%03d.mp3", surah, ayah)
    }

    /// URL absolut untuk satu ayat.
    public static func audioURL(subfolder: String, surah: Int, ayah: Int) -> URL {
        baseURL
            .appending(path: subfolder)
            .appending(path: fileName(surah: surah, ayah: ayah))
    }

    /// URL absolut untuk satu ayat dari `AyahReciter`.
    public static func audioURL(reciter: AyahReciter, surah: Int, ayah: Int) -> URL {
        audioURL(subfolder: reciter.subfolder, surah: surah, ayah: ayah)
    }
}

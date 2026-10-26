import Foundation

/// Daftar qari Masjidil Haram (Makkah) dan Masjid Nabawi (Madinah).
///
/// Diambil dari daftar statis yang dipakai Quran Central pada halaman
/// `/audio/haramain`. Semua slug sudah diverifikasi ada di `reciters.json`.
public enum HaramainData {

    public struct Group: Identifiable, Sendable {
        public let id: String
        public let title: String
        public let reciters: [ReciterRef]

        public init(id: String, title: String, reciters: [ReciterRef]) {
            self.id = id
            self.title = title
            self.reciters = reciters
        }
    }

    public static let groups: [Group] = [
        Group(
            id: "makkah",
            title: "Makkah — Masjid Al Haram",
            reciters: [
                ReciterRef(slug: "maher-al-mueaqly", name: "Maher Al Mueaqly"),
                ReciterRef(slug: "abdullah-awad-al-juhani", name: "Abdullah Awad al-Juhani"),
                ReciterRef(slug: "bandar-balila", name: "Bandar Baleela"),
                ReciterRef(slug: "faisal-al-ghazzawi", name: "Faisal Al Ghazzawi"),
                ReciterRef(slug: "abdur-rahman-as-sudais", name: "Abdur Rahman As-Sudais"),
                ReciterRef(slug: "saleh-al-taleb", name: "Saleh Al Taleb"),
                ReciterRef(slug: "yasser-al-dossari", name: "Yasser Al Dossari"),
                ReciterRef(slug: "khalid-al-ghamdi", name: "Khalid Al Ghamdi"),
                ReciterRef(slug: "saud-al-shuraim", name: "Saud Al-Shuraim"),
                ReciterRef(slug: "saleh-bin-humaid", name: "Saleh bin Humaid"),
                ReciterRef(slug: "badr-al-turki", name: "Badr Al-Turki"),
                ReciterRef(slug: "waleed-al-shamsan", name: "Waleed Al Shamsan"),
                ReciterRef(slug: "usaamah-khayyat", name: "Usaamah Khayyat"),
                ReciterRef(slug: "muhammad-al-subayyil", name: "Muhammad Al Subayyil"),
            ]
        ),
        Group(
            id: "madinah",
            title: "Madinah — Masjid An Nabawi",
            reciters: [
                ReciterRef(slug: "ali-abdur-rahman-al-huthaify", name: "Ali Abdur-Rahman al-Huthaify"),
                ReciterRef(slug: "abdul-muhsin-al-qasim", name: "Abdul Muhsin Al Qasim"),
                ReciterRef(slug: "salah-al-budair", name: "Salah Al-Budair"),
                ReciterRef(slug: "abdulbari-ath-thubaity", name: "AbdulBari ath-Thubaity"),
                ReciterRef(slug: "abdullah-al-buajan", name: "Abdullah Al Buajan"),
                ReciterRef(slug: "hussein-al-sheikh", name: "Hussein Al-Sheikh"),
                ReciterRef(slug: "ahmad-taleb-hameed", name: "Ahmad Taleb Hameed"),
                ReciterRef(slug: "khalid-al-mohanna", name: "Khalid Al Mohanna"),
                ReciterRef(slug: "ahmed-al-hodaifi", name: "Ahmed Al-Huthaify"),
                ReciterRef(slug: "muhammad-barhaji", name: "Muhammad Barhaji"),
                ReciterRef(slug: "abdullah-al-qarafi", name: "Abdullah Al Qarafi"),
                ReciterRef(slug: "ibrahim-al-akhdar", name: "Ibrahim Al Akhdar"),
            ]
        ),
    ]
}

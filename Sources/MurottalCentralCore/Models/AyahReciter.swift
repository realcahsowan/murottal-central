import Foundation

/// Qari untuk audio **per ayat** (sumber EveryAyah).
///
/// Berbeda dari `Reciter` (audio per surah dari Quran Central). Daftar ini
/// berasal dari `features/read-quran/data/list-reciters.json`, berbentuk objek
/// dengan key berupa ID numerik.
public struct AyahReciter: Identifiable, Hashable, Sendable {
    public let id: Int
    /// Nama folder di EveryAyah, mis. `Abdul_Basit_Murattal_192kbps`
    /// (bisa memuat sub-path, mis. `warsh/warsh_ibrahim_aldosary_128kbps`).
    public let subfolder: String
    public let name: String
    public let bitrate: String

    public init(id: Int, subfolder: String, name: String, bitrate: String) {
        self.id = id
        self.subfolder = subfolder
        self.name = name
        self.bitrate = bitrate
    }

    /// Label ringkas, mis. `Abdul Basit As-Samad (Murattal) · 192kbps`.
    public var displayName: String {
        bitrate.isEmpty ? name : "\(name) · \(bitrate)"
    }
}

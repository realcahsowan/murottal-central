# 02 — Arsitektur & Struktur Data

## 1. Prinsip

1. **Core tanpa UI** — semua model, networking, dan audio ada di target
   `MurottalCentralCore` agar bisa dites tanpa membuka jendela.
2. **Provider bisa diganti** — sumber data dibungkus protokol `QuranDataSource`
   sehingga mudah pindah dari Quran Central ke mp3quran.net/Quran.com.
3. **Offline-first** — katalog di-cache, audio bisa diunduh penuh, pemutaran
   fallback ke berkas lokal.
4. **Concurrency aman (Swift 6)** — client berupa `actor`, model `Sendable`,
   state UI `@MainActor @Observable`.

## 2. Layer

```
┌──────────────────────────────────────────────────────────┐
│  MurottalCentralApp  (SwiftUI, @MainActor)               │
│  RootView · Sidebar · Grid · Detail · PlayerBar · Settings│
└───────────────▲──────────────────────────────────────────┘
                │  @Observable AppState
┌───────────────┴──────────────────────────────────────────┐
│  MurottalCentralCore                                      │
│  ┌────────────┐  ┌──────────────┐  ┌───────────────────┐  │
│  │ Models     │  │ Networking   │  │ Audio             │  │
│  │ Codable    │  │ actor Client │  │ AudioPlayer (AVF) │  │
│  │ Sendable   │  │ URLCache     │  │ DownloadManager   │  │
│  └────────────┘  └──────┬───────┘  └─────────┬─────────┘  │
│  ┌────────────────────┐ │                    │            │
│  │ Persistence        │ │                    │            │
│  │ Favorites/History  │ │                    │            │
│  └────────────────────┘ │                    │            │
└─────────────────────────┼────────────────────┼────────────┘
                          ▼                    ▼
              data.qurancentral.com   podcasts.qurancentral.com
              artwork.qurancentral.com
```

## 3. Struktur folder

```
Sources/
├── MurottalCentralCore/
│   ├── Models/
│   │   ├── Reciter.swift
│   │   ├── Surah.swift
│   │   ├── AudioTrack.swift
│   │   ├── ReciterCategory.swift
│   │   ├── SurahTag.swift
│   │   ├── Juz.swift
│   │   ├── QuranVerse.swift
│   │   ├── ReciterRef.swift
│   │   └── HaramainData.swift
│   ├── Networking/
│   │   ├── QCEndpoints.swift
│   │   ├── QuranDataSource.swift
│   │   └── QuranCentralClient.swift
│   ├── Audio/
│   │   ├── AudioPlayer.swift
│   │   ├── DownloadManager.swift
│   │   ├── DownloadDelegate.swift
│   │   └── DownloadStatusStore.swift
│   ├── Persistence/
│   │   ├── FavoritesStore.swift
│   │   ├── PlaybackHistoryStore.swift
│   │   └── JSONFileStore.swift
│   ├── Settings/
│   │   └── AppSettings.swift
│   └── Utilities/
│       ├── DurationParser.swift
│       ├── ArtworkResolver.swift
│       └── CatalogSearch.swift
└── MurottalCentralApp/
    ├── App/MurottalCentralApp.swift
    ├── State/AppState.swift
    └── Views/...
```

## 4. Model data (Swift)

Semua model `Codable + Sendable + Hashable`, memakai `CodingKeys` untuk
memetakan nama JSON yang tidak konvensional (`ID`, `Trans`, `post_count`, …).

### 4.1 Reciter

```swift
public struct Reciter: Codable, Identifiable, Hashable, Sendable {
    public let id: Int
    public let slug: String
    public let name: String
    public let postCount: Int
    public let country: String?
    public let dialect: String?
    public let female: Bool?
    public let mujawwad: Bool?

    enum CodingKeys: String, CodingKey {
        case id, slug, name, country, dialect, female, mujawwad
        case postCount = "post_count"
    }
}
```

### 4.2 Surah

```swift
public struct Surah: Codable, Identifiable, Hashable, Sendable {
    public let id: Int                 // "ID"
    public let transliteration: String // "Trans"
    public let arabic: String          // "Arabic"
    public let translation: String     // "Translation"
    public let homepage: Bool?
    public let slug: String
    public let description: String?

    enum CodingKeys: String, CodingKey {
        case id = "ID"
        case transliteration = "Trans"
        case arabic = "Arabic"
        case translation = "Translation"
        case homepage, slug, description
    }
}
```

### 4.3 AudioTrack (unit putar terkecil)

```swift
public struct AudioTrack: Codable, Hashable, Identifiable, Sendable {
    public let title: String
    public let description: String?
    public let duration: String?   // "52" | "28:09" | "2:06:16"
    public let url: String         // relatif ke podcasts.qurancentral.com
    public var id: String { url }

    /// URL absolut siap dipakai AVPlayer.
    public var streamURL: URL { QCEndpoints.audioURL(for: url) }
    public var durationSeconds: Int? { DurationParser.seconds(from: duration) }
}
```

### 4.4 Kategori qari & tag surah

```swift
public struct ReciterCategory: Codable, Sendable {
    public let title: String
    public let description: String?
    public let image: String?
    public let female: Bool?
    public let link: String?
    public let items: [AudioTrack]
}

public struct SurahTag: Codable, Sendable {
    public let title: String
    public let items: [AudioTrack]
}
```

### 4.5 Juz & ayat

```swift
public struct Juz: Codable, Identifiable, Hashable, Sendable {
    public let index: Int
    public let start: VerseRef
    public let end: VerseRef
    public var id: Int { index }
}

public struct VerseRef: Codable, Hashable, Sendable {
    public let surah: Int
    public let verse: Int
}

public struct QuranVerse: Codable, Hashable, Sendable {
    public let sura: Int
    public let ayah: Int
    public let text: String
}
```

## 5. Endpoint helper

```swift
public enum QCEndpoints {
    public static let dataBase    = URL(string: "https://data.qurancentral.com")!
    public static let audioBase   = URL(string: "https://podcasts.qurancentral.com")!
    public static let artworkBase = URL(string: "https://artwork.qurancentral.com")!

    public static var reciters: URL { dataBase.appending(path: "reciters.json") }
    public static var surahs: URL   { dataBase.appending(path: "surahs.json") }

    public static func category(_ slug: String) -> URL {
        dataBase.appending(path: "categories/\(slug).json")
    }
    public static func surahTag(_ slug: String) -> URL {
        dataBase.appending(path: "tags/\(slug).json")
    }
    public static func audioURL(for relative: String) -> URL {
        audioBase.appending(path: relative)
    }
    public static func artworkURL(for slug: String) -> URL {
        artworkBase.appending(path: "\(ArtworkResolver.artworkSlug(for: slug))-300x300.jpg")
    }
}
```

## 6. Client (actor)

```swift
public actor QuranCentralClient: QuranDataSource {
    private let session: URLSession
    private let decoder: JSONDecoder
    private var inFlight: [URL: Task<Data, Error>] = [:]   // de-duplikasi request

    public init(cacheSizeMB: Int = 128) {
        let cfg = URLSessionConfiguration.default
        cfg.httpAdditionalHeaders = [
            "User-Agent": "MurottalCentral/0.1 (macOS)",
            "Origin": "https://qurancentral.com",   // WAJIB, jika tidak → 403
            "Referer": "https://qurancentral.com/",
        ]
        cfg.urlCache = URLCache(memoryCapacity: 16 << 20,
                                diskCapacity: cacheSizeMB << 20)
        cfg.requestCachePolicy = .useProtocolCachePolicy
        cfg.waitsForConnectivity = true
        session = URLSession(configuration: cfg)
        decoder = JSONDecoder()
    }

    public func reciters() async throws -> [Reciter] { try await get(QCEndpoints.reciters) }
    public func surahs()   async throws -> [Surah]   { try await get(QCEndpoints.surahs) }
    public func category(_ slug: String) async throws -> ReciterCategory {
        try await get(QCEndpoints.category(slug))
    }
    public func surahTag(_ slug: String) async throws -> SurahTag {
        try await get(QCEndpoints.surahTag(slug))
    }
    // …
}
```

**Detail penting:**

- `inFlight` mencegah dua view memicu request sama bersamaan.
- Semua error dinormalkan ke `QuranCentralError` (`.http(Int)`, `.decoding`, `.transport`).
- Tambahkan **rate limiter** sederhana (maks 4 task) untuk endpoint massal.

## 7. Audio

### 7.1 `AudioPlayer`

Dibungkus `AVPlayer` + `AVAudioSession` (macOS pakai `AVPlayer` saja).

```swift
@MainActor
public final class AudioPlayer: ObservableObject {
    @Published public private(set) var current: AudioTrack?
    @Published public private(set) var isPlaying = false
    @Published public var queue: [AudioTrack] = []
    @Published public var index: Int = 0
    @Published public var rate: Float = 1.0
    @Published public var currentTime: Double = 0
    @Published public var duration: Double = 0

    public func play(_ tracks: [AudioTrack], at index: Int) { … }
    public func togglePlayPause() { … }
    public func next() / previous() { … }
    public func seek(to seconds: Double) { … }
}
```

- **Resume posisi**: simpan `currentTime` per `track.url` (mirip web yang pakai
  `localStorage["{url}:0:0"]`).
- **Media keys / Now Playing**: `MPNowPlayingInfoCenter` + `MPRemoteCommandCenter`
  (play/pause/next/previous/seek + artwork). Sudah diimplementasikan.
- **Sleep timer** dan **repeat/shuffle** sebagai fitur fase lanjut.

#### ⚠️ Jebakan: closure `@MainActor` yang dipanggil framework dari queue lain

`MPMediaItemArtwork(boundsSize:requestHandler:)` dipanggil MediaPlayer dari
**queue internalnya** (`*/accessQueue`), bukan main thread. Bila closure
dibuat langsung di dalam method `@MainActor`, Swift 6 menyimpulkan closure itu
`@MainActor`-isolated; saat dipanggil dari queue lain, assertion isolasi gagal
→ `dispatch_assert_queue_fail` → **SIGILL** (app crash).

```swift
// ❌ Crash: closure mewarisi isolasi MainActor
await MainActor.run {
    self.nowPlayingArtwork = MPMediaItemArtwork(boundsSize: image.size) { _ in image }
}

// ✅ Aman: dibuat di fungsi nonisolated
nonisolated static func makeArtwork(from image: NSImage) -> MPMediaItemArtwork {
    MPMediaItemArtwork(boundsSize: image.size) { _ in image }
}
```

Aturan umum: setiap closure yang diserahkan ke framework dan **tidak dijamin
dipanggil di main thread** harus dibuat di konteks `nonisolated`, atau ditandai
`@Sendable`. Ini diterapkan pada handler artwork dan handler
`MPRemoteCommandCenter`; handler `addPeriodicTimeObserver` &
`NotificationCenter.addObserver` memakai `queue: .main` plus `@Sendable`.

Regresi ini dikunci oleh tes `AudioPlayerArtworkTests` dan
`LiveIntegrationTests.testPlayingPublishesNowPlayingWithoutCrash` (memutar trek
nyata lalu memastikan tidak crash).

### 7.2 `DownloadManager`

```swift
public actor DownloadManager {
    public func download(_ track: AudioTrack) async throws -> URL
    public func localURL(for track: AudioTrack) -> URL?   // cek berkas unduhan
    public func delete(_ track: AudioTrack) throws
}
```

- Simpan di `Application Support/MurottalCentral/Audio/{reciterSlug}/{file}.mp3`.
- `URLSessionDownloadDelegate` (`DownloadDelegate`) melaporkan progres ke
  `DownloadStatusStore` (`@MainActor @Observable`) sehingga UI bereaksi.
- Pemutar: jika berkas lokal ada → putar lokal, jika tidak → streaming.
- Resume unduhan (`resumeData`) belum diimplementasikan.

## 8. Persistensi

| Data | Penyimpanan | Alasan |
| --- | --- | --- |
| Favorit (audio & qari) | `JSONEncoder` → file di Application Support | portabel, mudah debug |
| Riwayat putar | file JSON (batas 200 entri) | — |
| Posisi putar per trek | `UserDefaults` (`[String: Double]`) | sering berubah |
| Pengaturan | `@AppStorage` | terikat UI |
| Katalog (reciters/surahs) | `URLCache` + snapshot JSON | offline |

## 9. Konfigurasi & tema

`AppSettings` (`@Observable`) berisi: tema (system/light/dark), hide foto
perempuan/laki-laki (meniru opsi web), kualitas unduhan, bahasa.

## 10. Penanganan error & state

Setiap layar punya 4 state eksplisit — **loading / empty / error / loaded** —
dibungkus komponen generik `AsyncContentView`, supaya konsisten dan tidak
mengulang kode (lihat dok. 03).

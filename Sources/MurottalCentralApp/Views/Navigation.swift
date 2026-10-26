import MurottalCentralCore
import SwiftUI

/// Item navigasi pada sidebar.
enum SidebarItem: String, CaseIterable, Identifiable {
    // Jelajahi — ditampilkan di sidebar
    case reciters, haramain, reading
    // Tersembunyi dari sidebar, tetapi masih tersedia sebagai rute internal
    // (dipakai oleh pintasan lama / pengembangan berikutnya).
    case surahs, juz, search
    // Koleksi saya
    case favorites, starred, history, downloads
    // Lainnya
    case settings, about

    var id: String { rawValue }

    var title: String {
        switch self {
        case .reciters: return "Qari"
        case .surahs: return "Surah"
        case .juz: return "Juz"
        case .haramain: return "Haramain"
        case .reading: return "Baca"
        case .search: return "Cari"
        case .favorites: return "Favorit"
        case .starred: return "Qari Berbintang"
        case .history: return "Riwayat"
        case .downloads: return "Unduhan"
        case .settings: return "Pengaturan"
        case .about: return "Tentang"
        }
    }

    var systemImage: String {
        switch self {
        case .reciters: return "person.wave.2"
        case .surahs: return "book"
        case .juz: return "square.stack.3d.up"
        case .haramain: return "building.columns"
        case .reading: return "text.book.closed"
        case .search: return "magnifyingglass"
        case .favorites: return "heart"
        case .starred: return "star"
        case .history: return "clock.arrow.circlepath"
        case .downloads: return "arrow.down.circle"
        case .settings: return "gearshape"
        case .about: return "info.circle"
        }
    }
}

/// Cakupan layar baca: satu surah atau satu juz.
enum ReadingScope: Hashable {
    case surah(Surah)
    case juz(Juz)

    var title: String {
        switch self {
        case let .surah(surah): return surah.displayTitle
        case let .juz(juz): return "Juz \(juz.index)"
        }
    }

    var subtitle: String {
        switch self {
        case let .surah(surah): return surah.translation
        case let .juz(juz): return "\(juz.start.surah):\(juz.start.verse) – \(juz.end.surah):\(juz.end.verse)"
        }
    }
}

/// Rute navigasi pada kolom detail.
enum Route: Hashable {
    case reciter(Reciter)
    case surah(Surah)
    case juz(Juz)
    case reading(ReadingScope)
}

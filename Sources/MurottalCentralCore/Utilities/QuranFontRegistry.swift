import AppKit
import CoreText
import Foundation

/// Mendaftarkan font Qur'an yang dibundel agar bisa dipakai Core Text/AppKit.
///
/// Catatan: sengaja **tidak** memakai `Bundle.module` karena accessor yang
/// dihasilkan SwiftPM menyimpan path build absolut sebagai fallback dan akan
/// `fatalError` bila bundle tidak ditemukan di mesin pengguna. Di sini bundle
/// dicari lewat beberapa kandidat path yang aman.
public enum QuranFontRegistry {

    /// Font yang dibundel (selain font sistem).
    public static let bundledFonts: [QuranFont] = [.uthmani, .indopak]

    /// Nama bundle resource yang dihasilkan SwiftPM (`<Package>_<Target>.bundle`).
    private static let resourceBundleName = "MurottalCentral_MurottalCentralCore.bundle"

    /// Daftarkan semua font yang dibundel. Aman dipanggil berulang kali.
    @discardableResult
    public static func registerBundledFonts() -> [String] {
        var registered: [String] = []

        for font in bundledFonts {
            guard let fileName = font.bundledFileName, let url = fontURL(fileName) else {
                continue
            }

            var error: Unmanaged<CFError>?
            let success = CTFontManagerRegisterFontsForURL(url as CFURL, .process, &error)

            if success {
                registered.append(fileName)
            } else if let error {
                // Kesalahan "already registered" bukan masalah.
                let description = String(describing: error.takeRetainedValue())
                if !description.localizedCaseInsensitiveContains("already") {
                    print("Font \(fileName) gagal didaftarkan: \(description)")
                }
            }
        }

        return registered
    }

    /// Apakah font bisa dipakai (system selalu dianggap tersedia).
    public static func isAvailable(_ font: QuranFont) -> Bool {
        guard let name = font.postScriptName else { return true }
        return NSFont(name: name, size: 12) != nil
    }

    /// Lokasi font di disk (untuk diagnostik/tes).
    public static func fileURL(for font: QuranFont) -> URL? {
        guard let fileName = font.bundledFileName else { return nil }
        return fontURL(fileName)
    }

    // MARK: - Privat

    /// Token untuk menemukan bundle tempat kode Core dimuat (berguna di test).
    private final class BundleToken {}

    private static func resourceBundle() -> Bundle? {
        var bases: [URL] = []

        if let resources = Bundle.main.resourceURL {
            bases.append(resources)
        }
        bases.append(Bundle.main.bundleURL)

        let tokenURL = Bundle(for: BundleToken.self).bundleURL
        bases.append(tokenURL)
        bases.append(tokenURL.deletingLastPathComponent())

        var candidates: [URL] = []
        for base in bases {
            candidates.append(base.appendingPathComponent(resourceBundleName))
            candidates.append(
                base.appendingPathComponent("Contents/Resources/\(resourceBundleName)")
            )
        }

        for url in candidates {
            if let bundle = Bundle(url: url) {
                return bundle
            }
        }
        return nil
    }

    private static func fontURL(_ fileName: String) -> URL? {
        guard let bundle = resourceBundle() else { return nil }
        return bundle.url(forResource: fileName, withExtension: "ttf", subdirectory: "Fonts")
            ?? bundle.url(forResource: fileName, withExtension: "ttf")
    }
}

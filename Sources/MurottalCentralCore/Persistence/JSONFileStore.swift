import Foundation

/// Penyimpanan JSON sederhana ke Application Support.
struct JSONFileStore {
    let url: URL

    init(fileName: String) {
        let base = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first ?? FileManager.default.temporaryDirectory
        let directory = base.appending(path: "MurottalCentral")
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        self.url = directory.appending(path: fileName)
    }

    func load<T: Decodable>(_ type: T.Type, default fallback: T) -> T {
        guard let data = try? Data(contentsOf: url) else { return fallback }
        return (try? JSONDecoder().decode(T.self, from: data)) ?? fallback
    }

    func save<T: Encodable>(_ value: T) {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        guard let data = try? encoder.encode(value) else { return }
        try? data.write(to: url, options: .atomic)
    }
}

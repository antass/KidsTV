import Foundation
import Observation

/// Holds the catalog shown on screen.
///
/// Load order: last good copy downloaded → copy bundled in the app. Then it
/// fetches the live `shows.json` from GitHub, so editing that file (even from
/// a phone) updates the Apple TV next time the app opens. No rebuild needed.
@Observable
final class CatalogStore {
    /// The editable catalog. Change this if the repo moves.
    static let remoteURL = URL(string: "https://raw.githubusercontent.com/antass/KidsTV/main/KidsTV/Data/shows.json")!

    private(set) var catalog: CatalogFile
    private(set) var lastRefresh: Date?

    private let cacheURL: URL = {
        let dir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        return dir.appendingPathComponent("shows.json")
    }()

    init() {
        catalog = CatalogFile()
        catalog = Self.decode(try? Data(contentsOf: cacheURL)) ?? Self.bundled() ?? CatalogFile()
    }

    /// Fetches the live catalog. Keeps what's on screen if anything goes wrong.
    func refresh() async {
        var request = URLRequest(url: Self.remoteURL, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 10)
        request.setValue("no-cache", forHTTPHeaderField: "Cache-Control")
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard (response as? HTTPURLResponse)?.statusCode == 200,
                  let fresh = Self.decode(data), !fresh.shows.isEmpty else { return }
            catalog = fresh
            lastRefresh = .now
            try? data.write(to: cacheURL, options: .atomic)
        } catch {
            // Offline or GitHub unreachable: the cached/bundled catalog stays up.
        }
    }

    private static func bundled() -> CatalogFile? {
        let url = Bundle.main.url(forResource: "shows", withExtension: "json")
            ?? Bundle.main.url(forResource: "shows", withExtension: "json", subdirectory: "Data")
        return decode(url.flatMap { try? Data(contentsOf: $0) })
    }

    private static func decode(_ data: Data?) -> CatalogFile? {
        guard let data else { return nil }
        return try? JSONDecoder().decode(CatalogFile.self, from: data)
    }
}

import Foundation

final class Catalog: ObservableObject {
    @Published private(set) var shows: [Show] = []

    init() {
        load()
    }

    func load() {
        guard let url = Bundle.main.url(forResource: "shows", withExtension: "json") else {
            assertionFailure("shows.json missing from app bundle")
            return
        }
        do {
            let data = try Data(contentsOf: url)
            shows = try JSONDecoder().decode([Show].self, from: data)
        } catch {
            assertionFailure("Failed to decode shows.json: \(error)")
        }
    }
}

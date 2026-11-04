import CoreLocation
import Foundation

struct Place: Identifiable, Hashable {
    let name: String
    let kind: PlaceKind
    /// Name of the next-bigger place this one sits inside.
    let parent: String?
    let latitude: Double
    let longitude: Double
    /// How far away the map camera sits (meters) so the whole place fits.
    let zoom: Double
    var emoji: String? = nil
    var note: String? = nil
    /// Names that are two kinds at once (Australia, New York). Taught in
    /// Zoom and the cheat sheet, but kept out of the "What is it?" quiz.
    var tricky = false
    /// Overrides the kind's word, e.g. "Province" for Canada's pieces.
    var word: String? = nil
    var meaning: String? = nil
    /// Name in the Natural Earth map data, when it differs.
    var mapName: String? = nil

    var kindWord: String { word ?? kind.name }
    var kindMeaning: String { meaning ?? kind.meaning }

    var id: String { "\(kind.rawValue)-\(name)" }
    var coordinate: CLLocationCoordinate2D { .init(latitude: latitude, longitude: longitude) }

    /// "the United States" reads right in a sentence; "the Boston" doesn't.
    var inSentence: String { name.hasPrefix("United") ? "the \(name)" : name }
    var title: String { [emoji, name].compactMap { $0 }.joined(separator: " ") }
}

/// Every place the app knows. Add a place by adding one line; its `parent`
/// must match the name of a bigger place already in the list.
enum Atlas {
    static let earth = Place(name: "Earth", kind: .planet, parent: nil,
                             latitude: 20, longitude: -40, zoom: 25_000_000, emoji: "🌍")

    static let places: [Place] = [
        earth,

        // Continents
        Place(name: "North America", kind: .continent, parent: "Earth", latitude: 45, longitude: -100, zoom: 9_000_000),
        Place(name: "South America", kind: .continent, parent: "Earth", latitude: -15, longitude: -60, zoom: 9_000_000),
        Place(name: "Europe", kind: .continent, parent: "Earth", latitude: 52, longitude: 15, zoom: 6_500_000),
        Place(name: "Africa", kind: .continent, parent: "Earth", latitude: 3, longitude: 20, zoom: 10_000_000),
        Place(name: "Asia", kind: .continent, parent: "Earth", latitude: 40, longitude: 90, zoom: 12_000_000),
        Place(name: "Australia", kind: .continent, parent: "Earth", latitude: -25, longitude: 134, zoom: 6_500_000,
              note: "Australia is a continent AND a country! It's the only place that's both.", tricky: true),
        Place(name: "Antarctica", kind: .continent, parent: "Earth", latitude: -80, longitude: 0, zoom: 8_000_000,
              emoji: "🐧", note: "Antarctica has no countries and no cities. Just ice and penguins!"),

        // Countries
        Place(name: "United States", kind: .country, parent: "North America", latitude: 39.8, longitude: -98.6, zoom: 6_000_000,
              emoji: "🇺🇸", note: "The United States is cut into 50 states, like a 50-piece puzzle.",
              mapName: "United States of America"),
        Place(name: "Canada", kind: .country, parent: "North America", latitude: 58, longitude: -100, zoom: 6_500_000,
              emoji: "🇨🇦", note: "Canada's pieces are called provinces instead of states."),
        Place(name: "Mexico", kind: .country, parent: "North America", latitude: 23.6, longitude: -102.5, zoom: 3_500_000, emoji: "🇲🇽"),
        Place(name: "Brazil", kind: .country, parent: "South America", latitude: -10, longitude: -53, zoom: 5_500_000, emoji: "🇧🇷"),
        Place(name: "Poland", kind: .country, parent: "Europe", latitude: 52, longitude: 19, zoom: 1_300_000, emoji: "🇵🇱"),
        Place(name: "France", kind: .country, parent: "Europe", latitude: 46.6, longitude: 2.4, zoom: 1_500_000, emoji: "🇫🇷"),
        Place(name: "Italy", kind: .country, parent: "Europe", latitude: 42.5, longitude: 12.5, zoom: 1_600_000, emoji: "🇮🇹"),
        Place(name: "United Kingdom", kind: .country, parent: "Europe", latitude: 54, longitude: -2.5, zoom: 1_500_000, emoji: "🇬🇧"),
        Place(name: "Germany", kind: .country, parent: "Europe", latitude: 51, longitude: 10, zoom: 1_300_000, emoji: "🇩🇪"),
        Place(name: "Egypt", kind: .country, parent: "Africa", latitude: 26.8, longitude: 30.8, zoom: 2_000_000, emoji: "🇪🇬"),
        Place(name: "Kenya", kind: .country, parent: "Africa", latitude: 0.2, longitude: 37.9, zoom: 1_500_000, emoji: "🇰🇪"),
        Place(name: "Japan", kind: .country, parent: "Asia", latitude: 36.2, longitude: 138.2, zoom: 2_500_000, emoji: "🇯🇵"),
        Place(name: "China", kind: .country, parent: "Asia", latitude: 35, longitude: 104, zoom: 6_000_000, emoji: "🇨🇳"),
        Place(name: "India", kind: .country, parent: "Asia", latitude: 21, longitude: 78, zoom: 4_000_000, emoji: "🇮🇳"),
        Place(name: "Australia", kind: .country, parent: "Australia", latitude: -25, longitude: 134, zoom: 5_500_000,
              emoji: "🇦🇺", note: "Australia is a country AND a continent! It's the only place that's both.", tricky: true),

        // States
        Place(name: "Massachusetts", kind: .state, parent: "United States", latitude: 42.25, longitude: -71.8, zoom: 350_000,
              note: "This is our state!"),
        Place(name: "Florida", kind: .state, parent: "United States", latitude: 28, longitude: -82.5, zoom: 1_100_000),
        Place(name: "California", kind: .state, parent: "United States", latitude: 37, longitude: -119.5, zoom: 1_500_000),
        Place(name: "Texas", kind: .state, parent: "United States", latitude: 31, longitude: -99.5, zoom: 1_600_000),
        Place(name: "New York", kind: .state, parent: "United States", latitude: 42.9, longitude: -75.5, zoom: 800_000,
              note: "Tricky! New York is a state. The big city inside it is called New York City.", tricky: true),
        Place(name: "Illinois", kind: .state, parent: "United States", latitude: 40, longitude: -89.2, zoom: 700_000),
        Place(name: "Maine", kind: .state, parent: "United States", latitude: 45.3, longitude: -69.2, zoom: 500_000),
        Place(name: "Hawaii", kind: .state, parent: "United States", latitude: 20.5, longitude: -157, zoom: 700_000,
              note: "Hawaii is a state made of islands, far out in the ocean."),
        Place(name: "Alaska", kind: .state, parent: "United States", latitude: 64, longitude: -150, zoom: 2_500_000,
              note: "Alaska is the biggest state of all 50."),
        Place(name: "New South Wales", kind: .state, parent: "Australia", latitude: -32.5, longitude: 147, zoom: 1_400_000,
              note: "Australia has states too, just like the United States."),
        Place(name: "Ontario", kind: .state, parent: "Canada", latitude: 49, longitude: -85, zoom: 1_600_000,
              tricky: true, word: "Province",
              meaning: "A piece of a country, like a puzzle piece. Canada calls its pieces provinces instead of states."),

        // Cities
        Place(name: "Boston", kind: .city, parent: "Massachusetts", latitude: 42.36, longitude: -71.06, zoom: 30_000,
              emoji: "🏠", note: "We live here, in East Boston!"),
        Place(name: "Orlando", kind: .city, parent: "Florida", latitude: 28.54, longitude: -81.38, zoom: 40_000),
        Place(name: "Miami", kind: .city, parent: "Florida", latitude: 25.76, longitude: -80.19, zoom: 40_000),
        Place(name: "Los Angeles", kind: .city, parent: "California", latitude: 34.05, longitude: -118.24, zoom: 60_000),
        Place(name: "Houston", kind: .city, parent: "Texas", latitude: 29.76, longitude: -95.37, zoom: 60_000),
        Place(name: "New York City", kind: .city, parent: "New York", latitude: 40.71, longitude: -74.0, zoom: 40_000,
              note: "New York City is a city inside the state of New York. Same name, different sizes!"),
        Place(name: "Chicago", kind: .city, parent: "Illinois", latitude: 41.88, longitude: -87.63, zoom: 40_000),
        Place(name: "Honolulu", kind: .city, parent: "Hawaii", latitude: 21.31, longitude: -157.86, zoom: 30_000),
        Place(name: "Sydney", kind: .city, parent: "New South Wales", latitude: -33.87, longitude: 151.21, zoom: 50_000),
        Place(name: "Toronto", kind: .city, parent: "Ontario", latitude: 43.65, longitude: -79.38, zoom: 30_000),
        Place(name: "Mexico City", kind: .city, parent: "Mexico", latitude: 19.43, longitude: -99.13, zoom: 50_000),
        Place(name: "Rio de Janeiro", kind: .city, parent: "Brazil", latitude: -22.9, longitude: -43.2, zoom: 40_000),
        Place(name: "Warsaw", kind: .city, parent: "Poland", latitude: 52.23, longitude: 21.01, zoom: 30_000),
        Place(name: "Paris", kind: .city, parent: "France", latitude: 48.86, longitude: 2.35, zoom: 25_000),
        Place(name: "Rome", kind: .city, parent: "Italy", latitude: 41.9, longitude: 12.5, zoom: 25_000),
        Place(name: "London", kind: .city, parent: "United Kingdom", latitude: 51.5, longitude: -0.13, zoom: 40_000),
        Place(name: "Berlin", kind: .city, parent: "Germany", latitude: 52.52, longitude: 13.4, zoom: 30_000),
        Place(name: "Cairo", kind: .city, parent: "Egypt", latitude: 30.04, longitude: 31.24, zoom: 40_000),
        Place(name: "Nairobi", kind: .city, parent: "Kenya", latitude: -1.29, longitude: 36.82, zoom: 30_000),
        Place(name: "Tokyo", kind: .city, parent: "Japan", latitude: 35.68, longitude: 139.69, zoom: 60_000),
        Place(name: "Beijing", kind: .city, parent: "China", latitude: 39.9, longitude: 116.4, zoom: 60_000),
        Place(name: "Mumbai", kind: .city, parent: "India", latitude: 19.08, longitude: 72.88, zoom: 40_000),
    ]

    static let home = place("Boston", .city)!

    /// Destinations for the Zoom screen, in chip order. Home first.
    static let trips: [Place] = [
        "Boston", "Orlando", "New York City", "Honolulu", "Toronto", "Mexico City",
        "Rio de Janeiro", "London", "Paris", "Warsaw", "Cairo", "Tokyo", "Sydney",
    ].compactMap { place($0, .city) } + [place("Antarctica", .continent)].compactMap { $0 }

    /// Names that only mean one thing, for the "What is it?" quiz.
    static let quizPlaces: [Place] = places.filter { $0.kind != .planet && !$0.tricky }

    /// Every city, for Stack It (each has at least continent → country → city).
    static let stackTargets: [Place] = places.filter { $0.kind == .city }

    static func place(_ name: String, _ kind: PlaceKind) -> Place? {
        places.first { $0.name == name && $0.kind == kind }
    }

    static func parent(of place: Place) -> Place? {
        guard let name = place.parent else { return nil }
        return places.first { $0.name == name && $0.kind < place.kind }
    }

    /// Earth → … → place, biggest first.
    static func chain(to place: Place) -> [Place] {
        var result = [place]
        var current = place
        while let up = parent(of: current) {
            result.insert(up, at: 0)
            current = up
        }
        return result
    }

    /// "Boston, Massachusetts, United States, North America, Earth"
    static func address(of place: Place) -> String {
        chain(to: place).reversed().map(\.name).joined(separator: ", ")
    }

    /// "Massachusetts is a state. A state is a piece of a country… It is inside the United States."
    static func sentence(for place: Place) -> String {
        var parts = ["\(place.name) is a \(place.kindWord.lowercased()).", place.kindMeaning]
        if let up = parent(of: place) {
            parts.append("\(place.name) is inside \(up.inSentence).")
        }
        if let note = place.note { parts.append(note) }
        return parts.joined(separator: " ")
    }
}

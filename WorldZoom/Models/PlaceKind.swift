import SwiftUI

/// The five sizes of place, biggest first. Every screen uses the same color,
/// icon, and word for each one so Charlie can lean on all three at once.
enum PlaceKind: Int, CaseIterable, Identifiable, Comparable {
    case planet, continent, country, state, city

    var id: Int { rawValue }

    static func < (lhs: PlaceKind, rhs: PlaceKind) -> Bool { lhs.rawValue < rhs.rawValue }

    /// The four kinds the games ask about (Earth is always the outer box).
    static let quizKinds: [PlaceKind] = [.continent, .country, .state, .city]

    var name: String {
        switch self {
        case .planet: "Planet"
        case .continent: "Continent"
        case .country: "Country"
        case .state: "State"
        case .city: "City"
        }
    }

    var plural: String {
        switch self {
        case .planet: "Planets"
        case .continent: "Continents"
        case .country: "Countries"
        case .state: "States"
        case .city: "Cities"
        }
    }

    var color: Color {
        switch self {
        case .planet: Color(red: 0.13, green: 0.67, blue: 0.75)
        case .continent: Color(red: 0.52, green: 0.33, blue: 0.84)
        case .country: Color(red: 0.16, green: 0.39, blue: 0.85)
        case .state: Color(red: 0.93, green: 0.52, blue: 0.10)
        case .city: Color(red: 0.16, green: 0.62, blue: 0.33)
        }
    }

    var symbol: String {
        switch self {
        case .planet: "globe.americas.fill"
        case .continent: "map.fill"
        case .country: "flag.fill"
        case .state: "puzzlepiece.fill"
        case .city: "building.2.fill"
        }
    }

    /// One or two short sentences a 9-year-old can hear and remember.
    var meaning: String {
        switch self {
        case .planet:
            "Our whole world. Every place is inside Earth."
        case .continent:
            "A giant piece of land. There are only 7 continents. Countries are inside continents."
        case .country:
            "A place with its own flag and its own leaders. Countries are inside continents."
        case .state:
            "A piece of a country, like a puzzle piece. States are inside countries."
        case .city:
            "A place where lots of people live close together, with streets and buildings. Cities are inside states or countries."
        }
    }

    var examples: String {
        switch self {
        case .planet: "Earth"
        case .continent: "North America, Europe, Asia, Africa"
        case .country: "United States, Poland, Japan, Mexico"
        case .state: "Massachusetts, Florida, Texas, California"
        case .city: "Boston, Paris, Tokyo, Orlando"
        }
    }
}

struct KindBadge: View {
    let kind: PlaceKind
    var large = false

    var body: some View {
        Label(kind.name.uppercased(), systemImage: kind.symbol)
            .font(.system(large ? .title2 : .subheadline, design: .rounded, weight: .heavy))
            .foregroundStyle(.white)
            .padding(.horizontal, large ? 16 : 10)
            .padding(.vertical, large ? 8 : 4)
            .background(kind.color, in: Capsule())
    }
}

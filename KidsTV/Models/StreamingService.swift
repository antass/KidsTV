import SwiftUI

/// What the app knows about a streaming service: its color and how to open its app.
struct StreamingService {
    let name: String

    private var key: String {
        name.lowercased().filter { $0.isLetter || $0.isNumber }
    }

    /// Opens the service's app at its home screen. Used as a last resort
    /// when none of a show's links work.
    var appHomeURL: URL? {
        switch key {
        case "netflix": URL(string: "nflx://")
        case "disney", "disneyplus": URL(string: "disneyplus://")
        case "primevideo", "prime", "amazonprime": URL(string: "aiv://")
        case "appletv", "appletvplus": URL(string: "https://tv.apple.com")
        case "max", "hbomax": URL(string: "hbomax://")
        default: nil
        }
    }

    var color: Color {
        switch key {
        case "netflix": Color(red: 0.70, green: 0.04, blue: 0.10)
        case "disney", "disneyplus": Color(red: 0.05, green: 0.20, blue: 0.55)
        case "primevideo", "prime", "amazonprime": Color(red: 0.0, green: 0.55, blue: 0.85)
        case "appletv", "appletvplus": Color(white: 0.15)
        case "pbskids", "pbs": Color(red: 0.15, green: 0.55, blue: 0.25)
        case "max", "hbomax": Color(red: 0.25, green: 0.10, blue: 0.70)
        default: Color(red: 0.45, green: 0.30, blue: 0.65)
        }
    }
}

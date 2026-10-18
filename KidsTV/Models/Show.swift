import Foundation

/// The whole curated catalog, as stored in `shows.json`.
struct CatalogFile: Decodable {
    var title: String
    var shows: [Show]

    init(title: String = "Kids' Picks", shows: [Show] = []) {
        self.title = title
        self.shows = shows
    }

    private enum CodingKeys: String, CodingKey { case title, shows }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        title = try container.decodeIfPresent(String.self, forKey: .title) ?? "Kids' Picks"
        // Skip any malformed entry instead of rejecting the whole catalog,
        // so one typo made while editing on a phone can't blank the screen.
        let lossy = try container.decodeIfPresent([Lossy<Show>].self, forKey: .shows) ?? []
        shows = lossy.compactMap(\.value)
    }
}

/// One tile: a show or movie that opens straight into a streaming app.
struct Show: Identifiable, Decodable, Hashable {
    let id: String
    let title: String
    /// Optional second line, e.g. "Season 1".
    let subtitle: String?
    /// Streaming service name, e.g. "Netflix", "Disney+".
    let service: String
    /// Optional artwork URL (16:9 works best). Without one, a colored tile is drawn.
    let image: URL?
    /// Links tried in order until one opens. Put the most specific first.
    let links: [URL]

    var serviceInfo: StreamingService { StreamingService(name: service) }

    private enum CodingKeys: String, CodingKey { case id, title, subtitle, service, image, links }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        subtitle = try container.decodeIfPresent(String.self, forKey: .subtitle)
        service = try container.decode(String.self, forKey: .service)
        let rawImage = try? container.decodeIfPresent(String.self, forKey: .image)
        image = rawImage.flatMap { URL(string: $0) }
        let rawLinks = try container.decodeIfPresent([String].self, forKey: .links) ?? []
        links = rawLinks.compactMap { URL(string: $0) }
    }
}

/// Decodes a value, or nil if that element is broken.
private struct Lossy<T: Decodable>: Decodable {
    let value: T?

    init(from decoder: Decoder) throws {
        value = try? T(from: decoder)
    }
}

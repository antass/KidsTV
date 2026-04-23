import Foundation

struct Show: Identifiable, Codable, Hashable {
    let id: String
    let title: String
    let service: String
    let thumbnail: String
    let deepLink: String
}

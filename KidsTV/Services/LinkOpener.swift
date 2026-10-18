import UIKit

/// Opens a show in its streaming app.
///
/// tvOS gives no visible error when a link fails, so this tries each of the
/// show's links in order, then the service's home screen, and reports back
/// whether anything opened.
enum LinkOpener {
    static func open(_ show: Show) async -> Bool {
        var candidates = show.links
        if let home = show.serviceInfo.appHomeURL {
            candidates.append(home)
        }
        for url in candidates {
            if await UIApplication.shared.open(url) {
                return true
            }
        }
        return false
    }
}

import SwiftUI

@main
struct KidsTVApp: App {
    @State private var store = CatalogStore()

    init() {
        // Keep artwork on disk so tiles appear instantly after the first launch.
        URLCache.shared = URLCache(memoryCapacity: 50_000_000, diskCapacity: 300_000_000)
    }

    var body: some Scene {
        WindowGroup {
            DashboardView()
                .environment(store)
        }
    }
}

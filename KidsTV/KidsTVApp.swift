import SwiftUI

@main
struct KidsTVApp: App {
    @StateObject private var catalog = Catalog()

    var body: some Scene {
        WindowGroup {
            DashboardView()
                .environmentObject(catalog)
        }
    }
}

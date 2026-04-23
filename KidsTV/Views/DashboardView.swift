import SwiftUI

struct DashboardView: View {
    @EnvironmentObject private var catalog: Catalog

    private let columns = [
        GridItem(.adaptive(minimum: 360), spacing: 48)
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 48) {
                    ForEach(catalog.shows) { show in
                        ShowTile(show: show)
                    }
                }
                .padding(60)
            }
            .navigationTitle("Kids' Picks")
        }
    }
}

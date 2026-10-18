import SwiftUI

struct DashboardView: View {
    @Environment(CatalogStore.self) private var store
    @Environment(\.scenePhase) private var scenePhase
    @State private var failedShow: Show?

    private let columns = [
        GridItem(.adaptive(minimum: 480, maximum: 560), spacing: 64, alignment: .top)
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 48) {
                Text(store.catalog.title)
                    .font(.system(size: 76, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)

                if store.catalog.shows.isEmpty {
                    emptyState
                } else {
                    LazyVGrid(columns: columns, spacing: 72) {
                        ForEach(store.catalog.shows) { show in
                            ShowTile(show: show) {
                                Task {
                                    if !(await LinkOpener.open(show)) {
                                        failedShow = show
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 80)
            .padding(.vertical, 60)
        }
        .scrollClipDisabled()
        .background(background)
        .task { await store.refresh() }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                Task { await store.refresh() }
            }
        }
        .alert(
            "Couldn't open \(failedShow?.title ?? "that")",
            isPresented: Binding(get: { failedShow != nil }, set: { if !$0 { failedShow = nil } }),
            presenting: failedShow
        ) { _ in
            Button("OK", role: .cancel) {}
        } message: { show in
            Text("Ask a grown-up to check that \(show.service) is installed and signed in.")
        }
    }

    private var emptyState: some View {
        Text("No shows yet. Add some to shows.json.")
            .font(.title2)
            .foregroundStyle(.white.opacity(0.7))
            .frame(maxWidth: .infinity, minHeight: 400)
    }

    private var background: some View {
        LinearGradient(
            colors: [Color(red: 0.10, green: 0.12, blue: 0.30), Color(red: 0.24, green: 0.12, blue: 0.36)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
}

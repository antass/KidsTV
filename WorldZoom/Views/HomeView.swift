import SwiftUI

enum Activity: String, CaseIterable, Identifiable, Hashable {
    case zoom, sort, stack, cheatSheet

    var id: String { rawValue }

    var title: String {
        switch self {
        case .zoom: "Zoom In"
        case .sort: "What Is It?"
        case .stack: "Stack It"
        case .cheatSheet: "Cheat Sheet"
        }
    }

    var blurb: String {
        switch self {
        case .zoom: "Fly from space all the way down to a city."
        case .sort: "Is it a city, a state, a country, or a continent?"
        case .stack: "Put the places in order, biggest to smallest."
        case .cheatSheet: "All four kinds of places on one page."
        }
    }

    var symbol: String {
        switch self {
        case .zoom: "plus.magnifyingglass"
        case .sort: "questionmark.bubble.fill"
        case .stack: "square.stack.3d.down.right.fill"
        case .cheatSheet: "book.fill"
        }
    }

    var color: Color {
        switch self {
        case .zoom: PlaceKind.planet.color
        case .sort: PlaceKind.continent.color
        case .stack: PlaceKind.state.color
        case .cheatSheet: PlaceKind.city.color
        }
    }
}

struct HomeView: View {
    @AppStorage(Speaker.readAloudKey) private var readAloud = true

    private let columns = [GridItem(.adaptive(minimum: 300), spacing: 24)]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 28) {
                    header

                    LazyVGrid(columns: columns, spacing: 24) {
                        ForEach(Activity.allCases) { activity in
                            NavigationLink(value: activity) {
                                ActivityTile(activity: activity)
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    Toggle(isOn: $readAloud) {
                        Label("Read aloud", systemImage: "speaker.wave.2.fill")
                            .font(.system(.title3, design: .rounded, weight: .semibold))
                    }
                    .frame(maxWidth: 320)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(.white, in: Capsule())
                }
                .padding(32)
                .frame(maxWidth: 1000)
                .frame(maxWidth: .infinity)
            }
            .background(Color(red: 0.94, green: 0.97, blue: 1.0).ignoresSafeArea())
            .navigationDestination(for: Activity.self) { activity in
                switch activity {
                case .zoom: ZoomView()
                case .sort: SortGameView()
                case .stack: StackGameView()
                case .cheatSheet: CheatSheetView()
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) { StarCount() }
            }
        }
    }

    private var header: some View {
        VStack(spacing: 16) {
            Text("World Zoom 🌍")
                .font(.system(size: 56, weight: .heavy, design: .rounded))

            // The one idea the app teaches, as a row of shrinking chips.
            HStack(spacing: 6) {
                ForEach(Array(PlaceKind.quizKinds.enumerated()), id: \.element) { i, kind in
                    if i > 0 {
                        Image(systemName: "chevron.right")
                            .font(.title3.weight(.heavy))
                            .foregroundStyle(.secondary)
                    }
                    KindBadge(kind: kind, large: true)
                        .scaleEffect(1.0 - Double(i) * 0.08)
                }
            }
            Text("Biggest ➜ smallest")
                .font(.system(.title3, design: .rounded, weight: .semibold))
                .foregroundStyle(.secondary)
        }
    }
}

private struct ActivityTile: View {
    let activity: Activity

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Image(systemName: activity.symbol)
                .font(.system(size: 48, weight: .bold))
            Text(activity.title)
                .font(.system(.largeTitle, design: .rounded, weight: .heavy))
            Text(activity.blurb)
                .font(.system(.title3, design: .rounded))
                .multilineTextAlignment(.leading)
            Spacer(minLength: 0)
        }
        .foregroundStyle(.white)
        .padding(24)
        .frame(maxWidth: .infinity, minHeight: 220, alignment: .topLeading)
        .background(activity.color.gradient, in: RoundedRectangle(cornerRadius: 28))
        .shadow(color: activity.color.opacity(0.35), radius: 10, y: 6)
    }
}

#Preview {
    HomeView()
}

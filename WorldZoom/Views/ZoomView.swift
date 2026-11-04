import SwiftUI

/// Pick a city and start right there. Each "Zoom out" steps up one box:
/// city → state/province → country → continent → Earth. The map keeps every
/// box of the address colored, so Charlie sees the smaller place sitting
/// inside the bigger one at every step.
struct ZoomView: View {
    @State private var trip = Atlas.home
    @State private var level = Atlas.chain(to: Atlas.home).count - 1

    private var chain: [Place] { Atlas.chain(to: trip) }
    private var current: Place { chain[level] }
    private var atTop: Bool { level == 0 }
    private var atBottom: Bool { level == chain.count - 1 }

    var body: some View {
        GeometryReader { geo in
            let wide = geo.size.width > geo.size.height
            let layout = wide ? AnyLayout(HStackLayout(spacing: 20)) : AnyLayout(VStackLayout(spacing: 16))

            VStack(spacing: 16) {
                tripPicker

                layout {
                    map
                        .frame(maxWidth: .infinity, maxHeight: .infinity)

                    ScrollView {
                        VStack(spacing: 16) {
                            explainer
                            NestedBoxes(
                                slots: chain.map { NestSlot($0) },
                                highlight: level,
                                onTap: { go(to: $0) }
                            )
                            controls
                        }
                    }
                    .frame(width: wide ? min(460, geo.size.width * 0.42) : nil)
                    .frame(maxHeight: wide ? .infinity : geo.size.height * 0.55)
                }
            }
            .padding(20)
        }
        .background(Color(red: 0.94, green: 0.97, blue: 1.0).ignoresSafeArea())
        .navigationTitle("Zoom Out")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { ToolbarItem(placement: .topBarTrailing) { StarCount() } }
        .onAppear { Speaker.shared.say("Pick a city, then tap Zoom out!") }
        .onDisappear { Speaker.shared.stop() }
    }

    // MARK: Pieces

    private var tripPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(Atlas.trips) { place in
                    let flag = Atlas.chain(to: place).first { $0.kind == .country }?.emoji
                    Button {
                        pick(place)
                    } label: {
                        Text("\(place.emoji ?? flag ?? "📍") \(place.name)")
                            .font(.system(.title3, design: .rounded, weight: .bold))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .foregroundStyle(place == trip ? Color.white : Color.primary)
                            .background(place == trip ? Color.accentColor : .white, in: Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var map: some View {
        PoliticalMap(chain: chain, level: level)
            .background(Color(red: 0.94, green: 0.97, blue: 1.0))
            .clipShape(RoundedRectangle(cornerRadius: 24))
            .overlay(alignment: .topLeading) {
                VStack(alignment: .leading, spacing: 4) {
                    KindBadge(kind: current.kind, large: true, word: current.kindWord)
                    Text(current.title)
                        .font(.system(size: 40, weight: .heavy, design: .rounded))
                        .shadow(color: .white, radius: 4)
                        .shadow(color: .white, radius: 8)
                }
                .padding(16)
            }
    }

    private var explainer: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                (Text(current.name).foregroundStyle(.primary)
                    + Text(" is a ").foregroundStyle(.secondary)
                    + Text(current.kindWord.lowercased()).foregroundStyle(current.kind.color))
                    .font(.system(.title, design: .rounded, weight: .heavy))
                Spacer()
                SpeakButton(text: speech)
            }
            Text(current.kindMeaning)
                .font(.system(.title3, design: .rounded))
            if let up = Atlas.parent(of: current) {
                Label("\(current.name) is inside \(up.inSentence).", systemImage: "arrow.up.left.and.arrow.down.right")
                    .font(.system(.title3, design: .rounded, weight: .semibold))
                    .foregroundStyle(up.kind.color)
            }
            if let note = current.note {
                Text("💡 \(note)")
                    .font(.system(.title3, design: .rounded, weight: .medium))
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.yellow.opacity(0.25), in: RoundedRectangle(cornerRadius: 12))
            }
            if atTop {
                Text("📬 The whole address: \(Atlas.address(of: trip))")
                    .font(.system(.title3, design: .rounded, weight: .bold))
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(PlaceKind.city.color.opacity(0.15), in: RoundedRectangle(cornerRadius: 12))
            }
        }
        .padding(16)
        .background(.white, in: RoundedRectangle(cornerRadius: 20))
    }

    private var controls: some View {
        HStack(spacing: 12) {
            Button {
                go(to: level + 1)
            } label: {
                Label("Zoom in", systemImage: "plus.magnifyingglass")
            }
            .buttonStyle(BigButtonStyle(color: .gray))
            .disabled(atBottom)
            .opacity(atBottom ? 0.4 : 1)

            Button {
                go(to: atTop ? chain.count - 1 : level - 1)
            } label: {
                Label(
                    atTop ? "Back to \(trip.name)" : "Zoom out to \(chain[level - 1].name)",
                    systemImage: atTop ? "arrow.counterclockwise" : "minus.magnifyingglass"
                )
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(BigButtonStyle(color: atTop ? trip.kind.color : chain[level - 1].kind.color))
        }
    }

    // MARK: Actions

    private var speech: String {
        atTop
            ? "\(Atlas.sentence(for: current)) You zoomed all the way out! The whole address is: \(Atlas.address(of: trip))."
            : Atlas.sentence(for: current)
    }

    private func pick(_ place: Place) {
        trip = place
        level = Atlas.chain(to: place).count - 1
        Speaker.shared.say(Atlas.sentence(for: place))
    }

    private func go(to newLevel: Int) {
        level = min(max(0, newLevel), chain.count - 1)
        Speaker.shared.say(speech)
    }
}

#Preview {
    NavigationStack { ZoomView() }
}

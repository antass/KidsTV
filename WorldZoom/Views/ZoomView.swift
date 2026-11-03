import MapKit
import SwiftUI

/// Pick a destination, then zoom in one level at a time: Earth → continent →
/// country → state → city. The map flies down and the nested boxes light up
/// the level you're on, so "bigger place holds smaller place" is something
/// Charlie sees, not just hears.
struct ZoomView: View {
    @State private var trip = Atlas.home
    @State private var level = 0
    @State private var camera: MapCameraPosition = Self.cameraPosition(for: Atlas.chain(to: Atlas.home), level: 0)

    private var chain: [Place] { Atlas.chain(to: trip) }
    private var current: Place { chain[level] }
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
                                fadeInner: true,
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
        .navigationTitle("Zoom In")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { ToolbarItem(placement: .topBarTrailing) { StarCount() } }
        .onAppear { Speaker.shared.say("Pick a place, then tap Zoom in!") }
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
        Map(position: $camera, interactionModes: []) {
            if level > 0 {
                Marker(trip.name, systemImage: trip.kind.symbol, coordinate: trip.coordinate)
                    .tint(trip.kind.color)
            }
        }
        .mapStyle(.hybrid(elevation: .realistic))
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .overlay(alignment: .topLeading) {
            KindBadge(kind: current.kind, large: true)
                .padding(16)
        }
        .overlay(alignment: .bottom) {
            Text(current.title)
                .font(.system(size: 40, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)
                .shadow(color: .black, radius: 6)
                .padding(.bottom, 20)
        }
    }

    private var explainer: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                (Text(current.name).foregroundStyle(.primary)
                    + Text(" is a ").foregroundStyle(.secondary)
                    + Text(current.kind.name.lowercased()).foregroundStyle(current.kind.color))
                    .font(.system(.title, design: .rounded, weight: .heavy))
                Spacer()
                SpeakButton(text: Atlas.sentence(for: current))
            }
            Text(current.kind.meaning)
                .font(.system(.title3, design: .rounded))
            if let up = Atlas.parent(of: current) {
                Label("\(current.name) is inside \(up.inSentence).", systemImage: "arrow.down.right.and.arrow.up.left")
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
            if atBottom {
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
                go(to: level - 1)
            } label: {
                Label("Zoom out", systemImage: "minus.magnifyingglass")
            }
            .buttonStyle(BigButtonStyle(color: .gray))
            .disabled(level == 0)
            .opacity(level == 0 ? 0.4 : 1)

            Button {
                go(to: level + 1)
            } label: {
                Label(atBottom ? "Start over" : "Zoom in", systemImage: atBottom ? "arrow.counterclockwise" : "plus.magnifyingglass")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(BigButtonStyle(color: atBottom ? PlaceKind.planet.color : chain[level + 1].kind.color))
        }
    }

    // MARK: Actions

    private func pick(_ place: Place) {
        trip = place
        go(to: 0)
    }

    private func go(to newLevel: Int) {
        let target = newLevel >= chain.count ? 0 : max(0, newLevel)
        level = target
        withAnimation(.easeInOut(duration: 1.6)) {
            camera = Self.cameraPosition(for: chain, level: target)
        }
        if target == chain.count - 1 {
            Speaker.shared.say("\(Atlas.sentence(for: current)) You made it! The whole address is: \(Atlas.address(of: trip)).")
        } else {
            Speaker.shared.say(Atlas.sentence(for: current))
        }
    }

    private static func cameraPosition(for chain: [Place], level: Int) -> MapCameraPosition {
        let place = chain[level]
        // From space, aim at the continent we're about to visit.
        let center = place.kind == .planet && chain.count > 1 ? chain[1].coordinate : place.coordinate
        return .camera(MapCamera(centerCoordinate: center, distance: place.zoom))
    }
}

#Preview {
    NavigationStack { ZoomView() }
}

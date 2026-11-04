import SwiftUI

// A political map drawn from Natural Earth borders (public domain, bundled as
// Data/world.json; rebuild it with tools/build_world_map.py). No map service,
// no satellite imagery: just countries, states/provinces, and a city dot,
// drawn on a globe so zooming out ends on the whole Earth.

// MARK: - Geometry

nonisolated struct Vec3: Sendable {
    var x: Double
    var y: Double
    var z: Double

    init(x: Double, y: Double, z: Double) {
        self.x = x
        self.y = y
        self.z = z
    }

    init(lon: Double, lat: Double) {
        let lo = lon * .pi / 180, la = lat * .pi / 180
        x = cos(la) * cos(lo)
        y = cos(la) * sin(lo)
        z = sin(la)
    }

    func dot(_ o: Vec3) -> Double { x * o.x + y * o.y + z * o.z }
    var lon: Double { atan2(y, x) * 180 / .pi }
    var lat: Double { asin(max(-1, min(1, z))) * 180 / .pi }

    func angle(to o: Vec3) -> Double { acos(max(-1, min(1, dot(o)))) }

    /// Walks along the great circle from a to b.
    static func slerp(_ a: Vec3, _ b: Vec3, _ t: Double) -> Vec3 {
        let w = a.angle(to: b)
        let s = sin(w)
        guard s > 1e-6 else { return t < 0.5 ? a : b }
        let ka = sin((1 - t) * w) / s, kb = sin(t * w) / s
        return Vec3(x: a.x * ka + b.x * kb, y: a.y * ka + b.y * kb, z: a.z * ka + b.z * kb)
    }
}

nonisolated struct GeoRegion: Sendable {
    let name: String
    let continent: String?
    let country: String?
    let color: Int
    let center: Vec3
    /// Angular radius (radians) of a cap that holds the whole region.
    let radius: Double
    let rings: [[Vec3]]
}

nonisolated struct WorldGeometry: Sendable {
    let countries: [GeoRegion]
    let states: [GeoRegion]

    nonisolated private struct RawRegion: Decodable {
        let name: String
        let continent: String?
        let country: String?
        let color: Int
        let center: [Double]
        let radius: Double
        let rings: [[[Double]]]
    }

    nonisolated private struct Raw: Decodable {
        let countries: [RawRegion]
        let states: [RawRegion]
    }

    /// Slow-ish (≈1 MB of JSON); call off the main thread.
    static func load() -> WorldGeometry? {
        let url = Bundle.main.url(forResource: "world", withExtension: "json")
            ?? Bundle.main.url(forResource: "world", withExtension: "json", subdirectory: "Data")
        guard let url, let data = try? Data(contentsOf: url),
              let raw = try? JSONDecoder().decode(Raw.self, from: data) else { return nil }

        func convert(_ r: RawRegion) -> GeoRegion {
            GeoRegion(
                name: r.name, continent: r.continent, country: r.country, color: r.color,
                center: Vec3(lon: r.center[0], lat: r.center[1]),
                radius: r.radius * .pi / 180,
                rings: r.rings.map { ring in ring.map { Vec3(lon: $0[0], lat: $0[1]) } }
            )
        }
        return WorldGeometry(countries: raw.countries.map(convert), states: raw.states.map(convert))
    }
}

/// Where the map looks: a point on Earth and how many km from the middle to the edge.
nonisolated struct MapCam: Equatable, Sendable {
    var lon: Double
    var lat: Double
    var km: Double

    /// Zoom out first, then in, so long trips swing out over the globe.
    static func between(_ a: MapCam, _ b: MapCam, _ raw: Double) -> MapCam {
        let t = raw < 0.5 ? 4 * raw * raw * raw : 1 - pow(-2 * raw + 2, 3) / 2
        let va = Vec3(lon: a.lon, lat: a.lat), vb = Vec3(lon: b.lon, lat: b.lat)
        let v = Vec3.slerp(va, vb, t)
        let peak = max(a.km, b.km, va.angle(to: vb) * 6371 * 0.8)
        let km = t < 0.5
            ? exp(log(a.km) + (log(peak) - log(a.km)) * t * 2)
            : exp(log(peak) + (log(b.km) - log(peak)) * (t - 0.5) * 2)
        return MapCam(lon: v.lon, lat: v.lat, km: km)
    }
}

/// Orthographic (globe) projection.
nonisolated struct Projector {
    let center: Vec3
    let east: Vec3
    let north: Vec3
    let scale: Double
    let cx: Double
    let cy: Double
    /// Angular radius of the part of the globe the screen can show.
    let viewAngle: Double

    init(cam: MapCam, size: CGSize) {
        let lo = cam.lon * .pi / 180, la = cam.lat * .pi / 180
        center = Vec3(lon: cam.lon, lat: cam.lat)
        east = Vec3(x: -sin(lo), y: cos(lo), z: 0)
        north = Vec3(x: -sin(la) * cos(lo), y: -sin(la) * sin(lo), z: cos(la))
        let half = min(size.width, size.height) / 2
        let theta = cam.km / 6371
        scale = theta >= 1.35 ? half * 0.92 : half / sin(theta)
        cx = size.width / 2
        cy = size.height / 2
        let corner = hypot(size.width, size.height) / 2
        viewAngle = corner >= scale ? .pi / 2 : asin(corner / scale)
    }

    func isVisible(_ p: Vec3) -> Bool { p.dot(center) > 0 }

    func point(_ p: Vec3) -> CGPoint {
        var x = p.dot(east), y = p.dot(north)
        if p.dot(center) < 0 {
            // Behind the globe: pin it to the edge so shapes follow the rim.
            let l = max(hypot(x, y), 1e-9)
            x /= l
            y /= l
        }
        return CGPoint(x: cx + x * scale, y: cy - y * scale)
    }

    func mightSee(_ r: GeoRegion) -> Bool {
        r.center.angle(to: center) - r.radius < viewAngle + 0.02
    }

    func path(_ r: GeoRegion) -> Path {
        var path = Path()
        for ring in r.rings {
            guard let first = ring.first else { continue }
            path.move(to: point(first))
            for p in ring.dropFirst() { path.addLine(to: point(p)) }
            path.closeSubpath()
        }
        return path
    }

    var sphere: Path {
        Path(ellipseIn: CGRect(x: cx - scale, y: cy - scale, width: scale * 2, height: scale * 2))
    }
}

extension Place {
    var mapCam: MapCam {
        // Cities have no border in the data, so show a little around them.
        MapCam(lon: longitude, lat: latitude, km: max(zoom * 0.55 / 1000, 90))
    }
}

// MARK: - View

/// Shows every box of the address at once: the continent tinted purple, the
/// country inside it blue, the state orange, the city a green dot. The level
/// being looked at gets a thick outline.
struct PoliticalMap: View {
    let chain: [Place]
    let level: Int

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var world: WorldGeometry?
    @State private var from: MapCam?
    @State private var to: MapCam?
    @State private var start = Date.distantPast
    @State private var animating = false

    private static let duration = 1.6
    private static let ocean = Color(red: 0.73, green: 0.86, blue: 0.95)
    private static let rim = Color(red: 0.56, green: 0.75, blue: 0.88)
    private static let stateLine = Color(red: 0.27, green: 0.31, blue: 0.47).opacity(0.35)
    private static let land: [Color] = [
        Color(red: 0.96, green: 0.94, blue: 0.89), Color(red: 0.91, green: 0.94, blue: 0.87),
        Color(red: 0.95, green: 0.90, blue: 0.91), Color(red: 0.89, green: 0.92, blue: 0.95),
        Color(red: 0.95, green: 0.91, blue: 0.84), Color(red: 0.91, green: 0.89, blue: 0.95),
        Color(red: 0.93, green: 0.94, blue: 0.86),
    ]

    private var target: MapCam { chain[level].mapCam }

    var body: some View {
        TimelineView(.animation(paused: !animating)) { timeline in
            Canvas { gc, size in
                draw(&gc, size: size, cam: camera(at: timeline.date))
            }
        }
        .overlay {
            if world == nil {
                ProgressView("Loading the map…")
                    .font(.system(.title3, design: .rounded, weight: .semibold))
            }
        }
        .overlay(alignment: .bottomTrailing) {
            Text("Map: Natural Earth")
                .font(.caption2)
                .padding(.horizontal, 6)
                .background(.white.opacity(0.7), in: Capsule())
                .padding(10)
        }
        .task {
            if world == nil {
                world = await Task.detached(priority: .userInitiated) { WorldGeometry.load() }.value
            }
        }
        .task(id: target) {
            let now = Date()
            let current = camera(at: now)
            from = (to == nil || reduceMotion) ? nil : current
            to = target
            start = now
            animating = from != nil
            guard animating else { return }
            try? await Task.sleep(for: .seconds(Self.duration + 0.05))
            if !Task.isCancelled { animating = false }
        }
        .accessibilityLabel("Map showing \(chain[level].name)")
    }

    private func camera(at date: Date) -> MapCam {
        guard let to else { return target }
        guard let from else { return to }
        let t = min(1, max(0, date.timeIntervalSince(start) / Self.duration))
        return t >= 1 ? to : MapCam.between(from, to, t)
    }

    private struct Mark {
        let kind: PlaceKind
        let strong: Bool
    }

    private func draw(_ gc: inout GraphicsContext, size: CGSize, cam: MapCam) {
        guard let world else { return }
        let proj = Projector(cam: cam, size: size)
        let current = chain[level]

        var countryMarks: [String: Mark] = [:]
        var stateMarks: [String: Mark] = [:]
        for place in chain {
            let mark = Mark(kind: place.kind, strong: place == current)
            switch place.kind {
            case .continent:
                for c in world.countries where c.continent == place.name { countryMarks[c.name] = mark }
            case .country:
                countryMarks[place.mapName ?? place.name] = mark
            case .state:
                stateMarks[place.name] = mark
            default:
                break
            }
        }

        func tint(_ mark: Mark) -> Color {
            switch mark.kind {
            case .continent: mark.kind.color.opacity(0.4)
            case .country: mark.kind.color.opacity(0.67)
            default: mark.kind.color.opacity(0.87)
            }
        }

        let sphere = proj.sphere
        gc.fill(sphere, with: .color(Self.ocean))
        gc.clip(to: sphere)
        let evenOdd = FillStyle(eoFill: true)

        var outlines: [(Path, Color)] = []
        for region in world.countries where proj.mightSee(region) {
            let path = proj.path(region)
            gc.fill(path, with: .color(Self.land[max(0, region.color - 1) % Self.land.count]), style: evenOdd)
            if let mark = countryMarks[region.name] {
                gc.fill(path, with: .color(tint(mark)), style: evenOdd)
                if mark.strong { outlines.append((path, mark.kind.color)) }
            }
            gc.stroke(path, with: .color(.white), lineWidth: 0.8)
        }
        for region in world.states where proj.mightSee(region) {
            let path = proj.path(region)
            if let mark = stateMarks[region.name] {
                gc.fill(path, with: .color(tint(mark)), style: evenOdd)
                if mark.strong { outlines.append((path, mark.kind.color)) }
            }
            gc.stroke(path, with: .color(Self.stateLine), lineWidth: 0.6)
        }
        for (path, color) in outlines {
            gc.stroke(path, with: .color(color), lineWidth: 3)
        }
        gc.stroke(sphere, with: .color(Self.rim), lineWidth: 4)

        if let city = chain.last, city.kind == .city {
            let v = Vec3(lon: city.longitude, lat: city.latitude)
            if proj.isVisible(v) {
                let pt = proj.point(v)
                let r: CGFloat = city == current ? 14 : 9
                let dot = Path(ellipseIn: CGRect(x: pt.x - r, y: pt.y - r, width: r * 2, height: r * 2))
                gc.fill(dot, with: .color(PlaceKind.city.color))
                gc.stroke(dot, with: .color(.white), lineWidth: 4)
                gc.drawLayer { layer in
                    layer.addFilter(.shadow(color: .white, radius: 3))
                    layer.addFilter(.shadow(color: .white, radius: 3))
                    layer.draw(
                        Text(city.name)
                            .font(.system(size: 20, weight: .heavy, design: .rounded))
                            .foregroundStyle(Color(red: 0.11, green: 0.13, blue: 0.25)),
                        at: CGPoint(x: pt.x + r + 8, y: pt.y),
                        anchor: .leading
                    )
                }
            }
        }
    }
}

import SwiftUI

/// One box in the nest. `name == nil` draws an empty dashed box waiting to be filled.
struct NestSlot: Identifiable {
    let kind: PlaceKind
    let name: String?
    var id: Int { kind.rawValue }

    init(_ place: Place) {
        kind = place.kind
        name = place.title
    }

    init(kind: PlaceKind, name: String?) {
        self.kind = kind
        self.name = name
    }
}

/// Boxes inside boxes: Earth holds the continent, which holds the country, …
/// This is the picture the whole app is built around.
struct NestedBoxes: View {
    let slots: [NestSlot]
    /// Box drawn with a thick border.
    var highlight: Int? = nil
    /// Boxes smaller than the highlighted one are faded ("still to explore").
    var fadeInner = false
    var onTap: ((Int) -> Void)? = nil

    var body: some View {
        if !slots.isEmpty {
            NestBox(slots: slots, index: 0, highlight: highlight, fadeInner: fadeInner, onTap: onTap)
        }
    }
}

private struct NestBox: View {
    let slots: [NestSlot]
    let index: Int
    let highlight: Int?
    let fadeInner: Bool
    let onTap: ((Int) -> Void)?

    private var slot: NestSlot { slots[index] }
    private var isHighlighted: Bool { highlight == index }
    private var isFaded: Bool { fadeInner && (highlight ?? .max) < index }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: slot.kind.symbol)
                Text(slot.name ?? "\(slot.kind.name)?")
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                Spacer(minLength: 4)
                Text(slot.kind.name.uppercased())
                    .font(.system(.caption, design: .rounded, weight: .heavy))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(slot.kind.color.opacity(0.2), in: Capsule())
            }
            .font(.system(isHighlighted ? .title2 : .title3, design: .rounded, weight: .bold))
            .foregroundStyle(slot.name == nil ? slot.kind.color.opacity(0.6) : slot.kind.color)

            if index + 1 < slots.count {
                NestBox(slots: slots, index: index + 1, highlight: highlight, fadeInner: fadeInner, onTap: onTap)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(slot.kind.color.opacity(slot.name == nil ? 0.04 : (isHighlighted ? 0.28 : 0.12)))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .strokeBorder(
                    slot.kind.color,
                    style: slot.name == nil
                        ? StrokeStyle(lineWidth: 2, dash: [8, 5])
                        : StrokeStyle(lineWidth: isHighlighted ? 5 : 2)
                )
        )
        .opacity(isFaded ? 0.4 : 1)
        .contentShape(RoundedRectangle(cornerRadius: 18))
        .onTapGesture { onTap?(index) }
        .animation(.spring(duration: 0.4), value: highlight)
        .accessibilityElement(children: .contain)
    }
}

// MARK: - Shared bits

struct SpeakButton: View {
    let text: String

    var body: some View {
        Button {
            Speaker.shared.say(text, force: true)
        } label: {
            Image(systemName: "speaker.wave.2.fill")
                .font(.title2)
                .padding(12)
                .background(.white, in: Circle())
                .shadow(radius: 2)
        }
        .accessibilityLabel("Read out loud")
    }
}

struct StarCount: View {
    @AppStorage("stars") private var stars = 0

    var body: some View {
        Label("\(stars)", systemImage: "star.fill")
            .font(.system(.title2, design: .rounded, weight: .heavy))
            .foregroundStyle(.yellow)
            .padding(.horizontal, 14)
            .padding(.vertical, 6)
            .background(.black.opacity(0.75), in: Capsule())
            .accessibilityLabel("\(stars) stars")
    }
}

struct BigButtonStyle: ButtonStyle {
    var color: Color = .accentColor

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(.title2, design: .rounded, weight: .bold))
            .foregroundStyle(.white)
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            .frame(minHeight: 64)
            .background(color, in: RoundedRectangle(cornerRadius: 18))
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

extension View {
    /// Wiggles the view sideways each time `trigger` changes.
    func shake(trigger: Int) -> some View {
        keyframeAnimator(initialValue: 0.0, trigger: trigger) { content, x in
            content.offset(x: x)
        } keyframes: { _ in
            KeyframeTrack {
                LinearKeyframe(14.0, duration: 0.07)
                LinearKeyframe(-14.0, duration: 0.1)
                LinearKeyframe(10.0, duration: 0.1)
                LinearKeyframe(-6.0, duration: 0.08)
                LinearKeyframe(0.0, duration: 0.07)
            }
        }
    }
}

/// Big friendly "you did it" banner.
struct Cheer: View {
    let title: String
    let message: String

    var body: some View {
        VStack(spacing: 10) {
            Text("🎉").font(.system(size: 72))
            Text(title)
                .font(.system(.largeTitle, design: .rounded, weight: .heavy))
            Text(message)
                .font(.system(.title3, design: .rounded))
                .multilineTextAlignment(.center)
        }
        .padding(28)
        .frame(maxWidth: .infinity)
        .background(.yellow.opacity(0.25), in: RoundedRectangle(cornerRadius: 24))
        .transition(.scale.combined(with: .opacity))
    }
}

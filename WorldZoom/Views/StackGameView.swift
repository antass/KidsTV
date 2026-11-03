import SwiftUI

/// The pieces of one address are jumbled up. Charlie taps them biggest
/// first, and each one drops into its box in the nest: continent, then
/// country, then state, then city.
struct StackGameView: View {
    @AppStorage("stars") private var stars = 0

    @State private var target = Atlas.stackTargets.randomElement() ?? Atlas.home
    @State private var placed = 0
    @State private var cards: [Place] = []
    @State private var wrongCard: String?
    @State private var shakes: [String: Int] = [:]

    /// Continent → … → city (Earth is always given as the outer box).
    private var steps: [Place] { Array(Atlas.chain(to: target).dropFirst()) }
    private var done: Bool { placed == steps.count }

    var body: some View {
        GeometryReader { geo in
            let wide = geo.size.width > geo.size.height
            let layout = wide ? AnyLayout(HStackLayout(alignment: .top, spacing: 28)) : AnyLayout(VStackLayout(spacing: 24))

            ScrollView {
                VStack(spacing: 20) {
                    instructions

                    layout {
                        NestedBoxes(slots: slots, highlight: done ? nil : placed + 1)
                            .frame(maxWidth: .infinity)

                        VStack(spacing: 16) {
                            if done {
                                finished
                            } else {
                                cardPile
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .padding(28)
            }
        }
        .background(Color(red: 1.0, green: 0.96, blue: 0.92).ignoresSafeArea())
        .navigationTitle("Stack It")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { ToolbarItem(placement: .topBarTrailing) { StarCount() } }
        .onAppear { if cards.isEmpty { newPuzzle(keepTarget: true) } }
        .onDisappear { Speaker.shared.stop() }
    }

    /// Earth is filled in; the rest wait as dashed "Country?" boxes until placed.
    private var slots: [NestSlot] {
        [NestSlot(Atlas.earth)] + steps.enumerated().map { i, place in
            i < placed ? NestSlot(place) : NestSlot(kind: place.kind, name: nil)
        }
    }

    // MARK: Pieces

    private var instructions: some View {
        HStack {
            Text("Tap the **biggest** place first!")
                .font(.system(.largeTitle, design: .rounded, weight: .heavy))
            Spacer()
            SpeakButton(text: "Tap the biggest place first. Then the next biggest, all the way down to the smallest.")
        }
    }

    private var cardPile: some View {
        VStack(spacing: 14) {
            ForEach(cards) { place in
                let used = steps.prefix(placed).contains(place)
                Button {
                    tap(place)
                } label: {
                    Text(place.title)
                        .font(.system(size: 40, weight: .heavy, design: .rounded))
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                        .foregroundStyle(.primary)
                        .frame(maxWidth: .infinity, minHeight: 90)
                        .background(.white, in: RoundedRectangle(cornerRadius: 22))
                        .overlay(
                            RoundedRectangle(cornerRadius: 22)
                                .strokeBorder(wrongCard == place.id ? Color.red : Color.gray.opacity(0.3), lineWidth: 4)
                        )
                        .shadow(color: .black.opacity(0.08), radius: 6, y: 3)
                }
                .buttonStyle(.plain)
                .shake(trigger: shakes[place.id, default: 0])
                .opacity(used ? 0 : 1)
                .disabled(used)
            }

            if wrongCard != nil {
                Text("Hmm, is that the biggest one left? Look at the next empty box.")
                    .font(.system(.title3, design: .rounded, weight: .semibold))
                    .multilineTextAlignment(.center)
            }
        }
    }

    private var finished: some View {
        VStack(spacing: 20) {
            Cheer(title: "You stacked it!", message: Atlas.address(of: target))
            SpeakButton(text: "The whole address is: \(Atlas.address(of: target)).")
            Button {
                newPuzzle(keepTarget: false)
            } label: {
                Label("New puzzle", systemImage: "shuffle")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(BigButtonStyle(color: PlaceKind.state.color))
        }
    }

    // MARK: Logic

    private func newPuzzle(keepTarget: Bool) {
        if !keepTarget {
            let others = Atlas.stackTargets.filter { $0 != target }
            target = others.randomElement() ?? target
        }
        placed = 0
        wrongCard = nil
        cards = steps.shuffled()
        Speaker.shared.say("Tap the biggest place first.")
    }

    private func tap(_ place: Place) {
        guard !done else { return }
        if place == steps[placed] {
            withAnimation(.spring(duration: 0.4)) {
                placed += 1
                wrongCard = nil
            }
            if done {
                stars += 1
                Speaker.shared.say("You did it! \(Atlas.address(of: target)).")
            } else {
                Speaker.shared.say("\(place.name) is a \(place.kind.name.lowercased()).")
            }
        } else {
            wrongCard = place.id
            shakes[place.id, default: 0] += 1
            Speaker.shared.say("Hmm. Is \(place.inSentence) the biggest one left?")
        }
    }
}

#Preview {
    NavigationStack { StackGameView() }
}

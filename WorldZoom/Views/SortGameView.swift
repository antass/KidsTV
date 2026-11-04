import SwiftUI

/// A place name shows up; Charlie taps Continent, Country, State, or City.
/// Every answer (right or wrong) shows the place inside its nest, so each
/// question re-teaches the big picture. Misses come back a few cards later.
struct SortGameView: View {
    private static let roundSize = 10

    @AppStorage("stars") private var stars = 0

    @State private var queue: [Place] = []
    @State private var picked: PlaceKind?
    @State private var missedThisCard = false
    @State private var everMissed: Set<String> = []
    @State private var showHint = false
    @State private var firstTryRight = 0
    @State private var cardsDone = 0
    @State private var shakes = 0

    private var place: Place? { queue.first }
    private var answeredRight: Bool { picked != nil && picked == place?.kind }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                if let place {
                    progress
                    question(place)
                    choices(place)
                    if picked != nil { feedback(place) }
                } else if cardsDone > 0 {
                    finished
                }
            }
            .padding(28)
            .frame(maxWidth: 900)
            .frame(maxWidth: .infinity)
        }
        .background(Color(red: 0.96, green: 0.94, blue: 1.0).ignoresSafeArea())
        .navigationTitle("What Is It?")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { ToolbarItem(placement: .topBarTrailing) { StarCount() } }
        .onAppear { if queue.isEmpty { newRound() } }
        .onDisappear { Speaker.shared.stop() }
    }

    // MARK: Pieces

    private var progress: some View {
        HStack(spacing: 6) {
            ForEach(0..<Self.roundSize, id: \.self) { i in
                Circle()
                    .fill(i < cardsDone ? Color.green : Color.gray.opacity(0.25))
                    .frame(width: 18, height: 18)
            }
        }
        .accessibilityLabel("\(cardsDone) of \(Self.roundSize) done")
    }

    private func question(_ place: Place) -> some View {
        VStack(spacing: 14) {
            HStack {
                Spacer()
                Text("What is")
                    .font(.system(.title, design: .rounded, weight: .semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                SpeakButton(text: "What is \(place.inSentence)? Is it a continent, a country, a state, or a city?")
            }
            Text("\(place.inSentence)?")
                .font(.system(size: 64, weight: .heavy, design: .rounded))
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.5)
                .shake(trigger: shakes)

            if picked == nil {
                if showHint {
                    Text(hint(for: place))
                        .font(.system(.title2, design: .rounded, weight: .semibold))
                        .padding(12)
                        .background(.yellow.opacity(0.3), in: RoundedRectangle(cornerRadius: 14))
                } else {
                    Button("💡 Hint") {
                        showHint = true
                        Speaker.shared.say(hint(for: place))
                    }
                    .font(.system(.title2, design: .rounded, weight: .bold))
                }
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(.white, in: RoundedRectangle(cornerRadius: 28))
    }

    private func choices(_ place: Place) -> some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 16), GridItem(.flexible(), spacing: 16)], spacing: 16) {
            ForEach(PlaceKind.quizKinds) { kind in
                let isAnswer = answeredRight && kind == place.kind
                let isWrongPick = picked == kind && kind != place.kind
                Button {
                    answer(kind, for: place)
                } label: {
                    VStack(spacing: 8) {
                        Image(systemName: kind.symbol).font(.system(size: 44))
                        Text(kind.name).font(.system(.largeTitle, design: .rounded, weight: .heavy))
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, minHeight: 140)
                    .background(kind.color, in: RoundedRectangle(cornerRadius: 24))
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .strokeBorder(isAnswer ? Color.yellow : .clear, lineWidth: 8)
                    )
                    .overlay(alignment: .topTrailing) {
                        if isAnswer {
                            Image(systemName: "checkmark.circle.fill").font(.system(size: 40)).padding(10)
                                .foregroundStyle(.yellow)
                        } else if isWrongPick {
                            Image(systemName: "xmark.circle.fill").font(.system(size: 40)).padding(10)
                                .foregroundStyle(.white)
                        }
                    }
                    .opacity(answeredRight && !isAnswer ? 0.35 : 1)
                }
                .buttonStyle(.plain)
                .disabled(answeredRight)
            }
        }
    }

    private func feedback(_ place: Place) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top) {
                Text(answeredRight ? (missedThisCard ? "👍 You got it!" : "⭐️ Yes!") : "Not quite. Try again!")
                    .font(.system(.largeTitle, design: .rounded, weight: .heavy))
                Spacer()
                if answeredRight { SpeakButton(text: Atlas.sentence(for: place)) }
            }

            if answeredRight {
                Text(Atlas.sentence(for: place))
                    .font(.system(.title3, design: .rounded))

                let chain = Atlas.chain(to: place)
                NestedBoxes(slots: chain.map { NestSlot($0) }, highlight: chain.count - 1)

                Button {
                    next()
                } label: {
                    Label("Next", systemImage: "arrow.right")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(BigButtonStyle())
            } else if let picked {
                Text("\(place.name) is not a \(picked.name.lowercased()). \(sizeHint(picked, vs: place.kind)) Look again!")
                    .font(.system(.title3, design: .rounded))
            }
        }
        .padding(20)
        .background(.white, in: RoundedRectangle(cornerRadius: 24))
        .transition(.opacity.combined(with: .move(edge: .bottom)))
    }

    private var finished: some View {
        VStack(spacing: 24) {
            Cheer(
                title: "Round done!",
                message: "You got \(firstTryRight) of \(Self.roundSize) on the first try."
            )
            Button {
                newRound()
            } label: {
                Label("Play again", systemImage: "arrow.counterclockwise")
                    .frame(maxWidth: 400)
            }
            .buttonStyle(BigButtonStyle())
        }
        .onAppear {
            Speaker.shared.say("Round done! You got \(firstTryRight) out of \(Self.roundSize) on the first try.")
        }
    }

    // MARK: Logic

    private func newRound() {
        queue = Array(Atlas.quizPlaces.shuffled().prefix(Self.roundSize))
        cardsDone = 0
        firstTryRight = 0
        everMissed = []
        resetCard()
        if let place { askAloud(place) }
    }

    private func resetCard() {
        picked = nil
        missedThisCard = false
        showHint = false
    }

    private func answer(_ kind: PlaceKind, for place: Place) {
        withAnimation(.spring(duration: 0.35)) { picked = kind }
        if kind == place.kind {
            if !missedThisCard {
                stars += 1
                if !everMissed.contains(place.id) { firstTryRight += 1 }
            }
            Speaker.shared.say("Yes! " + Atlas.sentence(for: place))
        } else {
            missedThisCard = true
            everMissed.insert(place.id)
            shakes += 1
            Speaker.shared.say("Not quite. \(place.name) is not a \(kind.name.lowercased()). Try again!")
        }
    }

    private func next() {
        guard let place else { return }
        let missed = missedThisCard
        withAnimation {
            queue.removeFirst()
            if missed {
                // Bring it back in a few cards so it sticks.
                queue.insert(place, at: min(3, queue.count))
            } else {
                cardsDone += 1
            }
            resetCard()
        }
        if let upcoming = queue.first { askAloud(upcoming) }
    }

    private func askAloud(_ place: Place) {
        Speaker.shared.say("What is \(place.inSentence)?")
    }

    private func hint(for place: Place) -> String {
        if let up = Atlas.parent(of: place), up.kind != .planet {
            return "Hint: \(place.name) is inside \(up.inSentence), which is a \(up.kind.name.lowercased())."
        }
        return "Hint: \(place.name) is so big, only Earth holds it!"
    }

    /// "Continents are bigger than that. Cities fit inside continents."
    private func sizeHint(_ picked: PlaceKind, vs actual: PlaceKind) -> String {
        picked < actual
            ? "\(picked.plural) are bigger than that. \(actual.plural) fit inside \(picked.plural.lowercased())."
            : "\(picked.plural) are smaller than that. \(picked.plural) fit inside \(actual.plural.lowercased())."
    }
}

#Preview {
    NavigationStack { SortGameView() }
}

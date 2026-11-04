import SwiftUI

/// Everything on one page: the nest, what each word means, our own address,
/// and the tricky ones that break the pattern.
struct CheatSheetView: View {
    private let tricky: [(String, String)] = [
        ("🇦🇺 Australia", "is a continent AND a country. It's the only one that's both."),
        ("🗽 New York", "is a state. New York City is a city inside it. Same name, different sizes!"),
        ("🐧 Antarctica", "is a continent with no countries and no cities. Just ice and penguins."),
        ("🇨🇦 Canada", "doesn't have states. Its pieces are called provinces. Lots of countries don't have states."),
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                section("Places fit inside places") {
                    NestedBoxes(slots: [PlaceKind.planet, .continent, .country, .state, .city].map {
                        NestSlot(kind: $0, name: $0 == .planet ? "Earth" : $0.name)
                    })
                }

                section("What the words mean") {
                    VStack(spacing: 14) {
                        ForEach(PlaceKind.quizKinds) { kind in
                            KindCard(kind: kind)
                        }
                    }
                }

                section("Our address") {
                    let chain = Atlas.chain(to: Atlas.home).reversed()
                    VStack(alignment: .leading, spacing: 10) {
                        ForEach(Array(chain)) { place in
                            HStack(spacing: 12) {
                                KindBadge(kind: place.kind, word: place.kindWord)
                                    .frame(width: 170, alignment: .leading)
                                Text(place.title)
                                    .font(.system(.title2, design: .rounded, weight: .bold))
                            }
                        }
                        Text("Smallest on top, biggest at the bottom, just like on an envelope.")
                            .font(.system(.title3, design: .rounded))
                            .foregroundStyle(.secondary)
                    }
                    .padding(18)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.white, in: RoundedRectangle(cornerRadius: 20))
                }

                section("Tricky ones") {
                    VStack(alignment: .leading, spacing: 12) {
                        ForEach(tricky.indices, id: \.self) { i in
                            (Text(tricky[i].0).bold() + Text(" " + tricky[i].1))
                                .font(.system(.title3, design: .rounded))
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(14)
                                .background(.yellow.opacity(0.22), in: RoundedRectangle(cornerRadius: 14))
                        }
                    }
                }
            }
            .padding(28)
            .frame(maxWidth: 900)
            .frame(maxWidth: .infinity)
        }
        .background(Color(red: 0.93, green: 0.98, blue: 0.94).ignoresSafeArea())
        .navigationTitle("Cheat Sheet")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { ToolbarItem(placement: .topBarTrailing) { StarCount() } }
        .onDisappear { Speaker.shared.stop() }
    }

    private func section<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(.largeTitle, design: .rounded, weight: .heavy))
            content()
        }
    }
}

private struct KindCard: View {
    let kind: PlaceKind

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: kind.symbol)
                .font(.system(size: 40, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 76, height: 76)
                .background(kind.color, in: RoundedRectangle(cornerRadius: 18))
            VStack(alignment: .leading, spacing: 6) {
                Text(kind.name)
                    .font(.system(.title, design: .rounded, weight: .heavy))
                    .foregroundStyle(kind.color)
                Text(kind.meaning)
                    .font(.system(.title3, design: .rounded))
                Text("Like: \(kind.examples)")
                    .font(.system(.title3, design: .rounded, weight: .semibold))
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
            SpeakButton(text: "\(kind.name). \(kind.meaning) Like \(kind.examples).")
        }
        .padding(16)
        .background(.white, in: RoundedRectangle(cornerRadius: 20))
    }
}

#Preview {
    NavigationStack { CheatSheetView() }
}

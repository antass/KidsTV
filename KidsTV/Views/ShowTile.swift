import SwiftUI

struct ShowTile: View {
    let show: Show
    let action: () -> Void

    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Button(action: action) {
                ShowArt(show: show)
                    .aspectRatio(16 / 9, contentMode: .fit)
            }
            .buttonStyle(.card)
            .focused($isFocused)

            VStack(alignment: .leading, spacing: 4) {
                Text(show.title)
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .lineLimit(1)
                if let subtitle = show.subtitle {
                    Text(subtitle)
                        .font(.system(size: 26, weight: .medium, design: .rounded))
                        .lineLimit(1)
                        .opacity(0.7)
                }
            }
            .foregroundStyle(.white)
            // Slide the label down so the enlarged focused card doesn't cover it.
            .offset(y: isFocused ? 16 : 0)
            .animation(.easeOut(duration: 0.2), value: isFocused)
        }
    }
}

/// The tile artwork: the show's image if it has one, otherwise a colored card
/// with the title. Always carries a small service badge.
struct ShowArt: View {
    let show: Show

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            if let image = show.image {
                AsyncImage(url: image, transaction: Transaction(animation: .easeIn(duration: 0.25))) { phase in
                    if let picture = phase.image {
                        picture.resizable().scaledToFill()
                    } else {
                        fallback
                    }
                }
            } else {
                fallback
            }

            Text(show.service)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background(show.serviceInfo.color, in: Capsule())
                .foregroundStyle(.white)
                .padding(16)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clipped()
    }

    private var fallback: some View {
        ZStack {
            LinearGradient(
                colors: [show.serviceInfo.color, show.serviceInfo.color.opacity(0.55)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            Text(show.title)
                .font(.system(size: 44, weight: .heavy, design: .rounded))
                .multilineTextAlignment(.center)
                .foregroundStyle(.white)
                .padding(32)
        }
    }
}

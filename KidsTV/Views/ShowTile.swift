import SwiftUI

struct ShowTile: View {
    let show: Show

    var body: some View {
        Button {
            open(show.deepLink)
        } label: {
            VStack(alignment: .leading, spacing: 12) {
                Image(show.thumbnail)
                    .resizable()
                    .aspectRatio(16/9, contentMode: .fill)
                    .frame(width: 360, height: 203)
                    .clipped()
                    .cornerRadius(12)

                Text(show.title)
                    .font(.title3)
                    .lineLimit(1)

                Text(show.service)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .buttonStyle(.card)
    }

    private func open(_ link: String) {
        guard let url = URL(string: link) else { return }
        #if canImport(UIKit)
        UIApplication.shared.open(url)
        #endif
    }
}

import SwiftUI

// MARK: - Stock Variant Card

/// A card component for displaying a stock background preset
/// in the horizontal scroller. Shows a thumbnail preview with a label.
struct StockVariantCard: View {
    let variant: StockVariant
    let thumbnail: UIImage?
    let isSelected: Bool
    let onTap: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: {
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
            onTap()
        }) {
            VStack(spacing: 8) {
                // Thumbnail
                ZStack {
                    if let thumbnail {
                        Image(uiImage: thumbnail)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 72, height: 72)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    } else {
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color.white.opacity(0.05))
                            .frame(width: 72, height: 72)
                            .overlay {
                                Image(systemName: variant.iconName)
                                    .font(.title2)
                                    .foregroundStyle(.secondary)
                            }
                    }
                }
                .overlay {
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(
                            isSelected
                                ? LinearGradient(
                                    colors: [
                                        Color(red: 0.48, green: 0.18, blue: 1.0),
                                        Color(red: 1.0, green: 0.18, blue: 0.58),
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                                : LinearGradient(
                                    colors: [Color.white.opacity(0.1)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                            lineWidth: isSelected ? 2.5 : 1
                        )
                }
                .shadow(
                    color: isSelected
                        ? Color(red: 0.48, green: 0.18, blue: 1.0).opacity(0.3)
                        : .clear,
                    radius: 8, y: 4
                )
                .scaleEffect(isSelected ? 1.05 : 1.0)
                .animation(.spring(response: 0.35, dampingFraction: 0.65), value: isSelected)

                // Label
                Text(variant.displayName)
                    .font(.caption2)
                    .fontWeight(isSelected ? .semibold : .regular)
                    .foregroundStyle(isSelected ? .white : .secondary)
                    .lineLimit(1)
                    .frame(width: 80)
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview {
    HStack(spacing: 12) {
        StockVariantCard(
            variant: .studioMinimal,
            thumbnail: nil,
            isSelected: true,
            onTap: {}
        )
        StockVariantCard(
            variant: .cyberpunkCity,
            thumbnail: nil,
            isSelected: false,
            onTap: {}
        )
        StockVariantCard(
            variant: .natureOutdoor,
            thumbnail: nil,
            isSelected: false,
            onTap: {}
        )
    }
    .padding()
    .background(Color(red: 0.05, green: 0.05, blue: 0.1))
}

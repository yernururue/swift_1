import SwiftUI

// MARK: - Adjustment Slider

/// A custom-styled slider with gradient track, label, and value display.
struct AdjustmentSlider: View {
    let title: String
    let iconName: String
    @Binding var value: Double
    var range: ClosedRange<Double> = 0...1
    var step: Double = 0.01

    @State private var isEditing = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: iconName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(width: 16)

                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)

                Spacer()

                Text("\(Int(normalizedValue * 100))%")
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                Color(red: 0.48, green: 0.18, blue: 1.0),
                                Color(red: 1.0, green: 0.18, blue: 0.58),
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .monospacedDigit()
                    .contentTransition(.numericText())
                    .animation(.snappy(duration: 0.2), value: value)
            }

            // Custom slider track
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    // Background track
                    Capsule()
                        .fill(Color.white.opacity(0.08))
                        .frame(height: 6)

                    // Active fill
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.48, green: 0.18, blue: 1.0),
                                    Color(red: 1.0, green: 0.18, blue: 0.58),
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: max(6, geo.size.width * normalizedValue), height: 6)

                    // Thumb
                    Circle()
                        .fill(.white)
                        .frame(width: isEditing ? 20 : 16, height: isEditing ? 20 : 16)
                        .shadow(color: Color(red: 0.48, green: 0.18, blue: 1.0).opacity(0.4), radius: 6, y: 2)
                        .offset(x: max(0, min(geo.size.width - 16, geo.size.width * normalizedValue - 8)))
                        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isEditing)
                }
                .frame(height: 20)
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { drag in
                            isEditing = true
                            let fraction = max(0, min(1, drag.location.x / geo.size.width))
                            let newValue = range.lowerBound + fraction * (range.upperBound - range.lowerBound)
                            let stepped = (newValue / step).rounded() * step
                            value = min(range.upperBound, max(range.lowerBound, stepped))
                        }
                        .onEnded { _ in
                            isEditing = false
                        }
                )
            }
            .frame(height: 20)
        }
    }

    private var normalizedValue: Double {
        let span = range.upperBound - range.lowerBound
        guard span > 0 else { return 0 }
        return (value - range.lowerBound) / span
    }
}

// MARK: - Preview

#Preview {
    struct PreviewWrapper: View {
        @State var blur: Double = 0.4
        @State var shadow: Double = 0.6
        @State var scale: Double = 0.7

        var body: some View {
            VStack(spacing: 24) {
                AdjustmentSlider(title: "Background Blur", iconName: "camera.filters", value: $blur)
                AdjustmentSlider(title: "Shadow", iconName: "shadow", value: $shadow)
                AdjustmentSlider(title: "Subject Scale", iconName: "arrow.up.left.and.arrow.down.right", value: $scale)
            }
            .padding(20)
            .background(Color(red: 0.05, green: 0.05, blue: 0.1))
        }
    }
    return PreviewWrapper()
}

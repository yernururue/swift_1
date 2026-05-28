import SwiftUI

// MARK: - Live Preview Canvas

/// Interactive preview canvas showing the composited result or
/// a live preview of subject + background. Supports drag-to-reposition
/// and pinch-to-scale the subject.
struct LivePreviewCanvas: View {
    @Bindable var viewModel: BackgroundEngineViewModel

    @State private var animateGradient = false
    @State private var pulseOpacity: Double = 0.4

    var body: some View {
        ZStack {
            // Animated gradient border
            RoundedRectangle(cornerRadius: 20)
                .stroke(
                    AngularGradient(
                        colors: [
                            Color(red: 0.48, green: 0.18, blue: 1.0).opacity(0.6),
                            Color(red: 1.0, green: 0.18, blue: 0.58).opacity(0.6),
                            Color(red: 0.0, green: 0.82, blue: 0.85).opacity(0.4),
                            Color(red: 0.48, green: 0.18, blue: 1.0).opacity(0.6),
                        ],
                        center: .center,
                        startAngle: .degrees(animateGradient ? 0 : 360),
                        endAngle: .degrees(animateGradient ? 360 : 720)
                    ),
                    lineWidth: 2
                )
                .onAppear {
                    withAnimation(.linear(duration: 4).repeatForever(autoreverses: false)) {
                        animateGradient = true
                    }
                }

            // Canvas content
            RoundedRectangle(cornerRadius: 18)
                .fill(Color(red: 0.06, green: 0.06, blue: 0.10))
                .overlay {
                    canvasContent
                        .clipShape(RoundedRectangle(cornerRadius: 18))
                }
        }
        .aspectRatio(1.0, contentMode: .fit)
    }

    // MARK: - Canvas Content

    @ViewBuilder
    private var canvasContent: some View {
        if let result = viewModel.compositedResult {
            // Show composited result
            Image(uiImage: result)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .transition(.opacity.combined(with: .scale(scale: 0.95)))
        } else if viewModel.isProcessing || viewModel.isIsolatingSubject {
            // Processing indicator
            VStack(spacing: 16) {
                ProgressView()
                    .progressViewStyle(.circular)
                    .tint(Color(red: 0.48, green: 0.18, blue: 1.0))
                    .scaleEffect(1.2)

                Text(viewModel.isIsolatingSubject ? "Isolating Subject..." : "Compositing...")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
            }
        } else if viewModel.isolatedSubject != nil || viewModel.subjectImage != nil {
            // Live preview: background + draggable subject
            livePreview
        } else {
            // Empty state
            emptyState
        }
    }

    // MARK: - Live Preview

    private var livePreview: some View {
        GeometryReader { geo in
            ZStack {
                // Background preview
                if let bg = viewModel.currentBackground {
                    Image(uiImage: bg)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: geo.size.width, height: geo.size.height)
                        .blur(radius: viewModel.blurAmount * 10)
                        .clipped()
                }

                // Subject overlay (draggable)
                if let subject = viewModel.isolatedSubject ?? viewModel.subjectImage {
                    Image(uiImage: subject)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(
                            width: geo.size.width * viewModel.subjectScale,
                            height: geo.size.height * viewModel.subjectScale
                        )
                        .offset(viewModel.subjectOffset)
                        .gesture(
                            DragGesture()
                                .onChanged { drag in
                                    viewModel.subjectOffset = drag.translation
                                }
                        )
                        .gesture(
                            MagnifyGesture()
                                .onChanged { scale in
                                    viewModel.subjectScale = max(0.2, min(1.5, viewModel.subjectScale * scale.magnification))
                                }
                        )
                }
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            ZStack {
                // Pulsing dashed border icon
                RoundedRectangle(cornerRadius: 12)
                    .stroke(style: StrokeStyle(lineWidth: 2, dash: [8, 6]))
                    .foregroundStyle(
                        Color.white.opacity(pulseOpacity)
                    )
                    .frame(width: 80, height: 80)
                    .onAppear {
                        withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                            pulseOpacity = 0.15
                        }
                    }

                Image(systemName: "person.crop.rectangle.badge.plus")
                    .font(.title)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                Color(red: 0.48, green: 0.18, blue: 1.0),
                                Color(red: 1.0, green: 0.18, blue: 0.58),
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }

            VStack(spacing: 4) {
                Text("Upload a Subject")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white.opacity(0.8))

                Text("Add your image to get started")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

import PhotosUI
import SwiftUI

// MARK: - Background Engine View

/// The main Background Engine screen with a premium dark glassmorphism UI.
/// Provides subject upload, background selection (photo/color/gradient/stock),
/// adjustment controls, and compositing.
struct BackgroundEngineView: View {
    @State private var viewModel = BackgroundEngineViewModel()

    // Accent gradient used throughout the UI
    private let accentGradient = LinearGradient(
        colors: [
            Color(red: 0.48, green: 0.18, blue: 1.0),
            Color(red: 1.0, green: 0.18, blue: 0.58),
        ],
        startPoint: .leading,
        endPoint: .trailing
    )

    var body: some View {
        NavigationStack {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 20) {
                    // Live Preview Canvas
                    LivePreviewCanvas(viewModel: viewModel)
                        .padding(.horizontal, 16)

                    // Subject Upload
                    subjectSection

                    // Background Mode Picker
                    modePicker

                    // Mode-specific controls
                    modeControls

                    // Adjustments
                    adjustmentsSection

                    // Generate Button
                    generateButton

                    Spacer(minLength: 30)
                }
                .padding(.top, 8)
            }
            .background(
                LinearGradient(
                    colors: [
                        Color(red: 0.05, green: 0.05, blue: 0.10),
                        Color(red: 0.03, green: 0.03, blue: 0.07),
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
            )
            .navigationTitle("Background Studio")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            viewModel.resetAll()
                        }
                    } label: {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    if viewModel.compositedResult != nil {
                        Menu {
                            Button {
                                viewModel.exportToPhotoLibrary()
                            } label: {
                                Label("Save to Photos", systemImage: "square.and.arrow.down")
                            }

                            if let image = viewModel.compositedResult {
                                ShareLink(
                                    item: Image(uiImage: image),
                                    preview: SharePreview("Background Studio Export", image: Image(uiImage: image))
                                )
                            }
                        } label: {
                            Image(systemName: "square.and.arrow.up")
                                .font(.subheadline)
                                .foregroundStyle(accentGradient)
                        }
                        .transition(.scale.combined(with: .opacity))
                    }
                }
            }
            .alert("Oops", isPresented: $viewModel.showError) {
                Button("OK") {}
            } message: {
                Text(viewModel.errorMessage ?? "Something went wrong.")
            }
            .alert("Saved!", isPresented: $viewModel.showExportSuccess) {
                Button("OK") {}
            } message: {
                Text("Image saved to your photo library.")
            }
        }
    }

    // MARK: - Subject Section

    private var subjectSection: some View {
        GlassCard {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Label("Subject", systemImage: "person.crop.rectangle")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)

                    if viewModel.isolatedSubject != nil {
                        Text("Background removed ✓")
                            .font(.caption2)
                            .foregroundStyle(.green.opacity(0.8))
                    } else if viewModel.subjectImage != nil {
                        Text("Image loaded")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    } else {
                        Text("Choose your main subject")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                PhotosPicker(
                    selection: $viewModel.subjectPhotoItem,
                    matching: .images,
                    photoLibrary: .shared()
                ) {
                    HStack(spacing: 6) {
                        Image(systemName: viewModel.subjectImage != nil ? "arrow.triangle.2.circlepath" : "plus")
                            .font(.caption)
                        Text(viewModel.subjectImage != nil ? "Change" : "Upload")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(accentGradient.opacity(0.8))
                    )
                    .foregroundStyle(.white)
                }
            }
        }
    }

    // MARK: - Mode Picker

    private var modePicker: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("Background")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)

                HStack(spacing: 4) {
                    ForEach(BackgroundMode.allCases) { mode in
                        Button {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                                viewModel.backgroundMode = mode
                                viewModel.compositedResult = nil
                            }
                        } label: {
                            VStack(spacing: 4) {
                                Image(systemName: mode.iconName)
                                    .font(.caption)
                                Text(mode.rawValue)
                                    .font(.caption2)
                                    .fontWeight(.medium)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background {
                                if viewModel.backgroundMode == mode {
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(accentGradient.opacity(0.25))
                                        .overlay {
                                            RoundedRectangle(cornerRadius: 10)
                                                .stroke(accentGradient, lineWidth: 1)
                                        }
                                        .matchedGeometryEffect(id: "modeSelector", in: modeNamespace)
                                }
                            }
                            .foregroundStyle(viewModel.backgroundMode == mode ? .white : .secondary)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    @Namespace private var modeNamespace

    // MARK: - Mode Controls

    @ViewBuilder
    private var modeControls: some View {
        switch viewModel.backgroundMode {
        case .uploadedPhoto:
            uploadedPhotoControls
        case .solidColor:
            solidColorControls
        case .gradient:
            gradientControls
        case .stockVariant:
            stockVariantControls
        }
    }

    // MARK: - Uploaded Photo Controls

    private var uploadedPhotoControls: some View {
        GlassCard {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Label("Background Photo", systemImage: "photo.on.rectangle.angled")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)

                    Text(viewModel.uploadedBackground != nil ? "Photo loaded" : "Choose a background image")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                PhotosPicker(
                    selection: $viewModel.backgroundPhotoItem,
                    matching: .images,
                    photoLibrary: .shared()
                ) {
                    HStack(spacing: 6) {
                        Image(systemName: viewModel.uploadedBackground != nil ? "arrow.triangle.2.circlepath" : "plus")
                            .font(.caption)
                        Text(viewModel.uploadedBackground != nil ? "Change" : "Select")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(.white.opacity(0.12))
                    )
                    .foregroundStyle(.white)
                }
            }
        }
        .transition(.asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity),
                                 removal: .move(edge: .leading).combined(with: .opacity)))
    }

    // MARK: - Solid Color Controls

    private var solidColorControls: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                Label("Solid Color", systemImage: "paintpalette.fill")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)

                HStack {
                    // Color preview
                    RoundedRectangle(cornerRadius: 10)
                        .fill(viewModel.solidColor)
                        .frame(width: 44, height: 44)
                        .overlay {
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(.white.opacity(0.2), lineWidth: 1)
                        }

                    ColorPicker("", selection: $viewModel.solidColor, supportsOpacity: false)
                        .labelsHidden()

                    Spacer()
                }
            }
        }
        .transition(.asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity),
                                 removal: .move(edge: .leading).combined(with: .opacity)))
    }

    // MARK: - Gradient Controls

    private var gradientControls: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 14) {
                Label("Gradient", systemImage: "circle.lefthalf.filled")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)

                // Gradient preview
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        LinearGradient(
                            colors: [viewModel.gradientPreset.startColor, viewModel.gradientPreset.endColor],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(height: 36)
                    .overlay {
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(.white.opacity(0.1), lineWidth: 1)
                    }

                HStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Start")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        ColorPicker("", selection: $viewModel.gradientPreset.startColor, supportsOpacity: false)
                            .labelsHidden()
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("End")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        ColorPicker("", selection: $viewModel.gradientPreset.endColor, supportsOpacity: false)
                            .labelsHidden()
                    }

                    Spacer()

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Angle")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        HStack(spacing: 4) {
                            Text("\(Int(viewModel.gradientPreset.angle))°")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundStyle(.white)
                                .monospacedDigit()

                            Stepper("", value: $viewModel.gradientPreset.angle, in: 0...360, step: 15)
                                .labelsHidden()
                        }
                    }
                }
            }
        }
        .transition(.asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity),
                                 removal: .move(edge: .leading).combined(with: .opacity)))
    }

    // MARK: - Stock Variant Controls

    private var stockVariantControls: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("   Presets")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.white)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(StockVariant.allCases) { variant in
                        StockVariantCard(
                            variant: variant,
                            thumbnail: viewModel.stockThumbnails[variant],
                            isSelected: viewModel.stockVariant == variant
                        ) {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                                viewModel.stockVariant = variant
                                viewModel.compositedResult = nil
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 4)
            }

            // Selected variant description
            if viewModel.backgroundMode == .stockVariant {
                Text(viewModel.stockVariant.description)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 16)
                    .transition(.opacity)
                    .id(viewModel.stockVariant) // Force re-render on change
            }
        }
        .transition(.asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity),
                                 removal: .move(edge: .leading).combined(with: .opacity)))
    }

    // MARK: - Adjustments Section

    private var adjustmentsSection: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 16) {
                Label("Adjustments", systemImage: "slider.horizontal.3")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)

                AdjustmentSlider(
                    title: "Background Blur",
                    iconName: "camera.filters",
                    value: $viewModel.blurAmount
                )

                AdjustmentSlider(
                    title: "Shadow Intensity",
                    iconName: "shadow",
                    value: $viewModel.shadowOpacity
                )

                AdjustmentSlider(
                    title: "Shadow Softness",
                    iconName: "circle.dotted",
                    value: $viewModel.shadowRadius
                )

                AdjustmentSlider(
                    title: "Subject Scale",
                    iconName: "arrow.up.left.and.arrow.down.right",
                    value: $viewModel.subjectScale,
                    range: 0.1...1.5
                )
            }
        }
    }

    // MARK: - Generate Button

    private var generateButton: some View {
        Button {
            Task {
                await viewModel.generateComposite()
            }
        } label: {
            HStack(spacing: 10) {
                if viewModel.isProcessing {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .tint(.white)
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: "sparkles")
                        .font(.subheadline)
                }

                Text(viewModel.isProcessing ? "Processing..." : "Generate Composite")
                    .font(.subheadline)
                    .fontWeight(.bold)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(accentGradient)
                    .shadow(color: Color(red: 0.48, green: 0.18, blue: 1.0).opacity(0.4), radius: 12, y: 6)
            )
            .foregroundStyle(.white)
        }
        .disabled(viewModel.isProcessing || viewModel.subjectImage == nil)
        .opacity(viewModel.subjectImage == nil ? 0.5 : 1.0)
        .padding(.horizontal, 16)
        .animation(.easeInOut(duration: 0.2), value: viewModel.isProcessing)
    }
}

// MARK: - Glass Card Component

/// A reusable glassmorphic card with translucent material background.
struct GlassCard<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        content
            .padding(16)
            .background {
                RoundedRectangle(cornerRadius: 18)
                    .fill(.ultraThinMaterial.opacity(0.5))
                    .overlay {
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(
                                LinearGradient(
                                    colors: [.white.opacity(0.12), .white.opacity(0.04)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 0.5
                            )
                    }
            }
            .padding(.horizontal, 16)
    }
}

// MARK: - Preview

#Preview {
    BackgroundEngineView()
        .preferredColorScheme(.dark)
}

import Observation
import PhotosUI
import SwiftUI
import UIKit

// MARK: - Background Engine ViewModel

@Observable
final class BackgroundEngineViewModel {

    // MARK: - Subject

    var subjectImage: UIImage?
    var isolatedSubject: UIImage?
    var subjectPhotoItem: PhotosPickerItem? {
        didSet { Task { await loadSubjectImage() } }
    }

    // MARK: - Background Mode

    var backgroundMode: BackgroundMode = .stockVariant
    var stockVariant: StockVariant = .studioMinimal

    // MARK: - Solid Color

    var solidColor: Color = Color(red: 0.12, green: 0.12, blue: 0.18)

    // MARK: - Gradient

    var gradientPreset: GradientPreset = .defaultPreset

    // MARK: - Uploaded Background

    var uploadedBackground: UIImage?
    var backgroundPhotoItem: PhotosPickerItem? {
        didSet { Task { await loadBackgroundImage() } }
    }

    // MARK: - Adjustments

    var blurAmount: Double = 0.3
    var shadowOpacity: Double = 0.5
    var shadowRadius: Double = 0.4
    var subjectScale: Double = 0.6
    var subjectOffset: CGSize = .zero

    // MARK: - Output

    var compositedResult: UIImage?
    var isProcessing: Bool = false
    var isIsolatingSubject: Bool = false
    var errorMessage: String?
    var showError: Bool = false
    var showExportSuccess: Bool = false

    // MARK: - Cached Backgrounds

    private var stockBackgroundCache: [StockVariant: UIImage] = [:]
    var stockThumbnails: [StockVariant: UIImage] = [:]

    // MARK: - Init

    init() {
        // Pre-generate thumbnails for stock variants
        let vm = self
        Task { @MainActor in
            var thumbnails: [StockVariant: UIImage] = [:]
            for variant in StockVariant.allCases {
                thumbnails[variant] = ProceduralBackgrounds.generateThumbnail(variant: variant)
            }
            vm.stockThumbnails = thumbnails
        }
    }

    // MARK: - Image Loading

    @MainActor
    private func loadSubjectImage() async {
        guard let item = subjectPhotoItem else { return }
        do {
            if let data = try await item.loadTransferable(type: Data.self),
               let image = UIImage(data: data)
            {
                subjectImage = image
                compositedResult = nil

                // Auto-isolate subject
                isIsolatingSubject = true
                do {
                    isolatedSubject = try await ImageCompositor.isolateSubject(from: image)
                } catch {
                    // If isolation fails, use original image
                    isolatedSubject = image
                    errorMessage = "Could not auto-remove background. Using original image."
                    showError = true
                }
                isIsolatingSubject = false
            }
        } catch {
            errorMessage = "Failed to load subject image."
            showError = true
        }
    }

    @MainActor
    private func loadBackgroundImage() async {
        guard let item = backgroundPhotoItem else { return }
        do {
            if let data = try await item.loadTransferable(type: Data.self),
               let image = UIImage(data: data)
            {
                uploadedBackground = image
                compositedResult = nil
            }
        } catch {
            errorMessage = "Failed to load background image."
            showError = true
        }
    }

    // MARK: - Current Background

    /// Returns the current background image based on the selected mode.
    var currentBackground: UIImage? {
        switch backgroundMode {
        case .solidColor:
            return ProceduralBackgrounds.generateSolidColor(UIColor(solidColor))
        case .gradient:
            return ProceduralBackgrounds.generateGradient(
                startColor: UIColor(gradientPreset.startColor),
                endColor: UIColor(gradientPreset.endColor),
                angleDegrees: gradientPreset.angle
            )
        case .stockVariant:
            if let cached = stockBackgroundCache[stockVariant] {
                return cached
            }
            let bg = ProceduralBackgrounds.generate(variant: stockVariant)
            stockBackgroundCache[stockVariant] = bg
            return bg
        case .uploadedPhoto:
            return uploadedBackground
        }
    }

    // MARK: - Compositing

    @MainActor
    func generateComposite() async {
        guard let subject = isolatedSubject ?? subjectImage else {
            errorMessage = "Please upload a subject image first."
            showError = true
            return
        }

        guard let background = currentBackground else {
            errorMessage = "Please select a background."
            showError = true
            return
        }

        isProcessing = true
        errorMessage = nil

        // Get color temperature for stock variants
        let colorTemp: (neutral: CGFloat, tint: CGFloat)?
        if backgroundMode == .stockVariant {
            colorTemp = stockVariant.colorTemperature
        } else {
            colorTemp = nil
        }

        // Perform compositing on background thread
        let blurAmt = blurAmount
        let shadowOp = shadowOpacity
        let shadowRad = shadowRadius
        let scale = subjectScale
        let offset = subjectOffset

        let result = await Task.detached(priority: .userInitiated) {
            ImageCompositor.composite(
                subject: subject,
                background: background,
                blurAmount: blurAmt,
                shadowOpacity: shadowOp,
                shadowRadius: shadowRad,
                subjectScale: scale,
                subjectOffset: offset,
                colorTemperature: colorTemp
            )
        }.value

        if let result {
            compositedResult = result
        } else {
            errorMessage = "Compositing failed. Please try again."
            showError = true
        }

        isProcessing = false
    }

    // MARK: - Export

    func exportToPhotoLibrary() {
        guard let image = compositedResult else { return }
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
        showExportSuccess = true
    }

    // MARK: - Reset

    func resetAll() {
        subjectImage = nil
        isolatedSubject = nil
        subjectPhotoItem = nil
        backgroundMode = .stockVariant
        stockVariant = .studioMinimal
        solidColor = Color(red: 0.12, green: 0.12, blue: 0.18)
        gradientPreset = .defaultPreset
        uploadedBackground = nil
        backgroundPhotoItem = nil
        blurAmount = 0.3
        shadowOpacity = 0.5
        shadowRadius = 0.4
        subjectScale = 0.6
        subjectOffset = .zero
        compositedResult = nil
        isProcessing = false
        errorMessage = nil
        stockBackgroundCache.removeAll()
    }
}

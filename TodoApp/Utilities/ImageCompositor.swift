import CoreImage
import CoreImage.CIFilterBuiltins
import UIKit
import Vision

// MARK: - Image Compositor

/// Core compositing engine that blends a subject onto a background
/// using Core Image filters for realistic integration.
struct ImageCompositor {

    private static let context = CIContext(options: [
        .useSoftwareRenderer: false,
        .highQualityDownsample: true,
    ])

    // MARK: - Subject Isolation (Vision Framework)

    /// Removes the background from the input image using Vision's person/subject segmentation.
    /// Returns the isolated subject with a transparent background.
    @MainActor
    static func isolateSubject(from image: UIImage) async throws -> UIImage {
        guard let cgImage = image.cgImage else {
            throw CompositorError.invalidImage
        }

        let request = VNGenerateForegroundInstanceMaskRequest()
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])

        try handler.perform([request])

        guard let result = request.results?.first else {
            throw CompositorError.segmentationFailed
        }

        let maskPixelBuffer = try result.generateScaledMaskForImage(
            forInstances: result.allInstances,
            from: handler
        )

        let maskCIImage = CIImage(cvPixelBuffer: maskPixelBuffer)
        let subjectCIImage = CIImage(cgImage: cgImage)

        // Scale mask to match subject dimensions
        let scaleX = subjectCIImage.extent.width / maskCIImage.extent.width
        let scaleY = subjectCIImage.extent.height / maskCIImage.extent.height
        let scaledMask = maskCIImage.transformed(by: CGAffineTransform(scaleX: scaleX, y: scaleY))

        // Feather the mask edges for smooth blending
        let featheredMask = featherMaskEdges(scaledMask, radius: 2.0)

        // Blend subject with transparent background using the mask
        let clearBackground = CIImage(color: .clear).cropped(to: subjectCIImage.extent)

        guard let blendFilter = CIFilter(
            name: "CIBlendWithMask",
            parameters: [
                kCIInputImageKey: subjectCIImage,
                kCIInputBackgroundImageKey: clearBackground,
                kCIInputMaskImageKey: featheredMask,
            ]
        ),
            let output = blendFilter.outputImage
        else {
            throw CompositorError.filterFailed
        }

        guard let cgResult = context.createCGImage(output, from: output.extent) else {
            throw CompositorError.renderFailed
        }

        return UIImage(cgImage: cgResult, scale: image.scale, orientation: image.imageOrientation)
    }

    // MARK: - Full Composite Pipeline

    /// Composites an isolated subject onto a background with shadow, lighting, and blur.
    static func composite(
        subject: UIImage,
        background: UIImage,
        blurAmount: Double,
        shadowOpacity: Double,
        shadowRadius: Double,
        subjectScale: Double,
        subjectOffset: CGSize,
        colorTemperature: (neutral: CGFloat, tint: CGFloat)? = nil
    ) -> UIImage? {
        guard let subjectCI = CIImage(image: subject),
              let bgCI = CIImage(image: background)
        else { return nil }

        let canvasSize = bgCI.extent

        // 1. Apply depth-of-field blur to background
        let blurredBG = applyDepthOfField(to: bgCI, amount: blurAmount)

        // 2. Scale and position subject
        let scaleFactor = subjectScale
        let scaledSubject = subjectCI.transformed(
            by: CGAffineTransform(scaleX: scaleFactor, y: scaleFactor)
        )

        // Center the subject, then apply user offset
        let subjectExtent = scaledSubject.extent
        let centerX = (canvasSize.width - subjectExtent.width) / 2 + subjectOffset.width
        let centerY = (canvasSize.height - subjectExtent.height) / 2 - subjectOffset.height
        let positionedSubject = scaledSubject.transformed(
            by: CGAffineTransform(translationX: centerX - subjectExtent.origin.x,
                                  y: centerY - subjectExtent.origin.y)
        )

        // 3. Apply color temperature matching to subject
        let adjustedSubject: CIImage
        if let temp = colorTemperature {
            adjustedSubject = matchLighting(positionedSubject, temperature: temp)
        } else {
            adjustedSubject = positionedSubject
        }

        // 4. Generate contact shadow
        let shadow = generateContactShadow(
            for: adjustedSubject,
            opacity: shadowOpacity,
            radius: shadowRadius,
            canvasExtent: canvasSize
        )

        // 5. Layer composite: background → shadow → subject
        let withShadow = shadow.composited(over: blurredBG.cropped(to: canvasSize))
        let final = adjustedSubject.composited(over: withShadow)

        guard let cgResult = context.createCGImage(final, from: canvasSize) else {
            return nil
        }

        return UIImage(cgImage: cgResult)
    }

    // MARK: - Depth of Field

    private static func applyDepthOfField(to image: CIImage, amount: Double) -> CIImage {
        guard amount > 0.1 else { return image }

        let clampFilter = CIFilter.affineClamp()
        clampFilter.inputImage = image
        clampFilter.transform = .identity

        guard let clamped = clampFilter.outputImage else { return image }

        let blurFilter = CIFilter.gaussianBlur()
        blurFilter.inputImage = clamped
        blurFilter.radius = Float(amount * 15)

        return blurFilter.outputImage?.cropped(to: image.extent) ?? image
    }

    // MARK: - Lighting / Color Temperature Matching

    private static func matchLighting(
        _ image: CIImage,
        temperature: (neutral: CGFloat, tint: CGFloat)
    ) -> CIImage {
        let tempFilter = CIFilter.temperatureAndTint()
        tempFilter.inputImage = image
        tempFilter.neutral = CIVector(x: temperature.neutral, y: 0)
        tempFilter.targetNeutral = CIVector(x: 6500, y: 0)

        return tempFilter.outputImage ?? image
    }

    // MARK: - Contact Shadow

    private static func generateContactShadow(
        for subject: CIImage,
        opacity: Double,
        radius: Double,
        canvasExtent: CGRect
    ) -> CIImage {
        guard opacity > 0.01 else {
            return CIImage(color: .clear).cropped(to: canvasExtent)
        }

        // Create dark silhouette of the subject
        let colorMatrix = CIFilter.colorMatrix()
        colorMatrix.inputImage = subject
        colorMatrix.rVector = CIVector(x: 0, y: 0, z: 0, w: 0)
        colorMatrix.gVector = CIVector(x: 0, y: 0, z: 0, w: 0)
        colorMatrix.bVector = CIVector(x: 0, y: 0, z: 0, w: 0)
        colorMatrix.aVector = CIVector(x: 0, y: 0, z: 0, w: CGFloat(opacity))

        guard let darkSilhouette = colorMatrix.outputImage else {
            return CIImage(color: .clear).cropped(to: canvasExtent)
        }

        // Offset shadow downward and squash vertically
        let shadowTransform = CGAffineTransform(translationX: 0, y: -15)
            .scaledBy(x: 1.0, y: 0.3)
        let offsetShadow = darkSilhouette.transformed(by: shadowTransform)

        // Blur the shadow
        let clamp = CIFilter.affineClamp()
        clamp.inputImage = offsetShadow
        clamp.transform = .identity

        guard let clamped = clamp.outputImage else {
            return CIImage(color: .clear).cropped(to: canvasExtent)
        }

        let blur = CIFilter.gaussianBlur()
        blur.inputImage = clamped
        blur.radius = Float(radius * 10)

        return blur.outputImage?.cropped(to: canvasExtent)
            ?? CIImage(color: .clear).cropped(to: canvasExtent)
    }

    // MARK: - Edge Feathering

    private static func featherMaskEdges(_ mask: CIImage, radius: Double) -> CIImage {
        let clamp = CIFilter.affineClamp()
        clamp.inputImage = mask
        clamp.transform = .identity

        guard let clamped = clamp.outputImage else { return mask }

        let blur = CIFilter.gaussianBlur()
        blur.inputImage = clamped
        blur.radius = Float(radius)

        return blur.outputImage?.cropped(to: mask.extent) ?? mask
    }

    // MARK: - Errors

    enum CompositorError: LocalizedError {
        case invalidImage
        case segmentationFailed
        case filterFailed
        case renderFailed

        var errorDescription: String? {
            switch self {
            case .invalidImage: return "The provided image is invalid or corrupted."
            case .segmentationFailed: return "Could not isolate the subject from the image."
            case .filterFailed: return "Image filter pipeline failed."
            case .renderFailed: return "Could not render the final image."
            }
        }
    }
}

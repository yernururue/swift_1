import CoreGraphics
import CoreImage
import CoreImage.CIFilterBuiltins
import UIKit

// MARK: - Procedural Background Generator

/// Generates all stock backgrounds programmatically using Core Graphics and Core Image.
struct ProceduralBackgrounds {

    /// Standard output size for generated backgrounds.
    static let outputSize = CGSize(width: 1920, height: 1920)

    // MARK: - Public Factory

    /// Generates a UIImage for the given stock variant.
    static func generate(variant: StockVariant, size: CGSize? = nil) -> UIImage {
        let targetSize = size ?? outputSize
        switch variant {
        case .studioMinimal:
            return generateStudioMinimal(size: targetSize)
        case .cyberpunkCity:
            return generateCyberpunkCity(size: targetSize)
        case .cozyInterior:
            return generateCozyInterior(size: targetSize)
        case .abstractGeometric:
            return generateAbstractGeometric(size: targetSize)
        case .natureOutdoor:
            return generateNatureOutdoor(size: targetSize)
        }
    }

    /// Generates a thumbnail for the stock variant card preview.
    static func generateThumbnail(variant: StockVariant) -> UIImage {
        generate(variant: variant, size: CGSize(width: 128, height: 128))
    }

    // MARK: - Solid Color

    /// Creates a solid-color background with subtle studio vignetting.
    static func generateSolidColor(_ color: UIColor, size: CGSize? = nil) -> UIImage {
        let targetSize = size ?? outputSize
        let renderer = UIGraphicsImageRenderer(size: targetSize)
        return renderer.image { ctx in
            let rect = CGRect(origin: .zero, size: targetSize)
            color.setFill()
            ctx.fill(rect)

            // Subtle radial vignette
            let center = CGPoint(x: targetSize.width / 2, y: targetSize.height * 0.4)
            let gradient = CGGradient(
                colorsSpace: CGColorSpaceCreateDeviceRGB(),
                colors: [
                    UIColor.white.withAlphaComponent(0.08).cgColor,
                    UIColor.clear.cgColor,
                ] as CFArray,
                locations: [0, 1]
            )!
            ctx.cgContext.drawRadialGradient(
                gradient,
                startCenter: center,
                startRadius: 0,
                endCenter: center,
                endRadius: max(targetSize.width, targetSize.height) * 0.7,
                options: .drawsAfterEndLocation
            )
        }
    }

    // MARK: - Linear Gradient

    /// Creates a linear gradient background.
    static func generateGradient(
        startColor: UIColor,
        endColor: UIColor,
        angleDegrees: Double,
        size: CGSize? = nil
    ) -> UIImage {
        let targetSize = size ?? outputSize
        let renderer = UIGraphicsImageRenderer(size: targetSize)
        return renderer.image { ctx in
            let _ = CGRect(origin: .zero, size: targetSize)
            let angleRad = angleDegrees * .pi / 180

            let dx = cos(angleRad)
            let dy = sin(angleRad)
            let maxDim = max(targetSize.width, targetSize.height)

            let center = CGPoint(x: targetSize.width / 2, y: targetSize.height / 2)
            let start = CGPoint(x: center.x - dx * maxDim / 2, y: center.y - dy * maxDim / 2)
            let end = CGPoint(x: center.x + dx * maxDim / 2, y: center.y + dy * maxDim / 2)

            let gradient = CGGradient(
                colorsSpace: CGColorSpaceCreateDeviceRGB(),
                colors: [startColor.cgColor, endColor.cgColor] as CFArray,
                locations: [0, 1]
            )!
            ctx.cgContext.drawLinearGradient(
                gradient,
                start: start,
                end: end,
                options: [.drawsBeforeStartLocation, .drawsAfterEndLocation]
            )
        }
    }

    // MARK: - Studio Minimal

    private static func generateStudioMinimal(size: CGSize) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { ctx in
            let _ = CGRect(origin: .zero, size: size)

            // Smooth radial gradient: light center → darker edges
            let topColor = UIColor(red: 0.88, green: 0.88, blue: 0.90, alpha: 1)
            let edgeColor = UIColor(red: 0.72, green: 0.72, blue: 0.75, alpha: 1)

            let center = CGPoint(x: size.width / 2, y: size.height * 0.35)
            let gradient = CGGradient(
                colorsSpace: CGColorSpaceCreateDeviceRGB(),
                colors: [topColor.cgColor, edgeColor.cgColor] as CFArray,
                locations: [0, 1]
            )!
            ctx.cgContext.drawRadialGradient(
                gradient,
                startCenter: center,
                startRadius: 0,
                endCenter: center,
                endRadius: size.width * 0.85,
                options: .drawsAfterEndLocation
            )

            // Floor plane — subtle horizon line
            let floorY = size.height * 0.62
            let floorGradient = CGGradient(
                colorsSpace: CGColorSpaceCreateDeviceRGB(),
                colors: [
                    UIColor(white: 0.0, alpha: 0.05).cgColor,
                    UIColor(white: 0.0, alpha: 0.0).cgColor,
                ] as CFArray,
                locations: [0, 1]
            )!
            ctx.cgContext.drawLinearGradient(
                floorGradient,
                start: CGPoint(x: 0, y: floorY),
                end: CGPoint(x: 0, y: floorY + size.height * 0.06),
                options: []
            )

            // Subtle floor shadow (elongated oval)
            let shadowRect = CGRect(
                x: size.width * 0.25,
                y: floorY - size.height * 0.01,
                width: size.width * 0.5,
                height: size.height * 0.03
            )
            let shadowPath = UIBezierPath(ovalIn: shadowRect)
            UIColor(white: 0, alpha: 0.08).setFill()
            shadowPath.fill()
        }
    }

    // MARK: - Cyberpunk City

    private static func generateCyberpunkCity(size: CGSize) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { ctx in
            // Dark base
            UIColor(red: 0.04, green: 0.02, blue: 0.08, alpha: 1).setFill()
            ctx.fill(CGRect(origin: .zero, size: size))

            let gc = ctx.cgContext

            // Neon glow blobs
            let neonColors: [(UIColor, CGPoint, CGFloat)] = [
                (UIColor(red: 1.0, green: 0.0, blue: 0.6, alpha: 0.35),
                 CGPoint(x: size.width * 0.2, y: size.height * 0.3), size.width * 0.4),
                (UIColor(red: 0.0, green: 0.8, blue: 1.0, alpha: 0.3),
                 CGPoint(x: size.width * 0.8, y: size.height * 0.25), size.width * 0.35),
                (UIColor(red: 0.5, green: 0.0, blue: 1.0, alpha: 0.25),
                 CGPoint(x: size.width * 0.5, y: size.height * 0.7), size.width * 0.45),
                (UIColor(red: 1.0, green: 0.3, blue: 0.0, alpha: 0.15),
                 CGPoint(x: size.width * 0.15, y: size.height * 0.8), size.width * 0.3),
            ]

            for (color, center, radius) in neonColors {
                let gradient = CGGradient(
                    colorsSpace: CGColorSpaceCreateDeviceRGB(),
                    colors: [color.cgColor, UIColor.clear.cgColor] as CFArray,
                    locations: [0, 1]
                )!
                gc.drawRadialGradient(
                    gradient,
                    startCenter: center, startRadius: 0,
                    endCenter: center, endRadius: radius,
                    options: .drawsAfterEndLocation
                )
            }

            // Rain streaks
            gc.setStrokeColor(UIColor.white.withAlphaComponent(0.08).cgColor)
            gc.setLineWidth(1.0)
            let rng = SystemRandomNumberGenerator()
            var gen = rng
            for _ in 0..<80 {
                let x = CGFloat.random(in: 0...size.width, using: &gen)
                let y = CGFloat.random(in: 0...size.height, using: &gen)
                let length = CGFloat.random(in: 15...40, using: &gen)
                gc.move(to: CGPoint(x: x, y: y))
                gc.addLine(to: CGPoint(x: x - 2, y: y + length))
                gc.strokePath()
            }

            // Simulated building silhouettes at bottom
            gc.setFillColor(UIColor(red: 0.02, green: 0.01, blue: 0.05, alpha: 0.8).cgColor)
            for i in 0..<12 {
                let bw = CGFloat.random(in: size.width * 0.06...size.width * 0.12, using: &gen)
                let bh = CGFloat.random(in: size.height * 0.15...size.height * 0.35, using: &gen)
                let bx = CGFloat(i) * (size.width / 12) + CGFloat.random(in: -10...10, using: &gen)
                let rect = CGRect(x: bx, y: size.height - bh, width: bw, height: bh)
                gc.fill(rect)

                // Tiny window lights
                gc.setFillColor(UIColor(red: 1, green: 0.9, blue: 0.5, alpha: 0.4).cgColor)
                let cols = Int(bw / 8)
                let rows = Int(bh / 12)
                for r in 0..<rows {
                    for c in 0..<cols {
                        if Bool.random(using: &gen) {
                            let wx = bx + CGFloat(c) * 8 + 3
                            let wy = size.height - bh + CGFloat(r) * 12 + 4
                            gc.fill(CGRect(x: wx, y: wy, width: 3, height: 5))
                        }
                    }
                }
                gc.setFillColor(UIColor(red: 0.02, green: 0.01, blue: 0.05, alpha: 0.8).cgColor)
            }

            // Wet ground reflection
            let reflectionGradient = CGGradient(
                colorsSpace: CGColorSpaceCreateDeviceRGB(),
                colors: [
                    UIColor(red: 0.5, green: 0.0, blue: 0.8, alpha: 0.15).cgColor,
                    UIColor.clear.cgColor,
                ] as CFArray,
                locations: [0, 1]
            )!
            gc.drawLinearGradient(
                reflectionGradient,
                start: CGPoint(x: 0, y: size.height),
                end: CGPoint(x: 0, y: size.height * 0.85),
                options: []
            )
        }
    }

    // MARK: - Cozy Interior

    private static func generateCozyInterior(size: CGSize) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { ctx in
            let gc = ctx.cgContext
            let rect = CGRect(origin: .zero, size: size)

            // Warm amber base
            let warmBase = UIColor(red: 0.35, green: 0.22, blue: 0.12, alpha: 1)
            let warmLight = UIColor(red: 0.55, green: 0.38, blue: 0.20, alpha: 1)

            warmBase.setFill()
            gc.fill(rect)

            // Warm radial light from upper-left (window simulation)
            let windowCenter = CGPoint(x: size.width * 0.2, y: size.height * 0.15)
            let windowGradient = CGGradient(
                colorsSpace: CGColorSpaceCreateDeviceRGB(),
                colors: [
                    UIColor(red: 1.0, green: 0.9, blue: 0.7, alpha: 0.4).cgColor,
                    UIColor.clear.cgColor,
                ] as CFArray,
                locations: [0, 1]
            )!
            gc.drawRadialGradient(
                windowGradient,
                startCenter: windowCenter, startRadius: 0,
                endCenter: windowCenter, endRadius: size.width * 0.6,
                options: .drawsAfterEndLocation
            )

            // Window light rectangles (simulated light beams)
            gc.saveGState()
            gc.setFillColor(UIColor(red: 1, green: 0.95, blue: 0.8, alpha: 0.06).cgColor)
            let beam = UIBezierPath()
            beam.move(to: CGPoint(x: size.width * 0.1, y: 0))
            beam.addLine(to: CGPoint(x: size.width * 0.3, y: 0))
            beam.addLine(to: CGPoint(x: size.width * 0.55, y: size.height))
            beam.addLine(to: CGPoint(x: size.width * 0.25, y: size.height))
            beam.close()
            beam.fill()
            gc.restoreGState()

            // Wood grain texture (horizontal lines with variation)
            gc.setStrokeColor(UIColor(white: 0, alpha: 0.04).cgColor)
            gc.setLineWidth(0.5)
            var gen = SystemRandomNumberGenerator()
            let floorY = size.height * 0.6
            for y in stride(from: floorY, to: size.height, by: 4) {
                gc.move(to: CGPoint(x: 0, y: y + CGFloat.random(in: -1...1, using: &gen)))
                for x in stride(from: CGFloat(0), to: size.width, by: 20) {
                    gc.addLine(to: CGPoint(
                        x: x + 20,
                        y: y + CGFloat.random(in: -1.5...1.5, using: &gen)
                    ))
                }
                gc.strokePath()
            }

            // Wall / floor boundary
            let wallFloor = CGGradient(
                colorsSpace: CGColorSpaceCreateDeviceRGB(),
                colors: [
                    warmLight.cgColor,
                    warmBase.cgColor,
                ] as CFArray,
                locations: [0, 1]
            )!
            gc.drawLinearGradient(
                wallFloor,
                start: CGPoint(x: 0, y: floorY - size.height * 0.05),
                end: CGPoint(x: 0, y: floorY + size.height * 0.05),
                options: []
            )

            // Plant silhouettes (simple abstract leaves)
            gc.setFillColor(UIColor(red: 0.15, green: 0.25, blue: 0.10, alpha: 0.3).cgColor)
            drawLeafCluster(gc: gc, center: CGPoint(x: size.width * 0.85, y: size.height * 0.4), scale: size.width * 0.08)
            drawLeafCluster(gc: gc, center: CGPoint(x: size.width * 0.9, y: size.height * 0.55), scale: size.width * 0.06)
        }
    }

    private static func drawLeafCluster(gc: CGContext, center: CGPoint, scale: CGFloat) {
        for angle in stride(from: 0.0, to: 360.0, by: 45.0) {
            gc.saveGState()
            gc.translateBy(x: center.x, y: center.y)
            gc.rotate(by: CGFloat(angle * .pi / 180))
            let leafPath = CGMutablePath()
            leafPath.addEllipse(in: CGRect(x: -scale * 0.15, y: -scale, width: scale * 0.3, height: scale))
            gc.addPath(leafPath)
            gc.fillPath()
            gc.restoreGState()
        }
    }

    // MARK: - Abstract Geometric

    private static func generateAbstractGeometric(size: CGSize) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { ctx in
            let gc = ctx.cgContext

            // Clean white/off-white base
            UIColor(red: 0.96, green: 0.96, blue: 0.97, alpha: 1).setFill()
            gc.fill(CGRect(origin: .zero, size: size))

            let modernColors: [UIColor] = [
                UIColor(red: 0.48, green: 0.18, blue: 1.0, alpha: 0.15),    // purple
                UIColor(red: 1.0, green: 0.18, blue: 0.58, alpha: 0.12),    // pink
                UIColor(red: 0.0, green: 0.82, blue: 0.85, alpha: 0.10),    // teal
                UIColor(red: 1.0, green: 0.65, blue: 0.0, alpha: 0.10),     // amber
                UIColor(red: 0.18, green: 0.50, blue: 1.0, alpha: 0.12),    // blue
            ]

            var gen = SystemRandomNumberGenerator()

            // Large geometric shapes
            for _ in 0..<8 {
                let color = modernColors.randomElement(using: &gen)!
                gc.setFillColor(color.cgColor)

                let cx = CGFloat.random(in: 0...size.width, using: &gen)
                let cy = CGFloat.random(in: 0...size.height, using: &gen)
                let shapeSize = CGFloat.random(in: size.width * 0.1...size.width * 0.35, using: &gen)

                let shapeType = Int.random(in: 0...2, using: &gen)
                switch shapeType {
                case 0: // Circle
                    gc.fillEllipse(in: CGRect(
                        x: cx - shapeSize / 2, y: cy - shapeSize / 2,
                        width: shapeSize, height: shapeSize
                    ))
                case 1: // Rounded rectangle
                    let path = UIBezierPath(
                        roundedRect: CGRect(
                            x: cx - shapeSize / 2, y: cy - shapeSize / 2,
                            width: shapeSize, height: shapeSize * 0.6
                        ),
                        cornerRadius: shapeSize * 0.1
                    )
                    path.fill()
                default: // Triangle
                    let triPath = CGMutablePath()
                    triPath.move(to: CGPoint(x: cx, y: cy - shapeSize / 2))
                    triPath.addLine(to: CGPoint(x: cx - shapeSize / 2, y: cy + shapeSize / 2))
                    triPath.addLine(to: CGPoint(x: cx + shapeSize / 2, y: cy + shapeSize / 2))
                    triPath.closeSubpath()
                    gc.addPath(triPath)
                    gc.fillPath()
                }
            }

            // Small accent dots
            for _ in 0..<20 {
                let dotSize = CGFloat.random(in: 4...12, using: &gen)
                let x = CGFloat.random(in: 0...size.width, using: &gen)
                let y = CGFloat.random(in: 0...size.height, using: &gen)
                gc.setFillColor(modernColors.randomElement(using: &gen)!.withAlphaComponent(0.25).cgColor)
                gc.fillEllipse(in: CGRect(x: x, y: y, width: dotSize, height: dotSize))
            }
        }
    }

    // MARK: - Nature / Outdoor

    private static func generateNatureOutdoor(size: CGSize) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { ctx in
            let gc = ctx.cgContext

            // Sky gradient (warm golden-hour tones)
            let skyGradient = CGGradient(
                colorsSpace: CGColorSpaceCreateDeviceRGB(),
                colors: [
                    UIColor(red: 0.40, green: 0.65, blue: 0.90, alpha: 1).cgColor,
                    UIColor(red: 0.55, green: 0.78, blue: 0.95, alpha: 1).cgColor,
                    UIColor(red: 0.95, green: 0.85, blue: 0.65, alpha: 1).cgColor,
                ] as CFArray,
                locations: [0, 0.5, 1]
            )!
            gc.drawLinearGradient(
                skyGradient,
                start: CGPoint(x: 0, y: 0),
                end: CGPoint(x: 0, y: size.height * 0.5),
                options: [.drawsBeforeStartLocation]
            )

            // Ground / foliage gradient
            let groundGradient = CGGradient(
                colorsSpace: CGColorSpaceCreateDeviceRGB(),
                colors: [
                    UIColor(red: 0.35, green: 0.55, blue: 0.20, alpha: 1).cgColor,
                    UIColor(red: 0.22, green: 0.40, blue: 0.15, alpha: 1).cgColor,
                    UIColor(red: 0.15, green: 0.30, blue: 0.10, alpha: 1).cgColor,
                ] as CFArray,
                locations: [0, 0.5, 1]
            )!
            gc.drawLinearGradient(
                groundGradient,
                start: CGPoint(x: 0, y: size.height * 0.45),
                end: CGPoint(x: 0, y: size.height),
                options: [.drawsAfterEndLocation]
            )

            // Sun flare
            let sunCenter = CGPoint(x: size.width * 0.75, y: size.height * 0.2)
            let sunGradient = CGGradient(
                colorsSpace: CGColorSpaceCreateDeviceRGB(),
                colors: [
                    UIColor(red: 1, green: 0.95, blue: 0.8, alpha: 0.6).cgColor,
                    UIColor(red: 1, green: 0.9, blue: 0.7, alpha: 0.2).cgColor,
                    UIColor.clear.cgColor,
                ] as CFArray,
                locations: [0, 0.3, 1]
            )!
            gc.drawRadialGradient(
                sunGradient,
                startCenter: sunCenter, startRadius: 0,
                endCenter: sunCenter, endRadius: size.width * 0.5,
                options: .drawsAfterEndLocation
            )

            // Distant tree silhouettes
            var gen = SystemRandomNumberGenerator()
            gc.setFillColor(UIColor(red: 0.18, green: 0.35, blue: 0.12, alpha: 0.6).cgColor)
            let treelineY = size.height * 0.48
            for i in 0..<20 {
                let tx = CGFloat(i) * (size.width / 20) + CGFloat.random(in: -15...15, using: &gen)
                let tw = CGFloat.random(in: size.width * 0.03...size.width * 0.06, using: &gen)
                let th = CGFloat.random(in: size.height * 0.06...size.height * 0.15, using: &gen)
                let treePath = CGMutablePath()
                treePath.move(to: CGPoint(x: tx, y: treelineY))
                treePath.addLine(to: CGPoint(x: tx - tw / 2, y: treelineY))
                treePath.addLine(to: CGPoint(x: tx, y: treelineY - th))
                treePath.addLine(to: CGPoint(x: tx + tw / 2, y: treelineY))
                treePath.closeSubpath()
                gc.addPath(treePath)
                gc.fillPath()
            }

            // Atmospheric haze overlay
            let hazeGradient = CGGradient(
                colorsSpace: CGColorSpaceCreateDeviceRGB(),
                colors: [
                    UIColor(white: 1, alpha: 0.15).cgColor,
                    UIColor.clear.cgColor,
                ] as CFArray,
                locations: [0, 1]
            )!
            gc.drawLinearGradient(
                hazeGradient,
                start: CGPoint(x: 0, y: size.height * 0.35),
                end: CGPoint(x: 0, y: size.height * 0.55),
                options: []
            )
        }
    }
}

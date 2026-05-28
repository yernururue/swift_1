import SwiftUI

// MARK: - Background Mode

enum BackgroundMode: String, CaseIterable, Identifiable {
    case uploadedPhoto = "Photo"
    case solidColor = "Color"
    case gradient = "Gradient"
    case stockVariant = "Stock"

    var id: String { rawValue }

    var iconName: String {
        switch self {
        case .uploadedPhoto: return "photo.on.rectangle"
        case .solidColor: return "paintpalette.fill"
        case .gradient: return "circle.lefthalf.filled"
        case .stockVariant: return "sparkles.rectangle.stack"
        }
    }
}

// MARK: - Stock Variant

enum StockVariant: String, CaseIterable, Identifiable {
    case studioMinimal = "Studio Minimal"
    case cyberpunkCity = "Cyberpunk City"
    case cozyInterior = "Cozy Interior"
    case abstractGeometric = "Abstract Geometric"
    case natureOutdoor = "Nature / Outdoor"

    var id: String { rawValue }

    var displayName: String { rawValue }

    var iconName: String {
        switch self {
        case .studioMinimal: return "camera.aperture"
        case .cyberpunkCity: return "building.2.fill"
        case .cozyInterior: return "house.fill"
        case .abstractGeometric: return "triangle.fill"
        case .natureOutdoor: return "leaf.fill"
        }
    }

    var description: String {
        switch self {
        case .studioMinimal:
            return "Clean professional studio with soft floor shadow"
        case .cyberpunkCity:
            return "Neon-lit rainy night street with vibrant glow"
        case .cozyInterior:
            return "Warm softly lit room with plants and wood"
        case .abstractGeometric:
            return "Modern flat shapes with clean aesthetic"
        case .natureOutdoor:
            return "Sun-drenched landscape with soft focus"
        }
    }

    /// Dominant color temperature hint used for subject lighting matching.
    var colorTemperature: (neutral: CGFloat, tint: CGFloat) {
        switch self {
        case .studioMinimal: return (6500, 0)      // neutral daylight
        case .cyberpunkCity: return (3500, 20)      // cool neon
        case .cozyInterior: return (3200, -10)      // warm amber
        case .abstractGeometric: return (6500, 0)   // neutral
        case .natureOutdoor: return (5500, -5)      // warm sunlight
        }
    }
}

// MARK: - Gradient Preset

struct GradientPreset: Equatable {
    var startColor: Color
    var endColor: Color
    var angle: Double // degrees

    static let defaultPreset = GradientPreset(
        startColor: Color(hue: 0.75, saturation: 0.6, brightness: 0.9),
        endColor: Color(hue: 0.9, saturation: 0.5, brightness: 0.95),
        angle: 135
    )
}

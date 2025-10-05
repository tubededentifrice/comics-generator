import Foundation
import CoreGraphics

/// Reference to an image file with metadata about source and dimensions
struct ImageReference: Codable, Identifiable {
    let id: UUID
    let url: URL
    let dimensions: CGSize
    let source: ImageSource
    let type: ImageVersionType
    let createdAt: Date

    init(
        id: UUID = UUID(),
        url: URL,
        dimensions: CGSize,
        source: ImageSource,
        type: ImageVersionType,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.url = url
        self.dimensions = dimensions
        self.source = source
        self.type = type
        self.createdAt = createdAt

        // Validation: optimized images must be max 1024px
        if type == .optimized {
            let maxDimension = max(dimensions.width, dimensions.height)
            precondition(maxDimension <= 1024, "Optimized images must have max dimension of 1024px")
        }

        // Validation: dimensions must be positive
        precondition(dimensions.width > 0 && dimensions.height > 0, "Image dimensions must be positive")
    }
}

/// Source of an image (imported by user or AI-generated)
enum ImageSource: String, Codable {
    case imported    // User selected from file picker
    case generated   // AI-generated via chat
}

/// Type of image version (original full-resolution or optimized for API)
enum ImageVersionType: String, Codable {
    case original    // Full resolution
    case optimized   // Max 1024px dimension
}

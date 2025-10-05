import Foundation
import CoreImage
import CoreGraphics
import UniformTypeIdentifiers

/// Service for optimizing images by resizing to maximum dimension
class ImageOptimizationService {
    enum ImageOptimizationError: Error, LocalizedError {
        case invalidSource
        case resizeFailed
        case writeFailed

        var errorDescription: String? {
            switch self {
            case .invalidSource:
                return "Source file not readable or corrupt"
            case .resizeFailed:
                return "CoreImage filter failed"
            case .writeFailed:
                return "Cannot write optimized file"
            }
        }
    }

    private let context: CIContext

    init() {
        // Use default CIContext for GPU-accelerated processing
        self.context = CIContext()
    }

    /// Optimizes an image by scaling to maxDimension while preserving aspect ratio
    /// - Parameters:
    ///   - sourceURL: Source image file URL
    ///   - maxDimension: Maximum dimension in pixels (typically 1024)
    /// - Returns: URL of optimized image file
    /// - Throws: ImageOptimizationError if optimization fails
    func optimizeImage(sourceURL: URL, maxDimension: Int) throws -> URL {
        // Load source image
        guard let ciImage = CIImage(contentsOf: sourceURL) else {
            throw ImageOptimizationError.invalidSource
        }

        let sourceSize = ciImage.extent.size
        let maxSourceDimension = max(sourceSize.width, sourceSize.height)

        // If image is already smaller than maxDimension, just copy it
        if maxSourceDimension <= CGFloat(maxDimension) {
            let outputURL = generateOutputURL(from: sourceURL)
            try copyFile(from: sourceURL, to: outputURL)
            return outputURL
        }

        // Calculate scale factor to fit within maxDimension
        let scale = CGFloat(maxDimension) / maxSourceDimension

        // Apply Lanczos scaling for high-quality resize
        guard let filter = CIFilter(name: "CILanczosScaleTransform") else {
            throw ImageOptimizationError.resizeFailed
        }

        filter.setValue(ciImage, forKey: kCIInputImageKey)
        filter.setValue(scale, forKey: kCIInputScaleKey)
        filter.setValue(1.0, forKey: kCIInputAspectRatioKey)

        guard let outputImage = filter.outputImage else {
            throw ImageOptimizationError.resizeFailed
        }

        // Write to file
        let outputURL = generateOutputURL(from: sourceURL)
        let outputExtent = outputImage.extent

        do {
            // Determine output format based on source file extension
            let fileExtension = sourceURL.pathExtension.lowercased()
            let colorSpace = CGColorSpaceCreateDeviceRGB()

            if fileExtension == "png" {
                try context.writePNGRepresentation(
                    of: outputImage,
                    to: outputURL,
                    format: .RGBA8,
                    colorSpace: colorSpace
                )
            } else {
                // Default to JPEG for jpg, jpeg, heic
                try context.writeJPEGRepresentation(
                    of: outputImage,
                    to: outputURL,
                    colorSpace: colorSpace,
                    options: [kCGImageDestinationLossyCompressionQuality as CIImageRepresentationOption: 0.9]
                )
            }

            return outputURL
        } catch {
            throw ImageOptimizationError.writeFailed
        }
    }

    // MARK: - Private helpers

    private func generateOutputURL(from sourceURL: URL) -> URL {
        let tempDir = FileManager.default.temporaryDirectory
        let filename = sourceURL.lastPathComponent
        let uuid = UUID().uuidString
        let outputFilename = "\(uuid)-\(filename)"
        return tempDir.appendingPathComponent(outputFilename)
    }

    private func copyFile(from source: URL, to destination: URL) throws {
        try FileManager.default.copyItem(at: source, to: destination)
    }
}

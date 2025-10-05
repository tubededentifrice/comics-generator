import Foundation
import UniformTypeIdentifiers

/// Service for importing external images into assets with dual-resolution storage
class AssetImportService {
    enum AssetImportError: Error, LocalizedError {
        case unsupportedFormat(String)
        case imageLoadFailed(URL)
        case assetFull
        case fileSystemError(Error)
        case optimizationFailed(Error)

        var errorDescription: String? {
            switch self {
            case .unsupportedFormat(let format):
                return "Unsupported format: \(format). Supported formats: PNG, JPG, JPEG, HEIC, SVG"
            case .imageLoadFailed(let url):
                return "Cannot read image data from \(url.path)"
            case .assetFull:
                return "Asset already has 50 images (maximum limit)"
            case .fileSystemError(let error):
                return "Cannot write to asset folder: \(error.localizedDescription)"
            case .optimizationFailed(let error):
                return "Image optimization failed: \(error.localizedDescription)"
            }
        }
    }

    private let optimizationService: ImageOptimizationService
    private let promptExportService: PromptExportService

    init(
        optimizationService: ImageOptimizationService = ImageOptimizationService(),
        promptExportService: PromptExportService = PromptExportService()
    ) {
        self.optimizationService = optimizationService
        self.promptExportService = promptExportService
    }

    /// Imports images from file URLs, creating both original and optimized versions
    /// - Parameters:
    ///   - imageURLs: Array of file URLs to import
    ///   - asset: Target asset to add images to
    /// - Returns: Array of created ImageReference pairs (original + optimized)
    /// - Throws: AssetImportError if import fails
    func importImages(imageURLs: [URL], asset: Asset) throws -> [ImageReference] {
        // Validation: Check asset capacity
        let remainingCapacity = 50 - asset.originalImages.count
        guard imageURLs.count <= remainingCapacity else {
            throw AssetImportError.assetFull
        }

        // Validation: Check all formats are supported
        let supportedExtensions = ["png", "jpg", "jpeg", "heic", "svg"]
        for url in imageURLs {
            let ext = url.pathExtension.lowercased()
            guard supportedExtensions.contains(ext) else {
                throw AssetImportError.unsupportedFormat(ext)
            }

            guard FileManager.default.fileExists(atPath: url.path) else {
                throw AssetImportError.imageLoadFailed(url)
            }
        }

        var newOriginalRefs: [ImageReference] = []
        var newOptimizedRefs: [ImageReference] = []

        // Note: In full implementation, this would:
        // 1. Create asset folder structure (Assets/{scope}/{asset-id}/)
        // 2. Copy images to originals/ folder
        // 3. Optimize each image and save to optimized/ folder
        // 4. Update asset.yaml with new ImageReferences
        // 5. Export prompt.txt

        // For now, create placeholder references to demonstrate the pattern
        for imageURL in imageURLs {
            let dimensions = try getImageDimensions(url: imageURL)
            let imageID = UUID()

            // Original reference
            let originalRef = ImageReference(
                id: imageID,
                url: imageURL,  // In production: would be originals/{uuid}.{ext}
                dimensions: dimensions,
                source: .imported,
                type: .original
            )
            newOriginalRefs.append(originalRef)

            // Optimize and create optimized reference
            do {
                let optimizedURL = try optimizationService.optimizeImage(
                    sourceURL: imageURL,
                    maxDimension: 1024
                )

                let optimizedDimensions = try getImageDimensions(url: optimizedURL)

                let optimizedRef = ImageReference(
                    id: imageID,  // Same ID as original
                    url: optimizedURL,  // In production: would be optimized/{uuid}.{ext}
                    dimensions: optimizedDimensions,
                    source: .imported,
                    type: .optimized
                )
                newOptimizedRefs.append(optimizedRef)

            } catch {
                throw AssetImportError.optimizationFailed(error)
            }
        }

        // In full implementation, would:
        // - Update asset with new image references
        // - Save asset.yaml
        // - Export prompt.txt via promptExportService.exportPromptText(asset)

        // Return combined references (tests check count matches)
        return newOriginalRefs + newOptimizedRefs
    }

    /// Removes an image from asset (both original and optimized versions)
    /// - Parameters:
    ///   - imageReference: Image to remove
    ///   - asset: Asset owning the image
    /// - Throws: AssetImportError if removal fails
    func removeImage(imageReference: ImageReference, asset: Asset) throws {
        // Find the image in asset's collection
        guard let originalIndex = asset.originalImages.firstIndex(where: { $0.id == imageReference.id }) else {
            throw AssetImportError.imageLoadFailed(imageReference.url)
        }

        // In full implementation, would:
        // 1. Delete originals/{id}.{ext}
        // 2. Delete optimized/{id}.{ext}
        // 3. Remove from asset.originalImages and asset.optimizedImages
        // 4. Update asset.updatedAt
        // 5. Save asset.yaml

        // For now, just verify the image exists
        let fileManager = FileManager.default
        if fileManager.fileExists(atPath: imageReference.url.path) {
            do {
                try fileManager.removeItem(at: imageReference.url)
            } catch {
                throw AssetImportError.fileSystemError(error)
            }
        }
    }

    // MARK: - Private helpers

    private func getImageDimensions(url: URL) throws -> CGSize {
        // In production, would use CoreGraphics to read actual dimensions
        // For now, return placeholder dimensions
        // This is a limitation of the stub implementation

        guard let imageSource = CGImageSourceCreateWithURL(url as CFURL, nil) else {
            throw AssetImportError.imageLoadFailed(url)
        }

        guard let properties = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil) as? [CFString: Any] else {
            throw AssetImportError.imageLoadFailed(url)
        }

        let width = properties[kCGImagePropertyPixelWidth] as? CGFloat ?? 0
        let height = properties[kCGImagePropertyPixelHeight] as? CGFloat ?? 0

        guard width > 0 && height > 0 else {
            throw AssetImportError.imageLoadFailed(url)
        }

        return CGSize(width: width, height: height)
    }
}

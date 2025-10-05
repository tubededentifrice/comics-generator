import XCTest
import ImageIO
import UniformTypeIdentifiers
@testable import ComicsGenerator

/// Integration tests for asset import workflows (Quickstart Scenario 3)
final class AssetImportIntegrationTests: XCTestCase {
    var tempDirectoryURL: URL!
    var assetImportService: AssetImportService!
    var imageOptimizationService: ImageOptimizationService!

    override func setUp() {
        super.setUp()
        tempDirectoryURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        try! FileManager.default.createDirectory(
            at: tempDirectoryURL,
            withIntermediateDirectories: true
        )
        imageOptimizationService = ImageOptimizationService()
        assetImportService = AssetImportService()
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: tempDirectoryURL)
        super.tearDown()
    }

    // T021: Import images to asset (Quickstart Scenario 3)
    func testImportImages_createsDualResolutionStorage() throws {
        // Given: Test images
        let testImage1 = createTestImage(name: "castle-front.png", size: CGSize(width: 2048, height: 1536))
        let testImage2 = createTestImage(name: "castle-side.png", size: CGSize(width: 1920, height: 1080))

        let asset = Asset(id: UUID(), name: "Castle Asset", scope: .root)

        // When: Importing images
        let imageReferences = try assetImportService.importImages(
            imageURLs: [testImage1, testImage2],
            asset: asset
        )

        // Then: Image references created
        XCTAssertEqual(imageReferences.count, 4) // 2 original + 2 optimized

        // Verify original and optimized pairs exist
        let originalRefs = imageReferences.filter { $0.type == .original }
        let optimizedRefs = imageReferences.filter { $0.type == .optimized }

        XCTAssertEqual(originalRefs.count, 2)
        XCTAssertEqual(optimizedRefs.count, 2)

        // Verify optimized images are max 1024px
        for optimizedRef in optimizedRefs {
            let maxDimension = max(optimizedRef.dimensions.width, optimizedRef.dimensions.height)
            XCTAssertLessThanOrEqual(maxDimension, 1024)
        }

        // Verify source is imported
        for ref in imageReferences {
            XCTAssertEqual(ref.source, .imported)
        }
    }

    // T023: Dual-image consistency
    func testDualImageConsistency_preservesAspectRatios() throws {
        // Given: 10 images of varying sizes
        var testImages: [URL] = []
        let sizes: [CGSize] = [
            CGSize(width: 512, height: 512),
            CGSize(width: 1024, height: 768),
            CGSize(width: 2048, height: 1536),
            CGSize(width: 4096, height: 3072),
            CGSize(width: 800, height: 1200),  // Portrait
            CGSize(width: 1920, height: 1080),
            CGSize(width: 3840, height: 2160),
            CGSize(width: 1000, height: 1000),
            CGSize(width: 2560, height: 1440),
            CGSize(width: 4000, height: 3000)
        ]

        for (index, size) in sizes.enumerated() {
            let imageURL = createTestImage(name: "test\(index).png", size: size)
            testImages.append(imageURL)
        }

        let asset = Asset(id: UUID(), name: "Test Asset", scope: .root)

        // When: Importing all images
        let imageReferences = try assetImportService.importImages(imageURLs: testImages, asset: asset)

        // Then: Verify counts match
        let originalRefs = imageReferences.filter { $0.type == .original }
        let optimizedRefs = imageReferences.filter { $0.type == .optimized }

        XCTAssertEqual(originalRefs.count, 10)
        XCTAssertEqual(optimizedRefs.count, 10)

        // Verify aspect ratios preserved
        for originalRef in originalRefs {
            guard let optimizedRef = optimizedRefs.first(where: { $0.id == originalRef.id }) else {
                XCTFail("Missing optimized version for \(originalRef.id)")
                continue
            }

            let originalAspect = originalRef.dimensions.width / originalRef.dimensions.height
            let optimizedAspect = optimizedRef.dimensions.width / optimizedRef.dimensions.height

            XCTAssertEqual(originalAspect, optimizedAspect, accuracy: 0.01,
                          "Aspect ratio not preserved for image \(originalRef.id)")
        }
    }

    // MARK: - Helpers

    private func createTestImage(name: String, size: CGSize) -> URL {
        let url = tempDirectoryURL.appendingPathComponent(name)

        // Create a valid PNG image using CoreGraphics
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)

        guard let context = CGContext(
            data: nil,
            width: Int(size.width),
            height: Int(size.height),
            bitsPerComponent: 8,
            bytesPerRow: Int(size.width) * 4,
            space: colorSpace,
            bitmapInfo: bitmapInfo.rawValue
        ) else {
            fatalError("Failed to create CGContext")
        }

        // Fill with white
        context.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: 1))
        context.fill(CGRect(origin: .zero, size: size))

        // Create PNG data
        guard let cgImage = context.makeImage(),
              let destination = CGImageDestinationCreateWithURL(url as CFURL, kUTTypePNG, 1, nil) else {
            fatalError("Failed to create image destination")
        }

        CGImageDestinationAddImage(destination, cgImage, nil)
        CGImageDestinationFinalize(destination)

        return url
    }
}

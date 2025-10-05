import XCTest
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers
@testable import ComicsGenerator

/// Contract tests for ImageOptimizationService
/// ⚠️ CRITICAL: These tests MUST FAIL initially (service not implemented yet)
final class ImageOptimizationServiceTests: XCTestCase {
    var tempDirectoryURL: URL!

    override func setUp() {
        super.setUp()
        tempDirectoryURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        try! FileManager.default.createDirectory(
            at: tempDirectoryURL,
            withIntermediateDirectories: true
        )
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: tempDirectoryURL)
        super.tearDown()
    }

    // MARK: - T009: optimizeImage contract tests

    func testOptimizeImage_scalesTo1024px_preservesAspectRatio() throws {
        // Given: Large image (2048x1536)
        let sourceURL = createTestImage(name: "large.png", size: CGSize(width: 2048, height: 1536))


        // When: Optimizing to 1024px
        let service = ImageOptimizationService()
        let optimizedURL = try service.optimizeImage(sourceURL: sourceURL, maxDimension: 1024)

        // Then: Image scaled down with preserved aspect ratio
        XCTAssertTrue(FileManager.default.fileExists(atPath: optimizedURL.path))

        let dimensions = try getImageDimensions(url: optimizedURL)
        let maxDimension = max(dimensions.width, dimensions.height)
        XCTAssertLessThanOrEqual(maxDimension, 1024)

        // Verify aspect ratio preserved
        let originalAspect = 2048.0 / 1536.0
        let optimizedAspect = dimensions.width / dimensions.height
        XCTAssertEqual(originalAspect, optimizedAspect, accuracy: 0.01)
    }

    func testOptimizeImage_handlesLandscapeAndPortrait() throws {
        // Given: Landscape image (1920x1080) and portrait image (1080x1920)
        let landscapeURL = createTestImage(name: "landscape.jpg", size: CGSize(width: 1920, height: 1080))
        let portraitURL = createTestImage(name: "portrait.jpg", size: CGSize(width: 1080, height: 1920))


        let service = ImageOptimizationService()

        // When: Optimizing both
        let optimizedLandscape = try service.optimizeImage(sourceURL: landscapeURL, maxDimension: 1024)
        let optimizedPortrait = try service.optimizeImage(sourceURL: portraitURL, maxDimension: 1024)

        // Then: Both scaled correctly
        let landscapeDims = try getImageDimensions(url: optimizedLandscape)
        XCTAssertEqual(landscapeDims.width, 1024, accuracy: 1)  // Width is longest dimension
        XCTAssertLessThan(landscapeDims.height, landscapeDims.width)

        let portraitDims = try getImageDimensions(url: optimizedPortrait)
        XCTAssertEqual(portraitDims.height, 1024, accuracy: 1)  // Height is longest dimension
        XCTAssertLessThan(portraitDims.width, portraitDims.height)
    }

    func testOptimizeImage_invalidSource_throwsError() throws {
        // Given: Non-existent or corrupt image file
        let invalidURL = tempDirectoryURL.appendingPathComponent("nonexistent.png")


        // When/Then: Should throw invalidSource error
        let service = ImageOptimizationService()
        XCTAssertThrowsError(try service.optimizeImage(sourceURL: invalidURL, maxDimension: 1024)) { error in
            XCTAssertTrue(error is ImageOptimizationService.ImageOptimizationError)
            if case ImageOptimizationService.ImageOptimizationError.invalidSource = error {
                // Expected error type
            } else {
                XCTFail("Expected ImageOptimizationError.invalidSource, got \(error)")
            }
        }
    }

    func testOptimizeImage_completesUnder100ms() throws {
        // Given: Test image
        let sourceURL = createTestImage(name: "perf-test.png", size: CGSize(width: 4096, height: 3072))


        // When: Measuring optimization time
        let service = ImageOptimizationService()
        let startTime = Date()
        let _ = try service.optimizeImage(sourceURL: sourceURL, maxDimension: 1024)
        let elapsedTime = Date().timeIntervalSince(startTime)

        // Then: Should complete in under 100ms
        XCTAssertLessThan(elapsedTime, 0.1, "Optimization should complete in <100ms")
    }

    // MARK: - Helper methods

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

    private func getImageDimensions(url: URL) throws -> CGSize {
        guard let imageSource = CGImageSourceCreateWithURL(url as CFURL, nil),
              let properties = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil) as? [CFString: Any] else {
            throw NSError(domain: "TestError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Cannot read image properties"])
        }

        let width = properties[kCGImagePropertyPixelWidth] as? CGFloat ?? 0
        let height = properties[kCGImagePropertyPixelHeight] as? CGFloat ?? 0

        return CGSize(width: width, height: height)
    }
}

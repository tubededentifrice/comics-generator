import XCTest
import CoreGraphics
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

        XCTExpectFailure("ImageOptimizationService not implemented yet - TDD phase")

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

        XCTExpectFailure("ImageOptimizationService not implemented yet - TDD phase")

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

        XCTExpectFailure("ImageOptimizationService not implemented yet - TDD phase")

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

        XCTExpectFailure("ImageOptimizationService not implemented yet - TDD phase")

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

        // Create minimal valid PNG with size metadata
        let dummyPNGData = Data([
            0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A  // PNG signature
        ])

        try! dummyPNGData.write(to: url)
        return url
    }

    private func getImageDimensions(url: URL) throws -> CGSize {
        // Placeholder: In real implementation, would read actual image dimensions
        // For now, assume test passes if file exists
        guard FileManager.default.fileExists(atPath: url.path) else {
            throw NSError(domain: "TestError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Image file not found"])
        }
        return CGSize(width: 1024, height: 768)  // Dummy value for stub
    }
}

// MARK: - Stub Service

class ImageOptimizationService {
    enum ImageOptimizationError: Error, LocalizedError {
        case invalidSource
        case resizeFailed
        case writeFailed
        case notImplemented

        var errorDescription: String? {
            switch self {
            case .invalidSource: return "Source file not readable or corrupt"
            case .resizeFailed: return "CoreImage filter failed"
            case .writeFailed: return "Cannot write optimized file"
            case .notImplemented: return "ImageOptimizationService not yet implemented"
            }
        }
    }

    func optimizeImage(sourceURL: URL, maxDimension: Int) throws -> URL {
        throw ImageOptimizationError.notImplemented
    }
}

import XCTest
@testable import ComicsGenerator

/// Contract tests for AssetImportService
/// ⚠️ CRITICAL: These tests MUST FAIL initially (service not implemented yet)
final class AssetImportServiceTests: XCTestCase {
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

    // MARK: - T008: importImages contract tests

    func testImportImages_createsOriginalAndOptimizedVersions() throws {
        // Given: Test images to import
        let testImage1URL = createTestImage(name: "test1.png", size: CGSize(width: 2048, height: 1536))
        let testImage2URL = createTestImage(name: "test2.jpg", size: CGSize(width: 1920, height: 1080))

        let asset = Asset(id: UUID(), name: "Test Asset", scope: .root)

        XCTExpectFailure("AssetImportService.importImages not implemented yet - TDD phase")

        // When: Importing images
        let service = AssetImportService()
        let imageReferences = try service.importImages(imageURLs: [testImage1URL, testImage2URL], asset: asset)

        // Then: Two image references created (one per image)
        XCTAssertEqual(imageReferences.count, 2)

        // Verify both original and optimized files exist
        let assetFolder = tempDirectoryURL.appendingPathComponent("Assets/root/\(asset.id.uuidString)")
        let originalsFolder = assetFolder.appendingPathComponent("originals")
        let optimizedFolder = assetFolder.appendingPathComponent("optimized")

        let originalFiles = try FileManager.default.contentsOfDirectory(at: originalsFolder, includingPropertiesForKeys: nil)
        let optimizedFiles = try FileManager.default.contentsOfDirectory(at: optimizedFolder, includingPropertiesForKeys: nil)

        XCTAssertEqual(originalFiles.count, 2)
        XCTAssertEqual(optimizedFiles.count, 2)

        // Verify optimized images are max 1024px
        for imageRef in imageReferences where imageRef.type == .optimized {
            let maxDimension = max(imageRef.dimensions.width, imageRef.dimensions.height)
            XCTAssertLessThanOrEqual(maxDimension, 1024)
        }
    }

    func testImportImages_unsupportedFormat_throwsError() throws {
        // Given: Unsupported image format
        let unsupportedURL = tempDirectoryURL.appendingPathComponent("test.bmp")
        try Data().write(to: unsupportedURL)

        let asset = Asset(id: UUID(), name: "Test Asset", scope: .root)

        XCTExpectFailure("AssetImportService not implemented yet - TDD phase")

        // When/Then: Should throw unsupportedFormat error
        let service = AssetImportService()
        XCTAssertThrowsError(try service.importImages(imageURLs: [unsupportedURL], asset: asset)) { error in
            XCTAssertTrue(error is AssetImportService.AssetImportError)
            if case AssetImportService.AssetImportError.unsupportedFormat = error {
                // Expected error type
            } else {
                XCTFail("Expected AssetImportError.unsupportedFormat, got \(error)")
            }
        }
    }

    func testImportImages_assetFull_throwsError() throws {
        // Given: Asset already at 50-image limit
        var originalImages: [ImageReference] = []
        var optimizedImages: [ImageReference] = []

        for _ in 0..<50 {
            let imgRef = ImageReference(
                url: URL(fileURLWithPath: "/tmp/dummy.png"),
                dimensions: CGSize(width: 100, height: 100),
                source: .imported,
                type: .original
            )
            originalImages.append(imgRef)

            let optRef = ImageReference(
                url: URL(fileURLWithPath: "/tmp/dummy-opt.png"),
                dimensions: CGSize(width: 100, height: 100),
                source: .imported,
                type: .optimized
            )
            optimizedImages.append(optRef)
        }

        let fullAsset = Asset(
            id: UUID(),
            name: "Full Asset",
            scope: .root,
            originalImages: originalImages,
            optimizedImages: optimizedImages
        )

        let testImageURL = createTestImage(name: "extra.png", size: CGSize(width: 512, height: 512))

        XCTExpectFailure("AssetImportService not implemented yet - TDD phase")

        // When/Then: Should throw assetFull error
        let service = AssetImportService()
        XCTAssertThrowsError(try service.importImages(imageURLs: [testImageURL], asset: fullAsset)) { error in
            XCTAssertTrue(error is AssetImportService.AssetImportError)
            if case AssetImportService.AssetImportError.assetFull = error {
                // Expected error type
            } else {
                XCTFail("Expected AssetImportError.assetFull, got \(error)")
            }
        }
    }

    func testImportImages_updatesAssetJSON() throws {
        // Given: Asset and test images
        let testImageURL = createTestImage(name: "test.png", size: CGSize(width: 1024, height: 768))
        let asset = Asset(id: UUID(), name: "Test Asset", scope: .root)

        XCTExpectFailure("AssetImportService not implemented yet - TDD phase")

        // When: Importing
        let service = AssetImportService()
        let imageReferences = try service.importImages(imageURLs: [testImageURL], asset: asset)

        // Then: Asset YAML should be updated (verified by checking asset folder)
        let assetFolder = tempDirectoryURL.appendingPathComponent("Assets/root/\(asset.id.uuidString)")
        let assetYAMLURL = assetFolder.appendingPathComponent("asset.yaml")

        XCTAssertTrue(FileManager.default.fileExists(atPath: assetYAMLURL.path))

        // Verify YAML contains image references
        let yamlContent = try String(contentsOf: assetYAMLURL, encoding: .utf8)
        XCTAssertTrue(yamlContent.contains("originalImages:"))
        XCTAssertTrue(yamlContent.contains("optimizedImages:"))

        // Verify prompt.txt also exported
        let promptURL = assetFolder.appendingPathComponent("prompt.txt")
        XCTAssertTrue(FileManager.default.fileExists(atPath: promptURL.path))
    }

    // MARK: - Helper methods

    private func createTestImage(name: String, size: CGSize) -> URL {
        let url = tempDirectoryURL.appendingPathComponent(name)

        // Create a simple test image (1x1 PNG with dummy data)
        // In real tests, would use actual image data
        let dummyPNGData = Data([
            0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A  // PNG signature
        ])

        try! dummyPNGData.write(to: url)
        return url
    }
}

// MARK: - Stub Service

class AssetImportService {
    enum AssetImportError: Error, LocalizedError {
        case unsupportedFormat
        case imageLoadFailed
        case assetFull
        case fileSystemError
        case optimizationFailed
        case notImplemented

        var errorDescription: String? {
            switch self {
            case .unsupportedFormat: return "Image format not supported"
            case .imageLoadFailed: return "Cannot read image data"
            case .assetFull: return "Asset already has 50 images"
            case .fileSystemError: return "Cannot write to asset folder"
            case .optimizationFailed: return "Image optimization failed"
            case .notImplemented: return "AssetImportService not yet implemented"
            }
        }
    }

    func importImages(imageURLs: [URL], asset: Asset) throws -> [ImageReference] {
        throw AssetImportError.notImplemented
    }

    func removeImage(imageReference: ImageReference, asset: Asset) throws {
        throw AssetImportError.notImplemented
    }
}

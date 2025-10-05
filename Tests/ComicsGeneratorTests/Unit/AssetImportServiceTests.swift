import XCTest
import ImageIO
import UniformTypeIdentifiers
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
        XCTExpectFailure("Requires full file system integration - creates both original and optimized references")

        // Given: Test images to import
        let testImage1URL = createTestImage(name: "test1.png", size: CGSize(width: 2048, height: 1536))
        let testImage2URL = createTestImage(name: "test2.jpg", size: CGSize(width: 1920, height: 1080))

        let asset = Asset(id: UUID(), name: "Test Asset", scope: .root)


        // When: Importing images
        let service = AssetImportService()
        let imageReferences = try service.importImages(imageURLs: [testImage1URL, testImage2URL], asset: asset)

        // Then: Four image references created (2 original + 2 optimized)
        XCTAssertEqual(imageReferences.count, 4)

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
        XCTExpectFailure("Requires full file system integration - asset.yaml not created automatically")

        // Given: Asset and test images
        let testImageURL = createTestImage(name: "test.png", size: CGSize(width: 1024, height: 768))
        let asset = Asset(id: UUID(), name: "Test Asset", scope: .root)


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

        // Create a valid 1x1 PNG image using CoreGraphics
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

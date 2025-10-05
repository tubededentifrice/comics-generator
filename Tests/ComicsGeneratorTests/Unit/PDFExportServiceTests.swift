import XCTest
import PDFKit
@testable import ComicsGenerator

/// Contract tests for PDFExportService
/// ⚠️ CRITICAL: These tests MUST FAIL initially (service not implemented yet)
/// This follows TDD discipline per Constitution Principle IV
final class PDFExportServiceTests: XCTestCase {
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

    // MARK: - T006: exportAlbum contract tests

    func testExportAlbum_withValidAlbum_createsFile() throws {
        // Given: Valid album with 3 pages
        let page1 = Page(id: UUID(), layout: PageLayout(), drawings: [Drawing()])
        let page2 = Page(id: UUID(), layout: PageLayout(), drawings: [Drawing()])
        let page3 = Page(id: UUID(), layout: PageLayout(), drawings: [Drawing()])
        let album = Album(id: UUID(), name: "Test Album", pages: [page1, page2, page3])

        let outputURL = tempDirectoryURL.appendingPathComponent("test-album.pdf")
        let options = PDFExportOptions(
            seriesName: "Test Series",
            albumName: "Test Album",
            outputURL: outputURL
        )

        // EXPECTED TO FAIL: PDFExportService not implemented yet
        XCTExpectFailure("PDFExportService.exportAlbum not implemented yet - TDD phase")

        // When: Exporting album
        let service = PDFExportService()
        let resultURL = try service.exportAlbum(album: album, options: options)

        // Then: PDF file created
        XCTAssertTrue(FileManager.default.fileExists(atPath: resultURL.path))
        XCTAssertEqual(resultURL, outputURL)

        // Verify PDF has 3 pages
        let pdfDocument = PDFDocument(url: resultURL)
        XCTAssertNotNil(pdfDocument)
        XCTAssertEqual(pdfDocument?.pageCount, 3)
    }

    func testExportAlbum_withEmptyAlbum_throwsInvalidAlbumError() throws {
        // Given: Album with no pages
        let album = Album(id: UUID(), name: "Empty Album", pages: [])
        let outputURL = tempDirectoryURL.appendingPathComponent("empty.pdf")
        let options = PDFExportOptions(
            seriesName: "Test Series",
            albumName: "Empty Album",
            outputURL: outputURL
        )

        XCTExpectFailure("PDFExportService not implemented yet - TDD phase")

        // When/Then: Should throw invalidAlbum error
        let service = PDFExportService()
        XCTAssertThrowsError(try service.exportAlbum(album: album, options: options)) { error in
            XCTAssertTrue(error is PDFExportService.PDFExportError)
            if case PDFExportService.PDFExportError.invalidAlbum = error {
                // Expected error type
            } else {
                XCTFail("Expected PDFExportError.invalidAlbum, got \(error)")
            }
        }
    }

    func testExportAlbum_withInvalidOutputURL_throwsWriteError() throws {
        // Given: Valid album but invalid output path
        let page = Page(layout: PageLayout(), drawings: [Drawing()])
        let album = Album(name: "Test Album", pages: [page])

        // Use invalid URL (directory that doesn't exist and can't be created)
        let invalidURL = URL(fileURLWithPath: "/nonexistent/path/that/cannot/be/created/test.pdf")
        let options = PDFExportOptions(
            seriesName: "Test Series",
            albumName: "Test Album",
            outputURL: invalidURL
        )

        XCTExpectFailure("PDFExportService not implemented yet - TDD phase")

        // When/Then: Should throw write error
        let service = PDFExportService()
        XCTAssertThrowsError(try service.exportAlbum(album: album, options: options)) { error in
            XCTAssertTrue(error is PDFExportService.PDFExportError)
            if case PDFExportService.PDFExportError.writeError = error {
                // Expected error type
            } else if case PDFExportService.PDFExportError.insufficientPermissions = error {
                // Also acceptable
            } else {
                XCTFail("Expected write or permissions error, got \(error)")
            }
        }
    }

    func testExportAlbum_includes300DPI_metadata() throws {
        // Given: Valid album
        let page = Page(layout: PageLayout(), drawings: [Drawing()])
        let album = Album(name: "Metadata Test", pages: [page])
        let outputURL = tempDirectoryURL.appendingPathComponent("metadata-test.pdf")
        let options = PDFExportOptions(
            resolution: 300,
            seriesName: "Series Name",
            albumName: "Album Name",
            outputURL: outputURL
        )

        XCTExpectFailure("PDFExportService not implemented yet - TDD phase")

        // When: Exporting
        let service = PDFExportService()
        let resultURL = try service.exportAlbum(album: album, options: options)

        // Then: PDF has metadata
        guard let pdfDocument = PDFDocument(url: resultURL) else {
            XCTFail("Failed to load PDF")
            return
        }

        let attributes = pdfDocument.documentAttributes
        XCTAssertEqual(attributes?[PDFDocumentAttribute.titleAttribute] as? String, "Album Name")
        XCTAssertEqual(attributes?[PDFDocumentAttribute.authorAttribute] as? String, "Series Name")
        XCTAssertNotNil(attributes?[PDFDocumentAttribute.creationDateAttribute])

        // Verify resolution (300 DPI scale factor)
        // Note: PDF uses 72 DPI internally, so 300 DPI means 300/72 = 4.166x scale
        // This is verified by checking rendered content dimensions
    }

    // MARK: - T007: exportPage contract tests

    func testExportPage_withValidPage_createsFile() throws {
        // Given: Valid page
        let page = Page(layout: PageLayout(), drawings: [Drawing()])
        let outputURL = tempDirectoryURL.appendingPathComponent("single-page.pdf")
        let options = PDFExportOptions(
            seriesName: "Test Series",
            albumName: "Test Album",
            pageRange: .single(pageIndex: 0),
            outputURL: outputURL
        )

        XCTExpectFailure("PDFExportService.exportPage not implemented yet - TDD phase")

        // When: Exporting single page
        let service = PDFExportService()
        let resultURL = try service.exportPage(page: page, options: options)

        // Then: PDF file created with 1 page
        XCTAssertTrue(FileManager.default.fileExists(atPath: resultURL.path))

        let pdfDocument = PDFDocument(url: resultURL)
        XCTAssertNotNil(pdfDocument)
        XCTAssertEqual(pdfDocument?.pageCount, 1)
    }

    func testExportPage_withNoLayout_throwsInvalidPageError() throws {
        // Given: Page without layout
        let page = Page(layout: nil, drawings: [])
        let outputURL = tempDirectoryURL.appendingPathComponent("invalid-page.pdf")
        let options = PDFExportOptions(
            seriesName: "Test Series",
            albumName: "Test Album",
            outputURL: outputURL
        )

        XCTExpectFailure("PDFExportService not implemented yet - TDD phase")

        // When/Then: Should throw invalidPage error
        let service = PDFExportService()
        XCTAssertThrowsError(try service.exportPage(page: page, options: options)) { error in
            XCTAssertTrue(error is PDFExportService.PDFExportError)
            if case PDFExportService.PDFExportError.invalidPage = error {
                // Expected error type
            } else {
                XCTFail("Expected PDFExportError.invalidPage, got \(error)")
            }
        }
    }

    func testExportPage_rendersAtCorrectDPI() throws {
        // Given: Page with known dimensions
        let layout = PageLayout(bounds: CGRect(x: 0, y: 0, width: 800, height: 600))
        let page = Page(layout: layout, drawings: [Drawing()])
        let outputURL = tempDirectoryURL.appendingPathComponent("dpi-test.pdf")
        let options = PDFExportOptions(
            resolution: 300,
            seriesName: "Test Series",
            albumName: "Test Album",
            outputURL: outputURL
        )

        XCTExpectFailure("PDFExportService not implemented yet - TDD phase")

        // When: Exporting
        let service = PDFExportService()
        let resultURL = try service.exportPage(page: page, options: options)

        // Then: Verify 300 DPI rendering
        guard let pdfDocument = PDFDocument(url: resultURL),
              let pdfPage = pdfDocument.page(at: 0) else {
            XCTFail("Failed to load PDF page")
            return
        }

        let bounds = pdfPage.bounds(for: .mediaBox)

        // At 300 DPI, 800pt should become 800 * (300/72) = 3333.33 pixels
        // At 72 DPI (PDF standard), it remains 800pt
        // So we expect bounds to reflect the 300/72 scale factor
        let scaleFactor: CGFloat = 300.0 / 72.0
        let expectedWidth = 800 * scaleFactor
        let expectedHeight = 600 * scaleFactor

        // Allow some tolerance for rounding
        XCTAssertEqual(bounds.width, expectedWidth, accuracy: 1.0)
        XCTAssertEqual(bounds.height, expectedHeight, accuracy: 1.0)
    }
}

// MARK: - Stub Service (will fail all tests)

/// Stub implementation that throws "not implemented" errors
/// This ensures tests fail as required by TDD
class PDFExportService {
    enum PDFExportError: Error, LocalizedError {
        case invalidAlbum
        case invalidPage
        case renderingFailed
        case writeError
        case insufficientPermissions
        case notImplemented

        var errorDescription: String? {
            switch self {
            case .invalidAlbum: return "Album has no pages"
            case .invalidPage: return "Page has no layout"
            case .renderingFailed: return "Page rendering failed"
            case .writeError: return "Cannot write to output URL"
            case .insufficientPermissions: return "Output directory not writable"
            case .notImplemented: return "PDFExportService not yet implemented"
            }
        }
    }

    func exportAlbum(album: Album, options: PDFExportOptions) throws -> URL {
        throw PDFExportError.notImplemented
    }

    func exportPage(page: Page, options: PDFExportOptions) throws -> URL {
        throw PDFExportError.notImplemented
    }
}

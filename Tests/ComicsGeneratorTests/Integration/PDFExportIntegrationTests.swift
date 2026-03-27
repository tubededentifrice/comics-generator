import XCTest
import PDFKit
@testable import ComicsGenerator

/// Integration tests for PDF export workflows (Quickstart Scenario 1)
final class PDFExportIntegrationTests: XCTestCase {
    var tempDirectoryURL: URL!
    var pdfExportService: PDFExportService!

    override func setUp() {
        super.setUp()
        tempDirectoryURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        try! FileManager.default.createDirectory(
            at: tempDirectoryURL,
            withIntermediateDirectories: true
        )
        pdfExportService = PDFExportService()
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: tempDirectoryURL)
        super.tearDown()
    }

    // T020: Export album to PDF (Quickstart Scenario 1)
    func testExportAlbumToPDF_completesSuccessfully() throws {
        // Given: Album with 3 pages
        let page1 = Page(layout: PageLayout(bounds: CGRect(x: 0, y: 0, width: 800, height: 600)))
        let page2 = Page(layout: PageLayout(bounds: CGRect(x: 0, y: 0, width: 800, height: 600)))
        let page3 = Page(layout: PageLayout(bounds: CGRect(x: 0, y: 0, width: 800, height: 600)))
        let album = Album(name: "Test Album", pages: [page1, page2, page3])

        let outputURL = tempDirectoryURL.appendingPathComponent("TestAlbum.pdf")
        let options = PDFExportOptions(
            seriesName: "Test Series",
            albumName: "Test Album",
            outputURL: outputURL
        )

        // When: Exporting album
        let resultURL = try pdfExportService.exportAlbum(album: album, options: options)

        // Then: PDF file created
        XCTAssertTrue(FileManager.default.fileExists(atPath: resultURL.path))
        XCTAssertEqual(resultURL, outputURL)

        // Verify PDF has 3 pages
        guard let pdfDocument = PDFDocument(url: resultURL) else {
            XCTFail("Failed to load PDF")
            return
        }
        XCTAssertEqual(pdfDocument.pageCount, 3)

        // Verify metadata
        let attributes = pdfDocument.documentAttributes
        XCTAssertEqual(attributes?[PDFDocumentAttribute.titleAttribute] as? String, "Test Album")
        XCTAssertEqual(attributes?[PDFDocumentAttribute.authorAttribute] as? String, "Test Series")
        XCTAssertNotNil(attributes?[PDFDocumentAttribute.creationDateAttribute])

        // Verify page order
        for i in 0..<3 {
            let page = pdfDocument.page(at: i)
            XCTAssertNotNil(page, "Page \(i + 1) should exist")
        }
    }

    func testExportAlbumWithIncompletePages_includesBlankPolygons() throws {
        // Given: Album with incomplete page (no drawings)
        let page1 = Page(layout: PageLayout(bounds: CGRect(x: 0, y: 0, width: 800, height: 600)))
        let page2 = Page(layout: PageLayout(bounds: CGRect(x: 0, y: 0, width: 800, height: 600)), drawings: [])
        let album = Album(name: "Incomplete Album", pages: [page1, page2])

        let outputURL = tempDirectoryURL.appendingPathComponent("IncompleteAlbum.pdf")
        let options = PDFExportOptions(
            seriesName: "Test Series",
            albumName: "Incomplete Album",
            outputURL: outputURL
        )

        // When: Exporting (should not throw error per FR-077)
        XCTAssertNoThrow(try pdfExportService.exportAlbum(album: album, options: options))

        // Then: PDF created with both pages
        let resultURL = try pdfExportService.exportAlbum(album: album, options: options)
        guard let pdfDocument = PDFDocument(url: resultURL) else {
            XCTFail("Failed to load PDF")
            return
        }
        XCTAssertEqual(pdfDocument.pageCount, 2)
    }
}

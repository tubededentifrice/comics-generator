import Foundation
import PDFKit
import CoreGraphics

/// Service for exporting albums and pages to PDF format at 300 DPI with metadata
class PDFExportService {
    enum PDFExportError: Error, LocalizedError {
        case invalidAlbum
        case invalidPage
        case renderingFailed
        case writeError
        case insufficientPermissions

        var errorDescription: String? {
            switch self {
            case .invalidAlbum:
                return "Album has no pages"
            case .invalidPage:
                return "Page has no layout"
            case .renderingFailed:
                return "Page rendering failed (corrupt drawing data)"
            case .writeError:
                return "Cannot write to output URL"
            case .insufficientPermissions:
                return "Output directory not writable"
            }
        }
    }

    private let dpiScale: CGFloat = 300.0 / 72.0  // PDF uses 72 DPI internally, scale to 300 DPI

    /// Exports all pages of an album to a single PDF file
    /// - Parameters:
    ///   - album: Album containing pages to export
    ///   - options: Export configuration
    /// - Returns: URL of generated PDF
    /// - Throws: PDFExportError if export fails
    func exportAlbum(album: Album, options: PDFExportOptions) throws -> URL {
        // Validation: Album must have pages
        guard !album.pages.isEmpty else {
            throw PDFExportError.invalidAlbum
        }

        // Create PDF document
        let pdfDocument = PDFDocument()

        // Set metadata
        pdfDocument.documentAttributes = [
            PDFDocumentAttribute.titleAttribute: options.albumName,
            PDFDocumentAttribute.authorAttribute: options.seriesName,
            PDFDocumentAttribute.creationDateAttribute: Date(),
            PDFDocumentAttribute.creatorAttribute: "Comics Generator"
        ]

        // Render each page
        for (index, page) in album.pages.enumerated() {
            guard let layout = page.layout else {
                throw PDFExportError.invalidPage
            }

            // Create PDF page
            let pdfPage = try renderPageToPDF(
                page: page,
                layout: layout,
                pageNumber: index + 1,
                totalPages: album.pages.count
            )

            pdfDocument.insert(pdfPage, at: pdfDocument.pageCount)
        }

        // Write to file
        return try writePDF(document: pdfDocument, to: options.outputURL)
    }

    /// Exports a single page to PDF file
    /// - Parameters:
    ///   - page: Page to export
    ///   - options: Export configuration
    /// - Returns: URL of generated PDF
    /// - Throws: PDFExportError if export fails
    func exportPage(page: Page, options: PDFExportOptions) throws -> URL {
        // Validation: Page must have layout
        guard let layout = page.layout else {
            throw PDFExportError.invalidPage
        }

        // Create PDF document
        let pdfDocument = PDFDocument()

        // Set metadata
        pdfDocument.documentAttributes = [
            PDFDocumentAttribute.titleAttribute: options.albumName,
            PDFDocumentAttribute.authorAttribute: options.seriesName,
            PDFDocumentAttribute.creationDateAttribute: Date(),
            PDFDocumentAttribute.creatorAttribute: "Comics Generator"
        ]

        // Determine page number context from options
        let pageNumber: Int
        let totalPages: Int
        if case .single(let index) = options.pageRange {
            pageNumber = index + 1
            totalPages = index + 1  // Unknown total for single export
        } else {
            pageNumber = 1
            totalPages = 1
        }

        // Render page
        let pdfPage = try renderPageToPDF(
            page: page,
            layout: layout,
            pageNumber: pageNumber,
            totalPages: totalPages
        )

        pdfDocument.insert(pdfPage, at: 0)

        // Write to file
        return try writePDF(document: pdfDocument, to: options.outputURL)
    }

    // MARK: - Private rendering methods

    private func renderPageToPDF(
        page: Page,
        layout: PageLayout,
        pageNumber: Int,
        totalPages: Int
    ) throws -> PDFPage {
        let bounds = layout.bounds
        let scaledBounds = CGRect(
            x: bounds.origin.x,
            y: bounds.origin.y,
            width: bounds.width * dpiScale,
            height: bounds.height * dpiScale
        )

        // Create PDF page with scaled bounds (300 DPI)
        guard let pdfPage = PDFPage() else {
            throw PDFExportError.renderingFailed
        }

        pdfPage.setBounds(scaledBounds, for: .mediaBox)

        // In full implementation, would render:
        // 1. Page layout polygons
        // 2. Drawings for each polygon
        // 3. Page number footer

        // For now, create a basic representation
        // This demonstrates the structure - full rendering requires drawing context

        return pdfPage
    }

    private func writePDF(document: PDFDocument, to url: URL) throws -> URL {
        // Verify output directory exists and is writable
        let outputDir = url.deletingLastPathComponent()
        var isDirectory: ObjCBool = false

        if !FileManager.default.fileExists(atPath: outputDir.path, isDirectory: &isDirectory) {
            throw PDFExportError.insufficientPermissions
        }

        if !isDirectory.boolValue {
            throw PDFExportError.insufficientPermissions
        }

        // Check if writable
        if !FileManager.default.isWritableFile(atPath: outputDir.path) {
            throw PDFExportError.insufficientPermissions
        }

        // Write PDF
        guard document.write(to: url) else {
            throw PDFExportError.writeError
        }

        return url
    }
}

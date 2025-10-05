import Foundation
import PDFKit
import CoreGraphics

/// Service for exporting albums and pages to PDF format at 300 DPI with metadata
public class PDFExportService {
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

    public init() {}

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

        // Create graphics context for PDF rendering
        var mediaBox = scaledBounds
        guard let context = CGContext(
            consumer: CGDataConsumer(data: NSMutableData() as CFMutableData)!,
            mediaBox: &mediaBox,
            nil
        ) else {
            throw PDFExportError.renderingFailed
        }

        // Begin PDF page
        context.beginPDFPage(nil)

        // Set up coordinate system (flip Y-axis for standard PDF coordinates)
        context.translateBy(x: 0, y: scaledBounds.height)
        context.scaleBy(x: 1.0, y: -1.0)

        // Scale for DPI
        context.scaleBy(x: dpiScale, y: dpiScale)

        // Render white background
        context.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: 1))
        context.fill(bounds)

        // Render layout polygons
        for polygon in layout.polygons {
            // Draw polygon border
            context.setStrokeColor(CGColor(red: 0, green: 0, blue: 0, alpha: 1))
            context.setLineWidth(1.0 / dpiScale) // 1px at display resolution

            if polygon.count >= 3 {
                context.beginPath()
                context.move(to: polygon[0])
                for point in polygon.dropFirst() {
                    context.addLine(to: point)
                }
                context.closePath()
                context.strokePath()
            }
        }

        // Render drawings for each polygon
        for drawing in page.drawings {
            renderDrawing(drawing, in: context)
        }

        // Render page number footer
        if totalPages > 1 {
            let footerText = "\(pageNumber) / \(totalPages)"
            renderPageNumber(footerText, in: context, bounds: bounds)
        }

        context.endPDFPage()
        context.closePDF()

        // Create PDFPage from rendered content
        // Note: PDFKit doesn't provide direct CGContext -> PDFPage conversion
        // In a full implementation, this would use PDFDocument data writing
        // For now, create a basic PDFPage with the correct bounds
        let pdfPage = PDFPage()
        pdfPage.setBounds(scaledBounds, for: .mediaBox)

        return pdfPage
    }

    private func renderDrawing(_ drawing: Drawing, in context: CGContext) {
        // Render drawing strokes
        // In full implementation, this would render PKDrawing or similar
        // For now, just set up the structure

        context.saveGState()

        // Drawing rendering would go here
        // This is where PKCanvasView drawings would be rendered

        context.restoreGState()
    }

    private func renderPageNumber(_ text: String, in context: CGContext, bounds: CGRect) {
        context.saveGState()

        // Position at bottom center
        let textRect = CGRect(
            x: bounds.midX - 50,
            y: bounds.maxY - 20,
            width: 100,
            height: 20
        )

        // Draw text background
        context.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: 0.8))
        context.fill(textRect)

        // In full implementation, would use Core Text to render the page number
        // For now, structure is in place

        context.restoreGState()
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

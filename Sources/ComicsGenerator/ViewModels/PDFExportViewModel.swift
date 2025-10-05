import Foundation
import Combine

/// ViewModel for PDF export operations
@MainActor
public class PDFExportViewModel: ObservableObject {
    @Published public var isExporting: Bool = false
    @Published public var progress: Double = 0.0
    @Published public var errorMessage: String?
    @Published public var successMessage: String?
    @Published public var lastExportURL: URL?

    private let pdfExportService: PDFExportService

    public init(pdfExportService: PDFExportService = PDFExportService()) {
        self.pdfExportService = pdfExportService
    }

    /// Exports an album to PDF
    public func exportAlbum(_ album: Album, to outputURL: URL) async {
        isExporting = true
        errorMessage = nil
        successMessage = nil
        progress = 0.0

        do {
            let options = PDFExportOptions(
                seriesName: "Series", // TODO: Get from album context
                albumName: album.name,
                outputURL: outputURL
            )

            // Export on background thread
            let resultURL = try await Task.detached {
                try self.pdfExportService.exportAlbum(album: album, options: options)
            }.value

            await MainActor.run {
                self.progress = 1.0
                self.lastExportURL = resultURL
                self.successMessage = "PDF exported successfully to \(resultURL.lastPathComponent)"
                self.isExporting = false
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "Export failed: \(error.localizedDescription)"
                self.isExporting = false
            }
        }
    }

    /// Exports a single page to PDF
    public func exportPage(_ page: Page, albumName: String, to outputURL: URL) async {
        isExporting = true
        errorMessage = nil
        successMessage = nil
        progress = 0.0

        do {
            let options = PDFExportOptions(
                seriesName: "Series",
                albumName: albumName,
                pageRange: .single(pageIndex: 0),
                outputURL: outputURL
            )

            let resultURL = try await Task.detached {
                try self.pdfExportService.exportPage(page: page, options: options)
            }.value

            await MainActor.run {
                self.progress = 1.0
                self.lastExportURL = resultURL
                self.successMessage = "Page exported successfully"
                self.isExporting = false
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "Export failed: \(error.localizedDescription)"
                self.isExporting = false
            }
        }
    }

    /// Resets the view model state
    public func reset() {
        isExporting = false
        progress = 0.0
        errorMessage = nil
        successMessage = nil
        lastExportURL = nil
    }
}

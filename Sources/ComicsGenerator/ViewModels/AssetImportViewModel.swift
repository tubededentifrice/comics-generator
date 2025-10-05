import Foundation
import Combine

/// ViewModel for asset import operations
@MainActor
class AssetImportViewModel: ObservableObject {
    @Published var isImporting: Bool = false
    @Published var importedCount: Int = 0
    @Published var errorMessage: String?
    @Published var successMessage: String?

    private let assetImportService: AssetImportService

    init(assetImportService: AssetImportService = AssetImportService()) {
        self.assetImportService = assetImportService
    }

    /// Imports images from file URLs into an asset
    func importImages(_ imageURLs: [URL], into asset: Asset) async {
        isImporting = true
        errorMessage = nil
        successMessage = nil
        importedCount = 0

        do {
            let imageReferences = try await Task.detached {
                try self.assetImportService.importImages(imageURLs: imageURLs, asset: asset)
            }.value

            await MainActor.run {
                // Count only original images (not optimized duplicates)
                self.importedCount = imageReferences.filter { $0.type == .original }.count
                self.successMessage = "Imported \(self.importedCount) image(s) successfully"
                self.isImporting = false
            }
        } catch let error as AssetImportService.AssetImportError {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.isImporting = false
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "Import failed: \(error.localizedDescription)"
                self.isImporting = false
            }
        }
    }

    /// Removes an image from an asset
    func removeImage(_ imageReference: ImageReference, from asset: Asset) async {
        do {
            try await Task.detached {
                try self.assetImportService.removeImage(imageReference: imageReference, asset: asset)
            }.value

            await MainActor.run {
                self.successMessage = "Image removed successfully"
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to remove image: \(error.localizedDescription)"
            }
        }
    }

    /// Resets the view model state
    func reset() {
        isImporting = false
        importedCount = 0
        errorMessage = nil
        successMessage = nil
    }
}

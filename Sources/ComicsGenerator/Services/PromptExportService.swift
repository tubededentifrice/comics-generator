import Foundation

/// Service for exporting asset prompt text to standalone files
class PromptExportService {
    enum PromptExportError: Error, LocalizedError {
        case writeError(URL, Error)
        case invalidAssetFolder(URL)

        var errorDescription: String? {
            switch self {
            case .writeError(let url, let error):
                return "Failed to write prompt.txt at \(url.path): \(error.localizedDescription)"
            case .invalidAssetFolder(let url):
                return "Invalid asset folder: \(url.path)"
            }
        }
    }

    /// Exports asset prompt text to {asset-folder}/prompt.txt
    /// - Parameter asset: Asset whose prompt text to export
    /// - Returns: URL of created prompt.txt file
    /// - Throws: PromptExportError if write fails
    func exportPromptText(asset: Asset) throws -> URL {
        // Note: This is a placeholder implementation since we don't have the full project structure yet
        // In a complete implementation, we would:
        // 1. Determine asset folder from asset.id and asset.scope
        // 2. Write asset.promptText to {asset-folder}/prompt.txt
        // 3. Return the URL of the written file

        // For now, create a temporary file path concept
        let assetFolderURL = URL(fileURLWithPath: "/tmp/Assets/\(asset.scope)/\(asset.id.uuidString)")

        // Verify folder exists (in real implementation, create if needed)
        let fileManager = FileManager.default
        if !fileManager.fileExists(atPath: assetFolderURL.path) {
            throw PromptExportError.invalidAssetFolder(assetFolderURL)
        }

        let promptFileURL = assetFolderURL.appendingPathComponent("prompt.txt")

        do {
            try asset.promptText.write(to: promptFileURL, atomically: true, encoding: .utf8)
            return promptFileURL
        } catch {
            throw PromptExportError.writeError(promptFileURL, error)
        }
    }
}

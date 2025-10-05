import Foundation

/// Service for managing AI chat conversations within asset editor
class AIChatService {
    enum AIChatError: Error, LocalizedError {
        case noAPIKey
        case invalidAPIKey
        case networkError(Error)
        case timeout
        case rateLimited
        case generationFailed(String)

        var errorDescription: String? {
            switch self {
            case .noAPIKey:
                return "No API key configured for AI provider"
            case .invalidAPIKey:
                return "API key validation failed"
            case .networkError(let error):
                return "Network request failed: \(error.localizedDescription)"
            case .timeout:
                return "Request exceeded 60s timeout"
            case .rateLimited:
                return "API rate limit exceeded"
            case .generationFailed(let reason):
                return "AI generation failed: \(reason)"
            }
        }
    }

    enum AIProvider {
        case midjourney
        case dalle3
        case gemini
    }

    private let apiKey: String?
    private let timeoutInterval: TimeInterval = 60.0

    init(apiKey: String?) {
        self.apiKey = apiKey
    }

    /// Sends user message with optional images to AI provider
    /// - Parameters:
    ///   - text: User message text
    ///   - images: Attached images (optimized versions used for API)
    ///   - provider: Selected AI model provider
    /// - Returns: Assistant response with generated images
    /// - Throws: AIChatError if request fails
    func sendMessage(text: String, images: [URL], provider: AIProvider) throws -> ChatMessage {
        // Validation: API key required
        guard let apiKey = apiKey, !apiKey.isEmpty else {
            throw AIChatError.noAPIKey
        }

        // Validation: text length
        guard text.count <= 5000 else {
            throw AIChatError.generationFailed("Message text exceeds 5000 characters")
        }

        // Validation: image count
        guard images.count <= 10 else {
            throw AIChatError.generationFailed("Cannot attach more than 10 images")
        }

        // In full implementation, would:
        // 1. Prepare API request with optimized images
        // 2. Make URLSession request with 60s timeout
        // 3. Handle timeout with "Keep Waiting"/"Cancel" dialog
        // 4. Parse response and extract generated image URLs
        // 5. Return ChatMessage with generatedImages array

        // For now, return a stub assistant message
        // Full implementation requires:
        // - URLSession configuration with timeout
        // - Provider-specific API formatting (Midjourney/DALL-E/Gemini)
        // - Image upload handling for multipart requests
        // - Response parsing

        let generatedImageURL = URL(fileURLWithPath: "/tmp/generated-\(UUID().uuidString).png")

        return ChatMessage(
            role: .assistant,
            text: "",
            generatedImages: [generatedImageURL]
        )
    }

    /// Loads chat history for an asset from disk
    /// - Parameter asset: Asset whose chat history to load
    /// - Returns: Array of messages in chronological order
    /// - Throws: ChatHistoryError if loading fails
    func loadHistory(asset: Asset) throws -> [ChatMessage] {
        guard let historyPath = asset.chatHistoryPath else {
            // No history file - return empty array (not error)
            return []
        }

        guard FileManager.default.fileExists(atPath: historyPath.path) else {
            return []
        }

        // In full implementation, would:
        // 1. Read history.yaml file
        // 2. Parse YAML using Yams library
        // 3. Decode to [ChatMessage]
        // 4. Verify messages sorted by timestamp
        // 5. Target: <50ms for 100 messages

        // For now, return empty (YAML parsing requires Yams dependency)
        // TODO: Add Yams via SPM and implement full YAML parsing

        let yamlData = try Data(contentsOf: historyPath)
        // let decoder = YAMLDecoder()  // Requires Yams
        // let history = try decoder.decode(ChatHistory.self, from: yamlData)
        // return history.messages

        return []  // Stub until Yams integrated
    }

    /// Saves chat history to disk for an asset
    /// - Parameters:
    ///   - messages: Complete message array to save
    ///   - asset: Asset to save history for
    /// - Throws: ChatHistoryError if save fails
    func saveHistory(messages: [ChatMessage], asset: Asset) throws {
        // Determine asset folder
        // In full implementation, would derive from asset.id and asset.scope
        let assetFolder = URL(fileURLWithPath: "/tmp/Assets/\(asset.scope)/\(asset.id.uuidString)")
        let chatFolder = assetFolder.appendingPathComponent(".chat")
        let historyURL = chatFolder.appendingPathComponent("history.yaml")

        // Create .chat directory if missing
        if !FileManager.default.fileExists(atPath: chatFolder.path) {
            try FileManager.default.createDirectory(
                at: chatFolder,
                withIntermediateDirectories: true
            )
        }

        // In full implementation, would:
        // 1. Create ChatHistory wrapper with version
        // 2. Encode to YAML using Yams
        // 3. Write atomically (temp file + move)
        // 4. Update asset.chatHistoryPath if nil
        // 5. Target: <50ms for 100 messages

        let history = ChatHistory(messages: messages)

        // TODO: Implement YAML encoding with Yams
        // let encoder = YAMLEncoder()
        // let yamlData = try encoder.encode(history)
        // try yamlData.write(to: historyURL, options: .atomic)

        // For now, write placeholder to demonstrate file creation
        let placeholderYAML = """
        messages: []
        version: "1.0"
        """
        try placeholderYAML.write(to: historyURL, atomically: true, encoding: .utf8)
    }

    /// Deletes chat history file for an asset
    /// - Parameter asset: Asset whose history to clear
    /// - Throws: ChatHistoryError if deletion fails
    func clearHistory(asset: Asset) throws {
        guard let historyPath = asset.chatHistoryPath else {
            // No history to clear - idempotent
            return
        }

        // Delete file if it exists (idempotent)
        if FileManager.default.fileExists(atPath: historyPath.path) {
            try FileManager.default.removeItem(at: historyPath)
        }

        // In full implementation, would also:
        // - Set asset.chatHistoryPath = nil
        // - Save asset.yaml
    }

    /// Imports AI-generated image from chat into asset's reference collection
    /// - Parameters:
    ///   - imageURL: URL of generated image
    ///   - asset: Asset to import into
    /// - Returns: Created ImageReference
    /// - Throws: AssetImportError if import fails
    func importGeneratedImage(imageURL: URL, asset: Asset) throws -> ImageReference {
        // In full implementation, would:
        // 1. Copy generated image to asset originals/ folder
        // 2. Create optimized version via ImageOptimizationService
        // 3. Add to asset with source: .generated
        // 4. Update asset.updatedAt
        // 5. Save asset.yaml

        // For now, create stub reference
        let imageRef = ImageReference(
            url: imageURL,
            dimensions: CGSize(width: 1024, height: 1024),
            source: .generated,
            type: .original
        )

        return imageRef
    }
}

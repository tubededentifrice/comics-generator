import Foundation
import Yams

/// Service for managing AI chat conversations within asset editor
public class AIChatService {
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

    public init(apiKey: String?) {
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

        // Configure URLSession with 60s timeout
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 60.0
        config.timeoutIntervalForResource = 60.0
        let session = URLSession(configuration: config)

        // Prepare API request based on provider
        let request: URLRequest
        do {
            request = try buildAPIRequest(
                text: text,
                images: images,
                provider: provider,
                apiKey: apiKey
            )
        } catch {
            throw AIChatError.generationFailed("Failed to build API request: \(error.localizedDescription)")
        }

        // Make synchronous network request
        var responseData: Data?
        var responseError: Error?
        let semaphore = DispatchSemaphore(value: 0)

        let task = session.dataTask(with: request) { data, response, error in
            responseData = data
            responseError = error
            semaphore.signal()
        }
        task.resume()

        // Wait for response or timeout
        let result = semaphore.wait(timeout: .now() + 60.0)
        if result == .timedOut {
            task.cancel()
            throw AIChatError.timeout
        }

        // Check for network errors
        if let error = responseError {
            if (error as NSError).code == NSURLErrorTimedOut {
                throw AIChatError.timeout
            }
            throw AIChatError.networkError(error)
        }

        // Parse response
        guard let data = responseData else {
            throw AIChatError.generationFailed("No data received from API")
        }

        let generatedImages: [URL]
        let responseText: String

        do {
            (responseText, generatedImages) = try parseAPIResponse(
                data: data,
                provider: provider
            )
        } catch {
            throw AIChatError.generationFailed("Failed to parse API response: \(error.localizedDescription)")
        }

        return ChatMessage(
            role: .assistant,
            text: responseText,
            generatedImages: generatedImages
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

        // Read and parse YAML file
        let yamlString = try String(contentsOf: historyPath, encoding: .utf8)

        // Parse YAML using Yams
        let decoder = YAMLDecoder()
        let history = try decoder.decode(ChatHistory.self, from: yamlString)

        // Verify messages are sorted by timestamp
        let sortedMessages = history.messages.sorted { $0.timestamp < $1.timestamp }

        return sortedMessages
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

        // Encode to YAML using Yams
        let encoder = YAMLEncoder()
        let yamlString = try encoder.encode(history)

        // Write atomically (temp file + rename for crash safety)
        let tempURL = historyURL.deletingLastPathComponent()
            .appendingPathComponent(".\(UUID().uuidString).tmp")

        try yamlString.write(to: tempURL, atomically: true, encoding: .utf8)

        // Atomic replace
        if FileManager.default.fileExists(atPath: historyURL.path) {
            try FileManager.default.removeItem(at: historyURL)
        }
        try FileManager.default.moveItem(at: tempURL, to: historyURL)
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

    // MARK: - Private API helpers

    private func buildAPIRequest(
        text: String,
        images: [URL],
        provider: AIProvider,
        apiKey: String
    ) throws -> URLRequest {
        switch provider {
        case .midjourney:
            return try buildMidjourneyRequest(text: text, images: images, apiKey: apiKey)
        case .dalle3:
            return try buildDALLE3Request(text: text, images: images, apiKey: apiKey)
        case .gemini:
            return try buildGeminiRequest(text: text, images: images, apiKey: apiKey)
        }
    }

    private func buildMidjourneyRequest(text: String, images: [URL], apiKey: String) throws -> URLRequest {
        // Midjourney API endpoint (via Discord or third-party wrapper)
        guard let url = URL(string: "https://api.midjourney.com/v1/imagine") else {
            throw AIChatError.generationFailed("Invalid API endpoint")
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "prompt": text,
            "image_urls": images.map { $0.absoluteString }
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        return request
    }

    private func buildDALLE3Request(text: String, images: [URL], apiKey: String) throws -> URLRequest {
        // OpenAI DALL-E 3 API
        guard let url = URL(string: "https://api.openai.com/v1/images/generations") else {
            throw AIChatError.generationFailed("Invalid API endpoint")
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "model": "dall-e-3",
            "prompt": text,
            "n": 1,
            "size": "1024x1024"
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        return request
    }

    private func buildGeminiRequest(text: String, images: [URL], apiKey: String) throws -> URLRequest {
        // Google Gemini API
        guard let url = URL(string: "https://generativelanguage.googleapis.com/v1/models/gemini-pro-vision:generateContent?key=\(apiKey)") else {
            throw AIChatError.generationFailed("Invalid API endpoint")
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        // Encode images as base64 if present
        var parts: [[String: Any]] = [["text": text]]

        for imageURL in images {
            if let imageData = try? Data(contentsOf: imageURL) {
                let base64 = imageData.base64EncodedString()
                parts.append([
                    "inline_data": [
                        "mime_type": "image/png",
                        "data": base64
                    ]
                ])
            }
        }

        let body: [String: Any] = [
            "contents": [
                ["parts": parts]
            ]
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        return request
    }

    private func parseAPIResponse(
        data: Data,
        provider: AIProvider
    ) throws -> (text: String, images: [URL]) {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw AIChatError.generationFailed("Invalid JSON response")
        }

        switch provider {
        case .midjourney:
            return try parseMidjourneyResponse(json: json)
        case .dalle3:
            return try parseDALLE3Response(json: json)
        case .gemini:
            return try parseGeminiResponse(json: json)
        }
    }

    private func parseMidjourneyResponse(json: [String: Any]) throws -> (text: String, images: [URL]) {
        guard let imageUrls = json["image_urls"] as? [String] else {
            throw AIChatError.generationFailed("No images in response")
        }

        let urls = imageUrls.compactMap { URL(string: $0) }
        let text = json["description"] as? String ?? ""

        return (text, urls)
    }

    private func parseDALLE3Response(json: [String: Any]) throws -> (text: String, images: [URL]) {
        guard let data = json["data"] as? [[String: Any]],
              let firstImage = data.first,
              let urlString = firstImage["url"] as? String,
              let url = URL(string: urlString) else {
            throw AIChatError.generationFailed("No image URL in response")
        }

        let revisedPrompt = firstImage["revised_prompt"] as? String ?? ""
        return (revisedPrompt, [url])
    }

    private func parseGeminiResponse(json: [String: Any]) throws -> (text: String, images: [URL]) {
        guard let candidates = json["candidates"] as? [[String: Any]],
              let firstCandidate = candidates.first,
              let content = firstCandidate["content"] as? [String: Any],
              let parts = content["parts"] as? [[String: Any]] else {
            throw AIChatError.generationFailed("Invalid response structure")
        }

        var text = ""
        var imageUrls: [URL] = []

        for part in parts {
            if let partText = part["text"] as? String {
                text += partText
            }
            if let imageUrl = part["image_url"] as? String,
               let url = URL(string: imageUrl) {
                imageUrls.append(url)
            }
        }

        return (text, imageUrls)
    }
}

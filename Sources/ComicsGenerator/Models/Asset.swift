import Foundation

/// Reusable character, object, or setting with reference images and AI chat history
public struct Asset: Codable, Identifiable {
    public let id: UUID
    public let name: String
    public let scope: AssetScope
    public let promptText: String
    public let originalImages: [ImageReference]
    public let optimizedImages: [ImageReference]
    public let chatHistoryPath: URL?
    public let createdAt: Date
    public let updatedAt: Date

    public init(
        id: UUID = UUID(),
        name: String,
        scope: AssetScope,
        promptText: String = "",
        originalImages: [ImageReference] = [],
        optimizedImages: [ImageReference] = [],
        chatHistoryPath: URL? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.scope = scope
        self.promptText = promptText
        self.originalImages = originalImages
        self.optimizedImages = optimizedImages
        self.chatHistoryPath = chatHistoryPath
        self.createdAt = createdAt
        self.updatedAt = updatedAt

        // Validation: name length (1-100 chars)
        precondition(!name.isEmpty && name.count <= 100, "Asset name must be 1-100 characters")

        // Validation: prompt text length (0-5000 chars)
        precondition(promptText.count <= 5000, "Prompt text cannot exceed 5000 characters")

        // Validation: image count limits (0-50 items each)
        precondition(originalImages.count <= 50, "Cannot have more than 50 original images")
        precondition(optimizedImages.count <= 50, "Cannot have more than 50 optimized images")

        // Validation: dual-image consistency (1:1 correspondence)
        precondition(
            originalImages.count == optimizedImages.count,
            "Original and optimized image counts must match"
        )

        // Validation: each optimized image must reference same base as corresponding original
        // (This is a structural check - actual validation happens at import time)
        for (index, original) in originalImages.enumerated() {
            let optimized = optimizedImages[index]
            precondition(
                original.source == optimized.source,
                "Original and optimized images at index \(index) must have same source"
            )
        }
    }

    /// Creates a new asset with updated timestamp
    func withUpdatedAt(_ date: Date = Date()) -> Asset {
        Asset(
            id: id,
            name: name,
            scope: scope,
            promptText: promptText,
            originalImages: originalImages,
            optimizedImages: optimizedImages,
            chatHistoryPath: chatHistoryPath,
            createdAt: createdAt,
            updatedAt: date
        )
    }
}

/// Hierarchy level for asset (root/series/album)
public enum AssetScope: String, Codable {
    case root
    case series
    case album
}

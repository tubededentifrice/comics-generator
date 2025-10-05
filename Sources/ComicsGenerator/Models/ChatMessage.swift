import Foundation

/// Single message in AI chat conversation, from either user or assistant
struct ChatMessage: Codable, Identifiable {
    let id: UUID
    let role: MessageRole
    let text: String
    let attachedImages: [URL]
    let generatedImages: [URL]
    let timestamp: Date

    init(
        id: UUID = UUID(),
        role: MessageRole,
        text: String = "",
        attachedImages: [URL] = [],
        generatedImages: [URL] = [],
        timestamp: Date = Date()
    ) {
        self.id = id
        self.role = role
        self.text = text
        self.attachedImages = attachedImages
        self.generatedImages = generatedImages
        self.timestamp = timestamp

        // Validation: user messages cannot have generated images
        if role == .user {
            precondition(generatedImages.isEmpty, "User messages cannot have generated images")
        }

        // Validation: assistant messages cannot have attached images
        if role == .assistant {
            precondition(attachedImages.isEmpty, "Assistant messages cannot have attached images")
        }

        // Validation: message must have text or generated images (no silent messages)
        precondition(!text.isEmpty || !generatedImages.isEmpty, "Message must have text or generated images")

        // Validation: text length limit
        precondition(text.count <= 5000, "Message text cannot exceed 5000 characters")

        // Validation: image count limits
        precondition(attachedImages.count <= 10, "Cannot attach more than 10 images")
        precondition(generatedImages.count <= 10, "Cannot have more than 10 generated images")
    }
}

/// Role of message sender (user or AI assistant)
enum MessageRole: String, Codable {
    case user
    case assistant
}

/// Complete conversation history for a single asset
struct ChatHistory: Codable {
    let messages: [ChatMessage]
    let version: String

    init(messages: [ChatMessage] = [], version: String = "1.0") {
        // Validation: messages must be ordered by timestamp
        for i in 1..<messages.count {
            precondition(
                messages[i].timestamp >= messages[i-1].timestamp,
                "Messages must be ordered by timestamp ascending"
            )
        }

        // Validation: no duplicate message IDs
        let ids = Set(messages.map { $0.id })
        precondition(ids.count == messages.count, "Message IDs must be unique")

        self.messages = messages
        self.version = version
    }
}

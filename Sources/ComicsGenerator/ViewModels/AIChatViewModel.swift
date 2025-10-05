import Foundation
import Combine

/// ViewModel for AI chat interface
@MainActor
public class AIChatViewModel: ObservableObject {
    @Published public var messages: [ChatMessage] = []
    @Published public var inputText: String = ""
    @Published public var isGenerating: Bool = false
    @Published public var errorMessage: String?
    @Published public var attachedImages: [URL] = []

    private let aiChatService: AIChatService
    private var currentAsset: Asset?

    public init(aiChatService: AIChatService) {
        self.aiChatService = aiChatService
    }

    /// Loads chat history for an asset
    public func loadHistory(for asset: Asset) async {
        self.currentAsset = asset
        let service = self.aiChatService

        do {
            let loadedMessages = try await Task.detached {
                try service.loadHistory(asset: asset)
            }.value

            await MainActor.run {
                self.messages = loadedMessages
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to load chat history: \(error.localizedDescription)"
            }
        }
    }

    /// Sends a message to the AI provider
    public func sendMessage(provider: AIChatService.AIProvider = .dalle3) async {
        guard !inputText.isEmpty || !attachedImages.isEmpty else { return }
        guard let asset = currentAsset else { return }

        // Create user message
        let userMessage = ChatMessage(
            role: .user,
            text: inputText,
            attachedImages: attachedImages
        )

        await MainActor.run {
            self.messages.append(userMessage)
            self.isGenerating = true
            self.inputText = ""
            self.attachedImages = []
        }

        do {
            // Send to AI service
            let service = self.aiChatService
            let assistantMessage = try await Task.detached {
                try service.sendMessage(
                    text: userMessage.text,
                    images: userMessage.attachedImages,
                    provider: provider
                )
            }.value

            await MainActor.run {
                self.messages.append(assistantMessage)
                self.isGenerating = false
            }

            // Auto-save history
            try await saveHistory(for: asset)

        } catch let error as AIChatService.AIChatError {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.isGenerating = false
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "AI generation failed: \(error.localizedDescription)"
                self.isGenerating = false
            }
        }
    }

    /// Saves chat history for the current asset
    public func saveHistory(for asset: Asset) async throws {
        let messagesToSave = await MainActor.run { self.messages }
        let service = self.aiChatService
        try await Task.detached {
            try service.saveHistory(messages: messagesToSave, asset: asset)
        }.value
    }

    /// Clears chat history
    public func clearHistory() async {
        guard let asset = currentAsset else { return }
        let service = self.aiChatService

        do {
            try await Task.detached {
                try service.clearHistory(asset: asset)
            }.value

            await MainActor.run {
                self.messages = []
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to clear history: \(error.localizedDescription)"
            }
        }
    }

    /// Imports a generated image into the asset
    public func importImage(_ imageURL: URL, into asset: Asset) async {
        let service = self.aiChatService
        do {
            let _ = try await Task.detached {
                try service.importGeneratedImage(imageURL: imageURL, asset: asset)
            }.value

            await MainActor.run {
                // Success - image added to asset
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to import image: \(error.localizedDescription)"
            }
        }
    }

    /// Attaches an image to the next message
    public func attachImage(_ url: URL) {
        guard attachedImages.count < 10 else {
            errorMessage = "Cannot attach more than 10 images"
            return
        }
        attachedImages.append(url)
    }

    /// Removes an attached image
    public func removeAttachedImage(_ url: URL) {
        attachedImages.removeAll { $0 == url }
    }
}

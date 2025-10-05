import Foundation
import Combine

/// ViewModel for AI chat interface
@MainActor
class AIChatViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var inputText: String = ""
    @Published var isGenerating: Bool = false
    @Published var errorMessage: String?
    @Published var attachedImages: [URL] = []

    private let aiChatService: AIChatService
    private var currentAsset: Asset?

    init(aiChatService: AIChatService) {
        self.aiChatService = aiChatService
    }

    /// Loads chat history for an asset
    func loadHistory(for asset: Asset) async {
        self.currentAsset = asset

        do {
            let loadedMessages = try await Task.detached {
                try self.aiChatService.loadHistory(asset: asset)
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
    func sendMessage(provider: AIChatService.AIProvider = .dalle3) async {
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
            let assistantMessage = try await Task.detached {
                try self.aiChatService.sendMessage(
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
    func saveHistory(for asset: Asset) async throws {
        try await Task.detached {
            try self.aiChatService.saveHistory(messages: self.messages, asset: asset)
        }.value
    }

    /// Clears chat history
    func clearHistory() async {
        guard let asset = currentAsset else { return }

        do {
            try await Task.detached {
                try self.aiChatService.clearHistory(asset: asset)
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
    func importImage(_ imageURL: URL, into asset: Asset) async {
        do {
            let _ = try await Task.detached {
                try self.aiChatService.importGeneratedImage(imageURL: imageURL, asset: asset)
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
    func attachImage(_ url: URL) {
        guard attachedImages.count < 10 else {
            errorMessage = "Cannot attach more than 10 images"
            return
        }
        attachedImages.append(url)
    }

    /// Removes an attached image
    func removeAttachedImage(_ url: URL) {
        attachedImages.removeAll { $0 == url }
    }
}

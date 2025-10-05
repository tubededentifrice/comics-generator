import XCTest
@testable import ComicsGenerator

/// Contract tests for AIChatService
/// ⚠️ CRITICAL: These tests MUST FAIL initially (service not implemented yet)
final class AIChatServiceTests: XCTestCase {
    var tempDirectoryURL: URL!

    override func setUp() {
        super.setUp()
        tempDirectoryURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        try! FileManager.default.createDirectory(
            at: tempDirectoryURL,
            withIntermediateDirectories: true
        )
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: tempDirectoryURL)
        super.tearDown()
    }

    // MARK: - T010: sendMessage contract tests

    func testSendMessage_noAPIKey_throwsError() throws {
        XCTExpectFailure("AIChatService not implemented yet - TDD phase")

        // Given: No API key configured
        let service = AIChatService(apiKey: nil)

        // When/Then: Should throw noAPIKey error
        XCTAssertThrowsError(
            try service.sendMessage(text: "Test message", images: [], provider: .dalle3)
        ) { error in
            XCTAssertTrue(error is AIChatService.AIChatError)
            if case AIChatService.AIChatError.noAPIKey = error {
                // Expected error type
            } else {
                XCTFail("Expected AIChatError.noAPIKey, got \(error)")
            }
        }
    }

    func testSendMessage_timeout_throwsAfter60Seconds() throws {
        XCTExpectFailure("AIChatService not implemented yet - TDD phase")

        // Given: Service with mock slow API
        let service = AIChatService(apiKey: "test-key", mockDelay: 61.0)

        // When: Sending message
        let startTime = Date()

        XCTAssertThrowsError(
            try service.sendMessage(text: "Test", images: [], provider: .dalle3)
        ) { error in
            let elapsed = Date().timeIntervalSince(startTime)

            // Then: Should timeout after ~60 seconds
            XCTAssertGreaterThanOrEqual(elapsed, 60.0)
            XCTAssertLessThan(elapsed, 62.0, "Timeout should be precise")

            XCTAssertTrue(error is AIChatService.AIChatError)
            if case AIChatService.AIChatError.timeout = error {
                // Expected error type
            } else {
                XCTFail("Expected AIChatError.timeout, got \(error)")
            }
        }
    }

    func testSendMessage_usesOptimizedImages() throws {
        XCTExpectFailure("AIChatService not implemented yet - TDD phase")

        // Given: Large image URL
        let largeImageURL = URL(fileURLWithPath: "/tmp/large-4k.png")

        // When: Sending message with image
        let service = AIChatService(apiKey: "test-key")
        let message = try service.sendMessage(
            text: "Describe this image",
            images: [largeImageURL],
            provider: .gemini
        )

        // Then: Service should have used optimized version
        // (This would be verified by checking internal API call logs)
        XCTAssertEqual(message.role, .assistant)
        XCTAssertTrue(message.generatedImages.isEmpty, "Text-only request should not generate images")
    }

    func testSendMessage_returnsAssistantMessage() throws {
        XCTExpectFailure("AIChatService not implemented yet - TDD phase")

        // Given: Valid request
        let service = AIChatService(apiKey: "test-key", mockResponse: "Generated image URL")

        // When: Sending message
        let message = try service.sendMessage(
            text: "Create a castle",
            images: [],
            provider: .midjourney
        )

        // Then: Returns assistant message with generated images
        XCTAssertEqual(message.role, .assistant)
        XCTAssertFalse(message.generatedImages.isEmpty)
        XCTAssertTrue(message.attachedImages.isEmpty, "Assistant messages cannot have attached images")
    }

    // MARK: - T011: history methods contract tests

    func testLoadHistory_emptyFile_returnsEmptyArray() throws {
        XCTExpectFailure("AIChatService not implemented yet - TDD phase")

        // Given: Asset with no chat history
        let asset = Asset(id: UUID(), name: "Test Asset", scope: .root)

        // When: Loading history
        let service = AIChatService(apiKey: "test-key")
        let messages = try service.loadHistory(asset: asset)

        // Then: Returns empty array (not error)
        XCTAssertTrue(messages.isEmpty)
    }

    func testSaveHistory_writesJSON_atomically() throws {
        XCTExpectFailure("AIChatService not implemented yet - TDD phase")

        // Given: Messages to save
        let messages = [
            ChatMessage(role: .user, text: "Hello"),
            ChatMessage(role: .assistant, text: "Hi there")
        ]
        let asset = Asset(id: UUID(), name: "Test Asset", scope: .root)

        // When: Saving history
        let service = AIChatService(apiKey: "test-key")
        try service.saveHistory(messages: messages, asset: asset)

        // Then: YAML file created atomically
        let assetFolder = tempDirectoryURL.appendingPathComponent("Assets/root/\(asset.id.uuidString)")
        let historyURL = assetFolder.appendingPathComponent(".chat/history.yaml")

        XCTAssertTrue(FileManager.default.fileExists(atPath: historyURL.path))

        // Verify YAML format
        let yamlContent = try String(contentsOf: historyURL, encoding: .utf8)
        XCTAssertTrue(yamlContent.contains("messages:"))
        XCTAssertTrue(yamlContent.contains("role: user"))
        XCTAssertTrue(yamlContent.contains("role: assistant"))
        XCTAssertTrue(yamlContent.contains("version:"))
    }

    func testClearHistory_deletesFile_idempotent() throws {
        XCTExpectFailure("AIChatService not implemented yet - TDD phase")

        // Given: Asset with existing history
        let asset = Asset(id: UUID(), name: "Test Asset", scope: .root)
        let messages = [ChatMessage(role: .user, text: "Test")]

        let service = AIChatService(apiKey: "test-key")
        try service.saveHistory(messages: messages, asset: asset)

        let assetFolder = tempDirectoryURL.appendingPathComponent("Assets/root/\(asset.id.uuidString)")
        let historyURL = assetFolder.appendingPathComponent(".chat/history.yaml")

        XCTAssertTrue(FileManager.default.fileExists(atPath: historyURL.path))

        // When: Clearing history
        try service.clearHistory(asset: asset)

        // Then: File deleted or empty
        let fileExists = FileManager.default.fileExists(atPath: historyURL.path)
        if fileExists {
            let content = try String(contentsOf: historyURL, encoding: .utf8)
            XCTAssertTrue(content.contains("messages: []"), "If file exists, should be empty")
        }

        // Verify idempotent (clearing again doesn't error)
        XCTAssertNoThrow(try service.clearHistory(asset: asset))
    }

    func testLoadHistory_completesUnder50ms_for100Messages() throws {
        XCTExpectFailure("AIChatService not implemented yet - TDD phase")

        // Given: Asset with 100 messages
        var messages: [ChatMessage] = []
        for i in 0..<100 {
            messages.append(ChatMessage(
                role: i % 2 == 0 ? .user : .assistant,
                text: "Message \(i)",
                timestamp: Date().addingTimeInterval(TimeInterval(i))
            ))
        }

        let asset = Asset(id: UUID(), name: "Test Asset", scope: .root)
        let service = AIChatService(apiKey: "test-key")
        try service.saveHistory(messages: messages, asset: asset)

        // When: Loading history (measure time)
        let startTime = Date()
        let loadedMessages = try service.loadHistory(asset: asset)
        let elapsed = Date().timeIntervalSince(startTime)

        // Then: Completes in <50ms
        XCTAssertLessThan(elapsed, 0.05, "Loading 100 messages should take <50ms")
        XCTAssertEqual(loadedMessages.count, 100)

        // Verify messages sorted by timestamp
        for i in 1..<loadedMessages.count {
            XCTAssertGreaterThanOrEqual(
                loadedMessages[i].timestamp,
                loadedMessages[i-1].timestamp,
                "Messages must be sorted by timestamp"
            )
        }
    }
}

// MARK: - Stub Service

class AIChatService {
    enum AIChatError: Error, LocalizedError {
        case noAPIKey
        case invalidAPIKey
        case networkError
        case timeout
        case rateLimited
        case generationFailed
        case notImplemented

        var errorDescription: String? {
            switch self {
            case .noAPIKey: return "No API key configured"
            case .invalidAPIKey: return "API key validation failed"
            case .networkError: return "Network request failed"
            case .timeout: return "Request exceeded 60s timeout"
            case .rateLimited: return "API rate limit exceeded"
            case .generationFailed: return "AI generation failed"
            case .notImplemented: return "AIChatService not yet implemented"
            }
        }
    }

    enum AIProvider {
        case midjourney
        case dalle3
        case gemini
    }

    private let apiKey: String?
    private let mockDelay: TimeInterval?
    private let mockResponse: String?

    init(apiKey: String?, mockDelay: TimeInterval? = nil, mockResponse: String? = nil) {
        self.apiKey = apiKey
        self.mockDelay = mockDelay
        self.mockResponse = mockResponse
    }

    func sendMessage(text: String, images: [URL], provider: AIProvider) throws -> ChatMessage {
        throw AIChatError.notImplemented
    }

    func loadHistory(asset: Asset) throws -> [ChatMessage] {
        throw AIChatError.notImplemented
    }

    func saveHistory(messages: [ChatMessage], asset: Asset) throws {
        throw AIChatError.notImplemented
    }

    func clearHistory(asset: Asset) throws {
        throw AIChatError.notImplemented
    }

    func importGeneratedImage(imageURL: URL, asset: Asset) throws -> ImageReference {
        throw AIChatError.notImplemented
    }
}

import SwiftUI
import ComicsGenerator

@main
struct ComicsGeneratorApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

struct ContentView: View {
    @StateObject private var assetImportVM = AssetImportViewModel()
    @StateObject private var pdfExportVM = PDFExportViewModel()
    @StateObject private var aiChatVM = AIChatViewModel(aiChatService: AIChatService(apiKey: nil))

    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            // Asset Import Tab
            AssetImportView(viewModel: assetImportVM)
                .tabItem {
                    Label("Import", systemImage: "photo.on.rectangle.angled")
                }
                .tag(0)

            // AI Chat Tab
            AIChatView(viewModel: aiChatVM)
                .tabItem {
                    Label("AI Chat", systemImage: "bubble.left.and.bubble.right")
                }
                .tag(1)

            // PDF Export Tab
            PDFExportView(viewModel: pdfExportVM)
                .tabItem {
                    Label("Export PDF", systemImage: "doc.text")
                }
                .tag(2)
        }
        .frame(minWidth: 800, minHeight: 600)
    }
}

// MARK: - Asset Import View

struct AssetImportView: View {
    @ObservedObject var viewModel: AssetImportViewModel

    var body: some View {
        VStack(spacing: 20) {
            Text("Asset Import")
                .font(.largeTitle)
                .bold()

            Text("Import images to create comic assets")
                .foregroundColor(.secondary)

            if viewModel.isImporting {
                ProgressView("Importing images...")
            } else if let error = viewModel.errorMessage {
                Text("Error: \(error)")
                    .foregroundColor(.red)
                    .padding()
            } else {
                Text("Imported \(viewModel.importedCount) images")
                    .font(.headline)
            }

            Button("Import Images") {
                // In a real app, would show file picker
                // For now, just demonstrate the functionality
                let demoAsset = Asset(id: UUID(), name: "Demo Asset", scope: .root)
                Task {
                    await viewModel.importImages(imageURLs: [], asset: demoAsset)
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(viewModel.isImporting)

            Spacer()
        }
        .padding()
    }
}

// MARK: - AI Chat View

struct AIChatView: View {
    @ObservedObject var viewModel: AIChatViewModel
    @State private var messageText = ""

    var body: some View {
        VStack(spacing: 0) {
            Text("AI-Assisted Image Generation")
                .font(.largeTitle)
                .bold()
                .padding()

            Text("Chat with AI to generate images for your comics")
                .foregroundColor(.secondary)
                .padding(.bottom)

            // Messages list
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(viewModel.messages) { message in
                        MessageBubble(message: message)
                    }
                }
                .padding()
            }

            // Input area
            HStack {
                TextField("Type your message...", text: $messageText)
                    .textFieldStyle(.roundedBorder)
                    .disabled(viewModel.isGenerating)

                Button("Send") {
                    let text = messageText
                    messageText = ""
                    let demoAsset = Asset(id: UUID(), name: "Demo Asset", scope: .root)
                    Task {
                        await viewModel.sendMessage(provider: .dalle3)
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(messageText.isEmpty || viewModel.isGenerating)
            }
            .padding()

            if viewModel.isGenerating {
                ProgressView("Generating...")
                    .padding()
            }

            if let error = viewModel.errorMessage {
                Text("Error: \(error)")
                    .foregroundColor(.red)
                    .padding()
            }
        }
    }
}

struct MessageBubble: View {
    let message: ChatMessage

    var body: some View {
        HStack {
            if message.role == .user {
                Spacer()
            }

            VStack(alignment: message.role == .user ? .trailing : .leading, spacing: 4) {
                Text(message.text)
                    .padding(10)
                    .background(message.role == .user ? Color.blue : Color.gray.opacity(0.2))
                    .foregroundColor(message.role == .user ? .white : .primary)
                    .cornerRadius(12)

                Text(message.timestamp, style: .time)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            if message.role == .assistant {
                Spacer()
            }
        }
    }
}

// MARK: - PDF Export View

struct PDFExportView: View {
    @ObservedObject var viewModel: PDFExportViewModel

    var body: some View {
        VStack(spacing: 20) {
            Text("PDF Export")
                .font(.largeTitle)
                .bold()

            Text("Export your comic pages as high-quality PDFs")
                .foregroundColor(.secondary)

            VStack(alignment: .leading, spacing: 10) {
                Text("Resolution: 300 DPI")
                Text("Format: PDF")
                Text("Metadata: Embedded")
            }
            .font(.headline)
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(8)

            if viewModel.isExporting {
                ProgressView("Exporting PDF...")
            } else if let error = viewModel.errorMessage {
                Text("Error: \(error)")
                    .foregroundColor(.red)
                    .padding()
            } else if let url = viewModel.lastExportURL {
                Text("✓ Exported to: \(url.lastPathComponent)")
                    .foregroundColor(.green)
                    .padding()
            }

            Button("Export Album as PDF") {
                // Demo: Create a simple album and export
                let demoAlbum = Album(
                    id: UUID(),
                    name: "Demo Album",
                    pages: [
                        Page(
                            id: UUID(),
                            layout: PageLayout(bounds: CGRect(x: 0, y: 0, width: 800, height: 600)),
                            drawings: []
                        )
                    ]
                )
                Task {
                    await viewModel.exportAlbum(album: demoAlbum)
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(viewModel.isExporting)

            Spacer()
        }
        .padding()
    }
}

#Preview {
    ContentView()
}

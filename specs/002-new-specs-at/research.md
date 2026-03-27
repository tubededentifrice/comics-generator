# Research: PDF Export and AI-Assisted Asset Generation

**Feature**: 002-new-specs-at
**Date**: 2025-10-05
**Status**: Complete

## Research Questions & Decisions

### 1. PDF Generation with Metadata

**Question**: How should we generate publication-quality PDFs with embedded metadata while maintaining 300 DPI resolution?

**Decision**: Use PDFKit's `PDFDocument` API

**Rationale**:
- Native Apple framework (no external dependencies)
- Full support for 300 DPI rendering via `PDFPage` drawing
- Built-in metadata support via `documentAttributes` dictionary
- Page-by-page composition allows flexible layout rendering
- Proven performance for large documents
- Cross-platform (macOS/iOS) compatibility

**Alternatives Considered**:
- **Core Graphics PDF Context**: Lower-level API, requires manual metadata embedding, more complex coordinate system handling
- **Third-party libraries** (e.g., PSPDFKit): Violates Constitution Principle VI (external dependencies), unnecessary complexity for our use case
- **HTML-to-PDF conversion**: Requires WebKit, poor control over DPI/quality, bloated output

**Implementation Approach**:
```swift
// Create PDF document
let pdfDocument = PDFDocument()
pdfDocument.documentAttributes = [
    PDFDocumentAttribute.titleAttribute: albumName,
    PDFDocumentAttribute.authorAttribute: seriesName,
    PDFDocumentAttribute.creationDateAttribute: Date()
]

// Render pages at 300 DPI
for page in album.pages {
    let pdfPage = PDFPage()
    let bounds = page.layout.bounds
    pdfPage.setBounds(bounds, for: .mediaBox)

    // Draw at 300 DPI (72 points/inch * 300/72 scale)
    let context = CGContext(...)
    context.scaleBy(x: 300/72, y: 300/72)
    renderPage(page, in: context)
}
```

---

### 2. Image Optimization Strategy

**Question**: How should we resize imported images to 1024px while maintaining aspect ratio and quality?

**Decision**: Use CoreImage with `CILanczosScaleTransform` filter

**Rationale**:
- Hardware-accelerated GPU processing
- High-quality Lanczos resampling preserves detail
- Standard library (Foundation/CoreImage)
- Automatic aspect ratio preservation
- Handles all common formats (PNG, JPG, HEIC, SVG)

**Alternatives Considered**:
- **vImage (Accelerate framework)**: Lower-level, more complex API, manual buffer management
- **UIGraphicsImageRenderer**: Deprecated in iOS 17, CPU-bound
- **Third-party libraries** (e.g., Kingfisher): Overkill for simple resize operation

**Implementation Approach**:
```swift
func optimizeImage(at sourceURL: URL, maxDimension: Int) throws -> URL {
    let ciImage = CIImage(contentsOf: sourceURL)
    let scale = Double(maxDimension) / max(ciImage.extent.width, ciImage.extent.height)

    let filter = CIFilter(name: "CILanczosScaleTransform")!
    filter.setValue(ciImage, forKey: kCIInputImageKey)
    filter.setValue(scale, forKey: kCIInputScaleKey)
    filter.setValue(1.0, forKey: kCIInputAspectRatioKey)

    let output = filter.outputImage!
    let context = CIContext()
    let cgImage = context.createCGImage(output, from: output.extent)!

    // Write to optimized/ directory
    let destURL = assetFolder.appendingPathComponent("optimized/\(UUID().uuidString).png")
    try context.write(cgImage, to: destURL)
    return destURL
}
```

---

### 3. Chat History Persistence

**Question**: How should we store chat history to ensure human-readability, Git-compatibility, and efficient loading?

**Decision**: YAML file per asset in `.chat/` subfolder

**Rationale**:
- Superior human-readability vs JSON (satisfies Constitution Principle I preference for YAML)
- Excellent Git-friendliness (cleaner diffs, no closing brace noise)
- Comments supported for future annotations
- Multiline strings more readable for long prompts
- Standard library support via Yams (Swift Package Manager)
- One file per asset prevents bloating main asset YAML
- Easy to backup/restore individually
- No database overhead

**Alternatives Considered**:
- **JSON**: Native Codable support but less readable, noisier Git diffs with brackets
- **SQLite**: Overkill for simple append-only data, binary format not Git-friendly
- **Embedded in asset YAML**: Bloats asset file, makes diffs noisy, harder to review
- **plist format**: Apple-specific, harder to read/edit manually

**Constitutional Alignment**: Constitution v1.0.1 explicitly prefers YAML over JSON for structured data files

**File Structure**:
```
Assets/
└── castle-asset-id/
    ├── asset.yaml           # Asset metadata
    ├── prompt.txt           # Asset prompt text (for quick viewing)
    ├── originals/           # Full-resolution images
    │   ├── image1.png
    │   └── image2.jpg
    ├── optimized/           # 1024px optimized versions
    │   ├── image1-opt.png
    │   └── image2-opt.jpg
    └── .chat/
        └── history.yaml     # Chat messages
```

**YAML Schema**:
```yaml
messages:
  - id: uuid-1
    role: user
    text: Create a medieval castle
    attachedImages:
      - url1
      - url2
    generatedImages: []
    timestamp: 2025-10-05T10:30:00Z

  - id: uuid-2
    role: assistant
    text: ""
    attachedImages: []
    generatedImages:
      - url3
    timestamp: 2025-10-05T10:30:15Z

version: "1.0"
```

---

### 4. Dual Image Storage Layout

**Question**: How should we organize original and optimized images to make their purpose clear?

**Decision**: Separate `originals/` and `optimized/` subdirectories per asset

**Rationale**:
- Clear semantic separation (archival vs. API-optimized)
- Easy to clean up optimized versions for regeneration
- Obvious to users inspecting folders manually
- Simplifies backup strategies (backup originals, skip optimized)
- No naming collisions or suffix confusion

**Alternatives Considered**:
- **Suffixed filenames** (e.g., `image.png`, `image-1024.png`): Less clear purpose, clutters directory
- **Single copy with on-demand resize**: Slower, no caching, repeated computation
- **Separate root-level folders** (`OriginalAssets/`, `OptimizedAssets/`): Breaks asset cohesion

**Implementation Notes**:
- Optimized images generated lazily on first import
- Original deletion triggers optimized deletion (cascade)
- Optimized regeneration possible if algorithm changes

---

### 5. AI Chat UI Pattern

**Question**: What SwiftUI presentation style should we use for the AI chat interface?

**Decision**: Sheet presentation with `ScrollView` + message bubbles

**Rationale**:
- Standard iOS/macOS pattern (familiar to users)
- Full-screen focus during chat session
- Accessibility-friendly (VoiceOver, Dynamic Type)
- Dismissible with standard gestures
- Scrollable history with bottom-anchored input
- Works identically on iPad (full sheet) and Mac (dialog)

**Alternatives Considered**:
- **Popover**: Too small on iPad, obscures context, non-standard for chat
- **Inline panel in asset editor**: Clutters UI, split attention, harder to type long prompts
- **Sidebar**: macOS-only pattern, doesn't scale to iPad

**UI Components**:
```swift
struct AIChatView: View {
    @StateObject var viewModel: AIChatViewModel

    var body: some View {
        VStack {
            // Scrollable message list
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack {
                        ForEach(viewModel.messages) { message in
                            MessageBubbleView(message: message)
                        }
                    }
                }
                .onChange(of: viewModel.messages.count) { _ in
                    proxy.scrollTo(viewModel.messages.last?.id)
                }
            }

            // Input area
            HStack {
                TextField("Message", text: $viewModel.inputText)
                Button("Send") { viewModel.sendMessage() }
            }
            .padding()
        }
        .navigationTitle("AI Chat")
        .toolbar {
            ToolbarItem(placement: .destructiveAction) {
                Button("Clear Chat") { viewModel.clearHistory() }
            }
        }
    }
}
```

---

## Performance Considerations

### PDF Rendering
- **Target**: <200ms for 10-page album at 300 DPI
- **Approach**: Render pages off main thread using `DispatchQueue.global()`
- **Validation**: Performance test with XCTest metrics

### Image Optimization
- **Target**: <100ms per image (1024px resize)
- **Approach**: Batch processing with concurrent queue (max 4 simultaneous)
- **Validation**: Unit test with 10 sample images (various sizes)

### Chat History Loading
- **Target**: <50ms to load 100 messages
- **Approach**: JSONDecoder with `DateDecodingStrategy.iso8601`
- **Validation**: Integration test with synthetic chat history

---

## Implementation Notes

**YAML from Day 1**:
- No migration from JSON needed - implementing all features with YAML from the start
- Constitution v1.0.1 establishes YAML as preferred format
- Both Feature 001 and Feature 002 will use YAML persistence
- Yams library (SPM) provides robust YAML Codable support

## Open Questions

*All critical questions resolved via /clarify session. No blockers remain.*

Minor implementation details to resolve during coding:
1. Exact page number placement (footer center vs. corner) - defer to design phase
2. Duplicate image import behavior (overwrite vs. rename) - handled in spec (FR-095a: allow duplicates)

---

## References

- [PDFKit Documentation](https://developer.apple.com/documentation/pdfkit)
- [CoreImage Filters Reference](https://developer.apple.com/library/archive/documentation/GraphicsImaging/Reference/CoreImageFilterReference/)
- [Apple Human Interface Guidelines - Sheets](https://developer.apple.com/design/human-interface-guidelines/sheets)
- Constitution v1.0.0 - `.specify/memory/constitution.md`

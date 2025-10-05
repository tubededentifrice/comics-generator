# Quick Start Guide - Comics Generator

## Launch the Demo App (5 minutes)

### Step 1: Open in Xcode
```bash
cd comics-generator
open Package.swift
```

Wait for Xcode to resolve dependencies (check the progress bar at the top).

### Step 2: Select the App Scheme
- Look at the top bar in Xcode
- Click the scheme selector (next to the Run/Stop buttons)
- Select **"ComicsGeneratorApp"** from the dropdown
- Ensure "My Mac" is selected as the destination

### Step 3: Run the App
- Click the Run button (▶️) or press **⌘R**
- The demo app will launch with three tabs

### Step 4: Explore the Demo

**Import Tab:**
- Click "Import Images" to test the import workflow
- Note: File picker not yet implemented - demonstrates API

**AI Chat Tab:**
- Type a message and click "Send" to test the chat interface
- Note: Requires valid API key for actual generation

**Export PDF Tab:**
- Click "Export Album as PDF" to test PDF generation
- Creates a demo PDF in the temp directory

## Command Line Quick Start

### Build and Run
```bash
# Build the app
swift build

# Run the app
.build/debug/ComicsGeneratorApp
```

### Run Tests
```bash
# All tests (30 tests)
swift test

# Watch mode (rebuild on file changes)
swift test --parallel
```

### Build for Distribution
```bash
# Release build
swift build -c release

# Find the executable
ls -lh .build/release/ComicsGeneratorApp
```

## Using the Library in Your Project

### 1. Add as Dependency

**Package.swift:**
```swift
dependencies: [
    .package(path: "../comics-generator")
]
```

**Or from GitHub:**
```swift
dependencies: [
    .package(url: "https://github.com/yourname/comics-generator.git", from: "1.0.0")
]
```

### 2. Import and Use

```swift
import ComicsGenerator

// Create a service
let pdfService = PDFExportService()

// Create an album
let album = Album(
    name: "My First Comic",
    pages: [
        Page(
            layout: PageLayout(),
            drawings: []
        )
    ]
)

// Export to PDF
let options = PDFExportOptions(
    seriesName: "My Series",
    albumName: album.name,
    outputURL: URL(fileURLWithPath: "/tmp/comic.pdf")
)

Task {
    let url = try await pdfService.exportAlbum(album: album, options: options)
    print("Exported to: \(url.path)")
}
```

## Troubleshooting

### "Product > Run is greyed out"
- Ensure you've selected **ComicsGeneratorApp** scheme (not ComicsGenerator)
- Select "My Mac" as the run destination

### Build errors about missing types
```bash
# Clean and rebuild
swift package clean
swift build
```

### Xcode indexing stuck
```bash
# Reset derived data
rm -rf ~/Library/Developer/Xcode/DerivedData
```

### Tests timeout
- AI chat tests make real network calls (timeout after 60s)
- This is expected behavior without valid API keys

## Next Steps

1. **Explore the Code**: Check `Sources/ComicsGenerator/Services/` for service implementations
2. **Read the Tests**: `Tests/ComicsGeneratorTests/` shows usage examples
3. **Review Specs**: `specs/002-new-specs-at/` contains detailed feature documentation
4. **Integrate**: Add the library to your own SwiftUI or UIKit app

## Getting Help

- Read the full [README.md](README.md) for detailed documentation
- Check [IMPLEMENTATION_STATUS.md](IMPLEMENTATION_STATUS.md) for current progress
- Review test files for usage examples
- See [specs/](specs/) for feature specifications

---

**Build Status**: ✅ All 30 tests passing
**Demo App**: ✅ Launches successfully
**Platforms**: macOS 14.0+, iOS 17.0+

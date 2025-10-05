# Comics Generator

A macOS and iPadOS application for creating comic books with Apple Pencil support, PDF export, and AI-assisted asset generation.

## Features

- **PDF Export**: Export albums or individual pages as publication-quality PDFs at 300 DPI
- **AI-Assisted Asset Generation**: Interactive chat interface with Midjourney, DALL-E 3, and Gemini
- **Dual-Image Storage**: Maintains both original high-resolution and API-optimized (1024px) versions
- **Chat History**: Preserves AI conversations per asset indefinitely
- **Source Tracking**: Images tagged as imported or AI-generated
- **YAML-Based Storage**: Human-readable, Git-friendly data format

## Requirements

### Development
- **macOS**: 14.0 (Sonoma) or later
- **Xcode**: 15.0 or later
- **Swift**: 5.9 or later
- **iOS Deployment Target**: 17.0+ (for iPad)

### Runtime
- macOS 14.0+ or iPadOS 17.0+
- 4GB RAM minimum, 8GB recommended
- 2GB available disk space

## Quick Start

### Building on Your Mac

1. **Clone the Repository**
   ```bash
   git clone <repository-url>
   cd comics-generator
   ```

2. **Open in Xcode**
   ```bash
   open Package.swift
   ```

   Or double-click `Package.swift` in Finder.

3. **Resolve Dependencies**
   - Xcode will automatically fetch dependencies (Yams for YAML parsing)
   - Wait for "Package Resolution" to complete (check status bar)

4. **Select Build Target**
   - Choose "ComicsGenerator" scheme
   - Select "My Mac" or an iOS Simulator as destination

5. **Build the Project**
   ```bash
   # Command line
   swift build

   # Or in Xcode: Product → Build (⌘B)
   ```

6. **Run Tests**
   ```bash
   # Command line
   swift test

   # Or in Xcode: Product → Test (⌘U)
   ```

### Project Structure

```
comics-generator/
├── Sources/
│   └── ComicsGenerator/
│       ├── Models/              # Data models (Asset, ImageReference, etc.)
│       ├── Services/            # Business logic (PDF, Import, AI Chat)
│       ├── ViewModels/          # SwiftUI view models
│       └── Views/               # SwiftUI views
├── Tests/
│   └── ComicsGeneratorTests/
│       ├── Unit/               # Service contract tests
│       └── Integration/        # End-to-end workflow tests
├── specs/                      # Feature specifications
│   └── 002-new-specs-at/
├── Package.swift               # Swift Package Manager manifest
└── README.md
```

## Development Workflow

### Running Locally

```bash
# Build and run (creates library)
swift build

# Run tests
swift test

# Run specific test
swift test --filter PDFExportServiceTests

# Generate Xcode project (optional)
swift package generate-xcodeproj
```

### Code Organization

- **Models**: Codable structs with YAML support (via Yams)
- **Services**: Business logic with dependency injection
- **ViewModels**: @MainActor ObservableObjects for SwiftUI
- **Views**: SwiftUI components following Apple HIG

### Testing Strategy

1. **Contract Tests** (Unit): Validate service APIs
2. **Integration Tests**: Test end-to-end workflows
3. **UI Tests**: Validate user interactions (future)
4. **Performance Tests**: Verify targets (<100ms, <200ms)

## Packaging for Distribution

### Option 1: Mac App Bundle (for macOS)

#### Create Xcode Project

```bash
# Generate Xcode project from Package.swift
xcodebuild -resolvePackageDependencies
xcodebuild -project ComicsGenerator.xcodeproj \
           -scheme ComicsGenerator \
           -configuration Release \
           -derivedDataPath ./build
```

#### Build Archive

1. Open `Package.swift` in Xcode
2. **Product → Archive**
3. In Organizer window:
   - Select archive
   - Click "Distribute App"
   - Choose distribution method:
     - **Mac App Store**: For App Store distribution
     - **Developer ID**: For direct distribution outside App Store
     - **Copy App**: For testing/internal distribution

#### Notarization (Required for macOS Distribution)

```bash
# After archiving, notarize the app
xcrun notarytool submit ComicsGenerator.zip \
    --apple-id "your-apple-id@example.com" \
    --team-id "YOUR_TEAM_ID" \
    --password "app-specific-password"

# Check notarization status
xcrun notarytool log <submission-id> --apple-id "your-apple-id@example.com"

# Staple notarization ticket to app
xcrun stapler staple "ComicsGenerator.app"
```

### Option 2: App Store Distribution

#### Prerequisites

1. **Apple Developer Account** ($99/year)
   - Enroll at https://developer.apple.com/programs/

2. **App Store Connect Setup**
   - Create app record at https://appstoreconnect.apple.com
   - Configure app metadata, screenshots, description
   - Set pricing and availability

3. **Certificates & Provisioning**
   ```bash
   # Create App Store distribution certificate
   # In Xcode: Preferences → Accounts → Manage Certificates
   # Click "+" and select "Apple Distribution"
   ```

#### Prepare for Submission

1. **Update Info.plist** (if using Xcode project)
   ```xml
   <key>CFBundleIdentifier</key>
   <string>com.yourcompany.comicsgenerator</string>
   <key>CFBundleShortVersionString</key>
   <string>1.0</string>
   <key>CFBundleVersion</key>
   <string>1</string>
   <key>LSMinimumSystemVersion</key>
   <string>14.0</string>
   ```

2. **Configure Entitlements**
   - Sandboxing (required for Mac App Store)
   - File access (user-selected files only)
   - Network (for AI API calls)

3. **Add App Icons**
   - Create AppIcon.appiconset with all required sizes
   - Use Asset Catalog in Xcode

#### Submit to App Store

```bash
# Upload archive via Xcode Organizer
# 1. Product → Archive
# 2. Open Organizer (Window → Organizer)
# 3. Select archive → "Distribute App"
# 4. Choose "App Store Connect"
# 5. Follow upload wizard

# Or via command line (after archiving)
xcrun altool --upload-app \
    --type macos \
    --file "ComicsGenerator.ipa" \
    --username "your-apple-id@example.com" \
    --password "app-specific-password"
```

#### TestFlight (Optional)

For beta testing before public release:

1. Upload build to App Store Connect
2. Enable TestFlight in App Store Connect
3. Add internal/external testers
4. Share invite link with testers

### Option 3: Direct Distribution (DMG)

For distribution outside the App Store:

```bash
# Create DMG installer
hdiutil create -volname "Comics Generator" \
    -srcfolder "ComicsGenerator.app" \
    -ov -format UDZO \
    "ComicsGenerator-1.0.dmg"

# Notarize DMG (required for Gatekeeper)
xcrun notarytool submit ComicsGenerator-1.0.dmg \
    --apple-id "your-apple-id@example.com" \
    --team-id "YOUR_TEAM_ID" \
    --password "app-specific-password"

# Staple notarization ticket
xcrun stapler staple "ComicsGenerator-1.0.dmg"
```

### Option 4: iOS App Store (iPad)

#### Build for iOS

1. **Select iOS Destination** in Xcode
2. **Product → Archive**
3. **Distribute App → App Store Connect**

#### iOS-Specific Requirements

- App Store screenshots (required sizes: 12.9" iPad Pro, 6.7" iPhone)
- Privacy Policy URL (if collecting data)
- Age rating
- Export Compliance (if using encryption)

#### Submission Checklist

- [ ] App icon (all required sizes)
- [ ] Launch screen
- [ ] Screenshots (iPad and iPhone if universal)
- [ ] App description and keywords
- [ ] Privacy policy (if applicable)
- [ ] Support URL
- [ ] Age rating
- [ ] Pricing and availability
- [ ] TestFlight testing completed
- [ ] App Review information

## Configuration

### API Keys (for AI Chat)

Create a configuration file (not tracked in Git):

```swift
// Sources/ComicsGenerator/Configuration.swift
struct Configuration {
    static let midjourneyAPIKey = "YOUR_MIDJOURNEY_KEY"
    static let openAIAPIKey = "YOUR_OPENAI_KEY"
    static let geminiAPIKey = "YOUR_GEMINI_KEY"
}
```

Or use environment variables:

```bash
export MIDJOURNEY_API_KEY="your-key"
export OPENAI_API_KEY="your-key"
export GEMINI_API_KEY="your-key"
```

### File Storage Location

Default storage location:
- **macOS**: `~/Documents/ComicsGenerator/`
- **iOS**: App's Documents directory (sandboxed)

## Troubleshooting

### Build Errors

**"Cannot find 'Yams' in scope"**
```bash
# Reset package dependencies
swift package reset
swift package resolve
```

**Xcode indexing issues**
```bash
# Clean derived data
rm -rf ~/Library/Developer/Xcode/DerivedData
```

### Runtime Issues

**PDF export fails**
- Verify output directory is writable
- Check available disk space (>100MB recommended)

**Image optimization slow**
- Ensure hardware acceleration is enabled
- Check system RAM (8GB+ recommended for large images)

**AI chat timeout**
- Verify API key is valid
- Check network connectivity
- Increase timeout in AIChatService.swift (default: 60s)

## Contributing

This project follows Test-Driven Development (TDD):

1. Write contract tests first
2. Implement services to make tests pass
3. Write integration tests for workflows
4. Add UI tests for user interactions

See [IMPLEMENTATION_STATUS.md](IMPLEMENTATION_STATUS.md) for current progress.

## Architecture

### Design Principles

1. **Open Standards** (YAML, PNG/JPG, PDF)
2. **Test-First Development** (TDD)
3. **Platform Consistency** (SwiftUI, Apple frameworks)
4. **Performance Targets** (<100ms, <200ms, <50ms)
5. **Simplicity** (Minimal dependencies)

### Data Flow

```
User Input → ViewModel → Service → File System
                ↓
              View (SwiftUI)
```

### File Format

```
Assets/{scope}/{asset-id}/
├── asset.yaml           # YAML metadata
├── prompt.txt           # Auto-exported prompt
├── originals/           # Full resolution
│   └── {uuid}.png
├── optimized/           # 1024px for API
│   └── {uuid}.png
└── .chat/
    └── history.yaml     # Conversation history
```

## License

[Add your license here]

## Support

For issues and feature requests, please use the GitHub issue tracker.

## Acknowledgments

- Built with Swift and SwiftUI
- Uses Yams for YAML parsing
- Follows Apple Human Interface Guidelines
- Constitution-driven development approach

---

**Version**: 1.0.0
**Last Updated**: 2025-10-05
**Minimum OS**: macOS 14.0, iPadOS 17.0

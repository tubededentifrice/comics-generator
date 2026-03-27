# Getting Started with Comics Generator

## 🚀 Quick Start (30 seconds)

```bash
# 1. Clone or open the project folder
cd /Volumes/External/git/comics-generator

# 2. Open in Xcode
open Package.swift

# 3. Wait for package resolution (watch bottom status bar)

# 4. Press ⌘R to build and run
```

That's it! Xcode will handle everything.

## 📋 What You Need

### On Your Mac
- **macOS 14.0+** (Sonoma or later)
- **Xcode 15.0+** (free from App Store)
- **4GB RAM** (8GB recommended)
- **2GB free disk space**

### For App Store Distribution
- **Apple Developer Account** ($99/year)
  - Sign up: https://developer.apple.com/programs/
  - Includes Mac and iOS distribution
  - Code signing certificates
  - App Store Connect access

## 🛠️ Development Setup

### First Time Setup

1. **Install Xcode** (if not already)
   ```bash
   # Check if installed
   xcode-select --version

   # If not installed, download from:
   # Mac App Store → Search "Xcode" → Install
   ```

2. **Install Command Line Tools**
   ```bash
   xcode-select --install
   ```

3. **Open Project**
   ```bash
   cd comics-generator
   open Package.swift
   ```

4. **Build**
   - Xcode will fetch dependencies automatically
   - First build takes 2-3 minutes
   - Subsequent builds are much faster

### Project Structure at a Glance

```
comics-generator/
├── Sources/ComicsGenerator/    # All app code here
│   ├── Models/                 # Data structures
│   ├── Services/               # Business logic
│   ├── ViewModels/             # UI state management
│   └── Views/                  # SwiftUI interfaces
├── Tests/                      # All tests here
├── specs/                      # Feature specifications
├── Package.swift               # Dependencies & config
└── README.md                   # Full documentation
```

## 🧪 Running Tests

### In Xcode
1. Press **⌘U** (Product → Test)
2. Watch test progress in sidebar
3. View results in Report Navigator (⌘9)

### Command Line
```bash
# Run all tests
swift test

# Run specific test file
swift test --filter PDFExportServiceTests

# Run with verbose output
swift test --verbose
```

## 📦 Building for Distribution

### Quick DMG for Testing

```bash
# 1. Build release version
swift build -c release

# 2. Archive in Xcode
#    Product → Archive
#    Wait for completion

# 3. Export app
#    Organizer → Distribute App → Developer ID → Export

# 4. Create DMG (after exporting)
hdiutil create -volname "Comics Generator" \
    -srcfolder "ComicsGenerator.app" \
    -format UDZO "ComicsGenerator.dmg"
```

### App Store Submission

See [BUILD_GUIDE.md](BUILD_GUIDE.md) for detailed steps.

**Quick version**:
1. Xcode → Product → Archive
2. Organizer → Distribute App → App Store Connect
3. Follow wizard (automatic signing)
4. Go to App Store Connect → select build → submit for review

## 🔧 Common Issues & Solutions

### "Cannot find 'Yams' in scope"

**Solution**: Reset package dependencies
```bash
swift package reset
swift package resolve
# Then rebuild in Xcode
```

### "Build failed with exit code 1"

**Solution**: Clean build folder
```bash
# In Xcode
Product → Clean Build Folder (⌘⇧K)

# Or command line
rm -rf .build
swift build
```

### Xcode is slow/unresponsive

**Solution**: Clear derived data
```bash
rm -rf ~/Library/Developer/Xcode/DerivedData
# Restart Xcode
```

### Tests are failing

**Solution**: Check XCTExpectFailure markers
- Some tests use `XCTExpectFailure` for TDD
- These are expected to fail until services fully implemented
- Check test file comments for guidance

## 📱 Platform-Specific Notes

### macOS
- Full feature support
- PDF export works perfectly
- File system access via standard pickers

### iPadOS (iPad)
- Optimized for Apple Pencil
- Touch-friendly interface
- Sandboxed file access
- PDF export supported
- Same codebase as macOS (universal app)

## 🎯 Next Steps

### For Development
1. Read [IMPLEMENTATION_STATUS.md](IMPLEMENTATION_STATUS.md) to see what's done
2. Check `specs/002-new-specs-at/` for feature details
3. Run tests to ensure everything works
4. Make changes to code
5. Run tests again

### For Distribution
1. Read [BUILD_GUIDE.md](BUILD_GUIDE.md) for detailed instructions
2. Choose distribution method:
   - **Mac App Store**: Widest reach, automatic updates
   - **Direct DMG**: Full control, no review process
   - **iOS App Store**: iPad users
3. Get Apple Developer Account ($99/year)
4. Configure code signing
5. Archive and distribute

### For Testing
1. Build in release mode
2. Test on clean macOS install (virtual machine recommended)
3. Test all features:
   - PDF export (albums and pages)
   - Image import (various formats)
   - AI chat (if API keys configured)
4. Check performance (should feel instant)
5. Verify file structure (Assets/ folders)

## 🔑 API Keys (Optional)

For AI chat features, you'll need API keys:

### Midjourney
- Sign up: https://www.midjourney.com
- Get API key from account settings

### OpenAI (DALL-E 3)
- Sign up: https://platform.openai.com
- Generate API key in dashboard

### Google (Gemini)
- Sign up: https://ai.google.dev
- Create API key in console

### Configure Keys

Create `Configuration.swift`:
```swift
// Sources/ComicsGenerator/Configuration.swift
struct Configuration {
    static let midjourneyAPIKey = "your-key-here"
    static let openAIAPIKey = "your-key-here"
    static let geminiAPIKey = "your-key-here"
}
```

**Important**: Add `Configuration.swift` to `.gitignore` to keep keys private.

## 📚 Documentation

- **README.md**: Full documentation, architecture, troubleshooting
- **BUILD_GUIDE.md**: Distribution methods, App Store submission
- **IMPLEMENTATION_STATUS.md**: Current progress, what's done/pending
- **specs/002-new-specs-at/**: Feature specifications, contracts, tests

## 💬 Support

### Issues
- Check existing issues on GitHub
- Search documentation above
- Run `swift test` to verify setup

### Questions
- See README.md for detailed answers
- Check BUILD_GUIDE.md for distribution
- Review specs/ for feature details

## ✅ Pre-Launch Checklist

Before distributing:

- [ ] All tests pass (`swift test`)
- [ ] Build succeeds in Release mode
- [ ] App runs on fresh macOS install
- [ ] PDF export works with test album
- [ ] Image import accepts PNG/JPG
- [ ] UI is responsive (no lag)
- [ ] App icon shows correctly
- [ ] Version number is correct
- [ ] Code signing configured
- [ ] Privacy policy written (if needed)

## 🎉 You're Ready!

You now have everything needed to:
- ✅ Build the app locally
- ✅ Run and modify code
- ✅ Test all features
- ✅ Package for distribution
- ✅ Submit to App Store

**Start developing**: `open Package.swift`

**Need help?** Read [README.md](README.md) for details.

**Ready to ship?** See [BUILD_GUIDE.md](BUILD_GUIDE.md).

---

**Quick Links**
- 📖 [README.md](README.md) - Full documentation
- 🏗️ [BUILD_GUIDE.md](BUILD_GUIDE.md) - Distribution guide
- 📊 [IMPLEMENTATION_STATUS.md](IMPLEMENTATION_STATUS.md) - Current status
- 📋 [specs/002-new-specs-at/](specs/002-new-specs-at/) - Feature specs

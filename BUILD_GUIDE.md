# Comics Generator - Build & Distribution Guide

## Quick Launch on Your Mac

### Option 1: Using Xcode (Recommended)

```bash
# 1. Open the project
open Package.swift

# 2. In Xcode:
#    - Wait for package resolution (bottom status bar)
#    - Select "ComicsGenerator" scheme
#    - Choose "My Mac" as destination
#    - Press ⌘R to build and run
```

### Option 2: Command Line

```bash
# Build the library
swift build

# Run tests
swift test

# Build in release mode
swift build -c release

# The compiled library will be at:
# .build/release/libComicsGenerator.a
```

### Option 3: Create Xcode Project (If Needed)

```bash
# Generate Xcode project
swift package generate-xcodeproj

# Open it
open ComicsGenerator.xcodeproj
```

## Pre-Distribution Checklist

- [ ] All tests pass (`swift test`)
- [ ] Release build succeeds (`swift build -c release`)
- [ ] Code signing configured (for App Store)
- [ ] App icon added (all sizes)
- [ ] Version number updated
- [ ] Privacy policy created (if collecting data)
- [ ] App metadata prepared (description, screenshots, keywords)

## Distribution Methods

### 1. Mac App Store (macOS)

**Best for**: Widest reach, automatic updates, trusted distribution

**Requirements**:
- Apple Developer Account ($99/year)
- Mac App Store certificate
- Sandboxed app (restricted file access)
- App Review approval (1-3 days typical)

**Steps**:

1. **Prepare App Bundle**
   ```bash
   # Open in Xcode
   open Package.swift

   # Product → Archive
   # Wait for archive to complete
   ```

2. **Configure App Store Connect**
   - Go to https://appstoreconnect.apple.com
   - Create new app
   - Fill in metadata:
     - App name: "Comics Generator"
     - Primary category: "Graphics & Design"
     - Subcategory: "Illustration"
     - Price: Free or Paid
   - Upload screenshots (required sizes):
     - 1280 x 800 (MacBook Air)
     - 1920 x 1080 (27" iMac)

3. **Upload Archive**
   - In Xcode Organizer (Window → Organizer)
   - Select archive
   - Click "Distribute App"
   - Choose "App Store Connect"
   - Follow wizard (automatic signing recommended)

4. **Submit for Review**
   - In App Store Connect, select uploaded build
   - Add "What's New" text
   - Submit for review
   - Average review time: 1-3 days

**Cost**: $99/year developer membership

---

### 2. Direct Distribution (DMG)

**Best for**: Beta testers, enterprise users, no App Store restrictions

**Requirements**:
- Developer ID certificate (included in $99/year membership)
- Notarization (automatic malware scan)
- DMG creation tools

**Steps**:

1. **Build Release Version**
   ```bash
   swift build -c release
   ```

2. **Create App Bundle** (requires Xcode project)
   ```bash
   # If starting from Package.swift, create Xcode project first
   swift package generate-xcodeproj
   open ComicsGenerator.xcodeproj

   # Product → Build for → Running
   # Product → Archive
   ```

3. **Export for Developer ID**
   - In Organizer, select archive
   - Click "Distribute App"
   - Choose "Developer ID"
   - Select "Export" (saves .app file)

4. **Create DMG**
   ```bash
   # Create DMG from app bundle
   hdiutil create -volname "Comics Generator" \
       -srcfolder "ComicsGenerator.app" \
       -ov -format UDZO \
       "ComicsGenerator-1.0.dmg"
   ```

5. **Notarize** (Required for macOS 10.15+)
   ```bash
   # Submit for notarization
   xcrun notarytool submit ComicsGenerator-1.0.dmg \
       --apple-id "your@email.com" \
       --team-id "YOUR_TEAM_ID" \
       --password "app-specific-password" \
       --wait

   # Staple ticket to DMG
   xcrun stapler staple "ComicsGenerator-1.0.dmg"
   ```

6. **Distribute**
   - Upload to your website
   - Share via cloud storage
   - No App Store approval needed
   - Users download and drag to Applications

**Cost**: $99/year (for Developer ID signing)

---

### 3. iOS App Store (iPad)

**Best for**: iPad users, touch-optimized experience

**Requirements**:
- Apple Developer Account
- iPad-specific screenshots
- iOS-specific testing

**Steps**:

1. **Build for iOS**
   ```bash
   # Open in Xcode
   open Package.swift

   # Select iOS destination (iPad simulator or device)
   # Product → Archive
   ```

2. **Configure iOS-Specific Settings**
   - Add iPad screenshots (required sizes):
     - 2048 x 2732 (12.9" iPad Pro)
     - 1668 x 2388 (11" iPad Pro)
   - Configure orientation support
   - Add Apple Pencil support metadata

3. **Upload to App Store Connect**
   - Same process as Mac App Store
   - Can use same app record (universal app)
   - Or create separate iPad app

4. **TestFlight Beta** (Optional but recommended)
   - Enable TestFlight in App Store Connect
   - Add up to 10,000 external testers
   - Get feedback before public release

**Cost**: $99/year (same account as macOS)

---

### 4. Open Source / GitHub Releases

**Best for**: Developer community, free distribution

**Steps**:

1. **Tag Release**
   ```bash
   git tag -a v1.0.0 -m "Initial release"
   git push origin v1.0.0
   ```

2. **Create GitHub Release**
   - Go to repository → Releases
   - Click "Draft a new release"
   - Choose tag (v1.0.0)
   - Add release notes
   - Attach built DMG or .app bundle

3. **Provide Build Instructions**
   - Include clear README
   - Document dependencies
   - Provide build scripts

**Cost**: Free

---

## Code Signing

### Get Certificates

1. **Join Apple Developer Program**
   - Go to https://developer.apple.com/programs/
   - Enroll ($99/year)
   - Wait for approval (usually same day)

2. **Download Certificates in Xcode**
   - Xcode → Preferences → Accounts
   - Click your Apple ID
   - Click "Manage Certificates"
   - Click "+" → "Apple Development" (for testing)
   - Click "+" → "Apple Distribution" (for App Store)
   - Click "+" → "Developer ID Application" (for direct distribution)

### Configure Signing

**Automatic (Recommended)**:
- In Xcode project settings → Signing & Capabilities
- Check "Automatically manage signing"
- Select your team
- Xcode handles everything

**Manual**:
```bash
# Sign app bundle
codesign --deep --force --sign "Developer ID Application: Your Name (TEAM_ID)" \
    "ComicsGenerator.app"

# Verify signature
codesign --verify --verbose "ComicsGenerator.app"
spctl --assess --verbose "ComicsGenerator.app"
```

## Versioning

Update version in `Package.swift` and Info.plist:

```swift
// Package.swift
let package = Package(
    name: "ComicsGenerator",
    platforms: [
        .macOS(.v14)
    ],
    // ...
)
```

**Semantic Versioning**:
- Major: Breaking changes (2.0.0)
- Minor: New features (1.1.0)
- Patch: Bug fixes (1.0.1)

## App Store Review Tips

### Common Rejection Reasons

1. **Missing Privacy Policy**: Add URL if collecting any data
2. **Crashes**: Test thoroughly on clean macOS install
3. **Incomplete Metadata**: Fill all required fields
4. **Guideline Violations**: Review App Store Review Guidelines

### Expedite Approval

- Clear, concise app description
- High-quality screenshots showing all features
- Detailed release notes
- Test on multiple Mac models (Intel and Apple Silicon)
- Provide demo account (if login required)

### App Review Information

Provide in App Store Connect:
- Contact information
- Demo account credentials (if needed)
- Notes explaining non-obvious features
- Links to documentation

## Distribution Comparison

| Method | Cost | Review Time | Update Speed | Reach | Control |
|--------|------|-------------|--------------|-------|---------|
| Mac App Store | $99/year | 1-3 days | Automatic | High | Limited |
| Direct (DMG) | $99/year | None | Manual | Medium | Full |
| iOS App Store | $99/year | 1-3 days | Automatic | High | Limited |
| GitHub | Free | None | Manual | Developer | Full |

## Recommended Path

**For Most Users**:
1. Start with **Direct DMG distribution** for beta testing
2. Submit to **Mac App Store** after stability confirmed
3. Add **iOS version** if iPad demand exists

**For Developers/Open Source**:
1. **GitHub releases** with build instructions
2. Optional: Homebrew formula for easy installation
3. Consider App Store for wider reach later

## Support & Updates

### Update Strategy

**App Store**:
- Push updates via App Store Connect
- Users get automatic updates
- Must pass review for each update

**Direct Distribution**:
- Implement auto-update system (e.g., Sparkle framework)
- Or rely on manual user downloads
- No approval process

### Crash Reporting

**App Store**:
- Built-in crash reporting in App Store Connect
- Automatic collection from users who opt-in

**Direct Distribution**:
- Integrate third-party service (Sentry, Crashlytics)
- Or rely on user reports

## Legal Requirements

- [ ] Privacy Policy (if collecting data)
- [ ] Terms of Service (recommended)
- [ ] EULA (optional, App Store has default)
- [ ] Copyright notices
- [ ] Open source license (if applicable)
- [ ] Export compliance (if using encryption)

## Checklist Before Launch

- [ ] All features tested on macOS 14.0+
- [ ] Tests passing (`swift test`)
- [ ] No compiler warnings
- [ ] Code signed with valid certificate
- [ ] App icon in all required sizes
- [ ] Launch screen/splash (iOS)
- [ ] Privacy policy published
- [ ] Support email configured
- [ ] Website or landing page ready
- [ ] Screenshots and marketing materials
- [ ] Pricing decided
- [ ] App Store Connect configured
- [ ] TestFlight testing completed (optional)

---

**Need Help?**
- Apple Developer Support: https://developer.apple.com/contact/
- App Store Connect: https://appstoreconnect.apple.com
- Documentation: https://developer.apple.com/documentation/

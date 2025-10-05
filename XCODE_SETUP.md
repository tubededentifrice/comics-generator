# Xcode Setup Guide

## Overview

The Comics Generator project uses Swift Package Manager (SPM) and includes a demo macOS app that can be launched directly from Xcode.

## Available Schemes

When you open `Package.swift` in Xcode, three schemes are available:

1. **ComicsGenerator** - Builds the library only
2. **ComicsGenerator-Package** - Builds everything (library + tests + app)
3. **ComicsGeneratorApp** - Builds and runs the demo app ⭐

## How to Launch the App in Xcode

### Method 1: Quick Launch (Recommended)

1. Open the project:
   ```bash
   cd comics-generator
   open Package.swift
   ```

2. Wait for package resolution to complete (watch the progress bar)

3. Select the **ComicsGeneratorApp** scheme:
   - Click the scheme selector in the top bar (next to ▶️ button)
   - Choose "ComicsGeneratorApp" from the dropdown
   - Ensure "My Mac" is selected as the destination

4. Click the Run button (▶️) or press **⌘R**

The app will launch showing three tabs for testing library functionality.

### Method 2: Command Line

```bash
# Build and run
swift build
.build/debug/ComicsGeneratorApp
```

### Method 3: Release Build

```bash
# Build optimized version
swift build -c release

# Run release version
.build/release/ComicsGeneratorApp
```

## Xcode Shortcuts

- **⌘R** - Run the app
- **⌘B** - Build only
- **⌘U** - Run tests (all 30 tests)
- **⌘.** - Stop running app
- **⇧⌘K** - Clean build folder
- **⇧⌘O** - Open quickly (file search)

## Project Structure in Xcode

```
ComicsGenerator (Package)
├── Sources
│   ├── ComicsGenerator (Library)
│   │   ├── Models
│   │   ├── Services
│   │   └── ViewModels
│   └── ComicsGeneratorApp (Executable)
│       └── main.swift
├── Tests
│   └── ComicsGeneratorTests
│       ├── Unit
│       └── Integration
└── Dependencies
    └── Yams
```

## Build Configuration

### Debug Build (Default)
- Optimizations: Off
- Assertions: Enabled
- Debug symbols: Full
- Location: `.build/debug/ComicsGeneratorApp`

### Release Build
- Optimizations: On
- Assertions: Disabled
- Debug symbols: Minimal
- Location: `.build/release/ComicsGeneratorApp`

## Troubleshooting

### Product > Run is Greyed Out

**Problem**: Can't click the Run button

**Solutions**:
1. Ensure **ComicsGeneratorApp** scheme is selected (not ComicsGenerator)
2. Select "My Mac" as the run destination
3. Wait for package resolution to complete
4. Try rebuilding: ⌘B

### Package Resolution Fails

**Problem**: "Failed to resolve dependencies"

**Solutions**:
```bash
# Reset and resolve packages
swift package reset
swift package resolve

# Or in Xcode:
# File > Packages > Reset Package Caches
```

### Build Errors

**Problem**: Compile errors about missing types

**Solutions**:
```bash
# Clean build folder
swift package clean

# Remove derived data
rm -rf ~/Library/Developer/Xcode/DerivedData

# Rebuild
swift build
```

### Indexing Stuck

**Problem**: Xcode "Indexing..." never completes

**Solutions**:
1. Close Xcode
2. Delete derived data:
   ```bash
   rm -rf ~/Library/Developer/Xcode/DerivedData
   ```
3. Reopen Xcode
4. Wait for indexing to complete

### App Crashes on Launch

**Problem**: App crashes immediately

**Solutions**:
1. Check Console.app for crash logs
2. Ensure macOS 14.0+ (Sonoma)
3. Try clean build: ⇧⌘K, then ⌘R
4. Run from terminal to see errors:
   ```bash
   .build/debug/ComicsGeneratorApp
   ```

## Running Tests in Xcode

### All Tests
- Select any scheme
- Press **⌘U**
- View results in Test Navigator (⌘6)

### Specific Test Suite
1. Open Test Navigator (⌘6)
2. Hover over test suite name
3. Click the diamond icon to run that suite only

### Single Test
1. Open test file
2. Click the diamond in the gutter next to the test function
3. Or: Place cursor in test function and press **⌃⌥⌘U**

### Test Output
- **Pass**: Green checkmark ✅
- **Fail**: Red X ❌
- **Expected Fail**: Orange diamond (XCTExpectFailure)

Current status: **30 tests passing** ✅

## Debugging in Xcode

### Breakpoints
1. Click in the gutter next to a line number
2. Run the app with ⌘R
3. App will pause at breakpoint

### LLDB Commands
```bash
# Print variable
po variableName

# Continue execution
continue

# Step over
next

# Step into
step

# Step out
finish
```

### View Hierarchy
- While app is running: **Debug > View Debugging > Capture View Hierarchy**
- Shows SwiftUI view tree in 3D

## Performance Profiling

### Instruments
1. Run with **⌘I** (Profile)
2. Choose instrument:
   - **Time Profiler** - CPU usage
   - **Allocations** - Memory usage
   - **Leaks** - Memory leaks
3. Click Record to start profiling

### Performance Tests
```swift
func testOptimizeImage_completesUnder100ms() throws {
    measure {
        try service.optimizeImage(sourceURL: testImageURL, maxDimension: 1024)
    }
}
```

## Distributing Your App

### Archive for Distribution
1. Select "Any Mac" as destination
2. Product > Archive
3. Wait for archive to complete
4. Organizer window opens automatically

### Distribution Options
- **App Store** - Submit to Mac App Store
- **Developer ID** - Distribute outside App Store (notarized)
- **Copy App** - Local testing only

See [README.md](README.md) for detailed distribution instructions.

## Next Steps

1. **Explore the Demo App**: Run and test all three tabs
2. **Read the Code**: Browse Services/ to understand implementations
3. **Run Tests**: Press ⌘U to see all tests pass
4. **Integrate**: Add library to your own project

## Additional Resources

- [README.md](README.md) - Full documentation
- [QUICKSTART.md](QUICKSTART.md) - 5-minute quick start
- [specs/](specs/) - Feature specifications
- [Tests/](Tests/) - Usage examples

---

**Status**: ✅ App launches successfully
**Tests**: ✅ 30/30 passing
**Platform**: macOS 14.0+

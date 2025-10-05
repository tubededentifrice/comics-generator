# Quickstart: PDF Export and AI-Assisted Asset Generation

**Feature**: 002-new-specs-at
**Date**: 2025-10-05
**Purpose**: Executable acceptance tests for validating feature implementation

## Prerequisites

**Test Data Setup**:
```bash
# Create test project structure
cd ~/ComicsGeneratorTestData
mkdir -p "TestSeries/TestAlbum"
mkdir -p "Assets/castle-asset"
mkdir -p "Assets/character-asset"

# Sample images for import testing
cp sample-images/castle-front.png Assets/
cp sample-images/castle-side.png Assets/
cp sample-images/character-ref.jpg Assets/
```

**Test Album Configuration**:
- Series: "TestSeries"
- Album: "TestAlbum"
- Pages: 3 complete pages with drawings
- Assets: "Castle" (2 images), "Character" (1 image)

**Environment**:
- macOS 14.0+ or iPadOS 17.0+
- Xcode 15+ with simulators
- Test API keys configured in Settings (optional for full AI testing)

---

## Scenario 1: Export Album to PDF

**Objective**: Verify complete album export with metadata and 300 DPI rendering

### Steps

1. **Launch Application**
   ```
   Open Comics Generator app
   Navigate to Projects folder
   Open "TestSeries" → "TestAlbum"
   ```

2. **Initiate Export**
   ```
   Click "Export" button in album view toolbar
   Select "Export Album to PDF"
   ```

3. **Configure Export**
   ```
   Verify default settings:
   - Resolution: 300 DPI (displayed, not editable)
   - Include Metadata: ✓ (checked, not editable)
   - Series Name: "TestSeries" (auto-filled)
   - Album Name: "TestAlbum" (auto-filled)
   ```

4. **Choose Destination**
   ```
   System save panel appears
   Navigate to ~/Desktop
   Filename: "TestAlbum.pdf"
   Click "Save"
   ```

5. **Wait for Completion**
   ```
   Progress indicator shows rendering progress
   Completion notification: "PDF exported successfully"
   Estimated time: <600ms for 3 pages
   ```

### Verification

**File Properties**:
```bash
cd ~/Desktop
ls -lh TestAlbum.pdf  # Verify file exists
file TestAlbum.pdf     # Should show "PDF document"
```

**Content Verification** (Manual):
1. Open `TestAlbum.pdf` in Preview.app
2. Verify page count: 3 pages
3. Verify page order matches album order
4. Verify drawings rendered correctly (no distortion)
5. Zoom to 300% → verify no pixelation (300 DPI quality)

**Metadata Verification**:
```bash
mdls TestAlbum.pdf | grep -E "(kMDItemTitle|kMDItemCreator|kMDItemCreationDate)"
# Expected:
# kMDItemTitle = "TestAlbum"
# kMDItemCreator = "TestSeries"
# kMDItemCreationDate = <current date>
```

**Page Numbers**:
- Open PDF, verify page numbers visible on each page
- Expected position: Bottom center or footer
- Format: "Page 1 of 3", "Page 2 of 3", "Page 3 of 3"

### Success Criteria

- [x] PDF file created at specified location
- [x] File size reasonable (1-5MB for 3 pages)
- [x] 3 pages rendered in correct order
- [x] 300 DPI resolution (verified by zoom test)
- [x] Metadata fields populated correctly
- [x] Page numbers visible on all pages
- [x] Export completed in <1 second total

---

## Scenario 2: Export Single Page to PDF

**Objective**: Verify individual page export functionality

### Steps

1. **Open Page Editor**
   ```
   In "TestAlbum", click on Page 2 card
   Page editor opens showing layout and drawings
   ```

2. **Initiate Export**
   ```
   Click "Export" button in page editor toolbar
   Select "Export Page to PDF"
   ```

3. **Save PDF**
   ```
   Save panel appears
   Filename: "TestAlbum-Page2.pdf"
   Save to ~/Desktop
   ```

### Verification

```bash
cd ~/Desktop
open TestAlbum-Page2.pdf
# Verify: Single page only
# Verify: Page number shows "Page 2 of 3" (maintains album context)
```

### Success Criteria

- [x] PDF contains exactly 1 page
- [x] Page matches selected page from album
- [x] Same quality as album export (300 DPI)
- [x] Metadata includes series/album names

---

## Scenario 3: Import External Images to Asset

**Objective**: Verify image import creates dual-resolution storage

### Steps

1. **Open Asset Editor**
   ```
   Navigate to "Assets" → "Global Assets"
   Click on "Castle" asset
   Asset editor opens showing current images (if any)
   ```

2. **Import Images**
   ```
   Click "Import External Images" button
   System file picker appears
   Navigate to ~/ComicsGeneratorTestData/Assets/
   Select files:
     - castle-front.png (2048x1536 px)
     - castle-side.png (1920x1080 px)
   Click "Open"
   ```

3. **Wait for Import**
   ```
   Progress indicator shows "Importing 2 images..."
   Estimated time: <200ms total
   ```

4. **Verify UI Update**
   ```
   Asset editor now shows 2 new images in reference collection
   Each image shows thumbnail + source indicator: "Imported"
   ```

### Verification

**File System Check**:
```bash
cd ~/Documents/ComicsGenerator/Assets/castle-asset
ls -R
# Expected structure:
# originals/
#   abc123.png  (2048x1536, full resolution)
#   def456.png  (1920x1080, full resolution)
# optimized/
#   abc123.png  (1024x768, scaled down)
#   def456.png  (1024x576, scaled down)
```

**Dimension Verification**:
```bash
sips -g pixelWidth -g pixelHeight originals/abc123.png
# Expected: 2048 x 1536

sips -g pixelWidth -g pixelHeight optimized/abc123.png
# Expected: 1024 x 768 (aspect ratio preserved, max dimension = 1024)
```

**Asset JSON Verification**:
```bash
cat asset.json | jq '.originalImages | length'  # Should be 2
cat asset.json | jq '.optimizedImages | length' # Should be 2
cat asset.json | jq '.originalImages[0].source' # Should be "imported"
```

### Success Criteria

- [x] Both images appear in asset editor
- [x] `originals/` folder contains full-resolution files
- [x] `optimized/` folder contains 1024px versions
- [x] Aspect ratios preserved in optimized versions
- [x] `asset.json` updated with ImageReferences
- [x] Source type correctly set to "imported"
- [x] Import completed in <200ms

---

## Scenario 4: AI Chat Asset Generation (Full Flow)

**Objective**: Verify complete AI chat workflow including history persistence

### Steps

1. **Open Chat Interface**
   ```
   Navigate to "Assets" → "Character" asset
   Click "Generate with AI" button
   Chat interface appears as sheet/modal
   ```

2. **Verify Empty State**
   ```
   Chat history area shows: "No messages yet"
   Input field enabled and focused
   "Clear Chat" button disabled (grayed out)
   ```

3. **Upload Reference Image**
   ```
   Click attachment button (📎) or drag character-ref.jpg into chat
   Image thumbnail appears above input field
   "1 image attached" indicator shown
   ```

4. **Send First Message**
   ```
   Type prompt: "Create a comic-style superhero based on this reference"
   Click "Send" button
   ```

5. **Verify User Message**
   ```
   User message bubble appears:
     - Text: "Create a comic-style superhero..."
     - Thumbnail of attached image
     - Timestamp: current time
   Loading indicator appears: "AI is generating..."
   ```

6. **Wait for AI Response**
   ```
   Timeout handling test:
   - If response takes >60s:
     - Dialog appears: "Generation is taking longer than expected"
     - Options: "Keep Waiting" | "Cancel"
     - For test: click "Keep Waiting"

   On success:
   - Loading indicator replaced with assistant message
   - Generated image displayed in message
   - Timestamp shown
   - Estimated time: 10-30 seconds (API-dependent)
   ```

7. **Import Generated Image**
   ```
   Click on generated image in chat
   Context menu appears: "Import to Asset"
   Click "Import to Asset"
   ```

8. **Verify Import**
   ```
   Toast notification: "Image added to asset"
   Generated image now appears in asset editor's reference collection
   Source indicator shows: "Generated"
   ```

9. **Test History Persistence**
   ```
   Click "Done" or dismiss chat sheet
   Return to asset list
   Re-open "Character" asset
   Click "Generate with AI" again
   ```

10. **Verify History Loaded**
    ```
    Chat interface shows previous conversation:
    - User message with attachment
    - Assistant message with generated image
    - Timestamps preserved
    - Can scroll to review
    ```

11. **Test Clear History**
    ```
    Click "Clear Chat" button
    Confirmation dialog: "This will delete all chat history. Continue?"
    Click "Clear"
    ```

12. **Verify Cleared State**
    ```
    Chat history now shows: "No messages yet"
    Previous messages gone
    Can start fresh conversation
    ```

### Verification

**File System Check (After Step 7)**:
```bash
cd ~/Documents/ComicsGenerator/Assets/character-asset

# Chat history file exists
ls -la .chat/history.json
cat .chat/history.json | jq '.messages | length'  # Should be 2 (user + assistant)

# Generated image imported
ls originals/ | grep -c ".*"     # Count increased by 1
ls optimized/ | grep -c ".*"     # Count increased by 1

# Verify source type
cat asset.json | jq '.originalImages[-1].source'  # Should be "generated"
```

**File System Check (After Step 12)**:
```bash
# History file deleted or empty
cat .chat/history.json | jq '.messages | length'  # Should be 0
# OR
ls .chat/history.json  # File not found (both valid)
```

### Success Criteria

- [x] Chat interface opens correctly
- [x] Image upload works via click or drag-drop
- [x] User messages appear immediately
- [x] Loading state shown during AI generation
- [x] Timeout handling works (if applicable)
- [x] Generated images displayed in chat
- [x] Import to asset succeeds
- [x] Generated images marked with correct source
- [x] History persists across navigation
- [x] History loads in <50ms
- [x] Clear history removes all messages
- [x] Chat remains responsive (60fps scroll)

---

## Scenario 5: Incomplete Page PDF Export

**Objective**: Verify handling of pages with missing drawings (blank polygons)

### Steps

1. **Create Incomplete Page**
   ```
   In "TestAlbum", create new page (Page 4)
   Select a layout with 3 polygons
   Leave all polygons blank (no drawings assigned)
   Save page
   ```

2. **Export Album**
   ```
   Return to album view
   Click "Export" → "Export Album to PDF"
   No warning dialog should appear (per FR-077)
   Save as "TestAlbum-Incomplete.pdf"
   ```

### Verification

```bash
open TestAlbum-Incomplete.pdf
# Verify: 4 pages total
# Verify: Page 4 shows layout with blank (white) polygons
# Verify: No errors or corruption
```

### Success Criteria

- [x] Export succeeds without warnings
- [x] Incomplete page included in PDF
- [x] Blank polygons render as white/empty areas
- [x] Layout structure preserved

---

## Performance Validation

### PDF Export Performance

**Test**: Export 10-page album
```bash
time comics-generator-cli export --album TestAlbum10 --output test.pdf
# Expected: <2 seconds total (<200ms per page)
```

**Measurement**:
- Use Xcode Instruments "Time Profiler"
- Track `PDFExportService.exportAlbum` method
- Verify no main thread blocking >16ms

### Image Optimization Performance

**Test**: Import 10 high-resolution images (4K)
```bash
time comics-generator-cli import --asset TestAsset --images *.png
# Expected: <1 second total (<100ms per image)
```

**Measurement**:
- Profile `ImageOptimizationService.optimizeImage`
- Verify GPU acceleration used (CoreImage)

### Chat History Loading Performance

**Test**: Load chat with 100 messages
```bash
# Create synthetic history.json with 100 messages
python generate_test_history.py --count 100

# Measure load time
time comics-generator-cli chat load --asset TestAsset
# Expected: <50ms
```

**Measurement**:
- Profile `AIChatService.loadHistory`
- Verify JSON decoding completes in target time

---

## Rollback Procedure

If feature fails validation, rollback steps:

1. **Revert Code**:
   ```bash
   git checkout main
   git branch -D 002-new-specs-at
   ```

2. **Restore Data** (if migrations ran):
   ```bash
   cd ~/Documents/ComicsGenerator
   rm -rf */*/optimized   # Remove optimized folders
   rm -rf */*/.chat       # Remove chat histories
   # Restore from backup if needed
   ```

3. **Clean Build**:
   ```bash
   cd ComicsGenerator.xcodeproj
   xcodebuild clean
   ```

---

## References

- Feature Specification: [spec.md](./spec.md)
- Implementation Plan: [plan.md](./plan.md)
- Contracts: [contracts/](./contracts/)
- Data Model: [data-model.md](./data-model.md)

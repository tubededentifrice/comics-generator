# Tasks: PDF Export and AI-Assisted Asset Generation

**Input**: Design documents from `/Volumes/External/git/comics-generator/specs/002-new-specs-at/`
**Prerequisites**: plan.md, data-model.md, contracts/, quickstart.md, research.md
**Tech Stack**: Swift 5.9+, SwiftUI, PDFKit, CoreImage, XCTest
**Target**: macOS 14.0+, iPadOS 17.0+

## Format: `[ID] [P?] Description`
- **[P]**: Can run in parallel (different files, no dependencies)
- All file paths are absolute from repository root

## Phase 3.1: Setup & Model Enhancements

**T001** Create folder structure for new models, services, views, and tests
- Create `ComicsGenerator/Models/` subdirectories if missing
- Create `ComicsGenerator/Services/` subdirectories if missing
- Create `ComicsGenerator/Views/` subdirectories if missing
- Create `ComicsGenerator/ViewModels/` subdirectories if missing
- Create `ComicsGeneratorTests/Unit/`, `Integration/`, `UI/` subdirectories

**T002** [P] Enhance Asset model with chat history and dual-image storage
- File: `ComicsGenerator/Models/Asset.swift`
- Add `originalImages: [ImageReference]` property
- Add `optimizedImages: [ImageReference]` property
- Add `chatHistoryPath: URL?` property
- Add `createdAt: Date` and `updatedAt: Date` properties
- Update Codable conformance
- Add validation: `originalImages.count == optimizedImages.count`
- Migration logic: convert old `images: [URL]` to new dual-storage format

**T003** [P] Create ImageReference model
- File: `ComicsGenerator/Models/ImageReference.swift`
- Properties: `id: UUID`, `url: URL`, `dimensions: CGSize`, `source: ImageSource`, `type: ImageVersionType`, `createdAt: Date`
- Enums: `ImageSource` (imported/generated), `ImageVersionType` (original/optimized)
- Codable conformance
- Validation: optimized images max 1024px in longest dimension

**T004** [P] Create ChatMessage model
- File: `ComicsGenerator/Models/ChatMessage.swift`
- Properties: `id: UUID`, `role: MessageRole`, `text: String`, `attachedImages: [URL]`, `generatedImages: [URL]`, `timestamp: Date`
- Enum: `MessageRole` (user/assistant)
- Codable conformance
- Validation rules per data-model.md (user/assistant constraints)

**T005** [P] Create PDFExportOptions model
- File: `ComicsGenerator/Models/PDFExportOptions.swift`
- Properties: `resolution: Int`, `includeMetadata: Bool`, `seriesName: String`, `albumName: String`, `pageRange: PageRange`, `outputURL: URL`
- Enum: `PageRange` (all, single(pageIndex: Int))
- Defaults: resolution=300, includeMetadata=true
- Validation: outputURL must be writable

## Phase 3.2: Contract Tests (TDD) ⚠️ MUST COMPLETE BEFORE 3.3

**CRITICAL: These tests MUST be written and MUST FAIL before ANY implementation**

**T006** [P] Contract test for PDFExportService.exportAlbum
- File: `ComicsGeneratorTests/Unit/PDFExportServiceTests.swift`
- Test: `testExportAlbum_withValidAlbum_createsFile()`
- Test: `testExportAlbum_withEmptyAlbum_throwsInvalidAlbumError()`
- Test: `testExportAlbum_withInvalidOutputURL_throwsWriteError()`
- Test: `testExportAlbum_includes300DPI_metadata()`
- Assert all tests FAIL (service not implemented yet)
- Follow contract in `contracts/pdf-export.json`

**T007** [P] Contract test for PDFExportService.exportPage
- File: `ComicsGeneratorTests/Unit/PDFExportServiceTests.swift` (add to existing)
- Test: `testExportPage_withValidPage_createsFile()`
- Test: `testExportPage_withNoLayout_throwsInvalidPageError()`
- Test: `testExportPage_rendersAtCorrectDPI()`
- Assert all tests FAIL

**T008** [P] Contract test for AssetImportService.importImages
- File: `ComicsGeneratorTests/Unit/AssetImportServiceTests.swift`
- Test: `testImportImages_createsOriginalAndOptimizedVersions()`
- Test: `testImportImages_unsupportedFormat_throwsError()`
- Test: `testImportImages_assetFull_throwsError()`
- Test: `testImportImages_updatesAssetJSON()`
- Assert all tests FAIL
- Follow contract in `contracts/asset-import.json`

**T009** [P] Contract test for AssetImportService.optimizeImage
- File: `ComicsGeneratorTests/Unit/ImageOptimizationServiceTests.swift`
- Test: `testOptimizeImage_scalesTo1024px_preservesAspectRatio()`
- Test: `testOptimizeImage_handlesLandscapeAndPortrait()`
- Test: `testOptimizeImage_invalidSource_throwsError()`
- Test: `testOptimizeImage_completesUnder100ms()`
- Assert all tests FAIL

**T010** [P] Contract test for AIChatService.sendMessage
- File: `ComicsGeneratorTests/Unit/AIChatServiceTests.swift`
- Test: `testSendMessage_noAPIKey_throwsError()`
- Test: `testSendMessage_timeout_throwsAfter60Seconds()`
- Test: `testSendMessage_usesOptimizedImages()`
- Test: `testSendMessage_returnsAssistantMessage()`
- Assert all tests FAIL
- Follow contract in `contracts/ai-chat.json`

**T011** [P] Contract test for AIChatService history methods
- File: `ComicsGeneratorTests/Unit/AIChatServiceTests.swift` (add to existing)
- Test: `testLoadHistory_emptyFile_returnsEmptyArray()`
- Test: `testSaveHistory_writesJSON_atomically()`
- Test: `testClearHistory_deletesFile_idempotent()`
- Test: `testLoadHistory_completesUnder50ms_for100Messages()`
- Assert all tests FAIL

## Phase 3.3: Core Service Implementation (ONLY after tests are failing)

**T012** Implement ImageOptimizationService.optimizeImage
- File: `ComicsGenerator/Services/ImageOptimizationService.swift`
- Use CoreImage CILanczosScaleTransform filter
- Scale to 1024px max dimension, preserve aspect ratio
- Input: source URL, output: optimized URL
- Target: <100ms per image
- Make tests T009 PASS

**T013** Implement AssetImportService.importImages
- File: `ComicsGenerator/Services/AssetImportService.swift`
- Copy images to `originals/` folder
- Call ImageOptimizationService for each image
- Save optimized to `optimized/` folder
- Update Asset model with dual ImageReferences
- Support: PNG, JPG, JPEG, HEIC, SVG
- Make tests T008 PASS

**T014** Implement AssetImportService.removeImage
- File: `ComicsGenerator/Services/AssetImportService.swift` (add to existing)
- Delete both original and optimized files
- Remove from Asset.originalImages and Asset.optimizedImages
- Update Asset.updatedAt timestamp
- Handle cascade deletion

**T015** Implement PDFExportService.exportAlbum
- File: `ComicsGenerator/Services/PDFExportService.swift`
- Use PDFKit PDFDocument API
- Render pages at 300 DPI (scale factor 300/72)
- Add metadata: series name, album name, creation date
- Render page numbers on each page (footer center)
- Include incomplete pages with blank polygons (per FR-077)
- Off main thread execution
- Target: <200ms per page
- Make tests T006 PASS

**T016** Implement PDFExportService.exportPage
- File: `ComicsGenerator/Services/PDFExportService.swift` (add to existing)
- Single-page PDF generation
- Same 300 DPI and metadata logic as exportAlbum
- Page number shows album context (e.g., "Page 2 of 5")
- Make tests T007 PASS

**T017** Implement AIChatService.sendMessage
- File: `ComicsGenerator/Services/AIChatService.swift`
- Support 3 providers: Midjourney, DALL-E 3, Gemini 2.5 Flash Image
- Use optimized image versions (1024px) for API calls
- URLSession for HTTP requests (no third-party libraries)
- 60-second timeout with "Keep Waiting"/"Cancel" dialog (per FR-102)
- Return ChatMessage with generatedImages array
- Make tests T010 PASS

**T018** Implement AIChatService history persistence methods
- File: `ComicsGenerator/Services/AIChatService.swift` (add to existing)
- `loadHistory`: Read `.chat/history.json`, decode to [ChatMessage]
- `saveHistory`: Atomic write (temp file + move), pretty-printed JSON
- `clearHistory`: Delete history.json, set chatHistoryPath = nil
- Create `.chat/` directory if missing
- Target: <50ms for 100 messages
- Make tests T011 PASS

**T019** Implement AIChatService.importGeneratedImage
- File: `ComicsGenerator/Services/AIChatService.swift` (add to existing)
- Copy generated image from chat cache to asset originals/
- Call ImageOptimizationService to create optimized version
- Add to Asset with `source: .generated`
- Update Asset.updatedAt

## Phase 3.4: Integration Tests (Validate end-to-end workflows)

**T020** [P] Integration test: Export album to PDF (Quickstart Scenario 1)
- File: `ComicsGeneratorTests/Integration/PDFExportIntegrationTests.swift`
- Create test album with 3 pages
- Call PDFExportService.exportAlbum
- Verify: PDF file exists, 3 pages, 300 DPI, metadata fields populated
- Verify: Page numbers visible on all pages
- Verify: Incomplete pages render with blank polygons
- Follow quickstart.md Scenario 1

**T021** [P] Integration test: Import images to asset (Quickstart Scenario 3)
- File: `ComicsGeneratorTests/Integration/AssetImportIntegrationTests.swift`
- Create test asset
- Import 2 sample images (PNG, JPG)
- Verify: `originals/` and `optimized/` folders contain files
- Verify: Optimized versions max 1024px
- Verify: asset.json updated with ImageReferences
- Follow quickstart.md Scenario 3

**T022** [P] Integration test: AI chat persistence (Quickstart Scenario 4)
- File: `ComicsGeneratorTests/Integration/AIChatPersistenceTests.swift`
- Create asset, send 5 chat messages (mocked AI responses)
- Save history
- Verify: `.chat/history.json` exists and valid
- Load history in new session
- Verify: All 5 messages loaded correctly
- Clear history, verify: file deleted or empty
- Follow quickstart.md Scenario 4

**T023** Integration test: Dual-image consistency
- File: `ComicsGeneratorTests/Integration/AssetImportIntegrationTests.swift` (add to existing)
- Import 10 images of varying sizes (512px to 4096px)
- Verify: originalImages.count == optimizedImages.count == 10
- Verify: All optimized images <= 1024px max dimension
- Verify: Aspect ratios preserved
- Delete 1 original, verify: corresponding optimized also deleted

## Phase 3.5: ViewModels & UI Implementation

**T024** [P] Implement PDFExportViewModel
- File: `ComicsGenerator/ViewModels/PDFExportViewModel.swift`
- ObservableObject with @Published properties
- Properties: `isExporting: Bool`, `progress: Double`, `errorMessage: String?`
- Methods: `exportAlbum(Album, URL)`, `exportPage(Page, URL)`
- Call PDFExportService, update UI state
- Handle errors with user-friendly messages

**T025** [P] Implement AssetImportViewModel
- File: `ComicsGenerator/ViewModels/AssetImportViewModel.swift`
- ObservableObject with @Published properties
- Properties: `isImporting: Bool`, `importedCount: Int`, `errorMessage: String?`
- Method: `importImages([URL], Asset)`
- Call AssetImportService, update UI state
- Show progress for batch imports

**T026** [P] Implement AIChatViewModel
- File: `ComicsGenerator/ViewModels/AIChatViewModel.swift`
- ObservableObject with @Published properties
- Properties: `messages: [ChatMessage]`, `inputText: String`, `isGenerating: Bool`, `errorMessage: String?`
- Methods: `sendMessage()`, `loadHistory(Asset)`, `saveHistory(Asset)`, `clearHistory(Asset)`, `importImage(URL, Asset)`
- Call AIChatService, update UI in real-time
- Handle 60s timeout with dialog

**T027** Create PDFExportView (SwiftUI)
- File: `ComicsGenerator/Views/PDFExportView.swift`
- Sheet presentation with export options
- Display: series name, album name (auto-filled)
- Display: resolution (300 DPI, read-only)
- Button: "Export" → triggers save panel
- Progress indicator during export
- Toolbar placement per Apple HIG

**T028** Enhance AssetEditorView with import/chat buttons
- File: `ComicsGenerator/Views/AssetEditorView.swift`
- Add "Import External Images" button (file picker trigger)
- Add "Generate with AI" button (opens AIChatView sheet)
- Display asset images with source indicators (imported/generated)
- Thumbnail grid with delete action per image

**T029** Create AIChatView (SwiftUI)
- File: `ComicsGenerator/Views/AIChatView.swift`
- Sheet presentation with full-screen chat interface
- ScrollView with LazyVStack for message bubbles
- User messages: right-aligned, blue bubbles
- Assistant messages: left-aligned, gray bubbles, generated images displayed
- Input field with attachment button (image upload)
- Loading indicator: "AI is generating..."
- Toolbar: "Clear Chat" button with confirmation dialog
- Auto-scroll to bottom on new messages

**T030** [P] Create ImageSourceIndicatorView component
- File: `ComicsGenerator/Views/ImageSourceIndicator.swift`
- Small badge overlay showing "Imported" or "Generated"
- Color-coded: green for imported, blue for generated
- Accessible label for VoiceOver

## Phase 3.6: UI Tests (Validate user interactions)

**T031** [P] UI test: Export album workflow
- File: `ComicsGeneratorTests/UI/PDFExportUITests.swift`
- Launch app, navigate to album
- Tap "Export" → "Export Album to PDF"
- Verify: Save panel appears
- Enter filename, tap "Save"
- Verify: Success notification shown
- Assert: PDF file created at chosen location

**T032** [P] UI test: AI chat interaction flow
- File: `ComicsGeneratorTests/UI/AIChatUITests.swift`
- Open asset editor
- Tap "Generate with AI"
- Verify: Chat sheet appears
- Upload image via button
- Type message, tap "Send"
- Verify: User message appears
- Mock AI response
- Verify: Assistant message with image appears
- Tap generated image
- Verify: "Import to Asset" action shown
- Tap import
- Verify: Image added to asset editor

## Phase 3.7: Polish & Performance

**T033** [P] Performance test: PDF rendering at 300 DPI
- File: `ComicsGeneratorTests/Integration/PDFExportIntegrationTests.swift` (add to existing)
- Export 10-page album
- Measure: XCTest performance metrics
- Assert: Average <200ms per page
- Assert: Total export <2 seconds
- Assert: Memory usage <500MB

**T034** [P] Performance test: Image optimization batch
- File: `ComicsGeneratorTests/Unit/ImageOptimizationServiceTests.swift` (add to existing)
- Import 10 images (2048px - 4096px)
- Measure: Time for batch completion
- Assert: Average <100ms per image
- Assert: Aspect ratios preserved

**T035** [P] Performance test: Chat history loading
- File: `ComicsGeneratorTests/Unit/AIChatServiceTests.swift` (add to existing)
- Generate synthetic history.json with 100 messages
- Measure: loadHistory() execution time
- Assert: <50ms total
- Assert: Messages sorted by timestamp

**T036** Error handling: Missing API key
- File: `ComicsGenerator/Services/AIChatService.swift` (enhance existing)
- When sendMessage() called without API key configured
- Show clear error: "No API key configured for [provider]"
- Add link to Settings (per FR-043a)
- Add test case to AIChatServiceTests

**T037** Error handling: File system errors
- Files: All services (PDFExportService, AssetImportService, AIChatService)
- Handle: Insufficient permissions, disk full, corrupt files
- Display user-friendly error messages
- Log technical details for debugging
- Add test cases for each error type

**T038** Accessibility: VoiceOver support
- Files: All Views (PDFExportView, AIChatView, AssetEditorView)
- Add `.accessibilityLabel()` to all interactive elements
- Add `.accessibilityHint()` for non-obvious actions
- Test with VoiceOver enabled on iOS simulator
- Verify: Tab order logical, all content readable

**T039** Update quickstart.md with actual file paths
- File: `specs/002-new-specs-at/quickstart.md`
- Replace placeholder paths with real Xcode project paths
- Add CLI test commands if applicable
- Add screenshot capture instructions

**T040** Run full quickstart validation
- File: Manual execution of `specs/002-new-specs-at/quickstart.md`
- Execute all 5 scenarios manually
- Verify: All success criteria met
- Document any deviations or issues
- Create bug tickets if needed

## Dependencies

**Setup blocks everything**: T001 → all other tasks

**Tests block implementation**:
- T006, T007 → T015, T016 (PDF tests → PDF implementation)
- T008, T009 → T012, T013, T014 (Import tests → Import implementation)
- T010, T011 → T017, T018, T019 (Chat tests → Chat implementation)

**Models block services**:
- T002, T003, T004, T005 → T012-T019 (Models → Services)

**Services block ViewModels**:
- T012-T019 → T024-T026 (Services → ViewModels)

**ViewModels block Views**:
- T024-T026 → T027-T030 (ViewModels → Views)

**Views block UI tests**:
- T027-T030 → T031, T032 (Views → UI tests)

**Integration tests require services**:
- T015, T016 → T020 (PDF service → PDF integration test)
- T013, T014 → T021, T023 (Import service → Import integration tests)
- T018 → T022 (Chat persistence → Chat integration test)

**Polish requires everything**:
- All implementation tasks → T033-T040 (Polish phase)

## Parallel Execution Examples

**Phase 3.1 (Models)**: Run T002-T005 in parallel
```bash
# All create different files, no dependencies
Task: "Enhance Asset model in ComicsGenerator/Models/Asset.swift"
Task: "Create ImageReference model in ComicsGenerator/Models/ImageReference.swift"
Task: "Create ChatMessage model in ComicsGenerator/Models/ChatMessage.swift"
Task: "Create PDFExportOptions model in ComicsGenerator/Models/PDFExportOptions.swift"
```

**Phase 3.2 (Contract Tests)**: Run T006-T011 in parallel
```bash
# All create different test files
Task: "Contract test PDFExportService.exportAlbum in ComicsGeneratorTests/Unit/PDFExportServiceTests.swift"
Task: "Contract test AssetImportService.importImages in ComicsGeneratorTests/Unit/AssetImportServiceTests.swift"
Task: "Contract test ImageOptimizationService in ComicsGeneratorTests/Unit/ImageOptimizationServiceTests.swift"
Task: "Contract test AIChatService.sendMessage in ComicsGeneratorTests/Unit/AIChatServiceTests.swift"
```

**Phase 3.4 (Integration Tests)**: Run T020-T023 in parallel
```bash
# Different test files, independent scenarios
Task: "Integration test PDF export in ComicsGeneratorTests/Integration/PDFExportIntegrationTests.swift"
Task: "Integration test asset import in ComicsGeneratorTests/Integration/AssetImportIntegrationTests.swift"
Task: "Integration test chat persistence in ComicsGeneratorTests/Integration/AIChatPersistenceTests.swift"
```

**Phase 3.5 (ViewModels)**: Run T024-T026 in parallel
```bash
# Different ViewModel files
Task: "Implement PDFExportViewModel in ComicsGenerator/ViewModels/PDFExportViewModel.swift"
Task: "Implement AssetImportViewModel in ComicsGenerator/ViewModels/AssetImportViewModel.swift"
Task: "Implement AIChatViewModel in ComicsGenerator/ViewModels/AIChatViewModel.swift"
```

## Notes

- **[P] marker**: Tasks can run in parallel because they modify different files
- **TDD discipline**: All contract tests (T006-T011) MUST be written and failing before implementation (T012-T019)
- **Commit strategy**: Commit after each task completes (atomic changes)
- **Test coverage**: Target 80%+ coverage for services and view models
- **Performance validation**: T033-T035 must pass constitutional targets (300 DPI, <200ms, <100ms, <50ms)
- **Quickstart execution**: T040 is manual validation of all acceptance scenarios

## Validation Checklist

- [x] All 3 contracts have corresponding tests (T006-T011)
- [x] All 4 entities have model tasks (T002-T005)
- [x] All tests come before implementation (T006-T011 → T012-T019)
- [x] Parallel tasks truly independent (different files, verified)
- [x] Each task specifies exact file path
- [x] No task modifies same file as another [P] task
- [x] Constitutional requirements covered (TDD, performance, open standards)
- [x] Quickstart scenarios mapped to integration tests (T020-T023)

**Total Tasks**: 40 (Setup: 5, Tests: 6, Services: 8, Integration: 4, UI: 7, Polish: 8, Validation: 2)

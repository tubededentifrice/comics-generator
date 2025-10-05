# Implementation Plan: PDF Export and AI-Assisted Asset Generation

**Branch**: `002-new-specs-at` | **Date**: 2025-10-05 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/Volumes/External/git/comics-generator/specs/002-new-specs-at/spec.md`

## Summary

This feature adds two major capabilities to the Comics Generator application:

1. **PDF Export**: Enables users to export albums or individual pages as publication-quality PDF files (300 DPI) with full metadata (series name, album name, page numbers, creation date). Incomplete pages are included with blank polygons.

2. **AI-Assisted Asset Generation**: Provides an interactive chat interface within the asset editor, allowing users to upload reference images, iteratively refine generations through conversation, and import results directly into assets. Images are stored in dual formats (original + 1024px optimized for API). Chat history is preserved indefinitely per asset.

## Technical Context

**Language/Version**: Swift 5.9+
**Primary Dependencies**: SwiftUI, UIKit (PKCanvasView), PDFKit, Foundation, CoreImage
**Storage**: File-based JSON/PNG/SVG (per Constitution Principle I)
**Testing**: XCTest (unit, UI, integration, performance)
**Target Platform**: macOS 14.0+, iPadOS 17.0+
**Project Type**: Mobile (single codebase for macOS/iPadOS)
**Performance Goals**: UI 60fps (16ms), file ops <200ms, <500MB memory
**Constraints**: 300 DPI PDF rendering, <20ms Apple Pencil latency, 1024px image optimization
**Scale/Scope**: Per-user app with file-based storage, no server infrastructure

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

### Principle I: Open Standards & Portability
- ✅ **PASS**: PDF uses standard format, images stored as PNG/JPG, chat history as JSON
- ✅ **PASS**: Dual image storage (original + optimized) maintains archival quality
- ✅ **PASS**: All data remains Git-compatible and human-reviewable

### Principle II: First-Class Stylus Support
- ✅ **PASS**: Feature doesn't modify existing pencil workflows
- ℹ️ **N/A**: PDF export and asset import don't involve pencil interaction

### Principle III: Platform Consistency & Universal Codebase
- ✅ **PASS**: SwiftUI-based UI works identically on macOS/iPadOS
- ✅ **PASS**: File picker, PDF export, image processing use platform-standard APIs

### Principle IV: Test-First Development (NON-NEGOTIABLE)
- ✅ **PASS**: Plan includes contract tests, integration tests, quickstart validation
- ✅ **PASS**: Tests will be written before implementation per TDD discipline

### Principle V: Performance Targets
- ✅ **PASS**: PDF rendering targets <200ms for typical albums
- ✅ **PASS**: Image optimization happens once at import (not runtime)
- ⚠️ **MONITOR**: Chat UI must maintain 60fps during message display

### Principle VI: Code Quality & Simplicity
- ✅ **PASS**: PDFKit is Apple framework (justified for PDF generation complexity)
- ✅ **PASS**: CoreImage for image resizing is standard library
- ✅ **PASS**: No new external dependencies required

### Principle VII: User Experience Consistency
- ✅ **PASS**: System file picker follows Apple HIG
- ✅ **PASS**: Chat interface uses standard SwiftUI patterns
- ✅ **PASS**: Export workflow follows standard save panel conventions

**Initial Assessment**: ✅ **ALL CHECKS PASS** - No constitutional violations

## Project Structure

### Documentation (this feature)
```
specs/002-new-specs-at/
├── plan.md              # This file
├── spec.md              # Feature specification
├── research.md          # Phase 0 output (research decisions)
├── data-model.md        # Phase 1 output (entity definitions)
├── quickstart.md        # Phase 1 output (acceptance test scenarios)
└── contracts/           # Phase 1 output (API contracts)
    ├── pdf-export.json
    ├── asset-import.json
    └── ai-chat.json
```

### Source Code (repository root)
```
ComicsGenerator/
├── Models/
│   ├── Asset.swift           # Enhanced with chat history + dual images
│   ├── PDFExportOptions.swift
│   ├── ChatMessage.swift
│   └── ImageVersion.swift
├── Services/
│   ├── PDFExportService.swift
│   ├── AssetImportService.swift
│   ├── ImageOptimizationService.swift
│   └── AIChatService.swift
├── Views/
│   ├── PDFExportView.swift
│   ├── AssetEditorView.swift  # Enhanced with import/chat buttons
│   ├── AIChatView.swift
│   └── ImageSourceIndicator.swift
└── ViewModels/
    ├── PDFExportViewModel.swift
    ├── AssetImportViewModel.swift
    └── AIChatViewModel.swift

ComicsGeneratorTests/
├── Unit/
│   ├── PDFExportServiceTests.swift
│   ├── ImageOptimizationServiceTests.swift
│   └── AIChatServiceTests.swift
├── Integration/
│   ├── PDFExportIntegrationTests.swift
│   ├── AssetImportIntegrationTests.swift
│   └── AIChatPersistenceTests.swift
└── UI/
    ├── PDFExportUITests.swift
    └── AIChatUITests.swift
```

**Structure Decision**: Single project structure (Option 1) as this is a unified macOS/iPadOS app. SwiftUI provides cross-platform UI, with UIKit interop for file pickers and PDF rendering. All source in `ComicsGenerator/` target, tests in `ComicsGeneratorTests/` target.

## Phase 0: Outline & Research

No NEEDS CLARIFICATION markers remain in spec—all critical decisions resolved via /clarify session.

### Research Topics

1. **PDF Generation with Metadata**
   - **Decision**: Use PDFKit's PDFDocument API
   - **Rationale**: Native Apple framework, supports 300 DPI rendering, metadata embedding, page-by-page composition
   - **Alternatives Considered**: Core Graphics PDF context (lower-level, more complex), third-party libs (violates Principle VI)

2. **Image Optimization Strategy**
   - **Decision**: Use CoreImage for aspect-ratio-preserving resize to 1024px
   - **Rationale**: Hardware-accelerated, maintains quality, standard library
   - **Alternatives Considered**: vImage (more complex API), UIGraphicsImageRenderer (deprecated)

3. **Chat History Persistence**
   - **Decision**: JSON file per asset in `.chat/` subfolder
   - **Rationale**: Human-readable, Git-friendly, simple to implement
   - **Alternatives Considered**: SQLite (overkill), embedded in asset JSON (bloats file)

4. **Dual Image Storage Layout**
   - **Decision**: `asset-id/originals/` and `asset-id/optimized/` subdirectories
   - **Rationale**: Clear separation, easy cleanup, obvious archival vs. API purpose
   - **Alternatives Considered**: Suffixed filenames (less clear), single copy with on-demand resize (slower)

5. **AI Chat UI Pattern**
   - **Decision**: Sheet presentation with ScrollView + message bubbles
   - **Rationale**: Standard iOS/macOS pattern, familiar UX, accessibility-friendly
   - **Alternatives Considered**: Popover (too small on iPad), inline panel (clutters asset editor)

**Output**: research.md (will be generated next)

## Phase 1: Design & Contracts

### Data Model Entities

**Asset** (enhanced):
- `id: UUID`
- `name: String`
- `scope: AssetScope` (root/series/album)
- `promptText: String`
- `originalImages: [ImageReference]` - full resolution
- `optimizedImages: [ImageReference]` - 1024px max
- `chatHistoryPath: URL?` - path to .chat JSON file

**ChatMessage**:
- `id: UUID`
- `role: MessageRole` (user/assistant)
- `text: String`
- `attachedImages: [URL]` - user-uploaded images
- `generatedImages: [URL]` - AI-generated results
- `timestamp: Date`

**PDFExportOptions**:
- `resolution: Int` (300 DPI)
- `includeMetadata: Bool` (true)
- `seriesName: String`
- `albumName: String`
- `pageRange: PageRange` (all/single)

**ImageVersion**:
- `type: ImageVersionType` (original/optimized)
- `url: URL`
- `dimensions: CGSize`
- `source: ImageSource` (imported/generated)

### API Contracts

*(Note: These are internal service contracts, not REST endpoints)*

**PDFExportService Contract**:
```json
{
  "exportAlbum": {
    "input": {
      "album": "Album",
      "options": "PDFExportOptions"
    },
    "output": "URL",
    "throws": "PDFExportError"
  },
  "exportPage": {
    "input": {
      "page": "Page",
      "options": "PDFExportOptions"
    },
    "output": "URL",
    "throws": "PDFExportError"
  }
}
```

**AssetImportService Contract**:
```json
{
  "importImages": {
    "input": {
      "imageURLs": "[URL]",
      "asset": "Asset"
    },
    "output": "[ImageReference]",
    "throws": "AssetImportError"
  },
  "optimizeImage": {
    "input": {
      "sourceURL": "URL",
      "maxDimension": "Int"
    },
    "output": "URL",
    "throws": "ImageOptimizationError"
  }
}
```

**AIChatService Contract**:
```json
{
  "sendMessage": {
    "input": {
      "text": "String",
      "images": "[URL]",
      "provider": "AIProvider"
    },
    "output": "ChatMessage",
    "throws": "AIChatError"
  },
  "loadHistory": {
    "input": {
      "asset": "Asset"
    },
    "output": "[ChatMessage]",
    "throws": "ChatHistoryError"
  },
  "saveHistory": {
    "input": {
      "messages": "[ChatMessage]",
      "asset": "Asset"
    },
    "output": "Void",
    "throws": "ChatHistoryError"
  },
  "clearHistory": {
    "input": {
      "asset": "Asset"
    },
    "output": "Void",
    "throws": "ChatHistoryError"
  }
}
```

### Quickstart Scenarios

1. **Export Album to PDF**:
   - Open album "Test Album" with 3 pages
   - Select "Export to PDF"
   - Verify file saved at chosen location
   - Open PDF and verify: 300 DPI, 3 pages in order, metadata present, page numbers visible

2. **Import Images to Asset**:
   - Open asset editor for "Castle" asset
   - Select "Import External Images"
   - Choose 2 PNG files (castle-front.png, castle-side.png)
   - Verify both images appear in reference collection
   - Verify `originals/` and `optimized/` subdirectories contain files
   - Verify optimized versions are max 1024px in longest dimension

3. **AI Chat Asset Generation**:
   - Open asset editor for "Character" asset
   - Select "Generate with AI"
   - Upload reference image + prompt "Create comic-style character"
   - Verify chat displays message
   - Wait for AI response
   - Click generated image → "Import to Asset"
   - Verify image added to asset's reference collection
   - Navigate away and return
   - Verify chat history preserved

**Output**: data-model.md, contracts/, quickstart.md (will be generated next)

## Phase 2: Task Planning Approach

*This section describes what the /tasks command will do - DO NOT execute during /plan*

**Task Generation Strategy**:
- Phase 1 artifacts (data-model.md, contracts/, quickstart.md) → tasks
- Each service contract → contract test + implementation task
- Each entity → model definition + validation tests
- Each quickstart scenario → integration test
- UI components → UI tests for acceptance scenarios

**Ordering Strategy**:
1. **Setup**: Enhance Asset model with chat history fields [P]
2. **Tests**: Write contract tests for all 3 services [P]
3. **Core**: Implement ImageOptimizationService [P], PDFExportService, AIChatService
4. **Integration**: File persistence, chat history storage
5. **UI**: PDFExportView, AssetImportButton, AIChatView [P]
6. **Polish**: Error handling, loading states, quickstart validation

**Estimated Output**: 18-22 tasks in tasks.md

**IMPORTANT**: This phase is executed by the /tasks command, NOT by /plan

## Phase 3+: Future Implementation

*These phases are beyond the scope of the /plan command*

**Phase 3**: Task execution (/tasks command creates tasks.md)
**Phase 4**: Implementation (execute tasks.md following TDD)
**Phase 5**: Validation (run tests, execute quickstart.md, performance checks)

## Complexity Tracking

*No constitutional violations detected—this section remains empty.*

## Progress Tracking

**Phase Status**:
- [x] Phase 0: Research complete (research.md)
- [x] Phase 1: Design complete (data-model.md, contracts/, quickstart.md)
- [x] Phase 2: Task planning described
- [x] Phase 3: Tasks generated (tasks.md with 40 numbered tasks)
- [ ] Phase 4: Implementation complete
- [ ] Phase 5: Validation passed

**Gate Status**:
- [x] Initial Constitution Check: PASS
- [x] Post-Design Constitution Check: PASS (no violations introduced)
- [x] All NEEDS CLARIFICATION resolved
- [x] Complexity deviations documented (none)

**Artifacts Generated**:
- ✅ research.md - Technology decisions and rationale
- ✅ data-model.md - Entity definitions and relationships
- ✅ contracts/pdf-export.json - PDFExportService contract
- ✅ contracts/asset-import.json - AssetImportService contract
- ✅ contracts/ai-chat.json - AIChatService contract
- ✅ quickstart.md - Executable acceptance scenarios

---
*Based on Constitution v1.0.0 - See `.specify/memory/constitution.md`*

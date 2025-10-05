# Data Model: PDF Export and AI-Assisted Asset Generation

**Feature**: 002-new-specs-at
**Date**: 2025-10-05
**Status**: Complete

## Entity Definitions

### Asset (Enhanced)

**Description**: Reusable character, object, or setting with reference images and AI chat history. Enhanced to support dual-resolution image storage and chat persistence.

**Properties**:
| Property | Type | Required | Constraints | Description |
|----------|------|----------|-------------|-------------|
| `id` | UUID | Yes | Unique | Asset identifier |
| `name` | String | Yes | 1-100 chars | Human-readable name |
| `scope` | AssetScope | Yes | Enum | Hierarchy level (root/series/album) |
| `promptText` | String | No | 0-5000 chars | Descriptive prompt for AI generation |
| `originalImages` | [ImageReference] | No | 0-50 items | Full-resolution reference images |
| `optimizedImages` | [ImageReference] | No | 0-50 items | 1024px optimized versions (same count as originals) |
| `chatHistoryPath` | URL? | No | File path | Path to `.chat/history.json` file |
| `createdAt` | Date | Yes | ISO 8601 | Creation timestamp |
| `updatedAt` | Date | Yes | ISO 8601 | Last modification timestamp |

**Relationships**:
- **1:1** with ChatHistory (via `chatHistoryPath`)
- **1:N** with ImageReference (both original and optimized)
- **N:1** with AssetScope (root/series/album)

**State Transitions**:
```
Created → ImagesAdded → ChatInitiated → ChatActive → ChatCleared → ImagesAdded
                ↓            ↓              ↓               ↓
              Deleted     Deleted       Deleted         Deleted
```

**Validation Rules**:
- `originalImages.count == optimizedImages.count` (1:1 correspondence)
- Each `optimizedImages[i]` must reference same base image as `originalImages[i]`
- `chatHistoryPath` must point to valid YAML file if non-nil
- `name` must be unique within scope

**File Structure**:
```
Assets/{scope}/{asset-id}/
├── asset.yaml            # This entity serialized
├── prompt.txt            # promptText exported for quick viewing (read-only export)
├── originals/
│   ├── {uuid}.png
│   └── {uuid}.jpg
├── optimized/
│   ├── {uuid}.png        # Max 1024px dimension
│   └── {uuid}.jpg
└── .chat/
    └── history.yaml      # ChatHistory entity
```

**Note**: prompt.txt is automatically exported from asset.yaml's `promptText` field for easy viewing/sharing. The source of truth is always asset.yaml. If prompt.txt is manually edited, changes are ignored on next save.

---

### ChatMessage

**Description**: Single message in AI chat conversation, from either user or assistant.

**Properties**:
| Property | Type | Required | Constraints | Description |
|----------|------|----------|-------------|-------------|
| `id` | UUID | Yes | Unique | Message identifier |
| `role` | MessageRole | Yes | Enum | Speaker (user/assistant) |
| `text` | String | No | 0-5000 chars | Message content |
| `attachedImages` | [URL] | No | 0-10 items | User-uploaded reference images |
| `generatedImages` | [URL] | No | 0-10 items | AI-generated output images |
| `timestamp` | Date | Yes | ISO 8601 | Message creation time |

**Relationships**:
- **N:1** with ChatHistory (messages belong to one chat)
- **N:M** with ImageReference (via URL references)

**Validation Rules**:
- `role == .user` → `generatedImages` must be empty
- `role == .assistant` → `attachedImages` must be empty
- `text` OR `generatedImages` must be non-empty (no silent messages)
- `attachedImages` URLs must point to existing files
- `generatedImages` URLs must point to cached generated results

**Enums**:
```swift
enum MessageRole: String, Codable {
    case user
    case assistant
}
```

---

### ChatHistory

**Description**: Complete conversation history for a single asset.

**Properties**:
| Property | Type | Required | Constraints | Description |
|----------|------|----------|-------------|-------------|
| `messages` | [ChatMessage] | Yes | Ordered list | Chronological message sequence |
| `version` | String | Yes | Semver | Schema version (currently "1.0") |

**Relationships**:
- **1:1** with Asset (one chat per asset)
- **1:N** with ChatMessage (ordered sequence)

**State Transitions**:
```
Empty → MessagesAdded → Cleared → MessagesAdded
  ↓           ↓            ↓
Deleted    Deleted      Deleted
```

**Validation Rules**:
- `messages` must be ordered by `timestamp` ascending
- No duplicate `message.id` values
- `version` must match parser version

**Persistence**:
- Stored as YAML at `{asset-folder}/.chat/history.yaml`
- Auto-saved after each new message
- Loaded lazily when chat interface opened

---

### PDFExportOptions

**Description**: Configuration for PDF export operation.

**Properties**:
| Property | Type | Required | Constraints | Description |
|----------|------|----------|-------------|-------------|
| `resolution` | Int | Yes | Fixed: 300 | DPI for rendering (print quality) |
| `includeMetadata` | Bool | Yes | Fixed: true | Embed document metadata |
| `seriesName` | String | Yes | 1-200 chars | Series name for metadata |
| `albumName` | String | Yes | 1-200 chars | Album name for metadata |
| `pageRange` | PageRange | Yes | Enum | Pages to export (all/single) |
| `outputURL` | URL | Yes | File path | Destination for PDF file |

**Enums**:
```swift
enum PageRange: Codable {
    case all
    case single(pageIndex: Int)
}
```

**Validation Rules**:
- `resolution` must be 300 (per FR-076)
- `includeMetadata` must be true (per FR-075)
- `outputURL` must be writable directory
- `pageRange.single(index)` must be valid page index

---

### ImageReference

**Description**: Reference to an image file with metadata about source and dimensions.

**Properties**:
| Property | Type | Required | Constraints | Description |
|----------|------|----------|-------------|-------------|
| `id` | UUID | Yes | Unique | Reference identifier |
| `url` | URL | Yes | File path | Path to image file |
| `dimensions` | CGSize | Yes | Width/height > 0 | Image pixel dimensions |
| `source` | ImageSource | Yes | Enum | Origin (imported/generated) |
| `type` | ImageVersionType | Yes | Enum | Resolution variant (original/optimized) |
| `createdAt` | Date | Yes | ISO 8601 | Import/generation timestamp |

**Enums**:
```swift
enum ImageSource: String, Codable {
    case imported    // User selected from file picker
    case generated   // AI-generated via chat
}

enum ImageVersionType: String, Codable {
    case original    // Full resolution
    case optimized   // Max 1024px dimension
}
```

**Validation Rules**:
- `type == .optimized` → `max(dimensions.width, dimensions.height) <= 1024`
- `url` must point to existing file
- `source` and `type` determine storage location:
  - `.imported` + `.original` → `originals/` folder
  - `.imported` + `.optimized` → `optimized/` folder
  - `.generated` + `.original` → `originals/` folder (from AI)
  - `.generated` + `.optimized` → `optimized/` folder

---

## Relationships Diagram

```
Root
 ├── Series (N)
 │    ├── Assets (N)
 │    │    ├── ImageReference (N) [original]
 │    │    ├── ImageReference (N) [optimized]
 │    │    └── ChatHistory (0..1)
 │    │         └── ChatMessage (N)
 │    │              ├── attachedImages [URL] (N)
 │    │              └── generatedImages [URL] (N)
 │    └── Albums (N)
 │         ├── Assets (N) [same structure as Series Assets]
 │         └── Pages (N)
 │              └── PDFExportOptions [created at export time]
 └── Assets (N) [root-level, same structure]
```

---

## Data Constraints

### Storage Limits
- **Max images per asset**: 50 (both original and optimized)
- **Max chat messages per asset**: Unlimited (indefinite retention per FR-100)
- **Max image size**: Unrestricted for originals, 1024px for optimized
- **Max prompt length**: 5000 characters
- **Max message text**: 5000 characters

### Performance Constraints
- **Image optimization**: <100ms per image (target)
- **Chat history load**: <50ms for 100 messages (target)
- **PDF rendering**: <200ms per page at 300 DPI (target)

### Consistency Rules
1. **Dual Image Consistency**: For every `originalImages[i]`, must exist corresponding `optimizedImages[i]` with same base UUID
2. **Chat-Asset Binding**: `chatHistoryPath` must point to existing file or be nil
3. **Asset Deletion Cascade**: Deleting asset deletes all ImageReferences, ChatHistory, and physical files
4. **Image Source Tracking**: Generated images imported to asset preserve `.generated` source

---

## Implementation Notes

**Feature 002 builds on Feature 001 foundation**:

**Asset Model Enhancements**:
```swift
// Feature 001 baseline (to be implemented)
struct Asset {
    let id: UUID
    let name: String
    let scope: AssetScope
    let promptText: String
    let images: [URL]  // Simple image list
}

// Feature 002 enhancements
struct Asset {
    let id: UUID
    let name: String
    let scope: AssetScope
    let promptText: String
    let originalImages: [ImageReference]   // Enhanced: dual-resolution storage
    let optimizedImages: [ImageReference]  // Enhanced: API-optimized versions
    let chatHistoryPath: URL?              // NEW: chat persistence
    let createdAt: Date                    // NEW: audit timestamps
    let updatedAt: Date                    // NEW: audit timestamps
}
```

**Implementation Approach**:
- All features will use YAML format from the start (no migration needed)
- Asset files stored as `asset.yaml` from initial implementation
- Chat history stored as `.chat/history.yaml` from first chat session
- prompt.txt automatically exported on each save for user convenience

---

## Test Data Requirements

**For Unit Tests**:
- 5 sample assets with varying image counts (0, 1, 5, 10, 50)
- 3 chat histories (empty, 10 messages, 100 messages)
- 10 test images at various resolutions (512px, 1024px, 2048px, 4096px)

**For Integration Tests**:
- 1 complete album with 5 pages, 3 assets each
- 1 asset with active chat session (20 messages, 5 generated images)
- 1 asset with mixed imported/generated images

**For Performance Tests**:
- 1 album with 50 pages (stress test PDF generation)
- 1 asset with 50 images (test dual-storage overhead)
- 1 chat history with 500 messages (test loading performance)

---

## References

- Feature Specification: [spec.md](./spec.md)
- Research Decisions: [research.md](./research.md)
- Constitution: `.specify/memory/constitution.md`

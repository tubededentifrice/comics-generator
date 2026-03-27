# Feature Specification: PDF Export and AI-Assisted Asset Generation

**Feature Branch**: `002-new-specs-at`
**Created**: 2025-10-05
**Status**: Draft
**Input**: User description: "New specs: PDF export at album/page level, AI-assisted asset generation with chat interface..."

---

## Clarifications

### Session 2025-10-05
- Q: What resolution/DPI should be used for PDF export—screen (72 DPI), print (300 DPI), or user-configurable? → A: Print resolution (300 DPI)
- Q: Should incomplete pages (missing drawings) be included in album exports, skipped, or trigger a warning? → A: Include with blank polygons (export all pages regardless of completion)
- Q: Should PDFs include metadata like series name, album name, page numbers, creation date? → A: Yes, include all metadata
- Q: Should imported images be automatically resized/optimized, or stored at original resolution? → A: Store at original resolution + model-optimized version (1024px max dimension)
- Q: Should chat history be preserved indefinitely, or have a retention limit? → A: Preserve indefinitely

---

## User Scenarios & Testing

### Primary User Story

A comic book creator has completed several pages of their album and wants to share a PDF proof with collaborators. They export the entire album as a PDF. Additionally, they need to create a castle asset based on reference photos they took during a trip. They open the asset editor, use the AI chat interface to upload their castle photos from multiple angles, iteratively refine the generated artwork through conversation with the AI model, and import the best results directly into their asset library for consistent use across pages.

### Acceptance Scenarios

1. **Given** an album with multiple completed pages, **When** the user selects "Export Album to PDF", **Then** a PDF file is generated containing all pages in order with proper layout rendering

2. **Given** a single page is open, **When** the user selects "Export Page to PDF", **Then** a PDF file is generated containing only that page with its layout and drawings

3. **Given** the user is editing an asset, **When** they select "Import External Images", **Then** a file picker opens allowing selection of one or more image files to add to the asset

4. **Given** the user is editing an asset, **When** they select "Generate with AI", **Then** a chat interface opens with the configured AI model ready for interaction

5. **Given** the AI chat interface is open, **When** the user uploads reference images (e.g., castle photos) and provides a prompt, **Then** the AI generates images based on the input

6. **Given** the AI has generated images in the chat, **When** the user clicks on a generated image, **Then** an "Import to Asset" option appears

7. **Given** a generated image is imported to the asset, **When** returning to the asset editor, **Then** the imported image appears in the asset's reference image collection

8. **Given** an AI chat session exists for an asset, **When** the user navigates away and returns to the asset, **Then** the chat history is preserved and visible

9. **Given** an active AI chat session, **When** the user selects "Clear Chat", **Then** the conversation history is erased and a fresh chat begins

10. **Given** an asset with AI-generated reference images, **When** the asset is referenced in a drawing prompt using "@" notation, **Then** the system includes all asset images (imported and generated) in the generation request

### Edge Cases

- When exporting an album with incomplete pages, all pages are included; missing drawings render as blank polygons
- PDF export uses 300 DPI (print resolution) for publication-quality output
- When a user attempts to upload an unsupported image format to the AI chat, system displays error: "Unsupported format: [format]. Supported formats: PNG, JPG, JPEG, HEIC, SVG" and prevents upload; user can select different file
- Imported images stored in two versions: original resolution (archival) and model-optimized 1024px max dimension (API transmission)
- When AI chat session fails mid-conversation (network error, API timeout), a clear error is shown indicating the reason for failure when available; timeout behavior follows FR-068 (60s warning with "Keep Waiting"/"Cancel" options)
- Chat history is preserved indefinitely with no automatic retention limits; deleted only when asset is deleted or user manually clears chat
- When a user imports the same generated image multiple times, system allows duplicates with separate UUIDs; each import creates independent ImageReference; user can manually delete unwanted duplicates via asset editor
- Users can delete individual reference images from an asset after importing (per FR-085)
- When an asset is deleted, its associated chat history is also deleted (per FR-100a)
- PDF exports include full metadata: series name, album name, page numbers (visible on pages), and creation date in document properties

---

## Requirements

### Functional Requirements

#### PDF Export
- **FR-069**: Albums MUST provide an "Export to PDF" option accessible from the album view
- **FR-070**: Individual pages MUST provide an "Export Page to PDF" option accessible from the page editor
- **FR-071**: Album PDF export MUST include all pages in their defined order
- **FR-072**: Page PDF export MUST render the single page with its layout, polygons, and active drawing versions
- **FR-073**: PDF export MUST render drawings at their original resolution within polygon boundaries
- **FR-074**: PDF export MUST preserve page dimensions as defined in the layout
- **FR-075**: PDF export MUST include complete document metadata:
  - Series name and album name in PDF document properties (author/title fields)
  - Page numbers visible on each page (format: "Page N of Total")
  - Creation date in document properties
  - All metadata fields accessible via standard PDF readers
- **FR-076**: PDF export MUST render at 300 DPI (print resolution) for publication-quality output
- **FR-077**: Album PDF export MUST include all pages regardless of completion status; incomplete pages with missing drawings render with blank polygons
- **FR-078**: Users MUST be able to specify a save location and filename for exported PDFs

#### Asset Import
- **FR-079**: Asset editor MUST include an "Import External Images" option
- **FR-080**: Import option MUST open a system file picker supporting multiple image selection
- **FR-081**: System MUST support importing common image formats: PNG, JPG, JPEG, HEIC, SVG
- **FR-082**: Imported images MUST be added to the asset's reference image collection
- **FR-083**: Imported images MUST be copied to the asset's storage folder (not referenced by external path)
- **FR-084**: System MUST store two versions of each imported image: (1) original resolution for archival, (2) model-optimized version with 1024px maximum dimension for API transmission
- **FR-084a**: Model-optimized versions MUST maintain aspect ratio while scaling the longest dimension to 1024px
- **FR-084b**: When sending asset images to AI APIs, system MUST use the model-optimized versions
- **FR-085**: Users MUST be able to remove individual images from an asset's reference collection

#### AI-Assisted Asset Generation
- **FR-086**: Asset editor MUST include a "Generate with AI" option
- **FR-087**: Generate with AI option MUST open a chat interface with the currently configured AI model provider
- **FR-088**: Chat interface MUST support text prompt input
- **FR-089**: Chat interface MUST support image upload via drag-and-drop or file picker
- **FR-089a**: System MUST validate uploaded image formats against supported list (PNG, JPG, JPEG, HEIC, SVG)
- **FR-089b**: System MUST display error "Unsupported format: [format]. Supported formats: PNG, JPG, JPEG, HEIC, SVG" and reject unsupported uploads
- **FR-090**: Chat interface MUST display conversation history (user prompts and AI responses) in chronological order
- **FR-091**: When user submits a prompt with optional images, system MUST send the request to the AI model API
- **FR-092**: AI-generated images MUST be displayed in the chat as responses
- **FR-093**: Each generated image in the chat MUST be clickable
- **FR-094**: Clicking a generated image MUST display an "Import to Asset" action
- **FR-095**: Importing a generated image MUST add it to the asset's reference image collection
- **FR-095a**: System MUST allow importing the same generated image multiple times, creating separate ImageReferences with unique UUIDs
- **FR-096**: Chat interface MUST include a "Clear Chat" button
- **FR-097**: Clear Chat MUST erase all conversation history and generated images from the current session
- **FR-098**: Chat history MUST persist when navigating away from the asset and returning
- **FR-099**: Chat history MUST be stored at the asset level (separate chat per asset)
- **FR-100**: Chat history MUST be preserved indefinitely with no automatic retention limits or message count caps
- **FR-100a**: When an asset is deleted, its associated chat history MUST also be deleted
- **FR-101**: System MUST display loading indicators while waiting for AI responses in chat
- **FR-102**: If chat generation exceeds 60 seconds, system MUST apply the same timeout behavior as drawing generation (FR-068: "Keep Waiting"/"Cancel" options)

#### Asset Reference Integration
- **FR-103**: Assets MUST store both manually imported and AI-generated images in the same reference collection
- **FR-104**: When an asset is referenced in a prompt via "@" notation, system MUST include all reference images (imported and generated) in the generation payload
- **FR-105**: Asset editor MUST display all reference images with visual indication of their source (imported vs. generated)

### Key Entities

- **Asset** (updated): Reusable character, object, or setting; consists of reference images (imported and/or AI-generated), descriptive prompt, and persistent AI chat history; scoped to Root, Series, or Album; referenced via "@name" syntax
- **AI Chat Session**: Conversation history associated with a specific asset; contains user prompts, uploaded reference images, AI responses, and generated images; persists across navigation
- **PDF Export**: Generated document containing rendered pages with layouts and drawings; includes metadata; saved to user-specified location

---

## Review & Acceptance Checklist

### Content Quality
- [x] No implementation details (languages, frameworks, APIs)
- [x] Focused on user value and business needs
- [x] Written for non-technical stakeholders
- [x] All mandatory sections completed

### Requirement Completeness
- [x] No [NEEDS CLARIFICATION] markers remain
- [x] Requirements are testable and unambiguous
- [x] Success criteria are measurable
- [x] Scope is clearly bounded
- [x] Dependencies and assumptions identified

**Remaining Clarifications**: None (all resolved 2025-10-05)

---

## Execution Status

- [x] User description parsed
- [x] Key concepts extracted
- [x] Ambiguities marked
- [x] User scenarios defined
- [x] Requirements generated
- [x] Entities identified
- [x] Review checklist passed

---

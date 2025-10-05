# Feature Specification: AI-Generated Comics Book Creator

**Feature Branch**: `001-build-an-application`
**Created**: 2025-10-05
**Status**: Draft
**Input**: User description: "Build an application that allows the user to create AI-generated books / comic books..."

---

## Clarifications

### Session 2025-10-05
- Q: Should orphaned drawings (not referenced by any page) be automatically cleaned up, manually managed, or retained indefinitely? → A: Mark as archived (hidden by default, retrievable from archive view)
- Q: Which specific AI model providers should be supported at launch? → A: Midjourney, DALL-E 3, Gemini 2.5 Flash Image
- Q: Should API keys be stored securely in system keychain, or as encrypted preferences? → A: Both: keychain preferred, fallback to encrypted preferences
- Q: Should the app validate API keys on entry, or only when generation is attempted? → A: Immediately on entry
- Q: What should happen if generation takes longer than a specified timeout? → A: Show error with "Keep Waiting" and "Cancel" options

---

## User Scenarios & Testing

### Primary User Story

A comic book creator wants to produce a new series with consistent characters and settings across multiple albums and pages. They create a series called "Space Adventures," define reusable assets (spaceship, captain character, alien planet), set up hierarchical prompts that apply to all downstream content, design custom page layouts with polygon-based panel arrangements, sketch initial artwork using Apple Pencil, and generate AI-enhanced images for each panel while maintaining visual consistency through asset references.

### Acceptance Scenarios

1. **Given** the app is opened for the first time, **When** the user taps "Create New Series", **Then** a new series is created and the user can enter a name and begin adding albums

2. **Given** a series exists with global assets defined (e.g., "@captain" character), **When** the user creates a new album and references "@captain" in a drawing prompt, **Then** the system includes the captain asset's images and prompt in the final generation request

3. **Given** an album with multiple pages, **When** the user long-presses a page card, **Then** the page is selected for reordering or deletion, and can be dragged to a new position

4. **Given** a page with a polygon-based layout, **When** the user clicks on a polygon, **Then** the drawing editor opens with prompt input, base drawing canvas, and generation controls

5. **Given** a drawing with a completed prompt and base sketch, **When** the user taps "Generate", **Then** the AI model generates an image and saves it as a new version accessible from the version history

6. **Given** multiple generated versions of a drawing exist, **When** the user selects a specific version, **Then** that version is displayed in the page polygon and persisted as the active version

7. **Given** prompt hierarchies exist at root, series, and album levels, **When** generating a drawing, **Then** prompts are concatenated in order (root → series → album → drawing) to form the final prompt

8. **Given** a page is deleted, **When** viewing the album's stored drawings, **Then** all drawings referenced by that page remain saved and accessible for reuse

9. **Given** the user is in drawing mode with Apple Pencil, **When** drawing with pressure sensitivity, **Then** pen strokes reflect pressure and tilt, with selectable pen types (fill, thin, eraser, cutter/move tool)

10. **Given** the drawing canvas has multiple layers, **When** the user creates, hides, or deletes layers, **Then** each layer maintains its content independently and visibility changes are reflected immediately

### Edge Cases

- When an asset reference (e.g., "@captain") is used in a prompt but the asset is deleted, an error is shown indicating the missing asset and which prompt references it, with links to edit the prompt or add a new asset at the same hierarchy level
- When the same asset name is defined at multiple hierarchy levels (root, series, album), the asset defined furthest down the hierarchy takes precedence (Album > Series > Root)
- When a user attempts to delete a layout that is actively used by existing pages, an error is shown indicating which pages in which series/albums are using that layout; once a layout is in use, polygons cannot be edited but new polygons can be added; decorative layers can always be edited (above or below the polygons layer) as they don't affect drawings
- When API key is missing or invalid and "Generate" is pressed, a clear error is shown indicating a model and API key must be configured, with a link to Settings (API keys are validated immediately on entry and saved only after successful validation)
- When drawing generation fails due to API errors or timeout, a clear error is shown indicating the reason for failure when available (After 60s, user chooses "Keep Waiting" or "Cancel"; repeat every 60s if waiting continues)
- When an album is deleted, all associated drawings are also deleted
- Polygon dimensions cannot be changed after drawings have been created for them (polygons are locked when layout is in use)
- When prompt concatenations exceed model token limits, a clear error is shown
- Page reordering is permitted while a page is open for editing; page order is stored as a reference in the Album YAML file and doesn't affect on-disk layout
- When a drawing becomes orphaned, it is automatically archived and accessible from the "Archived Drawings" view for restoration or permanent deletion

---

## Requirements

### Functional Requirements

#### Hierarchy & Navigation
- **FR-001**: System MUST organize content in a four-level hierarchy: Root → Series → Album → Page → Drawing
- **FR-002**: Users MUST be able to create, open, and manage multiple series from the opening screen
- **FR-003**: Users MUST be able to create, open, and manage multiple albums within a series
- **FR-004**: Opening screen MUST provide a collapsible left sidebar with tabs for Assets, Layouts, and Prompts at global (root) level
- **FR-005**: When an album is opened, sidebar MUST display additional scoped tabs: Series Assets, Album Assets, Series Layouts, Album Layouts, Series Prompts, Album Prompts
- **FR-006**: Album view MUST include a "Pages" tab showing a card-based view of all pages in the album

#### Assets Management
- **FR-007**: Users MUST be able to define assets at three levels: Root (global), Series, and Album
- **FR-008**: Each asset MUST consist of a set of reference images and an associated text prompt
- **FR-009**: Assets MUST be referenceable in prompts using "@" notation (e.g., "@tintin", "@spaceship")
- **FR-010**: System MUST resolve asset conflicts by applying the closest scope (Album overrides Series, Series overrides Root)
- **FR-011**: When an asset is referenced in a prompt, system MUST include the asset's images and prompt text in the AI generation request
- **FR-011a**: Users MUST be able to move assets between hierarchy levels (Root, Series, Album)
- **FR-011b**: When an asset reference is used in a prompt but the asset is deleted, system MUST display an error indicating the missing asset, which prompt references it, and provide links to edit the prompt or add a new asset at the same hierarchy level
- **FR-011c**: When the final prompt is constructed and includes a missing asset reference, system MUST prevent generation and display the error from FR-011b

#### Prompts Hierarchy
- **FR-012**: Users MUST be able to define text prompts at Root, Series, and Album levels
- **FR-013**: System MUST concatenate prompts hierarchically (Root → Series → Album → Drawing) to create the final "base prompt" for each drawing
- **FR-014**: Drawing-level prompts MUST support asset references using "@" notation
- **FR-015**: System MUST resolve all "@" references before sending the final prompt to the AI model
- **FR-015a**: When prompt concatenation exceeds model token limits, system MUST display a clear error message and prevent generation

#### Layouts
- **FR-016**: Users MUST be able to define reusable page layouts at Root, Series, and Album levels
- **FR-017**: Each layout MUST specify page width and height dimensions
- **FR-018**: Each layout MUST support user-defined polygons representing drawing panel positions
- **FR-019**: Each layout MUST support drawing layers for decorative elements (background colors, borders, etc.)
- **FR-019a**: Decorative layers MUST be positionable above or below the polygons layer
- **FR-019b**: Decorative layers MUST remain editable even when the layout is in use by pages
- **FR-020**: When creating a new page, users MUST select a layout from available layouts
- **FR-021**: Users MUST be able to change a page's layout after creation
- **FR-021a**: When a layout is in use by one or more pages, system MUST lock polygon editing (polygons cannot be modified or removed)
- **FR-021b**: When a layout is in use, users MUST still be able to add new polygons
- **FR-021c**: When a user attempts to delete a layout in use, system MUST display an error indicating which pages in which series/albums are currently using that layout
- **FR-021d**: System MUST prevent deletion of layouts that are actively referenced by pages

#### Page Management
- **FR-022**: Album's Pages tab MUST display pages as cards in a grid or list view
- **FR-023**: Users MUST be able to add new pages via an "Add New Page" button
- **FR-024**: Users MUST be able to reorder pages by long-pressing and dragging page cards
- **FR-025**: Long-pressing a page card MUST select it for deletion
- **FR-026**: Users MUST be able to click a page card to open the page editor
- **FR-027**: System MUST persist page order in the Album metadata file (YAML format)
- **FR-027a**: Page order MUST be stored as references and MUST NOT affect on-disk file structure
- **FR-027b**: Users MUST be able to reorder pages even while a page is currently open for editing

#### Drawing Storage & References
- **FR-028**: Drawings MUST be stored at the album level, not embedded in pages
- **FR-029**: Pages MUST reference drawings by identifier, not by embedding drawing data
- **FR-030**: When a page is deleted, system MUST retain all associated drawings on disk
- **FR-030a**: When an album is deleted, system MUST delete all associated drawings
- **FR-031**: System MUST mark orphaned drawings (not referenced by any page) as archived; archived drawings are hidden by default but retrievable from an archive view
- **FR-031a**: Users MUST be able to access an "Archived Drawings" view within each album
- **FR-031b**: Users MUST be able to restore archived drawings to active status or permanently delete them

#### Drawing Editor
- **FR-032**: Clicking a polygon on a page MUST open the drawing editor for that polygon
- **FR-033**: Drawing editor MUST display: (1) a prompt input box, (2) a base drawing canvas, (3) generation controls
- **FR-034**: Prompt input box MUST support text entry with "@" asset references
- **FR-035**: Base drawing canvas MUST match the aspect ratio of the source polygon
- **FR-036**: Base drawing canvas MUST support Apple Pencil input with pressure sensitivity and tilt detection
- **FR-037**: Base drawing canvas MUST support mouse input for macOS users without stylus
- **FR-038**: Drawing tools MUST include: large fill pen, thin drawing pen, eraser, cutter/move tool
- **FR-039**: Users MUST be able to select pen color
- **FR-040**: Users MUST be able to add text annotations on the canvas for image instructions
- **FR-041**: Canvas MUST support multiple layers that can be independently created, hidden, and deleted
- **FR-042**: System MUST maintain layer order and visibility state

#### AI Generation
- **FR-043**: Drawing editor MUST include a "Generate" button to trigger AI image generation
- **FR-043a**: When "Generate" is pressed without a configured API key, system MUST display a clear error indicating a model and API key must be configured, with a link to Settings
- **FR-044**: When "Generate" is pressed, system MUST construct the final prompt by concatenating: Root prompt + Series prompt + Album prompt + Drawing prompt
- **FR-045**: System MUST resolve all "@" asset references in the concatenated prompt
- **FR-046**: System MUST include asset reference images in the generation request payload
- **FR-047**: System MUST send the generation request to the configured AI model API
- **FR-047a**: When generation fails due to API errors or timeout, system MUST display a clear error message indicating the reason for failure when available
- **FR-048**: Each generated image MUST be saved as a new version under the drawing
- **FR-049**: System MUST display all generated versions in a version history UI at the bottom of the drawing editor
- **FR-050**: Users MUST be able to select which version to use as the active drawing
- **FR-051**: Users MUST be able to request modifications to a generated image (regenerate with refinements)
- **FR-052**: When returning to page view, system MUST display the selected version inside the polygon

#### Settings
- **FR-053**: Application MUST include a Settings section
- **FR-054**: Settings MUST allow users to select from three AI model providers: Midjourney, OpenAI DALL-E 3, and Google Gemini 2.5 Flash Image (Imagen 3)
- **FR-055**: Settings MUST provide a secure text input for users to enter their API key for the selected provider
- **FR-056**: System MUST store API keys in system keychain (preferred); if keychain unavailable, MUST fallback to encrypted app preferences
- **FR-056a**: API key encryption MUST use platform-standard encryption (AES-256 or equivalent)
- **FR-057**: System MUST validate API keys immediately upon entry by making a test API call to the selected provider
- **FR-057a**: System MUST display validation status (valid/invalid/checking) with clear visual feedback
- **FR-057b**: System MUST save the API key only after successful validation

#### File System & Persistence
- **FR-058**: All data MUST be saved to a single user-configurable folder as standard files (per Constitution Principle I)
- **FR-059**: Each series MUST be stored as a separate subfolder
- **FR-060**: Each album MUST be stored as a subfolder within its series folder
- **FR-061**: Assets, layouts, prompts, pages, and drawings MUST be stored as individual files (JSON for metadata, PNG/SVG for images)
- **FR-062**: File structure MUST be Git-compatible and human-readable
- **FR-063**: System MUST support iCloud Drive sync for the project folder

#### Performance & UX
- **FR-064**: Drawing input latency MUST be below 20ms for Apple Pencil strokes (per Constitution Principle II)
- **FR-065**: UI interactions (navigation, card selection, sidebar expansion) MUST respond within 16ms (60fps)
- **FR-066**: File save operations MUST complete within 200ms for typical projects
- **FR-067**: System MUST provide loading indicators during AI generation requests
- **FR-068**: If AI generation exceeds 60 seconds, system MUST display a timeout warning with two options: "Keep Waiting" (continues request) and "Cancel" (aborts request)
- **FR-068a**: If user selects "Keep Waiting", system MUST continue waiting and repeat the timeout warning every additional 60 seconds
- **FR-068b**: If user selects "Cancel", system MUST abort the API request and return to the drawing editor without saving a new version

### Key Entities

- **Series**: Top-level organizational unit; contains albums, series-scoped assets, prompts, and layouts; has a name and metadata
- **Album**: Collection of pages within a series; contains album-scoped assets, prompts, layouts, and all drawings; has a name and metadata
- **Page**: Ordered element within an album; references a layout and contains references to drawings for each polygon; has position/order
- **Drawing**: Reusable content unit stored at album level; contains base artwork (layers, strokes, text), drawing-specific prompt, generated versions, and selected active version; referenced by page polygons; can be archived if orphaned
- **Asset**: Reusable character, object, or setting; consists of reference images and descriptive prompt; scoped to Root, Series, or Album; referenced via "@name" syntax
- **Layout**: Page template defining dimensions, polygon panel positions, and decorative layers; scoped to Root, Series, or Album; reusable across pages
- **Prompt**: Hierarchical text snippet; scoped to Root, Series, Album, or Drawing; concatenated to form final generation prompt
- **Polygon**: Panel boundary within a layout; defines position and shape where a drawing will be rendered on a page
- **Layer**: Drawing canvas component; holds strokes, fills, text annotations; can be shown, hidden, reordered, or deleted
- **Version**: Generated image output from AI model; associated with a drawing; stored with generation parameters; one version marked as active

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

**Remaining Clarifications**: None

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

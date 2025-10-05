<!--
SYNC IMPACT REPORT
==================
Version: 0.0.0 → 1.0.0 (Initial Constitution)
Rationale: MAJOR bump - establishing foundational governance for new project

Modified Principles:
- N/A (initial creation)

Added Sections:
- Core Principles (7 principles)
- Platform Requirements
- Development Standards
- Governance

Templates Status:
✅ plan-template.md - reviewed, compatible with constitution checks
✅ spec-template.md - reviewed, compatible with requirement standards
✅ tasks-template.md - reviewed, compatible with TDD and quality gates

Follow-up TODOs:
- None
-->

# Comics Generator Constitution

## Core Principles

### I. Open Standards & Portability
All application data MUST be stored as standard, human-readable files in a single designated folder. This folder MUST be fully version-controllable via Git and manually reviewable without proprietary tools. File formats SHALL use open standards (JSON, Markdown, PNG, SVG) whenever feasible. No proprietary data formats are permitted unless absolutely necessary for platform integration, in which case the decision MUST be documented with export alternatives.

**Rationale**: Ensures user data ownership, enables version control workflows, facilitates debugging, and prevents vendor lock-in.

### II. First-Class Stylus Support (NON-NEGOTIABLE)
Apple Pencil input MUST be treated as a primary interaction method, not an optional enhancement. All drawing, annotation, and creative workflows MUST support pressure sensitivity, tilt detection, and palm rejection. Latency MUST be below 20ms for pencil input. UI components MUST provide pencil-optimized affordances (e.g., larger hit targets for precision tools, hover states).

**Rationale**: Comics creation is inherently visual and tactile; treating stylus as secondary degrades the core user experience.

### III. Platform Consistency & Universal Codebase
The application MUST use a single, shared codebase for macOS and iPadOS with identical feature parity and UI behavior across platforms. Platform-specific adaptations are limited to hardware interfaces (e.g., Touch Bar on Mac, Face ID on iPad). SwiftUI MUST be used for cross-platform UI consistency. Divergent UI paths between platforms are prohibited unless justified by fundamental platform differences.

**Rationale**: Reduces maintenance burden, ensures feature parity, and provides consistent user experience across devices.

### IV. Test-First Development (NON-NEGOTIABLE)
All features MUST follow strict TDD discipline: Write tests → User approval → Verify tests fail → Implement → Tests pass. No implementation without failing tests first. Unit tests required for business logic, UI tests for user flows, integration tests for file I/O and data persistence. Code coverage MUST exceed 80% for logic layers.

**Rationale**: Prevents regressions, ensures correctness, and documents expected behavior.

### V. Performance Targets
Interactive operations (UI response, pencil rendering) MUST complete within 16ms (60fps). File operations (save/load) MUST complete within 200ms for typical projects (<100MB). Memory footprint MUST stay below 500MB for active editing sessions. All targets validated via automated performance tests that fail if thresholds exceeded.

**Rationale**: Maintains fluid user experience essential for creative tools; prevents performance regressions.

### VI. Code Quality & Simplicity
Favor composition over inheritance. Avoid premature abstraction—copy-paste is acceptable until three instances exist, then refactor. External libraries permitted ONLY when they eliminate significant complexity (e.g., image processing, PDF generation). Each library addition requires architectural review justification. Prefer Swift standard library and Apple frameworks first.

**Rationale**: Reduces dependencies, minimizes maintenance burden, keeps codebase understandable.

### VII. User Experience Consistency
All UI patterns MUST follow Apple Human Interface Guidelines. Interactions (gestures, keyboard shortcuts, menu structures) MUST align with platform conventions. Custom UI only when standard components insufficient; document rationale. Accessibility features (VoiceOver, Dynamic Type, Keyboard Navigation) required for all user-facing features.

**Rationale**: Reduces cognitive load, ensures accessibility, meets App Store review standards.

## Platform Requirements

### Target Deployment
- **Minimum OS**: macOS 14.0 (Sonoma), iPadOS 17.0
- **Language**: Swift 5.9+
- **UI Framework**: SwiftUI with UIKit interop where necessary (e.g., PKCanvasView for pencil input)
- **Build System**: Xcode 15+, Swift Package Manager for dependencies
- **Distribution**: Apple App Store (adheres to App Store Review Guidelines)

### Hardware Support
- **macOS**: Intel and Apple Silicon Macs with trackpad/mouse + optional graphics tablet
- **iPadOS**: iPad Pro (all generations), iPad Air (5th gen+), iPad (10th gen+) with Apple Pencil (2nd gen preferred)
- **Storage**: Minimum 100MB free space for app, user projects scale independently

### File System Integration
- Single "Projects" folder configurable by user (default: Documents/ComicsGenerator)
- Each project = subfolder with manifest JSON + assets
- Support iCloud Drive sync (no proprietary sync layer)
- File operations use standard FileManager APIs

## Development Standards

### Testing Requirements
- **Unit Tests**: All view models, data models, business logic
- **UI Tests**: Critical user flows (create project, draw panel, export)
- **Integration Tests**: File I/O, persistence, undo/redo stack
- **Performance Tests**: Pencil latency, save/load times, memory usage
- Tests run on CI for every commit; failing tests block merges

### Code Review Gates
- All PRs require passing tests + manual review
- Performance regression checks required for rendering/file code
- Accessibility audit required for new UI components
- Constitution compliance verification (principles I-VII)

### Documentation Standards
- Public APIs documented with Swift DocC
- Architecture decisions recorded in specs/ (per existing templates)
- User-facing features documented in in-app help + external docs
- No README-only documentation; prefer doc comments + generated docs

### Versioning & Releases
- Semantic versioning (MAJOR.MINOR.PATCH)
- App Store version numbers match semantic version
- Breaking file format changes = MAJOR bump + migration tool
- Release notes generated from commit history

## Governance

### Amendment Process
1. Proposed changes submitted as PR to constitution.md
2. Architectural review by maintainers
3. Impact analysis on existing templates and code
4. Approval requires rationale for change + migration plan
5. Version bump per semantic rules (see below)

### Version Semantics
- **MAJOR**: Principle removed/redefined, new non-negotiable rule
- **MINOR**: New principle added, expanded guidance
- **PATCH**: Clarifications, typos, non-semantic edits

### Compliance Enforcement
- All feature plans MUST include Constitution Check section (per plan-template.md)
- Gate violations documented in Complexity Tracking with justification
- Unjustified violations block plan approval
- Post-design re-check required before task generation

### Constitutional Authority
This constitution supersedes all other development practices. When conflicts arise between this document and external guidelines (e.g., team conventions, library docs), constitution takes precedence. Changes to this document follow the Amendment Process above.

**Version**: 1.0.0 | **Ratified**: 2025-10-05 | **Last Amended**: 2025-10-05

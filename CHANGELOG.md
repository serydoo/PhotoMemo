# Changelog

## v1.7.0 (Build 7) - 2026-07-17

### Added
- Added the beginner-facing Expression Formula Guide inside Settings ->
  Usage & Help. It lists every configured time-anchor category and expression
  style, with separate Before, On Anchor/Day, and After examples.
- Added color-coded formula tokens so new users can distinguish Subject,
  Smart Output, and Anchor Result at a glance.
- Added a concise development-background section above Memory Objects on the
  Home surface, explaining the original child-memory use case and the later
  expansion from birth dates to anniversaries and future important dates.
- Added Main App Picker Live Photo release-candidate support: selected Live Photo assets can be routed through the VNext media pipeline, composed with MemoMark geometry, and saved back as motion-preserving Live Photo output when using original-format output.
- Added Media Geometry Foundation and CanonicalGeometry-based regression coverage for JPEG/HEIC geometry, Live Photo still/video composition, pairing identity, metadata readback, and batch queue routing.
- Added runtime evidence tooling for iOS Live Photo validation without copying private media.
- Added focused responsibility boundaries for the iOS root coordinator, Batch Queue execution, image export, Share Extension intake and presentation, configuration editing, settings persistence, and external-intake storage.

### Changed
- Clarified the expression model as Subject + Smart Output + Anchor Result.
  Smart modules continue to provide reusable time results, while users retain
  control over the final sentence wording.
- Updated Live Photo still output metadata so MemoMark description text is written through stable TIFF/IPTC fields while avoiding corrupted non-ASCII HEIC UserComment readback.
- Clarified release scope: Main App Picker Live Photo is a release candidate, while Share Extension Live Photo remains a separate production-validation item.
- Reduced the former large coordinator and service facades while preserving persistence keys, Share handoff records, renderer/layout ownership, and the Apple Photos workflow.
- Replaced repository and runtime demo values with neutral synthetic names, dates, places, coordinates, and device placeholders.
- Removed personal social contact from Settings while retaining the public support email and GitHub Issues.
- Removed tracked signed distribution artifacts, generated PDF output, and personal Xcode user state; signed artifacts are now ignored by Git.

### Fixed
- Fixed the iOS crash triggered by destructive swipe actions in nested
  collection views. Home preset rows and Time Anchor rows no longer embed
  nested List containers inside outer scroll surfaces; Time Anchor deletion
  now mutates data only after confirmation.
- Fixed the expression-guide formula marker parser so the iOS target builds
  successfully for device deployment.
- Corrected AVFoundation Live Photo metadata identifiers to use the public Auto Live Photo identifier and the valid `mdta/com.apple.quicktime.still-image-time` key.
- Updated stale regression expectations for current MemoMark symbols and copy, preset fallback naming, job-ID-based background ordering, parsed anchor types, and stored DTO properties.

### Verification
- Passed the arm64 physical-device Debug build for PhotoMemoiOS, including
  the Share Extension and Widget Extension.
- Passed 11 focused contract tests covering the expression guide, Home swipe
  actions, and Time Anchor confirmation deletion.
- Installed the resulting 1.7 (7) development build over the existing iPhone7
  installation without uninstalling or clearing app data.
- Successfully launched the installed build on iPhone7 after unlocking the
  device; the main App and Widget Extension processes were observed running.
- Captured the launched Home surface at
  /tmp/PhotoMemo-iPhone7-1.7-7-launch.png.
- Passed the complete Xcode 26.6 test run: `952` passed, `0` failed, and `1` documented manual ImageIO fixture test skipped.
- Passed unsigned Debug builds for macOS, the iOS app, and the Share Extension.
- Completed four post-refactor Share batches on the signed device with `7/7` assets saved: one JPEG and six Live Photos, with no failure, backlog, or crash.
- Retained the four existing Classic White renderer snapshots and all current App icon assets unchanged.

## v1.0.0-test1 - 2026-07-02

### Added
- Documented the first V1 testing IPA build and its reproducible local packaging path.
- Added `Docs/07_Releases/V1.0/README.md` with packaging notes, release label, and tester installation caveats.
- Added `scripts/export_options_v1_testing.plist` so the current IPA export path is reproducible from the repository.

### Changed
- Standardized the repository release artifact path for the current V1 testing line under `Docs/07_Releases/V1.0/`.

### Notes
- This is the first V1 testing release artifact, built from `PhotoMemoiOSV1`.
- The exported IPA uses the current local signed debugging export path and is appropriate for the active tester/provisioning setup.
- Signed IPA and provisioning artifacts are intentionally excluded from source control.

## PhotoMemo IA-001A Repository Product Definition Completion - 2026-06-23

### Added
- Added `Docs/NEVER_BREAK.md`.
- Added `Docs/PDR/PDR_INDEX.md`.

### Changed
- Added Product Boundary to `PROJECT_PHILOSOPHY.md`.
- Expanded `Docs/Behavior/BEHAVIOR_SPECIFICATION.md` with a Behavior State Machine and Configuration Snapshot Principle.
- Expanded `Docs/Guidelines/APPLE_NATIVE_GUIDELINES.md` with an Apple review checklist.
- Expanded `Docs/Guidelines/LANGUAGE_SYSTEM.md` and `Docs/Interaction/IA-001_Interaction_Architecture.md` with Smart Batch Recommendation and clarified that Soft Limit Language is guidance rather than a hard limit.
- Expanded `PROJECT_CONSTITUTION.md` with the Apple Trust design rationale.
- Added the repository mission to `README.md`.
- Updated `Docs/FROZEN_REGISTRY.md`, `Docs/DESIGN_DECISIONS.md`, `AI_CONTEXT.md`, `Docs/CURRENT_STATUS.md`, and `Docs/DOCUMENT_INDEX.md` to register the completed IA-001A assets.

### Notes
- This update is documentation-only and does not change runtime behavior.
- No Swift, renderer, metadata, export, database, or pipeline implementation files were changed.

## PhotoMemo IA-001 Interaction Architecture - 2026-06-23

### Added
- Added `Docs/Interaction/IA-001_Interaction_Architecture.md`.
- Added `Docs/Behavior/BEHAVIOR_SPECIFICATION.md`.
- Added `Docs/Guidelines/LANGUAGE_SYSTEM.md`.
- Added `Docs/Guidelines/PRODUCT_PERSONALITY.md`.
- Added `Docs/Guidelines/APPLE_NATIVE_GUIDELINES.md`.
- Added `Docs/Configuration/CONFIGURATION_MODEL.md`.
- Added `Docs/Product/ANTI_GOALS.md`.
- Added `Docs/DESIGN_DECISIONS.md`.
- Added `Docs/FROZEN_REGISTRY.md`.
- Added `Docs/PDR/PDR-003_Interaction_Architecture.md`.
- Added `LIFE_TIMELINE_PHILOSOPHY.md`.

### Changed
- Updated `PROJECT_CONSTITUTION.md`, `Docs/MASTER_PLAN.md`, `PROJECT_PHILOSOPHY.md`, `AI_CONTEXT.md`, `Docs/CURRENT_STATUS.md`, and `Docs/DOCUMENT_INDEX.md` to reflect IA-001 as the current frozen documentation slice.
- Formalized PhotoMemo as a local-first Memory Capability inside Apple Photos workflows instead of a standalone photo-management product.
- Frozen the Configuration Center role, share-first primary entry path, Zero Interaction, Quiet Computing, Back To Photos, behavior principles, language system, and anti-goals.
- Added a permanent five-step feature workflow in `Docs/MASTER_PLAN.md`: PDR -> Repository Refactor -> Architecture Review -> Implementation -> Review & Freeze.

### Notes
- This update is documentation-only and does not change runtime behavior.
- No Swift, renderer, metadata, export, database, or pipeline implementation files were changed.

## PhotoMemo Memory Presentation Philosophy - 2026-06-22

### Added
- Added `PROJECT_PHILOSOPHY.md`.
- Added `PROJECT_DIRECTION.md`.
- Added `Docs/03_Research/MemoryPhilosophy.md`.
- Added V2 architecture documentation in `Docs/ARCHITECTURE.md`.

### Changed
- Reframed PhotoMemo as a local-first, privacy-first Memory Presentation Engine.
- Added Life Position and Memory Timeline as core product concepts.
- Updated architecture language to include Memory Engine between Metadata Engine and Presentation Engine.

### Notes
- Memory Engine calculates relationships but does not write stories.
- Presentation Engine expresses relationships.
- Layout Engine presents meaning.
- Renderer draws.
- Runtime code remains untouched.

## PhotoMemo V2 Constitution - 2026-06-22

### Added
- Added `PROJECT_CONSTITUTION.md` as the highest-level repository instruction.
- Added research-system documents for reverse-engineering roadmap, canvas specification, panel specification, adaptive rules, and measurement methodology.

### Changed
- Updated AI and project entry files so `PROJECT_CONSTITUTION.md` is read before `Docs/MASTER_PLAN.md`.
- Updated `RepositoryAudit.md` with duplicated, outdated, and conflicting document groups.
- Clarified that old documentation should not be migrated until research specifications stabilize.

### Notes
- Runtime code remains untouched.
- Renderer remains frozen.
- UI work remains paused.

## PhotoMemo V2 Reset - 2026-06-22

### Added
- Added `Docs/MASTER_PLAN.md` as the single V2 project entry.
- Added `PROJECT_RESET.md` to preserve the permanent reset memory.
- Added `RepositoryAudit.md` with architecture, documentation, renderer, workflow, repository-health, and open-source readiness findings.
- Added the `Research/` system and initial specification stubs.
- Added non-destructive V2 target-structure folders for App, DesignSystem, LayoutEngine, Renderer, Examples, and Screenshots.
- Added `Docs/01_Product` through `Docs/07_Releases` buckets for the future documentation refactor.

### Changed
- Updated `README.md`, `AI.md`, `AI_CONTEXT.md`, `AGENTS.md`, `Docs/CURRENT_STATUS.md`, `Docs/DOCUMENT_INDEX.md`, and `Docs/PROJECT_STRUCTURE.md` to prioritize the V2 Research Phase.

### Notes
- Feature development is paused.
- Renderer polishing is paused.
- UI expansion is paused.
- This reset is documentation and repository-structure only; runtime code was not changed.

## Alpha 0.8 - 2026-06-20

### Added
- Added `Docs/ProductScore.md` to score the current product simplicity level and list the top remaining simplification opportunities.
- Added share-intake diagnostics across the Share Extension confirmation pipeline so failures now preserve stage-level context and low-level `NSError` details.
- Added focused regression coverage for nested intake error summaries and managed-copy diagnostic failures.

### Changed
- Removed multiple instructional cards from the Main App default flow so the configuration center feels less like a tutorial.
- Simplified Anchor management by removing the duplicated `设为当前` action and trimming editor-only educational copy.
- Reduced permission and output wording to short just-in-time explanations.
- Reduced the iPhone background-status sheet to current task, retry failed, and latest failure.
- Renamed more visible product language from configuration/workspace/template wording toward style-first language.
- Updated Share Extension wording so it now refers to the current style instead of the current configuration.
- Updated Share Extension failure handling to surface the failing intake stage and preserve copy/persist/serialization diagnostics instead of collapsing everything into one generic import error.

### Notes
- This release intentionally does not change architecture, renderer behavior, export behavior, metadata logic, or batch semantics.

## Alpha 0.7 - 2026-06-20

### Added
- Added `Docs/Alpha/Alpha01.md` to define the real-world validation rhythm for the current stage.
- Added `Docs/Alpha/BugList.md`, `Docs/Alpha/UXNotes.md`, and `Docs/Alpha/KnownIssues.md` for lightweight product validation tracking.

### Changed
- Shifted repository-facing milestone wording for the current stage toward `Alpha 0.7` instead of continuing open-ended sprint naming.

### Notes
- This update is documentation-only and sets the operating model for the next round of real-device product validation.

## v0.7.4 - 2026-06-20

### Added
- Added `Docs/ShareExtensionReview.md` to evaluate the Share Extension as the primary product entry from a user perspective.
- Added `Docs/DesignSystem.md` to establish baseline UI rules for spacing, radius, typography, colors, cards, and buttons.
- Added `Docs/ProductBacklog.md` to structure future work into Now / Next / Later / Icebox.

### Changed
- Extended `Docs/ProductDirection.md` with an explicit product-polishing phase statement and links to the new supporting docs.

### Notes
- This release is documentation-only and does not change runtime behavior.

## v0.7.3 - 2026-06-20

### Added
- Added `Docs/ProductDirection.md` to formalize PhotoMemo's share-first product direction.
- Added `Docs/UX_PRINCIPLES.md` as a long-term UX baseline for future product decisions.

### Changed
- Updated the README homepage positioning to: "PhotoMemo is a memory generator built around Apple Photos, not a photo editor."
- Aligned repository-facing product language around a share-first workflow where the Main App is a configuration center and the Share Extension is the primary entry.

### Notes
- This release is documentation-only and does not change runtime behavior.

## v0.7.0 - 2026-06-20

### Added
- Added the first `MemoryEngine` foundation with `MemoryContext`, `MemoryCalculationResult`, and `MemoryVariableProvider`.
- Added new public memory variables:
  - `{{days_since}}`
  - `{{years_since}}`
  - `{{months_since}}`
  - `{{weeks_since}}`
  - `{{baby_age}}`
- Added `Docs/MemoryEngine.md` and `ADR-006` to document the new domain boundary.
- Added a dedicated `MemoryEngineTests` Swift Testing suite inside `PhotoMemoTests`.

### Changed
- Changed `CardVariableProvider` so memory-oriented values now flow through the shared Memory Engine boundary instead of ad-hoc inline fallback logic.
- Kept `memory_summary` behavior aligned with existing story-first and anchor-summary-first semantics.
- Started the repository's forward-looking version rhythm at `v0.7.0` for release-facing documentation.

### Notes
- This release intentionally does not change renderer, export, batch, or UI behavior.
- `MemoryEngineTests` currently lives inside the existing `PhotoMemoTests` target to keep the scope conservative while still providing repeatable verification.

## 2026-06-19

### Added
- Added a real `PhotoMemoiOS` target plus a buildable `PhotoMemoShareExtension` target.
- Added app-group-backed shared helpers for external intake persistence, shared defaults, and lightweight batch-configuration snapshot loading.
- Added a shared `ExternalPhotoIntakeRequest` model so the intake request schema is no longer tied to the main-app intake center file.

### Changed
- Continued shrinking `MainView` into a thin coordinator and moved more UI-heavy responsibilities into `MainView+*.swift` files.
- Refined the permission and background-processing surface so granted permissions stop occupying unnecessary sidebar space and failure summaries better describe partial-success batches.
- Changed share intake to support partial success, deduplicate repeated URLs, and filter stale/missing files before queue handoff.
- Tightened `PhotoMemoShareExtension` target membership so it now compiles against a much smaller shared core instead of dragging in the full main UI and unrelated app services.
- Updated share-extension feedback wording so partial-success messages only show non-zero skipped/failed counts.

### Notes
- The share-extension fallback path deliberately avoids `UIImage -> JPEG` re-encoding to reduce EXIF-loss risk before PhotoMemo starts real processing.
- Current iOS foundation is now target-ready and buildable, but still requires real share-sheet/manual workflow validation before calling the mobile flow polished.

## 2026-06-17

### Added
- Added a real bottom-card export pipeline with `RecordCardExportService`, save panel support, and rendered image output.
- Added source file tracking on imported photos so exports can reuse original metadata where possible.
- Added time-anchor based smart fields including age text, duration text, total day count, and anchor summary variables.
- Added a minimalist white system-style main interface with dedicated sections for photo import, template preset, time anchor, variable insertion, and field editing.
- Added export description generation so the rendered card's memory text can also be written into image metadata comment/description fields for later indexing.
- Added three real local presets for your current workflow: growth memorial, daily record, and gear note.

### Changed
- Refactored the card template model from a simple three-column structure to fixed semantic regions: left top, left bottom, right top, right bottom, and badge.
- Switched anchor calculations to use the photo EXIF capture time instead of the current system time.
- Updated date/time template variables to output zero-padded values for month, day, hour, minute, and second.
- Changed anchor editing to support precise date and time input.
- Reworked the live preview renderer to use orientation-specific bottom border proportions for landscape and portrait images.
- Changed photo import to stay local-only by default and stop automatic reverse geocoding during import.
- Updated export metadata sanitization to keep source properties, refresh rendered pixel dimensions, and write PhotoMemo descriptions into TIFF, IPTC, EXIF, and PNG metadata dictionaries when available.
- Polished the main screen with stronger status feedback, softer system-style chips, and cleaner field editor presentation.
- Removed the unused reverse-geocoding service so the default offline workflow no longer compiles deprecated location lookup code.
- Reduced the main variable picker to offline-safe fields by removing reverse-geocoded location placeholders from the default UI.
- Refined the bottom card renderer with cleaner white card styling, lighter dividers, better text hierarchy, and an invisible empty badge state for final exports.
- Changed template 1 to use the anchor summary as its default right-bottom memory line so preview text and exported metadata stay aligned.

### Notes
- Locked sample-derived border height ratios:
  - Landscape: `1021 / 4536`
  - Portrait: `753 / 8064`
- Current export preserves original metadata where possible through ImageIO property copying, while rendering a new final image file.
- The right-bottom memory text and anchor summary now share the same export description source to keep preview content and saved metadata aligned.

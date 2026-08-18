# Changelog

## 2.1.2 (86) User Delivery Reliability Maintenance - 2026-08-18

- Prevented a photo with no meaningful resolved content from entering Renderer or Export as a blank successful result; that photo now becomes an actionable task failure while other photos continue.
- Preserved graceful fallback when EXIF or smart-time information is missing but user-authored or other meaningful content remains available for delivery.
- Added `BatchDeliverySummary` semantics so completion and attention counts begin with the number of photos originally handed to MemoMark, while duplicate skips do not create false attention counts and unsupported media remain actionable.
- Made Share Extension handoff state explicit when photos are persisted but background processing has not started, so users can distinguish “received” from “processing started.”
- Added notification deep links that open the related processing status and focus the corresponding Job/Failure instead of leaving users at the app home screen.
- Added localized handoff and content-validation recovery messages in Simplified Chinese and U.S. English, with regression coverage for delivery summaries, whitespace-only content, diagnostics, deep links, and notification formatting.

This is a reliability maintenance update rather than a new product capability. Release evidence remains open for the physical-device Apple Photos workflow, the 20-photo mixed delivery matrix, notification cold-start/terminated-state behavior, visual and accessibility acceptance, StoreKit, TestFlight, App Store delivery, and production certification.

## 2.1.2 (85) Configuration Center, Device QA, And Continuity Maintenance - 2026-08-14

- Started from the finalized `1b3b9f7` source-sync checkpoint and reorganized the iOS root view's local state into explicit editor interaction, output draft, configuration projection, lifecycle, and presentation ownership containers.
- Kept `ConfigurationSession` as the live configuration truth while preserving the existing Configuration Center hierarchy and Memory Presentation Engine boundaries.
- Added Subject/Configuration identity protection for asynchronous album-option loading so stale results cannot be applied after a context switch.
- Added focused contract coverage for the extracted root state containers, output draft behavior, album-load identity, and root presentation state.
- Hardened the PhotoKit static-image and Live Photo save receipt lifecycle with a recoverable intent phase, post-commit acknowledgement, queue-startup reconciliation, and idempotent reuse behavior.
- Corrected the Apple ProRAW declaration to an imported UTI and retained original-photo protection across the input policy and output lifecycle.
- Restored the Device QA target, shared scheme, QA manifest, QA contracts, UI harness, and local verification scripts into the synchronized workspace, and raised all app, extension, widget, QA, and test target configurations to `2.1.2 (85)`.

This is a maintenance update rather than a new product capability. Release evidence remains open for full-suite completion, manual device interaction, Apple Photos lifecycle, StoreKit, TestFlight, and App Store delivery.

## 2.1.1 (80) Card Content, Logo, And Configuration Continuity - 2026-08-13

- Consolidated the source changes recorded after the 2026-08-09 `2.1.0 (76)` checkpoint, including the previously unpublished `2.1.1 (77)` subject work and the later Logo persistence closure.
- Kept Memory Subject, Configuration, card text, all four content regions, output settings, and Logo state synchronized after save, reload, and switching.
- Made Apple mini Logo, Subject Avatar, and custom-upload Logo distinct ownership paths so a custom Logo cannot accidentally reuse an avatar resource.
- Preserved custom Logo resources across configuration save, import, local backup/restore, legacy migration, and portable-path recovery, with a safe Apple fallback when a resource is unavailable.
- Unified circular Logo appearance across selection, live card preview, and final output, and rejected late picker results after a newer Logo choice has been made.
- Raised all app, extension, widget, and test target configurations to `2.1.1 (80)`.

Release evidence remains open for manual tap-through, Apple Photos lifecycle, high-cost media, StoreKit, TestFlight, and App Store delivery. Photos remain local-first, originals remain unchanged, and this source checkpoint does not itself represent a store submission.

## 2.1.2 (79) Subject, Logo, Workflow, And Progress Closure - 2026-08-12

- Consolidated all user-facing changes after the 2026-08-09 `2.1.0 (76)` source checkpoint, including the unpublished 2.1.1 subject-switching work, into one 2.1.2 release candidate.
- Improved Memory Subject avatar framing, scaling, circular crop preview, and saved composition continuity.
- Made Memory Subject edits durable before updating live state and preserved drafts on save failure.
- Kept subject, anchor, card content, output, and Logo context synchronized across save, switch, and reload.
- Unified custom Logo uploads, previews, and rendering as circular identity marks.
- Fixed custom Logo asset paths being dropped during configuration save and restored portable paths to runtime paths on reload.
- Added a compact Home workflow reminder and removed the unexplained “备用” prefix from the in-app photo picker.
- Added durable final-result thumbnails to Progress history, with a deterministic representative image and count badge for multi-photo jobs.
- Added portable Job-level cover persistence, missing-file healing, legacy fallback, bounded retention, notification-attachment release, and two-pass orphan cleanup without retaining original photos.
- Raised all app, extension, widget, and test targets to `2.1.2 (79)`.

## 2.1.1 (77) Memory Subject Consistency Fix - 2026-08-11

- Fixed iOS Memory Subject switching so the selected subject, saved or draft
  configuration, time anchor, logo, output settings, custom memory text, and
  region previews refresh as one configuration context.
- Preserved the distinction between a durable saved configuration and a
  subject-synced draft when switching to a subject without saved configuration.
- Added regression coverage for destination subject identity and subject-region
  preview refresh.
- Raised all app, extension, widget, and test target version fields to
  `2.1.1 (77)`.
- Release evidence remains open; the simulator was unavailable during this
  pass and the remaining signed-device interaction checks are separate.

## 2.1.0 (76) Major Experience Update - 2026-08-09

- Rebuilt the four-region card-content editor around a full, unobstructed
  output preview, explicit region navigation, continuous TextKit composition,
  and clearer Done versus keyboard-dismiss behavior.
- Refined Configuration Center, Memory Subject, Settings, welcome guidance,
  and small-screen hierarchy in response to user feedback.
- Added today's time answer to Memory Subject surfaces and clarified the
  important-date setup flow without changing capture-time output truth.
- Improved user-facing recovery for photo picking, failed-task retry, Share
  intake, and duplicate purchase/restore/redemption actions.
- Prepared synchronized in-app, App Store, TestFlight, and internal release
  materials for `2.1.0 (76)`; release evidence remains open.

## 2.0.3 (70) Memory Expression And Save Recovery - 2026-08-06

### Fixed
- Aligned Memory Expression and compatibility paths with the photo capture
  time zone's calendar day, including a natural birthday-day result instead
  of `0 days`.
- Preserved exact receipt-backed Apple Photos saves across ambiguous readback,
  startup recovery, and later asset visibility without rerendering or creating
  replacement output.
- Unified the complete Memory Expression and optional user-authored Photo
  Description text through one newline-separated composition contract.

### Changed
- Refined Configuration Center device fit, Memory Subject and Time Anchor
  state consistency, adaptive presentation tokens, and Output presentation.
- Added persistent System, Light, and Dark appearance preferences while
  preserving the fixed visual semantics of rendered photos.
- Raised the macOS app, iOS app, Share Extension, Widget Extension, and test
  target configurations to `2.0.3 (70)`.

### Release Boundary
- This GitHub source checkpoint does not close `TX-001` signed-device Apple
  Photos interruption, restart, or delayed-visibility evidence.
- `BP-001` 48MP/RAW peak-memory evidence remains open. The production
  certification verdict remains `FAIL (Conditional)` and must not be
  represented as complete.

### Verification
- The complete macOS `PhotoMemoTests` run passed `1,317` tests, skipped `1`,
  and failed `0`.
- Unsigned macOS and generic-iOS Debug builds passed. Built Info.plists for the
  macOS app, iOS app, Share Extension, and Widget Extension all report
  `2.0.3 (70)`.

## 2.0.2 (69) Production Reliability And Compatibility - 2026-08-04

### Fixed
- Removed a generic continuation-holder shape that crashed the Xcode 26.6
  Swift Release optimizer while compiling the Share Extension. Completion and
  timeout arbitration now use non-generic, lock-protected responsibilities
  without disabling production optimization.
- Repaired Live Photo preservation across Apple Photos Share intake, queue
  routing, identity recovery, processing, and PhotoKit save-back. An
  `originalFormat` Live Photo no longer silently succeeds as a still image.
- Restored composed-variable compatibility during configuration restore and
  Preview so legacy combined expressions do not fall back to internal English
  names or render raw placeholders.
- Replaced duplicated module identity and title catalogs with stable module
  identities and localized display names shared by configuration, Preview, and
  final output.

### Added
- Added concrete configuration-save and photo-processing failure reasons,
  recovery guidance, and short support IDs.
- Added bounded, local-first, sanitized diagnostics export for Settings ->
  Feedback. Reports exclude photos, authored text, locations, filenames,
  paths, asset identifiers, and free-form system descriptions.
- Added actionable input classification for oversized, extreme-aspect-ratio,
  unreadable, unsupported, permission, storage, and Live Photo failures.

### Changed
- Long custom content remains durable user-authored content; visual fitting is
  separate from configuration persistence and does not itself cause save
  failure.
- PhotoKit Live Photo saves require post-save verification of `.photoLive`,
  still and paired-video resources, valid dimensions, and motion duration
  before reporting success.

### Release Boundary
- This is a V4 Engineering Loop maintenance release. It preserves the
  local-first workflow, original-photo protection, Configuration Center
  architecture, Memory Engine, Layout Engine, Renderer, Export, and Share
  Extension ownership boundaries.
- Physical Apple Photos Live Photo round-trip acceptance remains a separate
  device-evidence step; the currently paired iPhone may need to reconnect as
  available before installation.

### Verification
- Focused Live Photo, diagnostics, configuration compatibility, Share intake,
  and release-note tests passed; the complete `PhotoMemoTests` suite passed
  with `1,272` tests passed, `1` skipped, and `0` failed.
- The Xcode 26.6 optimized Release Share Extension build and complete unsigned
  generic-iOS Release archive passed. macOS, iOS, Share Extension, and Widget
  Extension builds passed; all product and test target version fields report
  `2.0.2 (69)`.
- `git diff --check` and Chinese/English `Localizable.strings` plist lint
  passed.

## 2.0.1 (67) App Store Version Train Repair - 2026-08-03

### Fixed
- Reopened App Store delivery on marketing version `2.0.1` after public version
  `2.0` closed its upload train and Xcode Cloud Build 66 returned
  `action_required` during App Store Connect preparation.
- Projected verified MemoMark+ purchase identity on the production Home header.
  First Recorder identity remains preserved and is presented there only while
  current verified Plus Access is active.
- Kept edited Memory Subject names synchronized across Home, the Configuration
  Center top summary, and subject overview after first-run setup is deferred.

### Changed
- Raised the macOS app, iOS app, Share Extension, and Widget Extension to
  `MARKETING_VERSION = 2.0.1` and raised all product and test target
  configurations to `CURRENT_PROJECT_VERSION = 67`.
- Updated the in-app Simplified Chinese and English What's New copy for the
  current maintenance release, Home identity, and Memory Subject repair.

### Release Boundary
- StoreKit, entitlement resolution, allowance, durable identity, Renderer,
  Export, PhotoKit, Share Extension processing, and original-photo behavior are
  unchanged.
- V4 Expression Style and BrandMark research, private media, screenshots,
  signed packages, and retained archives remain local-only.
- Local verification does not claim Xcode Cloud Build 67 or App Store Connect
  acceptance. Release Authorization remains `Not Authorized` pending that
  external evidence.

### Verification
- `61/61` focused release-note, Commerce, responsive-layout, identity
  projection, and edit-flow tests passed.
- The complete serialized macOS suite passed `1,221` tests, skipped `1`, and
  failed `0`; macOS and generic iOS Simulator Debug unsigned builds passed.
- Built Info.plists for the macOS app, iOS app, Share Extension, and Widget
  Extension all report `2.0.1 (67)`. Project/localization plist lint and
  whitespace validation passed.

## 2.0 (66) Commerce v1 Internal Closure Candidate - 2026-08-03

### Fixed
- Separated current MemoMark+ Access from historical First Recorder identity in
  the Settings projection. A retained commemorative date no longer claims
  unlimited recording after current Plus Access is absent.
- Added matching Simplified Chinese, English, and VoiceOver presentation for
  the historical First Recorder keepsake.

### Changed
- Raised the shared app, extension, macOS host, and test-target Build Number
  from `65` to `66` without changing marketing version `2.0`.
- Reconciled the test-only iOS root-size guard with the accepted Build 65
  purchase-flow coordination that had already moved the root past its old
  threshold; no root-view source changed in this candidate.
- Recorded Commerce v1 internal closure and its Release Candidate identity gate.
  Commerce feature expansion remains unauthorized.

### Candidate Scope
- This candidate is based on the existing `2.0 (65)` App Review purchase-entry
  repair and adds only FRI-002 projection closure plus its contracts and release
  governance.
- Uncommitted V4 Expression Style research and M01 time-determinism work from
  the primary workspace are explicitly excluded.
- Sandbox, TestFlight, App Review, refund/revocation, Offer Code, and Family
  Sharing remain external evidence and are not implied by local validation.

## 2.0 (65) App Review Recovery Candidate - 2026-07-30

### Changed
- Returned the App Store submission train to marketing version `2.0` and raised
  the build number to `65` across the app, Share Extension, Widget Extension,
  macOS host, and test target.
- Updated the in-app What's New sheet in Simplified Chinese and English to
  identify this candidate and explain the MemoMark+ purchase-entry repair.

### Fixed
- MemoMark+ now always exposes the StoreKit purchase action to users without a
  verified entitlement. If the App Store cannot return the product, the app
  explains the condition and preserves a retry action instead of accepting a
  tap without visible feedback.
- Settings now owns the MemoMark+ purchase sheet, so closing it returns to
  Settings rather than presenting the page only after returning to Home.

### Verification
- Focused release-note and MemoMark commerce suites, localization syntax,
  generic iOS Debug build, signed iOS Debug build, and strict nested-signature
  verification passed.
- Signed `2.0 (65)` installed in place and launched on the connected iPhone 17
  Pro Max without clearing its app container.
- A real StoreKit purchase-confirmation sheet remains an external App Store
  Connect and clean-Sandbox acceptance requirement; it is not inferred from
  the local build or device installation.

## 2.0.1 (48) Release Candidate - 2026-07-30

### Added
- Added an in-app What's New sheet under Settings -> About, localized in
  Simplified Chinese and English.
- Added a release note covering the July 27-30 V3 production-quality pass.

### Changed
- Hardened Apple Photos Share handoff, background processing recovery, queue
  admission, retry classification, and duplicate-save protection.
- Improved configuration save, restore, rename, subject switching, backup,
  and real Memory Card preview continuity.
- Refined the iOS root-view ownership boundaries, compact-device layout,
  Configuration Center hierarchy, Settings information center, and narrative
  product language.
- Refined the Advanced Modules sheet and compact Memory Expression row while
  preserving their native menus, bindings, and accessibility fallbacks.
- Replaced the Share status attachment paragraph with independent native rows,
  improved heading semantics and action sizing, and completed bilingual copy.
- Closed the V3 production-quality cycle with `2.0.1`. V4 starts with
  Expression Style research and remains the final refinement stage for the
  main interface, existing features, interaction logic, and device fit,
  without a large-scale core-flow or architecture rewrite. After V4, routine
  releases stop unless a material issue or required platform-maintenance need
  appears.
- Raised the marketing version to `2.0.1` and the next build to `48`.

### Fixed
- Carried the saved time-display configuration through production snapshots
  and final card construction so Daily Record output retains its weekday and
  matches Configuration Preview.
- Closed a missing Share checklist localization key found during pre-sync
  review.

### Verification
- Added or updated focused contracts for background processing, settings,
  release notes, localization, configuration lifecycle, media output, and
  responsive UI behavior.
- Full macOS `PhotoMemoTests` regression passed with `1,214` passed, `1`
  skipped, and `0` failed; macOS, generic iOS, and Share Extension Debug
  builds also passed.
- Signed build `2.0.1 (48)` was installed in place on one iPhone 17 Pro Max
  and two iPhone 15 Pro devices without clearing their app containers.
- Physical Apple Photos lifecycle and accessibility acceptance remain separate
  release evidence.

See `Docs/07_Releases/2026-07-29-2.0.1-v3-production-quality-update.md` for the
full scope and synchronization boundary.

## 2.0 (47) Release Candidate - 2026-07-24

### Added
- Added the Apple-managed MemoMark+ lifetime purchase, restore, redemption,
  first-recorder identity, local credit ledger, and TestFlight experience flow.
- Added Simplified Chinese and English localization for commerce, settings,
  usage status, transaction feedback, and Memory Anchor presentation.
- Added App Store Connect setup guidance and screenshot/App Preview release
  specifications.

### Changed
- Free users receive 200 initial successful-record credits and a 20-photo batch
  limit; MemoMark+ unlocks unlimited records and a 40-photo batch limit.
- Major-version gifts append credits once per major version instead of resetting
  the user's existing balance.
- Settings now places Language before version information, expands feedback
  channels, and reads the displayed version directly from the app bundle.
- Output naming again follows the original asset name and persistently advances
  duplicate suffixes such as `IMG_1642 (1)` and `IMG_1642 (2)`.

### Fixed
- Removed the main-thread full-library scan that could leave PhotoKit work at
  99%, replacing it with local save receipts and identifier-scoped lookups.
- Strengthened queue recovery, duplicate completion handling, static/Live Photo
  save consistency, and deterministic Live Photo regression testing.
- Isolated Production, Sandbox, and local Xcode commerce state so TestFlight
  activity cannot grant or consume Production entitlements and credits.

### Verification
- Passed the complete Xcode 26.6 regression: `1,032/1,032` tests across 182
  suites.
- Passed build, property-list validation, and whitespace checks for the 2.0
  release candidate.
- See `Docs/07_Releases/2026-07-24-2.0-upgrade-summary.md` for the full three-
  synchronization upgrade and release-risk summary.

## 1.7 (7) Post-push UI And Reliability Closure - 2026-07-23

### Added
- Added shared MemoMark design tokens and semantic iconography contracts for
  the Configuration Center visual baseline.
- Added the `MemoMark Share Design v1` specification and compact Share
  Extension module structure.
- Added queue persistence, Share handoff, cancellation, and PhotoKit
  consistency regression coverage.

### Changed
- Unified main-app content bounds, card hierarchy, inner panels, typography,
  and semantic icons around the Configuration Center.
- Changed Share request acknowledgement to occur after successful enqueue or
  an explicit terminal drop decision.
- Added read-back verification and surfaced persistence failures instead of
  silently continuing with uncertain queue state.
- Added task-scoped PhotoKit save identities and same-process save
  serialization for static images and Live Photos.

### Verification
- macOS, iOS, and Share Extension unsigned Debug builds passed.
- Signed `1.7 (7)` device build installed and launched on `iPhone7` (iPhone 17
  Pro Max) without clearing existing app data.
- Existing full-suite evidence remains `1,005` passed, `1` skipped, `0`
  failed; a fresh Xcode beta test run stalled in the test service and was
  interrupted.
- Strict PhotoKit commit recovery, high-cost-media budget enforcement, and
  forced-termination Apple Photos evidence remain open V3 certification work.

## 1.7 (7) Repository Update - 2026-07-21

### Added
- Added subject-aware Memory Source disclosure state. Manual collapse remains
  stable for the current subject, while switching subjects expands the section.
- Added reusable Configuration Center window/card hierarchy and iOS semantic
  iconography research specifications.
- Added the deferred Expression Style System research seed and V3 Production
  Reliability Certification report.

### Changed
- Memory Subject switching now restores the subject-owned durable configuration,
  selected Time Anchor, and editor drafts without requiring another save action.
- Custom Memory write content now supplements Smart Module output instead of
  replacing it.
- The Memory Subject overview now uses the Configuration Center's 18pt page
  margin, 14pt card padding, 18pt radius, and bounded content rules.

### Fixed
- Fixed Apple Photos descriptions dropping Smart Module and trailing Memory
  region fields by resolving the complete `CardTextBlockEngine` result.
- Fixed stale active configuration pointers after switching Memory Subjects.
- Fixed Memory Subject fields and anchor cards expanding beyond the page width.

### Removed
- Removed the retired `Views/Main/MainView*` Workspace/Composer editor path and
  its obsolete tests. Shared file-representation logic now lives in Services.

### Verification
- Reused the completed focused regression, macOS/iOS build, signed-device
  installation, and physical-device acceptance evidence.
- The latest Memory Subject card hierarchy was accepted on iPhone 17 Pro Max.
- BrandMark research and integration files are intentionally excluded from this
  repository update.

## 1.7 (7) - 2026-07-17

### Added
- Added a collapsible Home feedback card for the active TestFlight phase. It
  keeps Xiaohongshu and Douyin search guidance, QQ group `955680366`, and the
  existing TestFlight feedback path visible without adding network behavior.
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
- Simplified the Memory Subject profile section into continuous native rows and
  aligned Expression Subject selection with the shared Configuration Center
  selected-state styling.
- Standardized current release documentation on the product version identifier
  `1.7 (7)` and recorded successful signed-device Live Photo flows for both the
  Main App Picker and Share Extension.
- Clarified the expression model as Subject + Smart Output + Anchor Result.
  Smart modules continue to provide reusable time results, while users retain
  control over the final sentence wording.
- Updated Live Photo still output metadata so MemoMark description text is written through stable TIFF/IPTC fields while avoiding corrupted non-ASCII HEIC UserComment readback.
- Clarified release scope: Main App Picker and Share Extension Live Photo
  flows have both succeeded in signed-device validation; broader production
  certification remains tracked separately in the V3 evidence matrix.
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

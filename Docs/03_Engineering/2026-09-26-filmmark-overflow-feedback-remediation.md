# FilmMark Overflow Feedback Remediation

Status: implemented; manual device review pending

## Decision Gate

- Primary loop: Engineering Loop. The observed failure is a gap between an
  existing Layout result, the configuration preview, and the production render
  health check.
- Observed scenario: FilmMark Layout already resolves
  `isContentOverflowingSafeArea`; the preview raster layer can omit its image
  after a swallowed rasterization error, while export rejects the overflow
  later with a generic render failure.
- Owner: Layout Engine remains the owner of overflow truth. Configuration UI
  projects that result. `ProductionRenderHealthCheck` validates the resolved
  card after source metadata and actual text are available, before Renderer and
  export work. Renderer and export retain their existing fail-closed boundary.
- Source of truth: `FilmMarkPresentationResolver` plus
  `FilmMarkLayoutSpecification`; no duplicate UI or export geometry rule.
- Apple capability: use native SwiftUI text, `Label`, and system material for
  a restrained inline warning. No new framework, permission, dependency, or
  lifecycle is needed.
- Risk: P1, because predictable presentation overflow can otherwise become an
  unexplained failure in a primary workflow. Original-photo and output
  transaction boundaries remain unchanged.
- Admission boundary: exact preflight cannot run before photo metadata and
  resolved content exist. The production gate therefore fails before actual
  rendering/export, after preparation. The Configuration Center preview gives
  earlier guidance against its resolved sample canvas.

## Intended Outcome

- The full-photo and geometry-calibration previews show a localized, accessible
  explanation when Layout reports overflow, with concrete recovery actions.
- The production render health check rejects the same overflow before
  rasterization/export and maps it to a dedicated localized task failure.
- Editing and saving configuration remain available. Renderer continues to
  reject invalid output; no truncation or silent-success behavior is added.

## Bounded Change Set

- `Source/MemoMark/MemoMark/iOS/Views/FilmMarkPreviewSurface.swift`
- `Source/MemoMark/MemoMark/Models/ProductionConfigurationContract.swift`
- `Source/MemoMark/MemoMark/Models/ProductionDiagnosticEvent.swift`
- `Source/MemoMark/MemoMark/{zh-Hans,en,ja,ko}.lproj/Localizable.strings`
- focused production-health, diagnostics, and localization tests
- this record, updated with implementation and verification evidence

No queue admission redesign, durable configuration change, renderer geometry
change, original-photo mutation, Share Extension work, or unrelated UI polish is
in scope.

## Verification Plan

- Swift Testing proves valid FilmMark cards pass and overflow cards fail at the
  production health boundary; other presentation styles remain unaffected.
- Diagnostic tests prove the overflow receives a distinct actionable message;
  localization parity covers all four supported languages.
- Build the current iOS target and run focused tests against this working tree.
- Install the exact signed build on the paired iPhone 17 Pro Max for manual
  preview, Dynamic Type, and VoiceOver review. Simulator output is not physical
  device acceptance.
- Report any unavailable device or failed test-runner evidence as unverified.

## Implementation And Evidence

- `ProductionRenderHealthCheck` now resolves FM against the imported photo's
  pixel dimensions and throws a distinct content-overflow error before the
  static renderer/export path. Existing Live Photo render-health validation
  uses the same check before its overlay/export call.
- Full-photo and geometry-calibration previews now show the Layout-owned
  overflow state with recovery guidance. The accessibility value includes the
  warning and recovery text while preserving the authored output text.
- Production diagnostics map overflow to a dedicated failure code and
  localized recovery guidance. Simplified Chinese, English, Japanese, and
  Korean resources were updated.
- The new overflow regression test failed before the health-check change and
  passed afterward. A current suite-level macOS run reported 26 passed and one
  failed test. The new FilmMark overflow/accessibility assertions passed; the
  sole failure is the separate portrait viewport-ratio assertion in
  `productionPreviewsSelectSharedAssetsAndCanvasRatios` (`1.2784` absolute
  difference), whose viewport code is outside this change. An earlier
  individual-method filter returned an `unknown` result with zero tests; it is
  not counted as verification.
- Generic iOS build passed. A signed device build from the earlier remediation
  pass passed as `2.3.3 (111)`;
  deep code-signature verification passed. The build was installed over the
  existing app on the paired iPhone 17 Pro Max and launched successfully; no
  app data was cleared.
- Manual preview appearance, Dynamic Type, and VoiceOver review on the iPhone
  remains pending. Install and launch are deployment evidence only.

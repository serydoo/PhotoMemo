# Configuration Preview Header Alignment — 2026-10-11

## Decision record before implementation

- **Observed behavior:** In the supplied landscape captures, Configuration Center's page heading begins noticeably farther right than its configuration rows. The rows and Progress page share the same readable-column leading edge; the preview heading is centered against the full viewport.
- **Intended outcome:** In floating-rail landscape, the Configuration Center preview heading and preview align with the same rail-reserved readable column used by the configuration rows. Portrait and the dedicated full-width compact-landscape preview policy retain their current geometry.
- **Owner and boundary:** `MemoryCardEditorPageSurface` owns the preview pane's adaptive viewport geometry; `AdaptivePageLayout` owns the shared readable-column and rail-reservation math. No configuration state, preview data, editor identity, renderer, or navigation ownership changes.
- **Primary loop / risk:** Product Loop, based on the owner's observed screenshots; P2, bounded visual alignment.
- **Apple capability evaluated:** SwiftUI `GeometryReader` and existing safe-area/navigation layout are sufficient; no custom drawing or orientation-specific fixed offsets are needed.
- **Verification:** Add a source contract proving preview headings use the live viewport and the same trailing rail reservation as editor rows; run the focused contract test and iOS build; inspect Configuration Center in landscape and portrait on the paired physical iPhone 17 Pro Max. If the phone or focused test runner is unavailable, report that evidence boundary explicitly.

## Implementation and evidence

- `MemoryCardEditorPageSurface` now passes the live page viewport into its preview pane and uses the shared `adaptiveScrollContent` calculation for ordinary preview layouts. The same floating-rail reservation is applied to both the preview heading and editor rows. The explicit full-width compact-landscape preview branch remains unchanged.
- Added `configuration preview header shares the rail-reserved editor column` to `IPhoneResponsiveLayoutContractTests`.
- Xcode 27.0 iOS Release generic build succeeded; signed `MemoMarkiOS` Release build succeeded, strict codesign verification passed, and build `2.3.6 (124)` installed and launched on the paired iPhone 17 Pro Max. This was a local candidate, not a Store release.
- `git diff --check` passed. The focused `IPhoneResponsiveLayoutContractTests` run executed 61 cases: the new `configurationPreviewHeaderSharesEditorColumn` contract passed; 58 passed overall and 3 unrelated source contracts failed (`adaptiveEntryNavigationIsStatelessAndPreservesAllDestinations`, `landscapeFloatingRailReservesSafeContentViewport`, `primaryVerticalPagesAdoptSharedViewportContract`). These assertions target existing navigation/page viewport contracts and are outside this slice; the test run is therefore not fully green.
- After the owner locked the phone, iPhone Mirroring connected and the signed build's Configuration Center was opened. The portrait preview heading and configuration rows now share the same leading edge. The device was returned to portrait after orientation inspection. Landscape alignment remains **NOT VERIFIED** on-device: `devicectl` reported landscape sensor orientation while the actual display stayed at portrait bounds/rotation. No photo or purchase state was touched.

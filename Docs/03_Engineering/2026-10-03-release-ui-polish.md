# 2.3.5 (116) release UI polish

Product Loop; owner: iOS presentation and existing interface localization.
Observed: anchor editing and local backups bypass interface-language lookup;
editor copy exposes Module terminology; five-segment language/expression
choices can compress labels; commerce Done uses its own caption typography.
Risk: P1 localization/accessibility and primary selection surface; P2 copy/chrome.

Scope: SubjectAnchorDetailSection, LocalConfigurationLibrarySheet,
CardContentInspectorSurface, MemoryCardRegionEditorCluster,
InterfacePreferencesContent, ConfigurationOptionList, MemoMarkPlusPurchaseView,
and four existing Localizable.strings. Preserve existing dirty edits.
Use existing MemoMarkLanguage lookup, shared browser-sheet toolbar and native
Picker menu. Language always uses menu. Expression choices use intrinsic
uncompressed label width to decide segmented/menu, and menu at accessibility
sizes. Card-style selection is unchanged.

No Renderer/Export/Photos/Live Photo/Preset schema/ConfigurationSession changes.
Owner has accepted current preview collapse/reveal: preserve it unchanged.
Footer accessory migration is deferred: current safe-area footer belongs to
ConfigurationPageSurface, while TabView lives above the editor. Moving it would
require a hosting contract across save-state ownership; separate scoped work
and physical-device acceptance are needed.

Verification: localization syntax/key/format consistency, focused macOS-host
contracts, iOS device build, diff check and scoped review. Four-language visual,
VoiceOver and large-text acceptance of this new pass must be reported separately.

## Closure evidence

- Anchor/backup direct control literal gate: pre-edit 24 + 17 violations;
  current 0 + 0. 54 lookup keys exist in all four dictionaries; EN/KO
  have no Han-text leakage in those keys. Localizable.strings lint passed.
- Added release-surface localization/format/selection regression tests.
  Updated two existing copy assertions to the accepted information wording.
- Focused macOS-host tests: 105 passed, 0 failed, 0 skipped;
  `/tmp/MemoMarkUIPolishMirrorTests.xcresult`.
  Original Desktop run blocked in Foundation file open (process sample:
  `/tmp/MemoMarkUIPolishTestHost.sample`). Tests were run from a current-source
  copy in `/tmp/MemoMarkUIPolishMirror`, with unchanged assertions. Scoped UI
  files were byte-compared against main. This is automated contract evidence,
  not visual acceptance.
- iOS generic-device build and final signed physical-device build passed.
  `/tmp/MemoMarkUIPolishDevice.log`, `/tmp/MemoMarkUIPolishSignedFinal.log`.
  Strict signature verification and overwrite install on paired iPhone 17 Pro
  Max passed. Build remains 2.3.5 (116); no container reset.
  Launch was denied because the device was locked.
- `git diff --check` passed. Existing SDK deprecation/concurrency warnings remain
  outside scope. Review found no changes to save/restore/entitlement semantics.
- New language menu/expression adaptive layout needs four-language ordinary and
  large-text, VoiceOver, iPad and device visual acceptance. Card-style picker
  and preview portions byte-match the pre-edit snapshot.
- Also localized the active editor guidance and two Home accessibility labels.
  Preserved user-entered/stored anchor titles, notes, internal Module types and
  durable schemas. No commit, push or Store action.

## Continuation scope (2026-10-03)

Live working-tree review confirms the first pass already includes localization,
editor copy, shared commerce toolbar, language menu and expression fit handling.
This bounded P2 follow-up closes the remaining system-information category and
insertion-position accessibility copy, including fallback text in the photo
information library. Existing interface-language lookup owns these labels.
No input geometry, preview disclosure, selection binding or durable semantics
will change. Validate four dictionaries, existing focused contracts and an iOS
generic-device build; physical-device visual acceptance remains separate.

### Continuation verification

- Four Localizable.strings syntax checks passed; new insertion-position key
  occurs exactly once in every dictionary.
- Current iOS generic-device Debug build passed (signing disabled):
  `/tmp/MemoMarkUIContinuationBuild.log`.
- ReleaseUIPolishTests, ConfigurationOptionListContractTests and
  IPhoneResponsiveLayoutContractTests: 102 passed, 0 failed, 0 skipped;
  `/tmp/MemoMarkUIContinuationTests.xcresult`. The existing temporary mirror
  was refreshed; all iOS View and architecture-test Swift sources and four
  dictionaries byte-match the current Desktop checkout.
- `git diff --check` passed. Scoped review found only localized display and
  accessibility copy changes; preview disclosure, core semantics and
  selection bindings were untouched by this continuation.
- No device installation or manual visual/VoiceOver acceptance in this
  continuation. Prior signed-build/install evidence belongs to the first pass.
- Footer accessory, settings navigation/grouping and preview button chrome
  remain deferred pending a separate bounded interaction/visual specification.
  No commit, push, upload or Store action.

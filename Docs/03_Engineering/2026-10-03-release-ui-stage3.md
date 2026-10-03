# Release UI stage 3 — bounded P2 pass

## Decision before implementation

Product Loop. Live baseline: main 90502e8a plus existing dirty work. First two
passes are present: four-language anchor/backup/editor copy, common commerce
Done toolbar, language menu, adaptive expression selection, preview disclosure.
Preserve all existing changes and unrelated research/outreach files.

Owner: iOS Settings presentation; Configuration Center retains save, dirty,
saved, failure and action ownership. Risk P2 visual hierarchy; P1 navigation
compatibility and accessibility verification. No domain/schema/media change.

Current footer is a separate rounded material island above the Tab Bar. Apple's
`tabViewBottomAccessory` hosts content at TabView and adapts expanded/inline
placement (https://developer.apple.com/documentation/swiftui/view/tabviewbottomaccessory(content:)).
Current TabView is inside the shell NavigationStack; footer is inside the
configuration page's safe-area inset, suppressed while editing or on regular
layout. Accessory migration would need a new cross-layer view-hosting contract,
visibility/lifecycle handling and compact/regular/old-system acceptance. It can
preserve business ownership in principle, but is too broad for this release pass.
Use lighter chrome: remove footer's enclosing rounded material and border; keep
button chrome, geometry, confirmation, availability and safe-area ownership.

Settings: retain Plus hero and Getting Started emphasis. Combine secondary
persistent disclosure sections into one grouped surface with separators,
retaining expansion storage and all controls. Let navigation bar manage its own
background. Push About narrative, expression help, workflow and release notes in
the existing NavigationStack. Shared workflow/release surfaces keep modal defaults
for other callers. Welcome information also pushes; retain the separate FirstRunConfigurationSheet
save/defer transaction and commerce/diagnostics sheets.

Preview controls: visible disc 34pt, outer hit area 44pt with circular content
shape; reduce chevron font 18 -> 15pt. Preserve callbacks, gestures, VoiceOver,
orientation, zoom and accepted disclosure. Suggestions: smaller secondary title,
quieter example badge and plain 44pt minimum Add action; no anchor policy change.

Verification: current iOS build; focused settings, welcome, preview, responsive,
anchor and release contracts; git diff --check; compare baseline source hashes
for forbidden changes and inspect scoped diff. Physical-device four-language,
large text, VoiceOver, gestures and light/dark material acceptance is separate.

## Implementation and review

- Settings keeps Plus and Getting Started as standalone surfaces; six secondary
  disclosure sections share one grouped surface and separators. Existing seven
  expansion storage keys/defaults, summaries, controls and support actions remain.
- Expression help, About narrative, workflow, Welcome information and update log
  push within the existing stack. Welcome's workflow destination is attached to
  the Welcome page so Back returns there before Settings. Existing modal callers
  of shared narrative views retain their NavigationStack by default.
- Removed forced navigation-bar color/visibility. Commerce, diagnostics sharing
  and the separate first-run transactional editor retain modal presentation.
- Footer loses enclosing material/border only. Save title/icon, retry/disabled
  behavior, reset/delete confirmation and all configuration callbacks remain.
  Navigation shell and ConfigurationSession are unchanged.
- Preview controls use 34pt discs inside 44pt targets; arrows use 15pt symbols
  and semantic foreground. Swipe, zoom/orientation state functions and the
  accepted page disclosure source are unchanged from this session's baseline.
- Suggested anchors use secondary 15pt-style title, lighter badge and plain Add
  button with 44pt label target. Real anchor rows and activation policy unchanged.
- Scoped review: eight UI Swift files, four existing test files and this record.
  Initial source hashes confirm no Renderer/Export/Photos/Live Photo/Preset
  schema/ConfigurationSession/core changes. No localization resource changes.

## Verification and limitations

- Final iOS generic-device Debug build (signing disabled): PASS,
  `/tmp/MemoMarkUIStage3VerifiedBuild.log`.
- Focused macOS-host contracts: 99 passed / 0 failed / 0 skipped,
  `/tmp/MemoMarkUIStage3VerifiedTests.xcresult`. Covers Settings disclosure/help,
  welcome, release localization, responsive layout, preview visibility and time
  anchor editing. A temporary current-source mirror avoids known Desktop
  Foundation file-read blockage; all Swift and localization resources byte-match.
- The initial contract run exposed four stale assertions: sheet terminology,
  explicit workflow-close callback, a pre-localization literal title and the old
  segmented language control. Updated to current authorized contracts; all
  behavioral and remaining structural assertions retained.
- A stronger simulator navigation test reproduced a real sibling-destination
  issue in Welcome -> Workflow -> Back. Fixed by scoping Workflow destination
  to Welcome. A subsequent update-log test assumed collapsed About despite its
  persisted expanded preference; test now reads accessibility expansion state.
- Ordinary Chinese Settings simulator screenshot inspected: Plus/Getting Started
  hierarchy and shared secondary grouping are visible. This is scoped simulator
  observation, not four-language or physical-device acceptance.
- `git diff --check`: PASS. Existing toolchain warnings are outside this pass.
- No commit, push, physical-device install, StoreKit purchase, upload or Store action.

| Gate | Status | Evidence | Risk or gap | Next action |
|---|---|---|---|---|
| Build and unit contracts | PASS | Current iOS build; 99 contracts | No physical certification | None for bounded source checks |
| Accessibility | NOT VERIFIED | 44pt targets and existing labels/actions retained | VoiceOver, contrast, large text untested on device | Paired iPhone check |
| Localization | NOT VERIFIED | Resources unchanged; release localization contracts pass | Four-language layout not manually checked | Ordinary/accessibility sizes in four languages |
| Performance | N/A | Presentation-only changes; no processing work added | No measured performance claim | None |
| Physical device | NOT VERIFIED | No device installation in this pass | iPhone/iPad and older-system material/gesture fit | Separate device acceptance |

Accessory migration remains intentionally unimplemented. Its expanded/inline
placement and cross-layer host lifecycle need a separate bounded host contract
and compatibility matrix. Configuration Center must remain the business owner.

### Final navigation evidence

- `MemoMarkDeviceQAHarnessTests/testSettingsInformationPushReturnsToSettings`:
  1 passed / 0 failed on iPhone 17 Pro simulator, iOS 26.5.
  `/tmp/MemoMarkUIStage3NavigationTests.xcresult`.
  Covers expression guide, About narrative, workflow, Welcome and release notes;
  native Back returns to the same Settings page, including Welcome -> Workflow
  -> Welcome -> Settings. The test respects persisted About expansion state.
- Final source and test mirror byte comparison passed; `git diff --check` passed.
- Navigation gate: PASS for this simulator route only. Physical iPhone/iPad,
  swipe-back and four-language accessibility acceptance remain NOT VERIFIED.

## Subsequent owner-authorized phone delivery (2026-10-03)

After the source pass, the owner asked to push these changes to the phone.
Current signed Debug build: `/tmp/MemoMarkUIStage3Phone`, exact paired
physical iPhone 17 Pro Max destination. Build and strict signature verification
passed. Overwrite install of `com.serydoo.PhotoMemo.iOS` passed without uninstall
or data reset. Direct launch passed; app PID 52311 and widget processes were
observed alive. Installed app readback confirms 2.3.5 (116).

This supersedes the earlier no-device-install status for deployment only.
Manual visual, multilingual, VoiceOver, gesture and Photos acceptance remains
NOT VERIFIED. No GitHub push or Store action was performed.

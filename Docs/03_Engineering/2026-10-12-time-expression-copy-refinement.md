# Time expression copy refinement — 2026-10-12

## Decision before implementation

Product Loop / P2. Owner observations IMG_7252 and IMG_7226 show redundant helper copy below the time-expression choices consuming portrait and landscape space. Owner approves the top helper “围绕设定的时间锚点，选择不同语气的时间表达。” and removal of the optional-content helper, then signed installation on the paired iPhone 17 Pro Max.

Scope: ConfigurationOptionList memoryDisplayRow/subtitle, four-language resources, product-language guide and existing source contracts. Keep the native Picker, selected value, preview, entitlement note, configuration ownership, media pipeline and Share background route unchanged. The optional placement of time expressions remains a Card Content concern; choosing tone must not insert or rewrite user content. No Renderer, layout geometry constant or persisted schema change.

Preserve the mixed worktree. Pre-edit tracked patch, status and exact touched-file copies are under /tmp/MemoMarkExpressionCopy20261012. Do not stage, commit, push or submit to Store. This is a bounded single UI slice, not background compatibility implementation.

Verification: review task-only diff; localization parity and existing ConfigurationOptionList contracts; governance; signed Release iOS build; cover-install and launch on the paired physical phone. Verify the visible copy and removed helper in portrait/landscape when device UI evidence is available. Build/install do not establish manual visual acceptance or Share media certification.

## Evidence

- Implemented the top helper via configuration.expression.tone_guidance and removed the lower optional-content helper. Picker binding, choices, preview, entitlement note and existing portrait/landscape layout remain unchanged. Four localizations and product-language guide updated; obsolete helper key removed consistently.
- Existing ConfigurationOptionList contracts initially failed because they required the superseded count-based subtitle. Updated those existing assertions; no new test suite or product behavior added.
- Focused macOS contracts/localization suite: 54 passed, 0 failed, 0 skipped, no runtime warnings. Result: /tmp/MemoMarkExpressionCopy20261012/FocusedGreen.xcresult. Existing compile warnings are not part of this copy change.
- Governance, strings plutil checks, task-only diff review and git diff --check passed. No processing, media, save, configuration schema or entitlement behavior changed by this slice.
- Formal Xcode 27.0 signed Release MemoMarkiOS build passed; strict deep codesign validation passed. Source fingerprints remained equal throughout the build. Version remains 2.3.6 (124).
- Paired physical iPhone 17 Pro Max / iOS 27.2 Beta: devicectl cover-install succeeded and normal application launch succeeded, without uninstall/reset or test-only launch arguments. Install/launch evidence is under /tmp/MemoMarkExpressionCopy20261012.
- No physical screenshot or manual portrait/landscape visual acceptance was obtained in this slice. Owner can inspect Configuration Center → Time Expression on the installed build; install/launch is not visual acceptance. Paused media/style certification remains untouched. No Git/Store mutation performed.

# V1 Design Freeze Polish

Date: 2026-07-29
Primary loop: Product Loop
Risk: P1
Status: Accepted for implementation

## Observed Scenario

The current iOS UI already has a stable MemoMark identity and a complete
Home -> Configuration -> Save -> Progress loop. The remaining review feedback
is about information hierarchy, state confidence, copy density, and the visual
priority of existing controls. It is not evidence for reopening IA-002, the
Memory Engine, the renderer, the export pipeline, or the Apple Photos lifecycle.

Simulator acceptance is explicitly out of scope for this pass. Final manual
coverage will use an in-place install on the user's physical iPhone 17 Pro Max
without uninstalling the app or clearing its data.

## Intended Outcome

- Home gives the product title, person, and selected preset a quieter and more
  deliberate hierarchy.
- Subject and anchor surfaces use one restrained information hierarchy and a
  clear primary save action.
- Configuration Center explains expression choices through a readable preview,
  keeps the real Memory Card as the preview source, and visually distinguishes
  dirty, saving, saved, and failure states.
- Save is organized around the final result first and destination second. It
  exposes the existing original-format/static-image choice and states media
  behavior without making unsupported metadata-retention promises.
- Progress remains a truthful view of waiting, processing, completed, and
  attention states, while completed states use less green and Apple Photos is
  presented as an information row.
- First-run setup asks only for a person and an important date, explains the
  prepared defaults, and uses narrative product language.

## Accepted Review Items

- Reduce the home mark slightly and give the product title more typographic
  priority.
- Increase subject-avatar presence and reduce saturated green in statistics.
- Quiet unselected preset accessories and reduce repeated timestamp weight.
- Use restrained section headings and secondary anchor-category color.
- Present memory-expression examples in a sheet instead of an alert.
- Reuse the existing four-region editor and real Memory Card preview; do not
  create a second abstract preview.
- Group the existing module library by its existing categories only.
- Make save actions state-aware: blue for an actionable change, restrained for
  an already-saved state, and explicit for failure.
- Put final output behavior before album destination, expose the existing media
  output mode, add a clear Apple Photos description preview, animate optional
  text, and de-emphasize album refresh.
- Use one green completion signal on Progress and present the Apple Photos link
  as a row.
- Simplify first-run labels to a person and an important date, while preserving
  the existing configuration model and prepared defaults.

## Explicitly Rejected Or Deferred

- No IA-002, Memory Engine, Presentation Engine, Layout Engine, renderer,
  metadata, export, Share Extension, or PhotoKit lifecycle redesign.
- No dynamic frequency ranking, speculative 80-variable library, weather, map,
  AI copy, output history policy, record deletion, record reopening, or export
  of history.
- No invented subject field in processing history when the persisted projection
  does not provide one.
- No rename of Progress to Recent: the current implementation has real waiting,
  processing, completed, and failure states.
- No copy claiming complete EXIF, HDR, depth, or Live Photo preservation beyond
  what the selected output mode and production pipeline can prove.
- No simulator screenshots or simulator acceptance evidence.

## Ownership And Files

- Home and subject presentation: `V1HomePageSurface.swift`,
  `V1IOSSubjectOverviewSupport.swift`, `V1IOSSubjectAnchorDetailSection.swift`,
  `V1LocalConfigurationLibrarySheet.swift`.
- Configuration presentation: `V1ConfigurationOptionList.swift`,
  `V1ModuleLibrarySurface.swift`, and the existing configuration footer owner.
- Save presentation: `V1OutputPageSurface.swift` and existing output presenters.
- Progress and first run: `V1TaskPageSurface.swift`,
  `V1WelcomePresentation.swift`.
- Focused architecture/source contracts under
  `Tests/PhotoMemoTests/ArchitectureTests`.

## Failure Modes

- Copy overpromises media preservation or conflicts with the actual export path.
- A saved configuration still appears actionable, or a dirty configuration loses
  its primary action.
- Dynamic Type truncates new rows or state summaries.
- A UI-only change mutates configuration data, media lifecycle, or persistence.
- A physical-device install replaces user data instead of updating the app.

## Verification Plan

1. Add focused source contracts before changing each UI slice.
2. Run the focused architecture tests after every slice.
3. Run localization plist lint and Simplified Chinese/English key parity.
4. Run relevant test groups, a macOS Debug build, and a generic iOS Debug build.
5. Run `git diff --check` and a final multi-axis code review.
6. Produce a signed device build, install it over the existing app on the user's
   physical iPhone 17 Pro Max, and launch it. Do not uninstall the app and do
   not clear device data.
7. Record automated and physical-device evidence in `Docs/CURRENT_STATUS.md`.

## Acceptance Boundary

This is the final consolidated polish pass for the reviewed V1 surfaces. After
closure, further layout changes require new observed usability evidence or a
production defect; preference-only visual iteration is outside this pass.

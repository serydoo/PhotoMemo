# Advanced Modules Sheet Spacing Follow-up

Date: 2026-07-30

## Decision Gate

- Primary loop: Product Loop
- Risk: P2, because this is a bounded iOS sheet layout refinement with no
  change to module values, persistence, preview, or final output.
- Observed scenario: the supplied iPhone 15 Pro and iPhone 17 Pro Max
  screenshots show both advanced modules compressed inside one zero-spacing
  `List` row. The location and time groups read as a dense control cluster even
  though the sheet has ample vertical room and is expected to contain only
  these two modules for the foreseeable product scope.
- Scope: `V1AdvancedModulesSheet`, its focused source contract, and the current
  status record. Memory Engine, time and location presentation models,
  renderer, export, persistence, and other Configuration Center surfaces are
  out of scope.
- Source of truth: the sheet owns presentation-only spacing. Existing bindings
  and presentation models continue to own selected values.
- Apple-native capability evaluated: keep the grouped `List`, native row
  separators, `Menu`, `NavigationStack`, and the accepted `390pt` / `large`
  detents. No custom card stack or picker is introduced.
- Verification: focused contract tests, unsigned generic iOS Debug build, and
  `git diff --check`. Physical-device visual acceptance remains separate.

## Accepted Pass

- Location and time become two native rows in one grouped section instead of
  being nested inside one zero-spacing row.
- Each module receives `12pt` vertical content padding.
- The title-to-description gap remains `4pt`.
- The gap between a module heading and a secondary control becomes `12pt`.
- The accepted sheet detents and all selection behavior remain unchanged.

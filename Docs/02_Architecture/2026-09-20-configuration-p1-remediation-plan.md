# Configuration P1 Remediation Plan — 2026-09-20

## Scope

This plan closes the Configuration Center P1 findings confirmed by the
local source audit and an independent read-only Chat on Steroids review. The
implementation remains behavior-preserving for Apple Photos, Memory Engine,
Presentation/Layout/Renderer ownership, durable configuration identity, and
the Share-to-Processing workflow.

## Ordered phases

1. **Durable state and destructive-action safety**
   - Separate durable persistence from compatibility-projection warnings.
   - Permit switching/deleting after a durable save with a warning.
   - Preserve the pending destination after a failed save and offer an
     explicit discard-and-switch path.
   - Keep Processing Default changes fail-closed until the processing
     projection is ready.
2. **Concurrent-save protection**
   - Carry an editor generation through an aggregate save request and refuse
     to reapply a stale receipt after newer edits to the same configuration.
   - Add regression coverage for same-ID stale receipts and preserved edits.
3. **macOS FilmMark persistence closure**
   - Make macOS restore, preview, edit, and save use the independent
     `FilmMarkContentSchemaV2` chain; do not revive legacy slot-A semantics.
4. **Preset identity and creation clarity**
   - Make each Home row derive its style from its own durable configuration.
   - Separate local backup management from preset switching.
   - Add a clearly named new-preset flow based on an independent Classic White
     baseline while retaining explicit duplicate-current behavior.
   - Protect new-preset creation with the same save/discard/cancel boundary as
     preset switching; discarding restores durable edits and removes only an
     in-memory-only draft.

## Verification gates

Each phase must pass focused Swift tests before the next phase. The complete
change then requires a no-signing Xcode build, a code-quality review, and a
signed physical iPhone 17 Pro Max install/launch check without clearing the
existing app container. A locked device or other external state remains a
manual-acceptance limitation, not a reason to weaken the code contract.

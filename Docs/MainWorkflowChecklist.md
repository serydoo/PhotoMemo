# PhotoMemo Main Workflow Checklist

Last updated: 2026-06-21

This checklist turns the workflow-consolidation direction into small, reviewable work items.

It is intentionally biased toward correctness and simplification, not feature expansion.

## Now

- [x] Adopt one internal workflow standard: `Import -> Metadata -> Memory -> Renderer -> Export -> Share`
- [x] Document stage ownership and non-goals
- [x] Reaffirm that renderer is the final output layer, not the business core
- [x] Reaffirm that Template or Style and Renderer remain separate concerns
- [ ] Finish consolidating import-origin facts across intake, metadata, export, and save-back
- [ ] Verify original filename preservation end to end on real device flows
- [ ] Make share failures clearly attributable to a concrete stage during diagnostics and QA
- [ ] Verify the shortest user path on device: `Photos -> Share -> PhotoMemo -> Generate -> Save`

## Next

- [ ] Align remaining source-origin fields behind a cleaner canonical lifecycle
- [ ] Strengthen workflow acceptance checks for import, render, export, and share handoff
- [ ] Reduce remaining Main App surfaces that still behave like a debug console instead of a configuration center
- [ ] Keep share confirmation copy quiet, specific, and non-technical

## Later

- [ ] Move more day-to-day execution toward share-first usage once stability is proven
- [ ] Add clearer product-facing success and failure feedback for save-back results
- [ ] Expand workflow verification without expanding feature surface

## Explicitly Deferred

- [ ] No architecture rewrite around a new workflow abstraction
- [ ] No broad renderer redesign in the name of workflow consolidation
- [ ] No codebase-wide rename campaign unless it materially improves user understanding or maintenance
- [ ] No share-only execution mandate until the current happy path is stable

## Verification Checklist

- [x] `PhotoMemo` builds
- [x] `PhotoMemoiOS` builds
- [x] `PhotoMemoShareExtension` builds
- [x] if code changed, `PhotoMemoTests` remains green
- [x] docs and code still describe the same product shape

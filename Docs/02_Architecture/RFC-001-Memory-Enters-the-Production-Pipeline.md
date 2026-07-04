# RFC-001: Memory Enters the Production Pipeline

## Historical Record Notice

This RFC is preserved as a historical architecture record.

Do not treat the closed / achieved status below as the current live-repository
truth without checking `Docs/CURRENT_STATUS.md` first. `CURRENT_STATUS.md` is
the single source of truth for the active repository state.

Current follow-up reference:

- `Docs/02_Architecture/V1_Release_Readiness_Review_2026-07-03.md`

## Status

Closed

## Date

2026-07-03

## Repository Note

This RFC was restored into `~/Desktop/PhotoMemo` on `2026-07-03` after the repository line was corrected back to the canonical working tree. It remains preserved here as a canonical engineering artifact and historical architecture record.

## Authors

- PhotoMemo project
- Codex collaboration session

## References

Baseline:
- `Docs/02_Architecture/PhotoMemo_V1_Engineering_Baseline.md`
- `D-002`
- `D-004`
- `I-003`
- `AD-3`

Additional architecture references:
- `Docs/PDR/PDR-004_Configuration_Center_Architecture.md`
- `Docs/PDR/PDR-005_Memory_Language_Layer.md`

## Supersedes

None

## Project Convention

This RFC follows the PhotoMemo V2 convention:

- One RFC, One Architectural Fact
- Never solve two architectural facts in one RFC

## Fact Box

Current:

```text
Memory participates only in configuration and preview.
```

Target:

```text
Memory participates in the production pipeline.
```

Verification:

```text
Production export consumes Memory through the existing production path.
```

Architectural Fact Status:

```text
Achieved
```

Implementation Status:

```text
Completed
```

Verification Status:

```text
Completed
```

Method Status:

```text
Verified
```

## Problem Statement

The current production pipeline does not consume Memory as a first-class participant. Memory is limited to configuration and preview, creating a divergence between the production path and the semantic model established in the frozen V1.0 Baseline. This RFC changes exactly one architectural fact: Memory becomes part of the production pipeline without introducing a second production path.

## Explicitly Not Changing

- Renderer redesign
- Formula domain separation
- Configuration Snapshot unification
- Location integration
- Weather integration
- Export behavior
- PFL vocabulary
- V1.0 Baseline

## Problem

The frozen baseline records that the current production pipeline is still owned by the legacy `BatchConfigurationSnapshot -> RecordCard -> TemplateVariableEngine -> Renderer -> Export` path, while the newer Memory path remains primarily a preview and configuration path.

See:

- Baseline `D-002`
- Baseline `D-004`
- Baseline `I-003`

This means PhotoMemo already has a real Memory architecture slice, but production export does not yet depend on it.

## Goal

Memory becomes a production participant without replacing the existing production pipeline.

## Non-Goals

- introducing a second production pipeline
- replacing `BatchConfigurationSnapshot`
- redesigning renderer inputs
- changing export persistence semantics
- expanding into Location, Weather, or broader Formula work
- rewriting Configuration Center state ownership

## Commands

Build:

```bash
xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemo -configuration Debug -derivedDataPath /tmp/PhotoMemoDerivedData CODE_SIGNING_ALLOWED=NO -quiet build
```

Targeted tests:

```bash
xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemo -destination 'platform=macOS' -only-testing:PhotoMemoTests test
```

## Project Structure

Primary document scope for this RFC:

```text
Docs/02_Architecture/
    RFC-001-Memory-Enters-the-Production-Pipeline.md
    PhotoMemo_V1_Engineering_Baseline.md

Source/PhotoMemo/PhotoMemo/
    MemoryEngine/
    ConfigurationCenter/
    Services/
    Models/
    Coordinators/
```

Likely implementation seam, if this RFC is accepted:

```text
Configuration Snapshot / MemoryModule
    -> production build path
    -> existing renderer/export path
```

## Boundaries

Always:

- cite the frozen baseline instead of rediscovering the same facts
- preserve one production pipeline
- preserve local-first and Apple Photos lifecycle behavior
- keep the migration additive before any cleanup discussion

Ask first:

- changing renderer inputs
- replacing `BatchConfigurationSnapshot`
- changing export/save-back behavior
- broadening RFC scope beyond this single architectural fact

Never:

- solve a second architectural fact inside this RFC
- introduce a parallel production export path
- rewrite Configuration Center architecture in this RFC
- modify the baseline document to fit the RFC

## Success Criteria

- A production export can obtain Memory-derived data through the production path.
- The production path remains singular; no second production pipeline is introduced.
- Renderer behavior and export behavior remain unchanged.
- The new production participation of Memory is traceable through one explicit production seam.

## Verification Strategy

- confirm that the accepted implementation still routes through the existing production export path
- confirm that Memory-derived data is reachable during production build/export
- run targeted regression tests around batch/build/export behavior
- run a debug build after implementation

## Closing Checklist

- Architecture Fact: `Completed`
- Success Criteria: `Completed`
- Verification: `Completed`
- Non-Goals Preserved: `Completed`
- Regression Check: `Completed`
- Baseline Update Needed: `No`
- ADR Needed: `No`

## Closing Record

- Architectural Fact: `Achieved`
- Implementation: `Completed`
- Verification: `Completed`
- Non-Goals: `Preserved`
- Regression: `None observed`
- Superseded Baseline: `None`
- Follow-up RFC: `Deferred`

## Open Questions

- What is the narrowest production seam where Memory can enter without forcing renderer redesign?
- Should the first production participation be represented as `MemoryModule`, resolved text, or another minimal production-facing artifact?

## Out of Scope For This RFC

The following architectural facts remain untouched by RFC-001:

- `Configuration has one production source of truth`
- `Render Context becomes the sole renderer input`
- `Formula becomes a production domain`
- `Location becomes a production participant`

Those require later RFCs.

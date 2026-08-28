# Codex Governance And Skill Routing Specification

Status: accepted for incremental implementation
Date: 2026-08-28
Primary loop: Engineering Loop
Risk: P1 (agent workflow, release authorization, and verification quality)

## Objective

Keep MemoMark's Codex workflow accurate and economical as the product enters
the V4 final refinement stage. The work reduces irrelevant default context,
aligns project Skill instructions with current ownership, and makes evidence
and external-mutation boundaries explicit.

This specification governs Codex guidance only. It does not authorize a
production architecture rewrite, a new product feature, external distribution,
or automatic installation of third-party Skills.

## Decisions

1. `PROJECT_CONSTITUTION.md` remains the highest-level project authority.
2. `Docs/CURRENT_BRIEF.md` is a compact routing index, not a second product
   specification or replacement for historical records.
3. `HANDOFF.md` and `Docs/CURRENT_STATUS.md` remain complete records and are
   read on demand according to task relevance.
4. Existing project Skill directories remain compatibility entry points while
   their instructions are corrected in place. Renaming is a later, separately
   verified migration decision.
5. Project UI/media acceptance defaults to the paired physical iPhone 17 Pro
   Max. Simulator evidence cannot substitute for that boundary.
6. Release readiness defaults to audit and recommendation. Commit, push,
   TestFlight, App Store Connect, and App Store operations require separate
   explicit authorization.
7. New external Skills are candidates until their source, dependencies,
   trigger behavior, overlap, and a representative task are verified.
8. Cross-cutting accessibility, localization, performance, and device checks
   use one on-demand `memomark-quality-gates` skill to avoid three overlapping
   always-available specialist prompts.

## Routing And Ownership

| Concern | Owner | Evidence required |
|---|---|---|
| Current session routing | `Docs/CURRENT_BRIEF.md` | link to authoritative source |
| Product stage and frozen architecture | Constitution and accepted V4 documents | scoped product/architecture evidence |
| UI behavior | UI Reviewer plus current UI contracts | focused tests and physical device when applicable |
| Media fidelity | Media Fidelity skill plus PhotoKit contracts | resource/read-back and device evidence |
| Rendering | Layout/Renderer/Export contracts | preview/export parity and output evidence |
| Release | Release Readiness skill and release manifest | exact build, tests, device, authorization |
| Cross-cutting quality | `memomark-quality-gates` (on demand) | gate-specific evidence and exact device/build |

## Incremental Verification

- Validate Markdown and Skill frontmatter after each Skill slice.
- Run `scripts/validate_codex_governance.py .` for stable routing invariants.
- Run the focused Python tests for the governance checker.
- Run the MemoMark build and relevant tests before claiming source readiness.
- For UI or media changes, install and inspect the exact signed build on the
  paired physical iPhone 17 Pro Max; record unverified paths explicitly.

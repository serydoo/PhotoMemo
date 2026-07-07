# Repository Simplification Report

Last updated: 2026-06-24

## Review ID

```text
RSR-001
```

## Goal

Delete or downgrade content that no longer fits the MemoMark V3 Product Philosophy:

```text
MemoMark exists to help people read their memories,
not just store their photos.
```

## Scope

This review was documentation-only.

No Swift, SwiftUI, renderer, engine, metadata, export, database, pipeline, Xcode project, or test code was changed.

## Mission Check

Question 1:

```text
Does it help users read memories?
```

Question 2:

```text
If it is deleted, does the mission still hold?
```

RSR-001 applies these questions to repository language. Concepts that only make MemoMark feel like a workbench, dashboard, import tool, photo manager, or bulk-processing console were removed from active source-of-truth wording or downgraded to historical/internal implementation context.

## Deleted Or Downgraded Concepts

Deleted from active source-of-truth language:

- MemoMark as a workbench
- MemoMark as a daily app-open workflow
- MemoMark as an import-first product
- MemoMark as a dashboard
- MemoMark as a task center
- MemoMark as a workspace
- MemoMark as a photo manager
- MemoMark as an EXIF tool
- MemoMark as a large-batch-first system

Downgraded to historical or internal implementation context:

- Workspace migration documents
- MainView workspace code names
- renderer/internal Template model
- SwiftUI `#Preview` and preview test names
- historical handoff and changelog entries that describe past work

## Renamed Terms

| Previous wording | Current wording |
| --- | --- |
| Main App | Configuration Center |
| Slot Editor | Slot Configuration |
| Template, when describing user configuration | Preset |
| Preview, when describing calibration | Configuration Preview |
| Import-first daily workflow | Apple Photos Lifecycle |
| Repository Refactor, for this phase | Repository Simplification Review |

Renderer-internal `Template` remains because current Swift models and renderer boundaries still use it as implementation terminology.

## Vocabulary Audit

Searched repository terms:

- Workspace
- Import
- Import Flow
- Workspace Workflow
- Workspace State
- Dashboard
- Working Area
- Task Center
- Main App
- Slot Editor
- Template
- Preview

Findings:

- Current source-of-truth docs now avoid `Main App` as a product concept.
- Current source-of-truth docs use `Configuration Preview` for user calibration language.
- Current source-of-truth docs use `Preset` for user configuration language.
- `Import` remains only in forbidden-term or stale-language contexts inside active governance docs.
- Historical documents still contain older language. They are preserved as history and should not be mass-rewritten until research specifications stabilize.
- Source code still contains `Workspace`, `Template`, and `Preview` identifiers. These are implementation names and should be migrated only through a separate code-safe refactor.

## Workflow Audit

Deleted from active product language:

```text
Open App
-> Import
-> Configure
-> Export
```

Current daily workflow:

```text
Apple Photos
-> Share
-> MemoMark
-> Processing
-> Notification
-> Apple Photos
```

Apple Photos Lifecycle:

```text
Reading
-> Share
-> Processing
-> Notification
-> Reading
```

Behavior State Machine:

```text
Idle
-> Preparing
-> Processing
-> Completed
-> Reading
```

Exceptional path:

```text
Interrupted
-> Auto Recovery
-> Continue
```

## Batch Audit

RSR-001 downgrades large-run framing.

Use:

```text
Primary: 1-20
Secondary: 20-50
Advanced: 50+
```

Avoid making 300, 500, 1000, or similar counts part of the product identity.

MemoMark is better suited to processing:

```text
a passage of memory worth returning to
```

## Configuration Audit

The Configuration Center owns only long-term configuration:

- Memory Profile
- Life Anchor
- Preset
- Output
- Album
- Automation
- Advanced

Deleted from current product model:

- Workspace as a user-facing workflow concept
- Working State as a user-facing workflow concept
- Temporary Session as a product identity concept

Configuration Snapshot rule:

```text
Task starts
-> Configuration freezes
-> Task reads configuration as read-only
-> Later edits affect the next task only
```

## Added Documents

Added:

- `Docs/REPOSITORY_VOCABULARY.md`
- `Docs/REPOSITORY_SIMPLIFICATION_REPORT.md`

## Updated Documents

Updated:

- `README.md`
- `AGENTS.md`
- `AI_CONTEXT.md`
- `PROJECT_CONSTITUTION.md`
- `Docs/MASTER_PLAN.md`
- `RepositoryAudit.md`
- `Docs/Interaction/IA-001_Interaction_Architecture.md`
- `Docs/Behavior/BEHAVIOR_SPECIFICATION.md`
- `Docs/Configuration/CONFIGURATION_MODEL.md`
- `Docs/DESIGN_DECISIONS.md`
- `Docs/FROZEN_REGISTRY.md`

## Preserved Designs

Preserved:

- local-first rule
- non-destructive output rule
- Apple Photos trust principle
- Memory Engine ownership of Life Position
- Layout Engine as future layout truth
- renderer as drawing implementation
- Configuration Snapshot principle
- Quiet Computing
- Zero Interaction
- Back To Photos
- Smart Batch Recommendation
- internal renderer/template implementation language where current code still requires it

## Remaining Recommended Changes

Do later as separate reviewed slices:

- Decide whether old Workspace docs should be archived, renamed, or left in a historical namespace after research specifications stabilize.
- Plan a code-safe terminology migration for `Workspace*` identifiers only if the benefit outweighs regression risk.
- Review user-facing Swift strings for `template`, `preview`, and `import` after runtime work resumes.
- Update older product docs such as `Docs/PRODUCT_SPEC.md`, `Docs/ProductModel.md`, `Docs/ProductDirection.md`, and `Docs/ShareZeroFrictionWorkflow.md` once the new repository vocabulary has stayed stable.
- Revisit batch and notification UI copy against the `Primary / Secondary / Advanced` scale during the next interaction review.

## Closing Principle

Every review should leave the repository simpler than before.

每一次设计评审，都应该让时光记比昨天更简单一点。

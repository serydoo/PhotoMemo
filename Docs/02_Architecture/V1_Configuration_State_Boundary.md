# V1 Configuration State Boundary

Configuration State Contract

Date: 2026-07-04
Status: accepted
Scope: MemoMark V1 Configuration Center / iOS V1 surface

## 1. Purpose

This contract defines the lifecycle, persistence boundary, recovery strategy,
and ownership of V1 configuration state.

Its purpose is to prevent three state classes from being mixed together:

- durable product configuration
- recoverable presentation/session selection
- temporary workspace or UI interaction state

Future code that adds, persists, restores, or resets configuration state must
first classify that state through this document.

## 2. State Taxonomy

| State Type | Definition | Persistent | Bootstrap Restored | Session Only |
| --- | --- | --- | --- | --- |
| Production State | Product configuration that must survive app restart and drive real output behavior. | Yes | Yes | No |
| Recoverable State | Presentation/session selection that should survive View reconstruction and may optionally survive app restart. | Optional | Yes, when explicitly approved | No |
| Workspace State | In-progress editing or temporary working context for the current interaction. | No | No | Yes |
| Transient UI State | Pure UI affordance state such as focus, expanded panels, and sheet visibility. | No | No | Yes |

### Contract Rules

- Production State is the only state class that is automatically considered
  persistent product data.
- Recoverable State must be explicitly named before it can be restored.
- Workspace State must not be promoted to persistence just to fix a View
  reconstruction bug.
- Transient UI State must never be restored through Bootstrap.

### Review Prerequisite

Any change in one of these areas must be reviewed against this contract before
implementation is accepted:

- adding a configuration item
- adding Session state
- modifying Bootstrap
- modifying `SettingsService`
- modifying `ConfigurationSession`
- modifying recovery behavior

The review must answer:

1. Which state class does this belong to?
2. Is the implementation consistent with this contract?
3. If not, should the contract be amended or is the implementation wrong?

## 3. State Ownership

| State | State Type | Owner | Writer | Reader | Lifetime |
| --- | --- | --- | --- | --- | --- |
| Memory Subject | Production State | Settings / Configuration Session | Subject editor, Bootstrap restore | V1 UI, Configuration Center, Memory pipeline | Persistent |
| Time Anchor selection inside Subject | Production State | Memory Subject | Subject editor | V1 UI, Memory Engine path | Persistent |
| Badge / Logo asset selection | Production State | Settings / Configuration Session | Badge/logo editor, Bootstrap restore | Preview, Renderer input preparation | Persistent |
| Output target | Production State | Settings / Configuration Session | Output settings, Bootstrap restore | Export/output preparation | Persistent |
| Target album identifier/title | Production State | Settings / Configuration Session | Album settings, Bootstrap restore | Export/save-back flow | Persistent |
| Applied template / preset choice for production output | Production State | Settings / production configuration path | Configuration flow | Preview/export path | Persistent when stored by current production path |
| Selected Memory Preset | Recoverable State | Configuration Session | Preset picker | Home surface, inspector, region composer | Recoverable |
| Selected preset ID | Recoverable State | Configuration Session | Preset picker, reset/default selection | Home surface, inspector, region composer | Recoverable |
| Region template IDs | Recoverable State | Configuration Session | Region/template editor | Interactive Memory Card, preview composition | Recoverable |
| Current Profile title draft after commit | Recoverable State | Configuration Session | Profile rename action | Home surface, picker summaries | Recoverable |
| Current subject selected in UI | Recoverable State | Configuration Session | Subject selection flow, Bootstrap bridge | Home surface, subject editor | Recoverable when not already covered by Production State |
| Editor draft text before commit | Workspace State | View / local draft store | Text fields, composer | Current editor only | Current interaction |
| Inspector selection | Workspace State | View / inspector coordinator | Card region taps | Object Inspector | Current interaction |
| Expanded panel / editing mode | Transient UI State | View | Local UI controls | Current view only | Current render tree |
| Keyboard focus | Transient UI State | View | Focus system | Current view only | Current render tree |
| Sheet visibility | Transient UI State | View | Local navigation/action state | Current view only | Current render tree |

### Current Implementation Gap

The P0 lifecycle review identified that several values now treated as session
only behave like Recoverable State from a product experience perspective:

- `MemoryPreset`
- `selectedMemoryPresetID`
- `regionTemplateIDs`

This document classifies those values as Recoverable State for future P2 work.
P1 intentionally did not change their recovery behavior.

## 4. Recovery Contract

| State Type | View Reconstruction | App Restart | Bootstrap Participation |
| --- | --- | --- | --- |
| Production State | Must restore | Must restore | Required |
| Recoverable State | Must restore after explicit contract adoption | May restore when product-approved | Explicit only |
| Workspace State | Must not restore | Must not restore | Prohibited |
| Transient UI State | Must not restore | Must not restore | Prohibited |

### P2 Principle

P2 Recoverable State Recovery must not attempt to restore the entire
`ConfigurationSession`.

The goal is:

```text
Restore only the state that the contract classifies as Recoverable.
```

The goal is not:

```text
Persist every session field until the UI appears stable.
```

Any P2 implementation must list each recovered field and map it to a row in
this contract.

### P2 Acceptance Criteria

P2 Recoverable State Recovery is accepted by behavior, not by a specific
implementation shape.

Required behavior:

- after View reconstruction caused by navigation or surface recreation, every
  approved Recoverable State value is restored
- after full app restart, only Production State and explicitly approved
  app-restart Recoverable State are restored
- Workspace State is not restored by the recovery mechanism
- Transient UI State is not restored by the recovery mechanism
- Production State remains authoritative from persisted data and is not
  overwritten by UI session lifecycle changes

If a candidate implementation passes these behavior checks without violating
the ownership table, it satisfies the contract.

## 5. Bootstrap Boundary

Bootstrap is responsible for restoring the minimum state needed to re-enter a
valid product configuration.

Bootstrap owns:

- loading persisted Production State
- applying recovered Production State into the live session
- preserving output-affecting configuration across app lifecycle boundaries
- providing an explicit bridge for approved Recoverable State when P2 adds it

Bootstrap does not own:

- focus state
- sheet state
- expanded/collapsed UI state
- temporary editor drafts
- unapproved session fields
- implicit reconstruction of the full `ConfigurationSession`

### Code Review Gate

A change to Bootstrap is acceptable only if it answers all three questions:

1. Which state row from this contract is being restored?
2. Is that state Production or approved Recoverable State?
3. What test proves it does not restore Workspace or Transient UI State?

If those answers are missing, the change is out of contract.

## 6. Future Evolution

Before adding any new configuration state, answer these questions:

1. Is this product configuration?
2. Should it survive View reconstruction?
3. Should it survive app restart?
4. Who owns writing it?
5. Who is allowed to read it?
6. Is Bootstrap responsible for it?

Then classify the state:

| Answer Pattern | Classification |
| --- | --- |
| It drives real output and must survive restart. | Production State |
| It is a user selection that should survive View reconstruction, but is not durable product output by itself. | Recoverable State |
| It is part of the current editing interaction. | Workspace State |
| It only controls UI display mechanics. | Transient UI State |

### Contract Amendment Rule

If a future feature needs a state behavior not covered here, update this
contract before changing production code.

Do not silently add persistence as a bug fix.

Do not silently add Bootstrap restore behavior as a UI workaround.

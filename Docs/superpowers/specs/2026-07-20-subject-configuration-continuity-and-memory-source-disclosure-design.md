# Subject Configuration Continuity And Memory Source Disclosure Design

Date: 2026-07-20

## Current Behavior

Two related production issues are visible in the Configuration Center:

1. Switching between Memory Subjects does not always make each subject's saved Time Anchor configuration effective immediately. Re-entering the Configuration Center and choosing `保存到当前配置` makes the expected anchor effective.
2. A second saved configuration can retain only custom text fields while losing generated Smart Module content or other configured region items. The restored result is therefore incomplete even though the user previously saved a complete region composition.

The `记忆来源` section is also always expanded. This gives infrequently changed source settings the same visual weight as the card content the user is actively defining.

## Intended Outcome

- Every Memory Subject owns its saved configurations and the active configuration context selected for that subject.
- Switching Memory Subjects immediately restores the selected subject's effective configuration, including its selected Time Anchor, output context, ordered region content, Smart Modules, literal text, and custom fields.
- Switching subjects never requires a second `保存到当前配置` action merely to make an already saved configuration effective.
- The first Configuration Center section, `记忆来源`, can be collapsed from a button on the right side of its title.
- A subject change always expands `记忆来源` so the user can inspect or adjust the new subject's source definition.
- After the user collapses the section, it remains collapsed while the selected subject ID remains unchanged, including navigation away from and back to the Configuration Center during the current app session.
- The collapsed section shows a compact effective-state summary: `记忆对象 · 时间锚点 · 记忆显示`.

## Product Boundaries

This work is limited to Configuration Center configuration ownership, restoration, draft continuity, and V1 iOS presentation state.

It must not change:

- Renderer behavior
- Layout Engine decisions
- Metadata extraction or retention
- Export or Apple Photos save-back behavior
- Share Extension intake behavior
- Memory Engine ownership of time calculations
- IA-002 Configuration Center architecture

The Configuration Center remains:

`Library -> Interactive Memory Card -> Object Inspector`

## Configuration Ownership Design

The selected Memory Subject is the first lookup boundary. Configuration restoration must not begin from a repository-global active configuration when that configuration belongs to another subject.

For the selected subject, resolution uses this order:

1. The configuration already selected for that same subject in the current session.
2. The subject's durable active or preferred saved configuration, when represented by the current model.
3. The subject's most recently saved owned configuration.
4. The subject's first owned configuration.
5. No configuration, with stale configuration state cleared.

The implementation should use the smallest durable-model change that makes this deterministic. If the existing global `activeConfigurationID` cannot represent per-subject continuity, the model must add an explicit subject-scoped active configuration reference rather than simulating a save during subject switching.

Subject switching is a restore/apply operation, not a save operation. It may persist the selected subject identity, but it must not rewrite configuration content or timestamps merely to activate an existing configuration.

## Complete Region Content Design

A saved configuration must retain and restore the complete ordered editor representation for every card region.

The preservation contract includes:

- item order
- Smart Module identity
- Smart Module expression configuration
- template-variable content
- literal text items
- user-customized text
- active text-item selection where it is part of the saved editor contract
- region template IDs and presentation settings already owned by the configuration

Restoration must rebuild editor drafts and preview drafts from the same saved configuration. It must not reconstruct a region from only `customText`, `usesCustomText`, or another partial compatibility projection.

The production snapshot remains immutable after processing begins. This change only ensures the correct complete configuration is selected before snapshot creation.

## Memory Source Disclosure Design

`记忆来源` gains a trailing disclosure button in the section header.

Expanded state:

- Shows `记忆对象`, `时间锚点`, and `记忆显示` rows.
- The button uses an upward disclosure indicator and an accessible `收起记忆来源` label.

Collapsed state:

- Hides the three editing rows.
- Shows one compact summary line containing the effective Memory Subject, Time Anchor, and memory display style.
- The button uses a downward disclosure indicator and an accessible `展开记忆来源` label.

State rules:

- Initial state is expanded unless the current session already contains a collapse choice for the same selected subject.
- Manual collapse persists while the selected subject ID is unchanged.
- Navigating away from and back to the Configuration Center does not reset the state during the current app session.
- Any selected subject ID change forces the section to expanded.
- Changing only the Time Anchor or memory display style does not force expansion.
- Collapsing or expanding is presentation-only and does not mark the configuration dirty or trigger persistence.

## Data Flow

```text
Select Memory Subject
-> resolve subject-owned effective configuration
-> restore subject and selected Time Anchor
-> restore complete editor configuration
-> rebuild editor and preview drafts
-> refresh effective summary
-> expand Memory Source section
```

Saving remains explicit:

```text
Edit configuration
-> Save To Current Configuration
-> persist complete configuration record
-> update subject-scoped effective configuration reference
-> future subject switches restore it without re-saving
```

## Error And Compatibility Handling

- If a saved configuration references an anchor no longer owned by its subject, fall back to the subject's active or primary Time Anchor and preserve the rest of the configuration.
- If a subject has no owned configurations, clear stale configuration and draft state from the previously selected subject.
- Existing schema payloads must remain readable.
- Legacy configurations that contain only partial editor data retain the current compatibility fallback, but newly saved configurations must not lose complete editor content.
- Corrupt configuration data follows existing repository diagnostics and recovery behavior; this slice must not silently overwrite it during a subject switch.

## Verification Plan

Automated regression coverage must include:

1. Two subjects with different saved configurations and different selected Time Anchors; repeated A -> B -> A switching restores the correct anchor without saving.
2. Two configurations whose regions combine Smart Modules, literal text, and custom text; save, reload, and switch restore the complete ordered content.
3. Subject switching rebuilds both editor drafts and preview drafts from the restored configuration.
4. Switching to a subject with no configurations clears stale state.
5. Manual collapse remains collapsed while the subject ID is unchanged.
6. Leaving and returning to the Configuration Center retains the collapse choice in the current session.
7. Changing the subject ID forces expansion.
8. Collapsing and expanding do not change configuration dirty/saved status.

Required verification before closure:

- focused architecture and V1 configuration tests
- focused presentation-state tests for disclosure behavior
- repository Debug build using the command specified in `AGENTS.md`
- iOS simulator build when the touched V1 surface requires it
- simulator or physical-device evidence for subject switching and disclosure interaction when available
- explicit note of any behavior not manually verified

## Acceptance Criteria

- Subject A and Subject B each immediately regain their own saved Time Anchor configuration when selected.
- No repeated `保存到当前配置` action is needed after switching subjects.
- The second configuration restores every saved Smart Module and custom item in the original order.
- Preview and later processing use the same restored configuration context.
- `记忆来源` can be collapsed from its title row.
- The collapsed summary accurately reflects the effective subject, anchor, and memory display style.
- The section remains collapsed until the selected subject changes.
- Switching subjects automatically expands the section.
- No Renderer, Metadata, Export, Share Extension, Photo Library, or Layout Engine behavior changes.

# V1 Output Configuration Boundary

Date: 2026-07-07
Status: accepted
Scope: MemoMark V1 iOS output configuration, current configuration, and Memory Subject switching

## 1. Purpose

This document defines what V1 means by output configuration, where each value
is owned, and when a visible choice becomes effective production behavior.

It exists to prevent the current configuration from showing or applying stale
output state after scenarios such as:

- browsing Memory Subjects without committing a switch
- switching to a Memory Subject that has no saved Preset
- editing output options without saving the current configuration
- restoring the app from persisted shared configuration

The governing rule is:

```text
Browsing changes display context only.
Saving the current configuration changes production behavior.
```

## 2. Output Configuration Inventory

V1 currently has two output-configuration layers.

### 2.1 Preset-Scoped Presentation Output

This layer belongs to `ConfigurationSession` and `MemoryPreset`.

| Value | Current Code Field | Owner | Meaning |
| --- | --- | --- | --- |
| Output result type | `selectedOutputOption` / `MemoryPreset.outputOption` | Configuration Session / Preset | The configured result is a processed image. |
| Storage option label | `selectedStorageOption` / `MemoryPreset.storageOption` | Configuration Session / Preset | Presentation-level storage wording shown inside Configuration Center. |
| Smart-module write toggle | `usesCustomMemoryWriteText` / `MemoryPreset.usesCustomMemoryWriteText` | Configuration Session / Preset | Whether output description text should use custom copy. |
| Smart-module write text | `customMemoryWriteText` / `MemoryPreset.customMemoryWriteText` | Configuration Session / Preset | Custom description text when the toggle is enabled. |

This layer is restored when the selected Preset changes or when the selected
Memory Subject aligns to one of its Presets.

This layer does not fully represent the actual iOS Photos album destination.

### 2.2 Production Output Destination

This layer belongs to the V1 iOS output page, save/apply coordinator, settings,
and production snapshot provider.

| Value | Current Code Field | Owner | Meaning |
| --- | --- | --- | --- |
| Output destination mode | `V1IOSOutputTarget` | V1 iOS output page | User-facing destination mode: automatic, system library, existing album, or new album. |
| Existing album picker selection | `selectedExistingAlbumIdentifier` | V1 iOS output page | Temporary picker selection before save. |
| New album name | `newAlbumName` | V1 iOS output page | Temporary album title before save. |
| Resolved album identifier | `selectedAlbumIdentifier` | Settings / shared configuration | Final destination identifier used by production processing. |
| Resolved album title | `selectedAlbumTitle` | Settings / shared configuration | Display/recovery title for the saved destination. |

This layer becomes production-effective only after `保存为当前配置` succeeds.

The production pipeline consumes the normalized `selectedAlbumIdentifier`
through `BatchConfigurationSnapshotProvider` and `BatchConfigurationSnapshot`.

## 3. Ownership Rules

| Category | Source Of Truth | Display Reader | Production Reader | Persistence |
| --- | --- | --- | --- | --- |
| Memory Subject | `ConfigurationSession.state.selectedSubject` and saved subject library | Home / Configuration Center | Saved shared configuration snapshot | Persistent after save |
| Preset selection | `ConfigurationSession.state.selectedMemoryPresetID` | Home / Configuration Center | Not directly production-effective by itself | Recoverable/session plus saved when applied |
| Region text/template content | current drafts and selected Preset snapshot | Preview / Configuration Center | Saved `Template` after apply | Persistent after save |
| Smart-module write settings | `ConfigurationSession` / selected `MemoryPreset` | Output page / home summary | Settings snapshot after apply | Persistent after save |
| Output destination mode | V1 iOS view state bootstrapped from saved album identifier | Output page / home summary | Resolved album identifier only | Persistent after save |
| Resolved album destination | shared settings | Bootstrap / summaries | Batch processing / share pipeline | Persistent |

Do not treat `MemoryPreset.storageOption` as equivalent to the actual
production album destination. In current code, it is a Preset-scoped
presentation option, while production uses the resolved album identifier saved
through the V1 apply flow.

## 4. Effective-State Lifecycle

### 4.1 App Bootstrap

1. `V1ConfigurationBootstrapCoordinator` loads saved configuration state.
2. `V1ConfigurationBootstrapPresenter` projects the saved album identifier
   into a visible `V1IOSOutputTarget`.
3. `V1BootstrapFlowCoordinator` restores output UI state, subject library,
   selected subject, location configuration, birthday/date context, and drafts.
4. The view displays the restored choices, but no new production state is
   created during bootstrap.

Bootstrap must restore only accepted Production State or explicitly accepted
Recoverable State. It must not reconstruct temporary editing state as if it
were saved configuration.

### 4.2 Editing Output

Changing any output-page field marks the current configuration dirty:

- `outputTarget`
- `selectedExistingAlbumIdentifier`
- `newAlbumName`
- smart-module write toggle/text

Dirty output edits are visible in the UI immediately, but they are not
production-effective until the user saves the current configuration.

### 4.3 Saving Current Configuration

When the user taps `保存为当前配置`:

1. `V1ConfigurationApplyRequestBuilder` collects the current subject, region
   text, location display config, badge/logo, smart-module write settings,
   time-anchor context, and output destination state.
2. `V1ConfigurationApplyCoordinator` resolves the album destination before
   saving the configuration aggregate.
3. `ConfigurationCoordinator.saveV1Configuration` persists:
   - selected template
   - badge/logo
   - location display configuration
   - selected Memory Subject
   - subject library and selected subject ID
   - smart-module write settings
   - selected time anchor
   - resolved album identifier and title
4. `BatchConfigurationSnapshotProvider` reloads the shared production snapshot
   from persisted settings.
5. `V1ConfigurationApplyRuntimeCoordinator` snapshots the active
   `MemoryPreset` and marks it applied only after the save succeeds.

If album resolution or configuration save fails, the selected Preset must not
be marked applied and production output must continue using the previous saved
configuration.

### 4.4 Production Processing

Production processing does not read transient output page state.

It reads the frozen/shared configuration snapshot, including:

- normalized selected album identifier
- saved template
- saved badge/logo
- saved location display configuration
- saved smart-module write settings
- frozen Memory Subject / Configuration Snapshot

This preserves the rule that the Share/queue path uses the last successfully
saved current configuration, not whatever the user was merely previewing.

## 5. Memory Subject Switching Rules

The Memory Subject surface now has two distinct modes:

| Interaction | Allowed Effect |
| --- | --- |
| Horizontal browsing | Shows another subject card only; does not change current subject or current configuration. |
| `切换` mode candidate selection | Selects a pending target; does not change production state yet. |
| `保存切换` | Commits selected subject through the existing subject-selection path. |

After a committed subject switch:

1. `ConfigurationSession.selectSubject` updates the selected subject.
2. The session aligns `selectedMemoryPresetID` to a Preset whose
   `selectedSubjectID` matches the selected subject.
3. If a matching Preset exists, the session restores Preset-scoped
   presentation context:
   - selected time anchor
   - output option
   - storage option
   - smart-module write toggle
   - smart-module write text
4. If no matching Preset exists, `selectedMemoryPresetID` and
   `appliedMemoryPresetID` are cleared.
5. The home current-configuration card must show the no-configuration empty
   state instead of falling back to another subject's Preset.

Subject switching alone must not persist a new production output destination.
The selected subject and its restored Preset context become production-effective
only after `保存为当前配置` succeeds.

## 6. Current Ambiguity To Preserve Explicitly

Current code intentionally has a split:

```text
MemoryPreset.storageOption
!=
V1IOSOutputTarget + resolved selectedAlbumIdentifier
```

That means:

- the selected Preset can restore presentation output context
- the V1 output page can restore the last saved production destination
- a Preset does not currently own a complete per-subject album destination

If the product decision becomes "each Memory Subject Preset owns its own album
destination", code must add an explicit Preset-owned destination model instead
of overloading `ConfigurationStorageOption`.

Minimum fields for that future model would need to represent:

- destination mode
- resolved album identifier
- resolved album title
- picker selection identifier when needed
- new-album title draft when needed

Until that model exists, production album destination is global/shared current
configuration state, while smart-module write settings are Preset-scoped and
persisted into production on save.

## 7. Review Gate For Future Changes

Any change touching output configuration must answer these questions before
implementation:

1. Is the changed value Preset-scoped presentation context or production output
   destination?
2. Does it become effective immediately, on subject switch, or only after
   `保存为当前配置`?
3. Where is it restored during bootstrap?
4. What prevents another subject's Preset from being displayed after switching
   to a subject with no configurations?
5. What test proves failed save does not mark the Preset applied?
6. What test proves production processing reads the saved snapshot instead of
   transient UI state?

Required test coverage for related changes:

- subject switch to a subject without configurations clears stale current
  configuration
- subject switch to a subject with a matching Preset restores Preset-scoped
  output context
- album selection is resolved before configuration save
- failed album/configuration save does not apply the selected Preset
- bootstrap projects saved album identifier into the correct visible
  `V1IOSOutputTarget`

## 8. Accepted Product Rule

For V1, the user-facing rule is:

```text
滑动只是查看记忆对象。
切换并保存后，才进入当前对象上下文。
点击“保存为当前配置”后，当前对象、Preset 内容、智能模块写入设置和输出目的地才成为后续处理使用的配置。
```

This keeps the Configuration Center as an object-centered setup surface while
protecting the Apple Photos -> Share -> MemoMark -> Processing ->
Notification -> Apple Photos lifecycle from transient UI state.

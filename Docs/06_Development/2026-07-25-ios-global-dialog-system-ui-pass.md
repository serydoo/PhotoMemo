# iOS Global Dialog System UI Pass

Date: 2026-07-25
Primary loop: Product Loop
Risk: P1

## Observed Scenario

MemoMark currently uses `Alert`, `confirmationDialog`, context menus, and
content sheets without one explicit semantic presentation rule. On the Memory
Subject editor, Time Anchor deletion is attached to a control inside an
already-presented sheet. The system may therefore render the confirmation as
an anchored floating popover. It obscures unrelated identity content, points
at an incidental screen location, and does not read as a page-level irreversible
decision.

The problem is not a single corner radius or offset. Equivalent destructive
actions currently use different presentation geometry depending on where the
modifier is attached, while lightweight completion feedback interrupts the
user with the same visual weight as a blocking decision.

## Intended Outcome

Define four dialog styles by interaction meaning. All four retain Apple-native
presentation, Dynamic Type, VoiceOver order, semantic button roles, localization
behavior, and platform adaptation. MemoMark does not introduce a custom global
modal renderer or imitate private screenshots.

## Style 1: Destructive Confirmation

Use a centered system `Alert` for one irreversible or materially destructive
action.

- Geometry: centered and detached from the triggering row or icon.
- Title: concise question naming the object.
- Message: one short consequence statement; no implementation terminology.
- Actions: `取消` first in reading priority and one red destructive verb.
- Scope: deleting a Time Anchor, Memory Subject, configuration, or local backup;
  replacing unsaved configuration with defaults.
- Never use an anchored `confirmationDialog` for these decisions.

Recommended Time Anchor copy:

- Title: `删除“途途生日”？`
- Message: `使用这个锚点的配置需要重新选择锚点。此操作无法撤销。`
- Actions: `取消`, `删除锚点`

## Style 2: Blocking Guidance

Use a centered system `Alert` when the current action cannot continue and the
user must understand or correct something.

- Geometry: centered system alert.
- Title: state the problem, not a generic status.
- Message: state the smallest corrective action.
- Actions: one acknowledgement, or one primary destination plus `稍后`.
- Scope: final Time Anchor cannot be deleted, object name is missing, initial
  configuration is incomplete, and commerce milestones that require a choice.

Examples:

- `至少保留一个时间锚点` / `新增另一个锚点后，才能删除当前锚点。`
- `填写对象名称` / `对象名称是保存记忆对象的必填信息。`

## Style 3: Action Choice

Use a bottom `confirmationDialog` only when the user is choosing among two or
more valid actions and no action is itself a second-step confirmation.

- Geometry: system bottom action sheet on compact iPhone layouts; system-
  adapted presentation elsewhere.
- Title: identify the selected object or task.
- Actions: short verbs ordered from common to exceptional; destructive choices
  may be red but must open Style 1 before execution.
- Scope: long-press Time Anchor actions such as `编辑` and `删除`, subject
  switching choices, and comparable multi-action menus.
- A single destructive action plus cancel is not an action-choice dialog.

## Style 4: Content Sheet

Use a sheet for interactions that contain editable values, selections, previews,
or more than a short explanatory sentence.

- Geometry: content-sized detent where stable; `.large` for full editing flows.
- Navigation: explicit title and completion control when data is edited.
- Dismissal: follows the owning draft transaction; destructive confirmation
  appears above it as Style 1 rather than as an anchored bubble.
- Scope: Time Anchor editor, Memory Subject editor, avatar cropper, local
  configuration library, expression guide, and background processing detail.

## Non-Dialog Feedback

Successful save, refresh, restore, or completed local operations do not require
a modal acknowledgement. Present them as a short-lived inline status or
accessibility announcement. Failure remains a blocking alert when user action
is required.

The existing generic `配置操作` alert should therefore be split by outcome:

- success: non-modal status feedback;
- failure requiring user action: Style 2 with a specific title and remedy.

## Existing Surface Mapping

| Existing interaction | Target style |
| --- | --- |
| Editor Time Anchor deletion | Style 1 |
| Detail Time Anchor deletion | Style 1 |
| Delete final Time Anchor warning | Style 2 |
| Delete Memory Subject | Style 1 |
| Missing Memory Subject name | Style 2 |
| Reset current configuration | Style 1 |
| Delete current configuration, both entry points | Style 1 |
| Delete local configuration backup | Style 1 |
| Initial configuration required | Style 2 |
| MemoMark+ milestone choice | Style 2 |
| Generic configuration operation feedback | Non-dialog feedback or Style 2 |
| Long-press object actions | Style 3, followed by Style 1 if destructive |

## Ownership And Boundaries

This pass changes only SwiftUI presentation and user-facing copy. Existing
delete, reset, persistence, validation, navigation, Memory Engine, configuration
aggregate, queue snapshot, Renderer, Layout, Metadata, Export, PhotoKit, and
original-photo behavior remain unchanged.

Apple-native capabilities evaluated: SwiftUI `Alert`, `confirmationDialog`,
`sheet`, semantic button roles, Dynamic Type, VoiceOver, Reduce Motion, and
platform size-class adaptation. A custom overlay system is rejected because it
would duplicate system focus, accessibility, keyboard, and adaptation behavior.

## Verification Plan

1. Add source contracts preventing destructive single-action flows from using
   `confirmationDialog`.
2. Convert all single destructive confirmations to centered alerts.
3. Keep multi-action menus and content sheets in their semantic categories.
4. Replace generic success acknowledgement with non-modal feedback without
   hiding actionable failures.
5. Run focused architecture tests, the iOS device build, `git diff --check`,
   and signed-device checks for every mapped interaction.
6. Manually verify compact width, Dynamic Type, VoiceOver labels, and that no
   confirmation points to or obscures an unrelated card.

## Acceptance Criteria

- Time Anchor deletion is centered and never has an attachment arrow.
- Every irreversible action names the affected object and states its consequence.
- Equivalent delete actions share geometry, button order, and destructive role.
- Multi-action selection remains a bottom system menu on iPhone.
- Editable content remains in sheets and is not compressed into alerts.
- Successful routine operations no longer demand an acknowledgement tap.
- No business behavior or persistence ownership changes.

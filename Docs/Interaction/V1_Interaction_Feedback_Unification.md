# V1 Interaction Feedback Unification

Last updated: 2026-07-07

## Status

```text
Implemented
```

Implemented in the 2026-07-07 V1 interaction feedback unification slice.

## Objective

This document defines a unified V1 interaction-feedback upgrade for PhotoMemo's
real daily workflow:

```text
Apple Photos
-> Share
-> PhotoMemo
-> Processing
-> Notification
-> Apple Photos
```

The goal is not to redesign the app architecture.

The goal is to make the full user-visible feedback chain feel like one calm,
coherent product system instead of several separate MVP-era surfaces.

This work should unify:

- Share / open-with handoff surfaces
- Live Activity on the Lock Screen
- Dynamic Island compact / minimal / expanded presentations
- system notifications
- in-app task page
- in-app background status page

Success means users can understand the same batch of photos across these
surfaces without mentally translating different status names, tones, or UI
hierarchies.

## Why This Exists

The current implementation already has real queue state, Live Activity payloads,
system notifications, retry handling, and share-extension handoff.

However, these layers still behave like separate surfaces:

- Share handoff pages feel like technical bridge screens instead of product
  entry moments.
- Live Activity communicates progress, but its hierarchy is closer to an MVP
  status panel than a product-grade glanceable surface.
- Notifications return useful results, but still read more like queue summaries
  than calm user-facing receipts.
- in-app task and status views preserve details, but do not yet fully act as
  the canonical detailed layer for every upstream surface.
- unsupported input, partial success, timeout-like interruptions, retryable
  failures, and non-retryable failures are not yet expressed through one
  coherent product language.

This document closes that gap.

## Product Position

PhotoMemo remains:

- local-first
- privacy-first
- Apple-native
- background-capable
- configuration-centered in the main app

This unification work must strengthen the existing product shape:

```text
Configuration in PhotoMemo
Execution from Apple Photos
Quiet processing in background
Clear result feedback
Return to Apple Photos
```

This work must not turn PhotoMemo into:

- a queue dashboard product
- a batch-console product
- a notification-heavy task manager
- a multi-step share wizard

## Frozen Alignment

This proposal must remain aligned with already frozen repository principles:

- `Behavior Specification`
  - behavior is a state machine, not a UI flow
- `Product Personality`
  - calm, quiet, respectful, invisible, trustworthy
- `Apple Native Guidelines`
  - extend Apple workflows instead of replacing them
- `Share Zero-Friction Workflow`
  - Share is an execution surface, not a setup surface
- `MVP Reliability Lock`
  - the real daily loop is Share -> Processing -> Notification -> Apple Photos

Therefore this work is:

- interaction polish
- behavior-language unification
- visual and copy system unification

It is not:

- a new interaction architecture
- a new feature surface
- a renderer/layout redesign

## Scope

### In Scope

- status naming unification
- cross-surface message hierarchy
- feedback tone unification
- supported / unsupported / attention-needed expression rules
- share handoff page restructuring
- Live Activity information hierarchy redesign
- Dynamic Island compactness rules
- notification receipt redesign
- in-app detailed status surface alignment
- retry / attention / unsupported-result clarity

### Out Of Scope

- Renderer output changes
- metadata engine changes
- export format changes
- photo library save behavior changes
- share-extension execution architecture rewrite
- new queue capabilities
- new configuration controls inside Share
- Layout Engine work

## Commands

These commands are the verification baseline for later implementation slices.

Build app:

```bash
xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemo -configuration Debug -derivedDataPath /tmp/PhotoMemoDerivedData CODE_SIGNING_ALLOWED=NO -quiet build
```

Build iOS app:

```bash
xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemoiOS -destination 'generic/platform=iOS Simulator' -configuration Debug -derivedDataPath /tmp/PhotoMemoIOSDerivedData CODE_SIGNING_ALLOWED=NO -quiet build
```

Build Share Extension:

```bash
xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemoShareExtension -destination 'generic/platform=iOS Simulator' -configuration Debug -derivedDataPath /tmp/PhotoMemoShareExtensionDerivedData CODE_SIGNING_ALLOWED=NO -quiet build
```

## Project Structure

The future implementation for this unification project is expected to touch
these areas:

- `Source/PhotoMemo/PhotoMemo/iOS/ShareExtension/`
  - handoff and share-surface UI
- `Source/PhotoMemo/PhotoMemo/iOS/Activity/`
  - Live Activity payload shaping and surface presentation
- `Source/PhotoMemo/PhotoMemo/Services/BatchNotificationService.swift`
  - notification title/body/result phrasing
- `Source/PhotoMemo/PhotoMemo/App/PhotoMemoBackgroundStatusService.swift`
  - canonical background snapshot and product-facing state derivation
- `Source/PhotoMemo/PhotoMemo/iOS/Views/V1TaskPageSurface.swift`
  - task-page presentation
- `Source/PhotoMemo/PhotoMemo/iOS/Views/V1SettingsPagePresenter.swift`
  - summary wording and status mapping
- `Source/PhotoMemo/PhotoMemo/iOS/Views/PhotoMemoiOSBackgroundStatusSheet*.swift`
  - detailed in-app background feedback
- `Tests/PhotoMemoTests/BatchTests/`
  - notification and queue-state copy contracts
- `Tests/PhotoMemoTests/ArchitectureTests/`
  - projection and state-derivation contracts

## Core Problem

The current feedback system lacks one canonical answer to this question:

```text
What exactly should the user believe is happening right now?
```

Today the codebase has:

- queue state
- task phase
- failure messages
- input-policy rejection messages
- share-extension error messages
- notification summaries
- Live Activity summaries

But these are not yet one product language.

The result is local clarity inside each surface, but incomplete continuity
across surfaces.

## Design Principles

### 1. One Batch, One Story

A single photo batch should feel like one continuous story across all surfaces.

Each surface may expose different detail density, but they must not change the
meaning of the state.

### 2. Share Is A Handoff, Not A Workspace

Share and open-with surfaces must confirm and reassure.

They must not become editing surfaces, deep configuration surfaces, or queue
management surfaces.

### 3. Live Activity Is Progress, Not Explanation

Live Activity should answer:

- what is happening now
- how far along it is
- whether attention is needed

It should not attempt to teach complex failure causes.

### 4. Notification Is A Receipt, Not A Log

Notifications should summarize the outcome of one batch in plain language.

They should not read like step-by-step task history.

### 5. In-App Status Is The Detailed Layer

When deeper explanation is needed, the in-app task/status layer becomes the
canonical place for:

- why something needs attention
- which items are affected
- whether retry is possible
- what kind of unsupported or interrupted state occurred

### 6. Quiet Computing

Users should only be interrupted when necessary.

The happy path should feel:

- automatic
- low-reading
- low-decision
- trustworthy

### 7. Failure Is Not One Thing

The system must stop collapsing all non-happy paths into generic failure.

At minimum, the product language must distinguish:

- unsupported
- interrupted
- partial success
- recoverable attention
- non-recoverable attention

## Unified State Model

The V1 interaction-feedback system should standardize on these seven user-facing
states:

1. `已接收`
2. `准备中`
3. `处理中`
4. `已完成`
5. `部分完成`
6. `需处理`
7. `暂不支持`

### State Meaning

#### `已接收`

Meaning:

- PhotoMemo has accepted the incoming share/open request.
- The batch is now inside the PhotoMemo workflow.

Used in:

- Share handoff success
- first queue-confirmation message

#### `准备中`

Meaning:

- PhotoMemo is verifying files, reading source availability, or preparing
  heavy media conditions such as RAW.

Used in:

- early progress surfaces
- share-to-processing transition

#### `处理中`

Meaning:

- the batch is actively moving through metadata, memory, render, or save stages

Used in:

- Live Activity
- in-app task summary

#### `已完成`

Meaning:

- all intended supported photos in this batch finished and were written back

Used in:

- final Live Activity linger state
- success notifications
- task page summary

#### `部分完成`

Meaning:

- some photos completed successfully, while some require user attention

Used in:

- final notification
- task page summary
- in-app detailed status

#### `需处理`

Meaning:

- the user should return to PhotoMemo to understand or resolve something
- retry may or may not be available

Used in:

- final Live Activity attention state
- attention-needed notifications
- in-app detailed status and retry actions

#### `暂不支持`

Meaning:

- a photo or input type is outside the current supported capability envelope
- this is a capability boundary, not an app breakdown

Used in:

- share/open input rejection
- unsupported-item summaries
- in-app detail for skipped or unsupported media

## Derived Internal Classification

The seven user-facing states are not enough to preserve implementation truth on
their own. The detailed system should internally classify at least:

- unsupported input
- interrupted or timed-out handoff
- retryable task failure
- non-retryable task failure
- partial success
- completed save-back

This internal classification exists so the UI can stay simple while still
producing accurate downstream messages.

The main product rule is:

```text
Simple user-facing state
with accurate internal reason
```

## Surface Responsibilities

### 1. Share / Open-With Handoff Surface

Primary role:

- confirm what PhotoMemo detected
- explain what will happen next
- reassure the user that they do not need to stay here

Must answer:

1. what was detected
2. what PhotoMemo will do
3. where the user can check progress if needed

Must not default to:

- advanced settings
- long educational copy
- deep queue language
- renderer terminology

Supported states:

- detected and ready to hand off
- already handed off
- unsupported / nothing processable
- handoff not confirmed / requires manual open

### 2. Live Activity Lock Screen

Primary role:

- glanceable progress

Must answer:

1. what is happening now
2. roughly how far along it is
3. whether attention is needed

Must not answer:

- detailed failure root cause
- full unsupported policy explanation
- all queue history

### 3. Dynamic Island

Primary role:

- minimal glance surface

Compact:

- one status glyph
- one value, usually progress or key completion summary

Expanded:

- current stage
- one queue/file summary
- small aggregate result if needed

### 4. Notification

Primary role:

- outcome receipt for one batch

Must answer:

1. what finished
2. what result category it belongs to
3. whether the user needs to return to PhotoMemo

Notifications must remain short enough to scan in a list.

### 5. In-App Task Page

Primary role:

- readable operational summary

Must answer:

1. what the current or latest batch is doing
2. what finished
3. what needs attention
4. whether retry is available

### 6. In-App Background Status Page

Primary role:

- full explanation layer

This page is the most detailed feedback destination and should be considered the
canonical detailed view for:

- current stage
- queue context
- current file
- failure phase
- failure reason
- retry availability

## Message Hierarchy Rules

Each surface must follow the same message hierarchy.

### Level 1: State

The primary state should be recognizable within one second.

Examples:

- `准备交给 PhotoMemo`
- `正在生成记忆卡片`
- `已完成`
- `有 1 张照片需处理`

### Level 2: Outcome Or Current Step

The secondary line explains what PhotoMemo is doing or what result happened.

Examples:

- `将按当前配置继续处理`
- `已保存到系统相册`
- `大部分结果已完成，剩余项目可回到 PhotoMemo 查看`

### Level 3: Detail

Detail belongs only where the surface has enough room and responsibility.

Examples:

- current file name
- unsupported reason
- phase-specific error message
- retry guidance

## Tone Rules

All future wording in this system should follow these tone rules.

### Calm

Do not use urgent language for normal background work.

### Trustworthy

Say what the system knows. Do not invent confidence where there is uncertainty.

### Respectful

Do not blame the user for unsupported or interrupted cases.

### Quiet

Keep happy-path reading cost low.

### Precise

Do not collapse different situations into one generic failure phrase.

## Content Rules By Result Type

### Success

Use direct completion language.

Preferred pattern:

- what completed
- where the result went

Avoid:

- celebratory language
- verbose process recap

### Partial Success

Use explicit mixed-result language.

Preferred pattern:

- successful count
- remaining attention count

Avoid:

- calling the whole batch failed

### Needs Attention

Use action-oriented language without panic.

Preferred pattern:

- say how many photos need attention
- say that PhotoMemo can explain more
- only promise retry when retry is truly possible

### Unsupported

Use boundary language, not crash language.

Preferred pattern:

- `当前版本暂不支持...`
- `这张照片暂不支持当前处理`

Avoid:

- `失败`
- `出错`

### Interrupted / Timeout-Like States

Use continuity language.

Preferred pattern:

- explain that the process did not finish within the allowed handoff or
  background condition
- direct the user back to PhotoMemo when needed

Avoid:

- generic failure without context

## Visual System Direction

### Overall

The interaction-feedback system should look like one family.

### Share Surface

Use:

- system-compatible light container
- strong but calm title hierarchy
- one clear action
- one concise summary card

Avoid:

- huge empty white areas
- explanation-heavy layouts
- technical or dashboard-like structures

### Progress Surfaces

Use:

- dark, quiet, glass-like surfaces
- warm gold/amber as processing emphasis
- soft green for completion
- restrained orange for attention-needed states

Avoid:

- alarm-red-first language
- table-like density
- all information competing for first visual priority

### Notification

Use:

- short receipt structure
- strong first line
- lighter second line
- thumbnail as proof, not decoration

## Surface-Specific Upgrade Direction

### Share Handoff Upgrade

Current issue:

- feels like a bridge screen instead of a product-grade handoff moment

Upgrade direction:

- clearer stage distinction between "detected", "ready to hand off", and
  "already handed off"
- better use of space
- show current expected path and reassurance
- reduce long explanatory reading

### Live Activity Upgrade

Current issue:

- too much information competes at once

Upgrade direction:

- emphasize one primary state
- keep queue summaries secondary
- keep compact Dynamic Island extremely minimal
- keep expanded view helpful but not verbose

### Notification Upgrade

Current issue:

- reads more like queue output than a receipt

Upgrade direction:

- make notification titles and bodies correspond to clear result categories
- keep per-batch summary concise
- strengthen distinction between success, partial success, and attention-needed

### Task And Status Surface Upgrade

Current issue:

- useful detail exists, but not yet established as the canonical detailed layer

Upgrade direction:

- make in-app task/status surfaces the clearest place to understand why
  something needs attention
- align titles and state labels with upstream Share/Live Activity/notification
  language

## Mapping Rules

The same batch must map consistently across surfaces.

Example:

```text
Share:
已交给 PhotoMemo

Live Activity:
处理中

Notification:
已完成 / 部分完成 / 需处理

Task Page:
same result category + more detail
```

No downstream surface should reinterpret a batch into a conflicting meaning.

## Implementation Constraints

This project must preserve these realities:

- Share Extension may remain a handoff surface rather than a full execution
  renderer
- Live Activity payloads must stay compact enough for ActivityKit updates
- Notification Center must not become a dashboard
- in-app detailed views remain the place for richer explanation
- background processing must continue to function when notification permission is
  missing

## Testing Strategy

This project needs three testing layers.

### 1. State-Derivation Tests

Protect:

- user-facing status mapping
- partial-success mapping
- unsupported vs attention-needed mapping
- retryable vs non-retryable wording boundaries

### 2. Surface Contract Tests

Protect:

- notification title/body formatting
- Live Activity payload state mapping
- in-app presenter status copy

### 3. Manual Workflow Verification

Verify on device:

- share 1 supported still photo
- share 1 RAW / DNG
- share 2-3 supported mixed still photos
- share unsupported Live Photo
- share unsupported extreme aspect ratio
- partial success case
- retryable attention case
- notification permission denied
- share handoff not auto-switching back to app

## Boundaries

### Always Do

- keep Share low-reading and low-decision
- keep state naming consistent across surfaces
- distinguish unsupported from failure
- distinguish partial success from total failure
- keep in-app surfaces as the detailed explanation layer
- preserve Apple Photos -> Share -> Processing -> Notification -> Apple Photos

### Ask First

- adding new user-facing states beyond the seven defined here
- adding new Share controls
- changing the default auto-processing posture
- changing the app's return-to-Photos behavior

### Never Do

- turn Share into a setup wizard
- turn notifications into a task log
- turn Live Activity into a detailed error report
- reintroduce dashboard/workspace/import-first product language
- change renderer/export/share behavior under the disguise of UI polish

## Implementation Order

This project should execute in this order:

1. canonical state matrix
2. share handoff redesign
3. Live Activity and Dynamic Island redesign
4. notification receipt redesign
5. task page and status page alignment
6. focused wording and contract tests

Reason:

- state language must become canonical before surface polish
- Share is the first user-visible moment
- progress feedback should then align to the new state system
- result receipts should then align to the same system
- in-app detailed layers should close the loop last

## Acceptance Criteria

This spec is considered satisfied only when all of the following are true:

- the same batch carries one consistent result meaning across Share, Live
  Activity, notifications, and in-app views
- users can clearly distinguish:
  - `处理中`
  - `已完成`
  - `部分完成`
  - `需处理`
  - `暂不支持`
- unsupported input no longer reads as generic failure
- partial success no longer reads as full failure
- Share handoff feels like a calm confirmation surface instead of a technical
  bridge page
- notification copy reads like a receipt instead of a queue log
- Live Activity becomes more glanceable without becoming vague
- in-app detailed surfaces become the canonical place for explanation and retry
- no new architecture or feature sprawl is introduced

## Risks

### Risk 1: Over-Designing The Share Surface

Mitigation:

- preserve zero-friction and one-action default behavior

### Risk 2: Inflating Live Activity Payload Complexity

Mitigation:

- keep the canonical user state simple and derive more detailed reasoning
  in-app

### Risk 3: Mixing Product Cleanup With Runtime Refactors

Mitigation:

- treat copy/state mapping and execution behavior as separate reviewable slices

### Risk 4: Turning The Task Surface Into A Dashboard

Mitigation:

- keep the task/status surface informational and recovery-oriented, not
  productivity-oriented

## Open Questions

These questions should be resolved before implementation planning:

1. Should `超时` remain an internal technical reason under `需处理`, or appear as
   a first-class user-facing sublabel in some surfaces?
2. Should Share handoff show the current Preset name directly when available, or
   remain more generic to reduce reading cost?
3. Should unsupported items in a mixed batch be summarized during Share handoff
   immediately, or only later in in-app detailed status?
4. Should final success notifications continue to prefer saved-album wording
   first, or switch to a stronger "result written back" style first?

## Success Criteria

The project succeeds when PhotoMemo's feedback surfaces feel like one product
system rather than five adjacent implementations.

The user should be able to share photos, leave calmly, understand progress at a
glance, receive a clear outcome, and know exactly when returning to PhotoMemo is
necessary.

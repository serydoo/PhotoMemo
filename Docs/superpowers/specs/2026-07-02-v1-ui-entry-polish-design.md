# MemoMark V1 UI Entry Polish Design
Date: 2026-07-02
Status: Proposed and user-approved in conversation
Scope: V1 iOS UI polish only

## Goal

Improve the first impression and everyday entry experience of `PhotoMemoiOSV1` without changing renderer rules, export behavior, share-extension behavior, or the existing Memory Engine ownership boundaries.

This slice focuses on:

- first-launch welcome experience
- home-page information hierarchy
- quick-action semantics
- subject-management usability
- V1 visual consistency
- app icon direction

## Product Intent

The V1 app should immediately communicate:

- what MemoMark is
- why it is different from a normal photo editor
- how users should begin using it
- which object/configuration is currently active

The UI should feel closer to an Apple-native configuration product:

- lighter
- calmer
- more structured
- less repetitive
- more explicit about current state

## Constraints

This slice must not:

- redesign renderer layout rules
- move output logic into new architecture
- change share-extension intake semantics
- alter photo-library writeback rules
- reopen IA-002 architecture

This slice may:

- add a first-launch / re-openable welcome surface
- reorganize V1 home-page content ordering
- change the meaning and destination of entry buttons
- improve subject-management interactions
- replace user-facing icon assets

## Visual Direction

Approved direction: hybrid between the provided mockup and Apple-native system apps.

Rules:

- white or near-white primary surfaces
- faint blue accent for active state and guidance
- restrained cards, thin separators, more breathing room
- no purple, no dark theme bias, no loud gradients
- typography closer to Apple utility apps than a marketing landing page

## Screen 1: Welcome Page

### Purpose

Give first-time users a clear explanation of what MemoMark is and how it fits into the Apple Photos workflow.

### Entry Rules

- auto-present on first launch
- can be reopened later from Settings

### Structure

Single-screen layout:

1. app icon
2. app title: `MemoMark`
3. subtitle: `记录人生，珍藏记忆`
4. one short explanatory paragraph
5. four feature rows
6. bottom primary action
7. bottom secondary action

### Copy Direction

The paragraph should compress the README message into user-facing language:

MemoMark uses photo metadata, time anchors, and memory objects to generate more meaningful memory presentation while preserving the original photo.

Feature rows:

- `本地优先`
- `保留原图`
- `时间锚点`
- `一次配置，长期受益`

Buttons:

- primary: `开始使用`
- secondary: `查看使用流程`

### Behavior

- `开始使用` dismisses the page and enters Home
- `查看使用流程` shows a lightweight explanation of the Apple Photos -> Share -> 时光记 lifecycle or a follow-up help surface

## Screen 2: Home Page Reorder

### Goal

Make the home screen read as:

1. who is active
2. which configuration is active
3. what can I do now
4. what happened recently

### Final Order

1. top status/header area
2. current memory subject card
3. current configuration card
4. quick actions
5. recent processing module
6. bottom tab bar

The old large home-page output module is removed from the main content area and consolidated into the bottom `输出` tab.

### Top Header

Should feel more intentional than a plain title row:

- centered `首页`
- right-side Settings access remains
- overall chrome should be quieter and better aligned with the cards below

Optional lightweight header status treatment is allowed as long as it stays restrained.

## Current Memory Subject Card

### Role

Highest-priority content card on Home.

### Contents

- circular avatar
- subject name
- relationship
- current active time-anchor pill
- disclosure affordance

### Rules

- keep the card concise
- do not overload it with management tools
- tapping enters the subject-management secondary page

## Current Configuration Card

### Role

Show the border/preset currently in force and one compact summary of the current active combination.

### Contents

- preset/border name, for now `Classic White`
- short descriptor, for example `经典白 · 公开边框`
- active combination/module summary
- active badge or small state marker if useful

### Rules

- this card explains the active visual/output setup
- it should not repeat full output settings

## Quick Actions

### Goal

Re-scope quick actions as true high-frequency actions instead of duplicating lower sections.

### Final Actions

- `处理照片`
- `配置中心`
- `时间锚点`
- `使用说明`

### Removed

`最近处理` must be removed from quick actions because a dedicated recent-processing module already exists below.

## Process Photos Action

### New Meaning

`处理照片` becomes a true action launcher, not a shortcut to output settings.

### Behavior

Tap `处理照片`:

- opens the system photo picker
- supports both single and multiple selection
- defaults to the single-photo experience
- multiple selection enters the current batch-processing flow

### Product Reasoning

This aligns in-app initiation with the Share flow:

- both paths feed photos into the same MemoMark processing pipeline
- the home screen gains a real action entry
- output settings stop competing with action semantics

## Recent Processing Module

### Role

Dedicated status/history feedback area.

### Contents

- latest processing result or state
- recent items list
- optional lightweight `查看全部` style affordance

### Rules

- should feel like activity/status, not a launcher grid
- green status or completion indicators are allowed but should stay system-like

## Output Consolidation

### Change

The home-page output card is removed.

### New Rule

All output-related settings live in the bottom `输出` tab:

- default output target
- save location strategy
- write-back to description
- album/export preferences

### Reason

This removes duplication between:

- home-page output card
- quick actions
- bottom output tab

## Subject Management Secondary Page

### Goal

Improve memory-subject management while keeping the current configuration flow intact.

### Top Navigation Rules

- left: `删除` only when subject count is greater than `1`
- center: page title
- right: `+`

Deletion must always require confirmation.

If there is only one subject:

- hide `删除`

### Single-Subject State

When there is exactly one subject:

- show one current subject preview card
- place a visible `+` near the card on the right side
- do not render horizontal carousel behavior

### Multi-Subject State

When subject count is two or more:

- upgrade the top area into a horizontal swipe carousel
- current subject is centered and emphasized
- neighbor cards remain partially visible
- tap a card to switch the active subject

### Card Content

Each subject card should stay concise:

- avatar
- display name
- relationship
- current active time anchor

### Lower Summary Area

Below the card/carousel, show concise rows for:

- `当前生效时间锚点`
- `主体身份`
- `时间锚点数量`

Also keep a clear action:

- `进入当前对象配置`

## Subject Add/Delete Flow

### Add

Tap `+`:

- create a new subject draft with safe defaults
- enter subject configuration flow

### Delete

Tap `删除`:

- show destructive confirmation
- explain that the current memory subject will be removed
- if confirmed, switch to a surviving subject and sync Home immediately

## App Icon Direction

### Intent

Turn the approved onboarding icon language into the formal app icon.

### Semantic Meaning

`从照片中读取记忆`

### Visual Rules

- white rounded-square base
- strong black primary symbol
- small blue accent detail
- symbol should blend photo framing / capture / memory-reading cues
- must remain crisp at small icon sizes
- no complex gradients
- no decorative imitation of camera-app icons

### Usage

The same icon language should appear in:

- iOS app icon assets
- welcome page hero area
- future marketing/release materials where appropriate

## Interaction Notes

- the welcome page must be reopenable from Settings
- Home should no longer contain two different places claiming to be output-entry surfaces
- Home should no longer duplicate recent processing in both quick actions and a large module
- subject-management controls should become more explicit without bloating the current subject card on Home

## Persistence and State

This slice will likely need lightweight persistence for:

- whether welcome page has been seen

It must reuse the existing app/session/configuration ownership model for:

- current active subject
- subject list
- current active time anchor
- current output settings

No new independent truth source should be introduced.

## Non-Goals

- no renderer redesign
- no new export architecture
- no change to photo metadata extraction rules
- no redesign of bottom tab information architecture beyond consolidating output semantics
- no reopening of the existing Memory Engine ownership boundaries

## Validation Plan

Implementation should be considered complete only after validating:

1. welcome page appears on first launch
2. welcome page can be reopened from Settings
3. `处理照片` launches system picker successfully
4. single and multi-selection both route into the expected processing path
5. Home no longer duplicates recent-processing and output entry semantics
6. subject add/delete behavior works in both one-subject and multi-subject states
7. app icon assets update cleanly for iPhone and iPad sizes

## Recommended Implementation Order

1. welcome page surface + persistence flag + reopen entry
2. home-page section reorder
3. quick-action semantic changes
4. output consolidation into bottom tab ownership
5. subject-management single/multi-state behavior
6. app icon asset production and replacement

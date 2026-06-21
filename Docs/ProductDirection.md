# PhotoMemo Product Direction

Last updated: 2026-06-20

## Design Mission

Configure once. Remember forever.

一次设定，永久记录。

## Core Definition

PhotoMemo is a memory generator built around Apple Photos, not a photo editor.

PhotoMemo 不是修图工具，而是围绕系统相册构建的记忆生成器。

## Product Philosophy

- PhotoMemo is not an EXIF viewer.
- PhotoMemo is not a photo editor.
- PhotoMemo is not an app users should need to open first.
- PhotoMemo is a local-first memory capability invoked from Apple Photos.
- The Main App exists to prepare the workflow.
- The Share Extension exists to execute the workflow.

## Core Experience Principle

The best PhotoMemo experience is the one users barely notice.

PhotoMemo 最好的体验，是用户几乎感觉不到它的存在。

The ideal feeling is:

see a photo -> share -> wait a moment -> find a new photo worth keeping in the library.

The main app exists mainly to configure PhotoMemo.

The share extension exists mainly to use PhotoMemo.

The long-term promise is:

- configure once
- share from Photos
- let PhotoMemo generate and save quietly
- return to life instead of returning to settings

## Internal Workflow Standard

PhotoMemo is now also defined by one internal product workflow:

Import

-> Metadata

-> Memory

-> Renderer

-> Export

-> Share

This is an engineering and product-alignment rule, not a user-facing concept.

It keeps responsibilities clear:

- Import brings photos in and preserves source facts
- Metadata exposes canonical photo facts
- Memory derives meaning
- Renderer produces pixels
- Export writes results
- Share executes the lightweight user flow

Renderer quality matters, but renderer is not the product center.

## Primary Product Entry

Old mindset:

Open PhotoMemo

-> Choose Photo

-> Configure

-> Generate

-> Export

New mindset:

Apple Photos

-> Select Photo

-> Share

-> PhotoMemo

-> Generate

-> Save back to Photos

-> Continue browsing Photos

## Product Model

PhotoMemo is now defined by three layers:

1. Personal Profile
2. Style
3. Workflow

### Personal Profile

Personal Profile owns information that rarely changes:

- relationship
- baby nickname
- birthday
- default album
- default style

### Style

Style owns how a PhotoMemo result is generated:

- layout
- variables
- visual arrangement
- bottom-card structure
- renderer-facing behavior

Styles must not store user identity.

### Workflow

Workflow is the execution path:

Apple Photos

-> Share

-> PhotoMemo

-> Generate

-> Save

Workflow should become more automatic over time, not more configurable.

## Product Responsibilities

### Main App

The Main App should mainly be a lightweight workflow-preparation center.

It should focus on:

- personal profile
- styles
- settings
- about

Choosing photos inside the Main App remains valid, but it is a secondary workflow.

### Share Extension

The Share Extension should become the primary user workflow.

The ideal default interaction is:

Share

-> PhotoMemo

-> Automatically use the current configuration

-> Generate

-> Save

Advanced settings may exist later, but they must remain optional and never interrupt the default path.

The workflow should complete with as few decisions as possible.

The Share Extension should never ask users to enter personal information.

## Design Direction

- simplify the main app instead of expanding it
- reduce vertical scrolling
- remove redundant cards
- avoid duplicate labels and repeated context
- keep preview tightly aligned with the real renderer/exporter
- favor defaults over setup whenever possible
- prefer `风格 / 时间点 / 输出` over `配置 / 工作区 / 技术术语`
- move instructional copy into Help instead of keeping it in the default flow
- hide identity setup inside First Run instead of scattering it through the app
- treat Personal Profile as setup, not as daily editing friction

## Product Polishing Phase

PhotoMemo has now entered a product-polishing stage.

From this point forward, iterative UX improvement should follow one sentence:

Let users stay inside Apple Photos as much as possible, share to PhotoMemo only when needed, and receive a result worth keeping within seconds.

This is the clearest product differentiator PhotoMemo has.

## Supporting Documents

- `Docs/UX_PRINCIPLES.md`
- `Docs/DesignSystem.md`
- `Docs/MainWorkflowConsolidation.md`
- `Docs/MainWorkflowChecklist.md`
- `Docs/ProductBacklog.md`
- `Docs/ProductScore.md`
- `Docs/ShareExtensionReview.md`
- `Docs/ShareZeroFrictionWorkflow.md`
- `Docs/ProductModel.md`

## Product Boundary

This direction update does not require:

- architecture redesign
- renderer redesign
- metadata redesign
- memory engine redesign

It is a product-model and product-flow alignment document.

The goal is to make PhotoMemo feel share-first, photo-first, decision-light, and increasingly invisible in normal use.

# PhotoMemo Product Direction

Last updated: 2026-06-20

## Core Definition

PhotoMemo is a memory generator built around Apple Photos, not a photo editor.

PhotoMemo 不是修图工具，而是围绕系统相册构建的记忆生成器。

## Product Philosophy

- PhotoMemo is not an EXIF viewer.
- PhotoMemo is not a photo editor.
- PhotoMemo is not an app users should need to open first.
- PhotoMemo is a local-first memory capability invoked from Apple Photos.

The main app exists mainly to configure PhotoMemo.

The share extension exists mainly to use PhotoMemo.

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

## Product Responsibilities

### Main App

The Main App should mainly be a lightweight configuration center.

It should focus on:

- configuration management
- memory settings
- anchor management
- template editing
- export preferences
- output defaults

Choosing photos inside the Main App remains valid, but it is a secondary workflow.

### Share Extension

The Share Extension should become the primary user workflow.

The ideal interaction is:

Share

-> Preview

-> Select configuration

-> Generate

-> Save

The workflow should complete with as few decisions as possible.

## Design Direction

- simplify the main app instead of expanding it
- reduce vertical scrolling
- remove redundant cards
- avoid duplicate labels and repeated context
- keep preview tightly aligned with the real renderer/exporter
- favor defaults over setup whenever possible

## Product Polishing Phase

PhotoMemo has now entered a product-polishing stage.

From this point forward, iterative UX improvement should follow one sentence:

Let users stay inside Apple Photos as much as possible, share to PhotoMemo only when needed, and receive a result worth keeping within seconds.

This is the clearest product differentiator PhotoMemo has.

## Supporting Documents

- `Docs/UX_PRINCIPLES.md`
- `Docs/DesignSystem.md`
- `Docs/ProductBacklog.md`
- `Docs/ShareExtensionReview.md`

## Product Boundary

This direction update does not require:

- architecture redesign
- renderer redesign
- metadata redesign
- memory engine redesign

It is a product-flow alignment document.

The goal is to make PhotoMemo feel share-first, photo-first, and decision-light.

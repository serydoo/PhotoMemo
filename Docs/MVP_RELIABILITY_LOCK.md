# MemoMark MVP Reliability Lock

Last updated: 2026-06-29

## Purpose

This document freezes the next MVP hardening target.

The bottom border output is treated as locked for this sprint:

- layout
- content mapping
- typography
- font sizes
- icons
- rendered visual form

The current focus is not renderer polishing. The current focus is making the
daily Apple Photos lifecycle reliable enough to feel like a system capability.

```text
Apple Photos
-> Share
-> MemoMark
-> Processing
-> Notification
-> Apple Photos
```

## MVP Reliability Principle

MemoMark must generate a new image without modifying the original photo.

The user should be able to share photos, leave MemoMark, and trust that the
system will either finish quietly or explain exactly what needs attention.

## Locked User-Facing Queue Semantics

One queue represents one Share action.

Queue names use the Share/start time and photo count:

- today: `18:42（3张）`
- yesterday: `昨天 18:42（3张）`
- earlier this year: `6月29日 18:42（3张）`
- previous years: `2025年12月31日 18:42（3张）`

Queue lines should stay short:

- running: `18:42（3张） · 1/3 · 约 2 分钟`
- failed: `18:42（3张） · 1 张需要处理`
- completed: `18:42（3张） · 已保存 3 张`

Do not reintroduce engineering titles such as external processing jobs,
renderer tasks, background task names, or import workflows into user-facing
status.

## Supported Input Contract

Supported MVP inputs:

- JPEG / JPG
- HEIC / HEIF
- PNG
- TIFF
- RAW / DNG

Explicitly unsupported:

- Live Photo packages
- GIF
- WebP
- video
- extremely wide, tall, panoramic, long-screenshot, or very thin images outside
  the current still-photo envelope

Current envelope:

- max single side: `8064 px`
- max total pixels: `8064 x 6048`
- max aspect ratio: `3:1`

## Processing State Contract

Single-photo work should expose a full pipeline:

1. Receive photo
2. Read information
3. Generate card
4. Save to library
5. Complete

RAW / DNG work may expose additional wording while preserving the same user
mental model:

- preparing RAW photo
- generating RAW display version
- reading information
- generating image
- saving to library

## Notification And Live Activity Contract

Single task:

- show current stage
- show one fine progress indicator
- show remaining time when useful

Two or three queues:

- show one line per Share queue
- each line starts with the queue name

Four or more queues:

- show an aggregate summary
- do not turn Notification Center into a task dashboard

Completed:

- use a short saved-photo result
- linger briefly, then let the system settle

Needs attention:

- say how many photos need attention
- link back into MemoMark status
- avoid generic failure language

## Manual Regression Matrix

Before pushing a reliability milestone to the phone, manually check:

| Scenario | Expected Result |
|---|---|
| Share 1 JPEG | Queue appears, output saves, status finishes |
| Share 1 HEIC | Queue appears, output saves, EXIF tokens resolve |
| Share 1 RAW / DNG | RAW progress is visible, output saves or explains failure |
| Share 2-3 mixed photos | One Share action appears as one queue line |
| Share 4+ batches | Notification / Live Activity uses aggregate mode |
| Unsupported Live Photo | User sees a calm unsupported-state message |
| Unsupported extreme aspect ratio | Item is skipped or explained without blocking valid photos |
| Photo library permission missing | User gets a settings path, not a silent failure |
| Notification permission missing | Processing still works; progress is available in-app |
| Target album missing | Automatic `photomemo` album fallback works |
| Partial success | Successful photos remain saved; failed count is explicit |
| Retryable failure | Retry is available only when source is still recoverable |
| Non-retryable failure | User is told attention is needed without a false retry promise |

## Automated Guardrails

Current automated tests should protect:

- input support and rejection policy
- queue title formatting
- queue creation time from payload request time
- managed intake copy behavior
- export file naming
- album selection normalization
- metadata read-back where fixtures allow it

Future hardening should add tests for:

- background snapshot display mode
- Live Activity payload shape
- final notification copy
- partial-success queue summaries

## Release Gate

A build is not considered MVP-reliability ready unless:

- focused tests pass
- `PhotoMemoiOSMVP` builds for the connected device
- the app installs to the test phone
- macOS `MemoMark` still builds
- manual Share regression notes are updated in `HANDOFF.md` or
  `Docs/CURRENT_STATUS.md`

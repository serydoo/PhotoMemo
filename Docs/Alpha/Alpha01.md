# MemoMark Alpha 0.7

Last updated: 2026-06-20

## Goal

每天都愿意用，而不是每天都在开发。

This phase is not about shipping more features.

It is about proving that MemoMark can survive real use inside Apple Photos.

## Validation Mode

Current development rhythm:

1. Find one real-world friction point
2. Confirm whether it is a product problem or implementation problem
3. Fix one small issue
4. Build
5. Verify on device
6. Commit

Preferred change size:

- `200-500` lines per fix when possible

## Primary Real-world Flows

### 1. Share Extension

Test repeatedly from:

Photos

-> Share

-> MemoMark

-> Generate

-> Save

Suggested coverage:

- baby photos
- landscape
- night photos
- HEIC
- JPEG
- Live Photo still behavior

### 2. Main App

Only validate the configuration-center responsibilities:

- configuration save
- configuration switch
- anchor editing
- memory settings
- template editing

### 3. Export

Run repeated exports:

- `20-50` photos in normal use

Check:

- filename behavior
- EXIF retention
- save success
- Photos album visibility

## Paused Work

These should not be active priorities during Alpha 0.7 unless a bug forces them:

- large UI rewrites
- new Memory features
- new Renderer work
- new Batch expansion
- new Metadata expansion

## Success Signal

If, after a week of normal use, MemoMark starts feeling habitual inside the Photos flow, the product has crossed an important line.

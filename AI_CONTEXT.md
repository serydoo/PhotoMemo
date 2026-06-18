# PhotoMemo AI Context

## Product Position

PhotoMemo is a local-first memory card generator.

It is not:

- a cloud photo service
- a generic gallery app
- a destructive photo editor

It is:

- a template calibration center
- a metadata and memory overlay tool
- a background photo-processing pipeline that writes finished images back to the system photo library

## Current Product Shape

- The foreground app is mainly for configuring templates, anchors, badges, album destination, and description-writing rules
- The main UI should keep one preview image as the calibration surface
- Real day-to-day usage should move toward external intake such as open-with, share, or similar background entry points
- The app should generate a new image and preserve original photo usability in the library as much as the platform allows

## Core User Flow

1. Configure template
2. Configure anchor
3. Import one preview photo
4. Generate real preview context from EXIF and anchor rules
5. Save configuration
6. Later send photos into PhotoMemo from outside the app
7. Process in background
8. Save finished images into the system library and target album

## Current Technical State

- SwiftUI macOS app
- Light-mode-first minimal system-style UI
- Template editor supports four custom regions
- Smart time-anchor tokens are wired into real EXIF-based calculations
- Background batch queue exists for external intake and photo-library output
- Batch notifications now exist for queued and completed background jobs

## Near-Term Priorities

1. keep the permission flow explicit and stable
2. harden external intake and background processing
3. ensure preview, render, export, and metadata retention stay aligned
4. simplify UI interactions without breaking future iOS migration

## Product Guardrails

- local-first by default
- no fake-data-first UI decisions
- no network dependency for core processing
- no irreversible mutation of the original image
- no feature expansion that outruns the real end-to-end pipeline

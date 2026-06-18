# PhotoMemo Product Specification

## Product Position

PhotoMemo is a local-first memory card generator.

Not:

- gallery replacement
- destructive photo editor
- cloud-dependent AI product

Is:

- EXIF visualizer
- anniversary and age context generator
- family memory finishing tool

---

## Core Workflow

1. Configure template
2. Configure anchor
3. Save local settings
4. Use one preview photo to calibrate result style
5. Later send photos into PhotoMemo from external entry points
6. Process in background
7. Save the finished image into the system library and target album

---

## Product Shape

### Foreground App

The main window is a calibration center.

It should:

- show one preview image
- expose template and anchor controls
- control output album and description-writing behavior
- display lightweight queue progress and project warmth

It should not become a heavy batch dashboard.

### Background Layer

The real day-to-day processing path should trend toward:

- open with PhotoMemo
- share to PhotoMemo
- future iOS-oriented external intake

---

## Template Philosophy

- never modify original image pixels directly
- generate a new image
- render information in the reserved bottom information area
- keep layout rules stable across horizontal and vertical photos

---

## Current Visual Direction

- classic white base
- fixed bottom information bar
- left / center / right balance
- replaceable icon or badge region
- minimal, system-like, light-first interface

---

## Anchor Philosophy

Support user-defined meaningful time points such as:

- birthday
- relationship start
- wedding
- school milestone
- exam countdown
- custom family event

The anchor engine should output reusable time fragments instead of hard-coded full sentences.

# PhotoMemo V2 Architecture

Last updated: 2026-06-22

## Definition

PhotoMemo is a local-first, privacy-first Memory Presentation Engine.

The architecture exists to preserve both objective photo facts and emotional memory position.

## Target Flow

```text
Photo
-> Metadata Engine
-> Memory Engine
-> Presentation Engine
-> Layout Engine
-> Renderer
-> Export
-> Application
```

## Engine Responsibilities

### Metadata Engine

Metadata Engine owns objective photo facts:

- EXIF
- capture time
- camera
- lens
- GPS

It answers:

- When?
- Where?
- How?

### Memory Engine

Memory Engine owns relationships between photos and Life Anchors.

It calculates Life Position:

- baby age
- relationship duration
- marriage duration
- pregnancy countdown
- memorial elapsed time
- travel anniversary
- custom event distance

Memory Engine does not write stories. It outputs reusable semantic values.

### Presentation Engine

Presentation Engine receives:

- metadata
- memory variables
- templates

It produces presentation content.

Presentation Engine decides how users express meaning. It is the expression layer, not the calculation layer.

### Layout Engine

Layout Engine receives already-generated content.

It decides:

- position
- spacing
- typography
- alignment
- adaptive layout
- optical compensation

Layout Engine does not calculate memory relationships.

### Renderer

Renderer receives resolved text and layout instructions.

Renderer does not know about:

- baby
- marriage
- relationship
- Life Anchor
- countdown
- memory timelines

Renderer simply draws.

### Export

Export creates the final generated image and preserves source metadata usefulness as much as the platform allows.

## Product Principle

Photos have timestamps.

Memories have positions.

EXIF records when a photo was taken.

Memory Engine calculates where that photo belongs inside a person's life.

Presentation Engine decides how users express that meaning.

Layout Engine decides how that meaning is presented.

Renderer simply draws.

# MemoMark Project Direction

Last updated: 2026-06-22

## Direction

MemoMark is evolving from a Photo Presentation Engine into a Memory Presentation Engine.

This does not reject the V2 repository reset. It sharpens it.

MemoMark still needs:

- research
- specification
- Memory Engine
- Presentation Engine
- Layout Engine
- Renderer
- Export
- Application

But the project center is now memory meaning, not photo decoration.

## Current Version Sequence

- V2.0 Repository Reset: complete
- V2.1 Memory Engine: current
- V2.2 Layout Specification: waits for reverse-engineering completion
- V2.3 Layout Engine: future
- V2.4 Renderer Rewrite: future
- V2.5 macOS Release: future
- V3.0 iOS: future

## Current Focus

Current work is V2.1 Memory Engine.

The goal is to define how MemoMark calculates Life Position from objective photo facts and emotional Life Anchors.

No renderer work should happen in this phase.

No UI work should happen in this phase.

No runtime implementation should happen until the architecture is documented.

## Product Boundary

MemoMark preserves both:

- objective metadata: when, where, and how a photo was captured
- emotional context: what that moment means in a life timeline

## Future Product Shape

Long term, MemoMark should become a lifelong memory system.

It should support many life timelines:

- relationship
- marriage
- pregnancy
- birth
- childhood
- school
- graduation
- family
- parents
- travel
- pets
- memorial
- custom life events

One photo may belong to multiple timelines at once.

Presentation style, layout, and renderer implementation are important, but they serve the memory system. They are not the core mission by themselves.

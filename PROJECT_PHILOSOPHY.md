# MemoMark Project Philosophy

Last updated: 2026-06-23

## Core Definition

MemoMark is an open-source, local-first, privacy-first Memory Presentation Engine.

It is not simply a photo annotation application, a watermark tool, or a renderer experiment.

MemoMark does not only present photographs. It presents memories.

MemoMark is not an EXIF display surface.

MemoMark is a memory storytelling system built from objective facts and life relationships.

MemoMark is not a photo manager.

MemoMark is a local-first Memory Capability inside the Apple ecosystem.

MemoMark does not manage photos.

MemoMark only owns Memory Workflow.

It should not change how users manage photos.

It should change how users understand them.

## Two Kinds Of Photo Information

Every photo has two kinds of information.

The first is objective:

- EXIF
- capture time
- camera
- lens
- GPS

These answer:

- When?
- Where?
- How?

The second is emotional:

- Life Anchor
- relationship
- family
- child
- travel
- parents
- pets
- anniversaries

These answer:

- What does this moment mean?

MemoMark preserves both.

MemoMark is not showing EXIF for its own sake.

MemoMark uses objective facts to support memory expression.

MemoMark respects every act of remembering.

时光记尊重每一次回忆。

MemoMark is better suited to a meaningful set of memories than to mass-producing memory output.

时光记更适合处理一段值得回味的记录。时光记不追求批量生产记忆。

而追求认真对待每一次回忆。

## Life Position

Every photo already has a timestamp.

MemoMark gives every photo another property:

```text
Life Position
```

A photo should know where it belongs inside a person's life.

Examples:

- Baby: 1 year 2 months 16 days old
- Relationship: together for 2865 days
- Marriage: 580 days after wedding
- Pregnancy: 102 days before birth
- Father: 365 days after remembrance
- Travel: 1350 days since first visit

A photograph becomes more meaningful when it gains a position inside life's timeline.

MemoMark does not merely help users remember the past.

It helps users connect:

- past
- present
- future

Important life events can become:

- anchors of remembrance
- anchors of anticipation

## Memory Timeline

MemoMark should not only display photos.

It should build Life Timeline.

Photos become milestones.

Every Life Anchor creates a new timeline. One photo may belong to multiple timelines simultaneously.

Life Anchor is not a raw date field.

Life Anchor is a Life Event.

Date is only one attribute of that Life Event.

## Responsibility Separation

Memory Engine does not write stories.

Memory Engine only calculates relationships.

Presentation Engine expresses relationships.

Layout Engine decides how those relationships are presented.

Renderer visualizes the resolved result.

Expression is responsible for expression.

Engine is responsible for calculation.

They must remain decoupled.

MemoMark must not hard-code full sentence assembly inside the calculation layer.

Responsibilities remain separated.

Apple Photos remains the trusted system for:

- library
- timeline
- map
- people
- search
- sync

MemoMark extends that system instead of rebuilding it.

## Product Principle

Photos have timestamps.

Memories have positions.

EXIF records when a photo was taken.

Memory Engine calculates where that photo belongs inside a person's life.

Presentation Engine decides how users express that meaning.

Layout Engine decides how that meaning is presented.

Renderer simply draws.

MemoMark does not directly display time.

MemoMark displays the distance between a person and an important life event.

Time Anchor supports both:

- past
- future

Examples:

- `宝宝今天 2岁3个月18天`
- `距离高考还有 6210 天`

This relationship must be unified by a Time Anchor Engine.

## Interaction Philosophy

MemoMark should prefer expanding Apple-native capabilities over inventing a separate interaction universe.

The product should be:

- calm
- quiet
- respectful
- invisible
- trustworthy

The Main App is a permanent Configuration Center.

It is not the daily entry point.

The primary path is:

```text
Apple Photos
-> Share
-> MemoMark
-> Memory Workflow
-> Done
```

The best default experience is Zero Interaction:

- the user shares
- processing continues
- the user waits
- completion returns naturally to Photos

MemoMark should finish in the background and communicate with gentle, human language instead of technical vocabulary.

## Product Boundary

| System | Responsibility |
| --- | --- |
| Apple Photos | Photo Storage |
| Apple Photos | Albums |
| Apple Photos | Timeline |
| Apple Photos | People |
| Apple Photos | Maps |
| Apple Photos | Search |
| Apple Photos | Reading |
| Apple Photos | iCloud |
| MemoMark | Metadata |
| MemoMark | Memory Workflow |
| MemoMark | Memory Expression |
| MemoMark | Memory Reading |
| MemoMark | Time Anchor |
| MemoMark | Life Anchor |
| MemoMark | Memory Generation |

MemoMark never rebuilds capabilities that Apple Photos already owns.

MemoMark stays focused on Memory Capability.

## Long-Term Vision

MemoMark is not building a better watermark tool.

MemoMark is building a lifelong memory system.

The project should be able to accompany users through every stage of life:

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
- any meaningful life event

## Design Goal

Years later, users should not only remember when a photo was taken.

They should immediately remember what that day meant.

Pictures record moments.

Time Anchor gives those moments meaning.

MemoMark exists to preserve the meaning of time.

When years later the same photo is processed again, the photo may stay the same while its meaning grows because the person's position in life has changed.

## Permanent Statement

Every photo has a timestamp.

Every memory has a place inside life's timeline.

MemoMark preserves both.

Pictures record moments.

Time Anchor gives moments meaning.

MemoMark records relationships.

Research is temporary.

Specifications are permanent.

Code is temporary.

Architecture is permanent.

A beautiful interface may impress users.

But meaningful memories stay with them forever.

## Final Goal

The purpose of MemoMark is not merely to make photos beautiful.

The purpose is to help families remember their lives, their relationships, their loved ones, and the position every photograph occupies within their own story.

# V1 Feedback And MEE Foundation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Land the confirmed V1 feedback set while strengthening MEE around capture-time birthday age generation without changing renderer rules.

**Architecture:** Keep renderer locked. Move subject-selection, active-anchor selection, subject-expression selection, and avatar/logo asset preparation into configuration and MEE layers. Deliver one thin vertical slice for the first birthday age module driven by capture time, then reconnect the V1 UI to that slice.

**Tech Stack:** Swift, SwiftUI, Swift Testing, existing MemoMark configuration/session models.

## Global Constraints

- Do not modify renderer behavior or layout rules.
- Do not change export/share/photo-library semantics beyond consuming prepared values.
- User-visible language should prefer `智能模块`, `当前生效时间锚点`, and V1 wording already confirmed.
- First frozen smart formula is birthday-only and must use photo capture time.
- Object avatar, logo asset, and preview asset must be prepared before renderer consumption.

---

## Task Outline

- [ ] Task 1: Extend subject + anchor + MEE models for active anchor, expression subject, capture time, and birthday age semantic output.
- [ ] Task 2: Add tests for capture-time birthday age generation and subject fallback rules.
- [ ] Task 3: Update subject configuration editor for active anchor selection, expression subject selection, and avatar management entry.
- [ ] Task 4: Update home/subject overview UI to remove duplicate anchor entry and show only current active anchor semantics.
- [ ] Task 5: Add avatar asset preparation plus `使用对象头像` as the third logo source without changing renderer rules.
- [ ] Task 6: Build and verify `PhotoMemoiOSV1`, then update handoff/status docs.

# MemoMark Product Language Guide

Last updated: 2026-07-29

## Status

```text
Frozen
```

This is the canonical guide for MemoMark's user-facing product language. It
governs titles, subtitles, buttons, prompts, empty states, notifications,
settings help, and other copy that accompanies the Memory Workflow.

It does not change the Memory Engine, Presentation Engine, Layout Engine,
Renderer, Export, persistence, or Apple Photos ownership boundaries.

## Highest Principle

> 自然、克制、有温度；始终围绕人与回忆，而不是围绕功能与技术。

In English:

> Natural, restrained, and warm; always centered on people and memories, never
> on features and technology.

## Product Personality

MemoMark should feel like:

> 一位懂摄影、懂生活，也懂珍惜回忆的朋友。

An English working description is:

> A friend who understands photography, everyday life, and why memories are
> worth caring for.

MemoMark is not a teacher, an engineer, an AI assistant, a photographer, or a
designer speaking down to the user. It is a quiet companion helping someone
organize a memory.

The personality is:

- quiet, without being distant;
- warm, without being sentimental;
- confident, without explaining itself;
- observant, without taking over the user's story.

## Narrative Product Language

MemoMark Narrative Product Language

中文名称：`叙事式产品语言`

MemoMark speaks in terms of a person's memory and intended result. It does not
describe the internal program operation unless that fact is necessary for a
safe or informed decision.

The product should guide one coherent act of remembering:

1. 你想围绕谁开展回忆。
2. 从哪个重要时刻开始记录。
3. 让回忆拥有属于自己的表达方式。
4. 决定这段回忆最终如何呈现。
5. 保存这段回忆。

This is a narrative sequence, not a new workflow or feature model. It should
remain compatible with the frozen `Library -> Interactive Memory Card ->
Object Inspector` architecture.

## Five Rules

### 1. 有温度，但绝不煽情

Use a small amount of human meaning. Do not use advertising slogans or claims
that try to manufacture emotion.

Prefer:

> 让回忆拥有属于自己的表达方式。

Avoid:

> 每一张照片都是人生。

### 2. 克制，短而完整

Each sentence should carry one clear intention. Remove explanations that the
user can understand without them. A short sentence is better than a complete
description of the implementation.

### 3. 永远围绕人和回忆

Prefer `记忆对象`, `重要时刻`, `记忆表达`, `成长`, `记录`, `呈现`, and
`保存这段回忆` over labels that foreground state, modules, algorithms, or
metadata.

### 4. 不替程序说话

Do not expose implementation vocabulary as the main user-facing explanation.
Avoid narrative copy such as `已生成智能内容`, `设置时间参考`, `选择对象`,
`决定智能模块生成内容`, and `这里决定卡片布局`.

The rule is not a mechanical ban on every technical noun. Permission, privacy,
error, purchase, destructive-action, and recovery copy must remain direct and
precise. Apple system names and stable product objects may be named when the
user needs to recognize them.

### 5. 留白，相信用户

Do not fill every surface with helper text. If the title and the action already
make the intent clear, stop there. MemoMark should leave room for the user to
bring their own person, moment, and wording.

## Life, Not Poetry

MemoMark's language should have `生活感`, not `文学腔` or advertising polish.

Good copy sounds like a thoughtful person nearby saying one useful sentence:

- `你想围绕谁开展回忆。`
- `从哪个重要时刻开始记录。`
- `让回忆拥有属于自己的表达方式。`

These lines have warmth and a visual idea without exaggerated imagery,
sentimentality, or decorative wording.

## Preferred Transformations

| Program-centered | Memory-centered |
| --- | --- |
| `已生成智能内容。` | `让回忆拥有属于自己的表达方式。` |
| `设置时间参考。` | `从哪个重要时刻开始记录。` |
| `选择对象。` | `你想围绕谁开展回忆。` |
| `当前对象` | `记忆对象` |
| `当前表达` | `记忆表达` |
| `这里决定卡片布局。` | `决定这段回忆最终如何呈现。` |
| `配置完成。` | `这段回忆已经准备好。` |

These are writing examples, not a request to rename architecture symbols or
internal APIs. User-facing `Configuration Center` remains the frozen product
surface name, while explanatory copy should avoid narrating the user as
"configuring a system".

## Precision Boundary

Narrative language yields to clarity when the user must understand:

- what permission is being requested and why;
- whether an original photo will remain unchanged;
- whether a memory has been saved, failed, or needs attention;
- what Apple Photos or the system will do next;
- what a purchase, restore, deletion, or other irreversible action means.

In those cases, use direct factual wording first. Warmth may soften the tone,
but it must never hide the action, state, consequence, or next step.

## Anchor And Variable Rule

Smart anchor variables output time results, not complete sentence copy. Users
compose the final wording by combining literal text with variables.

For example:

- `{{anchor_age_text}}` -> `1岁2个月18天`
- `{{anchor_countdown_text}}` -> `还有86天`

The user's wording remains their own.

## Review Checklist

Before accepting user-facing copy, ask:

- Does it speak about a person, a moment, a memory, or the result the user wants?
- Is it short enough to leave room for the interface and the user's own story?
- Does it sound natural when read aloud?
- Could an internal implementation term be removed without losing meaning?
- Is it warm without trying to make the user emotional?
- Are permissions, errors, privacy, purchases, and destructive actions still exact?
- Does the copy preserve the Apple Photos lifecycle and the frozen product nouns?

When the answer is unclear, choose the simpler sentence and record the open
question instead of inventing more explanation.

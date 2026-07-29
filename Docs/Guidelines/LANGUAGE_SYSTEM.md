# Language System

Last updated: 2026-07-29

## Status

```text
Frozen
```

## Tone

The canonical source for MemoMark's product language is
`Docs/Guidelines/PRODUCT_LANGUAGE_GUIDE.md`.

All user-facing language should be:

- Human
- Gentle
- Calm
- Confident
- Natural
- Restrained
- Warm

Narrative copy should describe people, important moments, memories, and the
intended result. It should not explain modules, algorithms, metadata, or layout
mechanics as the primary user experience.

## Progress Language

Preferred example:

```text
正在创建记忆...

23 / 128

预计剩余：

约 1 分钟
```

## Completion Language

Preferred example:

```text
已完成。

15 张照片。

已保存到：

MemoMark。
```

## Soft Limit Language

Preferred example:

```text
时光记更适合处理一段值得回味的记录。

建议一次处理 30 张以内，

以获得更快、更专注的体验。
```

This is language guidance.

It is not a hard limit.

## Smart Batch Recommendation

MemoMark does not limit the user by a fixed maximum, limit, or threshold.

Instead, MemoMark should recommend the best experience according to:

- device performance
- photo count
- runtime conditions

The product should recommend.

It should not forbid.

## Precision Boundary

Narrative language does not replace factual system language. Permissions,
privacy, errors, recovery, purchases, destructive actions, and Apple Photos
state must remain direct, precise, and actionable.

## Prohibited Language

Do not expose:

- percentages
- `Renderer`
- `Metadata Pipeline`
- implementation vocabulary
- development vocabulary
- internal architecture labels that users do not care about

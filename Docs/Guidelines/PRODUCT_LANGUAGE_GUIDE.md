# MemoMark Product Language Guide

Last updated: 2026-08-23

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
2. 选择一个时间起点，让照片拥有时间答案。
3. 让回忆拥有属于自己的表达方式。
4. 决定这段回忆最终如何呈现。
5. 保存这段回忆。

This is a narrative sequence, not a new workflow or feature model. It should
remain compatible with the frozen `Library -> Interactive Memory Card ->
Object Inspector` architecture.

## Title And Subtitle Roles

A title names the stable object, destination, or action that the user can
recognize. A subtitle explains either the decision made in that area or its
visible effect. It should not restate the title or inventory every child row.

Use stable titles such as `配置中心`, `记忆来源`, `记忆对象`, `时间锚点`,
`记忆表达`, `预设`, `卡片内容`, and `Apple Photos`. Keep the explanation in
the subtitle:

| Title | Subtitle role |
| --- | --- |
| `时间锚点` editor | `选择一个时间起点，让照片拥有时间答案。` |
| `这一刻怎样表达` | `表达方式：自然（默认） · 随时间变化` |
| `表达方式` | `围绕时间锚点，可选择 5 种表达方式。` The number comes from the current available styles. |
| `卡片样式` | `选择照片卡片的整体视觉风格。` |
| `我的预设` | `下一次分享，照片会怎样呈现。` |

When the title and controls already make the result clear, omit the subtitle.
Do not add helper copy only to make a section look complete.

### Configuration Center Expression And Style Terms

The Configuration Center keeps two adjacent decisions deliberately separate:

- `这一刻怎样表达` is the user-facing entry for the time-aware Memory
  Expression result. It explains how the photo speaks about the moment before,
  on, or after the selected Time Anchor.
- `表达方式` is the selectable expression choice inside that section. It
  changes the wording pattern and time relationship; it does not generate a
  complete sentence on the user's behalf. Smart anchor variables still return
  time results, and the user composes the final sentence from literal text and
  variables.
- `卡片样式` is the visual expression system for the whole photo card. It may
  control composition, information density, typography hierarchy, color
  treatment, content placement, and the relationship between the photo and the
  presentation surface. It must not be described as only a `边框样式`.
- `卡片布局与内容` explains the content combination layer: the user's words,
  photo information, and Memory Expression. It does not own the visual style
  decision.

The internal model names remain implementation details:
`MemoryAnchorExpressionStyle` and `RecordCardPresentationStyle`. User-facing
copy should use `表达方式` and `卡片样式` so first-time users can identify what
they are choosing without knowing the renderer or layout architecture.

### Memory Subject Identity Terms

Use one stable four-field vocabulary wherever a Memory Subject is viewed or
edited: `对象名称` is required; `昵称`, `与我的关系`, and `专属称呼` are optional.
Optional values stay absent from the reading surface until the user fills them
in. `照片中的称呼` names the separate choice that decides which populated
identity value appears in memory expressions; it is not another identity field.
If a selected optional value becomes unavailable, expression text and its
visible source label both return directly to the required `对象名称`. Do not
continue through other optional identity fields as fallback candidates.

### Time Anchor Type Labels

Use complete type names in selection and explanatory contexts: `生日 / 出生`,
`恋爱纪念`, `结婚纪念`, `未来目标 / 高考 / 毕业`, and `自定义`. In compact Time
Anchor list rows, use the localized short labels `生日/出生`, `恋爱`, `结婚`,
`目标`, and `自定义`. The short label inherits the established semantic color
for its type and does not repeat an icon, capsule, or visible `类型：` prefix.
VoiceOver announces `类型，<完整类别>` instead of the shortened visual label.

### Compact Control Rows

In a width-constrained control row, a subtitle may be a short relational phrase
when the adjacent title and control make its meaning clear. This exception
protects the control's stable trailing position and does not authorize
implementation vocabulary or an incomplete page-level explanation.

The accepted Time Anchor row uses `回忆对象重要时刻`; its editor provides the
complete prompt `选择一个时间起点，让照片拥有时间答案。`. Sentence-ending
punctuation is optional for the compact phrase and remains expected for the
full prompt.

Configuration sheets may use one centered, secondary `footnote` subtitle below
the native navigation title when the sheet needs context. The current accepted
sheet context is:

- `时间锚点`: `选择一个时间起点，让照片拥有时间答案。`
- `时间与地点`: `决定照片中的时间和地点怎样呈现。`
- `卡片内容`: use `组合自己的文字、照片信息与记忆表达。` below the title.
  The bottom explanation remains split by responsibility:
  `四个区域都可以自由组合文字、照片信息和记忆表达，修改会实时出现在卡片上。`
  `右下内容也会写入 Apple Photos 的照片说明，方便之后查找这张照片。`
  `点“完成”返回配置中心；收起键盘不会离开编辑页。`
- `右下`: place `内容也会写入 Apple Photos 的照片说明，方便之后查找。`
  on its own secondary line below the region title. Do not compress this product
  benefit into a trailing caption.

These lines are quiet context, not banners, roadmap promises, or a substitute
for a feedback action.

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

Prefer `记忆对象`, `重要时刻`, `记忆表达`, `成长`, `呈现`, and
`保存这段回忆` over labels that foreground state, modules, algorithms, or
metadata. Use `记录` only where its context actually describes a record or the
act of preserving one.

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
- `选择一个时间起点，让照片拥有时间答案。`
- `让回忆拥有属于自己的表达方式。`

These lines have warmth and a visual idea without exaggerated imagery,
sentimentality, or decorative wording.

## Preferred Transformations

| Program-centered | Memory-centered |
| --- | --- |
| `已生成智能内容。` | `让回忆拥有属于自己的表达方式。` |
| `设置时间参考。` | `选择一个时间起点，让照片拥有时间答案。` |
| `选择对象。` | `你想围绕谁开展回忆。` |
| `当前对象` | `记忆对象` |
| `当前表达` | `记忆表达` |
| `这里决定卡片布局。` | `决定这段回忆最终如何呈现。` |
| `配置完成。` | `这段回忆已经准备好。` |

These are writing examples, not a request to rename architecture symbols or
internal APIs. User-facing `Configuration Center` remains the frozen product
surface name, while explanatory copy should avoid narrating the user as
"configuring a system".

## Contextual Verb Boundary

`记录`, `计算`, and `生成` are contextual verbs, not globally preferred or
forbidden words.

- Use `记录` for accepted output nouns such as `时光记录`, factual history,
  `记录于`, user-authored wording, and established commerce identity. Do not
  use it for a button or prompt whose actual action is choosing or saving
  configuration.
- Use `计算` when a factual explanation, diagnostic, or recovery step requires
  precision. In ordinary configuration copy, describe the visible result,
  such as a photo's time relationship, instead of narrating an algorithm.
- Use `生成` for an explicit output action or processing state, such as
  `生成时光记录`. Do not use it as the primary explanation of Memory
  Expression or as a claim that MemoMark authors the user's story.

The test is semantic: the word must match what happens next. Replacing every
occurrence mechanically would make permission, output, commerce, and recovery
copy less accurate.

## Precision Boundary

Narrative language yields to clarity when the user must understand:

- what permission is being requested and why;
- whether an original photo will remain unchanged;
- whether a memory has been saved, failed, or needs attention;
- what Apple Photos or the system will do next;
- what a purchase, restore, deletion, or other irreversible action means.

In those cases, use direct factual wording first. Warmth may soften the tone,
but it must never hide the action, state, consequence, or next step.

### Home Workflow Reminder

The Home page keeps the primary Apple Photos lifecycle visible beneath `我的预设`
so a new user does not need to remember the onboarding explanation. Use this
accepted Simplified Chinese copy:

- Title: `怎么记录`
- Primary path: `从 Apple Photos 选择照片并分享给时光记；时光记会按当前预设在本地处理，完成后将新照片保存回 Apple Photos。`
- Secondary path: `PS：也可以使用下方“App 内选择照片”；日常记录仍建议从 Apple Photos 分享。`

The reminder is a compact informational card without an icon or a competing
action. The bottom photo-picker action is `App 内选择照片`; do not prefix it
with `备用`, because the workflow reminder already explains that it is the
secondary path and the isolated label sounds unexplained or provisional.

## Anchor And Variable Rule

Smart anchor variables output time results, not complete sentence copy. Users
compose the final wording by combining literal text with variables.

For example:

- `{{anchor_age_text}}` -> `1岁2个月18天`
- `{{anchor_countdown_text}}` -> `还有86天`

The user's wording remains their own.

### Birthday Anchor Day

When a photo's capture date and a configured birth anchor fall on the same
calendar day, this is a distinct memory moment, not an age duration of `0天`.
The complete Simplified Chinese birthday expression is:

> `{主体}今天来到这个世界啦！`

All birthday expression styles use this same anchor-day meaning. The reusable
age result remains a result rather than a sentence and is expressed as
`出生当天`. The English complete expression is `{Subject} arrived in the
world today`, and its reusable result is `day of birth`.

The date comparison follows the capture calendar. A photo captured shortly
after midnight belongs to the next calendar day even when fewer than 24 hours
have elapsed.

### Photo Description Composition

Photo Description begins with the complete resolved Memory Expression shown in
the Memory Card's right-bottom region. When the user enables `补充一段话`, the
trimmed custom text follows that complete expression on a separate line.

Do not replace the Memory Expression or rewrite the user's punctuation. If the
resolved expression is empty, the non-empty custom text may stand alone.
Preview and final output must use the same newline-separated composition rule.

## Commerce Identity And Capability

First Recorder is a historical commemoration. MemoMark+ unlimited recording is
a current capability. User-facing copy must never infer one from the other.

Use these accepted Settings projections:

- Current Plus Access with a First Recorder date: `首批记录者 · 无限记录` /
  `First Recorder · Unlimited Records`.
- Current Plus Access without a First Recorder date: the standard MemoMark+
  unlimited status.
- Free Access with a historical First Recorder date: `首批记录纪念 · <本地化原始日期>` /
  `First Recorder Keepsake · <localized original date>`.
- Free Access without a First Recorder date: the standard free or remaining-
  allowance status.

The historical free state may invite a person to learn about MemoMark+, but it
must not describe unlimited recording as a current capability. Visible copy and
VoiceOver must preserve the same distinction.

## Review Checklist

Before accepting user-facing copy, ask:

- Does it speak about a person, a moment, a memory, or the result the user wants?
- Is it short enough to leave room for the interface and the user's own story?
- Does it sound natural when read aloud?
- Does the title name the object while the subtitle explains the decision or visible effect?
- Could an internal implementation term be removed without losing meaning?
- Do `记录`, `计算`, and `生成` match the action in this specific context?
- Is it warm without trying to make the user emotional?
- Are permissions, errors, privacy, purchases, and destructive actions still exact?
- Does the copy preserve the Apple Photos lifecycle and the frozen product nouns?

When the answer is unclear, choose the simpler sentence and record the open
question instead of inventing more explanation.

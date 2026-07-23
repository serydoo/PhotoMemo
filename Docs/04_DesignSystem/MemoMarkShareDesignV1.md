# MemoMark Share Design v1

Status: Frozen

This is the frozen confirmation structure for the MemoMark iOS Share
Extension. It is a product-language and visual-structure contract, not a
queue or processing contract.

## Structure

```text
Hero
-> Summary Card
-> Promise Card
-> Brand Statement
-> Primary Action
```

The surface contains exactly:

- one Hero title and one Hero subtitle;
- one Summary Card with exactly three rows: `照片`, `配置`, `相册`;
- one Promise Card with exactly four assurance rows;
- one plain Brand Statement with one sentence;
- one primary button.

## Typography

All typography uses `MemoMarkDesignTokens.Typography`. The Hero remains the
strongest text layer. Summary and Promise module titles are subordinate. Value
text is prominent inside the cards, while labels and support text use the
secondary roles.

The Hero subtitle is `N 张照片准备开始记录`; the primary button remains
`生成时光记录`, so the Hero and Action do not repeat the same verb.

The top app name is tertiary identity text and must not compete with the Hero.

The Hero subtitle uses semantic `secondaryLabel`. It must remain readable in
both light and dark appearances without a custom gray value.

## Spacing

- Use the existing 8pt spacing rhythm for card content and row groups.
- Keep 8pt between a summary row label and its value.
- Keep 24pt continuous corner radius and 24pt internal padding on functional
  Cards and the primary button.
- Keep summary dividers 12pt inset from the row group's leading and trailing
  edges.
- Keep 24pt between the primary button and the bottom safe area.
- Keep the existing 440pt preferred-height request; the system Share Sheet
  remains the final detent owner.

## Promise Icons

The four Promise rows are fixed to these SF Symbols and may be reworded only
as a replacement within the same four-row contract:

| Symbol | Meaning | Rendering |
| --- | --- | --- |
| `photo.stack.fill` | Original photo remains unchanged | Secondary hierarchical |
| `doc.badge.gearshape` | Capture information is retained | Secondary hierarchical |
| `bell.fill` | Completion notification | Secondary hierarchical |
| `arrow.right.circle.fill` | Continue sharing the next batch | Secondary hierarchical |

Promise icons remain monochrome hierarchical system symbols. Semantic color
belongs to the Iconography Reserve, but this compact Share surface does not
alternate accent colors row by row.

Do not add a fifth row. Replace an assurance only when the product promise
changes.

## Freeze Boundary

Do not add renderer settings, template terminology, EXIF terminology, queue
controls, extra summary rows, or additional actions to this confirmation
surface without a new product decision and a new visual verification pass.

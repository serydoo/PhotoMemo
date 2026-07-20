# Configuration Center Window Specification

Status: V3 UI foundation

This document defines the reusable window and card hierarchy for the
Configuration Center and adjacent iOS configuration surfaces. New screens and
new content must fit this hierarchy before they introduce local spacing or
container behavior.

## Hierarchy

```text
Window
└── Page Surface
    └── Bounded Content Column
        ├── Section Header
        └── Configuration Card
            ├── Card Header (optional)
            └── Inner Panel
                └── Information / Editing Rows
```

- Window owns navigation, background, safe area, and presentation detents.
- Page Surface owns scrolling and available geometry.
- Bounded Content Column owns readable width and horizontal margins.
- Configuration Card owns the outer surface, shadow, and card spacing.
- Inner Panel owns the rounded bordered group of related controls.
- Rows own icons, labels, values, dividers, and interaction targets.

Child content must not create a second page-width policy. An editor row may
compress or wrap inside its panel, but it must never report an unbounded width
that changes the card or page width.

## Geometry

| Level | Rule |
| --- | --- |
| Window | Fills the available navigation or sheet surface. |
| Bounded Content Column | Receives a bounded geometry proposal before entering `ScrollView`. |
| iPhone content margin | 18pt Configuration Center baseline, applied with `v1AdaptiveScrollContent(horizontalPadding: 18)`. |
| Configuration Card outer padding | 14pt. |
| Inner Panel | Full width of the card content column, not the window. |
| Inner Panel row padding | 12pt horizontal; 9pt vertical for compact rows. |
| Related card spacing | 14pt between cards; 18pt for distinct page sections. |
| Readable width | Cap at `V1AdaptivePageLayout.maximumReadableContentWidth`. |

The bounded width must be calculated before the `ScrollView` content is
measured. Do not use a child `frame(maxWidth: .infinity)` as a substitute for
the page proposal.

## Surface Tokens

| Surface | Fill | Border | Radius | Shadow |
| --- | --- | --- | ---: | --- |
| Page | `ConfigurationUI.appBackground` | none | n/a | none |
| Configuration Card | `ConfigurationUI.panelBackground` | `ConfigurationUI.faintHairline` | 18pt | `V1CardChrome` |
| Inner Panel | panel background or white | `ConfigurationUI.faintHairline` | 18pt | none |
| Selection control | `ConfigurationUI.selectedBackground` | optional hairline | 12pt | none |
| Icon tile | semantic tint at 9–12% | none | 10–12pt | none |

The outer card and inner panel are distinct surfaces. A card must not use the
same view as both its outer chrome and its inner bordered group.

## Typography

| Role | SwiftUI style | Weight |
| --- | --- | --- |
| Page title | `.title2` | bold |
| Section title | `.title3` | semibold |
| Row title | `.subheadline` | semibold |
| Editable field label/value | `.body` | regular or medium |
| Row subtitle | `.caption` | regular |
| Detail/status | `.caption` or `.caption2` | semibold |

Object overview pages use the same roles as the Configuration Center. A
subject name is a section-level identity title only when it introduces a
distinct identity block.

## Row Contracts

Every row inside an inner panel defines:

- a stable leading icon slot when it represents a semantic category;
- a primary title and optional secondary description;
- a trailing value, control, or navigation indicator;
- a minimum interaction height of 44pt;
- a divider owned by the row group;
- truncation or wrapping behavior for narrow and accessibility layouts.

Editable rows keep the field editor inside the row's proposed width. The value
field may compress or truncate; a `TextField` must not establish the width of
its ancestor card.

## Window Variants

### Configuration Center

```text
Preview -> Bounded Detail Column -> Configuration Cards
```

### Subject Overview

```text
Navigation Sheet -> Bounded Content Column -> Subject Rail -> Cards
```

The basic-information card and available-anchor card share the same outer card
construction and width proposal.

The basic-information card has exactly one outer Configuration Card and one
Inner Panel. The subject editor and the time-anchor entry row are children of
that panel; neither may add another card chrome or a second page-width frame.

### Detail Sheet

Uses a bounded scroll column and may use a large presentation detent. It must
not introduce a second card chrome or a different horizontal margin token.

## Adaptive Rules

- At compact iPhone widths, a rail with multiple actions switches to a stacked
  layout before controls are clipped.
- Card content stays within the bounded column; only text wraps or truncates.
- Accessibility Dynamic Type may increase row height, but not page width.
- iPad and Mac may widen the bounded column up to the readable-width cap.
- New window content first reuses `V1CardSurface` and
  `V1ConfigurationCardContainer`; custom chrome requires a documented reason.

## Implementation Checklist

1. Identify the window variant and bounded content owner.
2. Establish bounded page geometry before measuring scroll content.
3. Choose Configuration Card or Inner Panel, not both for one surface.
4. Map text to the typography roles above.
5. Define compact-width and Dynamic Type behavior.
6. Verify beside the Configuration Center on a physical iPhone.

This specification preserves the frozen Configuration Center architecture
while making future window and content additions predictable and reviewable.

# MemoMark Typography Tokens

Status: active shared contract, incremental adoption

MemoMark UI typography follows semantic Apple system roles first. The numeric
sizes below are the UIKit base sizes used when a UIKit surface needs a precise
starting point; they do not replace Dynamic Type or the existing SwiftUI role
standards.

| Token | UIKit base | SwiftUI role | Weight | Use |
| --- | ---: | --- | --- | --- |
| `hero` | 28 | `.title2` | bold | Share confirmation outcome |
| `heroSubtitle` | 17 | `.body` | regular | Hero supporting sentence |
| `sectionTitle` | 19 | `.title3` | semibold | Primary grouped-card title |
| `value` | 20 | `.headline` | medium | Photo count, subject, album |
| `moduleTitle` | 17 | `.headline` | semibold | Processing/status module |
| `body` | 16 | `.body` | regular | Normal explanatory text |
| `detail` | 15 | `.subheadline` | regular | Checklist and compact status |
| `secondary` | 14 | `.caption` | regular | Muted support text |
| `brand` | 14 | `.caption` | medium | Brand label and memory sentence |
| `caption` | 13 | `.caption2` | regular | Dense metadata/helper text |
| `button` | 17 | `.body` | semibold | Primary action title |

## Ownership

The implementation lives in:

`Source/PhotoMemo/PhotoMemo/App/MemoMarkDesignTokens.swift`

The file is shared by the iOS application and Share Extension through the
existing `App` source boundary. `MemoMarkTypographyToken` is not a
second Share-only design system. Its `swiftUIFont` property follows the
existing main-program semantic SwiftUI styles, while `uiFont()` applies the
same role and weight through `UIFontMetrics` for Dynamic Type-aware UIKit
surfaces.

`RendererConstants.Typography` remains owned by the Memory Card renderer. It
defines rendered-card typography and must not be repurposed as an application
UI token namespace.

## Adoption

Phase 1 migrates the Share Extension confirmation surface. Future main-app,
notification, and Live Activity migrations should replace local font choices
role by role and verify compact width and accessibility sizes before changing
their current visual structure.

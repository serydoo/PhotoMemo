# MemoMark Localization Foundation

Status: V3 bilingual delivery slice completed. The app now carries the
Simplified Chinese and English language context through configuration, preview,
memory generation, export transport, and Share Extension handoff. The active
language can follow the system or use an App-level override.

## Launch Scope

The initial supported languages are:

- `zh-Hans`: Simplified Chinese
- `en`: English

Unsupported locales fall back to English when selected by locale resolution.
Existing configurations and legacy task payloads without a language field
remain Simplified Chinese for compatibility.

## Resource Boundaries

| Area | Owner | Localization rule |
| --- | --- | --- |
| App UI | Localized resource files (`.strings`) | Stable keys; no display string used as logic |
| Preset and module names | Presentation resource | Stable Preset/module IDs remain unchanged |
| Anchor calculations | Memory Engine | Computes numbers and semantic state only |
| Anchor result text | Memory language formatter | Formats values for the selected language |
| User-entered names and sentences | Configuration data | Never auto-translate |
| Preview and export language | Configuration snapshot | Must use the same language context |
| App Store metadata | App Store Connect | Localized per storefront, outside the app bundle |

## Compatibility Rules

1. Existing Codable IDs and configuration payloads must not change because a
   display language is added.
2. Localized strings must never be used as persistence keys, feature flags, or
   renderer routing values.
3. The current Chinese computed properties remain compatibility shims while
   downstream consumers migrate to language-aware formatting.
4. Preview, Share Extension processing, and export must eventually receive the
   same language context. No partial language switch is acceptable for a saved
   output.
5. CJK and Latin text must be checked against the same measurable layout
   constraints. Adding a translation is not complete until long-string and
   line-wrapping cases are tested.

## Completed Slices

1. Anchor result formatting for `zh-Hans` and `en`.
2. Configuration Snapshot and BatchConfigurationSnapshot language context.
3. Preview, Memory Engine, production resolver, and Share transport language
   propagation.
4. Natural English phrasing for birthday, relationship, marriage, exam, and
   custom anchor styles.
5. en.lproj and zh-Hans.lproj resources for active Configuration Center and
   Share Extension UI.
6. Configuration Center language picker with App Group persistence and a
   Follow System option.
7. English date presentation in active date and status presenters.
8. Legacy Codable fallback and natural-language regression tests.
9. Stable variable IDs derived from tokens, localized built-in Preset and
   variable titles, and durable configuration language persistence.
10. RTL locale gate: Arabic and Hebrew remain unavailable until directional
    Layout Engine support exists.
11. Separate App interface-language preference and output-language preference;
    the former is applied at the root UI locale boundary and the latter remains
    part of the Configuration Snapshot.

## Remaining Release Work

1. Translate the remaining long-tail legacy UI strings and App Store Connect
   metadata/screenshots as a separate content pass.
2. Manually verify the iOS Configuration Center, Share Extension, preview, and
   exported card at English and Simplified Chinese on simulator or device.
3. Review final English copy with a native-speaking product/content reviewer.

The implemented slice keeps the local-first pipeline intact and makes each
remaining content pass independently testable and reversible.

# MemoMark Narrative Product Language Pass

Date: 2026-07-28; language guide frozen 2026-07-29
Status: Implemented; scoped automated verification complete
Primary loop: Product Loop
Risk: P2

## Objective

Align the active MemoMark user-facing headings and subtitles with the approved
brand personality: natural, restrained, warm, and centered on people and
memories rather than implementation concepts. The pass covers the active iOS
entry flow, its Chinese and English localization keys, and the macOS
Configuration Center column labels.

## Assumptions

1. The four user-approved copy decisions are authoritative.
2. Established product nouns such as Configuration Center, Preset, Memory
   Subject, Time Anchor, Apple Photos, EXIF, and Live Photo remain available
   when precision or architecture requires them.
3. Status, privacy, permission, destructive-action, purchase, and recovery
   copy remains direct and factual.
4. The current iOS row is titled `卡片内容`; this pass changes its subtitle
   only. A future title rename requires a separate explicit decision.

## Approved Copy Direction

- `记忆来源` subtitle: `你想围绕谁开展回忆。`
- `时间锚点` subtitle: `从哪个重要时刻开始记录。`
- `记忆显示` title: `记忆表达`
- `卡片内容` subtitle: `决定这段回忆最终如何呈现。`
- Narrative subtitles describe the user's memory and intended result, not how
  a module, algorithm, or metadata pipeline works.

The broader rule is now frozen in
`Docs/Guidelines/PRODUCT_LANGUAGE_GUIDE.md`: MemoMark has `生活感` rather than
`文学腔`. It should sound like a quiet friend helping the user organize a
memory, not like an explanation of a program.

## Scope

In scope:

- active iOS Configuration Center, Home, Output, Processing, Welcome, and
  Settings headings/subtitles;
- related Simplified Chinese and English localization entries;
- macOS Configuration Center column labels.

Out of scope:

- configuration state, persistence, Memory Engine, Layout Engine, Renderer,
  Export, Share Extension, PhotoKit, and Apple Photos lifecycle behavior;
- status, error, permission, accessibility, destructive-action, and commerce
  semantics unless a heading is explicitly part of the approved copy set;
- the temporary or retired editor entry paths.

## Verification

- Add a Swift Testing source contract for the approved vocabulary and key
  headings before changing production copy.
- Run the focused narrative-language contract and existing configuration copy
  contracts.
- Build `PhotoMemoiOS` with isolated DerivedData and run `git diff --check`.
- Review the diff for copy-only changes and record manual visual verification
  as pending unless a healthy simulator or signed device is available.

## Verification Results

- The narrative vocabulary contract and related Configuration Center,
  Apple-native, navigation, and presenter contracts passed for the scoped pass.
- Unsigned generic iOS Simulator and macOS Debug builds completed, and
  `plutil -lint` plus `git diff --check` passed for that pass.
- The later cross-pass review corrected stale responsive-layout and Settings
  disclosure expectations that still referenced retired copy; their focused
  rerun passed.
- The final integrated `PhotoMemoTests` run passed 1,185 tests with one skip and
  zero failures, and the final unsigned generic iOS build passed. The signed
  integrated build was overwrite-installed and launched on the paired physical
  `iPhone7` without uninstalling the app or clearing its container. This is
  deployment evidence only; no simulator or physical-device visual acceptance
  of the revised copy is claimed here.

## Open Follow-up

The exact Chinese replacement for the macOS `资料库` and `检查器` labels is
included as a conservative display-only polish (`记忆对象` and `编辑`). Any
broader terminology change inside the frozen Library -> Interactive Memory
Card -> Object Inspector architecture requires a separate product decision.

Remaining long-tail Chinese fallback strings that can appear under English are
outside this scoped vocabulary pass and require a separate localization audit.

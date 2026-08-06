# V4 Interface Language Refinement

Date: 2026-08-05

Status: Implemented; Manual Device Acceptance Pending

Primary loop: `Product Loop`

Risk: `P1`

## Objective

Refine the active iOS Configuration Center language where the current copy is
semantically inaccurate, implementation-centered, repetitive, or mismatched
with the action it labels. Preserve MemoMark's established narrative tone and
stable product nouns instead of adopting an external copy system wholesale.

Success means that the main configuration path names the object being edited,
briefly states the user-visible decision or result, and does not require users
to understand Memory Engine calculations or UI module structure.

## Observed State

The current interface already has a coherent language hierarchy:

```text
Memory Subject
-> Time Anchor
-> Memory Expression
-> Preset
-> Card Content
-> Save Destination
```

Most titles are accurate and should remain stable. The bounded problems are:

- the Time Anchor subtitle describes configuration as starting a record;
- `高级模块` exposes an internal implementation noun even though the surface
  only adjusts location and capture-time presentation;
- subject-detail subtitles foreground calculation rather than the visible
  effect on a photo;
- first-run completion says `开始记录` even though the action saves setup;
- several section subtitles are repetitive, mechanically worded, or describe
  a preview that the section does not show;
- the Output page does not consistently say that MemoMark creates a new photo.

## Existing Sources Of Truth

This change completes the existing language system. It does not create a
parallel standard.

- `Docs/Guidelines/PRODUCT_LANGUAGE_GUIDE.md` remains canonical.
- `Docs/Guidelines/LANGUAGE_SYSTEM.md` owns supporting language constraints.
- `Docs/Guidelines/PRODUCT_PERSONALITY.md` owns tone.
- `Docs/Localization/README.md` owns bilingual resource boundaries.
- IA-002 continues to own the Configuration Center structure.

## Product Language Decisions

1. A title names the user-recognizable object or destination.
2. A subtitle states either the decision made here or its visible effect.
3. Parent copy should not repeat information already clear from child rows.
4. Narrative warmth must not hide the action or introduce poetic ambiguity.
5. `模块`, `算法`, and `计算` are not primary configuration language.
6. `记录` is judged by context rather than prohibited mechanically:
   - avoid it when the action is configuring or saving setup;
   - retain it for accepted output nouns such as `时光记录`, user-authored
     content, `记录于`, commerce identity, and factual history or diagnostics.
7. `生成` remains valid for an explicit output action or processing state, but
   not as the main explanation of Memory Expression.
8. Stable product nouns remain `配置中心`, `记忆对象`, `时间锚点`,
   `记忆表达`, `预设`, and `Apple Photos`.

## Accepted Copy Changes

| Surface | Current | Accepted |
| --- | --- | --- |
| Configuration Center subtitle | `从一个人和一个重要时刻开始，让回忆慢慢成形。` | `围绕一个人和一个重要时刻，决定照片如何呈现。` |
| Memory Source subtitle | `你想围绕谁开展回忆。` | `围绕谁、以哪个重要时刻为参考，又如何表达。` |
| Time Anchor subtitle | `从哪个重要时刻开始记录。` | `选择一个重要时刻，呈现照片与它的时间关系。` |
| Card Layout subtitle | `决定卡片各区域的内容与显示形式` | `决定卡片里的内容与显示方式。` |
| Advanced Modules | `高级模块` | `更多信息` |
| Advanced Modules subtitle | `部分高级模块的展示形式选择` | `调整地点与拍摄时间的显示方式。` |
| Region Content sheet title | `区域内容设置` | `卡片内容` |
| Subject editor anchor subtitle | `管理用于计算的时间参考` | `维护与这个对象有关的重要时刻。` |
| Subject overview anchor subtitle | `用于计算记忆对象的时间参考` | `这些重要时刻会影响照片中的时间表达。` |
| Home Preset subtitle | `下一次分享，要用哪种方式记录。` | `下一次分享，照片会怎样呈现。` |
| Output page subtitle | `决定最后留下的照片，也选择它回到哪里。` | `决定新照片如何留下，也选择它回到哪里。` |
| Output result section | `最终结果` | `新照片` |
| Output result subtitle | `先看看这段回忆会以什么样子留下。` | `选择照片形式与需要保留的信息。` |
| Default photo-description note | `会根据照片拍摄时间、记忆对象和时间锚点写下这段回忆。` | `会根据拍摄时间、记忆对象和时间锚点，写入对应的记忆表达。` |
| First-run introduction | `告诉时光记你想围绕谁记录，以及从哪个重要时刻开始。` | `告诉时光记这段回忆围绕谁，以及哪个重要日子最重要。` |
| First-run subject section | `想围绕谁记录` | `想围绕谁` |
| First-run result summary | `按这个重要时刻记录变化` | `按这个重要时刻呈现时间变化` |
| First-run completion | `开始记录` | `完成设置` |
| Waiting task guidance | `从 Apple Photos 分享照片，就能开始记录。` | `从 Apple Photos 分享照片，即可开始生成。` |

The visible `更多信息` name does not rename the internal
`V1AdvancedModulesSheet` type or persisted module concepts.

### Historical Supersession

The original matrix above records the first accepted 2026-08-05 language pass.
Later physical-device evidence in
`V4_Configuration_Center_Anchor_Preview_Refinement_2026-08-05.md` supersedes
two compact Configuration Center rows without erasing that history:

- Memory Source returns to `你想围绕谁开展回忆。`.
- The compact Time Anchor row uses `回忆对象重要时刻`, while its editor owns
  the complete prompt `选择一个时间起点，让照片拥有时间答案。`.

These later phrases are the current source of truth.

## Ownership And Dependency Impact

Affected ownership:

- iOS presentation views and their accessibility labels;
- Simplified Chinese and English localization resources;
- source-level UI language contracts;
- canonical language documentation and current repository status.

Unaffected ownership:

- Memory Engine calculations and anchor semantics;
- Presentation Engine formulas and user-authored expression content;
- Layout Engine and Renderer behavior;
- configuration persistence and migration;
- Export, Share intake, PhotoKit, commerce identity, and original-photo safety.

## Apple-Native Evaluation

The change reuses existing SwiftUI page headers, section cards, navigation
titles, sheets, buttons, Dynamic Type behavior, and VoiceOver surfaces. It adds
no custom control, navigation layer, Apple framework, permission, or lifecycle.
Shorter titles should reduce compact-width and accessibility-size pressure.

## Failure Modes And Controls

- Risk: copy explains only one child row. Control: source contract covers the
  full Memory Source sequence.
- Risk: changing `记录` breaks accepted output or commerce identity. Control:
  scope assertions target configuration-only phrases and preserve output nouns.
- Risk: Chinese and English drift. Control: resource-key symmetry and explicit
  bilingual assertions.
- Risk: visible copy changes while VoiceOver retains old terms. Control: update
  accessibility labels and hints in the same slice.
- Risk: raw string edits silently remove required UI structure. Control:
  existing architecture contracts and an unsigned build remain mandatory.

## Implementation Plan

1. Update language contracts first and confirm they fail against old copy.
2. Refine Configuration Center, subject, region-content, Home, Output, first-run,
   and waiting-state copy in bounded source increments.
3. Synchronize Simplified Chinese and English resources and accessibility copy.
4. Amend the canonical language guide and supporting language-system examples.
5. Run focused tests, localization lint, static phrase audit, and unsigned build.
6. Review the final diff across correctness, simplicity, architecture, privacy,
   performance, accessibility, and localization.
7. Record the completed product-language milestone in `Docs/CURRENT_STATUS.md`.

## Verification Commands

```bash
xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj \
  -scheme PhotoMemoTests -configuration Debug \
  -destination 'platform=macOS' \
  -derivedDataPath /tmp/PhotoMemoLanguageDerivedData \
  CODE_SIGNING_ALLOWED=NO COMPILER_INDEX_STORE_ENABLE=NO -quiet test \
  -only-testing:PhotoMemoTests/MemoMarkNarrativeLanguageContractTests \
  -only-testing:PhotoMemoTests/V1ConfigurationOptionListContractTests \
  -only-testing:PhotoMemoTests/V1DesignFreezePolishContractTests \
  -only-testing:PhotoMemoTests/AppleNativeProductSurfaceContractTests \
  -only-testing:PhotoMemoTests/ConfigurationCenterOutputPanelPresenterTests \
  -only-testing:PhotoMemoTests/MemoryWriteOptionPresenterTests

plutil -lint Source/PhotoMemo/PhotoMemo/zh-Hans.lproj/Localizable.strings
plutil -lint Source/PhotoMemo/PhotoMemo/en.lproj/Localizable.strings

xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj \
  -scheme PhotoMemo -configuration Debug \
  -derivedDataPath /tmp/PhotoMemoDerivedData \
  CODE_SIGNING_ALLOWED=NO -quiet build
```

## Completion Evidence

- The language contracts were updated first and failed against the retired
  copy before implementation.
- Focused narrative-language, Configuration Center, Output, first-run,
  accessibility, localization, and commerce resource-symmetry contracts pass.
- The complete `PhotoMemoTests` suite passes. Its first run exposed one stale
  responsive-layout assertion for the old Configuration Center subtitle; that
  contract was aligned and the complete suite passed on the final rerun.
- Both localization resources pass `plutil -lint`; `git diff --check` passes.
- The required unsigned `PhotoMemo` Debug build and the `PhotoMemoiOS` Debug
  build pass.
- A signed `PhotoMemoiOS` Debug build was overwrite-installed and launched on
  the paired physical `IPhone5` iPhone 15 Pro without uninstalling the app or
  clearing its data. The installed version is `2.0.2 (69)`.
- Per the user's verification direction, no simulator visual acceptance is
  claimed. Manual compact-width, Dynamic Type, English, and VoiceOver review
  remains for the user on the installed iPhone 15 Pro build.
- Final review found no change to IA-002, navigation, state ownership,
  persistence, Memory Engine, Renderer, Export, PhotoKit, privacy, or the
  original-photo boundary.

## Acceptance Criteria

- The accepted copy matrix appears in the active iOS surfaces.
- Configuration UI no longer presents `高级模块`, `开始记录`, or
  `从哪个重要时刻开始记录` in the affected configuration path.
- `生成时光记录`, `记录于`, commerce identity, diagnostics, and user-authored
  expression options remain unchanged.
- Simplified Chinese and English resources stay syntactically valid and
  symmetric.
- Visible text and VoiceOver use the same product nouns.
- Focused contracts and the unsigned Debug build pass.
- Simulator or physical-device evidence checks compact layout, Dynamic Type,
  and the primary Configuration Center -> Output path; any unverified item is
  stated explicitly.

## Open Questions

No blocking product question remains. A repository-wide review of historical,
commerce, release-note, and diagnostic uses of `记录` is explicitly deferred;
those contexts require separate semantic decisions rather than bulk replacement.

## 2026-08-06 Runtime Language And Accessibility Closure

### Observed Current Behavior

A final source review after the first physical-device delivery found three
bounded gaps in the accepted interface-language pass:

- shared page headers, configuration-sheet subtitles, and compact
  configuration-row headings receive ordinary `String` values and can remain
  Chinese after the in-app interface language changes to English;
- the Memory Source disclosure control and custom Logo picker preserve the
  intended compact visible treatment but do not expose the shared 44-point
  minimum interaction target;
- page subtitles always stop at two lines, including Accessibility Dynamic
  Type sizes.

The Photo Description composition contract is unaffected. The complete
resolved right-bottom Memory Expression continues to join directly to the
trimmed optional user text with no automatic space, newline, punctuation, or
other separator. Users remain the sole owners of connecting punctuation.

### Intended Outcome

- Static shared headings and subtitles resolve through the selected MemoMark
  interface language at runtime, including the More Information sheet.
- Compact controls retain their current visible size and trailing alignment
  while their interaction frame meets the 44-point Apple-platform target.
- Page subtitles retain a two-line cap at standard text sizes and can expand
  without a line cap at Accessibility Dynamic Type sizes.

### Scope And Ownership

The bounded implementation may change only:

- shared iOS page-header and configuration-sheet subtitle presentation;
- Configuration Center row-heading and compact-control presentation;
- More Information labels and option-title presentation;
- Simplified Chinese and English resources;
- source-level UI contracts and current-state evidence.

It does not change IA-002, configuration persistence, Memory Engine semantics,
Presentation Engine content, Layout Engine, Renderer, Export, PhotoKit, or the
zero-separator Photo Description contract.

### Verification Plan

1. Strengthen source contracts first and confirm the current implementation
   fails the runtime-localization, minimum-hit-target, and Dynamic Type rules.
2. Apply the smallest SwiftUI and localization-resource changes that satisfy
   those contracts without increasing visible control chrome.
3. Run the focused UI contracts, resource lint and key-symmetry checks.
4. Run the complete test suite and required unsigned and signed builds because
   production UI source and localized resources changed after prior evidence.
5. Overwrite-install and launch the final signed build on the paired iPhone 15
   Pro without using a simulator; leave visual English, Dynamic Type and
   VoiceOver acceptance to the user.

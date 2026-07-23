# Iconography Consistency UI Pass

Date: 2026-07-21

## Objective

Apply the V3 iconography reserve to the active iOS Configuration Center
without changing product flow, data, Memory Engine, renderer, export, or
Apple Photos behavior. Existing compact icon geometry remains the visual
implementation standard.

Success means that one semantic concept uses one named `MemoMarkSymbol`, the
agreed 16 headings or entry rows have an adjacent semantic icon, and existing
buttons, navigation, bindings, and accessibility labels retain their behavior.

## Scope

In scope:

- `MemoMarkSymbol` semantic names and SF Symbol values.
- Compact card-heading presentation in the iOS UI layer.
- The following 16 confirmed positions:
  1. 时间锚点配置
  2. 我的配置
  3. 记忆对象
  4. 意见反馈
  5. 输出目标
  6. 写入与保留
  7. 保存选项
  8. 最近任务
  9. 为什么是时光记
  10. 使用与帮助
  11. 版本信息
  12. 能力与边界
  13. 反馈渠道
  14. 隐私与数据
  15. 初次打开你会用到
  16. 推荐流程

Out of scope:

- Renderer, metadata, export, share extension, Photo Library, and persistence.
- Navigation titles, helper paragraphs, and all non-confirmed card headings.
- New dependencies, image assets, or changes to interaction actions.

## Existing Visual Contract

- Compact icon tile: 36 pt square, 11 pt corner radius, 12 pt content spacing.
- Compact disclosure icon tile: 34 pt square, 10 pt corner radius.
- Semantic tile background: 10-12 percent tint opacity.
- Existing grouped system backgrounds, type hierarchy, padding, and Dynamic Type
  fallbacks remain unchanged.

The research reserve's 44-48 pt primary-row size is not introduced in this
pass. The active Configuration Center uses the compact 34-36 pt language.

## Implementation Plan

1. Extend the semantic icon catalog and add a source-contract test for its
   values and compact heading support.
2. Add an optional leading icon to reusable compact card and section headings.
3. Apply the 16 approved symbols by surface, retaining all current action and
   navigation closures.
4. Run the focused contracts, full test suite, unsigned Debug build, and a
   signed physical-device Debug build. Manually inspect the connected device
   for default and accessibility Dynamic Type.

## Commands

```bash
xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemoTests -configuration Debug -derivedDataPath /tmp/PhotoMemoDerivedData CODE_SIGNING_ALLOWED=NO test
xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemo -configuration Debug -derivedDataPath /tmp/PhotoMemoDerivedData CODE_SIGNING_ALLOWED=NO -quiet build
xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemoiOS -destination 'platform=iOS,id=00008150-000A043136A1401C' -configuration Debug -derivedDataPath /tmp/PhotoMemoIconographySignedDeviceDerivedData -quiet build
xcrun devicectl device install app --device 00008150-000A043136A1401C /tmp/PhotoMemoIconographySignedDeviceDerivedData/Build/Products/Debug-iphoneos/PhotoMemoiOS.app
xcrun devicectl device process launch --device 00008150-000A043136A1401C --terminate-existing com.serydoo.PhotoMemo.iOS
```

## Testing Strategy

- Source-contract tests prove the semantic catalog values and the presence of
  each approved title symbol.
- Existing responsive-layout contracts protect Dynamic Type and viewport
  behavior.
- Builds prove the macOS and iOS target graphs remain valid.
- Manual verification checks icon hierarchy, truncation, light mode, and the
  unchanged behavior of every touched button or navigation row.

## Boundaries

- Always preserve text labels and existing accessibility behavior; decorative
  leading icons remain redundant with adjacent text.
- Ask first before changing a renderer, product flow, persistence format, or
  adding any unapproved heading.
- Never add raster icon assets, modify original photos, or change state/action
  closures in this UI-only pass.

## Verification Result

- 2026-07-21: `PhotoMemoTests` passed with 983 tests, 0 failures, and 1
  skipped test. Existing QoS and Photo RAW/Live Photo declaration runtime
  warnings remain outside this UI-only scope.
- The unsigned macOS Debug product was built at
  `/tmp/PhotoMemoMacIconographyDerivedData/Build/Products/Debug/PhotoMemo.app`.
- The signed iOS Debug product was installed and launched on the connected
  physical iPhone7 device. `devicectl` confirmed the `PhotoMemoiOS` process
  remained running after launch.

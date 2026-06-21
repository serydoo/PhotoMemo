# PhotoMemo Current Status

Last updated: 2026-06-21

## Current Stage

PhotoMemo is currently in a combined refinement stage:

- Product-wise, it is moving from a **template calibration center** toward a **workflow preparation app built on Personal Profile + Style + Share-first Workflow**
- Engineering-wise, it is moving from a large prototype-style `MainView` toward a more maintainable coordinator structure
- Capability-wise, the project has already crossed the MVP foundation line:
  - real EXIF import
  - anchor calculation
  - preview rendering
  - export to new image
  - save back to Photo Library
  - background queue and permission foundation

According to `Docs/DEVELOPMENT_PLAN.md`, the project is between:

- Phase 2: Template Calibration Center
- Phase 5: Render Fidelity And Metadata Hardening

## 1.29 Classic White now has manual visual references and snapshot-grade regression checks

This slice stays renderer-only.

It does not change:

- metadata pipeline behavior
- memory engine behavior
- batch behavior
- share product flow

What landed:

- committed manual reference PNGs under:
  - `Tests/Fixtures/RendererSnapshots/ClassicWhite/full-card/`
- new snapshot support:
  - `ClassicWhiteSnapshotSupport`
  - deterministic synthetic scenarios for:
    - `landscape_standard`
    - `landscape_long_exif`
    - `portrait_standard`
    - `portrait_long_memory`
- new snapshot regression suite:
  - `ClassicWhiteSnapshotTests`
- new workflow doc:
  - `Docs/ClassicWhiteVisualQA.md`

Why this matters:

- Classic White is no longer protected only by theme constants and width math
- the project now has a small but real visual baseline for the full rendered card
- future typography, spacing, divider, or truncation drift can be caught before it reaches device testing

Snapshot policy:

- reference images are synthetic and deterministic
- record mode is explicit via `.record-mode`
- reference refresh uses exported Xcode test attachments
- normal comparison allows only a tiny tolerance for attachment-refresh color drift:
  - `maxChannelDelta <= 1`
  - differing pixels below `0.05%`

Verification for this slice:

- targeted snapshot tests passed:
  - `ClassicWhiteSnapshotTests`
- `PhotoMemoTests` full suite passed
- builds passed:
  - `PhotoMemo`
  - `PhotoMemoiOS`
  - `PhotoMemoShareExtension`
- device install passed:
  - `iPhone7` (`iPhone 17 Pro Max`)
- device launch passed:
  - `com.serydoo.PhotoMemo.iOS`

## 1.28 Classic White now has second-layer regression guards for routing and grid math

This slice continues the Classic White renderer-only hardening work.

It still does not change:

- metadata pipeline behavior
- memory engine behavior
- batch behavior
- share product flow

What landed:

- `RecordCardRenderer`
  - now exposes an explicit `destination(for:)` helper
  - the view body routes through that helper instead of hiding the preset switch inline
- `ClassicWhiteCardRenderer`
  - now exposes `layoutMetrics(forTotalWidth:)`
  - the live layout uses the same computed metrics that tests can assert against
- new renderer regression tests:
  - `RecordCardRendererRoutingTests`
  - `ClassicWhiteCardRendererLayoutTests`

Why this matters:

- Classic White routing is now locked at the renderer boundary instead of only indirectly through preset tests
- the fixed `40 / 20 / 40` grid is now covered as real width math, not just as theme constants
- future refactors are less likely to silently break module widths or route the wrong preset into the wrong renderer

Verification for this slice:

- tests passed:
  - `PhotoMemoTests`
- targeted renderer tests passed:
  - `RecordCardRendererRoutingTests`
  - `ClassicWhiteCardRendererLayoutTests`
  - `ClassicWhiteRendererThemeTests`
- builds passed:
  - `PhotoMemo`
  - `PhotoMemoiOS`
  - `PhotoMemoShareExtension`

## 1.27 Classic White now uses a fixed render design system

This slice is renderer-only.

It does not change:

- metadata pipeline behavior
- memory engine behavior
- batch behavior
- share product flow

What landed:

- `RenderTheme.swift`
  - introduces shared render-theme tokens for:
    - bottom bar
    - colors
    - grid
    - typography
    - spacing
    - divider
    - center module
- `ClassicWhiteRenderer`
  - no longer uses ratio-based border math
  - now exposes a fixed-height export sizing rule:
    - `imageHeight + 260`
- `ClassicWhiteCardRenderer`
  - extracts Classic White out of `RecordCardRenderer`
  - now renders with an explicit:
    - left module
    - center module
    - right module
  - uses fixed text sizes and truncation instead of scaling
- `RecordCardRenderer`
  - is back to being a layout router only
- `RecordCardExportService`
  - now reads Classic White export size from the renderer instead of old border ratios
- `Docs/RENDER_SPEC.md`
  - is now aligned with the new design-system values

Why this matters:

- Classic White now behaves like an information-card system instead of a proportional border experiment
- preview and export sizing are easier to reason about
- future themes can reuse the same theme-driven structure instead of adding more magic numbers inside the renderer

Verification for this slice:

- tests passed:
  - `PhotoMemoTests`
- targeted theme tests passed:
  - `ClassicWhiteRendererThemeTests`
- builds passed:
  - `PhotoMemo`
  - `PhotoMemoiOS`
  - `PhotoMemoShareExtension`
- compatibility note:
  - `ClassicWhite` files are now explicitly excluded at compile time from the share-extension target path via `PHOTOMEMO_SHARE_EXTENSION`, so renderer refactors do not leak into the lightweight intake target

## 1.26 Immers right-column alignment and placeholder naming fallback are now tightened

This slice keeps the scope narrow and user-facing.

What landed:

- `ImmersWhiteRenderer`
  - keeps the right column explicitly left aligned
  - now uses separate spacing for:
    - logo -> divider
    - divider -> right text
  - gives the right column more usable width in both portrait and landscape
  - enables text tightening so long EXIF lines are less likely to look visibly smaller than the left title line
- `PhotoFileNameResolver`
  - now treats `PhotoMemo Import` placeholder variants as non-canonical names, alongside `Photo Library`
  - now exposes:
    - `outputBaseName(...)`
    - `timestampFallbackBaseName(...)`
- `RecordCardExportService`
  - export naming priority is now:
    1. real imported original file name
    2. photo-library original file name resolved again from `assetLocalIdentifier`
    3. deterministic capture-date fallback:
       - `IMG_yyyyMMdd_HHmmss`
  - copy suffix behavior remains:
    - `name.jpg`
    - `name (1).jpg`
    - `name (2).jpg`

Why this matters:

- the right-side two-block area is now visually more anchored to the logo/divider cluster instead of drifting rightward
- `PhotoMemo Import` should no longer survive into final exported names when there is either a real original file name or at least a capture date available
- this improves the two most visible quality issues from the latest real-device review without touching renderer architecture, memory logic, or metadata boundaries

Verification for this slice:

- targeted tests passed:
  - `PhotoFileNameResolverTests`
  - `RecordCardBuildServiceTests`
  - `ExternalPhotoIntakeStoreDiagnosticsTests`
  - `ImmersWhiteRendererLayoutTests`
- builds passed:
  - `PhotoMemo`
  - `PhotoMemoiOS`
  - `PhotoMemoShareExtension`
- device install passed:
  - app reinstalled onto iPhone `00008150-000A043136A1401C`
- device launch was not verified automatically:
  - launch request was denied because the phone was locked at the time

## 1.25 Share success feedback is intentionally count-only again

This round does not expand capability.

It simplifies the Share completion language back to the quieter product decision:

- do not surface file names after Share finishes
- do not imply that a shown file name proves save-back succeeded
- keep success feedback focused on how many photos PhotoMemo accepted

What landed:

- `PhotoMemoShareExtensionViewController`
  - success wording remains count-based only
- `PhotoMemoShareExtensionImportResult`
  - no longer carries UI-only imported file name feedback
- `PhotoMemoShareWorkflowSummaryTests`
  - filename-oriented success formatter tests were removed

Why this matters:

- for multi-photo shares, one displayed file name does not help users identify which photo failed later
- the real success criterion is still whether a new generated photo appears in the library beside the original
- Share feedback stays simpler and more Apple-like while the intake and save-back pipeline continues to be debugged separately

Verification for this slice:

- `PhotoMemoTests` passed
- `PhotoMemo` build passed
- `PhotoMemoiOS` build passed
- `PhotoMemoShareExtension` build passed

## 1.24 Share success feedback now surfaces original file names when available

This slice was later superseded by 1.25 after product review simplified Share completion feedback back to count-only wording.

This round keeps the scope narrow and user-visible.

What landed:

- `PhotoMemoShareProcessingFeedbackFormatter`
  - formats share success feedback from counts plus imported original file names
- `PhotoMemoShareExtensionImportResult`
  - now carries `importedFileNames`
- `PhotoMemoShareExtensionIntakeService`
  - now forwards imported original file names into the result object
- `PhotoMemoShareExtensionViewController`
  - now uses the formatter for the success status message

User-facing effect:

- single-photo share success can now say:
  - `已接收《IMG_9558.HEIC》。处理完成后会写回系统相册。`
- partial success can now keep counts while still showing one concrete example file name

Why this matters:

- provenance is no longer only a hidden implementation detail
- users get clearer confirmation that the photo they intended to share was the one PhotoMemo actually received
- this builds toward calmer, more trustworthy share feedback without exposing technical pipeline terms

Verification for this slice:

- `PhotoMemoTests` passed
- `PhotoMemo` build passed
- `PhotoMemoiOS` build passed
- `PhotoMemoShareExtension` build passed

## 1.23 Share and external intake provenance now survives into batch tasks and imported photos

This round extends the prior `PhotoSourceInfo` slice across the intake pipeline instead of stopping at `SelectedPhoto`.

What landed:

- `ExternalPhotoIntakeItem`
  - managed URL
  - original file name
  - source identifier
  - content type identifier
- `ExternalPhotoIntakeRequest`
  - now optionally persists structured intake items
  - now exposes `intakePayloads`
- `BatchTaskIntakePayload`
  - now carries `fileName`
  - `sourceIdentifier`
  - `contentTypeIdentifier`
- `BatchTask`
  - now preserves the same provenance fields
- `BatchProcessingCoordinator`
  - now rebuilds `PhotoSourceInfo` from batch task provenance before import
- `PhotoMemoShareExtensionIntakeService`
  - now persists structured intake items instead of only raw managed URLs
- `PhotoMemoAppRuntime`
  - now enqueues batch tasks from structured intake payloads

Why this matters:

- share-first intake no longer falls back to temporary managed-copy naming in the batch layer
- background status and later imports can keep showing the original shared file name
- batch import can now rehydrate `SelectedPhoto.sourceInfo` from request/task provenance instead of reconstructing everything from the managed file path

What is still not finished:

- provenance is not yet promoted into every user-visible diagnostic surface
- non-share external URL intake still only preserves a lighter provenance set than the ideal long-term model
- canonical provenance is now cleaner across selected photo, request, payload, and task, but the save-back side still only consumes the parts needed today

Verification for this slice:

- `PhotoMemoTests` passed
- `PhotoMemo` build passed
- `PhotoMemoiOS` build passed
- `PhotoMemoShareExtension` build passed

## 1.22 Import source facts now have a lightweight canonical home inside `SelectedPhoto`

This round continues the workflow-consolidation checklist with a small code slice instead of a broad refactor.

What landed:

- `SelectedPhoto` now carries a dedicated `PhotoSourceInfo`
- `PhotoSourceInfo` currently preserves:
  - `originalFileName`
  - `assetLocalIdentifier`
  - `contentTypeIdentifier`
- `PhotoImportService` now writes that source info during imports
- `PhotoImporterView` now forwards the Photos asset identifier when available
- `RecordCardExportService` now prefers the imported original file name when generating export file names

Why this matters:

- original import facts are no longer represented only indirectly through `sourceURL`
- export naming is less dependent on temporary-path details
- future work on asset provenance can build on a real typed surface instead of more ad hoc URL parsing

Scope discipline for this slice:

- no new architecture layer
- no ADR change
- no renderer behavior change beyond export naming input
- no batch/share rewrite

What is still not finished:

- share intake still does not preserve every provenance field end to end
- source provenance is now cleaner, but not yet fully unified across all batch/request models
- `PhotoMetadata` remains the canonical photo-fact model, while `PhotoSourceInfo` is currently the lightweight canonical import-provenance model for selected photos

Verification for this slice:

- `PhotoMemoTests` passed
- `PhotoMemo` build passed
- `PhotoMemoiOS` build passed
- `PhotoMemoShareExtension` build passed

## 1.21 Main workflow consolidation is now explicitly documented as the current development standard

This round does not add features and does not introduce a new architecture layer.

Instead, it absorbs the worthwhile parts of `PhotoMemo v0.4 Main Workflow Consolidation` into project standards:

- PhotoMemo now has one explicit internal workflow:
  - `Import -> Metadata -> Memory -> Renderer -> Export -> Share`
- A new workflow standard document now records:
  - stage ownership
  - accepted boundaries
  - near-term consolidation focus
  - explicit non-goals
- A new workflow checklist now turns that direction into small follow-up items instead of a risky rewrite

The main judgment from this round:

- worth absorbing now:
  - one canonical workflow standard
  - clearer stage ownership
  - keeping renderer as the final visual layer instead of the product center
  - preserving Template/Style vs Renderer separation
  - continuing to tighten metadata-origin consistency
- not worth doing now:
  - broad architecture refactors
  - a new abstract workflow framework
  - codebase-wide structural reorganization
  - forcing all daily execution into Share before the current path is stable

New docs:

- `Docs/MainWorkflowConsolidation.md`
- `Docs/MainWorkflowChecklist.md`

This round keeps the existing ADR set unchanged.

Reason:

- the workflow rule is a clarification and execution standard within already accepted boundaries
- it does not replace the canonical template string model
- it does not alter the Memory Engine boundary
- it does not redefine renderer/export/batch responsibilities

Build verification for this slice is recorded after the compilation step in `HANDOFF.md`.

This round's build verification:

- `PhotoMemo` build passed
- `PhotoMemoiOS` build passed
- `PhotoMemoShareExtension` build passed

Tests were not rerun for this slice because the new work is documentation-only.

## 1.20 Share wake-up, original-filename import preservation, and default renderer routing now align with the current product direction

这一轮没有扩能力，重点是把三个已经影响真实体验的问题收口：

- 主程序从 `PhotosPicker` 导入同名照片时，不再因为临时目录冲突把原始文件名污染成 `(... 1)`
- Share confirmation 成功后，不再只是“写进共享收件箱然后静默关闭”，而是会主动尝试唤起主 App 刷新 intake
- 当前默认风格 `template1` 不再走 `ClassicWhiteRenderer`，而是统一切到更接近目标样图的 `ImmersWhite` 渲染路径

本轮已落地：

- `PhotoImportService`
  - 每次数据导入改成独立 UUID 临时子目录
  - 子目录内保留原始文件名
  - 显式传入的扩展名大小写继续保留
  - `Photo Library` 占位名继续回退到 `PhotoMemo Import.jpg`
- `PhotoMemoDeepLink`
  - 新增 `photomemo://share`
  - `PhotoMemoRootSceneView` 现在会识别这个 deep link 并执行 `runtime.refreshExternalIntakeState()`
- `PhotoMemoShareExtensionViewController`
  - share intake 成功后现在会先尝试唤起主 App，再关闭当前分享页
- 渲染路径统一：
  - 新增 `TemplatePreset.renderLayout`
  - `template1` 现在改走 `ImmersWhite`
  - `RecordCardRenderer` 预览路径与 `RecordCardExportService` 导出尺寸路径已经统一使用这套判定
- `ImmersWhiteRenderer`
  - 底栏背景改成偏暖白 `#F4F4F2`

本轮新增回归保护：

- `PhotoImportServiceTests`
  - 显式文件名保留
  - `Photo Library` 占位名回退
  - 重复导入同名照片时仍保持原始文件名
- `TemplatePresetRenderLayoutTests`
  - 锁定当前默认风格 renderer 路由
- `PhotoMemoDeepLinkTests`
  - 锁定 share deep link 解析

本轮验证：

- 定向测试通过：
  - `PhotoImportServiceTests`
  - `ExternalPhotoIntakeStoreDiagnosticsTests`
  - `TemplatePresetRenderLayoutTests`
  - `PhotoMemoDeepLinkTests`
- 全量测试通过：
  - `PhotoMemoTests`
- 构建通过：
  - `PhotoMemo`
  - `PhotoMemoiOS`
  - `PhotoMemoShareExtension`

这一轮仍需继续真机验证的部分：

1. `photomemo://share` 在系统分享后的真实唤起是否稳定
2. Share 触发后的生成与保存反馈是否已经足够清楚
3. 当前默认成片是否已经明显接近目标 Immers 样图
4. 写回系统相册后的最终文件名是否已经完全摆脱 `Photo Library.*`

## 1.19 Photo Library original-filename preservation is now explicitly wired, and renderer calibration moved one step closer to the sample output

这一轮继续遵守“小切片、先把真实链路修准”的方向，没有扩新能力，只修正真实导出回写行为并对样图视觉再靠近一步。

本轮已落地：

- Photo Library 写回命名补上了明确的原始文件名传递：
  - `PhotoLibraryExportService.saveImageResult(...)` 现在会设置：
    - `PHAssetResourceCreationOptions.originalFilename`
  - 值直接来自当前导出文件名
  - 这意味着如果导出结果已经是：
    - `IMG_1234.jpg`
    - `IMG_1234 (1).jpg`
    - `IMG_1234 (2).jpg`
    写回系统相册时也会尽量沿用同样的文件名语义
- 新增了一个小而明确的回归保护：
  - `usesExportedFileNameAsPhotoLibraryOriginalFilename()`
  - 这条测试锁住了：
    - 正常文件名
    - 带复制后缀文件名
    - 空白文件名回退
- `ClassicWhiteRenderer` 又做了一轮只影响展示细节的轻微参数回收：
  - 白栏背景改成更接近样图的暖灰白
  - 主文字、参数文字、次级文字层次更清楚
  - 分隔线颜色由透明黑改成显式浅灰
  - 分隔线宽度从 `1` 调整到 `2`
  - 中部徽标与右侧文案的几何节奏继续向样图贴近

本轮验证：

- 定向测试通过：
  - `PhotoMemoTests/RecordCardBuildServiceTests`
- 构建通过：
  - `PhotoMemo`
  - `PhotoMemoiOS`
  - `PhotoMemoShareExtension`

这一轮仍保留的人工验证债务：

1. 需要真机再次验证写回系统相册后的真实命名是否已经不再退化成 `Photo Library.*`
2. 白栏底色、分隔线粗细与中部几何关系仍要继续以你给的成品样图为准
3. 这一轮没有继续动更大的排版结构，只做了安全的小幅视觉回收

## 1.18 Product convergence: Main App now matches the five-layer direction more closely, Share wording is quieter, and Profile/Style boundaries are tighter

这一轮继续严格按 `North Star` 做减法，没有增加新功能，重点是把可见结构、用户语言和长期资料边界再往产品模型上收。

本轮已落地：

- Main App 顶层继续收口：
  - iPhone 主界面现在更接近最终目标：
    - `我的记录`
    - `默认风格`
    - `输出设置`
    - `设置`
    - `关于`
  - `预览` 不再在 iPhone 顶层单独占一个主块
  - 预览被下沉回 `默认风格` 内部，作为校准内容的一部分
  - macOS 仍保留右侧 detail 预览，用作单张真实校准面

- 用户可见术语继续去技术化：
  - `识别数据` 改为 `照片信息`
  - `智能数据` 改为 `记忆信息`
  - 多处 `时间点` 改为 `记忆日期`
  - Share 页 `当前设置` 改为 `这次会如何处理`
  - Share 页 `当前风格` 改为 `默认风格`

- Share Extension 又安静了一层：
  - 确认页继续保持单页
  - 现在更明确地只说：
    - 分享了几张
    - 默认风格
    - 结果去向
    - 接下来会发生什么
  - 单张预览说明也更直接：
    - `将按当前默认风格处理这张照片`
  - 失败提示不再让用户理解“当前风格”这类过于编辑态的概念

- `Personal Profile` 成为长期信息来源又前进了一步：
  - `PersonalProfileStore` 现在可以单独更新：
    - 默认风格
    - 默认保存位置
  - 主界面切换默认风格时，会同步回写 `Personal Profile`
  - 主界面切换保存相册时，也会同步回写 `Personal Profile`
  - 这意味着 Share 和 Main App 在默认风格/默认输出上的共同来源更加明确

- `Style` 更接近 presentation-only：
  - 保存当前风格时，不再先把当前相册和记忆日期当作风格持久化来源
  - 应用某个风格快照时，也不再顺手改掉当前相册和当前记忆日期
  - 现阶段风格恢复的核心重新聚焦到：
    - 模板
    - 标识
    - 说明写入相关设置

本轮验证：

- 定向测试通过：
  - `PersonalProfileStoreTests`
  - `PhotoMemoShareWorkflowSummaryTests`
- 全量测试通过：
  - `PhotoMemoTests`
- 这一轮我明确拿到了 `PhotoMemoTests` 的 `TEST SUCCEEDED`
- `PhotoMemo` / `PhotoMemoiOS` / `PhotoMemoShareExtension`
  - 构建命令已实际执行
  - 当前会话未保留三个 scheme 各自完整、干净的成功尾行
  - 但本轮涉及的主 app / share 文件已经被测试编译链真实编译覆盖

这一轮仍保留的产品债务：

1. `默认风格` 虽然已经更像设置层，但 `进一步调整` 里仍有不少低频项，后续依旧值得继续下沉。
2. First Run 目前是更短的 5 步版本，符合“更安静”的方向，但与最新 North Star 的显式完成页仍有一点差异，需要继续做产品判断。
3. Share confirmation page 现在更看得懂，但距离真正几乎无感的 `Share -> Generate -> Save -> Done` 体验还有最后一段真机手感打磨。

## 1.17 Alpha convergence cleanup: Main App lost another layer of dashboard feeling, and First Run became shorter

这一轮继续遵守 `complexity must go down every sprint` 这条规则，没有扩能力，只继续做减法。

本轮已落地：

- `Main App` 又收掉了一层重复表达：
  - macOS 右侧详情区不再重复显示一份 `默认风格`
  - 右侧重新回到更单纯的预览校准面
- iPhone 主界面继续收短：
  - 顶层不再默认并列 `关于`
  - `设置` 只在权限还没准备好时才出现
  - 默认主链现在更接近：
    - 我的记录
    - 默认风格
    - 输出
    - 预览
- `默认风格` 默认展开层继续减法：
  - 保留风格位切换和基础风格信息
  - 时间点 / 个性化区域 / 补充信息 / Logo 标识 被后置到 `进一步调整`
  - 这样首次进入时不会立刻看到整页低频项
- `FirstRunWizardView` 继续缩短：
  - 不再单独保留“完成页”
  - 最后一步直接完成设置并进入主界面
  - 当前首次流程收成：
    - 欢迎
    - 记录身份
    - 宝宝昵称
    - 出生日期
    - 保存位置

这一轮的产品含义：

- Main App 更接近真正的配置中心，而不是一层层展开的调试台
- First Run 更像一次性的系统设置，而不是“小向导 + 总结页”
- 低频项目还在，但默认不再抢占主流程注意力

这一轮仍保留的产品债务：

1. `默认风格` 内部依然承载了较多低频项，只是先后置，还没有完全迁到真正的二级设置结构。
2. `设置 / 关于` 还没有形成独立而稳定的入口层级；当前只是先从首页主舞台继续降权。
3. Share Extension 仍然不是最终的“几乎无感”生成保存体验；这轮没有继续动 Share 主链。

本轮验证：

- 构建与测试正在执行：
  - `PhotoMemo`
  - `PhotoMemoiOS`
  - `PhotoMemoShareExtension`
  - `PhotoMemoTests`
- 最终结果会同步记录到 `HANDOFF.md`

## 1.16 Alpha product refinement: Main App is closer to a configuration center, Share is closer to a single-page confirmation flow

这一轮没有继续扩能力，而是按 `PhotoMemo is a natural extension of Apple Photos` 这条方向，把主 App 和 Share Extension 再往“更少配置、更少技术词、更接近系统产品”推进了一步。

本轮已落地：

- Main App 开始更明显地从“工作台”收成“配置中心”：
  - `MainView` 现在接入了 `PersonalProfileStore`
  - 主界面新增并提前了 `我的记录`
  - `我的记录` 直接承接长期资料：
    - 记录身份
    - 宝宝昵称
    - 出生日期
    - 默认风格摘要
    - 默认保存位置摘要
- iPhone 主界面不再强调原先的 `预览 / 编辑` 双模式切换，而是改成单页配置流：
  - 我的记录
  - 默认风格
  - 照片
  - 时间锚点
  - 个性化区域
  - 补充信息
  - Logo 标识
  - 输出
  - 预览
- 默认风格区域进一步去工具化：
  - 头部直接显示当前生效模块
  - 展开后显示更像设置列表的模块项
  - 用户可见名称已从 `配置 1/2/3` 改为 `模块 1/2/3`
  - 操作仍保留切换、重命名、保存当前风格、恢复默认，但提示语更像用户语言
- 旧的“当前配置”式摘要继续降权：
  - `workspaceConfigurationSummary` 已收成更轻的说明文案
  - 风格保存和恢复提示不再重复强调一整串内部配置域

首次启动体验也更贴近新的产品模型：

- `FirstRunWizardView` 已从旧的 5 步配置导向，收成更接近长期使用模型的流程：
  - 欢迎
  - 记录身份
  - 宝宝昵称
  - 出生日期
  - 默认时间锚点说明
  - 保存位置
  - 完成
- 首次启动不再要求用户在一开始就理解多个风格位
- 默认时间锚点页面明确告诉用户：
  - 默认使用出生时间
  - 年龄会自动计算

Share Extension 继续从“技术交接面”往“确认一下就开始”的单页靠拢：

- `PhotoMemoShareExtensionViewController` 现在会尝试显示第一张照片预览
- 多张分享时只显示第一张，并提示：
  - 其余照片会使用相同风格处理
- 确认页继续去技术词：
  - `当前设置`
  - `开始生成`
  - `处理完成后会写回系统相册`
- `PhotoMemoShareWorkflowSummary` 的对外语言也更自然了：
  - `styleTitle` 替代旧的 `configurationTitle`
  - 输出去向统一成：
    - `系统相册`
    - `PhotoMemo 相册`
    - `“家庭相册”相册`
    - `当前选定相册`

兼容层这一轮也补了一步：

- `PersonalProfileStore` 新增了 `updateProfile(_:)`
- 这让主界面中的 `我的记录` 能直接更新长期资料，同时继续复用现有兼容桥接：
  - birthday anchor 同步
  - 默认风格位同步
  - 默认相册同步
  - 旧设置桥接保持不变

本轮验证：

- 已通过：
  - `PhotoMemo`
  - `PhotoMemoiOS`
  - `PhotoMemoShareExtension`
  - `PhotoMemoTests`
- 新旧测试继续通过，包含：
  - `PhotoMemoShareWorkflowSummaryTests`
  - `PersonalProfileStoreTests`
  - metadata / memory / export / batch / editor projection 既有测试集合

当前还留着的产品债务：

1. Main App 还没有完全收成最终理想形态的 `我的记录 / 默认风格 / 输出设置 / 设置 / 关于` 五层结构。
2. `时间锚点 / 个性化区域 / 补充信息 / Logo 标识` 仍然在首页主舞台上，虽然层级已变轻，但还没有真正下沉成二级配置。
3. Share confirmation page 已经更容易看懂，但还没有做到真正的“几乎感觉不到存在”的自动生成保存体验。
4. `MainView+PersonalProfile.swift` 目前通过编译条件避开 Share target，后续如果继续收 target 边界，最好再回头检查一次同步组覆盖范围。

下一轮最值得继续的三件事：

1. 继续给 Main App 做减法，把 `输出设置 / 设置 / 关于` 真正梳理成稳定层级。
2. 把 Share confirmation page 继续向 `生成 -> 保存 -> 完成` 的更短主链推进。
3. 做一轮真机 UX 回归，重点看：
   - 首次启动是否足够像系统设置
   - iPhone 主界面是否仍有“像工具”的感觉
   - 分享确认页是否已经足够让第一次使用的人敢点 `开始生成`

## 1.15 Share intake diagnostics are now wired through the full confirmation pipeline

PhotoMemo 的 Share Extension 这一轮没有改工作流本身，只强化了 intake 阶段的可观测性，目标是把“照片没有成功交给 PhotoMemo”从笼统报错升级成可定位的阶段性诊断。

本轮已落地：

- 新增共享诊断基础：
  - `PhotoMemoShareIntakeFailureStage`
  - `PhotoMemoShareIntakeNSErrorSummary`
  - `PhotoMemoShareIntakeFailureContext`
  - `PhotoMemoShareIntakeOperationSeed`
- `ExternalPhotoIntakeStore` 现在保留详细 copy / persist / serialization 失败上下文
- `PhotoMemoShareExtensionImportResult` 现在会携带：
  - `itemProviderCount`
  - `supportedProviderCount`
  - `failureStage`
  - `failureContext`
- `PhotoMemoShareExtensionIntakeService` 现在会对以下步骤逐一打点：
  - extension 收到多少个 item providers
  - 支持的 provider 数量
  - 选中的 UTType 与 provider 注册类型
  - `loadFileRepresentation` 开始 / 返回 URL / 失败
  - `loadItem` fallback 开始 / 返回 URL 或 Data / 失败
  - temporary copy 结果
  - shared container 目标路径
  - request 持久化结果
  - final import result 摘要
- `PhotoMemoShareExtensionViewController` 失败态现在会追加简短诊断：
  - 失败阶段
  - `NSError domain / code`

本轮验证：

- 新增 `PhotoMemoShareIntakeDiagnosticsTests` 通过
- 新增 `ExternalPhotoIntakeStoreDiagnosticsTests` 通过
- `PhotoMemoTests` 定向测试通过
- `PhotoMemoiOS` build 通过
  - 该次编译已包含 `PhotoMemoShareExtension` target

这代表什么：

- 从你下一次真机重试开始，如果 share 再失败，我们应该能立刻知道它卡在：
  - `load`
  - `copy`
  - `persist`
  - `serialization`
  - `completion`
- 并且能同时拿到对应的底层 `NSError.localizedDescription / domain / code / underlyingError`

还没完成的部分：

- 还没有基于新的诊断结果去真正修复 intake 根因
- 还需要你下一次在真机上重试一次，确认失败页是否已经从纯泛化文案升级成带阶段的错误
- 如果新的失败截图出现，我们就可以直接按阶段下刀，不需要再盲查整个 Share 流程

## 1.14 默认个性化文案与导出命名规则已收口一轮

PhotoMemo 在这一轮继续沿着 `Personal Profile + 默认风格` 的方向，把模板 1 的默认语言再向真实家庭记录语境推进了一步。

这一轮的目标仍然是：

- 不改渲染结构
- 不改导出流程
- 不改 Share 工作流
- 只收口默认模板语义、导出命名和变量注入

本轮已经落地：

- 新增 `relationship_label` 元数据键，用于把首次引导里的记录者身份注入运行时上下文
- 模板 1 左上默认语义改成：
  - `{{relationship_label}}手持{{model}}记录`
- 模板 1 右下默认语义改成：
  - `{{anchor_title}}今天{{anchor_age_text}}啦`
- `记录于{{capture_date_display}}` 默认文案改成：
  - `拍摄于{{capture_date_display}}`
- 模板归一化时会兼容迁移旧默认内容，避免已有模板直接失真
- 导出文件名现在默认沿用原图名称：
  - `IMG_1234.jpg`
  - `IMG_1234 (1).jpg`
  - `IMG_1234 (2).jpg`

本轮代码上的关键补充：

- `RecordCardBuildService` 现在会读取共享 `PersonalProfile`，把记录者称呼注入 `MetadataContext`
- `TemplateVariable` 新增公开变量：
  - `记录者称呼`
- 时间点标题的公开展示名进一步收口为：
  - `主角称呼`

本轮新增或补强验证：

- `RecordCardBuildServiceTests` 通过
- `EditorProjectionEngineTests` 通过
- `PhotoMemo` macOS build 通过
- `PhotoMemoiOS` build 通过
  - 该次编译已包含 iOS App、Share Extension、Widget Extension 依赖图

本轮仍需继续人工核查：

- 自定义区域中 EXIF 参数摘要模块的重新插入与删除边界
- 个别文本异常拼接，例如：
  - `途途1岁24天）〕啦`
- 右下区域在真实中文输入与多模块混排下的最终显示稳定性
- 你后续准备发送的分享失败提示图，还没有进入本轮分析

额外说明：

- 本轮尝试过独立 `PhotoMemoShareExtension` scheme 编译，但该 scheme 在当前工程里仍会拉起完整 iOS 依赖图，且命令被人为中断，没有保留单独的成功结论
- 但 `PhotoMemoiOS` 的完整成功编译已经覆盖到 Share Extension target 的真实编译路径，所以当前可以把 iOS/Share 视为可编译状态
- 你提供的样图里：
  - `/Users/rui/Downloads/IMG_5667.jpg`
  - `/Users/rui/Downloads/IMG_5668.JPEG`
  已可用于继续对齐文案观感
  - `/Users/rui/Downloads/IMG_9565.HEIC`
  本轮读取时本地未找到文件

## 1.13 First Run Wizard foundation landed

PhotoMemo now has its first implemented `Personal Profile + First Run` product slice in code.

This round stays compatibility-first:

- no renderer behavior change
- no export content change
- no template data-model redesign
- no share workflow redesign
- existing `SettingsService` and `UserDefaults` keys remain readable

What landed in code:

- additive `PersonalProfile` model
- additive `PersonalProfileStore`
- one-time `FirstRunWizardView`
- root-scene gating so first launch enters the setup flow before `MainView`
- compatibility backfill from existing birthday anchor / selected album / active style slot
- compatibility write-back into the current settings pipeline when first run completes

Current wizard shape:

1. who is recording
2. baby nickname
3. birthday
4. default style
5. save destination

What is user-visible now:

- first launch is no longer a raw settings surface
- users get a simpler setup path with human language
- `时间锚点` is not exposed in first run
- default style is presented as `宝宝成长（推荐）`
- save destination can now distinguish:
  - `系统相册`
  - `PhotoMemo 相册`
- the onboarding copy and hierarchy were further tightened toward a more Apple-like first-device setup feel:
  - welcome copy now emphasizes `只需要花 1 分钟完成设置`
  - step labels are simplified to `1 / 5 ... 5 / 5`
  - the setup summary is quieter and less dashboard-like

Important compatibility note:

- `系统相册` default save is now wired through runtime save behavior and summary wording
- `PhotoMemo 相册` remains the automatic-album default
- this round does not yet add a post-onboarding `Personal Profile` editing page
- this round does not yet migrate the Main App information architecture to `Profile / Styles / Settings / About`

Files added in this round:

- `Source/PhotoMemo/PhotoMemo/Models/PersonalProfile.swift`
- `Source/PhotoMemo/PhotoMemo/Services/PersonalProfileStore.swift`
- `Source/PhotoMemo/PhotoMemo/Views/FirstRun/FirstRunWizardView.swift`
- `Tests/PhotoMemoTests/MetadataTests/PersonalProfileStoreTests.swift`

Files updated in this round:

- `Source/PhotoMemo/PhotoMemo/App/PhotoMemoRootSceneView.swift`
- `Source/PhotoMemo/PhotoMemo/App/BatchConfigurationSnapshotProvider.swift`
- `Source/PhotoMemo/PhotoMemo/App/PhotoMemoShareWorkflowSummary.swift`
- `Source/PhotoMemo/PhotoMemo/Services/PhotoLibraryExportService.swift`
- `Source/PhotoMemo/PhotoMemo/Views/Main/MainView+DerivedState.swift`
- `Source/PhotoMemo/PhotoMemo/Views/Main/MainView+ExportActions.swift`
- `Source/PhotoMemo/PhotoMemo/Views/Main/MainView+MemoryProgress.swift`
- `Source/PhotoMemo/PhotoMemo/Views/Main/MainView+OutputSection.swift`
- `Tests/PhotoMemoTests/VariableTests/PhotoMemoShareWorkflowSummaryTests.swift`

Verification for this round:

- `PhotoMemoTests` passed
- focused `PersonalProfileStoreTests` and `PhotoMemoShareWorkflowSummaryTests` passed after the final target-boundary fix
- `PhotoMemo` build passed
- `PhotoMemoiOS` build passed
- `PhotoMemoShareExtension` build passed

Still not manually verified:

- the feel of the new first-run flow on real iPhone hardware
- whether the five-step flow is short enough for a genuine first-time user
- whether `系统相册` vs `PhotoMemo 相册` wording feels natural inside the existing Main App output panel
- whether users miss a direct post-onboarding place to edit Personal Profile

## 1.12 v1.0 product model foundation defined

PhotoMemo now has a formal product model document:

- `Docs/ProductModel.md`

This round is documentation-only.

It does not change architecture, renderer behavior, export behavior, share behavior, or persistence behavior in code.

What is newly defined:

- Personal Profile is now the owner of:
  - relationship
  - baby nickname
  - birthday
  - default album
  - default style
- Style is now the owner of:
  - layout
  - variables
  - visual arrangement
  - renderer-facing behavior
- Workflow is now the owner of:
  - share execution
  - generate/save flow
  - runtime progress and result state

What this changes at the product level:

- the Main App is no longer best understood as a general configuration dashboard
- it is becoming a workflow-preparation app
- the Share Extension is no longer just a technical intake surface
- it is the future primary execution surface
- First Run is now the preferred place for identity and default-output setup

Main App information architecture target is now:

- Personal Profile
- Styles
- Settings
- About

This round also aligns the repository slogan around:

- Configure once. Remember forever.
- 一次设定，永久记录。

Docs added or updated in this round:

- `Docs/ProductModel.md`
- `Docs/ProductDirection.md`
- `Docs/ProductBacklog.md`
- `Docs/CURRENT_STATUS.md`
- `HANDOFF.md`
- `README.md`

Recommended next implementation sequence:

1. add Personal Profile as additive data
2. backfill from current settings
3. introduce one-time First Run
4. move visible IA toward Profile / Styles / Settings / About
5. make Share read Profile + default Style automatically

ADR status:

- no ADR update in this round
- reason: product model was defined, but no implemented architecture boundary changed yet

## 1.11 Alpha 0.8 product simplification slice landed

PhotoMemo has now shipped the first code-level UI reduction slice that follows `Docs/ProductAudit.md`.

This round does not change architecture, renderer behavior, metadata logic, batch semantics, or export behavior.

What changed in the Main App:

- removed several dismissible guide cards from the default editing flow
- reduced explanatory copy in:
  - custom-region editing
  - supplemental content
  - output
  - anchor editing
  - permissions
- reduced the anchor list by removing the duplicated `设为当前` action
- removed the compact/header hero pills from the main editor path
- changed more visible language from:
  - configuration/workspace/template
  - toward:
  - style / current style / default style

What changed in iPhone/supporting UI:

- background status now keeps only:
  - current task
  - retry failed
  - latest failure
- the rest of the background dashboard-style detail is no longer shown in the default sheet

What changed in Share wording:

- `当前配置` now reads as `当前风格`
- confirmation, processing, retry, and follow-up wording are less technical

Docs added or updated in this round:

- `Docs/ProductScore.md`
- `Docs/ProductDirection.md`
- `Docs/ProductBacklog.md`
- `Docs/Alpha/BugList.md`
- `Docs/Alpha/UXNotes.md`

Verification for this round:

- `PhotoMemo` build passed
- `PhotoMemoiOS` build passed
- `PhotoMemoShareExtension` build passed
- `PhotoMemoTests` passed

Still not manually verified:

- real-device reaction to the lighter Main App with fewer guide cards
- whether first-time users miss any removed helper copy
- whether the reduced background-status sheet still feels sufficient in failure scenarios
- whether `当前风格` reads naturally enough in the real share sheet

## 1.10 Product audit completed

PhotoMemo now has its first repository-level UI product audit:

- `Docs/ProductAudit.md`

This round is documentation-only.

It does not modify architecture, renderer behavior, metadata logic, or workflow code.

What this audit adds:

- a page-by-page review of every current visible product surface
- a UI-element audit asking:
  - does the user need this
  - can it be removed
  - can it become automatic
  - can it move into settings
- a stronger product principle now written into `Docs/ProductDirection.md`:
  - The best PhotoMemo experience is the one users barely notice.

Highest-confidence conclusions from the audit:

- the Main App still explains itself too much
- the Share Extension should keep shrinking toward near-invisible execution
- help, troubleshooting, and low-frequency configuration actions should continue moving away from the main daily surface
- background status should keep losing prominence

## 1.8 Zero-Friction share baseline landed

PhotoMemo now has an explicit Zero-Friction share workflow baseline in both docs and the first runtime surface.

This round adds:

- `Docs/ShareZeroFrictionWorkflow.md`
- `Source/PhotoMemo/PhotoMemo/App/PhotoMemoShareWorkflowSummary.swift`
- `Tests/PhotoMemoTests/VariableTests/PhotoMemoShareWorkflowSummaryTests.swift`

What changed in product direction:

- default share no longer assumes in-flow configuration
- the Main App stays the configuration center
- the Share Extension now explicitly prefers:
  - use current configuration automatically
  - continue processing
  - write back to Photos
- advanced settings are now documented as future-optional rather than part of the default path

What changed in the current Share Extension slice:

- the extension no longer speaks like a technical handoff screen first
- it now shows a calmer automatic-processing surface
- it passively summarizes:
  - current configuration
  - current time point usage
  - output mode
- success wording now confirms receipt and continued automatic processing instead of only saying the photo entered an inbox

What intentionally did not change:

- intake persistence architecture
- render behavior
- export behavior
- batch semantics
- save-back pipeline ownership
- share preview / confirmation flow

Verification for this round:

- `PhotoMemoTests` passed
- `PhotoMemoShareExtension` build passed
- `PhotoMemoiOS` build passed
- `PhotoMemo` build passed

Still not manually verified:

- real-device share-sheet appearance on smaller iPhones
- whether the new share surface feels appropriately brief before auto-closing
- real-user understanding of the new wording in first-time use

## 1.9 Share Alpha-01 single-page confirmation landed

PhotoMemo has now taken the first Alpha usability slice on the Share Extension itself.

This round keeps the existing intake-backed architecture, but changes the extension from an automatic handoff surface into a clearer single-page confirmation surface.

What changed in this round:

- the Share Extension no longer starts immediately on open
- it now shows:
  - shared photo count
  - current configuration name
  - output destination summary
- the primary action is now an explicit confirmation button instead of an invisible auto-continue step
- success wording no longer says only “joined the inbox”
- failure states now provide retry-oriented, user-facing suggestions

Files touched in the core slice:

- `Source/PhotoMemo/PhotoMemo/iOS/ShareExtension/PhotoMemoShareExtensionViewController.swift`
- `Source/PhotoMemo/PhotoMemo/iOS/ShareExtension/PhotoMemoShareExtensionIntakeService.swift`
- `Source/PhotoMemo/PhotoMemo/iOS/ShareExtension/PhotoMemoShareExtensionImportResult.swift`

What intentionally did not change:

- no share preview yet
- no in-extension generate/save loop yet
- no batch-share expansion
- no smart configuration selection
- no multi-page wizard

Verification for this round:

- `PhotoMemoTests` passed
- `PhotoMemoShareExtension` build passed
- `PhotoMemoiOS` build passed
- `PhotoMemo` build passed

Not yet verified:

- real-device share-sheet layout and tap confidence
- whether the confirmation wording feels short enough in actual Photos sharing
- whether users still expect immediate completion instead of “continue processing”

## 1.7 Alpha 0.7 validation mode started

PhotoMemo has now entered a real product-validation phase.

This stage is intentionally different from the earlier architecture and feature-building rounds.

The current priority is:

- run the real product in normal life
- find friction through repeated use
- fix one issue at a time
- keep `main` usable

This round adds:

- `Docs/Alpha/Alpha01.md`
- `Docs/Alpha/BugList.md`
- `Docs/Alpha/UXNotes.md`
- `Docs/Alpha/KnownIssues.md`

The current milestone language should now prefer:

- `Alpha 0.7`

over open-ended sprint naming for this validation stage.

This round is documentation-only.

No runtime implementation changed.

## 1.5 Product direction alignment documented

PhotoMemo now has an explicit share-first product direction baseline in documentation.

This round adds:

- `Docs/ProductDirection.md`
- `Docs/UX_PRINCIPLES.md`

The direction is now stated clearly:

- PhotoMemo is a memory generator built around Apple Photos, not a photo editor
- the Share Extension is the primary workflow
- the Main App is a configuration center
- future UX decisions should reduce reading, scrolling, and duplicate information

This round is documentation-only.

No architecture, renderer, metadata, or workflow implementation changed in code.

## 1.6 Product polishing docs established

PhotoMemo now has the first product-polishing documentation layer beyond high-level direction.

This round adds:

- `Docs/ShareExtensionReview.md`
- `Docs/DesignSystem.md`
- `Docs/ProductBacklog.md`

What this round establishes:

- the Share Extension is now being reviewed as the real primary product surface
- the repository now has a concrete UI consistency baseline
- future ideas now have a backlog structure:
  - Now
  - Next
  - Later
  - Icebox

This round is documentation-only.

No runtime implementation changed.

## 1.4 v0.7.2 Alpha usability iteration started

PhotoMemo has now begun the first real Alpha usability pass.

This round intentionally avoids new features and architecture work.

The focus is simplifying the main workspace so users think about photos first and configuration second.

What changed in this round:

- photo selection was moved nearer to the top of the workspace flow
- `PhotoImporterView` now prefers Apple Photos picking first and keeps file import as a secondary path
- the compact preview flow no longer renders the workspace configuration panel twice
- the empty preview state inside scrolling containers no longer stretches into unnecessary blank space
- workspace configuration now behaves more like a direct module list:
  - tap to switch immediately
  - inline edit menu for rename / save / restore
  - no separate “current configuration” summary card
- the template section now speaks in more user-facing language and emphasizes direct editing instead of internal preset concepts
- the iOS composer now gives CJK input methods a more native path during text composition
- anchor management and editing affordances are more explicit
- manual export filename collisions now resolve with numbered suffixes instead of overwriting

Verification for this round:

- `PhotoMemo` build passed
- `PhotoMemoiOS` build passed
- `PhotoMemoShareExtension` build passed

Still waiting for hands-on validation:

- real-device `PhotosPicker` import feel
- Chinese IME behavior in longer composer sessions
- iPhone anchor editing flow

## 1.3 v0.7.1 Fixture-backed export read-back landed

PhotoMemo now has its first committed synthetic fixture binaries and real export read-back regression coverage.

This round added:

- `Tests/Fixtures/GenerateSyntheticFixtures.swift`
- `Tests/Fixtures/Synthetic/`
- `Tests/PhotoMemoTests/Support/SyntheticFixtureLibrary.swift`
- `Tests/PhotoMemoTests/ExportTests/FixtureExportReadbackTests.swift`
- `Tests/PhotoMemoTests/BatchTests/BatchFixtureCoverageTests.swift`

Coverage added in this round:

- JPEG fixture export -> read-back verification
- HEIC fixture import plus normalized export verification
- metadata-family assertions for:
  - EXIF
  - TIFF
  - GPS
  - orientation
  - dimensions
  - description fields
- batch fixture coverage for:
  - single-item enqueue
  - multi-item enqueue
  - cancellation cleanup
  - retry eligibility

One correctness fix also landed:

- `RecordCardExportService` now writes output dimension metadata using the actual rendered `CGImage` size instead of the intended render target size
- this removes a real off-by-one risk between top-level pixel dimensions and EXIF pixel dimensions

Verification for this round:

- `PhotoMemoTests` passed with 19 tests
- `PhotoMemo` build passed
- `PhotoMemoiOS` build passed
- `PhotoMemoShareExtension` build passed

## 1.2 v0.7.0 Memory Engine foundation landed

PhotoMemo has now entered its first explicitly versioned product-evolution release.

This round introduces the initial Memory Engine domain boundary without changing renderer, export, batch, or UI behavior.

New foundation types:

- `MemoryContext`
- `MemoryCalculationResult`
- `MemoryVariableProvider`

New public variables:

- `days_since`
- `years_since`
- `months_since`
- `weeks_since`
- `baby_age`
- `memory_summary` now also flows through the Memory Engine boundary

Key behavior choices:

- metadata capture time remains the source of truth
- existing anchor summaries remain preserved when already available
- future-relative anchors never produce negative `*_since` values
- baby-age formatting avoids awkward `0岁...` wording

Docs added:

- `Docs/MemoryEngine.md`
- `Docs/ADR/ADR-006-MemoryEngineFoundation.md`

Verification for this round:

- `PhotoMemoTests` passed, including the dedicated `MemoryEngineTests` suite
- `PhotoMemo` build passed
- `PhotoMemoiOS` build passed
- `PhotoMemoShareExtension` build passed

Process note:

- `v0.7.0` starts the repository's forward-looking version rhythm
- older `Sprint-*` notes remain as historical engineering records, but future release-facing summaries should prefer semantic version labels

## 1.1 Regression verification foundation landed

Sprint-009 moves PhotoMemo into the first real engineering-confidence stage.

This round added verification foundation docs:

- `Docs/FixtureSpecification.md`
- `Docs/RegressionMatrix.md`
- `Docs/AcceptanceCriteria.md`
- `Docs/CIReadiness.md`

This round also added repository-level test/fixture structure:

- `Tests/Fixtures/`
- `Tests/PhotoMemoTests/`

Important current decisions:

- no copyrighted real photos are committed yet
- fixture filenames and metadata requirements are now reserved through:
  - `Tests/Fixtures/FixtureManifest.json`
- the first automated layer is intentionally pure logic smoke coverage, not snapshot-heavy or Photos-integration-heavy testing

`PhotoMemoTests` now exists as a real Xcode target and shared scheme.

Current smoke coverage includes:

- EXIF timezone parsing
- GPS sign normalization
- metadata-derived aspect ratio / megapixels / location display
- `MetadataContext` capture-timezone date-field generation
- `TemplateVariableEngine` token replacement
- `RecordCardBuildService` description-writing switch behavior

Build and test verification for this round:

- `PhotoMemoTests` test passed
- `PhotoMemo` build passed
- `PhotoMemoiOS` build passed
- `PhotoMemoShareExtension` build passed

What still remains intentionally deferred:

- committed real fixture binaries
- renderer snapshot coverage
- export-file binary diff tests
- Photo Library integration automation
- batch end-to-end fixture execution

## 1.0 Output integrity verification sprint landed

Sprint-008 focused on verification and product reliability, not feature expansion.

This round added six dedicated docs:

- `Docs/ExportMetadataAudit.md`
- `Docs/ExportReadbackVerification.md`
- `Docs/JPEG_HEIC_Compatibility.md`
- `Docs/BatchExportReliability.md`
- `Docs/LivePhotoAssessment.md`
- `Docs/OutputIntegrityReport.md`

What this round clarified:

- PhotoMemo's export path is currently a pass-through-plus-patching metadata strategy:
  - it starts from original `sourceProperties`
  - rewrites final dimensions and orientation
  - conditionally writes export description fields
- output integrity is strongest today for:
  - still-photo JPEG-first workflows
  - deterministic batch export
  - dimension/orientation normalization
- output integrity is not yet fully guaranteed for:
  - ICC / color-profile preservation
  - explicit JPEG / HEIC parity
  - Live Photo paired-resource support
  - complete metadata round-trip validation for description/comment fields

One correctness fix also landed in this sprint:

- disabling `shouldWritePhotoDescription` now truly stops PhotoMemo from writing export description metadata
- the corresponding UI preview text now matches that behavior

Build verification for this round:

- `PhotoMemo` build passed
- `PhotoMemoiOS` build passed
- `PhotoMemoShareExtension` build passed

Architecture note:

- no architecture redesign was introduced
- no renderer redesign was introduced
- no workspace/editor migration was performed

## 0.8 Metadata audit and roadmap docs were added

The latest non-code sprint produced a dedicated metadata review set:

- `Docs/MetadataPipelineReview.md`
- `Docs/VariableEngineRoadmap.md`
- `Docs/MetadataTechnicalDebt.md`
- `Docs/MetadataRoadmap.md`

What this round clarified:

- PhotoMemo already has one real metadata-read path:
  - `PhotoMetadataReader -> PhotoMetadata -> MetadataContext / CardVariableProvider -> TemplateVariableEngine -> Renderer / Export`
- the iOS share extension does not create a second EXIF pipeline:
  - it persists files and configuration only
  - real metadata reading still begins in the main app import path
- the biggest current metadata gaps are:
  - location enrichment is modeled but not populated
  - variable catalog coverage lags behind runtime context coverage
  - time/GPS normalization and metadata regression coverage should be hardened before expanding variable surface

Recommended next metadata sprint from these docs:

- `Sprint-007: Metadata Normalization And Catalog Alignment`

## 0.9 Metadata normalization and catalog alignment landed

Sprint-007 is now implemented without changing the architecture baseline.

Core results:

- `PhotoMetadata` now acts as the metadata normalization center
- canonical metadata inventory now exists in code:
  - `PhotoMetadata.canonicalInventory`
- canonical runtime keys now exist in code:
  - `MetadataContext.Key`
- `PhotoMetadataReader` now normalizes:
  - timezone suffix extraction
  - GPS sign handling
  - altitude reference
- public variable catalog now exposes the previously missing high-value metadata fields:
  - `location`
  - `location_display`
  - `latitude`
  - `longitude`
  - `altitude`
  - `country`
  - `province`
  - `city`
  - `district`
  - `weekday`
  - `capture_date_short`
  - `capture_time_short`
  - `capture_timezone`
  - `orientation`
  - `aspect_ratio`
  - `megapixels`
  - `lens_brand`
  - `memory_summary`

This round also added three new metadata docs:

- `Docs/MetadataInventory.md`
- `Docs/VariableCatalogAlignment.md`
- `Docs/MetadataNormalizationPlan.md`

Build verification for this round:

- `PhotoMemo` build passed
- `PhotoMemoiOS` build passed
- `PhotoMemoShareExtension` build passed

Architecture note:

- no ADR update was required
- no new architectural layer was introduced

## What Was Completed In This Round

### 0. Project-local Swift/iOS skills were added for the next PhotoMemo phase

The project-local skills folder now also includes:

- `activitykit`
- `background-processing`
- `ios-simulator`
- `photokit`
- `swift-testing`
- `swiftui-patterns`

Why these were added:

- `photokit` directly supports photo-library permission, picker, and save-back work
- `background-processing` matches the share-intake and batch/export direction
- `activitykit` prepares for iPhone progress surfaces like Dynamic Island / Lock Screen
- `swiftui-patterns` helps keep `MainView` and the future iPhone UI aligned with modern state/composition rules
- `swift-testing` gives a better path for new Swift-native tests
- `ios-simulator` helps future iPhone regression, privacy, push, and location validation

These were installed into:

- `Source control path`: `/Users/rui/Desktop/PhotoMemo/.codex/skills`

Important current-session note:

- the skills are already present in the project and readable on disk
- but an already-open Codex session may not auto-refresh its built-in skill registry
- in practice, a restart or a fresh session is the stable way to make them appear as normal installed skills

### 0.1 iPhone background-status groundwork was added

The latest iPhone-facing slice also adds a lightweight intermediate status layer:

- `Source/PhotoMemo/PhotoMemo/App/PhotoMemoBackgroundStatusService.swift`

What it does:

- observes `BatchQueueStore`
- resolves the most relevant external/background job snapshot
- normalizes progress, phase title, retryability, and status text into one stable model

Why this matters:

- future iPhone progress surfaces should not couple directly to `BatchQueueStore`
- the next Dynamic Island / Lock Screen / iPhone shell work can build on this snapshot service instead of re-deriving queue state ad hoc

### 0.2 iPhone now has a dedicated background-status entry without polluting the main editor

The latest follow-up iPhone slice also adds:

- a top-right background-status entry in `PhotoMemoiOSHomeView`
- a dedicated sheet:
  - `Source/PhotoMemo/PhotoMemo/iOS/Views/PhotoMemoiOSBackgroundStatusSheet.swift`

Behavior choice for this slice:

- the main iPhone editor remains focused on template calibration and preview
- background progress is not pushed back into the main editing content area
- users can open a separate sheet to check queue status, failure summaries, and retry failed items

### 0.3 iPhone background-status updates are now live, and active jobs get extra background run time

The latest follow-up after that also tightens the iPhone shell behavior:

- `PhotoMemoiOSHomeView` now directly observes both:
  - `BatchQueueStore`
  - `PhotoMemoBackgroundStatusService`
- the background-status sheet now reads live queue state instead of only receiving a one-time snapshot payload
- iPhone app runtime now owns:
  - `PhotoMemoiOSBackgroundExecutionService`
- when the app moves to the background while `BatchQueueStore` is still processing, PhotoMemo now requests a standard iOS background task window so the current batch has a better chance to keep progressing before suspension

Why this matters:

- the iPhone background-status entry is no longer just structurally present; it now reflects queue changes in real time
- the app is better aligned with the intended workflow of “share photo -> leave the foreground -> let PhotoMemo continue for a while”
- this improves reliability without turning the main calibration UI into a progress dashboard and without changing the underlying import-render-export behavior

### 0.4 iPhone background-status sheet is now closer to a formal control center

The latest follow-up also upgrades the dedicated iPhone background-status sheet:

- adds a clearer processing-focus card:
  - current photo
  - task state
  - latest update time
- adds a per-job configuration card:
  - template
  - anchor
  - description-writing mode
  - save destination summary
- adds a current-job recent-records card so users can see which photos are:
  - currently running
  - failed
  - queued
  - completed

Why this matters:

- users no longer need to infer everything from one hero string and a failure list
- the sheet now behaves more like a real mobile-side background control center while still staying outside the main editor
- this also creates a cleaner stepping stone before any future ActivityKit / Dynamic Island integration

### 0.5 ActivityKit-ready bridge groundwork now exists without forcing a widget target yet

The latest follow-up also adds a dedicated bridge layer for future Live Activity work:

- shared display titles were normalized in `BatchProcessing` for:
  - `BatchJobState`
  - `BatchJobLaunchSource`
- added a Live Activity payload model:
  - `Source/PhotoMemo/PhotoMemo/iOS/Activity/PhotoMemoBackgroundLiveActivityPayload.swift`
- added a bridge service:
  - `Source/PhotoMemo/PhotoMemo/iOS/Activity/PhotoMemoiOSLiveActivityBridgeService.swift`
- iPhone app runtime now owns that bridge service so future ActivityKit driver code can consume one stable source instead of re-deriving queue state again

What this bridge does:

- converts `PhotoMemoBackgroundStatusService` output into ActivityKit-ready attributes and content-state payloads
- tracks the current projected job and any obsolete job IDs that a future ActivityKit driver should end
- keeps Live Activity preparation separated from the main editor and from the raw queue model

Why this matters:

- the next Dynamic Island / Lock Screen slice can focus on the actual ActivityKit lifecycle and widget presentation
- PhotoMemo avoids coupling future Live Activity code directly to `BatchQueueStore`
- this keeps the current iteration small and build-safe while still moving the iPhone roadmap forward

### 0.6 App-side Live Activity driver is now wired, with a safe fallback when presentation is not fully available yet

The latest follow-up after that takes one more small step:

- adds an app-side driver:
  - `Source/PhotoMemo/PhotoMemo/iOS/Activity/PhotoMemoiOSLiveActivityDriverService.swift`
- the driver now:
  - observes `PhotoMemoiOSLiveActivityBridgeService`
  - restores any existing PhotoMemo activities on launch
  - requests a new Live Activity for an active external job
  - updates the activity while progress changes
  - ends the activity when the job becomes terminal or obsolete
- `PhotoMemoiOS` target now declares:
  - `NSSupportsLiveActivities = YES`

Safety choice for this slice:

- if the current environment can compile ActivityKit but still cannot successfully request a Live Activity, the driver disables repeated request attempts instead of spamming the pipeline with the same failure over and over

Why this matters:

- the iPhone app now has a real ActivityKit lifecycle driver, not only payload preparation
- the next slice can focus on the widget / Lock Screen / Dynamic Island presentation side instead of redoing app-side lifecycle work
- the current implementation still keeps risk controlled because it fails closed when full presentation support is not ready

### 0.7 Live Activity presentation and widget-extension wiring are now buildable end to end

The latest follow-up first added a presentational shell:

- `Source/PhotoMemo/PhotoMemo/iOS/Activity/PhotoMemoLiveActivityPresentation.swift`

What it contains:

- a `Widget` definition for the PhotoMemo Live Activity presentation
- Lock Screen layout
- Dynamic Island compact / minimal / expanded regions
- shared icon, tint, and status helpers that read from the new ActivityKit-ready payload

This line then moved past the project-wiring blocker:

- `Source/PhotoMemo/PhotoMemoWidgetExtension/PhotoMemoWidgetExtensionBundle.swift`
- `Source/PhotoMemo/PhotoMemoWidgetExtension-Info.plist`
- `Source/PhotoMemo/ShareExtension-Info.plist`
- `Source/PhotoMemo/PhotoMemo.xcodeproj/project.pbxproj`

What was resolved:

- the share extension plist now includes the base bundle keys Xcode expects, so the embedded extension no longer collapses to a `(null)` bundle identifier
- `PhotoMemoiOS` now embeds both:
  - `PhotoMemoShareExtension.appex`
  - `PhotoMemoWidgetExtension.appex`
- the new widget extension target now builds cleanly and hosts:
  - `PhotoMemoLiveActivityWidgetDefinition`
  - shared Live Activity payload/presentation files

Why this matters:

- the UI/presentation side for Live Activities is no longer just a shell inside the app target; it now has a real extension target and real embedded product output
- PhotoMemo's iPhone line has crossed from “ActivityKit groundwork only” into “project can build app + share extension + widget extension together”
- the next Live Activity slice can focus on runtime behavior and device validation instead of re-fighting `xcodeproj` embed wiring

### 1. Addy Osmani skills installed for future development workflow

The following skills are now installed in local Codex:

- `spec-driven-development`
- `planning-and-task-breakdown`
- `incremental-implementation`
- `test-driven-development`
- `code-review-and-quality`
- `frontend-ui-engineering`

Recommended usage pattern for future work:

1. `/spec`
2. `/plan`
3. `/build`
4. `/test`
5. `/review`

### 2. MainView refactor continued in controlled slices

`MainView.swift` is still large, but it has been meaningfully reduced and split into focused subviews.

Recent extracted files:

- `Source/PhotoMemo/PhotoMemo/Views/Main/MainView+MemoryProgress.swift`
- `Source/PhotoMemo/PhotoMemo/Views/Main/MainView+OutputSection.swift`
- `Source/PhotoMemo/PhotoMemo/Views/Main/MainView+Permissions.swift`
- `Source/PhotoMemo/PhotoMemo/Views/Main/MainView+ComposerEditor.swift`
- `Source/PhotoMemo/PhotoMemo/Views/Main/MainView+ComposerPanels.swift`
- `Source/PhotoMemo/PhotoMemo/Views/Main/MainView+TemplatePanels.swift`
- `Source/PhotoMemo/PhotoMemo/Views/Main/MainView+SetupPanels.swift`
- `Source/PhotoMemo/PhotoMemo/Views/Main/MainView+PreviewPanels.swift`
- `Source/PhotoMemo/PhotoMemo/Views/Main/MainView+StateModels.swift`

MainView line-count trend observed in this refactor stream:

- `5706`
- `5096`
- `4885`
- `4614`
- `4529`
- `4314`
- `4164`
- `3974`
- `3648`
- `3496`
- `2905`
- `2842`
- `1186`
- `467`
- `300`
- `228`
- `112`
- `72`

Current result:

- `Source/PhotoMemo/PhotoMemo/Views/Main/MainView.swift` is now acting more like a coordinator
- its remaining coordinator state is now partially grouped through `MainPresentationState`, `MainAlertState`, and `MainEditorSessionState`
- template setup, logo setup, photo import summary, anchor setup, live preview shell, and multiple editor/panel regions have been extracted
- composer session state, workspace configuration lifecycle, and export/save actions have now also been split into dedicated `MainView+*.swift` files
- dead block-style composer helpers and their unused widget file have now been removed instead of being kept as stale compatibility code
- some dead UI helpers were removed after extraction to prevent stale code from remaining in `MainView`

### 3. Template-calibration UI structure is more stable

Completed structural extractions now cover:

- template section
- template rename sheet
- custom content section
- logo section
- photo section
- anchor section
- preview/detail display shell
- inline custom-region editor
- variable library panels
- field editor wrappers
- output / permission panels

This means future MainView work should prioritize:

- any lingering state-heavy editing helpers that still live inline
- any remaining preview-adjacent helper logic that is still coupled to coordinator code
- any permission/scene lifecycle actions that still sit beside unrelated coordinator code

### 4. Immers-style white border direction has already been integrated

Product/UI decisions already established in this workstream:

- only borrow the bottom white-bar design language from Immers
- keep PhotoMemo content centered on memory + smart modules, not generic EXIF-only filler
- unify the old badge semantics toward `Logo 标识`
- for `immersWhite`, when no custom logo is selected, use a classic Apple mini logo fallback
- horizontal layout was tuned to better match the reference direction while still staying consistent with PhotoMemo

Key related files:

- `Source/PhotoMemo/PhotoMemo/Renderers/ImmersWhiteRenderer.swift`
- `Source/PhotoMemo/PhotoMemo/Renderers/RecordCardRenderer.swift`
- `Source/PhotoMemo/PhotoMemo/Models/TemplatePreset.swift`
- `Source/PhotoMemo/PhotoMemo/Models/Template.swift`
- `Source/PhotoMemo/PhotoMemo/Models/TemplateItem.swift`
- `Source/PhotoMemo/PhotoMemo/Views/Template/BadgePickerView.swift`

### 5. Permission and content wording refinement started

Latest refinement work now also covers:

- denied photo-library permission no longer pretends the system prompt can be re-shown; the UI now guides the user toward System Settings
- birthday-style smart text suppresses awkward under-one-year wording like `0岁8个月`
- the `补充信息` section now uses a single card and treats the checkbox as custom batch-description mode; when it is off, PhotoMemo falls back to the rendered right-bottom content

### 6. Multi-configuration workspace controls are now in progress

Latest MainView work now also adds a real right-side configuration workflow:

- three persisted local configuration slots
- one active slot at a time
- right-side save / restore-default actions instead of the old toolbar-only save entry
- a right-side operation-guide menu and sheet
- dismissible helper cards for anchor, smart-module, and supplemental-content guidance

Behavior expectations for this slice:

- switching slots should refresh the left-side configuration state and right-side preview together
- unsaved slots should fall back to `模板 1 / 2 / 3` default skeletons
- the active slot should remain aligned with the batch queue's default configuration snapshot

### 7. Workspace naming and help-center navigation were refined

The latest follow-up refinement now also adds:

- custom naming for each of the three configuration slots
- a dedicated rename sheet for the active slot
- a grouped right-side help-center menu instead of a flat operation-guide list
- a formal split-view help center with category navigation and topic detail panes

Important behavior choices:

- slot renaming changes only the workspace slot label, not the template name
- restoring a slot to its default skeleton clears the saved snapshot but keeps the custom slot name
- already-dismissed inline tips remain removable from the left side, while the full explanation stays available inside the help center

### 8. Left-side clutter and output controls were reduced further

The latest cleanup pass now also does the following:

- memory-progress guidance is dismissible like the other helper cards
- the personalized-region guidance is dismissible instead of being hard-coded inline text
- the supplemental-content area is truly reduced to a single card
- the permission block no longer occupies the sidebar after both permissions are granted
- the help center no longer keeps a separate permission topic after the permission flow is already understood
- the output area now focuses on album selection plus save-to-library, without the extra metadata-validation buttons

### 9. Dead validation UI paths were cleaned out of MainView

The latest internal cleanup pass now also removes:

- the no-longer-reachable metadata-validation sheet flow from `MainView`
- the old metadata debug view file that was only serving that removed flow
- the collapsed-permission-summary branch that no longer matters now that the whole permission block hides after authorization

This keeps the UI simplification aligned with the actual coordinator code instead of only hiding old actions visually.

### 10. Custom-region editing moved closer to visual module composition

The latest refinement slice now also does the following:

- the extra top control/help block under `个性化区域` is gone from the left side
- the old inline raw-token editing path was removed from `MainView`
- manual text is now added and edited as its own literal chip inside the same single-line module flow
- `识别数据` and `智能数据` keep acting as direct insert buttons into the explicitly selected region
- user-facing help copy in the editor/help center no longer leans on raw `{{token}}` syntax
- the `补充信息` and `输出` section explanations now use dismissible guide cards, with the fuller explanation still preserved in the right-side help center

Behavior expectations for this slice:

- tapping a region still defines the only valid insertion target
- inserted EXIF / smart modules should remain human-readable instead of exposing raw tokens
- users should be able to keep composing around modules without switching to a separate text-entry sheet
- the template section should show human-readable default-output summaries instead of raw template tokens

### 11. Custom-region editing now favors cursor-based inline composition

The latest follow-up slice now also does the following:

- the four custom regions no longer require a separate “添加文字 / 编辑文字” action
- users can click directly into a region and type their own short phrase inline
- EXIF and smart-module buttons now insert into the current text cursor position instead of inserting as separate manual-text chips
- inserted modules are shown as human-readable inline labels such as `〔年岁〕`, so the editor no longer exposes raw `{{token}}` syntax during normal editing
- the right-side help-center wording for the custom-region topic now reflects the new cursor-first editing model

Behavior expectations for this slice:

- clicking a region should place or restore the caret inside that region
- clicking a module button should insert that module exactly at the current caret or selected text range
- users should be able to continue typing before or after an inserted module without opening any extra sheet
- the underlying template still persists real raw tokens, so preview/render/export behavior should remain on the existing pipeline

### 12. Inline module visuals were restored closer to block-style editing

The latest follow-up slice now also does the following:

- inline module labels inside the four custom regions are rendered with block-like highlighted styling instead of appearing as plain text only
- deletion near a module now expands to the full inline module label, so backspace/delete behaves closer to removing one whole block
- editor-side display mapping now also covers common composite tokens such as `camera_summary`, avoiding mixed output like one readable label plus one raw token

Behavior expectations for this slice:

- a module inserted at the caret should look visually distinct from ordinary typed text
- when the caret is immediately next to a module, delete/backspace should remove the whole module display label in one action
- display-only labels must still map back to the original raw template tokens before preview/render/export

### 13. Share-intake persistence and fallback hardening advanced again

The latest iOS-readiness slice focused on making the external intake path safer for novice users without changing the main calibration UI.

Completed in this round:

- added a shared album-selection helper:
  - `Source/PhotoMemo/PhotoMemo/App/PhotoMemoAlbumSelection.swift`
- removed the share-extension snapshot path's dependence on `PhotoAlbumOption` constants from the photo-library export layer
- strengthened `ExternalPhotoIntakeStore` so persistence failure now cleans up managed inbox copies instead of leaving orphaned temporary files behind
- deduplicated repeated URLs before persisting or queueing external-intake requests
- `PhotoMemoAppRuntime.flushExternalRequests()` now filters out missing source files before enqueuing, so stale requests degrade into smaller valid batches instead of failing later at import time
- `PhotoMemoShareExtensionIntakeService` now:
  - accepts partial success instead of treating one provider failure as a whole-share failure
  - reports imported / skipped / failed counts back to the share UI
  - tries a safer fallback path using file URLs or raw image data when direct file representation is unavailable
  - does **not** fall back to `UIImage -> JPEG` rewriting, to avoid silently stripping EXIF or changing the source photo bits during intake

Why this matters:

- it stays aligned with the "ExternalIntake is pure temporary storage" decision
- it reduces invisible failure modes before the real import/render/export pipeline starts
- it keeps metadata-retention priorities ahead of convenience fallbacks

Verification for this round:

- passed:
  - `xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemoShareExtension -configuration Debug -destination 'generic/platform=iOS Simulator' -derivedDataPath /tmp/PhotoMemoShareExtensionDerivedData CODE_SIGNING_ALLOWED=NO -quiet build`
  - `xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemoiOS -configuration Debug -destination 'generic/platform=iOS Simulator' -derivedDataPath /tmp/PhotoMemoIOSDerivedData CODE_SIGNING_ALLOWED=NO -quiet build`
  - `xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemo -configuration Debug -derivedDataPath /tmp/PhotoMemoDerivedData CODE_SIGNING_ALLOWED=NO -quiet build`
- observed:
  - only the existing Xcode destination-selection warning on macOS build
- not yet manually verified:
  - real Photos share-sheet input that provides only `loadItem` data and not file representation
  - multi-photo share where one or more items disappear before the host app flushes the request
  - user-facing wording and timing of the share-extension success/partial-success message on device

### 14. Share-extension compile surface was reduced to a small shared core

The latest architecture slice focused on trimming `PhotoMemoShareExtension` so it only compiles what the share-intake pipeline actually needs.

Completed in this round:

- added a synchronized-group target-exception set in:
  - `Source/PhotoMemo/PhotoMemo.xcodeproj/project.pbxproj`
- excluded clearly app-only files from the share-extension target, including:
  - main app shells
  - `Views/*`
  - renderers
  - queue / export / permission services
  - unused engines and helper extensions
- extracted `ExternalPhotoIntakeRequest` into its own shared file:
  - `Source/PhotoMemo/PhotoMemo/App/ExternalPhotoIntakeRequest.swift`
- this removes the previous coupling where `ExternalPhotoIntakeStore` depended on `ExternalPhotoIntakeCenter.swift` just to see the request model
- refined the share-extension success message so partial-success feedback only shows the non-zero skipped / failed counts

Current result:

- the share-extension target now compiles against a much smaller shared core
- the generated `PhotoMemoShareExtension.SwiftFileList` is now `19` lines, down from the previous much broader compile surface that still included:
  - `MainView`
  - preview/template/anchor views
  - app entry shells
  - queue/export/permission services

Why this matters:

- iOS share flow is now less coupled to the macOS calibration UI
- future extension-specific bugs become easier to isolate
- future share-flow testing is less likely to be blocked by unrelated UI/service regressions

Verification for this round:

- passed:
  - `xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemoShareExtension -configuration Debug -destination 'generic/platform=iOS Simulator' -derivedDataPath /tmp/PhotoMemoShareExtensionDerivedData CODE_SIGNING_ALLOWED=NO -quiet build`
  - `xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemoiOS -configuration Debug -destination 'generic/platform=iOS Simulator' -derivedDataPath /tmp/PhotoMemoIOSDerivedData CODE_SIGNING_ALLOWED=NO -quiet build`
  - `xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemo -configuration Debug -derivedDataPath /tmp/PhotoMemoDerivedData CODE_SIGNING_ALLOWED=NO -quiet build`
- observed:
  - only the existing Xcode destination-selection warning on macOS build
- not yet manually verified:
  - real share-sheet behavior after the new target slimming on device
  - whether any third-party share source relies on a file path or raw data shape not yet seen in manual testing

## Behavior Rules Preserved During Refactor

These behaviors were intentionally preserved and should not be reverted:

- variable insertion must target an explicitly selected custom region
- no implicit fallback that silently inserts into the right-bottom region
- template switching, restoring defaults, and template rename must refresh composer editing state
- preview-side template calibration must stay connected to the real render/export chain

## Verification Status

Recent verification command:

```bash
xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemo -configuration Debug -derivedDataPath /tmp/PhotoMemoDerivedData CODE_SIGNING_ALLOWED=NO -quiet build
```

Status:

- build passes
- only Xcode destination-selection warning observed
- no new compile error from the latest MainView extraction rounds
- there is still no separate automated test target in the current Xcode project, so refactor validation is currently build-first plus manual regression checks

## Current Technical Debt

### Coordinator shell is now thin, but needs semantic cleanup

`Source/PhotoMemo/PhotoMemo/Views/Main/MainView.swift` is now down to about `72` lines, which is a strong coordinator-shell result.

The remaining debt is no longer raw file size. It is now about whether the remaining state is grouped at the right boundary and whether access control / ownership are as clear as the new structure suggests.

### Multi-config and in-app guidance still need a dedicated design slice

The newly requested three-slot configuration system and right-side operation guide are both product-shaping changes. They should be implemented as a dedicated state/persistence redesign instead of being mixed into small UI tweaks.

### Manual UI regression checks are still needed

Builds are passing, but some refactor rounds were verified mainly by compilation and structure review. Manual checks remain important for:

- template rename flow
- anchor selection flow
- photo import flow
- logo fallback behavior on `immersWhite`
- preview/export visual parity

## Recommended Next Steps

### Near-term

1. Tighten access control now that the `MainView` coordinator shell has settled
2. Revisit badge / output / workspace bindings and move any obviously local binding logic beside the related panels
3. Run a deliberate manual check for:
   - template switching
   - template rename
   - anchor selection
   - photo import
   - live preview rendering after import
   - white-border logo fallback

### Product hardening

1. Continue preview/export parity work
2. Continue metadata-retention validation
3. Harden failed-task retry and library save feedback

### Architecture

1. Keep reducing macOS-only assumptions where practical
2. Preserve future iOS migration room
3. Avoid adding new feature surface faster than the real processing chain can support

## Best Entry Files For A New Session

Read in this order:

1. `README.md`
2. `AI_CONTEXT.md`
3. `HANDOFF.md`
4. `AGENTS.md`
5. `Docs/CURRENT_STATUS.md`
6. `Docs/DEVELOPMENT_PLAN.md`

Then inspect:

- `git status`
- `Source/PhotoMemo/PhotoMemo/Views/Main/MainView.swift`
- the newest `MainView+*.swift` extraction files

## 2026-06-19 Follow-Up

This round added a dedicated inline-composer display engine:

- `Source/PhotoMemo/PhotoMemo/Views/Main/MainView+ComposerDisplayEngine.swift`

Purpose:

- stop treating every visible `〔...〕` label as a real token
- track real inserted modules by span instead of regex-only text matching
- keep module-aware selection/deletion behavior aligned across macOS and UIKit

Related notes kept for the next session:

- optimization log:
  - `Docs/OPTIMIZATION_LOG_2026-06-19.md`
- competitor and product-direction notes:
  - `Docs/COMPETITOR_NOTES_2026-06-19.md`
- iOS readiness audit:
  - `Docs/IOS_READINESS_2026-06-19.md`
- manual regression checklist:
  - `Docs/MANUAL_REGRESSION_CHECKLIST_2026-06-19.md`

MainView re-review result for this follow-up:

- `Source/PhotoMemo/PhotoMemo/Views/Main/MainView.swift` is now around `3621` lines
- the next most valuable extractions are:
  - composer session state
  - workspace configuration lifecycle
  - export/save actions

## 2026-06-19 External Intake Foundation Follow-Up

The latest infrastructure slice now also does the following:

- adds a shared app-container helper:
  - `Source/PhotoMemo/PhotoMemo/App/PhotoMemoSharedContainer.swift`
- adds a persisted intake inbox:
  - `Source/PhotoMemo/PhotoMemo/App/ExternalPhotoIntakeStore.swift`
- updates `ExternalPhotoIntakeCenter` so external image requests are no longer in-memory only
- updates settings, permission-primer state, and batch-queue persistence to read/write through a shared defaults entry point
- updates app runtime activation flow so persisted intake requests are automatically flushed on launch/activation without adding any progress UI back into the main screen

Behavior expectations for this slice:

- external intake requests should survive app relaunch instead of being lost with process memory
- the default batch configuration snapshot used for background intake should stay aligned with the current saved workspace configuration
- the main UI should remain a calibration center only; no queue/progress panel should reappear

## 2026-06-19 External Intake Cleanup Follow-Up

The latest follow-up now also does the following:

- teaches `ExternalPhotoIntakeStore` to clean up only the managed source files that PhotoMemo copied into the shared `ExternalIntake` inbox
- wires that cleanup into safe terminal paths:
  - after a task completes successfully
  - when a queued/running job is explicitly cancelled

Behavior expectations for this slice:

- shared intake files should no longer accumulate forever after successful background processing
- failed tasks should still retain their managed source files so retry remains possible
- original user-selected files outside the managed intake inbox must never be deleted by this cleanup path

## 2026-06-19 External Intake Orphan Cleanup Follow-Up

The latest follow-up now also does the following:

- exposes the currently referenced managed source URLs from `BatchQueueStore`
- runs an orphaned managed-intake cleanup scan during app-side external-intake refresh
- removes inbox child files/directories that are no longer referenced by any pending request or persisted batch task

Behavior expectations for this slice:

- a previously interrupted app session should not leave unmanaged `ExternalIntake` directories accumulating forever
- queued, running, or failed-for-retry managed sources must remain intact while still referenced by queue state

## 2026-06-19 Share Extension Skeleton Follow-Up

The latest follow-up now also does the following:

- adds a minimal iOS share-extension intake service that writes incoming shared images into the existing shared `ExternalIntake` inbox
- adds a minimal share-extension view controller and extension plist/entitlement files
- wires a real `PhotoMemoShareExtension` target into the Xcode project
- keeps the main iOS app entry isolated behind a compilation condition so the extension target can compile cleanly without conflicting `@main` app entrypoints

Behavior expectations for this slice:

- the repository now contains a real compilable share-extension target rather than only “future-ready” architecture
- shared images can be persisted into the same intake pipeline foundation already used by the app runtime
- the main calibration-center UI remains unchanged; this slice is project/runtime groundwork only

## 2026-06-19 Strict Temporary Intake Follow-Up

The latest follow-up now also does the following:

- tightens the shared `ExternalIntake` copies into a strict temporary-file policy
- cleans managed intake source files on all terminal outcomes, including failed tasks
- marks failures that have lost their managed temporary source as non-retryable
- trims persisted terminal job history before saving queue state

Behavior expectations for this slice:

- managed intake files should not linger as a long-term cache after success, cancellation, or failure
- retry should remain available only for failures whose source is still genuinely available
- queue history should stop growing without bound across long-term usage

## 2026-06-19 Partial Failure Semantics Follow-Up

The latest follow-up now also does the following:

- refines batch-result semantics so small failure counts are treated as exceptions instead of making the whole batch feel like a total failure
- updates failure summaries and completion notifications to prefer “mostly completed, with exceptions” language when most photos succeeded
- hides retry actions for failures that no longer have a real recoverable source under the strict temporary-file policy

Behavior expectations for this slice:

- when a large batch finishes with only one or a few failures, users should still feel that the batch fundamentally completed
- failure handling remains explicit, but it no longer overstates the impact of isolated exceptions

## 2026-06-19 Share Extension Warning Cleanup

The latest follow-up now also does the following:

- moves the share-extension plist outside the synchronized `PhotoMemo/` group root
- points `PhotoMemoShareExtension` at the new external plist path
- removes the previous share-extension `Info.plist` bundle-resource warning during build verification

## 2026-06-19 Share Extension Slimming Follow-Up

The latest follow-up now also does the following:

- extracts a lightweight shared batch-configuration snapshot reader:
  - `Source/PhotoMemo/PhotoMemo/App/SharedBatchConfigurationSnapshotService.swift`
- moves the share-extension intake flow away from the full `SettingsService` dependency
- keeps the extension reading only the minimum persisted configuration inputs it needs to enqueue shared photos consistently

Behavior expectations for this slice:

- the share extension should now rely on a smaller, clearer configuration boundary
- future target slimming can focus on removing additional unnecessary app-only compile dependencies without changing the user-visible flow

## 2026-06-19 Refactor Completion

This follow-up successfully landed the three extractions that were queued in the previous note:

- `Source/PhotoMemo/PhotoMemo/Views/Main/MainView+ComposerSession.swift`
- `Source/PhotoMemo/PhotoMemo/Views/Main/MainView+WorkspaceConfigurationState.swift`
- `Source/PhotoMemo/PhotoMemo/Views/Main/MainView+ExportActions.swift`

What moved out of `MainView.swift`:

- editor display text / selection / module-span session state
- workspace-slot save, switch, restore-default, and snapshot application flow
- photo-library permission prompt, album reload, and save-to-library actions

Updated structure result:

- `Source/PhotoMemo/PhotoMemo/Views/Main/MainView.swift` is now around `2905` lines
- build succeeds again after removing the leftover duplicate legacy method definition
- the coordinator file is now meaningfully less responsible for low-level editing and save-flow mechanics

One more safe follow-up extraction has already landed after that:

- `Source/PhotoMemo/PhotoMemo/Views/Main/MainView+PermissionLifecycle.swift`

That file now owns:

- first-appearance permission refresh
- active-scene permission refresh
- primer-sheet permission request flow
- notification permission request feedback

Latest line-count result after this extra slice:

- `Source/PhotoMemo/PhotoMemo/Views/Main/MainView.swift` is now around `2842` lines

This workstream then continued with a more aggressive but still behavior-preserving cleanup:

- removed the no-longer-used block-style composer item state, chip widgets, literal-composer sheet, and scrubber helpers
- extracted `MainView+DerivedState.swift`
- extracted `MainView+CoordinatorSupport.swift`
- extracted `MainView+TemplateEditingActions.swift`

Latest line-count result after that cleanup:

- `Source/PhotoMemo/PhotoMemo/Views/Main/MainView.swift` is now around `1186` lines

The refactor then continued with two more coordinator-focused extractions:

- extracted `MainView+PresentationState.swift`
- extracted `MainView+LayoutSections.swift`

That moved:

- rename-sheet / help-center sheet presentation and local draft state
- sidebar/detail assembly and section-level view composition

Latest line-count result after that follow-up:

- `Source/PhotoMemo/PhotoMemo/Views/Main/MainView.swift` is now around `467` lines

One final light cleanup also landed immediately after:

- extracted `MainView+UIPrimitives.swift`

That moved:

- `MainFieldSlot`
- palette and card/chip style primitives
- small shared layout wrappers used by the main editor flow

Latest line-count result after this step:

- `Source/PhotoMemo/PhotoMemo/Views/Main/MainView.swift` is now around `300` lines

The coordinator shell then kept shrinking in two small, safe follow-ups:

- extracted `MainView+ModalAndLifecycle.swift`
- extracted `MainView+Feedback.swift`

That moved:

- anchor sheet / rename sheet / help sheet / alert wiring
- onAppear / onChange lifecycle routing
- alert presentation helper and local preview stub

Latest line-count trend after these last follow-ups:

- `Source/PhotoMemo/PhotoMemo/Views/Main/MainView.swift` is now around `228` lines
- then around `112` lines
- and after grouping the remaining editor session state, around `72` lines

Verification for this completion slice:

- passed:
  - `xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemo -configuration Debug -derivedDataPath /tmp/PhotoMemoDerivedData CODE_SIGNING_ALLOWED=NO -quiet build`
- observed:
  - only the existing Xcode destination-selection warning
- not yet manually verified:
  - permission primer -> authorize -> album refresh flow
  - switching workspace slots while custom-region editor caret is active
  - save-to-library success and failure alerts against a real photo

One more light state-ownership follow-up has now landed:

- added `Source/PhotoMemo/PhotoMemo/Views/Main/MainView+StateModels.swift`
- grouped the remaining editor-session fields into `MainEditorSessionState`
- moved `focusedField`, display texts, selections, and module spans under that single coordinator-facing state model

Latest result after this follow-up:

- `Source/PhotoMemo/PhotoMemo/Views/Main/MainView.swift` is now about `72` lines
- the coordinator shell now mostly declares service/state ownership and forwards `body` to `mainScene`
- the earlier `MainPresentationState` / `MainAlertState` grouping is now joined by `MainEditorSessionState`, which makes the remaining state easier to reason about without changing editor behavior

Verification for this extra slice:

- passed:
  - `xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemo -configuration Debug -derivedDataPath /tmp/PhotoMemoDerivedData CODE_SIGNING_ALLOWED=NO -quiet build`
- observed:
  - only the existing Xcode destination-selection warning
- not yet manually verified:
  - workspace-slot switching while editor caret is active
  - live caret preservation while repeatedly inserting EXIF / smart modules
  - save-to-library success and failure alerts against a real photo

Next three most valuable areas after this slice:

1. selective access-control tightening after the refactor settles
2. badge/output/workspace bindings that can move beside their related panels
3. manual regression coverage for caret routing, slot switching, and export feedback now that the coordinator shell is structurally stable

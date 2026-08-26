# MemoMark 命名迁移规范

最后更新：2026-08-26

## 目标

将产品从早期内部名称 `PhotoMemo` 统一为正式产品名称 `MemoMark`，同时
保持已发布 App 的更新身份、用户配置、Apple Photos 分享链路、Share
Extension 共享容器、后台任务、通知和旧外部链接继续可用。

本规范只处理命名迁移，不改变 Memory Engine、Presentation Engine、Layout
Engine、Renderer、Export、PhotoKit 或 Configuration Center 的职责边界。

## 当前基线

### 工作区与远端

- 分支：`main`
- `HEAD` 与 `origin/main` 均为 `c0f11a7`
- 远端领先/落后：`0/0`
- 当前工作区：103 个已跟踪文件有改动，11 个未跟踪文件，共 114 个变更项
- 未执行拉取、提交、推送、TestFlight 上传或 App Store 提交
- 不运行自动同步脚本：该脚本会 `git add -A`、自动提交并推送当前全部改动

### 旧名称统计

以下统计为工作区文本内容，排除 Git、构建目录和常见图片/视频二进制，
`PhotoMemo` 匹配不区分大小写：

| 范围 | 匹配次数 | 涉及文件 |
| --- | ---: | ---: |
| `Source/PhotoMemo` | 1,868 | 358 |
| `Tests/PhotoMemoTests` | 2,292 | 221 |
| `Tests/PhotoMemoUITests` | 1 | 1 |
| `scripts` | 96 | 14 |
| `Docs` | 8,290 | 202 |
| 全仓库（含根目录及 `.codex`） | 15,788 | 819 |

文件名 basename 中包含旧名称的项目共 69 个，其中：源码目录 48 个、测试
11 个、文档 4 个、脚本 1 个、根目录或输出资产 5 个。源码目录中的 48 个
项目包括 38 个 Swift 文件、4 个 plist、3 个 entitlements 和 3 个 scheme；
Xcode 工程与目录本身还会额外影响大量路径引用。

### 主要代码符号规模

工作区 Swift 源码中，代表性旧前缀的引用规模如下：

| 符号族 | 引用次数 | 涉及文件 |
| --- | ---: | ---: |
| `PhotoMemoResult` | 100 | 25 |
| `PhotoMemoError` | 45 | 18 |
| `PhotoMemoSharedContainer` | 88 | 44 |
| `PhotoMemoShareDiagnostics` | 86 | 25 |
| `PhotoMemoBackground*` | 164 | 22 |
| `PhotoMemoiOS*` | 145 | 22 |
| `PhotoMemoShare*` | 472 | 77 |

编译条件 `PHOTOMEMO_SHARE_EXTENSION` 出现 440 次，涉及 410 个文件；这类
条件名需要和 Xcode build settings 一起成组迁移，不能只替换 Swift 文件。

## 命名分层

### 可以在代码迁移中统一为 `MemoMark`

- Swift 类型、协议扩展、错误/结果容器、服务和纯内部状态类型的旧产品前缀
- 当前源码文件 basename
- Xcode project 的工程名、target/scheme 名称和产品显示名（在不改变 bundle
  identifier 的前提下）
- 测试 target 的模块导入名和测试文件 basename
- 当前脚本、当前文档和自动化输出中的新产品称呼

### 必须保留或兼容读取

以下值不是普通品牌文案，而是已发布运行时身份或用户数据协议。第一轮不改
其值，只将其集中到明确的兼容层：

| 旧值 | 原因 | 策略 |
| --- | --- | --- |
| `com.serydoo.PhotoMemo` | App Store macOS bundle identity | 保留 |
| `com.serydoo.PhotoMemo.iOS` | App Store iOS bundle identity | 保留 |
| `com.serydoo.PhotoMemo.iOS.ShareExtension` | 已发布 extension identity | 保留 |
| `com.serydoo.PhotoMemo.iOS.WidgetExtension` | 已发布 widget identity | 保留 |
| `group.com.serydoo.PhotoMemo` | 主 App 与 Share Extension 的共享数据域 | 保留 |
| `photomemo.*` UserDefaults keys | 现有配置、队列、诊断和回执数据 | 保留读取/写入，集中管理 |
| `__photomemo_auto__`、`__photomemo_system__` | 已持久化的输出目标标识 | 保留解码 |
| `photomemo://` | 旧快捷指令、通知或外部链接 | 保留解析；新生成链接使用 `memomark://` |
| `com.serydoo.PhotoMemo.batch-processing` | BGTaskScheduler 已登记标识 | 保留，避免后台任务注册不一致 |
| StoreKit product ID 中的旧 bundle 前缀 | App Store 商品身份 | 保留，不能凭品牌改商品 ID |
| 历史发布记录、迁移记录、旧资产归档 | 历史事实和可追溯性 | 不改原始上下文；必要时增加当前说明 |

`PersonalProfileSaveDestination.photoMemoAlbum` 等 Codable enum case 也不能
直接改名；若未来需要改 Swift case，必须先增加显式 Codable 兼容映射并以
测试证明旧 JSON 可读、新 JSON 可写。

## 分阶段实施

### Slice 0：规范与基线

- 保存本规范。
- 保存旧名称、文件名和关键运行时身份统计。
- 以当前工作区完成 macOS build，记录与改名无关的既有警告。

### Slice 1：低风险 Swift 领域符号

- 先迁移不参与持久化协议的 `PhotoMemoResult` / `PhotoMemoError` 等基础
  类型及其调用方。
- 同步单元测试引用。
- 不改 bundle ID、App Group、UserDefaults key、BGTask ID、StoreKit ID、URL
  scheme 或 Codable enum raw value。
- 运行 focused tests 与 macOS build。

### Slice 2：运行时内部服务与 App/Share 边界

- 迁移 `PhotoMemoSharedContainer`、Share diagnostics、background status 等
  内部类型。
- 保留兼容值，并补充/更新持久化和 Share Extension 边界测试。
- 检查主 App、Share Extension、Widget 的编译条件和依赖方向。

### Slice 3：Xcode 工程、target、scheme 和文件名（已完成）

- 迁移 project/group/target/scheme 的可见命名以及源码文件 basename。
- `PRODUCT_BUNDLE_IDENTIFIER`、entitlements 中的 App Group 和 App Store
  相关 ID 保持不变。
- 更新所有构建脚本、设备 QA 工具和测试模块导入。
- 先执行静态工程完整性检查，再构建 macOS 与通用 iOS；UI 改名后使用签名
  的物理 iPhone 17 Pro Max 安装/启动确认，不使用 Simulator 作为视觉验收。

### Slice 4：当前文档、脚本和开发入口（已完成）

- 更新当前 README、脚本说明、当前状态和开发入口中的非历史名称。
- 历史 release note、handoff、迁移说明和旧资产归档保留事实；只在必要时
  添加“当前名称为 MemoMark”的上下文，而不是批量改写历史。
- 自动同步已切换到 `com.serydoo.memomark.autosync` 新 plist/label；安装器
  在重新安装时先 boot out 旧的 `com.serydoo.photomemo.autosync`，支持目录
  仍保留原位置以避免丢失日志和状态。未在本次会话执行安装或重装。

### Slice 5：清理与冻结（本次完成静态检查与构建验证）

- 用静态扫描确认当前代码不再有未分类的 `PhotoMemo` 符号。
- 确认所有保留的旧值都有兼容原因、集中 owner 和测试。
- 运行完整 macOS `MemoMarkTests`、macOS build、通用 iOS build、签名物理
  设备安装/启动及 Apple Photos -> Share -> Processing -> Notification ->
  Apple Photos 的人工回归。
- 通过代码质量审查后，再决定是否提交；不得由自动同步脚本代替人工提交。

## 验收命令

每个代码 slice 至少执行：

```bash
git diff --check
xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/MemoMark/MemoMark.xcodeproj \
  -scheme MemoMark \
  -configuration Debug \
  -derivedDataPath /tmp/MemoMarkRenameDerivedData \
  CODE_SIGNING_ALLOWED=NO \
  -quiet build
```

涉及持久化、Share Extension、后台任务或工程 target 的 slice 还必须执行
对应 focused tests，并核对：

- 既有配置、队列、诊断、回执和资产文件仍可读取；
- App Store bundle identifier 未变化；
- App Group 仍能在主 App 与 Share Extension 中解析并读回；
- `memomark://` 新链接可用，`photomemo://` 旧链接仍可解析；
- StoreKit product ID、BGTask identifier 和关键通知/诊断协议未被误改；
- 原图不修改，PhotoKit 保存回写链路不改变。

## 当前决定

1. 不执行远端同步：远端已与 `HEAD` 同步，且自动同步会提交当前无关改动。
2. 不改变 App Store bundle identifier 或 App Group。
3. 不把旧持久化 key 当作品牌文案清理；它们属于数据兼容协议。
4. 从低风险 Swift 领域符号开始，每一 slice 构建并测试后再扩大范围。
5. 不把历史文档中的 `PhotoMemo` 自动替换为 `MemoMark`，以保留历史真实性。
6. 当前工程入口已迁移为 `/Users/rui/Desktop/PhotoMemo/Source/MemoMark/MemoMark.xcodeproj`；
   仅发布身份相关旧值继续保留，不再保留旧工程路径作为当前开发入口。

## 本次执行结果（2026-08-26）

- 完成 Swift 内部符号、后台/Share/Widget/iOS/UI 文件 basename、编译条件、
  Xcode project/group/target/scheme/module、plist 路径、测试目录和当前脚本
  入口迁移；没有改变 UI 层级、布局常量、状态流、交互、Renderer、Export、
  PhotoKit、Live Photo 或本地数据行为。
- 通过 `xcodebuild -list`，macOS `MemoMark` Debug build，通用 iOS
  `MemoMarkiOS` Debug build，`MemoMarkShareExtension`、
  `MemoMarkWidgetExtension` build，以及 `MemoMarkDeviceQA` build-for-testing。
- 通过 macOS 聚焦稳定性测试（配置迁移、队列、诊断、共享容器、持久化、深链），
  以及 117 个脚本测试；`git diff --check` 和 7 个 plist lint 通过。
- 当前工作区全量 macOS 测试的既有 UI source-contract 失败仍单独保留，未将其
  伪装成命名迁移回归，也未为改名修改 UI 产品契约。
- 兼容审计确认以下值保持不变：发布 bundle ID、App Group、`photomemo.*`
  defaults keys、StoreKit product ID、BGTask identifier、诊断域和旧
  `photomemo://` 解析能力。

## 开放决策

- 是否执行物理 iPhone 的签名覆盖安装/启动与 Apple Photos -> Share -> Processing
  -> Notification -> Apple Photos 人工回归；这属于设备与发布验证，不在本次
  无行为改名的工作区验证中执行。

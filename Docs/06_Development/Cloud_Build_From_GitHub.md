# 从 GitHub 构建完整 MemoMark

## 源码入口与工具链

完整仓库包含当前应用及所有已接受的 V5 自适应呈现、编辑体验和设置优化。工程入口为 `Source/MemoMark/MemoMark.xcodeproj`。当前源码版本保留2.3.7(132)，不是新的分发构建号。

本检查点在 Xcode27.2（27B5028f）、iPhoneOS27.2 SDK 验证。云端应选择提供同等 API 的 Xcode27.2 工具链；仅运行时 availability 检查不能让旧 SDK 识别新 API。iOS deployment target 仍为18.0。macOS 应用和 host 测试 deployment target 当前为27.0，host 测试机必须满足该要求。工具链可用性按云端实际配置确认，不把本地 SDK 版本视为云端已配置证明。

从干净 clone 的仓库根目录运行。工程没有 Swift Package Manager 外部包引用，不需要虚构 Package.resolved 或安装开发 Skill；所需 Apple 框架随 Xcode 提供。App 图标、预览资源、Info.plist、entitlements、Share/Widget target 和共享 Scheme 随源码维护。本机 config/mcporter.json 不是 App 构建依赖。

## 不依赖本地签名材料的源码归档

```sh
xcodebuild -project Source/MemoMark/MemoMark.xcodeproj \
  -scheme MemoMarkiOS -configuration Release \
  -destination 'generic/platform=iOS' \
  -derivedDataPath /tmp/MemoMarkCleanDerivedData \
  -archivePath /tmp/MemoMarkCleanArchive.xcarchive \
  CODE_SIGNING_ALLOWED=NO archive
```

该命令验证主 App 及其依赖的 Share/Widget 可归档，不生成可直接安装或上架的签名包。分发签名由拥有相应 Bundle ID、App Group 和权限的 Apple Developer / Xcode Cloud 配置提供，证书与私钥不进入 GitHub。

## Host 回归

```sh
xcodebuild -project Source/MemoMark/MemoMark.xcodeproj \
  -scheme MemoMarkTests -destination 'platform=macOS' \
  -derivedDataPath /tmp/MemoMarkCleanHostData \
  -parallel-testing-enabled NO CODE_SIGNING_ALLOWED=NO test
```

原有 ImageIO fixture-writing 测试显式禁用，应报告跳过；不要改写为全部测试已执行。生产媒体/Photos/Live Photo/StoreKit 与真机视觉仍采用各自验收矩阵。

## Xcode Cloud

已有 GitHub 集成使用共享 Scheme MemoMarkiOS 的 iOS Archive。新构建应指向含本检查点的 main 提交，并在 Cloud 设置中核对工具链、构建号和签名。Cloud 配置存于 Apple 服务，不能仅从项目文件推断现有设置或自动分发行为。源码同步完成后读取新提交上的 Xcode Cloud check；没有运行或未完成就如实标注。不得把旧提交成功记录当作新源码已在线构建成功。

Cloud Archive、App Store Connect 处理、TestFlight 可用和 App Store 发布是不同状态。此次仅授权 GitHub 完整源码同步；不手动触发上传、分发、购买、审核或正式发布。

## 研究代码和本地证据

Research 中的 Swift 探针、Python 分析工具和 HTML 方案保留完整历史。它们不在 App target，部分需按相应研究记录提供合成 fixture、测试附件或分析目录；不是生产构建前置步骤。原始设备截图/录屏、私人媒体、测试结果包、日志、签名产物留在本地。文档中的 $REPO_ROOT 为 clone 根目录，$HOME/本地证据路径仅为历史位置占位符，不是 CI 输入。

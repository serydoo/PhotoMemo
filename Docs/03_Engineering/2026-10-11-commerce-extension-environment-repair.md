# Share Extension 权益环境一致性修复

2026-10-11，Engineering Loop，P1。用户报告主程序显示已购买，要求重新安装最新包并处理 bug。最新现有 signed Release 2.3.6 (124) 已覆盖安装/启动，保留用户容器。

## 实施前决定

- 证据：设备共享 snapshot 为 sandbox / founderLifetime；Extension currentRuntime 只在 Bundle.main（appex）查 _MASReceipt，找不到会按 production 读取，环境隔离因此丢弃 sandbox 权益。尚需真机确认新 lookup 找到 App 收据。
- Owner：CommerceEnvironment 平台分发环境识别；StoreKit 是已验证权益事实来源，CommercePersistence 保持 strict environment 与订阅有效期检查。
- 范围：收据 URL 查找复用所属 App 的位置；仅规范 .app/PlugIns/.appex 允许上溯，拒绝任意祖先扫描。无 UI、购买流程、额度或历史身份改动。
- Apple 能力：本地 receipt 分发环境与 StoreKit verified AppTransaction；优先复用现有收据路径，若设备无 legacy receipt，继续以真实证据定位 StoreKit 2 环境差异，不接受共享缓存跨环境通行。
- 验证：先复现 extension enclosing App 收据和 production/no-receipt 隔离，focused commerce tests；签名 Release、覆盖安装/启动、真实 Share admission 读回。不重置用量、不发起购买。

## 验证进展

- 旧行为 red：`/tmp/MemoMarkCommerceReceiptRed20261011.xcresult`，新 enclosing-App 收据测试失败；其他原有持久化断言通过。
- 修复后 focused：`/tmp/MemoMarkCommerceReceiptGreen20261011.xcresult`，47 passed / 0 failed / 0 skipped，覆盖 persistence、policy、Store、share capacity、queue accounting。
- 保留 no-receipt Production safe default、Production 拒绝 Sandbox cache、过期订阅归一化、Xcode policy 隔离。未接受 cache.environment 替代运行分发环境，也未改 StoreKit entitlement verification。
- 收据只是分发环境事实，不是购买验证：Share 仍消费主 App 已验证的共享快照并检查有效期；不能仅凭 receipt URL 授予 Plus。

- 新签名 Release 编译、严格签名校验、覆盖安装/启动通过。完整 macOS：`/tmp/MemoMarkCommerceFixedFull20261011.xcresult`，2,099 passed / 1 existing skipped / 0 failed；979 Source/Tests 与 test mirror byte-equal。
- 首次新包真机 Share regression 在 Photos 选择模式取消失败（自动 hit point -1,-1），未到达扩展/权益判断，也未提交照片。Harness 补一次按已观察按钮 frame 中心重试；不以此失败判断修复结果。

## 真机反例扩展

第二轮已进入扩展，仍显示免费额度完成，表明 enclosing-App legacy receipt 不能建立当前 Sandbox 环境。根本差异是主 App 验证 StoreKit 2 AppTransaction，而 extension 仅采用旧式收据存在性。扩展范围：公共 CommerceEnvironment 增加只读 async verified AppTransaction resolver；confirmation 在读取后呈现容量；persist 再确认；Continued worker 独立验证同一环境。查询不进行 refresh/purchase/restore、不依赖 snapshot 环境冒充运行环境，失败仍回退已有 runtime safe default。UI 只增加读取前禁用确认并在取消/离开后防止旧 Task 更新；无新 copy 或交互入口。Apple 原生 SDK 确认 shared 可用于 extension，没有 iOSApplicationExtension unavailable 标记；官方 shared 文档说明需 verification 且可能抛错，保持失败路径。

## 当前闭环结果

- StoreKit 2 resolver red：`/tmp/MemoMarkCommerceStoreKit2Red20261011.xcresult`，缺失 verified environment precedence 的断言失败。
- 最终 full：`/tmp/MemoMarkCommerceStoreKit2Full20261011.xcresult`，2,100 passed / 1 existing skipped / 0 failed。四处 extension/common 接线由签名 Release 构建确认，保留 original main StoreKit refresh/expiry 策略。
- 最终 signed Release：`/tmp/MemoMarkCommerceStoreKit2Release20261011.log` exit 0，strict/deep codesign、覆盖安装、正常启动通过。版本仍 2.3.6 (124)；当前 local binary 不等于 Store 原包，没有发布或推送。
- 真机：`/tmp/MemoMarkCommerceStoreKit2Physical20261011.xcresult`，1 passed / 0 failed / 0 skipped。标准 Release UI test 从既有 QA Inputs 选择一张 JPEG，通过真实 Share 入口，QA Outputs 新增且只新增一个 asset；输出解码、尺寸检查、EXIF DateTimeOriginal（源存在时）及输入 SHA-256 前后相同均通过。提交后 host 一直非前台；这是 warm-background 场景，不是 cold-start 认证。测试保留新增 QA 输出。
- 测试后正常打开主 App，shared snapshot 仍 sandbox / founderLifetime / isPlus true。没有重置 production 或 Xcode 额度，没有购买/恢复/refresh 操作；解析仅调用只读 shared verification。
- 最终 979 Source/Tests 文件与 full-test mirror 一致。真实 production commerce、offline/不可验证 AppTransaction、到期/撤销真机、其他三样式/Live Photo/权限与长等待矩阵仍开放，当前单 JPEG PASS 不替代生产认证或编辑器 IME/undo 验收。
- Apple shared API 依据：[AppTransaction.shared](https://developer.apple.com/documentation/storekit/apptransaction/shared)，StoreKit 提供已签名 App transaction 与 verification result，获取可能失败；不调用 refresh。

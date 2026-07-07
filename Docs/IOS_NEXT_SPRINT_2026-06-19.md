# MemoMark iOS Next Sprint

Date: 2026-06-19

这份文档用于把时光记当前 iOS / 分享扩展方向，整理成后续 AI 或人工都能直接接着做的执行清单。

## Current Reality

当前已经具备：

- `PhotoMemoiOS` target 可构建
- `PhotoMemoShareExtension` target 可构建
- share extension 已缩到小型共享核心
- app-group 共享容器、共享默认配置、共享收件箱已经打通

当前还没有完成：

- 真实系统分享链路手动回归
- iPhone 端的产品级交互流程
- 分享完成后的后台处理反馈闭环
- 多来源输入下的完整元数据保留信心验证

## Sprint Goal

这一轮不要扩功能面，优先证明：

1. iOS 分享入口真实可用
2. 失败与部分成功语义对新手可理解
3. 主 app / share extension / shared intake 这三层责任边界继续保持清晰

## Recommended Order

### Slice 1. Real share-flow validation

目标：

- 验证“从系统分享进入时光记”在真实场景下能稳定写入共享收件箱

重点场景：

- `1张照片`
- `多张照片`
- `重复来源`
- `部分失效`
- `只有 raw data，没有 file representation`

验收：

- 至少一张成功时，share extension 不整体失败
- 共享收件箱里只出现去重后的有效输入
- 失败与跳过计数文案符合真实情况
- 不出现“成功 1 张，失败 0 张”这种不自然提示

### Slice 2. Flush-to-queue confirmation

目标：

- 验证主 app 启动或回到前台时，是否能正确 flush 共享收件箱请求

重点检查：

- 主 app 是否只入队仍然存在的文件
- 已失效文件是否被安全跳过
- 托管临时文件是否继续遵守“只清自己复制文件”的边界

验收：

- 无效请求不会污染主队列
- 有效请求能正常形成 batch job
- 不会误删用户原图路径

### Slice 3. Novice-user feedback tightening

目标：

- 补强用户能理解的失败/例外表达，而不是只让系统在内部“处理失败”

优先点：

- share extension 成功/部分成功/完全失败文案
- 主 app 中最新失败摘要的可读性
- 是否需要在帮助中心补一条“分享后去了哪里”的说明

验收：

- 用户能理解这次分享到底进了几张、跳过几张、失败几张
- 少量失败被表达为例外，而不是把整批任务说成全失败

### Slice 4. iPhone product shell

目标：

- 开始真正思考 iPhone 端日常使用模式，但仍不破坏当前主链

方向：

- 主界面仍保持“参数设定 + 自定义信息 + 预览”
- 进度不放在主界面中央
- 日常处理继续优先走分享入口 / 后台处理 / 通知反馈

验收：

- iPhone 不需要把 macOS 左右双栏原样搬过去
- 主工作流仍围绕设定、保存配置、分享进来、后台处理

## Explicit Non-Goals

这一轮不要优先做：

- 云同步
- 网络能力
- iPad 专项布局精修
- 模板数量扩张
- 为了兼容更多来源而偷偷重编码图片

## Critical Guardrails

后续 iOS / 分享入口开发时，继续守住：

- 不修改原图
- 不上传照片
- 不牺牲 EXIF 优先级换取表面兼容
- 不把主界面做成进度控制台
- 不让智能模块自动输出整句文案

## Suggested Verification Commands

```bash
xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemoShareExtension -configuration Debug -destination 'generic/platform=iOS Simulator' -derivedDataPath /tmp/PhotoMemoShareExtensionDerivedData CODE_SIGNING_ALLOWED=NO -quiet build
```

```bash
xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemoiOS -configuration Debug -destination 'generic/platform=iOS Simulator' -derivedDataPath /tmp/PhotoMemoIOSDerivedData CODE_SIGNING_ALLOWED=NO -quiet build
```

```bash
xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemo -configuration Debug -derivedDataPath /tmp/PhotoMemoDerivedData CODE_SIGNING_ALLOWED=NO -quiet build
```

## Best Immediate Follow-Up

如果下一个 AI 会话要直接继续做，建议提示它：

```text
继续时光记的 iOS / share extension 方向开发。
先读 AI.md、Docs/IOS_NEXT_SPRINT_2026-06-19.md、Docs/MANUAL_REGRESSION_CHECKLIST_2026-06-19.md、HANDOFF.md、Docs/CURRENT_STATUS.md。
优先做真实系统分享回归与失败语义补强，不要扩张功能面。
保持 local-first，不修改原图，不牺牲 EXIF，不把主界面变成进度面板。
```

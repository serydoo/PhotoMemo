# GlassCard 完整功能接入工作方案

2026-09-30。根据用户本轮要求，将静态保存与 Live Photo 纳入同一第四 renderer 接入目标，外观在集成过程中继续完善。开发基础已在 main 工作区，尚未提交。

## 代码核对

`RecordCardPresentationPlanner` 已提供统一的 outputPixelSize / content / artifact 注册点。媒体链路接受 `PresentationArtifact`（旧别名 FixedFooterOverlayDescriptor）。因此先让 GlassCard 生成既有 artifact，并沿用现有静态与 Live Photo 输出服务；不新增一套独立保存系统。当前只有三个正式 presentation style，GlassCard 仍需明确注册和配置传输契约。

## 落实顺序

1. 定义第四样式的配置与内容契约：独立样式标识；四位置继续承接既有自定义内容；默认值不限制字段含义；旧预设和旧输出不迁移。核对持久化、Production Snapshot、Batch Frozen Snapshot 与 Share 配置传输，避免只新增枚举造成漏接。
2. 将研究 renderer 拆分为正式 renderer 与 DEBUG 候选比较页；Layout 产生一次 resolved plan，预览与 artifact 消费同一字体、几何、内容和固定材质候选。统一处理空值与溢出。外观数值保留版本化候选记录，调整不改动内容意义。
3. 接入 planner 的预览与 artifact；复用现有新照片保存、EXIF/描述、相册选择与错误恢复。先确认静态全链路可用，再接 Live Photo。
4. 通过同一 artifact 接入既有 Live Photo 几何、视频合成、资源配对和 PhotoKit 保存服务。核对横竖方向、关键帧、音轨、配对标识、输出尺寸与色彩。此前普通 MOV 实验不作为配对验收；模拟器 CoreAnimation 异常须通过真机对照定位。
5. 按代码片段逐项审核并回流 main；完整 Debug 真机包核对四区域编辑、预览、静态保存、Live Photo 保存和 Photos 回读。真机观察继续指导研究分支的材质微调。

## 交付界限

合并可在外观微调完成前分批进行；静态保存和 Live Photo 属于同一个最终目标，但各自需要验证。尚未核对的输出能力不标记为完成。正式开放需满足项目现行生产契约和验收要求。

## 2026-09-30 本轮落实

完整 Debug 功能联调代码已接入 main 工作区；最终全量回归 1947 通过、1 跳过，模拟器 Debug/Release 与真机签名构建通过。iPhone 17 Pro Max 完整包已覆盖安装，启动等待手机解锁。真实 Photos/Live Photo 保存回读仍待手动核验。详见 `GlassCard-Full-Integration-Delivery-2026-09-30.md`。

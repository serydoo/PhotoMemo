# MemoMark 发布同步规范

## 1. 范围由用户指定

每一轮正式版本由产品负责人明确提供：

- 变更范围起点（日期时间、提交或上一正式候选）；
- marketing version；
- build number；
- 本轮是否仅准备、允许 Git 提交、允许推送、允许上传 TestFlight 或允许提交 App Store。

不得自行把更早的历史改动、未批准研究或下一轮计划并入当前版本。若时间点与提交之间没有完全重合，应记录采用的相邻提交和原因。

## 2. 先分类，再同步

工作区内容必须分成三类：

1. **正式同步范围**：产品代码、测试、双语资源、版本配置、已接受的产品/工程记录和发布说明。
2. **本地保留范围**：未冻结研究、私人照片/数据、实验资产、设备截图、归档包、签名产物和个人 Xcode 状态。
3. **待决定范围**：无法确认归属、验证不足或会改变架构/发布声明的内容。

只有第一类可进入发布提交；第二类不得暂存；第三类在获得明确决定前不得同步。

## 3. 四套说明使用同一事实源

发布说明必须先形成一份版本总表，再分别投影：

| 受众 | 内容边界 |
| --- | --- |
| 应用内“关于 -> 更新日志” | 面向普通用户的完整、温和、可长期查看说明 |
| App Store “此版本的新内容” | 最短的用户价值与隐私边界，不含测试术语 |
| TestFlight | 可执行的测试路径、反馈字段和隐私提醒 |
| 内部记录 | 构建号、提交范围、测试证据、风险编号、未关闭认证与同步授权 |

普通用户文案不得出现内部类型名、测试数量、Git/Xcode 细节、`TX-001`、`BP-001`、`FAIL (Conditional)` 或未经验证的绝对可靠性承诺。

## 4. 同步前检查顺序

1. 核对所有 App、Extension 与 Test target 的版本和构建号。
2. 核对应用内、App Store、TestFlight 和内部记录的版本、范围与承诺一致。
3. 运行双语键集合/格式检查、`git diff --check`、聚焦测试、完整测试和对应构建。
4. 将自动化、安装启动、真机手动路径、StoreKit/App Store Connect 与生产认证证据分开报告。
5. 检查 `git status`、diff 统计、未跟踪文件与本地排除项，形成明确暂存清单。
6. 只有在用户授权后，才按顺序执行暂存、提交、推送、TestFlight 上传和 App Store 提交。

## 5. 版本状态术语

- **Draft**：范围或文案仍在整理。
- **Version Locked; Release Evidence Open**：版本字段和说明已锁定，最终证据未完成。
- **Source Checkpoint Ready**：源码范围与基础验证清楚，可请求提交/推送授权。
- **TestFlight Candidate**：对应构建已归档上传，等待或正在测试。
- **App Store Candidate**：商店元数据与最终候选对应，仍不等于审核通过或正式发布。
- **Released**：App Store Connect 已确认正式版本可用；不得仅根据 Git 推送、构建成功或 TestFlight 可安装使用该状态。

## 6. 停止点

“整理”“准备同步”“准备发布”默认不授权 Git 提交、推送、上传或提交审核。每一项外部状态变更必须来自本轮明确授权；任一关键验证失败时，保留现场并回到 `Release Evidence Open`。

## 7. 每次同步的固定整理包

每一个版本同步都必须建立一个独立的版本总表，并使用同一版本号、构建号和事实范围生成以下四份材料：

1. `YYYY-MM-DD-VERSION-release-notes.md`：应用内完整更新说明与内部发布边界。
2. `YYYY-MM-DD-VERSION-app-store-whats-new.md`：简体中文和 U.S. English 的 App Store 文案。
3. `YYYY-MM-DD-VERSION-testflight-notes.md`：测试路径、反馈字段和隐私提醒。
4. `YYYY-MM-DD-VERSION-sync-manifest.md`：同步范围、排除范围、证据、风险、授权和停止点。

同时必须更新：

- `CHANGELOG.md` 的版本首段；
- `README.md` 的当前版本入口和发布说明链接；
- `Docs/CURRENT_STATUS.md` 的同步事件记录；
- 所有 App、Extension、Widget 和 Test target 的版本字段。

如果本轮没有面向用户的功能变化，也必须明确写出“修复性更新”“维护性更新”或“仅内部构建”，不得用空泛的“性能优化”代替事实。

## 8. 固定同步检查表

同步前必须逐项记录结果，不得只写“已检查”：

- [ ] 已确定版本范围起点、上一版本、marketing version 和 build number。
- [ ] 已检查工作区，并将文件分为正式同步、本地保留、待决定三类。
- [ ] App、Share Extension、Widget Extension 和 test target 的版本字段全部一致。
- [ ] 版本总表、应用内、App Store、TestFlight、CHANGELOG、README 和 CURRENT_STATUS 互相一致。
- [ ] 双语资源格式和键集合检查通过，或明确记录失败原因。
- [ ] `git diff --check` 通过。
- [ ] 聚焦测试、完整测试和构建结果分别记录；警告不得写成通过证据。
- [ ] 自动化、真机安装启动、手动关键路径、StoreKit、App Store Connect 和生产认证证据分开记录。
- [ ] 已核对未跟踪文件，确认没有私人照片、设备材料、归档包、签名产物或本地诊断进入同步范围。
- [ ] 已获得本轮明确的 Git 暂存、提交和推送授权。
- [ ] TestFlight 上传和 App Store 提交是否授权已单独确认，不由“同步”一词推断。

## 9. 固定执行顺序与交付状态

标准执行顺序固定为：

```text
整理事实源
-> 生成四份版本材料
-> 更新 CHANGELOG / README / CURRENT_STATUS / 版本字段
-> 运行检查与构建
-> 核对暂存清单
-> 用户授权后暂存
-> 用户授权后提交
-> 用户授权后推送
-> 如另有授权，再上传 TestFlight
-> 如另有授权，再提交 App Store
```

每次同步完成后，回复中必须包含：版本与构建号、提交号、推送分支、验证结果、未完成证据、是否上传 TestFlight、是否提交 App Store，以及对应材料链接。

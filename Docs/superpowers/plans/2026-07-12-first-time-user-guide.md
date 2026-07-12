# 时光记首次使用指南实施计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 基于当前 iOS 代码和真实界面，制作面向第一次打开用户的 App 内引导文案与可转发图文手册。

**Architecture:** 以 Markdown 内容母版作为唯一内容来源，截图资产独立存放，Word/PDF 从同一结构生成。首轮不修改已审核 App 源码，只交付可审阅文案、真实截图和发布手册。

**Tech Stack:** SwiftUI source inspection, Xcode/iOS Simulator, Markdown, python-docx/OOXML, LibreOffice/Poppler render QA.

---

### Task 1: 锁定真实操作路径

**Files:**
- Create: `Docs/UserGuide/FirstRunGuideCopy.md`
- Reference: `Source/PhotoMemo/PhotoMemo/iOS/Views/V1WelcomePresentation.swift`
- Reference: `Source/PhotoMemo/PhotoMemo/iOS/Views/V1HomePageSurface.swift`
- Reference: `Source/PhotoMemo/PhotoMemo/iOS/Views/PhotoMemoiOSV1View.swift`
- Reference: `Source/PhotoMemo/PhotoMemo/iOS/Views/V1SettingsPageSurface.swift`

- [x] 逐页记录当前真实按钮、页面名称和前置条件。
- [x] 写出五阶段 App 内引导文案和按钮文案。
- [x] 标出首轮仅建议、不直接落入 SwiftUI 的调整项。
- [x] 用 `rg` 检查禁用术语和日常路径一致性。

### Task 2: 采集真实界面

**Files:**
- Create: `Docs/UserGuide/Assets/FirstRun/*.png`

- [x] 构建 iOS Simulator Debug 版本并确认退出码为 0。
- [x] 启动可用模拟器，安装并运行 `PhotoMemo.app`。
- [ ] 使用虚构宝宝资料和仓库测试照片完成首次设置。
- [ ] 截取欢迎、首页、对象、配置中心、保存、任务、设置页面。
- [ ] 尝试截取 Apple Photos 分享和回存路径；不能验证的真机环节单独标记。
- [ ] 为公开截图增加编号、箭头和必要遮挡。

### Task 3: 撰写内容母版

**Files:**
- Create: `Docs/UserGuide/时光记-首次使用指南.md`

- [x] 写入 30 秒产品说明与隐私承诺。
- [x] 写入首次资料设置和保存配置步骤。
- [x] 写入 Apple Photos 日常分享路径。
- [x] 写入结果查找、20 张限制和兼容性边界。
- [x] 写入常见问题与反馈渠道。
- [x] 将当前可用真实截图按步骤嵌入母版。

### Task 4: 生成 Word 与 PDF

**Files:**
- Create: `Docs/UserGuide/时光记-首次使用指南.docx`
- Create: `Docs/UserGuide/时光记-首次使用指南.pdf`
- Create: `Docs/UserGuide/build_first_run_guide.py`

- [x] 加载 Codex 文档运行时与依赖路径。
- [x] 按 `compact_reference_guide` 数值令牌生成 Word。
- [x] 使用真实编号列表、明确页边距和固定图片宽度。
- [ ] 渲染 DOCX 为逐页 PNG 并检查中文、截图和分页。
- [ ] 从最终 DOCX 生成 PDF，再渲染 PDF 检查每一页。

### Task 5: 项目交接与最终验证

**Files:**
- Modify: `HANDOFF.md`

- [x] 记录新手指南交付物、模拟器证据和真机缺口。
- [ ] 运行链接、占位符、禁用术语和 `git diff --check` 检查。
- [ ] 列出已验证与尚未人工验证的内容。

# MemoMark Alpha UX Notes

Last updated: 2026-06-20

Use this file for subjective observations that are not necessarily bugs.

Good examples:

- "This step feels slow."
- "The wording is correct but still confusing."
- "The preview looks trustworthy, but save feedback feels weak."
- "I hesitated before tapping this button."

## Template

### ALPHA-UX-###

- Date:
- Flow:
- Observation:
- Why it feels off:
- Severity: Low / Medium / High
- Proposed simplification:
- Follow-up:

## Notes

### ALPHA-UX-001

- Date: 2026-06-20
- Flow: Share Extension Alpha-01
- Observation: 分享入口已经从“收件箱交接面”收成了单页确认面，用户现在能先看到照片数量、当前配置和结果去向，再决定继续。
- Why it feels off: 目前还是 intake-backed 路径，用户虽然更看得懂了，但还没有真实预览和生成完成反馈，心理闭环仍然偏弱。
- Severity: Medium
- Proposed simplification: 下一刀优先补单张图预览，不扩展到批量、多页面或复杂恢复。
- Follow-up: 真机从系统相册分享一张照片，观察是否还会在主按钮前犹豫。

### ALPHA-UX-002

- Date: 2026-06-20
- Flow: Alpha 0.8 Main App simplification
- Observation: 主界面去掉了多张说明卡片后，默认视线更容易落在照片、风格、时间点和输出上。
- Why it feels off: 帮助中心、风格管理和输出仍然在同一屏里，首次使用时信息密度已经下降，但还没有到“几乎无感”。
- Severity: Medium
- Proposed simplification: 继续把低频说明、背景状态和管理动作往后放，优先保证照片与预览成为视觉中心。
- Follow-up: 真机观察第一次打开时，是否还需要读很多字才敢操作。

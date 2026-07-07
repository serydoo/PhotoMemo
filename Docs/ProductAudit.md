# MemoMark Product Audit

Last updated: 2026-06-20

## Audit Scope

This audit reviews every currently visible product-facing page in MemoMark.

To keep the audit useful, UI elements are grouped by meaningful user-facing control clusters instead of listing every decorative text label separately.

For each element, four questions are answered:

1. Does the user really need this?
2. Can this be removed?
3. Can this become automatic?
4. Can this move into Settings?

## Core Judgment

MemoMark's biggest product opportunity is not more capability.

It is less surface.

The current product is already strong enough to start removing visible decision points.

The main app should continue shrinking into a configuration center.

The Share Extension should continue evolving toward an almost invisible workflow.

## Pages Reviewed

1. Main App configuration center
2. Main App preview tab / detail preview
3. Share Extension Alpha-01 confirmation page
4. Anchor list page
5. Anchor editor page
6. Permission panel and first-run permission sheet
7. Help center / operation guide
8. Background status sheet
9. Rename sheets and other low-frequency modal pages

---

## 1. Main App Configuration Center

| UI element | Need? | Remove? | Automatic? | Move into Settings? | Audit decision |
|---|---|---:|---:|---:|---|
| `从照片中选择` | Yes | No | No | No | Keep. This is the best calibration entry when users intentionally open the app. |
| `从文件导入` | Partial | Partial | No | No | Keep, but demote further. It should feel like a fallback, not a peer to Photos. |
| Photo metadata summary under importer | Yes | No | Already automatic | No | Keep. It builds trust that MemoMark is reading the real photo correctly. |
| Hero pills (`模板 / 时间点 / 图库`) | Partial | Yes | Yes | No | Compress or remove. These repeat state already visible elsewhere and add scanning cost. |
| iPhone `预览 / 编辑` segmented switch | Yes | Not yet | Remember last tab | No | Keep for now, but long-term one screen should solve one problem with less mode switching. |
| `配置工作区` panel header | Partial | Partial | No | Yes | Keep the concept, but rename toward `Default Style` and move most management actions out of the main workspace. |
| Three configuration slot cards | Yes | No | Partial | Yes | Keep multiple saved styles, but they should feel like style presets, not a workspace system. |
| Slot status text (`已保存 / 默认 / 当前使用...`) | Partial | Yes | Yes | No | Reduce copy. Most of this can be implied by active highlighting. |
| Slot `编辑` menu (`重命名 / 保存当前内容 / 恢复默认`) | Partial | Partial | Partial | Yes | Keep actions, but these are settings-level tasks, not part of the normal photo workflow. |
| `帮助中心` entry in workspace header | Partial | Partial | No | Yes | Keep help, but move it out of the primary workspace header over time. |
| Template section current-name card | Partial | Partial | No | Yes | Keep template naming, but the explanatory card is too heavy for a screen that should feel like settings. |
| `修改名称` | Partial | No | No | Yes | Keep, but this belongs in style settings, not on the main daily surface. |
| `恢复模板默认字段` | Partial | No | No | Yes | Keep as a recovery action, but demote into advanced style settings. |
| Anchor picker | Yes | No | Partial | Yes | Keep. A chosen time point is core product value. Eventually the picker can feel like a default-style field rather than a live workspace field. |
| `管理与编辑` time point button | Yes | No | No | Yes | Keep, but this is clearly a settings task. |
| Anchor explanation text | No | Yes | N/A | Yes | Remove from the main screen. The behavior should become self-evident, with deeper explanation living in Help. |
| Composer guide card | No | Yes | N/A | Yes | Remove after the interaction is cleaner. A main editing surface should not need a paragraph to explain itself. |
| `识别数据` variable strip | Yes | No | Partial | No | Keep. This is one of the few places where direct insertion still creates clear value. |
| `智能数据` variable strip | Yes | No | Partial | No | Keep, but reduce explanation and eventually prefer smarter defaults. |
| Four custom region editors | Yes | No | No | No | Keep. This is still the most important calibration surface in the main app. |
| Supplemental content guide card | No | Yes | N/A | Yes | Remove from the main surface; explanation belongs in Help. |
| Supplemental content single input | Partial | No | Already partly automatic | Yes | Keep one input, but conceptually this is an advanced style/output setting, not a daily control. |
| Supplemental content preview text | Partial | Partial | Yes | Yes | Collapse or move to advanced settings. Users rarely need a prose explanation of fallback logic. |
| `Logo 标识` picker and preview | Partial | Partial | Partial | Yes | Keep customization, but this is a style setting and should not dominate the main workflow. |
| Output album picker | Yes | No | Partial | Yes | Keep album default selection, but position it as an output preference, not a repetitive decision. |
| `保存新图到…` button in main app | Partial | No | No | No | Keep as a manual trust-building workflow, but continue demoting it relative to Share. |
| Output strategy explainer card | No | Yes | N/A | Yes | Remove from the main page. This is product policy, not a repeated user task. |
| iPhone save hint text | Partial | Yes | N/A | No | Remove once the flow itself makes the next step obvious. |

### Main App Verdict

The Main App still contains too much "explaining itself."

It should feel more like:

- choose default style
- edit style
- choose time point
- choose output defaults

It should feel less like:

- learn a workspace system
- read multiple guide cards
- manage low-frequency controls in the primary screen

---

## 2. Main App Preview Surface

| UI element | Need? | Remove? | Automatic? | Move into Settings? | Audit decision |
|---|---|---:|---:|---:|---|
| Preview canvas | Yes | No | N/A | No | Keep. Preview is still the trust-establishment surface inside the main app. |
| Preview header (`实时预览`) | Partial | Partial | N/A | No | Simplify. The canvas itself already communicates preview. |
| Preview summary card (`Live Context`) | Partial | Yes | Yes | No | Remove or collapse. Template name and anchor summary are redundant once the style model is clearer. |
| Separate preview tab on iPhone | Yes | Not yet | Remember last choice | No | Keep for now, but longer-term reduce page switching and make preview feel more integrated. |

### Preview Verdict

Preview should remain in the Main App for calibration and trust.

But its surrounding chrome should keep shrinking.

---

## 3. Share Extension Alpha-01 Confirmation Page

| UI element | Need? | Remove? | Automatic? | Move into Settings? | Audit decision |
|---|---|---:|---:|---:|---|
| Brand label `MemoMark` | Partial | Partial | N/A | No | Keep lightly branded, but this can become quieter over time. |
| Confirmation title and subtitle | Yes | No | Partial | No | Keep for Alpha. Later, when trust is established, most of this should disappear. |
| Shared photo count | Yes | No | Automatic data | No | Keep. Users need to know what this share action is about to process. |
| Current configuration name | Yes | No | Automatic data | Yes | Keep, but rename toward `Default Style`. Selection belongs in the main app. |
| Result destination summary | Yes | No | Automatic data | Yes | Keep. Users need confidence about where the result will go. |
| Status card (`继续后会发生什么`) | Yes | Partial | Yes | No | Keep for Alpha-01, then shorten aggressively in later stages. |
| Footer guidance about returning to main app | Partial | Yes | N/A | Yes | Too much explanation for the default path. Help text should not compete with the primary action. |
| Primary button `按当前配置继续` | Yes | Later yes | Later yes | No | Keep now. In Stage 3, this button should disappear and the workflow should auto-continue. |
| Failure title/message/suggestion | Yes | No | Partial | No | Keep. Failure is the moment where more words actually create value. |

### Share Verdict

Share Alpha-01 is the right intermediate step.

But the long-term target is still:

Photos -> Share -> Generate -> Save -> Done

The confirmation page is a trust-building bridge, not the final product shape.

---

## 4. Anchor List Page

| UI element | Need? | Remove? | Automatic? | Move into Settings? | Audit decision |
|---|---|---:|---:|---:|---|
| Empty state | Yes | No | N/A | No | Keep. |
| Anchor row title and summary | Yes | No | N/A | No | Keep. This is the core browsing surface for time points. |
| Tap row to select current anchor | Yes | No | N/A | No | Keep. |
| Separate `编辑` button per row | Yes | No | N/A | No | Keep, although swipe/context menus could reduce noise later. |
| Separate `设为当前` button | No | Yes | Yes | No | Remove. Tapping the row already performs the same job. |
| Toolbar `新建时间锚点` | Yes | No | N/A | No | Keep. |

### Anchor List Verdict

This page is useful, but it still has duplicate action affordances.

The clearest simplification is to remove `设为当前` as a separate button.

---

## 5. Anchor Editor Page

| UI element | Need? | Remove? | Automatic? | Move into Settings? | Audit decision |
|---|---|---:|---:|---:|---|
| Type picker | Yes | No | Partial | No | Keep. This changes how time is interpreted. |
| Title field | Yes | No | Partial | No | Keep, but seed smarter defaults more aggressively. |
| Date picker | Yes | No | No | No | Keep. |
| Explanatory paragraph about EXIF difference | Partial | Partial | N/A | Yes | Reduce or move to Help. |
| `计算方式` segmented control | Yes | No | Partial | No | Keep. This is a real product choice. |
| Helper text / scene examples / mode text / long sample scenario | Partial | Yes | Partial | Yes | Most of this should move to Help. The editor should focus on setting the anchor, not teaching the product at length. |
| Cancel / Save toolbar buttons | Yes | No | No | No | Keep. |

### Anchor Editor Verdict

The editor currently teaches too much inside the form itself.

Users mostly need:

- what is this called
- when is it
- is it past or future

Everything else can move to Help.

---

## 6. Permission Surfaces

| UI element | Need? | Remove? | Automatic? | Move into Settings? | Audit decision |
|---|---|---:|---:|---:|---|
| Inline permission section when not granted | Yes | No | Partial | No | Keep only while permissions are missing. |
| Separate rows for Photos and Notifications | Yes | No | Yes | No | Keep. These are the only two permissions users really need to understand. |
| Long permission descriptions | Partial | Partial | N/A | Yes | Shorten. The core reason matters; the long explanation can live in Help. |
| `允许访问` / `打开系统设置` | Yes | No | System-driven | No | Keep. |
| First-run permission sheet | Partial | Partial | Yes | No | Eventually request permissions just-in-time instead of front-loading a large primer. |
| Primer sheet educational copy | Partial | Yes | N/A | Yes | Too much reading for a best-case flow that should feel almost invisible. |

### Permission Verdict

Permission UI should keep moving toward:

- ask only when needed
- explain in one sentence
- disappear permanently once resolved

---

## 7. Help Center / Operation Guide

| UI element | Need? | Remove? | Automatic? | Move into Settings? | Audit decision |
|---|---|---:|---:|---:|---|
| Help center existence | Partial | No | N/A | Yes | Keep as a fallback, but move it out of the main workspace header over time. |
| Category navigation | Partial | Partial | N/A | Yes | Keep if help remains multi-topic, but not as a frequent top-level control. |
| Long topic introductions and bullet sections | Partial | Partial | N/A | Yes | Helpful for onboarding, but also evidence that the main UI is still too explanatory. |
| Per-section dismissible guide cards in main UI | No | Yes | N/A | Yes | Continue removing these from the main UI and keep the full explanation only here. |

### Help Center Verdict

The help center is useful as a safety net.

But every article it contains should also be treated as a design smell:

if users need this page often, the main UI is not simple enough yet.

---

## 8. Background Status Sheet

| UI element | Need? | Remove? | Automatic? | Move into Settings? | Audit decision |
|---|---|---:|---:|---:|---|
| Toolbar button to open background status | Partial | Partial | Notifications / Live Activity can replace part of it | Yes | Demote. This should not compete with the product's core flow. |
| Status hero card | Partial | No | Partial | No | Keep as the primary status summary if this page remains. |
| Count cards (`已完成 / 失败 / 总数`) | Partial | Partial | Yes | No | Collapse into the hero summary unless the user explicitly wants details. |
| Current processing focus card | Yes | No | Partial | No | Keep. This is the most human-readable operational detail. |
| `本批次配置` card | No | Yes | N/A | Yes | Too internal for most users. This feels like debug information. |
| Intake summary card | Partial | Yes | N/A | Yes | This is useful during engineering validation, but not a long-term primary product UI. |
| Timeline / recent records | Partial | Yes | N/A | Yes | Move to an advanced/debug layer if retained at all. |
| Retry failed items button | Yes | No | Partial | No | Keep. This is one of the few operational actions that directly helps users. |
| Latest failure card | Yes | No | Partial | No | Keep when failures exist. |
| Recent failure log list | Partial | Partial | N/A | Yes | Keep only in an advanced troubleshooting layer. |

### Background Status Verdict

This entire page should continue losing prominence.

MemoMark's ideal state is:

- notifications for passive awareness
- optional live status when needed
- a recovery page only when something actually went wrong

Not a dashboard users are expected to visit routinely.

---

## 9. Low-Frequency Modal Pages

| UI element | Need? | Remove? | Automatic? | Move into Settings? | Audit decision |
|---|---|---:|---:|---:|---|
| Configuration rename sheet | Partial | No | No | Yes | Keep, but this is clearly a settings task. |
| Template rename sheet | Partial | No | No | Yes | Keep, but move toward style settings. |
| Repeated explanatory copy inside rename sheets | No | Yes | N/A | Yes | Reduce. The action is simple and does not need much teaching. |

### Modal Page Verdict

These pages are legitimate, but they should be treated as administration surfaces.

They should not shape the user's mental model of the core product.

---

## Highest-Confidence Removals

These are the safest elements to remove or demote next:

1. Main-screen guide cards that explain composer, supplemental content, or output.
2. Main-screen hero pills that duplicate visible state.
3. Separate `设为当前` buttons in the anchor list.
4. Long educational copy inside the anchor editor.
5. Background-status configuration and intake-detail cards.
6. Help-center prominence inside the primary workspace header.

## Highest-Confidence Automations

These are the safest things to make more automatic next:

1. Remember the user's last iPhone tab or reduce the need for tabs altogether.
2. Treat style selection as a persistent default rather than an in-flow decision.
3. Turn the Share confirmation page into a shorter bridge on the way to zero-friction.
4. Move permission prompting closer to first real use instead of front-loading explanation.
5. Auto-seed more anchor names and modes from type choice.

## Highest-Confidence Moves Into Settings

These are the clearest candidates to move away from the daily surface:

1. Configuration rename and save-management actions.
2. Template rename and reset actions.
3. Badge / logo customization.
4. Supplemental content fallback behavior explanation.
5. Output strategy explanation and advanced metadata wording.
6. Help center and troubleshooting flows.

## Product Conclusion

MemoMark is at its best when it stops asking users to think like operators.

The Main App should increasingly feel like:

- style defaults
- time defaults
- output defaults

The Share Extension should increasingly feel like:

- invisible execution

The product should keep moving toward one standard:

The best MemoMark experience is the one users barely notice.

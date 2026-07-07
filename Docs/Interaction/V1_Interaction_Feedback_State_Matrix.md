# V1 Interaction Feedback State Matrix

Last updated: 2026-07-07

## Status

```text
Implemented
```

Implemented in the 2026-07-07 V1 interaction feedback unification slice.

## Purpose

This document defines the canonical state mapping for the V1 interaction
feedback unification project.

Every user-facing feedback surface should derive from this matrix:

- Share / open-with handoff
- Live Activity
- Dynamic Island
- notifications
- task page
- background status page

## Canonical States

| State | Meaning | User Needs Action |
| --- | --- | --- |
| `已接收` | PhotoMemo has accepted the incoming share request. | No |
| `准备中` | PhotoMemo is verifying files or preparing media prerequisites. | No |
| `处理中` | PhotoMemo is actively generating or saving results. | No |
| `已完成` | All intended supported photos finished successfully. | No |
| `部分完成` | Some photos finished; some still need attention. | Maybe |
| `需处理` | The batch requires a return to PhotoMemo for details or retry. | Yes |
| `暂不支持` | The input is outside the current supported capability envelope. | Maybe |

## Cross-Surface Mapping

### `已接收`

- Share title:
  - `已接收 3 张照片`
- Share detail:
  - `PhotoMemo 会按当前配置继续处理。`
- Live Activity:
  - not usually shown for long; transitions quickly to `准备中`
- Notification:
  - not used as a final result state
- In-app:
  - queue has been created and is waiting to proceed

### `准备中`

- Share title:
  - `正在准备原图`
- Share detail:
  - `系统正在准备可处理的照片内容。`
- Live Activity primary line:
  - `正在准备照片`
- Live Activity detail:
  - `读取原图与处理信息`
- Notification:
  - not used as a final result state
- In-app:
  - visible as early queue progress

### `处理中`

- Share title:
  - `正在交给 PhotoMemo`
- Share detail:
  - `主程序会继续处理并写回系统相册。`
- Live Activity primary line:
  - `正在生成记忆卡片`
- Live Activity detail:
  - current file or queue summary
- Notification:
  - not used as a final result state
- In-app:
  - active progress, current phase, current file, queue context

### `已完成`

- Share title:
  - `已交给 PhotoMemo`
- Share detail:
  - `完成后结果会回到系统相册。`
- Live Activity primary line:
  - `处理已完成`
- Live Activity detail:
  - `结果已写回系统相册`
- Notification title:
  - `09:12 处理 3 张照片已完成`
- Notification body:
  - `已保存到「PhotoMemo」。`
- In-app:
  - latest batch completed, no attention needed

### `部分完成`

- Share:
  - not usually final inside Share
- Live Activity primary line:
  - `部分照片已完成`
- Live Activity detail:
  - `仍有 1 张需要回到 PhotoMemo 查看`
- Notification title:
  - `09:12 已完成 8 张，1 张需处理`
- Notification body:
  - `大部分结果已保存，剩余项目可回到 PhotoMemo 查看。`
- In-app:
  - completed items stay saved; attention items remain visible

### `需处理`

- Share title:
  - `这次分享需要查看`
- Share detail:
  - `可以重新交给 PhotoMemo，或直接打开主程序继续。`
- Live Activity primary line:
  - `有照片需要处理`
- Live Activity detail:
  - `请回到 PhotoMemo 查看原因`
- Notification title:
  - `09:12 2 张照片需要处理`
- Notification body:
  - `请回到 PhotoMemo 查看原因并重试。`
- In-app:
  - detailed reason, phase, retry availability

### `暂不支持`

- Share title:
  - `这次分享里没有可处理照片`
- Share detail:
  - `当前版本暂不支持这类图片。`
- Live Activity primary line:
  - `这批照片暂不支持处理`
- Live Activity detail:
  - `请改用当前支持的静态照片格式`
- Notification title:
  - generally avoid as a final queue notification unless the batch actually
    entered processing
- In-app:
  - show unsupported reason instead of generic failure

## Result Classification Rules

### Final State Selection

Use these rules in order:

1. If all failed items are unsupported input and nothing completed:
   - `暂不支持`
2. If some completed and some failed:
   - `部分完成`
3. If any failed and nothing completed:
   - `需处理`
4. If all intended items completed:
   - `已完成`
5. If the batch is still validating or waiting for files:
   - `准备中`
6. If the batch is actively progressing:
   - `处理中`

## Detail-Layer Rules

### Share

- shortest copy
- explain what will happen next
- no deep failure reasons unless the handoff itself failed

### Live Activity

- one dominant state line
- one supporting detail line
- never more than one actionable idea

### Notification

- line 1 = result
- line 2 = destination or next action

### In-App

- may include phase
- may include reason
- may include retry guidance
- may include unsupported specifics

## Copy Rules

- Prefer `需处理` over `失败`
- Prefer `暂不支持` over `无法处理`
- Prefer `已接收` over `已提交`
- Prefer `结果已写回系统相册` over engineering-language summaries
- Only promise retry when retry is truly available

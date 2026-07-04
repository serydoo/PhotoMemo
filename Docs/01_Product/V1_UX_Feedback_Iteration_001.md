# V1 UX Feedback Iteration 001

Status: `Implemented`

Primary Source: `Product`

Principle:

> The Configuration Center should become lighter, not fuller.

## Implemented

1. `记忆对象切换后，时间锚点标题未刷新`
   - fixed in the live V1 iOS path
   - current anchor title, formula presentation, and preview-side anchor date now follow the selected subject instead of a stale hardcoded label

2. `概览区域重新组织`
   - overview now focuses on current state
   - `主体身份` remains first
   - `当前生效时间锚点` is promoted as the highlighted state row
   - `时间锚点数量` removed from the overview surface

3. `删除关系类型`
   - removed from the V1 subject editor
   - removed from the V1 subject overview identity surface

4. `删除对象定义`
   - removed from the V1 subject editor flow

5. `当前锚点名称 -> 自定义锚点名称`
   - updated in the V1 subject editor

6. `删除重复展示的当前表述公式`
   - removed the separate gray current-selection block from the time-anchor editor

7. `表达公式区域重新布局`
   - time-anchor formula selection now uses a single inline row:
   - left label: `请选择表达公式`
   - right side: menu selector

8. `删除无效辅助信息`
   - removed `行为映射` section from the V1 subject editor
   - removed extra anchor-type helper copy from the time-anchor editor
   - removed the V1-side editable `锚点说明` field from this surface

## Deferred

- `P2 表达公式语言体系重做`
  - recorded only
  - not included in this iteration

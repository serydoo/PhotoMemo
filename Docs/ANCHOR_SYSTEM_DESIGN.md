# PhotoMemo 时间锚点系统设计

## 定位

`时间锚点` 不只是一个模板变量，而是 `PhotoMemo` 的照片语义系统。

照片原本只有：

- 拍摄时间
- 设备信息
- EXIF 参数

加入锚点以后，照片会多出一层解释：

- 这张照片发生在某个重要人生节点之后多久
- 这张照片发生在某个目标事件之前多久
- 这张照片处于哪个阶段
- 这张照片和谁、和什么事件有关

这会让 `PhotoMemo` 从“照片底部加信息”升级成“给照片加人生坐标”。

---

## 目标

本设计文档有两个目标：

1. 定义一套稳定的锚点语义体系，统一智能模块命名、输出格式和适用场景。
2. 结合当前代码，明确这套体系如何深入嵌入现有工程，而不是另起炉灶。

---

## 当前代码现状

当前项目已经具备一套可工作的锚点基础链路，主要分布如下：

- 模型入口
  - [Anchor.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/Models/Anchor.swift)
  - 当前字段：`type`、`title`、`date`、`isCountdown`
- 计算结果
  - [AnchorResult.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/Models/AnchorResult.swift)
  - 当前字段：`primaryText`、`secondaryText`、`summaryText`、`ageText`、`durationText`、`countdownText`、`elapsedText`、`dayIndexText`、`weekText`、`monthAgeText`、`milestoneText`、`years/months/days`、`totalDays`
- 计算引擎
  - [AnchorEngine.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/Engines/AnchorEngine.swift)
  - 当前负责：过去时长、未来倒计时、年龄文本、纪念文本
- 变量映射
  - [CardVariableProvider.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/Models/CardVariableProvider.swift)
  - 当前已暴露：
    - `anchor_title`
    - `anchor_primary`
    - `anchor_secondary`
    - `anchor_summary`
    - `anchor_smart_text`
    - `anchor_countdown_text`
    - `anchor_age_text`
    - `anchor_duration_text`
    - `anchor_total_days_text`
    - `anchor_elapsed_text`
    - `anchor_day_index_text`
    - `anchor_week_text`
    - `anchor_month_age_text`
    - `anchor_milestone_text`
    - `anchor_years/months/days`
- 智能模块定义
  - [TemplateVariable.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/Models/TemplateVariable.swift)
  - [TemplateItem.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/Models/TemplateItem.swift)
- 配置 UI
  - [AnchorEditorView.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/Views/Anchor/AnchorEditorView.swift)
  - [AnchorListView.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/Views/Anchor/AnchorListView.swift)
- 使用入口
  - [MainView.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/Views/Main/MainView.swift)

结论：

- 当前结构已经适合做 `V1 锚点语义系统`
- 不需要推翻重来
- 只需要在现有模型上继续扩层

---

## V1 语义分层

建议把锚点系统固定成 3 层：

### 1. 事件层

定义“这是什么时间点”。

当前已覆盖：

- 出生 / 生日
- 恋爱开始
- 结婚纪念
- 高考 / 毕业 / 未来目标
- 自定义事件

建议继续统一理解为：

- `birth`
- `relationship`
- `marriage`
- `goal`
- `custom`

当前代码里可以继续沿用 `AnchorType`，只是语义上要更明确。

### 2. 关系层

定义“照片和锚点是什么关系”。

V1 只需要两类：

- `过去`
- `未来`

当前代码里其实已经存在：

- `isCountdown == false` -> 过去
- `isCountdown == true` -> 未来

这层负责决定输出：

- 年岁
- 纪念时长
- 已过天数
- 倒计时
- 自动摘要

### 3. 角色层

定义“这张照片是谁的、谁拍的、和谁有关”。

这层当前代码还没有正式建模，但产品价值很高，适合作为下一阶段扩展：

- `拍摄者`
- `陪伴者`
- `主体`

例如：

- 爸爸视角记录
- 妈妈拍下的第 100 天
- 和奶奶一起的第一次旅行

---

## V1 时间结果模块命名规范

以下是建议固定下来的 V1 时间结果模块。

| 展示名 | Token | 使用方向 | 输出格式 | 典型场景 |
| --- | --- | --- | --- | --- |
| 年岁 | `{{anchor_age_text}}` | 过去 | `X岁X月X天` | 宝宝成长、宠物到家、成长节点 |
| 纪念时长 | `{{anchor_duration_text}}` | 过去 | `X年X个月X天` | 恋爱、结婚、搬家、毕业、入职 |
| 天数值 | `{{anchor_total_days_text}}` | 过去 | `XX天` | 只想插入纯天数 |
| 已过天数 | `{{anchor_elapsed_text}}` | 过去 | `已过XX天` | 纪念日、打卡、关系时长 |
| 倒计时 | `{{anchor_countdown_text}}` | 未来 | `还有XX天` | 高考、毕业、婚礼、旅行出发 |
| 第几天 | `{{anchor_day_index_text}}` | 过去 | `第XX天` | 宝宝第几天、项目第几天 |
| 周数 | `{{anchor_week_text}}` | 过去 | `XX周X天` | 孕周、成长周数、计划进度 |
| 月龄 | `{{anchor_month_age_text}}` | 过去 | `XX个月` | 宝宝月龄、宠物月龄 |
| 里程碑 | `{{anchor_milestone_text}}` | 过去 / 未来 | `100天` / `1周年` / `还有30天` | 满月、百天、周年、特殊倒计时节点 |
| 智能结果 | `{{anchor_smart_text}}` | 自动 | 自动选择最贴切的结果 | 不想手动区分时使用 |
| 时间点名称 | `{{anchor_title}}` | 通用 | 锚点标题 | 搭配自定义前后缀 |
| 通用结果 | `{{anchor_primary}}` | 通用 | 当前场景主结果 | 内部汇总用 |
| 锚点日期 | `{{anchor_secondary}}` | 通用 | 锚点日期 | 说明补充 |
| 完整摘要 | `{{anchor_summary}}` | 通用 | 一整句摘要 | 快速预览 |

### 命名原则

- 模块只输出 `时间结果本身`
- 完整句子由用户在前后自由补字
- 计算层和表达层彻底分离

例如：

- `途途今天` + `{{anchor_age_text}}`
- `距离高考` + `{{anchor_countdown_text}}`
- `来到这个世界` + `{{anchor_day_index_text}}`

---

## V1 输出规则

### 过去锚点

#### 年岁

规则：

- 固定输出 `X岁X月X天`
- 即使某一位为 0，也保留

示例：

- `0岁10月30天`
- `1岁0月0天`
- `3岁2月5天`

适用：

- 出生后多久
- 宝宝成长
- 宠物到家后多久
- 某个生活阶段开始后多久

#### 纪念时长

规则：

- 固定输出 `X年X个月X天`
- 强调“时长”而不是“年龄”

示例：

- `0年10个月30天`
- `1年0个月0天`
- `7年3个月12天`

适用：

- 恋爱
- 结婚
- 搬家
- 入职
- 创业
- 毕业后多久

#### 已过天数

规则：

- `{{anchor_total_days_text}}` 只输出纯天数
- `{{anchor_elapsed_text}}` 保留最小方向语义

示例：

- `30天`
- `328天`
- `1000天`
- `已过30天`
- `已过328天`

适用：

- 打卡
- 成长第几天
- 纪念第几天
- 项目第几天

#### 第几天

规则：

- 固定输出 `第XX天`
- 用于强调阶段序号，而不是时长语气

示例：

- `第1天`
- `第128天`

#### 周数

规则：

- 固定输出 `XX周X天`
- 整周时输出 `XX周`

示例：

- `3周2天`
- `24周`

#### 月龄

规则：

- 固定输出 `XX个月`
- 适合比“年岁”更偏婴幼儿表达的场景

示例：

- `6个月`
- `38个月`

### 未来锚点

#### 倒计时

规则：

- 保留最小方向语义
- 固定输出 `还有XX天`

示例：

- `还有30天`
- `还有7天`
- `还有100天`

适用：

- 高考
- 毕业
- 婚礼
- 旅行出发
- 演唱会
- 预产期

### 自动结果

#### 智能结果

规则：

- 出生类优先走 `年岁`
- 纪念类优先走 `纪念时长`
- 倒计时类优先走 `倒计时`
- 命中特殊节点时优先走 `里程碑`
- 日数特别重要时可退化为 `已过XX天`

适用：

- 用户不想理解模块区别
- 快速生成默认模板

---

## 场景矩阵

### 成长类

- 今天 `{{anchor_age_text}}`
- 来到这个世界 `{{anchor_day_index_text}}`
- 当前月龄 `{{anchor_month_age_text}}`
- 距离上小学 `{{anchor_countdown_text}}`

### 纪念类

- 我们已经一起 `{{anchor_duration_text}}`
- 领证后 `{{anchor_elapsed_text}}`
- 领证后的 `{{anchor_day_index_text}}`
- 从 `{{anchor_title}}` 到今天

### 目标类

- 距离高考 `{{anchor_countdown_text}}`
- 距离毕业 `{{anchor_countdown_text}}`
- 距离旅行出发 `{{anchor_countdown_text}}`

### 回望类

- 这一刻，距离那天已经 `{{anchor_duration_text}}`
- 这一刻已经 `{{anchor_elapsed_text}}`
- 回头看，已经走了 `{{anchor_summary}}`

---

## 当前代码可以直接承接的部分

当前代码已经可以稳定承接以下能力：

- 单锚点模型
- 过去 / 未来二分类
- EXIF 拍摄时间差值计算
- 智能变量注入到模板上下文
- 预览实时渲染
- 输出到图片元数据说明文本

这意味着以下需求不需要重构架构，直接可以继续往里长：

- 年岁固定格式
- 天数值 / 已过天数
- 倒计时
- 第几天
- 周数
- 月龄
- 基础里程碑
- 智能结果命名收口
- 更清晰的锚点类型引导
- 更多模板文案

---

## 当前默认模板建议

为了让用户恢复默认字段后就能直接看到真实效果，当前 3 套默认模板建议固定为：

- 模板 1：成长纪念
  - 左上默认：`{{title}}`
  - 右下默认：`今天{{anchor_age_text}}`
- 模板 2：纪念时长
  - 左上默认：`{{title}}`
  - 右下默认：`已经{{anchor_duration_text}}`
- 模板 3：未来倒计时
  - 左上默认：`{{title}}`
  - 右下默认：`{{anchor_countdown_text}}`

这样做的好处是：

- 新用户不需要先理解全部 token
- 恢复默认字段后就能马上看到真实语义结果
- 右下区域同时可直接复用为相册说明文本

---

## 下一步值得新增的字段

以下字段适合做 `V2`，并且都能自然接入现有 `AnchorResult -> CardVariableProvider -> TemplateVariable` 结构。

### 强推荐

| 字段 | 说明 | 示例 |
| --- | --- | --- |
| `anchor_direction` | 过去 / 未来 | `past` / `future` |
| `anchor_relation` | 和锚点的关系文案 | `出生后` / `恋爱后` / `婚礼前` |
| `anchor_total_weeks` | 总周数 | `42` |
| `anchor_total_months` | 总月数 | `10` |
| `anchor_milestone_label` | 里程碑标签 | `满月` / `百天` / `1周年` |
| `anchor_phase_label` | 阶段标签 | `孕中期` / `高三冲刺` / `幼儿园阶段` |

### 角色增强

| 字段 | 说明 |
| --- | --- |
| `anchor_actor` | 谁拍的 |
| `anchor_companion` | 和谁一起 |
| `anchor_subject` | 主体是谁 |

### 事件增强

| 字段 | 说明 |
| --- | --- |
| `anchor_event_index` | 第几次事件 |
| `anchor_week_index` | 第几周 |
| `anchor_year_index` | 第几年 |

---

## 深度嵌入当前代码的方式

下面是建议的嵌入策略，不需要另起一套系统。

### 1. Anchor.swift

当前：

- `type`
- `title`
- `date`
- `isCountdown`

建议下一步增加可选字段：

- `actor`
- `companion`
- `subject`
- `eventIndexRule`

原则：

- 保持兼容
- 新增字段全部设为可选
- 不破坏已存档的本地数据

### 2. AnchorResult.swift

当前已经有：

- `ageText`
- `durationText`
- `years/months/days`
- `totalDays`

建议新增：

- `direction`
- `relationText`
- `totalWeeks`
- `totalMonths`
- `milestoneLabel`
- `phaseLabel`

理由：

- `AnchorResult` 是最适合承载锚点语义结果的中间层
- 不应该让 UI 或模板变量自己再拼业务逻辑

### 3. AnchorEngine.swift

当前职责已经正确，下一步继续加强即可：

- 统一格式化规则
- 增加周 / 月总量计算
- 增加里程碑判断
- 增加阶段标签判断

建议继续把所有“语义计算”放在这里，避免散到 `MainView` 或渲染层。

### 4. CardVariableProvider.swift

这是当前最关键的桥接层。

建议未来所有新增锚点字段，都统一在这里映射到：

- `MetadataContext`
- 模板变量 token
- 导出说明文本

这样模板系统无需知道业务计算细节。

### 5. TemplateVariable.swift / TemplateItem.swift

这里负责“用户看见什么智能模块”。

建议规范：

- 用户看见的是语义名
- 代码内部保持 token 稳定

例如：

- 展示名：`年岁`
- Token：`{{anchor_age_text}}`

不要频繁更改 token，只调整展示文案和说明文字。

### 6. AnchorEditorView.swift

下一步可以继续增强：

- 事件类型更明确
- 过去 / 未来解释更直观
- 未来加入角色字段输入

但原则是不让它变成复杂表单。

锚点编辑器应该仍然是：

- 轻量
- 一次只做一件事
- 更像系统设置页，而不是数据库编辑器

### 7. MainView.swift

当前主要负责：

- 显示智能数据模块
- 让用户插入 token
- 即时预览

这里不适合继续堆业务计算。

建议以后只做：

- 模块展示
- 插入交互
- 说明文案

不做：

- 复杂锚点判断
- 里程碑算法
- 事件关系拼接

---

## 优先级建议

### P0：已经具备 / 正在稳定

- 年岁
- 纪念时长
- 天数值 / 已过天数
- 倒计时
- 第几天
- 周数
- 月龄
- 智能结果

### P1：最值得接着做

- `anchor_direction`
- `anchor_total_weeks`
- `anchor_total_months`
- `anchor_milestone_label`
- 更清晰的事件类型命名

### P2：产品差异化增强

- `anchor_actor`
- `anchor_companion`
- `anchor_phase_label`
- `anchor_event_index`

### P3：高级玩法

- 多锚点并存
- 自动推荐锚点
- 里程碑自动切模板
- 系列回顾分组导出

---

## 结论

`PhotoMemo` 的锚点系统已经不适合再按“单个变量”理解。

更准确的定位应该是：

- 锚点是事件
- 照片是时间切片
- 智能模块是事件和照片之间关系的输出

当前工程已经具备承接这套系统的基础结构。

最合适的推进方式不是重做，而是沿着现有链路继续加深：

- `Anchor`
- `AnchorResult`
- `AnchorEngine`
- `CardVariableProvider`
- `TemplateVariable`

只要这条链路继续保持清晰，`PhotoMemo` 就会从“参数信息卡片”逐步升级成“人生节点照片解释器”。

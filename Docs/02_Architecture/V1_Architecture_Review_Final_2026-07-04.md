# V1 收口与 IA-003 迁移架构审查结论

| Item | Value |
| --- | --- |
| **Status** | Accepted |
| **Scope** | V1 Closure / IA-003 Migration |
| **Architecture Phase** | Convergence |
| **Decision** | Freeze Renderer / Complete Production Freeze Line |
| **Next Review** | After IA-003 Completion |

---

# Executive Summary

当前代码已经具备**可维护、可发布**的 V1 架构基础。

Renderer 应继续作为锁定的 V1 输出合同（Output Contract），不作为当前阶段的架构演进重点。

后续工作重点不应继续投入 Renderer 或 UI 架构重构，而应聚焦 IA-003 生产冻结线建设：

> 提交阶段冻结完整 Memory 配置；
>
> 生产阶段仅消费冻结输入；
>
> 建立可验证、可复现的生产流水线。

本次审查认为，PhotoMemo 当前已经进入 **Architecture Convergence** 阶段。后续工作应围绕冻结输入、唯一事实来源（Single Source of Truth）以及生产消费边界持续收敛，而不是继续引入新的运行期状态或新的配置模型。

# Review Scope

本次审查覆盖：

- V1 Production Pipeline
- Configuration Center
- Memory Engine
- Renderer Boundary
- Workspace Session
- Snapshot Pipeline
- Production Configuration
- Preview Contract
- Architecture Naming

不涉及：

- Renderer 功能扩展
- 多边框 Layout
- V2 UI Evolution
- 新功能设计

# Architecture Assessment

## 已完成收敛

本轮审查确认以下架构边界已达到 V1 发布要求：

- Renderer 已形成稳定 Output Contract。
- Render Contract 不建议继续开放。
- Configuration Center 已完成 IA-003 基础接入。
- Memory Engine 已建立独立入口。
- V1 Production Pipeline 可正常工作。
- Build、Debug、Git 状态正常。
- 当前代码整体具备可维护、可发布基础。

## 当前主要演进方向

当前项目的架构重点已经发生变化。

不再继续围绕：

- Renderer 重构
- UI 架构迁移
- View 拆分

而应聚焦：

> Production Freeze Line

即：

```text
Submit
    ↓
Freeze
    ↓
Build
    ↓
Render
    ↓
Export
```

所有 IA-003 后续工作均应围绕上述生产流水线持续收敛。

# Priority Assessment

## P0

### 1. Production Freeze

冻结：

- MemorySubject
- MemoryBehavior
- ConfigurationSnapshot

确保提交时的 Memory 配置成为生产阶段唯一事实来源（Single Source of Truth）。

生产链路不得重新读取运行期配置。

### 2. Memory Engine Semantic Boundary

Memory Engine 应输出：

```text
MemoryResult
```

Presentation 层负责：

- 文案组合
- 最终表达
- 用户可配置句式

避免 Memory Engine 成为最终句子生成器。

## P1

### 1. Snapshot Convergence

逐步收敛：

- BatchConfigurationSnapshot
- ConfigurationSnapshot

建立唯一生产 Snapshot。

BatchConfigurationSnapshot 最终应退化为 Legacy / Transport DTO。

### 2. Production Pipeline Purity

生产流水线应逐步移除：

- live UserDefaults
- 当前 Profile
- 运行期配置读取

避免：

```text
Current State
    ≠
Frozen State
```

### 3. Naming Freeze

IA-003 完成后统一配置体系语言。

重点包括：

- Workspace
- Template
- Profile
- Preset
- MemorySubject
- ConfigurationCenter

避免历史命名长期共存。

## P2

### 1. Build Coordinator Boundary

限制 RecordCardBuildService 继续吸收：

- Metadata Logic
- Memory Logic
- Profile Logic

保持其作为：

- Coordinator
- Assembly Point

的职责边界。

### 2. Preview Contract

最终统一：

```text
Configuration Preview
```

与

```text
Renderer Output
```

之间的语义合同。

避免长期产生 Preview / Export 漂移。

### 3. Engineering Hygiene

包括：

- 空文件
- Preview Stub
- Legacy Naming
- Dead Code

属于工程卫生，不影响 V1 发布。

# Governance Principle

本次审查冻结以下治理原则：

> **新增能力可以增加 Contract，不应该增加新的 Truth。**

后续所有 IA-003 与 V2 开发均应遵循：

```text
Submit
    ↓
Freeze
    ↓
Consume
```

任何新功能均不应：

- 绕过冻结配置；
- 引入新的事实来源；
- 在生产阶段重新读取运行期状态。

# IA-003 Completion Criteria

IA-003 完成不以功能数量判断，而以生产流水线是否完成冻结配置驱动闭环判断。

IA-003 进入完成态前，应满足：

- Production Pipeline 仅消费冻结输入。
- Memory Engine 输出结构化 `MemoryResult`，不直接生成最终表达。
- `ConfigurationSnapshot` 成为唯一生产 Snapshot。
- `BatchConfigurationSnapshot` 退化为 Legacy / Transport DTO。
- Production Pipeline 不再依赖运行期 `UserDefaults`。
- Naming Freeze 完成，配置体系语言统一。
- Renderer Contract 保持稳定，无新增运行期状态依赖。

# IA-003 Execution Principle

IA-003 的目标不是产生新的架构，而是完成既定架构的收敛。

除非 IA-003 Completion Criteria 明确要求，否则不再启动新的架构重构。

除非出现新的 ADR 或 IA-003 Completion Criteria 发生变化，否则本 Architecture Review 文档不再继续扩展。

IA-003 后续工作应被视为 **Domain Model Convergence**，而不是 UI、Renderer 或泛架构重构。

执行顺序应保持：

1. **Freeze Contract**：冻结 `MemoryResult` 的语义边界和数据结构。
2. **Implement**：修改 Memory Engine 输出结构化结果。
3. **Migrate**：让调用方逐步消费 `MemoryResult`。
4. **Remove Legacy**：删除旧字符串输出和不再需要的 Adapter。

`MemoryResult` Contract 应回答：

> Memory Engine 知道了什么？

而不是：

> 界面最终要显示什么？

因此，`MemoryResult` 应保持：

- 纯语义：不包含最终展示文案。
- 可组合：Presentation 可自由组合不同模板或语言。
- 可扩展：新增周年、节日、成长阶段等能力不破坏已有字段语义。
- 可序列化：可稳定用于缓存、导出、测试与回归验证。

# IA-003 Milestones

| Milestone | Status | Scope |
| --- | --- | --- |
| Production Freeze Line Phase 1 | ✅ Complete | Frozen `MemorySubject` / frozen `ConfigurationSnapshot` / resolver prefers frozen input. |
| Structured `MemoryResult` | 🟡 Next | Freeze contract, output pure semantics, move final expression to Presentation. |
| Snapshot Convergence | 🟡 Next | Establish single production Snapshot and complete `Submit -> Freeze -> Consume`. |

# Snapshot Convergence Done

Snapshot Convergence 完成前应满足：

- `ConfigurationSnapshot` 成为生产流水线唯一事实来源。
- `BatchConfigurationSnapshot` 不再承载新的领域语义。
- Adapter 仅负责兼容历史入口，不新增职责。
- 新功能不得直接扩展 `BatchConfigurationSnapshot`。

# Architecture Impact Check

后续 IA-003 改动应在评审中回答：

| Item | Expected |
| --- | --- |
| New Runtime State Introduced | No |
| New Truth Introduced | No |
| Bypasses Frozen Input | No |
| Production Pipeline Changed | Yes / No |
| Architecture Review Update Required | Yes / No |

# Final Assessment

PhotoMemo 当前不是缺少更多重构，而是需要完成 IA-003 的最后收口：

- 冻结输入；
- 结构化 Memory 语义；
- 唯一事实来源；
- 生产消费边界。

完成上述收口后，项目将完成从：

> **运行期配置驱动**

向

> **冻结配置驱动**

的架构转换。

届时，V1 的架构重点将正式从**持续架构迁移**转向**稳定合同演进**。

后续功能扩展应建立在既有 Contract 之上，而不是重新引入新的运行期状态。

# Architecture Checklist

后续所有 Architecture Review 均建议检查以下三项：

| Check | Question |
| --- | --- |
| **Submit** | 是否完成配置冻结？ |
| **Freeze** | 是否保持唯一事实来源（Single Source of Truth）？ |
| **Consume** | 生产链路是否仅消费冻结输入？ |

# Review History

| Version | Date | Summary |
| --- | --- | --- |
| Review-001 | 2026-07-04 | V1 收口，冻结 Renderer，确定 Production Freeze Line |

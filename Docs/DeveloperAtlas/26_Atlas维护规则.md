# Atlas 维护规则

## 什么时候更新 Atlas

出现以下情况时，应该同步更新 Atlas：

- 新增或移动重要源码入口
- 新增 V1 / Configuration Center / Memory Engine 相关功能
- 新增测试文件或验证路径
- 改变生产 pipeline
- 改变默认配置或 snapshot 语义
- 改变 renderer / export 行为
- 新增项目术语或废弃旧术语

## 更新哪一类文档

### 新增功能入口

更新：

- [19_开发入口（Developer GPS）.md](/Users/rui/Desktop/PhotoMemo/Docs/DeveloperAtlas/19_开发入口（Developer%20GPS）.md)
- [20_扩展点（Extension Points）.md](/Users/rui/Desktop/PhotoMemo/Docs/DeveloperAtlas/20_扩展点（Extension%20Points）.md)
- [24_代码索引（按主题查文件）.md](/Users/rui/Desktop/PhotoMemo/Docs/DeveloperAtlas/24_代码索引（按主题查文件）.md)

### 新增测试

更新：

- [25_测试索引（按功能查验证）.md](/Users/rui/Desktop/PhotoMemo/Docs/DeveloperAtlas/25_测试索引（按功能查验证）.md)

### 改变数据流或状态流

更新：

- [05_数据流（Data Flow）.md](/Users/rui/Desktop/PhotoMemo/Docs/DeveloperAtlas/05_数据流（Data%20Flow）.md)
- [06_状态流（State Flow）.md](/Users/rui/Desktop/PhotoMemo/Docs/DeveloperAtlas/06_状态流（State%20Flow）.md)
- `diagrams/` 下对应图

### 改变对象模型

更新：

- [18_所有Model说明.md](/Users/rui/Desktop/PhotoMemo/Docs/DeveloperAtlas/18_所有Model说明.md)
- [diagrams/10_模型分层图.md](/Users/rui/Desktop/PhotoMemo/Docs/DeveloperAtlas/diagrams/10_模型分层图.md)

### 改变术语

更新：

- [23_术语词典（中英文）.md](/Users/rui/Desktop/PhotoMemo/Docs/DeveloperAtlas/23_术语词典（中英文）.md)

## 写法规则

Atlas 文档要保持：

- 中文优先
- 文件链接具体
- 少讲抽象口号
- 多给入口和判断标准
- 不重复粘贴源码
- 不把历史词汇重新包装成当前产品语言

## 图的规则

优先用 Mermaid。

适合画图的内容：

- 入口链路
- 数据流
- 状态流
- 调用链
- 模型分层
- 功能落点矩阵

不建议画图的内容：

- 每个小函数的内部细节
- 大量 SwiftUI view hierarchy
- 还没稳定的临时想法

## 更新后的检查

每次改 Atlas 后，至少确认：

- README 是否需要新增入口
- 阅读指南是否需要调整顺序
- 代码索引是否漏掉新文件
- 测试索引是否漏掉新测试
- `Docs/CURRENT_STATUS.md` 是否需要记录

## 不要做什么

- 不把 Atlas 当成旧文档迁移桶
- 不在 Atlas 里决定产品方向
- 不用 Atlas 绕过 Research / Specification 流程
- 不因为写 Atlas 顺手改源码行为

# PhotoMemo Developer Atlas

## 这是什么

Developer Atlas 是 PhotoMemo 的开发导航资料库。

它不是一次性代码分析报告，而是后续新增功能、理解 V1、确认 V1 / Configuration Center / Memory Engine 边界时的入口。

## 第一次阅读

建议从这几篇开始：

1. [00_阅读指南.md](/Users/rui/Desktop/PhotoMemo-main-archive-20260702/Docs/DeveloperAtlas/00_阅读指南.md)
2. [01_项目全景（产品角度）.md](/Users/rui/Desktop/PhotoMemo-main-archive-20260702/Docs/DeveloperAtlas/01_项目全景（产品角度）.md)
3. [02_项目架构（技术角度）.md](/Users/rui/Desktop/PhotoMemo-main-archive-20260702/Docs/DeveloperAtlas/02_项目架构（技术角度）.md)
4. [05_数据流（Data Flow）.md](/Users/rui/Desktop/PhotoMemo-main-archive-20260702/Docs/DeveloperAtlas/05_数据流（Data%20Flow）.md)
5. [19_开发入口（Developer GPS）.md](/Users/rui/Desktop/PhotoMemo-main-archive-20260702/Docs/DeveloperAtlas/19_开发入口（Developer%20GPS）.md)

## 想新增功能时

优先看：

1. [19_开发入口（Developer GPS）.md](/Users/rui/Desktop/PhotoMemo-main-archive-20260702/Docs/DeveloperAtlas/19_开发入口（Developer%20GPS）.md)
2. [20_扩展点（Extension Points）.md](/Users/rui/Desktop/PhotoMemo-main-archive-20260702/Docs/DeveloperAtlas/20_扩展点（Extension%20Points）.md)
3. [22_新增功能开发指南.md](/Users/rui/Desktop/PhotoMemo-main-archive-20260702/Docs/DeveloperAtlas/22_新增功能开发指南.md)
4. [21_风险分析（哪些地方不能乱改）.md](/Users/rui/Desktop/PhotoMemo-main-archive-20260702/Docs/DeveloperAtlas/21_风险分析（哪些地方不能乱改）.md)
5. [24_代码索引（按主题查文件）.md](/Users/rui/Desktop/PhotoMemo-main-archive-20260702/Docs/DeveloperAtlas/24_代码索引（按主题查文件）.md)
6. [25_测试索引（按功能查验证）.md](/Users/rui/Desktop/PhotoMemo-main-archive-20260702/Docs/DeveloperAtlas/25_测试索引（按功能查验证）.md)
7. [27_常见任务速查.md](/Users/rui/Desktop/PhotoMemo-main-archive-20260702/Docs/DeveloperAtlas/27_常见任务速查.md)

## 想看图

图都放在：

- [diagrams](/Users/rui/Desktop/PhotoMemo-main-archive-20260702/Docs/DeveloperAtlas/diagrams)

首批最常用图：

- [01_系统入口图.md](/Users/rui/Desktop/PhotoMemo-main-archive-20260702/Docs/DeveloperAtlas/diagrams/01_系统入口图.md)
- [02_V1_V2边界图.md](/Users/rui/Desktop/PhotoMemo-main-archive-20260702/Docs/DeveloperAtlas/diagrams/02_V1_V2边界图.md)
- [03_数据流总图.md](/Users/rui/Desktop/PhotoMemo-main-archive-20260702/Docs/DeveloperAtlas/diagrams/03_数据流总图.md)
- [07_状态流图.md](/Users/rui/Desktop/PhotoMemo-main-archive-20260702/Docs/DeveloperAtlas/diagrams/07_状态流图.md)
- [11_功能落点矩阵.md](/Users/rui/Desktop/PhotoMemo-main-archive-20260702/Docs/DeveloperAtlas/diagrams/11_功能落点矩阵.md)

## 按问题查

### V1 从哪里进入

- [08_页面导航.md](/Users/rui/Desktop/PhotoMemo-main-archive-20260702/Docs/DeveloperAtlas/08_页面导航.md)
- [diagrams/01_系统入口图.md](/Users/rui/Desktop/PhotoMemo-main-archive-20260702/Docs/DeveloperAtlas/diagrams/01_系统入口图.md)

### 状态在哪里

- [06_状态流（State Flow）.md](/Users/rui/Desktop/PhotoMemo-main-archive-20260702/Docs/DeveloperAtlas/06_状态流（State%20Flow）.md)
- [diagrams/07_状态流图.md](/Users/rui/Desktop/PhotoMemo-main-archive-20260702/Docs/DeveloperAtlas/diagrams/07_状态流图.md)

### 函数调用怎么走

- [10_Call Graph（函数调用）.md](/Users/rui/Desktop/PhotoMemo-main-archive-20260702/Docs/DeveloperAtlas/10_Call%20Graph（函数调用）.md)

### Repository / Service / Engine 怎么分工

- [12_Repository分析.md](/Users/rui/Desktop/PhotoMemo-main-archive-20260702/Docs/DeveloperAtlas/12_Repository分析.md)
- [13_Service分析.md](/Users/rui/Desktop/PhotoMemo-main-archive-20260702/Docs/DeveloperAtlas/13_Service分析.md)
- [14_Engine分析.md](/Users/rui/Desktop/PhotoMemo-main-archive-20260702/Docs/DeveloperAtlas/14_Engine分析.md)

### Renderer 应该怎么理解

- [15_Renderer分析.md](/Users/rui/Desktop/PhotoMemo-main-archive-20260702/Docs/DeveloperAtlas/15_Renderer分析.md)
- [07_Render Pipeline.md](/Users/rui/Desktop/PhotoMemo-main-archive-20260702/Docs/DeveloperAtlas/07_Render%20Pipeline.md)

### 术语怎么说

- [23_术语词典（中英文）.md](/Users/rui/Desktop/PhotoMemo-main-archive-20260702/Docs/DeveloperAtlas/23_术语词典（中英文）.md)

### 代码和测试怎么找

- [24_代码索引（按主题查文件）.md](/Users/rui/Desktop/PhotoMemo-main-archive-20260702/Docs/DeveloperAtlas/24_代码索引（按主题查文件）.md)
- [25_测试索引（按功能查验证）.md](/Users/rui/Desktop/PhotoMemo-main-archive-20260702/Docs/DeveloperAtlas/25_测试索引（按功能查验证）.md)

### Atlas 自己怎么维护

- [26_Atlas维护规则.md](/Users/rui/Desktop/PhotoMemo-main-archive-20260702/Docs/DeveloperAtlas/26_Atlas维护规则.md)
- [27_常见任务速查.md](/Users/rui/Desktop/PhotoMemo-main-archive-20260702/Docs/DeveloperAtlas/27_常见任务速查.md)
- [28_覆盖清单.md](/Users/rui/Desktop/PhotoMemo-main-archive-20260702/Docs/DeveloperAtlas/28_覆盖清单.md)
- [29_后续深化路线.md](/Users/rui/Desktop/PhotoMemo-main-archive-20260702/Docs/DeveloperAtlas/29_后续深化路线.md)

## 当前边界

当前 Atlas 第一版聚焦：

- V1 iOS 代码
- V1 / Configuration Center 并存边界
- Memory Engine 进入生产路径的关键关系
- 后续新增功能的开发入口

它不替代 Research / Specification，也不改变 IA-003 的实现顺序。

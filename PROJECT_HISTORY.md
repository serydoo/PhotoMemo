
# PhotoMemo Project History

## 2026-06-16

### 项目创建

项目名称：

PhotoMemo

定位：

Apple生态本地优先（Local First）照片信息边框生成工具。

核心场景：

儿童成长记录。

---

### 产品方向确定

明确：

* 不做通用修图软件
* 不做云端服务
* 不做AI图片生成

专注：

* 家庭照片
* 儿童成长记录
* 时间与地点记忆

核心价值：

让用户多年后仍能快速理解照片背后的时间与场景。

---

### 技术架构确定

技术栈：

* SwiftUI
* AppKit
* ImageIO
* CoreLocation

原则：

* 本地运行
* 保留原始EXIF
* 不压缩图片
* 不上传任何数据

---

### v0.1 完成

已实现：

✅ 拖拽照片

✅ 图片预览

✅ EXIF读取

✅ 拍摄时间读取

✅ 设备型号读取

✅ GPS读取

✅ 经纬度显示

✅ 地理位置反向解析

当前显示：

* 文件名
* 拍摄时间
* 设备型号
* 纬度
* 经度
* 地点名称

---

### UI原型确认

参考方案：

Photo Info Card

布局：

图片区域

↓

信息区域

信息区域内容：

左侧：

* 标题
* 日期

中间：

* Logo

右侧：

* EXIF参数
* 智能信息

---

### 模板方向确定

模板名称：

PhotoMemo Classic

背景色：

#F4F3F3

布局：

Left + Center + Right

支持未来扩展：

* Classic Dark
* Leica
* Film
* Minimal
* Apple Style

---

### 年龄系统立项

新增模块：

Age Engine

目标：

根据出生日期自动计算：

示例：

1岁2个月6天

或：

出生第432天

应用场景：

儿童成长记录

---

### GitHub建立

仓库：

https://github.com/serydoo/PhotoMemo

已完成：

* Git初始化
* GitHub关联
* 首次推送

---

### 项目文档体系建立

已建立：

README.md

DEVELOPMENT.md

ROADMAP.md

AI_CONTEXT.md

PROJECT_HISTORY.md

---

### 当前版本

v0.1

---

### 下一阶段

v0.2

目标：

AgeCalculator.swift

实现：

* 年龄计算
* 天数计算
* 成长文案生成


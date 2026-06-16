# AI_CONTEXT.md

## Project

PhotoMemo

Version: v0.1

Platform:

- macOS
- SwiftUI
- Apple Silicon

Repository:

https://github.com/serydoo/PhotoMemo

---

# Project Vision

PhotoMemo 是一款面向 Apple 生态的本地优先（Local-first）成长照片记录工具。

核心目标：

帮助家庭用户快速生成具有成长信息、时间信息、地点信息的纪念照片。

不是：

- 图片编辑器
- 修图软件
- AI绘图工具

而是：

成长记忆增强工具（Memory Enhancement Tool）。

---

# Product Positioning

目标用户：

1. 儿童成长记录家庭
2. 家庭相册整理用户
3. 旅行记录用户
4. 摄影爱好者

---

# Product Principles

必须遵守：

- 本地运行
- 不上传照片
- 不依赖云端
- 保留原图
- 保留 EXIF
- 不压缩画质

所有处理在设备本地完成。

---

# Core Workflow

用户选择照片

↓

读取 EXIF

↓

读取 GPS

↓

地址解析

↓

计算年龄

↓

生成纪念信息

↓

渲染模板

↓

导出照片

↓

保存结果

---

# Current Status

Current Version:

v0.1

---

# Completed Features

## Photo Preview

支持拖放照片

已完成

---

## Metadata Extraction

已完成

读取：

- 文件名
- 拍摄时间
- 设备型号

---

## GPS Extraction

已完成

读取：

- 纬度
- 经度

---

## Reverse Geocoding

已完成

经纬度

↓

省

↓

市

↓

区县

示例：

河南省 商丘市 永城市

---

# Existing Files

ContentView.swift

PhotoMetadata.swift

---

# Technology Stack

UI

- SwiftUI

System

- AppKit

Image

- ImageIO

Location

- CoreLocation

Future

- MapKit

---

# Current UI

显示：

- 图片预览
- 文件名
- 拍摄时间
- 设备型号
- 纬度
- 经度
- 地址

---

# Product Architecture

## Layer 1

Metadata Engine

文件：

PhotoMetadata.swift

状态：

已完成

负责：

- EXIF
- GPS
- Camera Info

---

## Layer 2

Location Engine

技术：

CLGeocoder

状态：

已完成

负责：

GPS

↓

地点名称

---

## Layer 3

Age Engine

文件：

AgeCalculator.swift

状态：

未开发

负责：

生日

↓

拍摄日期

↓

年龄计算

输出：

1岁2个月6天

出生第432天

---

## Layer 4

Template Engine

文件：

PhotoTemplate.swift

状态：

未开发

负责：

布局

字体

Logo

文案

模板

---

## Layer 5

Renderer

文件：

PhotoRenderer.swift

状态：

未开发

负责：

图片合成

导出

---

# Product Roadmap

## v0.1

已完成

- EXIF
- GPS
- 地址解析
- 图片预览

---

## v0.2

Age Engine

新增：

- 宝宝生日配置
- 出生第X天
- X岁X月X天

---

## v0.3

Classic Template

新增：

- 底部信息栏
- Logo
- 年龄信息
- 纪念日文案
- 模板渲染

---

## v0.4

Export

新增：

- 导出图片
- 保存目录
- 保留EXIF

---

## v0.5

Batch Processing

新增：

- 批量导入
- 批量导出
- 自动处理

---

# Design Philosophy

PhotoMemo 不是摄影参数工具。

PhotoMemo 的核心：

成长记录

家庭回忆

旅行记录

摄影参数只是辅助信息。

---

# PhotoMemo Classic

这是 v1.0 官方模板。

所有开发优先围绕此模板。

---

# Template Layout

------------------------------------------------

照片区域

------------------------------------------------

左侧

设备型号

拍摄时间

地点

中间

Logo

右侧

EXIF参数

年龄信息

纪念日文案

------------------------------------------------

---

# Design Specification

Background Color

#F4F3F3

RGB

244

243

243

---

Logo

72 × 72 px

固定大小

---

Layout

Three Column

左侧

Logo

右侧

---

# Border Strategy

采用：

固定高度

不采用：

比例高度

原因：

保证成长相册连续浏览时视觉统一。

---

Landscape

260px

---

Portrait

320px

---

# Future Template System

未来支持：

- Classic
- Classic Dark
- Film
- Leica
- Minimal
- Travel
- Family

当前只开发：

PhotoMemo Classic

---

# Anniversary Templates

模板1

宝宝今天：

{年龄} ❤️

---

模板2

出生至今：

第 {天数} 天 ❤️

---

模板3

拍摄于：

{日期}

距今：

{天数} 天

---

模板4

我们已经相伴：

{天数} 天 ❤️

---

# Future Features

- 照片备注
- 标签系统
- SQLite
- 搜索
- iCloud同步
- Apple Photos集成
- 地图展示
- 天气信息
- 海拔信息

---

# AI Development Rules

AI参与开发时：

1. 优先保持本地运行

2. 优先保留 EXIF

3. 不引入云服务依赖

4. 不改变产品定位

5. 优先开发路线图中的下一版本

6. 当前重点：

v0.2 Age Engine

实现年龄计算系统

---

# Notes

当前已完成：

- 拖拽照片
- EXIF读取
- GPS读取
- 地址解析
- 图片预览

下一开发目标：

AgeCalculator.swift

实现宝宝年龄计算。

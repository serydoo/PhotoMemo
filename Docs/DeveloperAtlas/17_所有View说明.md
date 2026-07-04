# 所有 View 说明

## 先说结论

当前仓库里的 View 不适合按“一个文件一个文件顺序读”。

更有效的读法是按 4 组理解：

1. iOS 入口与外层容器
2. V1 iOS Views
3. Configuration Center iOS Views
4. 历史 `Views/` 通用与主编辑流

## 1. iOS 入口与外层容器

### 关键文件

- [PhotoMemoiOSHomeView.swift](/Users/rui/Desktop/PhotoMemo-main-archive-20260702/Source/PhotoMemo/PhotoMemo/iOS/Views/PhotoMemoiOSHomeView.swift)
- [PhotoMemoiOSTemporaryEntryView.swift](/Users/rui/Desktop/PhotoMemo-main-archive-20260702/Source/PhotoMemo/PhotoMemo/iOS/Views/PhotoMemoiOSTemporaryEntryView.swift)
- [PhotoMemoiOSBackgroundStatusSheet.swift](/Users/rui/Desktop/PhotoMemo-main-archive-20260702/Source/PhotoMemo/PhotoMemo/iOS/Views/PhotoMemoiOSBackgroundStatusSheet.swift)

### 这一组负责什么

- 承接 runtime
- 承接后台状态
- 决定当前用户进入 V1 还是 Configuration Center

## 2. V1 iOS Views

### 主壳

- [PhotoMemoiOSV1View.swift](/Users/rui/Desktop/PhotoMemo-main-archive-20260702/Source/PhotoMemo/PhotoMemo/iOS/Views/PhotoMemoiOSV1View.swift)

### V1 surface / support

- [V1HomePageSurface.swift](/Users/rui/Desktop/PhotoMemo-main-archive-20260702/Source/PhotoMemo/PhotoMemo/iOS/Views/V1HomePageSurface.swift)
- [V1OutputPageSurface.swift](/Users/rui/Desktop/PhotoMemo-main-archive-20260702/Source/PhotoMemo/PhotoMemo/iOS/Views/V1OutputPageSurface.swift)
- [V1SettingsPageSurface.swift](/Users/rui/Desktop/PhotoMemo-main-archive-20260702/Source/PhotoMemo/PhotoMemo/iOS/Views/V1SettingsPageSurface.swift)
- [V1IOSViewSupportComponents.swift](/Users/rui/Desktop/PhotoMemo-main-archive-20260702/Source/PhotoMemo/PhotoMemo/iOS/Views/V1IOSViewSupportComponents.swift)

### V1 协调与预览相关

- `V1Configuration*`
- `V1Draft*`
- `V1Preview*`
- `V1Module*`

### V1 subject / home 相关

- `V1IOSSubject*`
- `V1SubjectHomeSummarySupport.swift`
- `V1IOSHome*`

### 这一组负责什么

- 当前 iPhone V1 产品面
- 预览与输出体验
- 当前主功能导航壳

## 3. Configuration Center iOS Views

### 主壳

- [ConfigurationCenteriOSView.swift](/Users/rui/Desktop/PhotoMemo-main-archive-20260702/Source/PhotoMemo/PhotoMemo/iOS/Views/ConfigurationCenteriOSView.swift)

### 典型分组

- `ConfigurationCenterSidebarView.swift`
- `ConfigurationCenterTopPreviewSection.swift`
- `ConfigurationCenterDetailPresenter.swift`
- `ConfigurationCenterRegionDraftStore.swift`
- `ConfigurationCenterSelectionCoordinator.swift`
- `ConfigurationCenterSelectionApplier.swift`
- `ConfigurationCenterRegion*`

### 这一组负责什么

- Library / Card / Inspector 架构
- 对象选择
- 区域编辑
- 配置预览

## 4. 历史 `Views/` 通用与主编辑流

目录：

- [/Users/rui/Desktop/PhotoMemo-main-archive-20260702/Source/PhotoMemo/PhotoMemo/Views](/Users/rui/Desktop/PhotoMemo-main-archive-20260702/Source/PhotoMemo/PhotoMemo/Views)

### `Views/Main`

这是历史主编辑流和 macOS 方向的重要遗留与资产区。

关键点：

- `MainView.swift` 已经被拆成 coordinator shell
- 相关逻辑散在大量 `MainView+*.swift`

### 其他分组

- `Views/Anchor`
- `Views/Preview`
- `Views/Template`
- `Views/Components`

这几组更多是通用可复用视图和历史 UI 资产。

## 读 View 的推荐顺序

### 如果你关注当前 iPhone 功能

先读：

1. `PhotoMemoiOSTemporaryEntryView`
2. `PhotoMemoiOSV1View`
3. `V1*`
4. `ConfigurationCenter*`

### 如果你关注历史主编辑流

先读：

1. `Views/Main/MainView.swift`
2. `Views/Main/MainView+*.swift`

### 如果你关注通用组件

先读：

1. `Views/Components`
2. `Views/Preview`
3. `Views/Template`
4. `Views/Anchor`

## 一个重要提醒

`iOS/Views` 物理上是平铺的，但逻辑上并不平铺。

这也是为什么：

- 新 Configuration Center helper 统一用 `ConfigurationCenter*`
- 新 V1 helper 统一用 `V1*`

这个命名约定本身就是一种逻辑分层。

# V1 UI Entry Polish Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Land the approved V1 iOS entry polish slice by adding a reopenable welcome page, reorganizing the home page, improving subject management, wiring `处理照片` to the system photo picker, and replacing the iOS app icon assets without changing renderer or export rules.

**Architecture:** Keep `PhotoMemoiOSV1View` as the state owner and add lightweight view-only helpers around it. Reuse existing runtime/coordinator/intake paths for photo processing, add only minimal persisted UI state for welcome-page visibility, and keep subject-management changes inside the existing overview/configuration flow.

**Tech Stack:** SwiftUI, PhotosUI, AppStorage, existing MemoMark coordinators/runtime services, Swift Testing, Xcode asset catalogs.

---

### Task 1: Add the welcome-page state model and tests

**Files:**
- Create: `Source/PhotoMemo/PhotoMemo/iOS/Views/V1WelcomePageSurface.swift`
- Create: `Source/PhotoMemo/PhotoMemo/iOS/Views/V1WelcomePresentation.swift`
- Test: `Tests/PhotoMemoTests/ArchitectureTests/V1WelcomePresentationTests.swift`

- [ ] **Step 1: Write the failing test**

```swift
#if !PHOTOMEMO_SHARE_EXTENSION
import Testing
@testable import PhotoMemo

@Suite("V1 welcome presentation")
struct V1WelcomePresentationTests {

    @Test("uses the approved title, subtitle, features, and actions")
    func usesApprovedCopy() {
        let presentation = V1WelcomePresentation.default

        #expect(presentation.title == "MemoMark")
        #expect(presentation.subtitle == "记录人生，珍藏记忆")
        #expect(presentation.features.count == 4)
        #expect(presentation.primaryActionTitle == "开始使用")
        #expect(presentation.secondaryActionTitle == "查看使用流程")
    }
}
#endif
```

- [ ] **Step 2: Run test to verify it fails**

Run: `xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemoTests -destination 'platform=macOS' -only-testing:PhotoMemoTests/V1WelcomePresentationTests CODE_SIGNING_ALLOWED=NO COMPILER_INDEX_STORE_ENABLE=NO test`

Expected: FAIL because `V1WelcomePresentation` does not exist yet.

- [ ] **Step 3: Write the minimal implementation**

```swift
struct V1WelcomePresentation: Equatable {
    struct Feature: Equatable, Identifiable {
        let id: String
        let title: String
        let detail: String
        let systemImage: String
    }

    let title: String
    let subtitle: String
    let message: String
    let features: [Feature]
    let primaryActionTitle: String
    let secondaryActionTitle: String

    static let `default` = V1WelcomePresentation(
        title: "MemoMark",
        subtitle: "记录人生，珍藏记忆",
        message: "时光记会结合照片信息、时间锚点与记忆对象，生成更有意义的记忆表达，同时保留原图。",
        features: [
            .init(id: "local", title: "本地优先", detail: "不上传照片，处理留在设备内。", systemImage: "internaldrive"),
            .init(id: "original", title: "保留原图", detail: "生成新图，不改动原始照片。", systemImage: "photo"),
            .init(id: "anchor", title: "时间锚点", detail: "让照片回到人生的具体位置。", systemImage: "timeline.selection"),
            .init(id: "benefit", title: "一次配置，长期受益", detail: "设定好对象与输出后，后续处理更轻松。", systemImage: "checkmark.seal")
        ],
        primaryActionTitle: "开始使用",
        secondaryActionTitle: "查看使用流程"
    )
}
```

- [ ] **Step 4: Add the view surface**

```swift
struct V1WelcomePageSurface: View {
    let presentation: V1WelcomePresentation
    let onStart: () -> Void
    let onShowWorkflow: () -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    Image("AppIconWelcomeMark")
                    Text(presentation.title)
                    Text(presentation.subtitle)
                    Text(presentation.message)
                    ForEach(presentation.features) { feature in
                        Label(feature.title, systemImage: feature.systemImage)
                    }
                    Button(presentation.primaryActionTitle, action: onStart)
                    Button(presentation.secondaryActionTitle, action: onShowWorkflow)
                }
                .padding(24)
            }
        }
    }
}
```

- [ ] **Step 5: Run test to verify it passes**

Run: `xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemoTests -destination 'platform=macOS' -only-testing:PhotoMemoTests/V1WelcomePresentationTests CODE_SIGNING_ALLOWED=NO COMPILER_INDEX_STORE_ENABLE=NO test`

Expected: PASS

### Task 2: Wire welcome-page persistence and home-page action/state changes

**Files:**
- Modify: `Source/PhotoMemo/PhotoMemo/iOS/Views/PhotoMemoiOSV1View.swift`
- Modify: `Source/PhotoMemo/PhotoMemo/iOS/Views/V1HomePageSurface.swift`
- Modify: `Source/PhotoMemo/PhotoMemo/iOS/Views/V1IOSHomeSupportViews.swift`
- Test: `Tests/PhotoMemoTests/ArchitectureTests/V1IOSHomeQuickActionsTests.swift`

- [ ] **Step 1: Write the failing test**

```swift
#if !PHOTOMEMO_SHARE_EXTENSION
import Testing
@testable import PhotoMemo

@Suite("V1 iOS quick actions")
struct V1IOSHomeQuickActionsTests {

    @Test("uses the approved four actions without recent-processing duplication")
    func usesApprovedActions() {
        let actions = V1IOSHomeQuickAction.defaultActions

        #expect(actions.map(\.title) == ["处理照片", "配置中心", "时间锚点", "使用说明"])
    }
}
#endif
```

- [ ] **Step 2: Run test to verify it fails**

Run: `xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemoTests -destination 'platform=macOS' -only-testing:PhotoMemoTests/V1IOSHomeQuickActionsTests CODE_SIGNING_ALLOWED=NO COMPILER_INDEX_STORE_ENABLE=NO test`

Expected: FAIL because `V1IOSHomeQuickAction` does not exist yet.

- [ ] **Step 3: Add a light action model and update the home support view**

```swift
struct V1IOSHomeQuickAction: Equatable, Identifiable {
    enum Destination {
        case processPhotos
        case configurationCenter
        case timeAnchor
        case usageGuide
    }

    let id: Destination
    let title: String
    let subtitle: String
    let systemImage: String

    static let defaultActions: [Self] = [
        .init(id: .processPhotos, title: "处理照片", subtitle: "从系统图库选择照片并开始处理", systemImage: "photo.badge.plus"),
        .init(id: .configurationCenter, title: "配置中心", subtitle: "继续校准当前配置", systemImage: "slider.horizontal.3"),
        .init(id: .timeAnchor, title: "时间锚点", subtitle: "查看当前对象与生效锚点", systemImage: "calendar.badge.clock"),
        .init(id: .usageGuide, title: "使用说明", subtitle: "重新查看欢迎说明与流程", systemImage: "questionmark.circle")
    ]
}
```

- [ ] **Step 4: Update the V1 view and home surface**

```swift
@AppStorage("photomemo.v1.welcomeSeen")
private var hasSeenWelcome = false

@State private var showsWelcomePage = false
@State private var showsWorkflowHelp = false
@State private var selectedProcessingItems: [PhotosPickerItem] = []
@State private var selectedProcessingItem: PhotosPickerItem?

private func bootstrapIfNeeded() {
    guard !didBootstrap else { return }
    didBootstrap = true
    bootstrapSavedSettings()
    bootstrapDrafts()
    showsWelcomePage = !hasSeenWelcome
}
```

- [ ] **Step 5: Remove the home output card and add the four actions**

```swift
V1HomePageSurface(
    ...
    onOpenTimeAnchor: { showsSubjectOverview = true },
    onOpenUsageGuide: { showsWelcomePage = true },
    onOpenPhotoPicker: { showsPhotoPicker = true }
)
```

- [ ] **Step 6: Run the targeted tests and iOS build**

Run: `xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemoTests -destination 'platform=macOS' -only-testing:PhotoMemoTests/V1IOSHomeQuickActionsTests -only-testing:PhotoMemoTests/V1WelcomePresentationTests CODE_SIGNING_ALLOWED=NO COMPILER_INDEX_STORE_ENABLE=NO test`

Run: `xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemoiOSV1 -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO COMPILER_INDEX_STORE_ENABLE=NO build`

Expected: Tests pass; iOS build succeeds with the home page still compiling.

### Task 3: Wire `处理照片` into the existing intake flow

**Files:**
- Modify: `Source/PhotoMemo/PhotoMemo/iOS/Views/PhotoMemoiOSV1View.swift`
- Test: `Tests/PhotoMemoTests/BatchTests/PhotoMemoiOSV1PhotoIntakeTests.swift`

- [ ] **Step 1: Write the failing test for URL filtering / intake preparation**

```swift
#if !PHOTOMEMO_SHARE_EXTENSION
import Foundation
import Testing
@testable import PhotoMemo

@Suite("V1 photo intake")
struct PhotoMemoiOSV1PhotoIntakeTests {

    @Test("keeps supported image URLs and removes duplicates")
    func keepsSupportedImageURLsAndRemovesDuplicates() {
        let urls = [
            URL(fileURLWithPath: "/tmp/a.heic"),
            URL(fileURLWithPath: "/tmp/a.heic"),
            URL(fileURLWithPath: "/tmp/b.jpeg"),
            URL(fileURLWithPath: "/tmp/c.txt")
        ]

        let resolved = V1PhotoIntakeURLResolver.resolve(urls)

        #expect(resolved.count == 2)
    }
}
#endif
```

- [ ] **Step 2: Run test to verify it fails**

Run: `xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemoTests -destination 'platform=macOS' -only-testing:PhotoMemoTests/PhotoMemoiOSV1PhotoIntakeTests CODE_SIGNING_ALLOWED=NO COMPILER_INDEX_STORE_ENABLE=NO test`

Expected: FAIL because `V1PhotoIntakeURLResolver` does not exist.

- [ ] **Step 3: Add the minimal resolver and hook the picker result into intake**

```swift
enum V1PhotoIntakeURLResolver {
    static func resolve(_ urls: [URL]) -> [URL] {
        urls
            .filter { ["jpg", "jpeg", "png", "heic", "heif", "tiff"].contains($0.pathExtension.lowercased()) }
            .reduce(into: [URL]()) { result, url in
                let normalized = url.standardizedFileURL
                if !result.contains(normalized) {
                    result.append(normalized)
                }
            }
    }
}
```

- [ ] **Step 4: Load picker URLs and submit them through `ExternalPhotoIntakeCenter.shared`**

```swift
private func submitPickedPhotos(_ urls: [URL]) {
    let resolvedURLs = V1PhotoIntakeURLResolver.resolve(urls)
    guard !resolvedURLs.isEmpty else { return }

    ExternalPhotoIntakeCenter.shared.submit(
        urls: resolvedURLs,
        source: .inApp
    )
    refreshExternalIntake()
    refreshProcessingState()
}
```

- [ ] **Step 5: Run the new test and build**

Run: `xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemoTests -destination 'platform=macOS' -only-testing:PhotoMemoTests/PhotoMemoiOSV1PhotoIntakeTests CODE_SIGNING_ALLOWED=NO COMPILER_INDEX_STORE_ENABLE=NO test`

Run: `xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemoiOSV1 -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO COMPILER_INDEX_STORE_ENABLE=NO build`

Expected: The resolver test passes and the V1 target still builds.

### Task 4: Update the subject overview into single-card / carousel management

**Files:**
- Modify: `Source/PhotoMemo/PhotoMemo/iOS/Views/V1IOSSubjectOverviewSupport.swift`
- Test: `Tests/PhotoMemoTests/ArchitectureTests/V1IOSSubjectOverviewPresenterTests.swift`

- [ ] **Step 1: Extend the presenter test with subject-count aware management summaries**

```swift
@Test("presentation reports anchor count and subject identity for management rows")
func presentationReportsManagementRows() {
    ...
    #expect(presentation.anchorCountLabel == "2 个时间锚点")
    #expect(presentation.subtitle == "成长记录")
}
```

- [ ] **Step 2: Update the sheet UI without changing the underlying save flow**

```swift
if subjects.count == 1 {
    singleSubjectManagementCard
} else {
    subjectCarousel
}
```

- [ ] **Step 3: Add plus/delete controls with guarded delete visibility**

```swift
.toolbar {
    ToolbarItem(placement: .topBarLeading) {
        if subjectCount > 1 { deleteButton }
    }
    ToolbarItem(placement: .topBarTrailing) {
        addButton
    }
}
```

- [ ] **Step 4: Run the presenter test and iOS build**

Run: `xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemoTests -destination 'platform=macOS' -only-testing:PhotoMemoTests/V1IOSSubjectOverviewPresenterTests CODE_SIGNING_ALLOWED=NO COMPILER_INDEX_STORE_ENABLE=NO test`

Run: `xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemoiOSV1 -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO COMPILER_INDEX_STORE_ENABLE=NO build`

Expected: The subject-overview tests pass and the new sheet layout compiles.

### Task 5: Add the settings reopen entry, replace icon assets, and finish verification

**Files:**
- Modify: `Source/PhotoMemo/PhotoMemo/iOS/Views/V1SettingsPageSurface.swift`
- Modify: `Source/PhotoMemo/PhotoMemo/Assets.xcassets/AppIcon.appiconset/*`
- Modify: `Docs/CURRENT_STATUS.md`
- Modify: `HANDOFF.md`

- [ ] **Step 1: Add the settings entry**

```swift
V1CardSurface(title: "设置") {
    Button("重新查看欢迎说明") {
        onShowWelcome()
    }
}
```

- [ ] **Step 2: Replace the app icon raster set**

Use one master 1024px icon matching the approved semantic direction, then regenerate the existing named PNG sizes already declared in `AppIcon.appiconset/Contents.json`.

- [ ] **Step 3: Run final targeted checks**

Run: `git diff --check`

Run: `xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemoTests -destination 'platform=macOS' -only-testing:PhotoMemoTests/V1WelcomePresentationTests -only-testing:PhotoMemoTests/V1IOSHomeQuickActionsTests -only-testing:PhotoMemoTests/PhotoMemoiOSV1PhotoIntakeTests -only-testing:PhotoMemoTests/V1IOSSubjectOverviewPresenterTests CODE_SIGNING_ALLOWED=NO COMPILER_INDEX_STORE_ENABLE=NO test`

Run: `xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemoiOSV1 -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO COMPILER_INDEX_STORE_ENABLE=NO build`

Run: `xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemoiOSV1 -destination 'id=REDACTED_DEVICE_ID' -derivedDataPath /tmp/PhotoMemoDeviceSignedBuild COMPILER_INDEX_STORE_ENABLE=NO build`

Run: `xcrun devicectl device install app --device REDACTED_DEVICE_ID /tmp/PhotoMemoDeviceSignedBuild/Build/Products/Debug-iphoneos/PhotoMemoiOSV1.app`

Run: `xcrun devicectl device process launch --device REDACTED_DEVICE_ID com.serydoo.PhotoMemo.iOS`

Expected: lint-style diff check is clean, targeted tests pass, simulator build passes, signed device build installs, and the app launches on `TestDeviceB`.

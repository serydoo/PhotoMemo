# Subject Configuration Continuity And Memory Source Disclosure Implementation Plan

Status: Closed on 2026-07-21.

The acceptance criteria are implemented and physically accepted. The original
unchecked task list is retained as historical planning evidence and must not be
treated as an active implementation queue. Equivalent implementation reused
existing configuration models where possible instead of following every
pseudocode suggestion literally. Closure evidence is recorded in `HANDOFF.md`
and `Docs/07_Releases/2026-07-21-1.7-build-7-configuration-continuity-and-ui-closure.md`.

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make Memory Subject switching restore each subject's complete effective configuration and add a subject-aware collapsible `记忆来源` section.

**Architecture:** Keep subject switching as a restore operation and configuration saving as an explicit persistence operation. Resolve configuration ownership from the selected subject, preserve complete `MemoryConfigurationEditorState` region item arrays, rebuild V1 editor/preview drafts after switching, and isolate disclosure state in a small presentation model keyed by selected subject ID.

**Tech Stack:** Swift, SwiftUI, Swift Testing, Codable configuration records, Xcode build/test tooling.

---

## File Map

- Modify `Source/PhotoMemo/PhotoMemo/Models/ConfigurationLibraryRecord.swift`: represent or resolve each subject's preferred effective configuration without breaking schema-1 decoding.
- Modify `Source/PhotoMemo/PhotoMemo/ConfigurationCenter/ConfigurationEditingState.swift`: select the correct subject-owned configuration and restore its complete context.
- Modify `Source/PhotoMemo/PhotoMemo/iOS/Views/V1ConfigurationDraftProjection.swift`: project complete saved editor content into V1 drafts for the selected configuration.
- Modify `Source/PhotoMemo/PhotoMemo/iOS/Views/V1BootstrapFlowSupport.swift`: bootstrap from the selected subject/configuration pair instead of an unrelated global active ID.
- Modify `Source/PhotoMemo/PhotoMemo/iOS/Views/V1SubjectFlowSupport.swift`: request complete draft rebootstrap after subject selection without saving configuration content.
- Create `Source/PhotoMemo/PhotoMemo/iOS/Views/V1MemorySourceDisclosureState.swift`: own expanded/collapsed session behavior.
- Modify `Source/PhotoMemo/PhotoMemo/iOS/Views/PhotoMemoiOSV1View.swift`: retain disclosure state across page navigation and pass it into the configuration list.
- Modify `Tests/PhotoMemoTests/ArchitectureTests/ConfigurationSessionConfigurationLifecycleTests.swift`: subject-owned configuration regression coverage.
- Modify `Tests/PhotoMemoTests/ArchitectureTests/V1ConfigurationBootstrapPresenterTests.swift`: complete editor draft restoration coverage.
- Modify `Tests/PhotoMemoTests/ArchitectureTests/V1SubjectLibrarySupportTests.swift`: switching event and no-resave coverage.
- Create `Tests/PhotoMemoTests/ArchitectureTests/V1MemorySourceDisclosureStateTests.swift`: disclosure-state behavior coverage.
- Update `HANDOFF.md`: record the closed regression, verification, and manual-validation status.

### Task 1: Reproduce Subject Configuration Switching Regression

**Files:**
- Modify: `Tests/PhotoMemoTests/ArchitectureTests/ConfigurationSessionConfigurationLifecycleTests.swift`
- Modify: `Tests/PhotoMemoTests/ArchitectureTests/V1SubjectLibrarySupportTests.swift`

- [ ] **Step 1: Add repeated A -> B -> A configuration restoration test**

Create two subjects, give each a configuration with a different `selectedTimeAnchorID`, and assert repeated switching restores the matching configuration and anchor without calling a save action:

```swift
session.selectSubject(secondSubject)
#expect(session.state.selectedMemoryPresetID == secondConfiguration.id)
#expect(session.selectedTimeAnchorID == secondAnchor.id)

session.selectSubject(firstSubject)
#expect(session.state.selectedMemoryPresetID == firstConfiguration.id)
#expect(session.selectedTimeAnchorID == firstAnchor.id)
```

- [ ] **Step 2: Add switching-flow no-resave assertion**

Use a spy `ConfigurationCoordinator` or existing persistence test seam and verify `V1SubjectOverviewActionCoordinator.selectSubject` persists subject selection/library state but does not invoke the current-configuration save path or advance configuration `savedAt`.

- [ ] **Step 3: Run the focused tests and confirm RED**

Run:

```bash
xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemoTests -destination 'platform=macOS' -only-testing:PhotoMemoTests/ConfigurationSessionConfigurationLifecycleTests -only-testing:PhotoMemoTests/V1SubjectLibrarySupportTests CODE_SIGNING_ALLOWED=NO COMPILER_INDEX_STORE_ENABLE=NO test
```

Expected: at least one new A -> B -> A or no-resave assertion fails against current behavior.

### Task 2: Make Subject-Owned Effective Configuration Deterministic

**Files:**
- Modify: `Source/PhotoMemo/PhotoMemo/Models/ConfigurationLibraryRecord.swift`
- Modify: `Source/PhotoMemo/PhotoMemo/ConfigurationCenter/ConfigurationEditingState.swift`
- Modify: `Tests/PhotoMemoTests/ArchitectureTests/ConfigurationLibraryRecordTests.swift`
- Modify: `Tests/PhotoMemoTests/ArchitectureTests/ConfigurationSessionConfigurationLifecycleTests.swift`

- [ ] **Step 1: Add subject-owned resolver tests**

Lock this order for a selected subject: same-subject selected configuration, durable subject preference when available, latest saved owned configuration, first owned configuration, then `nil`. Assert another subject's global active configuration is never returned.

- [ ] **Step 2: Implement a focused resolver**

Add a model-level function with a subject boundary, for example:

```swift
func effectiveConfiguration(
    for subjectID: UUID,
    preferredConfigurationID: UUID?
) -> MemoryConfigurationRecord?
```

The function must inspect only the matching `SubjectConfigurationRecord.configurations` array. Preserve schema-1 decoding; if durable per-subject preference requires a new optional field, decode it with `decodeIfPresent` and derive a compatibility fallback from existing `activeSubjectID` plus `activeConfigurationID`.

- [ ] **Step 3: Route subject alignment through the resolver**

Update `preferredMemoryPresetForSelectedSubject` / `alignSelectedMemoryPresetToSelectedSubject` so they use the selected subject's resolved configuration and then call:

```swift
restoreConfigurationContext(from: configuration)
refreshPresetDrivenPreview()
```

Clear `selectedMemoryPresetID`, applied state, draft configuration, and stale previews when no owned configuration exists.

- [ ] **Step 4: Run model and lifecycle tests and confirm GREEN**

Run the Task 1 command plus:

```bash
xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemoTests -destination 'platform=macOS' -only-testing:PhotoMemoTests/ConfigurationLibraryRecordTests CODE_SIGNING_ALLOWED=NO COMPILER_INDEX_STORE_ENABLE=NO test
```

Expected: all selected suites pass with zero failures.

### Task 3: Preserve And Restore Complete Region Content

**Files:**
- Modify: `Tests/PhotoMemoTests/ArchitectureTests/V1ConfigurationBootstrapPresenterTests.swift`
- Modify: `Tests/PhotoMemoTests/ArchitectureTests/V1ConfigurationApplyRequestBuilderTests.swift`
- Modify: `Source/PhotoMemo/PhotoMemo/iOS/Views/V1ConfigurationDraftProjection.swift`
- Modify: `Source/PhotoMemo/PhotoMemo/iOS/Views/V1BootstrapFlowSupport.swift`

- [ ] **Step 1: Add a complete-content round-trip test**

Build a configuration region containing ordered Smart Module, literal text, and customized text items. Save/project/reload and assert exact ordered identity and payload:

```swift
#expect(restored.items.map(\.id) == original.items.map(\.id))
#expect(restored.items.map(\.templateValue) == original.items.map(\.templateValue))
#expect(restored.items.map(\.expressionConfiguration) == original.items.map(\.expressionConfiguration))
#expect(restored.items.map(\.value) == original.items.map(\.value))
```

- [ ] **Step 2: Run the new test and confirm RED**

Run:

```bash
xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemoTests -destination 'platform=macOS' -only-testing:PhotoMemoTests/V1ConfigurationBootstrapPresenterTests -only-testing:PhotoMemoTests/V1ConfigurationApplyRequestBuilderTests CODE_SIGNING_ALLOWED=NO COMPILER_INDEX_STORE_ENABLE=NO test
```

Expected: the new assertion exposes the partial custom-text restoration path.

- [ ] **Step 3: Restore from the full saved editor contract**

In `V1ConfigurationDraftProjection`, select the configuration resolved for the current subject and construct every `V1EditorDraft` from the complete saved region item collection. Do not synthesize a region solely from `usesCustomText` or `customText` when complete editor items exist.

- [ ] **Step 4: Align bootstrap with selected configuration**

Update bootstrap input so `V1BootstrapFlowSupport` receives or resolves both `selectedSubjectID` and `selectedMemoryPresetID`. The projection must not always begin with repository-global `aggregate.activeConfigurationID` when the session has already switched subjects.

- [ ] **Step 5: Run complete-content tests and confirm GREEN**

Run the Task 3 test command. Expected: all selected suites pass with exact item-order and module-configuration equality.

### Task 4: Rebootstrap Editor And Preview Drafts On Subject Switch

**Files:**
- Modify: `Source/PhotoMemo/PhotoMemo/iOS/Views/V1SubjectFlowSupport.swift`
- Modify: `Source/PhotoMemo/PhotoMemo/iOS/Views/PhotoMemoiOSV1View.swift`
- Modify: `Tests/PhotoMemoTests/ArchitectureTests/V1SubjectLibrarySupportTests.swift`
- Modify: `Tests/PhotoMemoTests/ArchitectureTests/V1DraftRuntimeCoordinatorTests.swift`

- [ ] **Step 1: Add editor-and-preview synchronization test**

After selecting the second subject, apply the returned `.rebootstrapPreviewDrafts` event and assert both `regionDrafts` and `previewDraftsByRegion` contain the second configuration's Smart Module and text items.

- [ ] **Step 2: Ensure switch applies restored session state before bootstrap**

Keep this ordering in the root flow:

```text
session.selectSubject
-> configuration alignment/restoration
-> persist selected subject identity/library pointer
-> bootstrapDrafts
-> refresh preview
```

Do not call `applyCurrentV1Configuration()` or `saveCurrentMemoryPreset()` from the switching path.

- [ ] **Step 3: Run switch and draft tests**

Run:

```bash
xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemoTests -destination 'platform=macOS' -only-testing:PhotoMemoTests/V1SubjectLibrarySupportTests -only-testing:PhotoMemoTests/V1DraftRuntimeCoordinatorTests CODE_SIGNING_ALLOWED=NO COMPILER_INDEX_STORE_ENABLE=NO test
```

Expected: all selected suites pass with no explicit save needed.

### Task 5: Add Subject-Aware Memory Source Disclosure State

**Files:**
- Create: `Source/PhotoMemo/PhotoMemo/iOS/Views/V1MemorySourceDisclosureState.swift`
- Create: `Tests/PhotoMemoTests/ArchitectureTests/V1MemorySourceDisclosureStateTests.swift`

- [ ] **Step 1: Write disclosure state tests**

Cover initial expansion, manual collapse, same-subject retention, and different-subject forced expansion:

```swift
var state = V1MemorySourceDisclosureState(selectedSubjectID: firstID)
state.setExpanded(false)
state.synchronize(selectedSubjectID: firstID)
#expect(state.isExpanded == false)

state.synchronize(selectedSubjectID: secondID)
#expect(state.isExpanded == true)
```

Also assert toggling disclosure has no configuration-status output or persistence command.

- [ ] **Step 2: Run the test and confirm RED**

Run:

```bash
xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemoTests -destination 'platform=macOS' -only-testing:PhotoMemoTests/V1MemorySourceDisclosureStateTests CODE_SIGNING_ALLOWED=NO COMPILER_INDEX_STORE_ENABLE=NO test
```

Expected: compile failure because the state type does not exist.

- [ ] **Step 3: Implement the minimal state model**

Use a value type with no persistence dependency:

```swift
struct V1MemorySourceDisclosureState: Hashable {
    private(set) var selectedSubjectID: UUID?
    private(set) var isExpanded: Bool = true

    mutating func setExpanded(_ isExpanded: Bool) {
        self.isExpanded = isExpanded
    }

    mutating func synchronize(selectedSubjectID: UUID?) {
        guard self.selectedSubjectID != selectedSubjectID else { return }
        self.selectedSubjectID = selectedSubjectID
        isExpanded = true
    }
}
```

- [ ] **Step 4: Run the state tests and confirm GREEN**

Run the Task 5 test command. Expected: all disclosure-state tests pass.

### Task 6: Implement The Memory Source Disclosure UI

**Files:**
- Modify: `Source/PhotoMemo/PhotoMemo/iOS/Views/PhotoMemoiOSV1View.swift`
- Modify: `Tests/PhotoMemoTests/ArchitectureTests/V1HomeConfigurationActionContractTests.swift` or create a focused source-contract test beside existing V1 presentation tests.

- [ ] **Step 1: Keep disclosure state at the root view level**

Add one `@State` value to `PhotoMemoiOSV1View` so navigation away from and back to the editor does not recreate the choice. Synchronize it in the existing selected-subject change path:

```swift
memorySourceDisclosureState.synchronize(
    selectedSubjectID: session.state.selectedSubjectID
)
```

- [ ] **Step 2: Pass expansion binding and summary values**

Extend `V1ConfigurationOptionList` with:

```swift
@Binding var isMemorySourceExpanded: Bool
let memorySourceSummary: String
```

Build the summary from the effective subject display name, `session.currentTimeAnchorTitle`, and `ConfigurationCenterMemoryDisplaySupport.summaryValue(subject:)`.

- [ ] **Step 3: Add the trailing disclosure button**

Extend `groupedSection` only as needed to accept a trailing header action. The button must use `chevron.up` / `chevron.down`, visible `收起` / `展开` text when space permits, and accessibility labels `收起记忆来源` / `展开记忆来源`.

- [ ] **Step 4: Render expanded rows or collapsed summary**

Use conditional SwiftUI content:

```swift
if isMemorySourceExpanded {
    subjectRow
    optionDivider
    timeAnchorRow
    optionDivider
    memoryDisplayRow
} else {
    memorySourceSummaryRow
}
```

The button only mutates disclosure state. It must not change `activeConfigurationStatus` or call a configuration action.

- [ ] **Step 5: Run presentation contract and state tests**

Run:

```bash
xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemoTests -destination 'platform=macOS' -only-testing:PhotoMemoTests/V1MemorySourceDisclosureStateTests -only-testing:PhotoMemoTests/V1HomeConfigurationActionContractTests CODE_SIGNING_ALLOWED=NO COMPILER_INDEX_STORE_ENABLE=NO test
```

Expected: all selected tests pass.

### Task 7: Regression Verification And Project Handoff

**Files:**
- Update: `HANDOFF.md`

- [ ] **Step 1: Run the combined focused regression suite**

Run all suites touched in Tasks 1-6 in one `xcodebuild test` invocation. Expected: zero failures.

- [ ] **Step 2: Run the required repository build**

```bash
xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemo -configuration Debug -derivedDataPath /tmp/PhotoMemoDerivedData CODE_SIGNING_ALLOWED=NO -quiet build
```

Expected: exit code 0.

- [ ] **Step 3: Run the V1 iOS simulator build**

```bash
xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemoiOSV1 -destination 'generic/platform=iOS Simulator' -configuration Debug -derivedDataPath /tmp/PhotoMemoiOSV1DerivedData CODE_SIGNING_ALLOWED=NO -quiet build
```

Expected: exit code 0.

- [ ] **Step 4: Run repository hygiene checks**

```bash
git diff --check
git status --short
```

Expected: no whitespace errors; only scoped task changes plus pre-existing user changes.

- [ ] **Step 5: Record the engineering event**

Append a concise HANDOFF entry covering root cause, files changed, regression tests, builds, simulator/device evidence, and anything not manually verified. Do not rewrite unrelated existing status entries.

- [ ] **Step 6: Manual acceptance sequence**

On simulator or device when available:

1. Create or select two subjects with different configurations and anchors.
2. Confirm A -> B -> A switching immediately changes the effective anchor without pressing save.
3. Confirm the second configuration displays its Smart Modules and custom fields together.
4. Collapse `记忆来源`, leave and return to the Configuration Center, and confirm it stays collapsed.
5. Switch subjects and confirm `记忆来源` expands automatically.

Record whether each step was verified or remains outstanding.

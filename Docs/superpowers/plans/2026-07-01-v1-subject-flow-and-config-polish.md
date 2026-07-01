# V1 Subject Flow And Configuration Center Polish Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Turn the Home `当前记忆对象` entry into a dedicated subject-configuration flow, while polishing the main V1 and iOS Configuration Center interactions without touching renderer or export semantics.

**Architecture:** Keep IA-002 structure intact. Reuse existing subject-editing content instead of inventing a new editor model, and confine new behavior to V1 navigation shells plus lightweight iOS configuration-center interaction helpers. Preserve current `ConfigurationSession` fallback behavior for memory-write text, but correct the UI wording and affordances around it.

**Tech Stack:** SwiftUI, Swift Testing, existing `ConfigurationSession` / V1 presenter-coordinator helpers.

---

### Task 1: Dedicated Subject Entry Flow

**Files:**
- Modify: `Source/PhotoMemo/PhotoMemo/iOS/Views/PhotoMemoiOSV1View.swift`
- Modify: `Source/PhotoMemo/PhotoMemo/iOS/Views/V1IOSSubjectOverviewSupport.swift`
- Create: `Source/PhotoMemo/PhotoMemo/iOS/Views/V1IOSSubjectConfigurationFlow.swift`
- Test: `Tests/PhotoMemoTests/ArchitectureTests/V1IOSSubjectOverviewPresenterTests.swift`

- [ ] Add a dedicated subject-configuration destination from Home instead of routing `前往配置中心` back to the main editor tab.
- [ ] Reuse `MemorySubjectEditorView` inside a dedicated iOS shell that provides page-level save/back semantics and keeps focus on overview, basic profile, and time anchors.
- [ ] Keep the Home sheet lightweight: subject overview remains the entry surface, but its continuation action now opens the dedicated subject flow.
- [ ] Add or extend focused tests around subject-overview presentation and any new pure navigation/presentation helper introduced for the flow.

### Task 2: Main Configuration Center Interaction Polish

**Files:**
- Modify: `Source/PhotoMemo/PhotoMemo/iOS/Views/ConfigurationCenteriOSView.swift`
- Modify: `Source/PhotoMemo/PhotoMemo/ConfigurationCenter/MemoryCard/InteractiveMemoryCard.swift`
- Create: `Source/PhotoMemo/PhotoMemo/iOS/Views/ConfigurationCenterPageChromePresenter.swift`
- Test: `Tests/PhotoMemoTests/ArchitectureTests/ConfigurationCenterSessionBindingPresenterTests.swift`
- Test: `Tests/PhotoMemoTests/ArchitectureTests/ConfigurationCenterSelectionCoordinatorTests.swift`
- Test: `Tests/PhotoMemoTests/ArchitectureTests/ConfigurationCenterPageChromePresenterTests.swift`

- [ ] Remove remaining MVP-style fade/slide emphasis from configuration preview-region editing so the page feels stable instead of staged.
- [ ] Add page-level save affordance and clear toolbar actions for the main Configuration Center without changing renderer/export behavior.
- [ ] Add unified keyboard dismissal behavior for blank-area taps, scrolling, and panel changes where feasible.
- [ ] Keep the main Configuration Center as a freely switchable root page, not a pushed page with fake back semantics.

### Task 3: Memory-Write UI Semantics Cleanup

**Files:**
- Modify: `Source/PhotoMemo/PhotoMemo/iOS/Views/PhotoMemoiOSV1View.swift`
- Modify: `Source/PhotoMemo/PhotoMemo/iOS/Views/ConfigurationCenteriOSView.swift`
- Modify: `Source/PhotoMemo/PhotoMemo/iOS/Views/ConfigurationCenterSessionBindingPresenter.swift`
- Test: `Tests/PhotoMemoTests/ArchitectureTests/ConfigurationCenterSessionBindingPresenterTests.swift`

- [ ] Preserve the existing `ConfigurationSession.resolvedMemoryWriteText` fallback rule.
- [ ] Change the user-facing toggle semantics from “whether to write memory” to “whether to use separately entered text”.
- [ ] When custom text is off, clearly show that the app will write the full `slotD` output by default.
- [ ] Keep both V1 Output and the mac-like iOS Configuration Center wording aligned.

### Task 4: Verification And Project Memory

**Files:**
- Modify: `HANDOFF.md`
- Modify: `Docs/CURRENT_STATUS.md`

- [ ] Run targeted Swift Testing suites for any new helpers or presenters added in Tasks 1-3.
- [ ] Run an iOS build for the active `PhotoMemoiOSV1` target.
- [ ] Record what was verified and any remaining manual UX validation gaps in the project state docs.

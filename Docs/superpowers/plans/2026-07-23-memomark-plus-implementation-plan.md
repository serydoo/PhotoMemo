# MemoMark+ Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a production-ready MemoMark+ non-consumable purchase flow with StoreKit Sandbox/Production isolation, a 200-record free allowance, 20/40-photo batch policy, native purchase UI, Offer Code redemption, and first-recorder identity.

**Architecture:** One Release binary serves both TestFlight and App Store. StoreKit's verified App transaction environment selects an isolated commerce namespace; a shared local commerce store owns allowance and entitlement presentation, then writes a minimal App Group snapshot for the Share Extension. Rendering and export remain unchanged; the queue records usage only when a task transitions to completed with a saved Apple Photos asset identifier.

**Tech Stack:** Swift 6, SwiftUI, StoreKit 2, Swift Testing, UserDefaults App Group persistence, existing Configuration Center design tokens.

---

## File Map

- Create `Source/PhotoMemo/PhotoMemo/Models/MemoMarkCommerceModels.swift`: pure environment, entitlement, allowance, batch-limit, and milestone models.
- Create `Source/PhotoMemo/PhotoMemo/App/MemoMarkCommercePersistence.swift`: environment-namespaced count, idempotency, major-version gift, and shared snapshot persistence shared with the Share Extension.
- Create `Source/PhotoMemo/PhotoMemo/Services/MemoMarkCommerceStore.swift`: StoreKit product loading, transaction verification/listening, purchase, restore, and derived UI state.
- Create `Source/PhotoMemo/PhotoMemo/iOS/Views/MemoMarkPlusPurchaseView.swift`: native purchase page, success commemoration, restore, and Offer Code entry.
- Create `Source/PhotoMemo/PhotoMemo/iOS/Views/MemoMarkPlusBadge.swift`: reusable warm-gold purchased badge.
- Modify `Source/PhotoMemo/PhotoMemo/App/PhotoMemoAppRuntime.swift`: own and start the shared commerce store.
- Modify `Source/PhotoMemo/PhotoMemo/Architecture/AppEnvironment.swift`: inject commerce persistence into the queue store.
- Modify `Source/PhotoMemo/PhotoMemo/Services/BatchQueueStore.swift`: enforce admission and record unique successful saves.
- Modify `Source/PhotoMemo/PhotoMemo/iOS/ShareExtension/PhotoMemoShareExtensionIntakeService.swift`: derive the selection limit from the shared snapshot.
- Modify `Source/PhotoMemo/PhotoMemo/iOS/ShareExtension/PhotoMemoShareExtensionViewController.swift`: use dynamic limit copy.
- Modify `Source/PhotoMemo/PhotoMemo/iOS/ShareExtension/ShareExtensionViewStateRenderer.swift`: use dynamic limit copy.
- Modify `Source/PhotoMemo/PhotoMemo/iOS/Views/V1SettingsPageSurface.swift`: add the top status card and entitlement-aware 20/40 capability copy.
- Modify `Source/PhotoMemo/PhotoMemo/iOS/Views/ConfigurationCenteriOSView.swift`: present the purchase page and pass commerce state.
- Modify `Source/PhotoMemo/PhotoMemo/iOS/Views/ConfigurationCenterTopPreviewSection.swift`: display and open the purchased warm-gold badge.
- Create `Tests/PhotoMemoTests/ArchitectureTests/MemoMarkCommercePolicyTests.swift`: allowance, gift, environment, and batch-limit tests.
- Create `Tests/PhotoMemoTests/ArchitectureTests/MemoMarkCommercePersistenceTests.swift`: idempotency and namespace persistence tests.
- Create `Tests/PhotoMemoTests/ArchitectureTests/MemoMarkCommerceUIContractTests.swift`: source-level UI and StoreKit boundary contracts.

### Task 1: Commerce Domain And Persistence

- [ ] **Step 1: Write failing policy tests**

Cover free allowance 200, free batch 20, Plus batch 40, record 190/200 milestones, paid unlimited behavior, and a configured `major-2` gift of 50 records.

```swift
@Test func freeAndPlusPoliciesStayDistinct() {
    #expect(MemoMarkCommercePolicy.free.batchLimit == 20)
    #expect(MemoMarkCommercePolicy.plus.batchLimit == 40)
    #expect(MemoMarkCommercePolicy.free.remainingRecords(after: 190) == 10)
    #expect(MemoMarkCommercePolicy.plus.remainingRecords(after: 9_999) == nil)
}
```

- [ ] **Step 2: Run the focused tests and confirm failure**

Run:

```bash
xcodebuild -project Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemoTests -destination 'platform=macOS' -only-testing:PhotoMemoTests/MemoMarkCommercePolicyTests test
```

Expected: compile failure because commerce types do not exist.

- [ ] **Step 3: Implement pure commerce models**

Define:

```swift
enum MemoMarkCommerceEnvironment: String, Codable {
    case xcode, sandbox, production
}

struct MemoMarkCommercePolicy: Equatable {
    static let free = Self(isPlus: false, baseAllowance: 200, bonusAllowance: 0, batchLimit: 20)
    static let plus = Self(isPlus: true, baseAllowance: 200, bonusAllowance: 0, batchLimit: 40)
}
```

Milestone output is `.none`, `.approaching(remaining: 10)`, or `.allowanceCompleted`; Plus always returns `.none`.

- [ ] **Step 4: Write persistence tests**

Verify a task ID increments once, different task IDs increment independently, Sandbox and Production counts never overlap, and the same major gift campaign applies once.

```swift
let persistence = MemoMarkCommercePersistence(defaults: defaults)
#expect(persistence.recordSuccessfulSave(taskID: taskID, environment: .sandbox))
#expect(!persistence.recordSuccessfulSave(taskID: taskID, environment: .sandbox))
#expect(persistence.successfulRecordCount(environment: .sandbox) == 1)
#expect(persistence.successfulRecordCount(environment: .production) == 0)
```

- [ ] **Step 5: Implement namespaced persistence and shared snapshot**

Persist count and completed task IDs under environment-specific keys. Store the current shared snapshot as a small Codable value containing environment, Plus status, batch limit, remaining records, and update date. Apply explicitly configured gift campaign `major-2` once when the shipping version reaches 2.x; do not reset counts.

- [ ] **Step 6: Run policy and persistence tests**

Expected: all new tests pass.

### Task 2: StoreKit Entitlement Store

- [ ] **Step 1: Add StoreKit UI-contract tests**

Assert the source contains the immutable product identifier `com.serydoo.PhotoMemo.iOS.memomarkplus.lifetime`, verified transaction handling, `Transaction.updates`, and environment-derived persistence.

- [ ] **Step 2: Implement the observable StoreKit store**

Use:

```swift
@MainActor
final class MemoMarkCommerceStore: ObservableObject {
    static let plusProductID = "com.serydoo.PhotoMemo.iOS.memomarkplus.lifetime"
    @Published private(set) var product: Product?
    @Published private(set) var entitlement: MemoMarkPlusEntitlement = .free
    @Published private(set) var purchaseState: MemoMarkPurchaseState = .idle
}
```

At startup, verify `AppTransaction.shared`, map its environment, load the product, inspect `Transaction.currentEntitlements`, start a `Transaction.updates` listener, and publish the shared snapshot. Never grant entitlement from an unverified transaction.

- [ ] **Step 3: Implement purchase and restore**

`purchasePlus()` calls `product.purchase()`, handles success/pending/cancel, updates verified entitlement, finishes the transaction, and records the original purchase date. `restorePurchases()` calls `AppStore.sync()` and refreshes current entitlements.

- [ ] **Step 4: Run focused commerce tests**

Expected: model, persistence, and source contract suites pass.

### Task 3: Queue Counting And Admission

- [ ] **Step 1: Write failing queue-policy tests**

Test that a free store rejects a new batch when remaining allowance is zero or smaller than the payload count, Plus accepts up to 40, and a task transition to completed with a saved asset ID records exactly once.

- [ ] **Step 2: Inject persistence into `BatchQueueStore`**

Add a commerce persistence dependency and a current policy provider. Admission checks run before `execution.enqueue`; rejected admission publishes a clear message without creating a job.

- [ ] **Step 3: Count successful save transitions**

In `updateTask`, compare the previous and updated task. Call `recordSuccessfulSave` only when phase changes to `.completed` and `savedAssetIdentifier` is non-empty. This covers both static and Live Photo paths without changing Renderer or export ownership.

- [ ] **Step 4: Publish refreshed snapshot after count changes**

The main app refreshes remaining allowance immediately so Settings and Share Extension observe the same value.

- [ ] **Step 5: Run queue and commerce tests**

Expected: existing queue tests plus new admission/counting tests pass.

### Task 4: Share Extension Dynamic Policy

- [ ] **Step 1: Write source and policy tests**

Require the intake service to use a `maxSupportedPhotoCount` instance value sourced from the shared commerce snapshot rather than a static `20`.

- [ ] **Step 2: Read the shared snapshot in the extension**

Free state resolves to `min(20, remainingRecords)`; Plus resolves to 40. If the free allowance is complete, return a dedicated actionable error directing the user to open MemoMark and unlock MemoMark+.

- [ ] **Step 3: Replace static limit call sites**

Update controller diagnostics, confirmation validation, error copy, and state renderer copy to use the resolved instance limit.

- [ ] **Step 4: Run Share Extension tests and build**

Expected: existing share responsibility tests pass and the extension compiles.

### Task 5: Native Purchase And Commemoration UI

- [ ] **Step 1: Write UI contract tests**

Check purchase copy includes unlimited records, 40-photo batches, Family Sharing, local processing, separate collaboration Presets, Offer Code redemption, and restore purchase. Ensure forbidden `VIP`, crown, and Renderer purchase language do not appear.

- [ ] **Step 2: Implement `MemoMarkPlusPurchaseView`**

Build a light-first SwiftUI scroll page using `ConfigurationUI` surfaces and spacing. Render the StoreKit localized price, loading/unavailable/pending/error states, primary purchase action, `offerCodeRedemption` system sheet, restore action, privacy statement, and collaboration Preset boundary.

- [ ] **Step 3: Implement first-recorder success state**

After verified purchase or Offer Code redemption, show the approved date-based message and a restrained warm-gold mark. The date comes from verified original purchase truth when available.

- [ ] **Step 4: Implement the reusable warm-gold badge**

Use champagne-gold foreground, pale fill, fine border, sparkle and `MemoMark+` text. Add a VoiceOver label and no looping animation. Do not place the badge in Renderer or Memory Card code.

- [ ] **Step 5: Run UI contract tests**

Expected: all MemoMark+ copy and boundary checks pass.

### Task 6: Settings And Configuration Center Integration

- [ ] **Step 1: Add the Settings top entitlement card**

Pass commerce presentation into `V1SettingsPageSurface`. Free shows used/total records and opens MemoMark+; Plus shows first-recorder date, unlimited records, and 40-photo batch capability.

- [ ] **Step 2: Make the capability row entitlement-aware**

Replace fixed `最多 20 张照片` with the current policy value and preserve the existing stability explanation.

- [ ] **Step 3: Present the independent purchase sheet**

`ConfigurationCenteriOSView` observes `runtime.commerceStore`, presents `MemoMarkPlusPurchaseView`, and routes Settings and badge taps to it.

- [ ] **Step 4: Add the purchased badge to the active Configuration Center header**

Place `MemoMarkPlusBadge` beside `时光记` in `ConfigurationCenterTopPreviewSection`; keep the app name unchanged and show the badge only for verified entitlement.

- [ ] **Step 5: Add milestone presentation state**

Expose the record-190 and record-200 milestone from the commerce store. Show each once after successful save; do not block or obscure the completed output.

- [ ] **Step 6: Run responsive and UI contract tests**

Expected: existing Configuration Center and iPhone layout contracts remain green.

### Task 7: StoreKit Configuration, Verification, And Handoff

- [ ] **Step 1: Add a local StoreKit configuration**

Create `Source/PhotoMemo/Configuration.storekit` with the MemoMark+ non-consumable and a CNY 48 test price. Attach it only to local Debug scheme execution; TestFlight continues to use App Store Connect Sandbox product data.

- [ ] **Step 2: Run focused tests**

Run commerce, queue, Share Extension, settings, and responsive contract suites. Expected: pass.

- [ ] **Step 3: Run unsigned iOS and Share Extension build**

Run:

```bash
xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemoiOS -configuration Debug -derivedDataPath /tmp/PhotoMemoDerivedData CODE_SIGNING_ALLOWED=NO -quiet build
```

Expected: build succeeds.

- [ ] **Step 4: Record App Store Connect setup requirements**

Document the exact product ID, non-consumable type, CNY 48 initial tier, Family Sharing switch, localization, review screenshot, Paid Apps Agreement, Offer Code setup, and the rule that the same tested build is selected for App Review.

- [ ] **Step 5: Update repository status**

Add a bounded entry to `Docs/CURRENT_STATUS.md` or `HANDOFF.md` describing implementation, automated evidence, and remaining physical-device StoreKit verification.

- [ ] **Step 6: Perform final self-review**

Confirm no private images, credentials, StoreKit secrets, hard-coded localized price, Renderer changes, or unrelated user edits are included.

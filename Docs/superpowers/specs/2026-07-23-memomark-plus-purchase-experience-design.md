# MemoMark+ Purchase Experience Design

Date: 2026-07-23

Status: Product and UI design approved for specification review. StoreKit integration, release timing, entitlement migration, and production activation are not part of this design pass.

## 1. Purpose

MemoMark should introduce payment only after a user has formed real value through successful memory records. The purchase experience must preserve the product's local-first, Apple-native, respectful character and must not resemble a timer-based trial, advertisement, or photo-capacity upsell.

The product model is:

```text
MemoMark Free
-> 200 successfully saved growth records
-> MemoMark+ lifetime unlock
-> optional separately purchased collaboration Presets
```

MemoMark+ is the user-facing name. Internal Renderer terminology must not appear in purchase copy. Future paid Renderer work is presented to users as a collaboration Preset or separately purchased Preset collection.

## 2. Frozen Commercial Model

### 2.1 Free experience

MemoMark Free provides:

- 200 growth records;
- up to 20 photos added in one batch;
- full output quality;
- no advertisements;
- no additional purchase watermark;
- unchanged local-first processing and non-destructive output behavior.

The product must describe this as a `free growth record allowance`, not as a trial limit, storage quota, or remaining processing count.

### 2.2 MemoMark+

MemoMark+ is a non-consumable lifetime purchase. The first public offer is presented as:

```text
首批记录者感谢价
一次购买，永久使用
```

The initial intended China storefront price is CNY 48. The app must display the localized StoreKit price rather than hard-code `¥48`. The first-recorder offer has no visible purchaser count, remaining-place count, or countdown. The developer decides when the offer ends through App Store Connect and release operations.

MemoMark+ provides:

- unlimited growth records;
- up to 40 photos added in one batch;
- Family Sharing when enabled for the App Store product;
- continued updates to foundational Presets and core MemoMark capabilities;
- the first-recorder commemorative mark for eligible early purchasers and code recipients.

Cross-device configuration sync is not a MemoMark+ entitlement or future promise.

### 2.3 Separately purchased Presets

Future collaboration Presets, including possible externally designed Presets, may be sold separately as non-consumable content. Buying MemoMark+ does not promise access to every future Preset.

The MemoMark+ page must state:

```text
部分未来联名 Preset 可能单独提供
```

This statement protects the boundary between the core lifetime unlock and future design collaborations. It must remain secondary and must not distract from the current MemoMark+ value.

## 3. Counting Contract

A free record is consumed only after a generated output is successfully written back to Apple Photos.

The following do not consume an allowance:

- preview rendering;
- failed processing;
- failed Apple Photos saves;
- canceled work;
- retries of the same task;
- duplicate completion callbacks for the same task.

Each output task needs a durable unique identity so one successfully saved output can increment the count at most once. The 200th record must complete and save normally before the user sees the completion message or purchase invitation.

At record 201, new work must not enter processing unless MemoMark+ is active. Existing Apple Photos assets, generated outputs, saved configurations, and Configuration Center editing remain available.

Historical usage, migration behavior, reinstall behavior, and the production activation date require a separate engineering and release decision. This design does not retroactively count work produced by existing App Store or TestFlight builds.

## 4. Batch Contract

MemoMark Free accepts up to 20 photos in one batch. MemoMark+ accepts up to 40.

User-facing copy may say:

```text
单次最多处理 40 张照片
```

or:

```text
一次加入最多 40 张照片
```

It must not claim that 40 photos are processed concurrently. The processing pipeline retains ownership of safe concurrency and resource control.

For a larger batch, use the neutral guidance:

```text
处理较多照片可能需要更长时间，锁屏或切换 App 后，任务仍会按系统允许继续进行。
```

The guidance does not vary by device model in this product design. Engineering remains responsible for preventing unsafe memory or extension pressure.

## 5. Entry And Navigation

### 5.1 Settings placement

The Settings page places a compact MemoMark+ entitlement card at the top of its scroll content, before the current `为什么是时光记` section. This placement is necessary because the current overview is long and would otherwise bury the purchase entry.

The compact card is an entry and status surface, not a paywall. It opens a separate MemoMark+ page.

Free state before record 190:

```text
MemoMark+
继续保存那些未来值得回看的瞬间
[了解 MemoMark+]
```

Free state from record 190 onward:

```text
MemoMark+
还有 10 张免费成长记录
[了解 MemoMark+]
```

Purchased or redeemed state:

```text
MemoMark+
首批记录者 · 无限记录
愿今天留下的时光，在未来仍然清晰而温暖。
[查看权益与纪念印记]
```

Neither the main screen nor Settings reveals the allowance before record 190. Settings becomes a gentle remaining-record reminder only for the final ten free records; milestone messages remain the contextual entry.

### 5.2 Existing Settings compatibility

The current fixed `最多 20 张照片` capability row must become entitlement-aware when MemoMark+ is implemented:

- Free: `最多 20 张照片`;
- MemoMark+: `最多 40 张照片`.

The existing local configuration disclosure remains correct. No purchase copy may imply that MemoMark+ adds cross-device configuration sync.

### 5.3 Purchased home identity

After a verified purchase or eligible Offer Code redemption, the home header retains `时光记` as the primary product name and adds a compact warm-gold `MemoMark+` badge beside it. The app name, App Store name, Configuration Center name, and primary product title do not change to a separate Plus product.

Recommended composition:

```text
时光记   [ ✦ MemoMark+ ]
```

The badge uses a low-saturation champagne-gold or warm-brass foreground, a very light warm-gold fill, a fine border, and a small sparkle or plus mark. It must not use a crown, diamond, coin, `VIP` label, aggressive metallic shine, or continuously looping animation.

The badge may perform one short restrained highlight animation immediately after purchase or redemption. During normal use it remains static. Selecting it opens the MemoMark+ entitlement and first-recorder commemorative page.

VoiceOver reads:

```text
MemoMark+，已解锁，首批记录者
```

The badge is app chrome only. It never appears on the Memory Card, rendered output, exported photo, app icon, or original photo.

## 6. Milestone Experience

### 6.1 Early use

The first launch does not mention payment. The first successful output celebrates the completed memory record without advertising the 200-record allowance.

There is no message at record 50 or 150. This avoids turning normal use into a countdown.

### 6.2 Record 190

After the 190th successful save, show one non-blocking message:

```text
你已经留下 190 张成长记录

还有 10 张免费成长记录。
解锁 MemoMark+，继续记录此后的每一个瞬间。

[了解 MemoMark+]
[继续记录]
```

This milestone appears at most once for the entitlement lifecycle.

### 6.3 Record 200

The 200th output saves first. The completion surface then states:

```text
第 200 张成长记录已保存

你已经完成了 MemoMark 的免费成长记录旅程。
照片已完整保存到 Apple Photos。

MemoMark+
无限记录未来的时光

[成为首批记录者]
[稍后]
```

The message must lead with successful saving so the user never suspects that MemoMark withheld or degraded the final free output.

### 6.4 Record 201

When a free user requests new processing after the allowance is complete, present the MemoMark+ page before creating a new processing task. The user can dismiss it and retain access to settings, existing records, and existing outputs.

## 7. MemoMark+ Page

### 7.1 Content hierarchy

The page is a calm invitation to continue recording, not a membership storefront.

```text
MemoMark+

让未来的时光，继续被记录

你已经用 MemoMark 留下了许多值得回看的瞬间。
一次购买，继续完整记录此后的每一张照片。

[Localized StoreKit Price]
首批记录者感谢价
一次购买，永久使用

✓ 无限创建成长记录
✓ 单次最多处理 40 张照片
✓ 支持家庭共享
✓ 基础 Preset 与核心能力持续更新

[成为首批记录者 · Localized StoreKit Price]

兑换 MemoMark+ 代码
恢复购买

所有照片仍在本地处理
完整画质 · 无广告 · 不修改原始照片

部分未来联名 Preset 可能单独提供
```

If the first-recorder offer is no longer active, price and offer language come from the active product presentation. The page must not keep stale `感谢价` wording after the corresponding product or campaign ends.

### 7.2 Visual direction

- Use the established Apple-native, light-first Configuration Center language.
- Use a real Memory Card output detail as the visual anchor.
- Reuse the purchased home badge's restrained champagne-gold identity for eligible MemoMark+ status.
- Avoid crowns, diamonds, coins, countdowns, aggressive gradients, oversized sale badges, and generic subscription-page decoration.
- Keep the localized price as the strongest commercial information.
- Render `首批记录者感谢价` as a quiet, low-saturation warm label.
- Use the current Configuration Center accent treatment for the primary action.
- Preserve Dynamic Type, VoiceOver order, sufficient contrast, and a minimum 44-point interaction target.

## 8. Offer Code Redemption

MemoMark+ may be granted free or at a discount through App Store Connect Offer Codes associated with the MemoMark+ non-consumable in-app purchase.

App-level Promo Codes are not the MemoMark+ entitlement mechanism. MemoMark is a free app, so giving access to the app itself does not unlock MemoMark+.

The MemoMark+ page places `兑换 MemoMark+ 代码` below the primary purchase action and above or beside `恢复购买` as a secondary action. The Settings compact card does not add a separate redemption control.

Selecting the action presents Apple's StoreKit offer-code redemption sheet. MemoMark must not implement a custom code text field or custom validation UI. StoreKit owns invalid, expired, ineligible, canceled, and successful redemption feedback.

The app must also observe verified StoreKit transactions so redemptions completed through the App Store or an external redemption URL grant entitlement without delay.

A successfully redeemed MemoMark+ code grants the same product entitlement as a paid purchase:

- unlimited growth records;
- a 40-photo batch limit;
- Family Sharing according to App Store product configuration;
- restoration on the purchasing Apple Account;
- first-recorder identity when the redeemed offer belongs to the early-user campaign.

The product may distribute redemption links as the preferred campaign experience and plain codes as a fallback. Distribution terms, storefront eligibility, campaign expiry, and Apple-required holder terms belong to release operations, not the in-app page.

## 9. First-Recorder Commemorative Mark

### 9.1 Purpose

The mark thanks early supporters without ranking them, exposing purchaser counts, or introducing a server dependency.

### 9.2 Success experience

After a verified eligible purchase or redemption:

```text
感谢你成为
MemoMark 首批记录者

2026.08.18

愿今天认真留下的时光，
在未来仍然清晰而温暖。

[继续记录]
```

The date uses the verified transaction's original purchase or redemption date when available. A local date may be used immediately after success, but later restoration should reconcile it to StoreKit transaction truth.

### 9.3 Persistent location

Settings shows `首批记录者 · YYYY.MM.DD` in the purchased MemoMark+ card. Selecting `查看权益与纪念印记` reopens the entitlement detail and commemorative message.

The mark:

- has no sequential number;
- does not reveal the campaign size;
- never appears automatically on exported photos;
- does not modify Memory Card content;
- does not require cloud identity or an MemoMark account.

Family members receive shared MemoMark+ capabilities according to Apple's entitlement behavior. The commemorative identity and date follow the original eligible transaction rather than creating a new purchase date for each family member.

## 10. Purchase And Entitlement States

### 10.1 Cancel

Remain on the MemoMark+ page without an error alert or loss of context.

### 10.2 Pending

Show a neutral pending state and do not grant MemoMark+ until a verified transaction arrives. Existing free allowance remains unchanged.

### 10.3 Failure

Show a retryable explanation. Do not decrement allowance, create a processing task, or alter local records.

### 10.4 Success

Verify the transaction, update entitlement immediately, finish the transaction, and show the first-recorder success experience when eligible.

### 10.5 Restore

Restore MemoMark+ capability and the first-recorder identity associated with the verified original transaction. Restoration is not a new purchase and must not create a new commemorative date.

### 10.6 Refund or revocation

Recalculate entitlement from verified StoreKit state. Existing outputs and configurations remain untouched. Future processing returns to the applicable free allowance rules; detailed allowance behavior after revocation requires an engineering policy before release.

### 10.7 Offline

Existing locally cached verified entitlement may continue according to the StoreKit architecture chosen during implementation. New purchase and code redemption actions explain that the App Store connection is temporarily unavailable. Photo processing remains local.

### 10.8 TestFlight

TestFlight builds are treated as unlimited for product evaluation and do not show production allowance blocking. StoreKit sandbox and offer-code test surfaces may be enabled only in deliberate test scenarios. The exact build switch belongs to implementation and release planning.

## 11. Data And Ownership Boundaries

Implementation should separate these responsibilities:

- `MemoMark+ entitlement`: StoreKit product and verified transaction truth;
- `growth record allowance`: durable local count of unique successful Apple Photos saves;
- `batch selection limit`: policy derived from current entitlement;
- `first-recorder eligibility`: verified product or offer campaign identity;
- `purchase presentation`: localized price and eligibility-driven UI;
- `Preset ownership`: separate entitlements for future paid collaboration Presets.

The Renderer, Layout Engine, Metadata Engine, Export behavior, and Apple Photos save semantics are not modified by this product design. Monetization observes successful save completion; it does not take ownership of rendering or export decisions.

## 12. Accessibility And Product Language

- Use `MemoMark+`, `成长记录`, `Preset`, and `首批记录者` in user-facing copy.
- Do not use `Pro`, `Renderer`, `模板`, `试用到期`, `解除限制`, `容量`, or `剩余处理次数` as purchase language.
- Do not rely on color alone for free, purchased, pending, or failed state.
- Announce successful purchase or redemption and updated entitlement through VoiceOver.
- Keep legal and purchase controls readable at accessibility text sizes.
- Preserve system purchase and redemption sheets rather than imitating Apple transaction UI.

## 13. Verification Plan

Before production activation, verify:

1. Count transitions at successful records 189, 190, 199, 200, and a requested 201st record.
2. Failed, canceled, retried, and duplicate-callback tasks never consume extra allowance.
3. Free selection accepts 20 and rejects 21; MemoMark+ accepts 40 and rejects 41.
4. Purchase cancel, pending, failure, success, restore, refund, and revocation update UI and task admission correctly.
5. One-time and custom Offer Codes cover success, invalid, expired, ineligible, canceled, and externally redeemed transactions.
6. Family Sharing behavior matches App Store Connect configuration and verified StoreKit state.
7. First-recorder date survives restoration and is not replaced by a restore date.
8. TestFlight remains non-blocking while explicit StoreKit test configurations remain testable.
9. Settings capability copy changes between 20 and 40 without stale cached presentation.
10. Dynamic Type, VoiceOver, narrow iPhone widths, Reduce Motion, and light/dark appearance remain usable.
11. No purchase or redemption state changes existing photos, generated outputs, saved configurations, or local-first processing.
12. The purchased home badge appears only for verified entitlement, remains legible without color alone, opens the entitlement page, and never enters rendered or exported content.

## 14. Deferred Decisions

The following require separate implementation or release planning:

- production activation version and date;
- handling of existing App Store usage when counting begins;
- reinstall and local-count recovery policy;
- exact StoreKit product identifiers and campaign configuration;
- first-recorder campaign end conditions;
- localized price tiers after the first-recorder offer;
- exact collaboration Preset products and pricing;
- refund or revocation behavior when a user has already exceeded 200 records;
- final StoreKit API availability based on the deployment target and shipping SDK.

These deferrals do not block review of the content and interface design.

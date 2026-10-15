# Settings: App Store rating and manual update destinations

2026-10-15 owner priority insertion, main d17bf849. Product Loop / P2 bounded native iOS Settings support UI. Preserve dirty V5 candidate, iPhone/iPad navigation and rendering/business owners. No commit/push/release/cloud operations.

## Observation and research

Owner screenshot1: MemoMark+ and extended Getting Started, then existing disclosures; About already owns installed Bundle version and in-app release notes. Screenshot2: unrelated product with visible update/review utility rows; visual reference only, no redemption-code or paywall scope.

Primary sources checked2026-10-15:
- Things version/About and App Store manual updates: https://culturedcode.com/things/support/articles/2803598/
- Day One settings/Appearance/support separation, official illustrated guide: https://dayoneapp.com/guides/settings/accessing-the-settings-in-day-one-for-ios/
- Bear extension preferences (task-specific Settings): https://bear.app/faq/ios-app-extension/ ; no claim its current About contains rating/update rows.
- Apple HIG Settings: https://developer.apple.com/design/human-interface-guidelines/settings
- Apple requesting App Store reviews: https://developer.apple.com/documentation/storekit/requesting-app-store-reviews
- Apple manual app updates: https://support.apple.com/en-ie/102629

Inference/design decision: retain existing hierarchy and About disclosure, add utilities adjacent to installed version/release notes. Avoid copying decorative color/VIP/redemption mechanisms or changing Getting Started defaults. Existing long first section can be separately reconsidered later.

## Contract and ownership

About content presents Version → Check for Updates → Release Notes → Rate MemoMark. Existing page owns openURL and a failure alert. Use existing SettingsActionRow, SF Symbols, Dynamic Type, system colors, centered readable width; four locales. No new page/sheet for a two-link task.

Rating opens verified MemoMark App Store ID6788331801 with action=write-review; manual action must not call probabilistic requestReview. No rating gating, reward or automatic prompt. Updating opens product page in the person's storefront. Subtitle explicitly states App Store destination and does not claim a version check ran, latest-version availability or installation. Apple owns regional availability, compatibility, update/download/auth. TestFlight installed version may be newer than public; do not compare these or present downgrade as update. A rejected openURL displays a localized actionable error, no fake success. No auto network request, version lookup endpoint/cache, background task, photo/preset transmission, entitlement or persistent config changes. No Mac App Store destination added without a published Mac product identity.

## Implementation and validation

Allowlist: AboutSettingsContent, SettingsPageSurface, a tiny presentation-owned Foundation URL destination value, four existing Localizable.strings; focused destination tests plus settings/localization contracts; this spec/results/CURRENT_STATUS. Preserve before copies and check unrelated entry fingerprints.

1. Meaningful RED tests for exact ID/destination separation and HTTPS/storefront-neutral URLs. Implement constants and delegated native actions. Run focused tests.
2. Build iOS Simulator Debug and signed generic iOS Release; host test scheme when available, do not loop if runner stalls.
3. Native local independent phone and13inch iPad, light/dark, portrait/landscape and max Dynamic Type screenshots. Confirm rating/update rows, version/log behavior, localized text; native App Store handoff if available, else retain simulator failure as NOT VERIFIED and test URL contract separately. Do not submit review, buy or update during validation.
4. Scoped diff, source fingerprint check, saved raw PNG/AX/index. Physical App Store handoff/install and user visual acceptance remain owner-deferred.

## 文案跟进

用户希望评分入口更加俏皮、带支持意味。执行文案：标题“给时光记打个分”，说明“去 App Store，聊聊你的使用感受。”；保持每个人都可进入且不预筛满意度，不要求五星或给出奖励。JA/KO/EN使用自然、简短的同义表述。公开只读lookup已核对ID6788331801、bundle com.serydoo.PhotoMemo.iOS为MemoMark；该公开版本信息只用于身份核对，应用不新增lookup请求或版本比较逻辑。

## 用户反馈渠道修订

保留邮箱serydoo@gmail.com与既有诊断导出/TestFlight说明，删除GitHub反馈行/回调和相应无用文案。新增小红书反馈信息行：搜索MemoMark，找到账号直接私信问题/建议；依据现有CommunitySupportContent与项目对外资料，不编造profileURL或accountID。小红书从社区移至反馈，社区继续保留QQ与抖音，避免重复。仅展示/可选中文案，不自动发送消息或读账号隐私。扩展allowlist包含FeedbackSupportContent、CommunitySupportContent和对应现有渠道合同/本地化audit。

## 最终渠道范围（覆盖前文社区保留条款）

用户明确要求移除整个社区，实际尚无群体。不再展示QQ/抖音，不维持空社区。删除Settings community enum/披露binding与unused CommunitySupportContent及专用四语言文案。既有shared defaults中的历史communityExpanded值不迁移/清空；仅停止读取，以保护其他持久状态。反馈保留email和小红书私信信息，后置诊断/条件TestFlight。扩展allowlist包含现有LocalizationResourceParityTests并保留其before副本。中间测试/Release在用户调整范围时主动取消，最终候选按新范围顺序验证，不计取消为通过。

## 最大字号观察增量

原生iPad最大辅助字号09-max-about.png发现共享SettingsRowIcon字体随DynamicType增长，布局框却固定24pt，版本行图标挤到文字。新增allowlist SettingsSupportRowComponents.swift（before已存），按同一caption度量使用ScaledMetric调整图标占位，保持large下原24pt，不更改语义/行文本/偏好。重新Simulator/Release构建并补最大字号实图；先前74项测试针对同一行为/路由且无测试删除，本次仅显示度量。

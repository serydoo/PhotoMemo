#if os(iOS) && !MEMOMARK_SHARE_EXTENSION
import SwiftUI

struct MemoMarkPlusPurchaseView: View {

    @AppStorage(
        MemoMarkLanguage.interfacePreferenceStorageKey,
        store: MemoMarkSharedContainer.sharedUserDefaults
    )
    private var interfaceLanguagePreferenceRawValue =
        MemoMarkInterfaceLanguagePreference.system.rawValue

    @ObservedObject
    var store: MemoMarkCommerceStore

    let onDismiss: () -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    identitySection
                    planSection
                    benefitSection
                    actionSection
                    trustSection
                }
                .padding(.top, 18)
                .padding(.bottom, 34)
                .adaptiveScrollContent(
                    horizontalPadding:
                        ConfigurationUI
                        .contentColumnPadding
                )
            }
            .background(
                ConfigurationUI.appBackground
                    .ignoresSafeArea()
            )
            .navigationTitle(
                localized(
                    "commerce.title",
                    fallback: "MemoMark+"
                )
            )
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(
                    placement: .topBarTrailing
                ) {
                    Button(
                        localized(
                            "commerce.done",
                            fallback: "完成"
                        ),
                        action: onDismiss
                    )
                        .font(.caption.weight(.semibold))
                }
            }
        }
        .memoMarkSheet(.browser)
    }

    private var identitySection: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(
                        Color(
                            red: 0.98,
                            green: 0.94,
                            blue: 0.82
                        )
                    )
                Image(
                    systemName:
                        store.isPlus
                        ? "checkmark.seal.fill"
                        : "sparkles"
                )
                .font(.title.weight(.semibold))
                .foregroundStyle(warmGold)
            }
            .frame(width: 56, height: 56)

            Text(
                heroTitle
            )
            .font(.title3.weight(.bold))
            .multilineTextAlignment(.center)

            if store.hasFirstRecorderIdentity {
                Text(firstRecorderDateText)
                    .font(.caption.weight(.semibold).monospacedDigit())
                    .foregroundStyle(warmGold)

                Text(
                    localized(
                        "commerce.purchase.hero.first_recorder_message",
                        fallback: "愿今天认真留下的时光，\n在未来仍然清晰而温暖。"
                    )
                )
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            } else if store.isTestFlightExperienceActive {
                Text(
                    localized(
                        "commerce.purchase.hero.testflight_message",
                        fallback: "当前 TestFlight 版本可无限创建成长记录。\n正式版权益仍由 Apple 购买或兑换决定。"
                    )
                )
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            } else {
                Text(
                    localized(
                        "commerce.purchase.hero.free_message",
                    fallback: "订阅 MemoMark+，完整记录此后的每一张照片。"
                    )
                )
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }

    private var benefitSection: some View {
        ConfigurationCardSurface(
            title: localized(
                "commerce.purchase.benefits.title",
                fallback: "完整记录能力"
            ),
            systemImage: "heart.text.square.fill",
            tint: .pink
        ) {
            VStack(spacing: 9) {
                benefit(
                    localized(
                        "commerce.purchase.benefit.unlimited_records",
                        fallback: "本地不限量处理照片"
                    ),
                    "infinity"
                )
                benefit(
                    localized(
                        "commerce.purchase.benefit.objects_anchors",
                        fallback: "解锁更多记忆对象与时间锚点"
                    ),
                    "point.3.connected.trianglepath.dotted"
                )
                benefit(
                    localized(
                        "commerce.purchase.benefit.expressions",
                        fallback: "全部第一方表达方式一次开放"
                    ),
                    "text.badge.star"
                )
                benefit(
                    localized(
                        "commerce.purchase.benefit.batch_40",
                        fallback: "单次最多处理 40 张照片"
                    ),
                    "rectangle.stack.fill"
                )
                benefit(
                    localized(
                        "commerce.purchase.benefit.family_sharing",
                        fallback: "支持家庭共享"
                    ),
                    "person.2.fill"
                )
                benefit(
                    localized(
                        "commerce.purchase.benefit.core_updates",
                        fallback: "基础 Preset 与核心能力持续更新"
                    ),
                    "sparkles.rectangle.stack"
                )
            }
        }
    }

    @ViewBuilder
    private var planSection: some View {
        let periods = store.availableSubscriptionPeriods
        if !store.isPlus && periods.count > 1 {
            VStack(alignment: .leading, spacing: 10) {
                Label(
                    localized(
                        "commerce.purchase.plan.title",
                        fallback: "选择订阅周期"
                    ),
                    systemImage: "calendar.badge.clock"
                )
                .font(.headline.weight(.semibold))

                HStack(alignment: .top, spacing: 12) {
                    ForEach(periods) { period in
                        subscriptionPlanCard(for: period)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color.primary.opacity(0.045))
            )
        }
    }

    private func subscriptionPlanCard(
        for period: MemoMarkSubscriptionPeriod
    ) -> some View {
        let isSelected =
            store.selectedSubscriptionPeriod == period
        let accent =
            period == .annual ? warmGold : Color.accentColor

        return Button {
            store.selectSubscriptionPeriod(period)
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .top, spacing: 6) {
                    Text(planTitle(for: period))
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                    Spacer(minLength: 0)
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(accent)
                    }
                }

                if period == .annual {
                    Text(
                        localized(
                            "commerce.purchase.plan.annual_badge",
                            fallback: "年度更优惠"
                        )
                    )
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(accent)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(
                        Capsule(style: .continuous)
                            .fill(accent.opacity(0.14))
                    )
                } else {
                    Text(
                        localized(
                            "commerce.purchase.plan.monthly_badge",
                            fallback: "灵活订阅"
                        )
                    )
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                }

                Text(store.displayPrice(for: period))
                    .font(.title3.weight(.bold))
                    .monospacedDigit()
                    .foregroundStyle(.primary)

                Text(planSubtitle(for: period))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity, minHeight: 104, alignment: .topLeading)
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(
                        isSelected
                        ? accent.opacity(0.12)
                        : Color.primary.opacity(0.035)
                    )
            )
            .overlay {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(
                        isSelected
                        ? accent.opacity(0.72)
                        : Color.primary.opacity(0.10),
                        lineWidth: isSelected ? 1.5 : 1
                    )
            }
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityLabel(
            "\(planTitle(for: period))，\(store.displayPrice(for: period))"
        )
    }

    private func planTitle(
        for period: MemoMarkSubscriptionPeriod
    ) -> String {
        switch period {
        case .annual:
            return localized(
                "commerce.purchase.plan.annual",
                fallback: "年度 · 更优惠"
            )
        case .monthly:
            return localized(
                "commerce.purchase.plan.monthly",
                fallback: "月度"
            )
        }
    }

    private func planSubtitle(
        for period: MemoMarkSubscriptionPeriod
    ) -> String {
        switch period {
        case .annual:
            return localized(
                "commerce.purchase.plan.annual_subtitle",
                fallback: "长期记录更合适"
            )
        case .monthly:
            return localized(
                "commerce.purchase.plan.monthly_subtitle",
                fallback: "按月灵活管理"
            )
        }
    }

    private var actionSection: some View {
        VStack(spacing: 12) {
            if !store.isPlus {
                VStack(spacing: 4) {
                    Text(purchasePrice)
                        .font(.largeTitle.weight(.bold))
                        .monospacedDigit()
                    Text(
                        purchasePriceNote
                    )
                        .font(.caption)
                        .foregroundStyle(warmGold)
                }

                Button(action: purchase) {
                    HStack {
                        if store.isPurchaseActionInProgress {
                            ProgressView()
                                .tint(.white)
                        }
                        Text(primaryButtonTitle)
                            .font(.headline.weight(.semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 50)
                }
                .buttonStyle(.borderedProminent)
                .disabled(
                    store.isPurchaseActionInProgress
                )

                if store.isTestFlightExperienceActive {
                    Button(
                        localized(
                            "commerce.purchase.testflight.deactivate",
                            fallback: "退出 TestFlight 临时体验"
                        ),
                        role: .destructive
                    ) {
                        store.deactivateTestFlightExperience()
                    }
                    .font(.subheadline)
                }
            } else {
                Label(
                    localized(
                        "commerce.purchase.entitled",
                        fallback: "MemoMark+ 权益已全部开放"
                    ),
                    systemImage: "checkmark.seal.fill"
                )
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.green)
                .frame(maxWidth: .infinity)
            }

            if case .failed(let message) =
                store.purchaseState {
                Text(message)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
            } else if store.purchaseState == .pending {
                Text(
                    localized(
                        "commerce.purchase.pending",
                        fallback: "购买正在等待确认，完成后会自动解锁。"
                    )
                )
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else if store.purchaseState == .restoring {
                Text(localized(
                    "commerce.purchase.restoring",
                    fallback: "正在恢复购买…"
                ))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else if store.purchaseState == .redeeming {
                Text(localized(
                    "commerce.purchase.redeeming",
                    fallback: "正在打开兑换页面…"
                ))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if !store.isPlus {
                Button(
                    localized(
                        "commerce.purchase.apple_code",
                        fallback: "兑换 MemoMark+ 代码"
                    )
                ) {
                    Task {
                        await store.redeemOfferCode()
                    }
                }
                .font(.subheadline.weight(.semibold))
                .disabled(store.isPurchaseActionInProgress)
            }

            Button(
                localized(
                    "commerce.purchase.restore",
                    fallback: "恢复购买"
                )
            ) {
                Task {
                    await store.restorePurchases()
                }
            }
            .font(.subheadline)
            .disabled(store.isPurchaseActionInProgress)
        }
        .padding(.horizontal, 2)
    }

    private var trustSection: some View {
        VStack(spacing: 8) {
            Label(
                localized(
                    "commerce.purchase.trust.local_processing",
                    fallback: "所有照片仍在设备本地处理"
                ),
                systemImage: "lock.shield.fill"
            )
            .font(.subheadline.weight(.semibold))

            Text(
                localized(
                    "commerce.purchase.trust.quality",
                    fallback: "完整画质 · 无广告 · 不修改原始照片"
                )
            )
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(
                localized(
                    "commerce.purchase.trust.future_presets",
                    fallback: "部分未来联名 Preset 可能单独提供"
                )
            )
                .font(.caption2)
                .foregroundStyle(.tertiary)

            if store.environment == .sandbox {
                Text(
                    localized(
                        "commerce.purchase.testflight.sandbox_notice",
                        fallback: "当前为 TestFlight / Sandbox 环境，不会产生实际费用，也不会转移到 App Store 正式版。"
                    )
                )
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.top, 4)
            }

            HStack(spacing: 16) {
                Link(
                    localized(
                        "commerce.purchase.privacy_policy",
                        fallback: "隐私政策"
                    ),
                    destination: Self.privacyPolicyURL
                )
                Link(
                    localized(
                        "commerce.purchase.terms_of_use",
                        fallback: "使用条款"
                    ),
                    destination: Self.termsOfUseURL
                )
            }
            .font(.caption2)
            .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 4)
    }

    private func benefit(
        _ title: String,
        _ systemImage: String
    ) -> some View {
        HStack(spacing: 11) {
            Image(systemName: systemImage)
                .foregroundStyle(Color.accentColor)
                .frame(width: 24)
            Text(title)
                .font(.subheadline.weight(.medium))
            Spacer(minLength: 0)
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
        }
        .accessibilityElement(children: .combine)
    }

    private var primaryButtonTitle: String {
        guard store.displayPrice != "—" else {
            if case .failed = store.purchaseState {
                return localized(
                    "commerce.purchase.retry",
                    fallback: "重新连接 App Store"
                )
            }

            return localized(
                "commerce.purchase.connecting",
                fallback: "正在连接 App Store"
            )
        }

        return formatted(
            "commerce.purchase.primary_format.subscription",
            fallback: "订阅 MemoMark+ · %@",
            store.displayPrice
        )
    }

    private var purchasePrice: String {
        store.displayPrice == "—"
        ? localized(
            "commerce.purchase.connecting",
            fallback: "正在连接 App Store"
        )
        : store.displayPrice
    }

    private var purchasePriceNote: String {
        return localized(
            "commerce.purchase.price_note.subscription",
            fallback: "自动续订 · 周期与价格由 App Store 显示"
        )
    }

    private var heroTitle: String {
        if store.hasFirstRecorderIdentity {
            return localized(
                "commerce.purchase.hero.first_recorder",
                fallback: "感谢你成为 MemoMark 首批记录者"
            )
        }

        if store.hasFounderLifetimeEntitlement {
            return localized(
                "commerce.purchase.hero.plus",
                fallback: "MemoMark+ 已永久解锁"
            )
        }

        if store.hasActiveSubscription {
            return localized(
                "commerce.purchase.hero.subscription",
                fallback: "MemoMark+ 订阅会员已生效"
            )
        }

        if store.isTestFlightExperienceActive {
            return localized(
                "commerce.purchase.hero.testflight",
                fallback: "MemoMark+ TestFlight 体验已激活"
            )
        }

        return localized(
            "commerce.purchase.hero.continuity",
            fallback: "让未来的时光，继续被记录"
        )
    }

    private func purchase() {
        Task {
            await store.purchasePlus()
        }
    }

    private var firstRecorderDateText: String {
        guard let date =
                store.snapshot
                .firstRecorderDate else {
            return localized(
                "commerce.purchase.first_recorder_label",
                fallback: "首批记录者"
            )
        }

        return date.formatted(
            .dateTime
            .year()
            .month(.twoDigits)
            .day(.twoDigits)
            .locale(
                interfaceLanguage.locale
            )
        )
    }

    private var warmGold: Color {
        Color(
            red: 0.58,
            green: 0.40,
            blue: 0.13
        )
    }

    private static let privacyPolicyURL = URL(
        string: "https://github.com/serydoo/PhotoMemo/blob/main/PRIVACY.md"
    )!
    private static let termsOfUseURL = URL(
        string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/"
    )!

    private func localized(
        _ key: String,
        fallback: String
    ) -> String {
        interfaceLanguage
            .localized(
                key: key,
                fallback: fallback
            )
    }

    private func formatted(
        _ key: String,
        fallback: String,
        _ arguments: CVarArg...
    ) -> String {
        String(
            format: localized(
                key,
                fallback: fallback
            ),
            locale:
                interfaceLanguage.locale,
            arguments: arguments
        )
    }

    private var interfaceLanguage: MemoMarkLanguage {
        MemoMarkInterfaceLanguagePreference(
            rawValue: interfaceLanguagePreferenceRawValue
        )?.resolvedLanguage
        ?? MemoMarkLanguage.interfaceStored
    }
}
#endif

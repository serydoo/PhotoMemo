#if os(iOS) && !PHOTOMEMO_SHARE_EXTENSION
import SwiftUI

struct MemoMarkPlusPurchaseView: View {

    @ObservedObject
    var store: MemoMarkCommerceStore

    let onDismiss: () -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    identitySection
                    benefitSection
                    actionSection
                    trustSection
                }
                .padding(.top, 18)
                .padding(.bottom, 34)
                .v1AdaptiveScrollContent(
                    horizontalPadding:
                        ConfigurationUI
                        .contentColumnPadding
                )
            }
            .background(
                ConfigurationUI.appBackground
                    .ignoresSafeArea()
            )
            .navigationTitle("MemoMark+")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(
                    placement: .topBarTrailing
                ) {
                    Button("完成", action: onDismiss)
                        .font(.caption.weight(.semibold))
                }
            }
        }
    }

    private var identitySection: some View {
        VStack(spacing: 12) {
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
            .frame(width: 68, height: 68)

            Text(
                store.isPlus
                ? "感谢你成为 MemoMark 首批记录者"
                : "让未来的时光，继续被记录"
            )
            .font(.title2.weight(.bold))
            .multilineTextAlignment(.center)

            if store.isPlus {
                Text(firstRecorderDateText)
                    .font(.headline.monospacedDigit())
                    .foregroundStyle(warmGold)

                Text("愿今天认真留下的时光，\n在未来仍然清晰而温暖。")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            } else {
                Text("一次购买，继续完整记录此后的每一张照片。")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
    }

    private var benefitSection: some View {
        V1CardSurface(
            title: "完整记录能力",
            systemImage: "heart.text.square.fill",
            tint: .pink
        ) {
            VStack(spacing: 13) {
                benefit("无限创建成长记录", "infinity")
                benefit("单次最多处理 40 张照片", "rectangle.stack.fill")
                benefit("支持家庭共享", "person.2.fill")
                benefit("基础 Preset 与核心能力持续更新", "sparkles.rectangle.stack")
            }
        }
    }

    private var actionSection: some View {
        VStack(spacing: 12) {
            if !store.isPlus {
                VStack(spacing: 4) {
                    Text(store.displayPrice)
                        .font(.largeTitle.weight(.bold))
                        .monospacedDigit()
                    Text("首批记录者感谢价 · 一次购买，永久使用")
                        .font(.caption)
                        .foregroundStyle(warmGold)
                }

                Button {
                    Task {
                        await store.purchasePlus()
                    }
                } label: {
                    HStack {
                        if store.purchaseState
                            == .purchasing {
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
                    store.product == nil
                    || store.purchaseState
                        == .purchasing
                )
            }

            if case .failed(let message) =
                store.purchaseState {
                Text(message)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
            } else if store.purchaseState == .pending {
                Text("购买正在等待确认，完成后会自动解锁。")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if !store.isPlus {
                Button("兑换 MemoMark+ 代码") {
                    Task {
                        await store.redeemOfferCode()
                    }
                }
                .font(.subheadline.weight(.semibold))
            }

            Button("恢复购买") {
                Task {
                    await store.restorePurchases()
                }
            }
            .font(.subheadline)
        }
        .padding(.horizontal, 2)
    }

    private var trustSection: some View {
        VStack(spacing: 8) {
            Label(
                "所有照片仍在设备本地处理",
                systemImage: "lock.shield.fill"
            )
            .font(.subheadline.weight(.semibold))

            Text("完整画质 · 无广告 · 不修改原始照片")
                .font(.caption)
                .foregroundStyle(.secondary)

            Text("部分未来联名 Preset 可能单独提供")
                .font(.caption2)
                .foregroundStyle(.tertiary)

            if store.environment == .sandbox {
                Text("当前为 TestFlight / Sandbox 测试交易，不会产生实际费用，也不会转移到 App Store 正式版。")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.top, 4)
            }
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
        store.displayPrice == "—"
        ? "正在连接 App Store"
        : "成为首批记录者 · \(store.displayPrice)"
    }

    private var firstRecorderDateText: String {
        guard let date =
                store.snapshot
                .firstRecorderDate else {
            return "首批记录者"
        }

        return date.formatted(
            .dateTime
            .year()
            .month(.twoDigits)
            .day(.twoDigits)
            .locale(
                Locale(identifier: "zh_CN")
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
}
#endif

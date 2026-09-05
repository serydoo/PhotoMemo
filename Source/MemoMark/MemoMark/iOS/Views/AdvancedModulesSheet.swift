#if os(iOS) && !MEMOMARK_SHARE_EXTENSION
import SwiftUI

struct AdvancedModulesSheet: View {

    @Environment(\.dynamicTypeSize)
    private var dynamicTypeSize

    @Environment(\.dismiss)
    private var dismiss

    let locationPresentation:
        LocationDisplayInspectorPresentation

    @Binding
    var selectedLocationOptionID: String

    let timePresentation: TimeDisplayInspectorPresentation

    @Binding
    var selectedTimeOptionID: String

    @Binding
    var selectedTimeSupplement: TimeDisplayConfiguration.Supplement

    var body: some View {
        NavigationStack {
            ScrollView {
                IOSCompactEntryListGroup {
                    locationDisplayRow
                        .padding(
                            .horizontal,
                            ConfigurationUI.sheetPanelPadding
                        )
                        .padding(
                            .vertical,
                            ConfigurationUI.compactRowVerticalPadding
                        )

                    HorizontalDivider(
                        horizontalInset: ConfigurationUI.sheetDividerInset
                    )

                    timeDisplaySelectionRow
                        .padding(
                            .horizontal,
                            ConfigurationUI.sheetPanelPadding
                        )
                        .padding(
                            .vertical,
                            ConfigurationUI.compactRowVerticalPadding
                        )

                    HorizontalDivider(
                        horizontalInset: ConfigurationUI.sheetDividerInset
                    )

                    timeSupplementRow
                        .padding(
                            .horizontal,
                            ConfigurationUI.sheetPanelPadding
                        )
                        .padding(
                            .vertical,
                            ConfigurationUI.compactRowVerticalPadding
                        )
                }
                .padding(.bottom, 28)
                .adaptiveScrollContent(
                    horizontalPadding: ConfigurationUI.contentColumnPadding
                )
            }
            .safeAreaInset(edge: .top, spacing: 0) {
                ConfigurationSheetSubtitle(
                    "决定照片中的时间和地点怎样呈现。"
                )
            }
            .background(
                ConfigurationUI.appBackground.ignoresSafeArea()
            )
            .navigationTitle("时间与地点")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
        }
        .memoMarkSheet(
            .browser,
            detents: [
                .height(ConfigurationUI.compactSheetHeight),
                .large
            ]
        )
    }

    @ViewBuilder
    private var locationDisplayRow: some View {
        if dynamicTypeSize.isAccessibilitySize {
            verticalLocationDisplayRow
        } else {
            horizontalLocationDisplayRow
        }
    }

    private var horizontalLocationDisplayRow: some View {
        HStack(alignment: .center, spacing: 10) {
            locationDisplayHeading

            Spacer(minLength: 8)

            locationDisplayMenu
                .frame(
                    minWidth: 72,
                    maxWidth: ConfigurationUI.compactTrailingControlWidth,
                    alignment: .trailing
                )
        }
    }

    private var verticalLocationDisplayRow: some View {
        VStack(
            alignment: .leading,
            spacing: MemoMarkDesignTokens.Spacing.medium
        ) {
            locationDisplayHeading

            locationDisplayMenu
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
    }

    private var locationDisplayHeading: some View {
        VStack(
            alignment: .leading,
            spacing: MemoMarkDesignTokens.Spacing.extraSmall
        ) {
            Text(localized("地点显示"))
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)

            Text(localized("选择地点在卡片里怎样显示。"))
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .layoutPriority(1)
    }

    @ViewBuilder
    private var timeDisplaySelectionRow: some View {
        if dynamicTypeSize.isAccessibilitySize {
            verticalTimeDisplayRow
        } else {
            horizontalTimeDisplayRow
        }
    }

    private var horizontalTimeDisplayRow: some View {
        HStack(alignment: .center, spacing: 10) {
            timeDisplayHeading

            Spacer(minLength: 8)

            timeDisplayMenu
                .frame(
                    minWidth: 72,
                    maxWidth: ConfigurationUI.compactTrailingControlWidth,
                    alignment: .trailing
                )
        }
    }

    private var verticalTimeDisplayRow: some View {
        VStack(
            alignment: .leading,
            spacing: MemoMarkDesignTokens.Spacing.medium
        ) {
            timeDisplayHeading

            timeDisplayMenu
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
    }

    private var timeDisplayHeading: some View {
        VStack(
            alignment: .leading,
            spacing: MemoMarkDesignTokens.Spacing.extraSmall
        ) {
            Text(localized("时间显示"))
                .font(.subheadline.weight(.semibold))

            Text(localized("选择拍摄时间怎样显示。"))
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .layoutPriority(1)
    }

    private var timeDisplayMenu: some View {
        Menu {
            ForEach(timePresentation.options) { option in
                Button {
                    selectedTimeOptionID = option.id
                } label: {
                    if option.id == selectedTimeOptionID {
                        Label(
                            localized(option.title),
                            systemImage: "checkmark"
                        )
                    } else {
                        Text(localized(option.title))
                    }
                }
            }
        } label: {
            CompactSelectionLabel(title: selectedTimeValue)
        }
        .accessibilityLabel(localized("时间显示"))
        .accessibilityValue(selectedTimeValue)
    }

    private var selectedTimeValue: String {
        localized(
            timePresentation.options.first {
                $0.id == selectedTimeOptionID
            }?.title
            ?? timePresentation.selectedValue
        )
    }

    @ViewBuilder
    private var timeSupplementRow: some View {
        if dynamicTypeSize.isAccessibilitySize {
            VStack(alignment: .leading, spacing: 10) {
                timeSupplementHeading

                timeSupplementMenu
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
        } else {
            HStack(alignment: .center, spacing: 10) {
                timeSupplementHeading

                Spacer(minLength: 8)

                timeSupplementMenu
                    .frame(
                        minWidth: 72,
                        maxWidth:
                            ConfigurationUI.compactTrailingControlWidth,
                        alignment: .trailing
                    )
            }
        }
    }

    private var timeSupplementHeading: some View {
        VStack(
            alignment: .leading,
            spacing: MemoMarkDesignTokens.Spacing.extraSmall
        ) {
            Text(localized("日期补充"))
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)

            Text(localized("补充农历、节气或节日信息。"))
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var timeSupplementMenu: some View {
        Menu {
            ForEach(
                TimeDisplayConfiguration.Supplement.allCases,
                id: \.self
            ) { supplement in
                Button {
                    selectedTimeSupplement = supplement
                } label: {
                    if supplement == selectedTimeSupplement {
                        Label(
                            timeSupplementTitle(supplement),
                            systemImage: "checkmark"
                        )
                    } else {
                        Text(timeSupplementTitle(supplement))
                    }
                }
            }
        } label: {
            CompactSelectionLabel(
                title: timeSupplementTitle(selectedTimeSupplement)
            )
        }
        .accessibilityLabel(localized("日期补充"))
        .accessibilityValue(timeSupplementTitle(selectedTimeSupplement))
    }

    private func timeSupplementTitle(_ supplement: TimeDisplayConfiguration.Supplement) -> String {
        switch supplement {
        case .none: return localized("不显示")
        case .lunar: return localized("农历")
        case .lunarAndSolarTerm: return localized("农历 · 节气")
        case .holiday: return localized("节日")
        case .statutoryHoliday: return localized("法定假日")
        }
    }

    private var locationDisplayMenu: some View {
        Menu {
            ForEach(locationPresentation.options) { option in
                Button {
                    selectedLocationOptionID = option.id
                } label: {
                    if option.id == selectedLocationOptionID {
                        Label(
                            localized(option.title),
                            systemImage: "checkmark"
                        )
                    } else {
                        Text(localized(option.title))
                    }
                }
            }
        } label: {
            CompactSelectionLabel(title: selectedLocationValue)
        }
        .accessibilityLabel(localized("地点显示"))
        .accessibilityValue(selectedLocationValue)
    }

    private var selectedLocationValue: String {
        localized(
            locationPresentation.options
                .first {
                    $0.id == selectedLocationOptionID
                }?
                .title
            ?? locationPresentation.selectedValue
        )
    }

    private func localized(_ value: String) -> String {
        MemoMarkLanguage.interfaceStored.localized(
            key: value,
            fallback: value
        )
    }
}
#endif

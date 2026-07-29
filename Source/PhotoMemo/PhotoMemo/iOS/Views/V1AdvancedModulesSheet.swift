#if os(iOS) && !PHOTOMEMO_SHARE_EXTENSION
import SwiftUI

struct V1AdvancedModulesSheet: View {

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
            List {
                Section {
                    VStack(spacing: 0) {
                        locationDisplayRow
                        V1HorizontalDivider(horizontalInset: 0)
                        timeDisplayRow
                    }
                } header: {
                    Text("高级模块")
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("高级模块")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.fraction(0.58), .large])
        .presentationDragIndicator(.visible)
    }

    @ViewBuilder
    private var locationDisplayRow: some View {
        if dynamicTypeSize.isAccessibilitySize {
            verticalLocationDisplayRow
        } else {
            ViewThatFits(in: .horizontal) {
                horizontalLocationDisplayRow
                verticalLocationDisplayRow
            }
        }
    }

    private var horizontalLocationDisplayRow: some View {
        HStack(alignment: .center, spacing: 10) {
            locationDisplayHeading

            Spacer(minLength: 8)

            locationDisplayMenu
                .frame(
                    minWidth: 72,
                    maxWidth: 128,
                    alignment: .trailing
                )
        }
    }

    private var verticalLocationDisplayRow: some View {
        VStack(alignment: .leading, spacing: 10) {
            locationDisplayHeading

            locationDisplayMenu
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var locationDisplayHeading: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text("地理显示")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)

            Text("地点想怎样被写下。")
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .layoutPriority(1)
    }

    private var timeDisplayRow: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .center, spacing: 10) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("时间显示")
                        .font(.subheadline.weight(.semibold))
                    Text("照片时间想怎样被写下。")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 8)
                Menu {
                    ForEach(timePresentation.options) { option in
                        Button {
                            selectedTimeOptionID = option.id
                        } label: {
                            if option.id == selectedTimeOptionID {
                                Label(option.title, systemImage: "checkmark")
                            } else {
                                Text(option.title)
                            }
                        }
                    }
                } label: {
                    optionSelectionPill(title: selectedTimeValue)
                }
                .frame(minWidth: 72, maxWidth: 128)
                .accessibilityLabel("时间显示")
                .accessibilityValue(selectedTimeValue)
            }

            Menu {
                ForEach(TimeDisplayConfiguration.Supplement.allCases, id: \.self) { supplement in
                    Button {
                        selectedTimeSupplement = supplement
                    } label: {
                        if supplement == selectedTimeSupplement {
                            Label(timeSupplementTitle(supplement), systemImage: "checkmark")
                        } else {
                            Text(timeSupplementTitle(supplement))
                        }
                    }
                }
            } label: {
                HStack {
                    Text("时间补充")
                    Spacer()
                    Text(timeSupplementTitle(selectedTimeSupplement))
                        .foregroundStyle(.secondary)
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(.secondary)
                }
                .font(.caption)
                .padding(.horizontal, 9)
                .padding(.vertical, 7)
                .background(ConfigurationUI.controlBackground)
                .clipShape(RoundedRectangle(cornerRadius: ConfigurationUI.smallCornerRadius, style: .continuous))
            }
            .accessibilityLabel("时间补充")
            .accessibilityValue(timeSupplementTitle(selectedTimeSupplement))
        }
    }

    private var selectedTimeValue: String {
        timePresentation.options.first { $0.id == selectedTimeOptionID }?.title
            ?? timePresentation.selectedValue
    }

    private func timeSupplementTitle(_ supplement: TimeDisplayConfiguration.Supplement) -> String {
        switch supplement {
        case .none: return "不显示"
        case .lunar: return "农历"
        case .lunarAndSolarTerm: return "农历 · 节气"
        case .holiday: return "节日"
        case .statutoryHoliday: return "法定假日"
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
                            option.title,
                            systemImage: "checkmark"
                        )
                    } else {
                        Text(option.title)
                    }
                }
            }
        } label: {
            optionSelectionPill(title: selectedLocationValue)
        }
        .accessibilityLabel("地理显示")
        .accessibilityValue(selectedLocationValue)
    }

    private func optionSelectionPill(title: String) -> some View {
        HStack(spacing: 6) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.76)
                .allowsTightening(true)
                .truncationMode(.tail)

            Image(systemName: "chevron.down")
                .font(.caption2.weight(.bold))
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 6)
        .frame(maxWidth: .infinity, alignment: .trailing)
        .background(
            RoundedRectangle(
                cornerRadius: ConfigurationUI.smallCornerRadius,
                style: .continuous
            )
            .fill(ConfigurationUI.controlBackground)
        )
        .overlay(
            RoundedRectangle(
                cornerRadius: ConfigurationUI.smallCornerRadius,
                style: .continuous
            )
            .stroke(ConfigurationUI.faintHairline)
        )
    }

    private var selectedLocationValue: String {
        locationPresentation.options
            .first {
                $0.id == selectedLocationOptionID
            }?
            .title
        ?? locationPresentation.selectedValue
    }
}
#endif

#if os(iOS) && !PHOTOMEMO_SHARE_EXTENSION
import SwiftUI

struct ConfigurationCenterMemoryWritePanelModel:
    Equatable {

    let description: String
    let toggleTitle: String
    let inputPlaceholder: String
    let resolvedTitle: String
    let resolvedText: String
    let showsCustomTextField: Bool
}

struct ConfigurationCenterOutputSelectionPanelModel:
    Equatable {

    let presentation:
        ConfigurationCenterOutputPanelPresentation
}

struct ConfigurationCenterGuideCardModel:
    Identifiable,
    Equatable {

    var id: String { title }

    let title: String
    let note: String
    let systemImage: String
}

struct ConfigurationCenterLocationDisplayPanel:
    View {

    let presentation:
        LocationDisplayInspectorPresentation

    let locationModule:
        IOSInsertedModule?

    @Binding
    var selectedOptionID: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .center, spacing: 10) {
                Image(systemName: presentation.systemImage)
                    .font(.subheadline.weight(.semibold))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(iconColor)
                    .frame(width: 20)

                VStack(alignment: .leading, spacing: 3) {
                    Text(presentation.title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.primary)

                    Text(currentValueText)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: 0)

                Picker(
                    presentation.title,
                    selection: $selectedOptionID
                ) {
                    ForEach(presentation.options) { option in
                        Text(option.title)
                            .tag(option.id)
                    }
                }
                .labelsHidden()
                .pickerStyle(.menu)
            }

            if let statusDetail {
                Text(statusDetail)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(12)
        .configurationPanelChrome()
    }

    private var currentValueText: String {
        return LocationDisplayInspectorPresenter
            .selectedValue(
                fromConfiguration:
                    LocationDisplayInspectorPresenter
                    .configuration(
                        for: selectedOptionID
                    )
            )
    }

    private var iconColor: Color {
        locationModule == nil
        ? Color.secondary
        : Color.accentColor
    }

    private var selectedOptionNote: String? {
        presentation
            .options
            .first {
                $0.id == selectedOptionID
            }?
            .note
    }

    private var statusDetail: String? {
        guard locationModule != nil else {
            return "当前选择将在插入位置模块后生效。"
        }

        return selectedOptionNote
    }
}

struct ConfigurationCenterMemoryWritePanel: View {

    let model: ConfigurationCenterMemoryWritePanelModel

    @Binding
    var usesCustomText: Bool

    @Binding
    var customText: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(model.description)
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            Toggle(
                model.toggleTitle,
                isOn: $usesCustomText
            )
            .font(.subheadline.weight(.semibold))

            if model.showsCustomTextField {
                TextField(
                    model.inputPlaceholder,
                    text: $customText,
                    axis: .vertical
                )
                .textFieldStyle(.plain)
                .font(.subheadline)
                .lineLimit(1...3)
                .configurationFieldChrome(isActive: true)
            }

            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "text.magnifyingglass")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .frame(width: 15)

                VStack(alignment: .leading, spacing: 3) {
                    Text(model.resolvedTitle)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)

                    Text(model.resolvedText)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(Color.primary.opacity(0.82))
                        .lineLimit(3)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(10)
            .configurationPanelChrome()
        }
        .padding(10)
        .configurationPanelChrome()
    }
}

struct ConfigurationCenterOutputSelectionPanel:
    View {

    let model: ConfigurationCenterOutputSelectionPanelModel

    @Binding
    var storageOption: ConfigurationStorageOption

    let onOpenMemoryModule: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("输出区现在只保留最终结果、保存去向、元数据保留和相册说明写入这 4 件事。中间格式细项先不展开，默认沿用当前本地安全链路。")
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            outputInfoCard(
                title: "输出结果",
                value: model.presentation.outputTitle,
                note: model.presentation.outputNote,
                systemImage: "photo"
            )

            outputInfoCard(
                title: "元数据保留",
                value: model.presentation.metadataTitle,
                note: model.presentation.metadataNote,
                systemImage: "info.circle"
            )

            VStack(alignment: .leading, spacing: 10) {
                outputInfoHeader(
                    title: "图片存放地点",
                    value:
                        storageOption.title,
                    systemImage: "folder"
                )

                Picker(
                    "存放地点",
                    selection: $storageOption
                ) {
                    ForEach(ConfigurationStorageOption.allCases) { option in
                        Text(option.title)
                            .tag(option)
                    }
                }
                .pickerStyle(.menu)

                Text(storageOption.note)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(12)
            .configurationPanelChrome()

            VStack(alignment: .leading, spacing: 10) {
                outputInfoHeader(
                    title: "相册说明写入",
                    value:
                        model.presentation.memoryWriteTitle,
                    systemImage: "text.badge.checkmark"
                )

                Text(model.presentation.memoryWriteDescription)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Color.primary.opacity(0.86))
                    .fixedSize(horizontal: false, vertical: true)

                Text(model.presentation.memoryWriteNote)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                Button(
                    model.presentation.memoryWriteActionTitle
                ) {
                    onOpenMemoryModule()
                }
                .buttonStyle(.borderless)
                .font(.caption.weight(.semibold))
            }
            .padding(12)
            .configurationPanelChrome()
        }
        .padding(12)
        .configurationPanelChrome()
    }

    private func outputInfoCard(
        title: String,
        value: String,
        note: String,
        systemImage: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            outputInfoHeader(
                title: title,
                value: value,
                systemImage: systemImage
            )

            Text(note)
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(12)
        .configurationPanelChrome()
    }

    private func outputInfoHeader(
        title: String,
        value: String,
        systemImage: String
    ) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: systemImage)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .frame(width: 16)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)

                Text(value)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Color.primary.opacity(0.86))
            }
        }
    }
}

struct ConfigurationCenterGuidePanel: View {

    let items: [ConfigurationCenterGuideCardModel]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach(items) { item in
                ConfigurationCenterGuideCard(item: item)
            }
        }
    }
}

private struct ConfigurationCenterGuideCard: View {

    let item: ConfigurationCenterGuideCardModel

    var body: some View {
        HStack(alignment: .top, spacing: 9) {
            Image(systemName: item.systemImage)
                .font(.body.weight(.medium))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(Color.accentColor)
                .frame(width: 22)

            VStack(alignment: .leading, spacing: 4) {
                Text(item.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.primary)

                Text(item.note)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(11)
        .configurationPanelChrome()
    }
}
#endif

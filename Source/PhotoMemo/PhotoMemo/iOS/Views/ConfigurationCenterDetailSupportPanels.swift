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

    let outputTitle: String
    let storageTitle: String
    let storageNote: String
}

struct ConfigurationCenterGuideCardModel:
    Identifiable,
    Equatable {

    var id: String { title }

    let title: String
    let note: String
    let systemImage: String
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

    var body: some View {
        VStack(alignment: .leading, spacing: 11) {
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "photo")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .frame(width: 16)

                VStack(alignment: .leading, spacing: 3) {
                    Text("输出结果")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)

                    Text(model.outputTitle)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(Color.primary.opacity(0.86))
                }
            }

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

            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "folder")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .frame(width: 16)

                VStack(alignment: .leading, spacing: 3) {
                    Text("图片存放地点")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)

                    Text(model.storageTitle)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(Color.primary.opacity(0.86))
                }
            }

            Text(model.storageNote)
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(12)
        .configurationPanelChrome()
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

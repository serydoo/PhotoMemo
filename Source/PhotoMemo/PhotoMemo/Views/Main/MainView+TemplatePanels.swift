import SwiftUI

struct MainTemplateSectionView: View {

    let selectedPreset: Binding<TemplatePreset>

    let resolvedTemplateDisplayName: String

    let currentPresetDisplayName: String

    let currentPresetDefaultOutput: String

    let currentPresetSummary: String

    let onPresentTemplateRename: () -> Void

    let onResetTemplateDefaults: () -> Void

    var body: some View {

        VStack(
            alignment: .leading,
            spacing: 14
        ) {

            HStack(
                alignment: .center,
                spacing: 10
            ) {

                Picker(
                    "模板",
                    selection: selectedPreset
                ) {

                    ForEach(
                        TemplatePreset.allCases,
                        id: \.self
                    ) { preset in

                        Text(preset.displayName)
                            .tag(preset)
                    }
                }
                .pickerStyle(.menu)
                .controlSize(.small)
                .frame(
                    maxWidth: .infinity,
                    alignment: .leading
                )

                Button(action: onPresentTemplateRename) {
                    Label(
                        "自定义名称",
                        systemImage: "pencil"
                    )
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }

            MinimalInsetCard {
                LabeledContent("当前定位") {
                    Text(resolvedTemplateDisplayName)
                        .font(.subheadline.weight(.medium))
                }

                Divider()

                LabeledContent("预设骨架") {
                    Text(currentPresetDisplayName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Divider()

                LabeledContent("默认右下") {
                    Text(currentPresetDefaultOutput)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.trailing)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            HStack(spacing: 10) {
                Button("恢复模板默认字段") {
                    onResetTemplateDefaults()
                }
                .buttonStyle(.bordered)
                .controlSize(.small)

                Text(currentPresetSummary)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(
            maxWidth: .infinity,
            alignment: .leading
        )
    }
}

struct MainCustomContentSectionView: View {

    @Binding
    var titleText: String

    @Binding
    var storyText: String

    @Binding
    var shouldWritePhotoDescription: Bool

    @Binding
    var photoDescriptionOverride: String

    let defaultPhotoDescriptionHint: String

    var body: some View {

        MinimalInsetCard {
            Text("这里负责标题、记忆文案，以及是否使用单独批量说明内容。若不单独填写批量说明，系统会自动回退到右下区域最终生成的完整内容。")
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            Divider()

            Text("内容")
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)

            TextField(
                "标题",
                text: $titleText
            )
            .textFieldStyle(.roundedBorder)

            TextField(
                "记忆文案",
                text: $storyText,
                axis: .vertical
            )
            .lineLimit(3...5)
            .textFieldStyle(.roundedBorder)

            Divider()

            Toggle(
                "使用单独批量说明内容",
                isOn: $shouldWritePhotoDescription
            )

            if shouldWritePhotoDescription {

                Divider()

                Text("勾选后，图片说明会优先写入这里的自定义内容；如果这里留空，会回退到右下区域的完整结果。")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                TextField(
                    "例如：这是这次批量统一写入图片内的说明",
                    text: $photoDescriptionOverride,
                    axis: .vertical
                )
                .lineLimit(2...4)
                .textFieldStyle(.roundedBorder)
            }

            Divider()

            VStack(
                alignment: .leading,
                spacing: 4
            ) {

                Text("图片说明写入预览")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)

                Text(descriptionPreviewText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(
            maxWidth: .infinity,
            alignment: .leading
        )
    }

    private var descriptionPreviewText: String {

        let trimmedOverride =
            photoDescriptionOverride
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        if shouldWritePhotoDescription,
           !trimmedOverride.isEmpty {
            return "当前会批量写入：\(trimmedOverride)"
        }

        if shouldWritePhotoDescription {
            return "当前未填写单独批量说明，将回退到右下区域最终内容。\(defaultPhotoDescriptionHint)"
        }

        return "未勾选单独批量说明时，会直接写入右下区域最终内容。\(defaultPhotoDescriptionHint)"
    }
}

struct MainBadgeSectionView<Preview: View>: View {

    let badgeNames: [String]

    let selectedBadgeName: Binding<String>

    let selectedBadgeTitle: String

    let selectedBadgeSummary: String

    @ViewBuilder
    let preview: () -> Preview

    var body: some View {

        VStack(
            alignment: .leading,
            spacing: 14
        ) {

            Picker(
                "Logo 标识",
                selection: selectedBadgeName
            ) {

                ForEach(
                    badgeNames,
                    id: \.self
                ) { badgeName in

                    Text(badgeName)
                        .tag(badgeName)
                }
            }
            .pickerStyle(.menu)
            .controlSize(.small)

            MinimalInsetCard {
                HStack(spacing: 12) {

                    preview()

                    VStack(
                        alignment: .leading,
                        spacing: 4
                    ) {

                        Text(selectedBadgeTitle)
                            .font(.subheadline.weight(.medium))

                        Text(selectedBadgeSummary)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Spacer(minLength: 0)
                }
            }
        }
        .frame(
            maxWidth: .infinity,
            alignment: .leading
        )
    }
}

struct MainTemplateRenameSheetView: View {

    @Binding
    var templateNameDraft: String

    let currentPresetDisplayName: String

    let resolvedTemplateDisplayName: String

    let onCancel: () -> Void

    let onSave: () -> Void

    var body: some View {

        NavigationStack {

            VStack(
                alignment: .leading,
                spacing: 16
            ) {

                Text("为当前模板设置一个更贴近你使用场景的名字。")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                TextField(
                    "例如：途途成长版",
                    text: $templateNameDraft
                )
                .textFieldStyle(.roundedBorder)

                MinimalInsetCard {
                    LabeledContent("当前预设") {
                        Text(currentPresetDisplayName)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Divider()

                    LabeledContent("当前显示") {
                        Text(resolvedTemplateDisplayName)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer(minLength: 0)
            }
            .padding(20)
            .navigationTitle("模板名称")
            .toolbar {
                ToolbarItem(
                    placement: .cancellationAction
                ) {
                    Button("取消") {
                        onCancel()
                    }
                }

                ToolbarItem(
                    placement: .primaryAction
                ) {
                    Button("保存") {
                        onSave()
                    }
                }
            }
            .frame(
                minWidth: 360,
                minHeight: 220
            )
        }
    }
}

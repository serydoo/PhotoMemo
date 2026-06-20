import SwiftUI

struct MainTemplateSectionView: View {

    let resolvedTemplateDisplayName: String

    let currentPresetSummary: String

    let onPresentTemplateRename: () -> Void

    let onResetTemplateDefaults: () -> Void

    var body: some View {

        VStack(
            alignment: .leading,
            spacing: 14
        ) {

            MinimalInsetCard {
                LabeledContent("当前风格") {
                    Text(resolvedTemplateDisplayName)
                        .font(.subheadline.weight(.medium))
                }

                Divider()

                Text(currentPresetSummary)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
            }

            HStack(spacing: 10) {
                Button("修改风格名") {
                    onPresentTemplateRename()
                }
                .buttonStyle(.bordered)
                .controlSize(.small)

                Button("恢复默认内容") {
                    onResetTemplateDefaults()
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
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
    var shouldWritePhotoDescription: Bool

    @Binding
    var photoDescriptionOverride: String

    let defaultPhotoDescriptionHint: String

    let onBeginCustomDescriptionEditing: () -> Void

    @FocusState
    private var isCustomDescriptionFocused: Bool

    var body: some View {

        VStack(
            alignment: .leading,
            spacing: 12
        ) {

            MinimalInsetCard {
                Toggle(
                    "使用自定义补充信息",
                    isOn: $shouldWritePhotoDescription
                )
                .font(.subheadline.weight(.medium))
                .onChange(
                    of: shouldWritePhotoDescription
                ) { _, isEnabled in
                    if isEnabled {
                        onBeginCustomDescriptionEditing()
                        isCustomDescriptionFocused = true
                    } else {
                        isCustomDescriptionFocused = false
                    }
                }

                TextField(
                    "例如：这是这张图想额外补进去的说明",
                    text: $photoDescriptionOverride,
                    axis: .vertical
                )
                .lineLimit(2...4)
                .textFieldStyle(.roundedBorder)
                .disabled(!shouldWritePhotoDescription)
                .focused($isCustomDescriptionFocused)
                .opacity(
                    shouldWritePhotoDescription
                    ? 1
                    : 0.56
                )
                .onChange(
                    of: isCustomDescriptionFocused
                ) { _, isFocused in
                    if isFocused {
                        onBeginCustomDescriptionEditing()
                    }
                }

                VStack(
                    alignment: .leading,
                    spacing: 4
                ) {

                    Text("当前写入结果")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)

                    Text(descriptionPreviewText)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
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

        if !shouldWritePhotoDescription {
            return "当前会自动写入右下区域最终生成的完整内容。"
        }

        if !trimmedOverride.isEmpty {
            return "当前会写入这段说明：\(trimmedOverride)"
        }

        return "已开启自定义补充信息；如果暂时留空，会先回退到右下区域当前结果。\(defaultPhotoDescriptionHint)"
    }
}

struct MainBadgeSectionView<Preview: View>: View {

    let badgeNames: [String]

    @Binding
    var selectedBadgeName: String

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
                selection: $selectedBadgeName
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

                Text("为当前风格设置一个更贴近使用场景的名字。")
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
            .navigationTitle("风格名称")
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

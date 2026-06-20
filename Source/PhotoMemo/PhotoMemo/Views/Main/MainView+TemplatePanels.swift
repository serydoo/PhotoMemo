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
                LabeledContent("当前名称") {
                    Text(resolvedTemplateDisplayName)
                        .font(.subheadline.weight(.medium))
                }

                Divider()

                Text("当前固定使用模板 1 的结构骨架，你只需要继续编辑下方个性化区域，不需要再处理多套模板类型。")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                Divider()

                Text(currentPresetSummary)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
            }

            HStack(spacing: 10) {
                Button("修改名称") {
                    onPresentTemplateRename()
                }
                .buttonStyle(.bordered)
                .controlSize(.small)

                Button("恢复模板默认字段") {
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

    var body: some View {

        VStack(
            alignment: .leading,
            spacing: 12
        ) {

            MainDismissibleGuideCard(
                storageKey:
                    "photomemo.guide.supplementalContent.dismissed",
                title: "补充信息说明",
                message: "这里现在只保留一条补充说明输入框。填写后会优先写入这段内容；留空时会回退到右下区域最终结果。更完整的说明已经放进右侧操作指南里，熟悉后可以直接关闭这条提示。"
            )

            MinimalInsetCard {
                TextField(
                    "例如：这是这张图想额外补进去的说明",
                    text: $photoDescriptionOverride,
                    axis: .vertical
                )
                .lineLimit(3...5)
                .textFieldStyle(.roundedBorder)
                .onChange(
                    of: photoDescriptionOverride
                ) { _, newValue in
                    shouldWritePhotoDescription =
                        !newValue.trimmingCharacters(
                            in: .whitespacesAndNewlines
                        ).isEmpty
                }

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
            return "当前不会把补充说明写入导出图片的 metadata。"
        }

        if !trimmedOverride.isEmpty {
            return "当前会写入这段说明：\(trimmedOverride)"
        }

        return "当前留空时，会回退到右下区域最终内容。\(defaultPhotoDescriptionHint)"
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

#if !MEMOMARK_SHARE_EXTENSION
import SwiftUI
#if canImport(PhotosUI)
import PhotosUI
#endif

/// Presentation-only avatar controls used by the Memory Subject editor.
///
/// The parent editor keeps ownership of selection request identity, crop
/// presentation, asset optimization, and `ConfigurationSession` persistence.
/// These surfaces deliberately receive only the current draft, picker binding,
/// and explicit user actions so visual extraction cannot create a second
/// avatar lifecycle or durable write path.
struct SubjectAvatarDetailedEditorSurface: View {

    let draft: SubjectAvatarEditingDraft
    let isOptimizing: Bool

#if canImport(PhotosUI)
    @Binding
    var selectedAvatarItem: PhotosPickerItem?
#endif

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center, spacing: 14) {
                SubjectAvatarPreview(
                    path: draft.previewPath,
                    size: 64
                )

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text("对象头像")
                            .font(.subheadline.weight(.semibold))

                        if isOptimizing {
                            SubjectAvatarStatusCapsule(
                                title: "处理中",
                                tint: .orange
                            )
                        }
                    }

                    Text(draft.statusMessage)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(
                            horizontal: false,
                            vertical: true
                        )
                }

                Spacer(minLength: 0)
            }

            HStack(spacing: 8) {
                SubjectAvatarResourceChip(
                    title: "头像",
                    isReady: draft.displayImagePath?.isEmpty == false
                )

                SubjectAvatarResourceChip(
                    title: "标识",
                    isReady: draft.badgeImagePath?.isEmpty == false
                )

                SubjectAvatarResourceChip(
                    title: "预览",
                    isReady: draft.previewImagePath?.isEmpty == false
                )
            }

#if canImport(PhotosUI)
            PhotosPicker(
                selection: $selectedAvatarItem,
                matching: .images
            ) {
                HStack(spacing: 8) {
                    Image(
                        systemName:
                            isOptimizing
                            ? "hourglass"
                            : "person.crop.circle.badge.plus"
                    )
                    .font(.subheadline.weight(.semibold))

                    Text(
                        isOptimizing
                        ? "正在处理头像"
                        : "选择对象头像"
                    )
                    .font(.subheadline.weight(.semibold))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 4)
            }
            .buttonStyle(.bordered)
            .controlSize(.regular)
            .disabled(isOptimizing)

            Text("选择后可像联系人头像一样拖动、放大和调整位置，再生成对象头像资源。")
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
#endif
        }
        .padding(12)
        .configurationPanelChrome(isSelected: true)
    }
}

#if canImport(PhotosUI)
struct SubjectAvatarContactEditorSurface: View {

    let draft: SubjectAvatarEditingDraft
    let isOptimizing: Bool

    @Binding
    var selectedAvatarItem: PhotosPickerItem?

    let onRemove: () -> Void

    var body: some View {
        let avatarIsAvailable = draft.hasAvatar

        VStack(spacing: 8) {
            ZStack(alignment: .topTrailing) {
                PhotosPicker(
                    selection: $selectedAvatarItem,
                    matching: .images
                ) {
                    VStack(spacing: 8) {
                        SubjectAvatarPreview(
                            path: draft.previewPath,
                            size: 112
                        )

                        HStack(spacing: 5) {
                            if isOptimizing {
                                ProgressView()
                                    .controlSize(.small)
                            }

                            Text(
                                avatarIsAvailable
                                ? "编辑"
                                : "添加照片"
                            )
                            .font(.subheadline.weight(.medium))
                        }
                        .frame(
                            minHeight:
                                ConfigurationUI.minimumInteractiveHeight
                        )
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .foregroundStyle(Color.accentColor)
                .disabled(isOptimizing)
                .accessibilityIdentifier("subject-avatar-picker")
                .accessibilityLabel(
                    avatarIsAvailable
                    ? "编辑对象头像"
                    : "添加对象照片"
                )
                .accessibilityHint(Text(
                    MemoMarkLanguage.interfaceStored.localized(
                        key: "accessibility.choose_crop",
                        fallback: "Choose a photo, then zoom and move the crop area"
                    )
                ))

                if avatarIsAvailable {
                    Button(role: .destructive, action: onRemove) {
                        Image(systemName: "minus")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.white)
                            .frame(width: 24, height: 24)
                            .background(
                                Circle()
                                    .fill(Color.red)
                            )
                            .overlay(
                                Circle()
                                    .stroke(Color.white, lineWidth: 2)
                            )
                            .frame(
                                width: ConfigurationUI.minimumInteractiveHeight,
                                height: ConfigurationUI.minimumInteractiveHeight
                            )
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(Text(
                        MemoMarkLanguage.interfaceStored.localized(
                            key: "accessibility.delete_avatar",
                            fallback: "Delete object avatar"
                        )
                    ))
                    .offset(x: 14, y: -14)
                    .disabled(isOptimizing)
                }
            }
        }
    }
}
#endif

private struct SubjectAvatarResourceChip: View {

    let title: String
    let isReady: Bool

    var body: some View {
        Label(
            title,
            systemImage: isReady
            ? "checkmark.circle.fill"
            : "circle.dashed"
        )
        .font(.caption.weight(.semibold))
        .foregroundStyle(
            isReady
            ? Color.accentColor
            : Color.secondary
        )
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(
            Capsule(style: .continuous)
                .fill(
                    isReady
                    ? Color.accentColor.opacity(0.10)
                    : ConfigurationUI.controlBackground
                )
        )
        .overlay(
            Capsule(style: .continuous)
                .stroke(
                    isReady
                    ? Color.accentColor.opacity(0.18)
                    : ConfigurationUI.faintHairline
                )
        )
    }
}

private struct SubjectAvatarStatusCapsule: View {

    let title: String
    let tint: Color

    var body: some View {
        Text(title)
            .font(.caption2.weight(.semibold))
            .foregroundStyle(tint)
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(
                Capsule(style: .continuous)
                    .fill(tint.opacity(0.10))
            )
    }
}
#endif

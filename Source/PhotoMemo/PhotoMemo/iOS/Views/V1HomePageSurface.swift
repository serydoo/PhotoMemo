#if os(iOS) && !PHOTOMEMO_SHARE_EXTENSION
import SwiftUI

struct V1HomePageSurface<
    PresetPicker: View,
    PresetOperationsMenu: View,
    ProfileTrackingBackground: View
>: View {

    let subjectSummary: V1IOSHomeSubjectSummaryProjection
    let subject: MemorySubject?
    let borderStyleName: String
    let borderStyleDescription: String
    let presetSummary: V1IOSHomePresetSummaryProjection
    let presetStatusTone: V1IOSHomeStatusBadge.Tone
    let presetSavedStatusText: String
    let hasHomePresetSelection: Bool
    let isEditingMemoryPresetTitle: Bool
    let memoryPresetTitleDraft: Binding<String>
    let memoryPresetTitleFieldFocused: FocusState<Bool>.Binding
    let onOpenSubject: () -> Void
    let onCommitMemoryPresetTitle: () -> Void
    let onOpenPhotoPicker: () -> Void
    let onOpenEditor: () -> Void
    let onOpenTimeAnchor: () -> Void
    let onOpenUsageGuide: () -> Void
    let onOpenSettings: () -> Void
    let onDismissKeyboard: () -> Void
    let presetPicker: PresetPicker
    let presetOperationsMenu: PresetOperationsMenu
    let profileTrackingBackground: ProfileTrackingBackground

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                topHeaderSection

                topSummaryCluster
            }
            .padding(.horizontal, 18)
            .padding(.top, 16)
            .padding(.bottom, 34)
        }
        .scrollDismissesKeyboard(.interactively)
        .simultaneousGesture(
            TapGesture()
                .onEnded {
                    onDismissKeyboard()
                }
        )
        .background(
            ConfigurationUI.appBackground
                .ignoresSafeArea()
        )
        .navigationTitle("首页")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var topSummaryCluster: some View {
        VStack(spacing: 14) {
            profileSection
                .background(profileTrackingBackground)

            currentPresetSection
            quickActionsSection
        }
    }

    private var topHeaderSection: some View {
        HStack(alignment: .top, spacing: 14) {
            V1HomeAppMark()

            VStack(alignment: .leading, spacing: 8) {
                Text("PhotoMemo")
                    .font(.title2.weight(.semibold))

                Text("本地优先的记忆呈现引擎，让照片不止记录画面，也保留它在人生时间线里的位置。")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: 8) {
                    V1HomeHeaderPill(
                        systemImage: "lock.shield",
                        title: "本地优先"
                    )

                    V1HomeHeaderPill(
                        systemImage: "photo.on.rectangle",
                        title: "Apple Photos"
                    )
                }
            }

            Spacer(minLength: 0)

            Button(action: onOpenSettings) {
                Image(systemName: "gearshape")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(Color.blue)
                    .frame(width: 42, height: 42)
                    .background(
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color.white,
                                            Color.blue.opacity(0.10)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )

                            Circle()
                                .stroke(Color.blue.opacity(0.16), lineWidth: 1)
                        }
                    )
                    .shadow(
                        color: Color.blue.opacity(0.10),
                        radius: 10,
                        y: 4
                    )
            }
            .buttonStyle(.plain)
            .accessibilityLabel("打开设置")
        }
        .padding(.horizontal, 2)
        .padding(.vertical, 4)
    }

    private var profileSection: some View {
        V1CardSurface(title: "记忆对象") {
            V1IOSSubjectHomeEntryContent(
                subjectSummary: subjectSummary,
                subject: subject,
                onOpenSubject: onOpenSubject
            )
        }
    }

    private var currentPresetSection: some View {
        V1CardSurface(title: "当前配置") {
            VStack(alignment: .leading, spacing: 10) {
                V1HomeCurrentPresetRow(
                    title: presetSummary.title,
                    subtitle: borderStyleName,
                    detail: "上次修改：\(presetSavedStatusText)",
                    statusLabel: presetSummary.statusLabel,
                    statusTone: presetStatusTone,
                    hasSelection: hasHomePresetSelection,
                    presetPicker: presetPicker,
                    presetOperationsMenu: presetOperationsMenu
                )

                if isEditingMemoryPresetTitle {
                    HStack(spacing: 8) {
                        TextField(
                            "配置名称",
                            text: memoryPresetTitleDraft
                        )
                        .textFieldStyle(.roundedBorder)
                        .font(.subheadline)
                        .submitLabel(.done)
                        .focused(memoryPresetTitleFieldFocused)
                        .onSubmit {
                            onCommitMemoryPresetTitle()
                        }

                        Button("完成") {
                            onCommitMemoryPresetTitle()
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                        .accessibilityLabel("完成名称编辑")
                    }
                    .padding(.horizontal, 4)
                    .padding(.top, 2)
                }
            }
        }
    }

    private var quickActionsSection: some View {
        V1CardSurface(title: "快捷操作") {
            V1IOSHomeQuickActionsContent(
                openPhotoPicker: onOpenPhotoPicker,
                openEditor: onOpenEditor,
                openTimeAnchor: onOpenTimeAnchor,
                openUsageGuide: onOpenUsageGuide
            )
        }
    }
}

private struct V1HomeCurrentPresetRow<
    PresetPicker: View,
    PresetOperationsMenu: View
>: View {

    let title: String
    let subtitle: String
    let detail: String
    let statusLabel: String
    let statusTone: V1IOSHomeStatusBadge.Tone
    let hasSelection: Bool
    let presetPicker: PresetPicker
    let presetOperationsMenu: PresetOperationsMenu

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            presetThumbnail

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(1)

                    V1IOSHomeStatusBadge(
                        text: statusLabel,
                        tone: statusTone
                    )
                }

                Text(subtitle)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                Text(detail)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 8)

            VStack(alignment: .trailing, spacing: 6) {
                if hasSelection {
                    presetPicker
                    presetOperationsMenu
                } else {
                    Text("等待配置")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(
                cornerRadius: 20,
                style: .continuous
            )
            .fill(Color.white.opacity(0.94))
        )
        .overlay(
            RoundedRectangle(
                cornerRadius: 20,
                style: .continuous
            )
            .stroke(ConfigurationUI.faintHairline)
        )
        .shadow(
            color: Color.black.opacity(0.045),
            radius: 12,
            y: 5
        )
    }

    private var presetThumbnail: some View {
        ZStack {
            RoundedRectangle(
                cornerRadius: 12,
                style: .continuous
            )
            .fill(
                LinearGradient(
                    colors: [
                        Color.white,
                        Color.blue.opacity(0.08)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )

            VStack(spacing: 3) {
                RoundedRectangle(
                    cornerRadius: 3,
                    style: .continuous
                )
                .fill(Color.black.opacity(0.16))
                .frame(width: 24, height: 5)

                RoundedRectangle(
                    cornerRadius: 4,
                    style: .continuous
                )
                .stroke(Color.black.opacity(0.22), lineWidth: 1.2)
                .frame(width: 34, height: 20)
            }
        }
        .frame(width: 52, height: 52)
    }
}

private struct V1HomeAppMark: View {

    var body: some View {
        ZStack {
            RoundedRectangle(
                cornerRadius: 22,
                style: .continuous
            )
            .fill(Color.white)
            .shadow(
                color: Color.black.opacity(0.05),
                radius: 12,
                y: 6
            )

            RoundedRectangle(
                cornerRadius: 12,
                style: .continuous
            )
            .stroke(Color.black, lineWidth: 4)
            .frame(width: 40, height: 46)
            .offset(x: -5, y: -1)

            RoundedRectangle(
                cornerRadius: 11,
                style: .continuous
            )
            .stroke(Color.black.opacity(0.92), lineWidth: 3)
            .frame(width: 34, height: 38)
            .offset(x: 9, y: 6)

            Circle()
                .fill(Color.blue)
                .frame(width: 8, height: 8)
                .offset(x: 15, y: -13)
        }
        .frame(width: 68, height: 68)
    }
}

private struct V1HomeHeaderPill: View {

    let systemImage: String
    let title: String

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: systemImage)
                .font(.caption.weight(.semibold))

            Text(title)
                .font(.caption.weight(.semibold))
                .lineLimit(1)
        }
        .foregroundStyle(Color.blue)
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(
            Capsule(style: .continuous)
                .fill(Color.blue.opacity(0.08))
        )
    }
}
#endif

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
    let isEditingMemoryPresetTitle: Bool
    let memoryPresetTitleDraft: Binding<String>
    let memoryPresetTitleFieldFocused: FocusState<Bool>.Binding
    let isSavingConfiguration: Bool
    let recentProcessingPresentation: V1IOSHomeRecentProcessingPresentation
    let onOpenSubject: () -> Void
    let onCommitMemoryPresetTitle: () -> Void
    let onApplyCurrentConfiguration: () -> Void
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
            VStack(spacing: 18) {
                topHeaderSection

                profileSection
                    .background(profileTrackingBackground)

                currentPresetSection
                quickActionsSection
                recentProcessingSection
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

    private var topHeaderSection: some View {
        HStack(alignment: .top, spacing: 14) {
            V1HomeAppMark()

            VStack(alignment: .leading, spacing: 8) {
                Text("PhotoMemo")
                    .font(.title2.weight(.semibold))

                Text("记录人生，珍藏记忆")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                HStack(spacing: 8) {
                    V1HomeHeaderPill(
                        systemImage: "person.crop.circle",
                        title: subjectSummary.title
                    )

                    V1HomeHeaderPill(
                        systemImage: "sparkles",
                        title: "V1.0"
                    )
                }
            }

            Spacer(minLength: 0)

            Button(action: onOpenSettings) {
                Image(systemName: "gearshape")
                    .font(.subheadline.weight(.semibold))
                    .frame(width: 38, height: 38)
                    .background(
                        Circle()
                            .fill(Color.white.opacity(0.94))
                    )
                    .overlay(
                        Circle()
                            .stroke(ConfigurationUI.faintHairline)
                    )
            }
            .buttonStyle(.plain)
            .accessibilityLabel("打开设置")
        }
        .padding(18)
        .background(
            RoundedRectangle(
                cornerRadius: 26,
                style: .continuous
            )
            .fill(
                LinearGradient(
                    colors: [
                        Color.white,
                        Color.white.opacity(0.92)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
        )
        .overlay(
            RoundedRectangle(
                cornerRadius: 26,
                style: .continuous
            )
            .stroke(ConfigurationUI.faintHairline)
        )
        .shadow(
            color: Color.black.opacity(0.04),
            radius: 14,
            y: 6
        )
    }

    private var profileSection: some View {
        V1CardSurface(title: "当前记忆对象") {
            V1IOSSubjectHomeEntryContent(
                subjectSummary: subjectSummary,
                subject: subject,
                onOpenSubject: onOpenSubject
            )
        }
    }

    private var currentPresetSection: some View {
        V1CardSurface(title: "当前配置") {
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(borderStyleName)
                            .font(.headline.weight(.semibold))

                        Text("边框样式")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer(minLength: 0)

                    V1IOSHomeStatusBadge(
                        text: presetSummary.statusLabel,
                        tone: presetStatusTone
                    )
                }

                Text(borderStyleDescription)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                Text("这一组决定下一次默认使用的边框样式、配置组合、时间锚点与输出组合。")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                V1IOSHomeInsetGroup {
                    HStack(alignment: .center, spacing: 12) {
                        Image(systemName: "slider.horizontal.below.rectangle")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .frame(width: 18)

                        VStack(alignment: .leading, spacing: 4) {
                            Text("配置组合")
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(.secondary)
                                .textCase(.uppercase)

                            presetPicker
                        }

                        Spacer(minLength: 0)

                        presetOperationsMenu
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 13)

                    if !presetSummary.detail.isEmpty {
                        Rectangle()
                            .fill(ConfigurationUI.faintHairline)
                            .frame(height: 0.5)
                            .padding(.leading, 14)

                        Text(presetSummary.detail)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 14)
                    }

                    if isEditingMemoryPresetTitle {
                        Rectangle()
                            .fill(ConfigurationUI.faintHairline)
                            .frame(height: 0.5)
                            .padding(.leading, 14)

                        HStack(spacing: 8) {
                            TextField(
                                "配置组合名称",
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
                        .padding(.horizontal, 14)
                        .padding(.vertical, 14)
                    }
                }

                Button(action: onApplyCurrentConfiguration) {
                    HStack(spacing: 8) {
                        if isSavingConfiguration {
                            ProgressView()
                                .controlSize(.small)
                        }

                        Text(
                            presetSummary.emphasizesAppliedState
                            ? "重新保存默认配置"
                            : "保存为默认配置"
                        )
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .disabled(isSavingConfiguration)
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

    private var recentProcessingSection: some View {
        V1CardSurface(title: "最近处理") {
            V1IOSHomeRecentProcessingContent(
                presentation: recentProcessingPresentation,
                openStatus: onOpenSettings
            )
        }
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

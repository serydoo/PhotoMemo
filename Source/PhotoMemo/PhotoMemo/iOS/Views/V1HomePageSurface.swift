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
    let outputSummary: V1IOSHomeOutputSummaryProjection
    let recentProcessingPresentation: V1IOSHomeRecentProcessingPresentation
    let onOpenSubject: () -> Void
    let onCommitMemoryPresetTitle: () -> Void
    let onApplyCurrentConfiguration: () -> Void
    let onOpenOutput: () -> Void
    let onOpenEditor: () -> Void
    let onOpenSettings: () -> Void
    let onDismissKeyboard: () -> Void
    let presetPicker: PresetPicker
    let presetOperationsMenu: PresetOperationsMenu
    let profileTrackingBackground: ProfileTrackingBackground

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                profileSection
                    .background(profileTrackingBackground)

                currentPresetSection
                quickActionsSection
                recentProcessingSection
                defaultOutputSummarySection
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
        .navigationTitle("PhotoMemo")
        .navigationBarTitleDisplayMode(.inline)
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
                    V1IOSHomeSemanticRow(
                        title: "配置组合",
                        value: presetSummary.title,
                        detail: presetSummary.subtitle,
                        systemImage: "slider.horizontal.below.rectangle"
                    )

                    HStack(alignment: .center, spacing: 12) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("切换配置组合")
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
                openOutput: onOpenOutput,
                openEditor: onOpenEditor,
                openSettings: onOpenSettings
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

    private var defaultOutputSummarySection: some View {
        V1CardSurface(title: "默认输出") {
            V1IOSHomeDefaultOutputSummaryContent(
                summary: outputSummary
            )
        }
    }
}
#endif

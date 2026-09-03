#if os(iOS) && !MEMOMARK_SHARE_EXTENSION
import SwiftUI

struct SubjectOverviewSheet: View {

    @Environment(\.dismiss)
    private var dismiss

    let availableConfigurationCount: Int
    let completedPhotoCount: Int

    @ObservedObject
    var session: ConfigurationSession

    let onSelectSubject: (MemorySubject.ID) -> Void
    let onAddSubject: () -> Void
    let onEditSubject: () -> SubjectConfigurationFlowState?
    let onDeleteCurrentSubject: () -> Void
    let onPersistSubjectChanges: () -> Void

    @State
    private var isSwitchingSubject = false

    @State
    private var switchCandidateSubjectID: MemorySubject.ID?

    @State
    private var configurationFlowState:
        SubjectConfigurationFlowState?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 14) {
                    if isSwitchingSubject {
                        subjectSwitcher
                    }

                    ConfigurationTitledSectionSurface(
                        title: "基础资料",
                        subtitle: "名字、关系和你熟悉的称呼。",
                        trailingAccessory: {
                            editSubjectButton
                        }
                    ) {
                        subjectBasicInformation
                    }

                    ConfigurationTitledSectionSurface(
                        title: "时间锚点",
                        subtitle: "选择重要日子，让照片拥有时间答案。"
                    ) {
                        SubjectAnchorDetailSection(
                            session: session,
                            onPersistSubjectChanges:
                                onPersistSubjectChanges
                        )
                    }

                }
                .padding(.top, 12)
                .padding(.bottom, 34)
                .adaptiveScrollContent(
                    horizontalPadding:
                        ConfigurationUI.contentColumnPadding
                )
            }
            .background(
                ConfigurationUI.appBackground
                    .ignoresSafeArea()
            )
            .navigationTitle("记忆对象")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        beginSwitchingSubject()
                    } label: {
                        Label("切换", systemImage: "person.2")
                    }
                    .accessibilityLabel("切换记忆对象")
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .accessibilityIdentifier("subject-overview")
        .onChange(of: session.state.selectedSubjectID) { _, newValue in
            guard !isSwitchingSubject else {
                return
            }

            switchCandidateSubjectID = newValue
        }
        .sheet(item: $configurationFlowState) { flowState in
            SubjectConfigurationFlow(
                flowState: flowState,
                onDeleteSubject: {
                    onDeleteCurrentSubject()
                    configurationFlowState = nil
                },
                onCancel: {
                    configurationFlowState = nil
                },
                onSave: {
                    configurationFlowState = nil
                }
            )
        }
    }

    private var subjectSwitcher: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("切换记忆对象")
                    .font(.subheadline.weight(.semibold))

                Spacer(minLength: 12)

                Button("取消") {
                    isSwitchingSubject = false
                    switchCandidateSubjectID = nil
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }

            SubjectOverviewSubjectRail(
                subjects: session.state.subjects,
                selectedSubjectID: session.state.selectedSubjectID,
                switchCandidateSubjectID:
                    switchCandidateSubjectID,
                onSelectSubject: { subjectID in
                    switchCandidateSubjectID = subjectID
                    onSelectSubject(subjectID)
                    isSwitchingSubject = false
                },
                onAddSubject: onAddSubject
            )
        }
    }

    private var editSubjectButton: some View {
        ConfigurationCardHeaderIconButton(
            systemImage: "pencil",
            accessibilityLabel: "编辑记忆对象"
        ) {
            configurationFlowState = onEditSubject()
        }
        .accessibilityIdentifier("subject-edit")
        .accessibilityHint("编辑对象身份、关系与时间锚点")
    }

    @ViewBuilder
    private var subjectBasicInformation: some View {
        if let subject = session.state.selectedSubject {
            VStack(spacing: 0) {
                subjectIdentitySummary

                if let shortName = normalized(
                    subject.identity.shortName
                ) {
                    HorizontalDivider(horizontalInset: 14)
                    SubjectOverviewFactRow(
                        title: "昵称",
                        value: shortName
                    )
                }

                if let relationship = normalized(
                    subject.relationship.role
                ) {
                    HorizontalDivider(horizontalInset: 14)
                    SubjectOverviewFactRow(
                        title: "与我的关系",
                        value: relationship
                    )
                }

                if let relationshipLabel = normalized(
                    subject.relationship.label
                ) {
                    HorizontalDivider(horizontalInset: 14)
                    SubjectOverviewFactRow(
                        title: "专属称呼",
                        value: relationshipLabel
                    )
                }
            }
            .v1CardChrome()
        }
    }

    private var subjectIdentitySummary: some View {
        let subject = session.state.selectedSubject

        return HStack(spacing: 14) {
            SubjectAvatarView(
                imagePath:
                    subject?.identity.avatarPreviewImagePath
                    ?? subject?.identity.avatarImagePath,
                size: 84
            )

            VStack(alignment: .center, spacing: 4) {
                Text(subjectDisplayName)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)

                Text("照片中的回忆正围绕 TA 展开。")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity, alignment: .center)
        }
        .padding(12)
        .accessibilityElement(children: .combine)
    }

    private var subjectDisplayName: String {
        normalized(session.state.selectedSubject?.identity.displayName)
        ?? "记忆对象"
    }

    private func normalized(_ value: String?) -> String? {
        guard let value else {
            return nil
        }

        let trimmed = value.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
        return trimmed.isEmpty ? nil : trimmed
    }

    private func beginSwitchingSubject() {
        switchCandidateSubjectID =
            session.state.selectedSubjectID
            ?? session.state.subjects.first?.id
        isSwitchingSubject = true
    }
}

private struct SubjectOverviewFactRow: View {

    let title: String
    let value: String

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Text(title)
                .font(.body)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: true, vertical: false)

            Spacer(minLength: 0)

            Text(value)
                .font(.body)
                .foregroundStyle(.primary)
                .multilineTextAlignment(.trailing)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .fixedSize(horizontal: false, vertical: true)
                .layoutPriority(1)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 7)
        .accessibilityElement(children: .combine)
    }
}
#endif

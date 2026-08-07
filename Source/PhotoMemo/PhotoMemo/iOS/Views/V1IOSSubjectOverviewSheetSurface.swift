#if os(iOS) && !PHOTOMEMO_SHARE_EXTENSION
import SwiftUI

struct V1IOSSubjectOverviewSheet: View {

    let subjects: [MemorySubject]
    let subject: MemorySubject?
    let availableConfigurationCount: Int
    let completedPhotoCount: Int

    @ObservedObject
    var session: ConfigurationSession

    let selectedSubjectID: MemorySubject.ID?
    let onSelectSubject: (MemorySubject.ID) -> Void
    let onAddSubject: () -> Void
    let onEditSubject: () -> V1IOSSubjectConfigurationFlowState?
    let onDeleteCurrentSubject: () -> Void
    let onPersistSubjectChanges: () -> Void

    @State
    private var isSwitchingSubject = false

    @State
    private var switchCandidateSubjectID: MemorySubject.ID?

    @State
    private var configurationFlowState:
        V1IOSSubjectConfigurationFlowState?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 14) {
                    if isSwitchingSubject {
                        subjectSwitcher
                    }

                    V1TitledSectionCard(
                        title: "基础资料",
                        subtitle: "对象身份与关系信息",
                        trailingAccessory: {
                            editSubjectButton
                        }
                    ) {
                        subjectBasicInformation
                    }

                    V1TitledSectionCard(
                        title: "时间锚点",
                        subtitle: "这些重要时刻会影响照片中的时间表达。"
                    ) {
                        V1IOSSubjectAnchorDetailSection(
                            session: session,
                            subject: subject,
                            onPersistSubjectChanges:
                                onPersistSubjectChanges
                        )
                    }

                    V1IOSSubjectStatisticsStrip(
                        availableConfigurationCount:
                            availableConfigurationCount,
                        completedPhotoCount:
                            completedPhotoCount
                    )
                }
                .padding(.top, 12)
                .padding(.bottom, 34)
                .v1AdaptiveScrollContent(
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
                        Image(systemName: "arrow.left.arrow.right")
                    }
                    .accessibilityLabel("切换记忆对象")
                }
            }
        }
        .onChange(of: selectedSubjectID) { _, newValue in
            guard !isSwitchingSubject else {
                return
            }

            switchCandidateSubjectID = newValue
        }
        .sheet(item: $configurationFlowState) { flowState in
            V1IOSSubjectConfigurationFlow(
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

            V1IOSSubjectOverviewSubjectRail(
                subjects: subjects,
                selectedSubjectID: selectedSubjectID,
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
        V1CardHeaderIconButton(
            systemImage: "pencil",
            accessibilityLabel: "编辑记忆对象"
        ) {
            configurationFlowState = onEditSubject()
        }
        .accessibilityHint("编辑对象身份、关系与时间锚点")
    }

    @ViewBuilder
    private var subjectBasicInformation: some View {
        if let subject {
            VStack(spacing: 0) {
                subjectIdentitySummary

                if let shortName = normalized(
                    subject.identity.shortName
                ) {
                    V1HorizontalDivider(horizontalInset: 14)
                    V1IOSSubjectFactRow(
                        title: "昵称",
                        value: shortName
                    )
                }

                if let relationship = normalized(
                    subject.relationship.role
                ) {
                    V1HorizontalDivider(horizontalInset: 14)
                    V1IOSSubjectFactRow(
                        title: "与我的关系",
                        value: relationship
                    )
                }

                if let relationshipLabel = normalized(
                    subject.relationship.label
                ) {
                    V1HorizontalDivider(horizontalInset: 14)
                    V1IOSSubjectFactRow(
                        title: "专属称呼",
                        value: relationshipLabel
                    )
                }
            }
            .v1CardChrome()
        }
    }

    private var subjectIdentitySummary: some View {
        HStack(spacing: 14) {
            V1SubjectAvatarView(
                imagePath:
                    subject?.identity.avatarPreviewImagePath
                    ?? subject?.identity.avatarImagePath,
                size: 68
            )

            VStack(alignment: .center, spacing: 4) {
                Text(subjectDisplayName)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)

                Text("当前生效的记忆主体")
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
        normalized(subject?.identity.displayName)
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
            selectedSubjectID
            ?? subject?.id
            ?? subjects.first?.id
        isSwitchingSubject = true
    }
}

private struct V1IOSSubjectFactRow: View {

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

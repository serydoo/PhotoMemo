#if os(iOS) && !PHOTOMEMO_SHARE_EXTENSION
import SwiftUI

struct V1IOSSubjectOverviewSheet: View {

    let subjects: [MemorySubject]
    let subject: MemorySubject?

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

                    subjectIdentityHeader

                    V1CardSurface(
                        title: "",
                        tint: .blue
                    ) {
                        subjectModuleHeader(
                            title: "基础资料",
                            explanation: "对象身份与关系信息"
                        )

                        subjectBasicInformation
                    }

                    V1CardSurface(
                        title: "",
                        tint: .blue
                    ) {
                        subjectModuleHeader(
                            title: "时间锚点",
                            explanation: "用于计算记忆对象的时间参考"
                        )

                        V1IOSSubjectAnchorDetailSection(
                            session: session,
                            subject: subject,
                            onPersistSubjectChanges:
                                onPersistSubjectChanges
                        )
                    }
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

                ToolbarItem(placement: .topBarTrailing) {
                    Button("编辑") {
                        configurationFlowState = onEditSubject()
                    }
                    .fontWeight(.semibold)
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

    private var subjectIdentityHeader: some View {
        VStack(spacing: 10) {
            V1SubjectAvatarView(
                imagePath:
                    subject?.identity.avatarPreviewImagePath
                    ?? subject?.identity.avatarImagePath,
                size: 112
            )

            Text(subjectDisplayName)
                .font(.title2.weight(.semibold))
                .foregroundStyle(.primary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private var subjectBasicInformation: some View {
        if let subject {
            VStack(spacing: 0) {
                    V1IOSSubjectFactRow(
                        title: "对象名称",
                        value: subjectDisplayName
                    )

                    if let shortName = normalized(
                        subject.identity.shortName
                    ) {
                        V1HorizontalDivider()
                        V1IOSSubjectFactRow(
                            title: "昵称",
                            value: shortName
                        )
                    }

                    if let relationshipLabel = normalized(
                        subject.relationship.label
                    ) {
                        V1HorizontalDivider()
                        V1IOSSubjectFactRow(
                            title: "专属称呼",
                            value: relationshipLabel
                        )
                    }

                    if let relationship = normalized(
                        subject.relationship.role
                    ) {
                        V1HorizontalDivider()
                        V1IOSSubjectFactRow(
                            title: "与我关系",
                            value: relationship
                        )
                    }
                }
                .padding(.horizontal, 16)
            }
        }

    private var subjectDisplayName: String {
        normalized(subject?.identity.displayName)
        ?? "记忆对象"
    }

    private func subjectModuleHeader(
        title: String,
        explanation: String
    ) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            Text(title)
                .font(.subheadline.weight(.semibold))
            Text(explanation)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .truncationMode(.tail)
            Spacer(minLength: 0)
        }
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
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(value)
                .font(.body)
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 10)
        .accessibilityElement(children: .combine)
    }
}
#endif

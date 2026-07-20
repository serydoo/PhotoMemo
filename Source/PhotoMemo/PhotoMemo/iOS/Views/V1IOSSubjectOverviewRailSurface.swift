#if os(iOS) && !PHOTOMEMO_SHARE_EXTENSION
import SwiftUI

struct V1IOSSubjectOverviewSubjectRail: View {

    let subjects: [MemorySubject]
    let selectedSubjectID: MemorySubject.ID?
    let switchCandidateSubjectID: MemorySubject.ID?
    let isSwitchingSubject: Bool
    let onSelectSubject: (MemorySubject.ID) -> Void
    let onAddSubject: () -> Void
    let onSaveSubject: () -> Void
    let onBeginSwitch: () -> Void
    let onCancelSwitch: () -> Void
    let onCommitSwitch: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if isSwitchingSubject {
                switchingHeaderLayout
            } else {
                ViewThatFits(in: .horizontal) {
                    HStack(alignment: .center, spacing: 10) {
                        currentSubjectSummary

                        Spacer(minLength: 0)

                        headerActions
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        currentSubjectSummary

                        HStack(spacing: 0) {
                            Spacer(minLength: 0)
                            headerActions
                        }
                    }
                }
            }

            if isSwitchingSubject {
                switchingLayout
            }
        }
    }

    private var switchingHeaderLayout: some View {
        VStack(alignment: .leading, spacing: 8) {
            currentSubjectSummary

            HStack(spacing: 0) {
                Spacer(minLength: 0)
                headerActions
            }
        }
    }

    @ViewBuilder
    private var headerActions: some View {
        if isSwitchingSubject {
            HStack(spacing: 8) {
                Button("取消") {
                    onCancelSwitch()
                }
                .buttonStyle(.bordered)
                .controlSize(.small)

                if subjects.count > 1 {
                    Button {
                        onCommitSwitch()
                    } label: {
                        Label("保存切换", systemImage: "checkmark")
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                    .disabled(
                        switchCandidateSubjectID == nil
                        || switchCandidateSubjectID
                        == resolvedSelectedSubjectID
                    )
                }
            }
        } else {
            HStack(spacing: 8) {
                Button {
                    onSaveSubject()
                } label: {
                    Label("保存", systemImage: "checkmark")
                        .font(.subheadline.weight(.semibold))
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .frame(minHeight: 44)
                .accessibilityLabel("保存当前记忆对象信息")

                Button {
                    onBeginSwitch()
                } label: {
                    Label(
                        "切换对象",
                        systemImage:
                            "arrow.left.arrow.right"
                    )
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .frame(minHeight: 44)
                .accessibilityLabel("切换当前对象")
            }
        }
    }

    private var currentSubjectSummary: some View {
        HStack(spacing: 8) {
            if let subject = currentSubject {
                V1IOSHomeStatusBadge(
                    text:
                        isSwitchingSubject
                        ? "选择对象"
                        : "当前使用",
                    tone:
                        isSwitchingSubject
                        ? .neutral
                        : .accent
                )

                Text(stableSubjectDisplayName(subject))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .truncationMode(.tail)
            } else {
                VStack(alignment: .leading, spacing: 3) {
                    Text("记忆对象")
                        .font(.subheadline.weight(.semibold))

                    Text("先新增一个记忆对象")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private var switchingLayout: some View {
        if subjects.count <= 1 {
            singleSubjectSwitchLayout
        } else {
            multiCardLayout
        }
    }

    private var singleSubjectSwitchLayout: some View {
        HStack(spacing: 12) {
            if let subject = currentSubject {
                V1IOSSubjectSwitchChip(
                    subject: subject,
                    isCurrent: true,
                    isCandidate: true,
                    action: {
                        onSelectSubject(subject.id)
                    }
                )
                .frame(maxWidth: .infinity)
            }

            Button(action: onAddSubject) {
                Image(systemName: "plus")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(Color.accentColor)
                    .frame(width: 58, height: 58)
                    .background(
                        Circle()
                            .fill(Color.white.opacity(0.96))
                    )
                    .overlay(
                        Circle()
                            .stroke(ConfigurationUI.faintHairline)
                    )
            }
            .buttonStyle(.plain)
            .accessibilityLabel("新增记忆对象")
        }
        .padding(.top, 2)
    }

    private var multiCardLayout: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 14) {
                ForEach(subjects) { subject in
                    V1IOSSubjectSwitchChip(
                        subject: subject,
                        isCurrent:
                            subject.id
                            == resolvedSelectedSubjectID,
                        isCandidate:
                            subject.id
                            == resolvedSwitchCandidateSubjectID,
                        action: {
                            onSelectSubject(subject.id)
                        }
                    )
                    .frame(width: 222)
                }
            }
            .padding(.horizontal, 2)
        }
        .contentMargins(.horizontal, 1, for: .scrollContent)
    }

    private var resolvedSelectedSubjectID: MemorySubject.ID? {
        selectedSubjectID
        ?? subjects.first?.id
    }

    private var resolvedSwitchCandidateSubjectID:
        MemorySubject.ID? {
        guard isSwitchingSubject else {
            return nil
        }

        return switchCandidateSubjectID
        ?? resolvedSelectedSubjectID
    }

    private var currentSubject: MemorySubject? {
        subjects.first {
            $0.id == resolvedSelectedSubjectID
        } ?? subjects.first
    }

    private func stableSubjectDisplayName(
        _ subject: MemorySubject
    ) -> String {
        let displayName =
            subject.identity.displayName
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        return displayName.isEmpty
        ? "记忆对象"
        : displayName
    }

}

private struct V1IOSSubjectSwitchChip: View {

    let subject: MemorySubject
    let isCurrent: Bool
    let isCandidate: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                V1SubjectAvatarView(
                    imagePath:
                        subject.identity.avatarImagePath
                        ?? subject.identity.avatarPreviewImagePath,
                    size: 44
                )

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(subjectDisplayName)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.primary)
                            .lineLimit(1)

                        if isCurrent {
                            V1IOSHomeStatusBadge(
                                text: "当前",
                                tone: .accent
                            )
                        }
                    }

                    Text(subjectRelationship)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Spacer(minLength: 0)

                Image(
                    systemName:
                        isCandidate
                        ? "checkmark.circle.fill"
                        : "circle"
                )
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(
                    isCandidate
                    ? Color.accentColor
                    : Color.secondary.opacity(0.55)
                )
            }
            .padding(12)
            .frame(maxWidth: .infinity, minHeight: 72)
            .background(
                RoundedRectangle(
                    cornerRadius: 18,
                    style: .continuous
                )
                .fill(Color.white.opacity(0.95))
            )
            .overlay(
                RoundedRectangle(
                    cornerRadius: 18,
                    style: .continuous
                )
                .stroke(
                    isCandidate
                    ? Color.accentColor.opacity(0.26)
                    : ConfigurationUI.faintHairline,
                    lineWidth: isCandidate ? 1 : 0.75
                )
            )
        }
        .buttonStyle(.plain)
    }

    private var subjectDisplayName: String {
        let displayName =
            subject.identity.displayName
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        return displayName.isEmpty
        ? "记忆对象"
        : displayName
    }

    private var subjectRelationship: String {
        let trimmed =
            subject.relationship.label
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        return trimmed.isEmpty
            ? "补充关系信息"
            : trimmed
    }
}
#endif

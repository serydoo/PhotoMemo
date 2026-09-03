#if os(iOS) && !MEMOMARK_SHARE_EXTENSION
import SwiftUI

struct SubjectOverviewSubjectRail: View {

    let subjects: [MemorySubject]
    let selectedSubjectID: MemorySubject.ID?
    let switchCandidateSubjectID: MemorySubject.ID?
    let onSelectSubject: (MemorySubject.ID) -> Void
    let onAddSubject: () -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(subjects) { subject in
                    subjectButton(subject)
                }

                Button(action: onAddSubject) {
                    Image(systemName: "plus")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(Color.accentColor)
                        .frame(width: 58, height: 58)
                        .background(
                            Circle()
                                .fill(ConfigurationUI.panelBackground)
                        )
                        .overlay(
                            Circle()
                                .stroke(ConfigurationUI.faintHairline)
                        )
                }
                .buttonStyle(.plain)
                .accessibilityLabel("新增记忆对象")
            }
            .padding(.horizontal, 2)
        }
        .contentMargins(.horizontal, 1, for: .scrollContent)
    }

    private func subjectButton(
        _ subject: MemorySubject
    ) -> some View {
        Button {
            onSelectSubject(subject.id)
        } label: {
            VStack(spacing: 7) {
                SubjectAvatarView(
                    imagePath:
                        subject.identity.avatarPreviewImagePath
                        ?? subject.identity.avatarImagePath,
                    size: 48
                )

                Text(displayName(subject))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .frame(width: 76)
            }
            .padding(10)
            .background(
                RoundedRectangle(
                    cornerRadius: 18,
                    style: .continuous
                )
                .fill(ConfigurationUI.panelBackground)
            )
            .overlay(
                RoundedRectangle(
                    cornerRadius: 18,
                    style: .continuous
                )
                .stroke(
                    subject.id == resolvedCandidateID
                    ? Color.accentColor.opacity(0.45)
                    : ConfigurationUI.faintHairline
                )
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(
            MemoMarkDynamicInterfaceText
            .subjectSwitchLabel(
                subjectName:
                    displayName(subject),
                language: .interfaceStored
            )
        )
        .accessibilityAddTraits(
            subject.id == selectedSubjectID
            ? .isSelected
            : []
        )
    }

    private var resolvedCandidateID: MemorySubject.ID? {
        switchCandidateSubjectID
        ?? selectedSubjectID
        ?? subjects.first?.id
    }

    private func displayName(
        _ subject: MemorySubject
    ) -> String {
        let trimmed = subject.identity.displayName
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "记忆对象" : trimmed
    }
}
#endif

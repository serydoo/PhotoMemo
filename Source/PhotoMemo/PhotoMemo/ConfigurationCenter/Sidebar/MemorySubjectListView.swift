#if !PHOTOMEMO_SHARE_EXTENSION
import SwiftUI

struct MemorySubjectListView: View {

    @ObservedObject
    var session: ConfigurationSession

    var body: some View {
        List {
            Section {
                sidebarTitle
            }

            ForEach(groupedSubjects) { group in
                Section(group.title) {
                    ForEach(group.subjects) { subject in
                        Button {
                            session.selectSubject(subject)
                        } label: {
                            MemorySubjectRow(
                                subject: subject,
                                isSelected:
                                    subject.id
                                    == session.state.selectedSubject?.id
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            Section {
                Button {
                } label: {
                    Label("New Subject", systemImage: "plus")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(Color.accentColor)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 5)
                }
                .buttonStyle(.plain)
            }
        }
        .listStyle(.sidebar)
        .safeAreaInset(edge: .bottom) {
            VStack(alignment: .leading, spacing: 7) {
                Text("Memory Object Library")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.primary)

                Text("Apple Photos remains the reading space.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(.regularMaterial)
        }
    }

    private var sidebarTitle: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Library")
                .font(.title2.weight(.semibold))
                .foregroundStyle(Color.primary)

            Text("Memory Subjects")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 8)
    }

    private var groupedSubjects: [MemorySubjectGroup] {
        let people =
            session.state.subjects
            .filter {
                $0.relationship.role == "Family"
            }

        let travel =
            session.state.subjects
            .filter {
                $0.relationship.role == "Travel"
            }

        return [
            MemorySubjectGroup(
                title: "People",
                subjects: people
            ),
            MemorySubjectGroup(
                title: "Travel",
                subjects: travel
            )
        ]
        .filter {
            !$0.subjects.isEmpty
        }
    }
}

private struct MemorySubjectGroup:
    Identifiable {

    let id = UUID()
    var title: String
    var subjects: [MemorySubject]
}

private struct MemorySubjectRow: View {

    let subject: MemorySubject
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: iconName)
                .font(.body.weight(.semibold))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(
                    isSelected
                    ? Color.accentColor
                    : Color.secondary
                )
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 3) {
                Text(subject.identity.displayName)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.primary)

                Text(subject.relationship.label)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 0)

            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.accentColor)
            }
        }
        .padding(.vertical, 6)
        .contentShape(Rectangle())
    }

    private var iconName: String {
        subject.decorations
            .first(where: { $0.kind == .icon })?
            .systemSymbolName ?? "person.fill"
    }
}
#endif

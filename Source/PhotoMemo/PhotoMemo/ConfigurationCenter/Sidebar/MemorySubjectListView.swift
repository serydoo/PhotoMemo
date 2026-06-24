#if !PHOTOMEMO_SHARE_EXTENSION
import SwiftUI

struct MemorySubjectListView: View {

    @ObservedObject
    var session: ConfigurationSession

    var body: some View {
        List {
            Section("Memory Subjects") {
                ForEach(session.state.subjects) { subject in
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
        .listStyle(.sidebar)
        .safeAreaInset(edge: .bottom) {
            VStack(alignment: .leading, spacing: 8) {
                Label(
                    "Configuration Center",
                    systemImage: "slider.horizontal.3"
                )
                .font(.caption.weight(.semibold))

                Text("Apple Photos remains the reading space.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(14)
            .background(Color.white)
        }
    }
}

private struct MemorySubjectRow: View {

    let subject: MemorySubject
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: iconName)
                .font(.body.weight(.semibold))
                .foregroundStyle(
                    isSelected
                    ? Color.accentColor
                    : Color.secondary
                )
                .frame(width: 22)

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
                    .foregroundStyle(Color.accentColor)
            }
        }
        .padding(.vertical, 6)
        .contentShape(Rectangle())
    }

    private var iconName: String {
        subject.decorations
            .first(where: { $0.kind == .icon })?
            .systemSymbolName ?? "person.crop.circle"
    }
}
#endif

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
                    Label("新建记忆对象", systemImage: "plus")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(Color.accentColor)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 7)
                }
                .buttonStyle(.plain)
            }
        }
        .listStyle(.sidebar)
        .safeAreaInset(edge: .bottom) {
            VStack(alignment: .leading, spacing: 10) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("时间锚点")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.primary)

                    Text("不同记忆对象拥有不同锚点，也拥有不同的回忆角度。")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Divider()
                    .opacity(0.45)

                VStack(alignment: .leading, spacing: 4) {
                    Text("记忆对象资料库")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.primary)

                    Text("PhotoMemo 用锚点帮助你阅读回忆。")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(.thinMaterial)
        }
    }

    private var sidebarTitle: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text("资料库")
                .font(.title3.weight(.semibold))
                .foregroundStyle(Color.primary)

            Text("记忆对象")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 6)
    }

    private var groupedSubjects: [MemorySubjectGroup] {
        let people =
            session.state.subjects
            .filter {
                $0.relationship.role == "家庭"
            }

        let travel =
            session.state.subjects
            .filter {
                $0.relationship.role == "旅行"
            }

        return [
            MemorySubjectGroup(
                title: "人物",
                subjects: people
            ),
            MemorySubjectGroup(
                title: "旅行",
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
                    .font(.subheadline.weight(.medium))
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
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(
                    isSelected
                    ? ConfigurationUI.selectedBackground
                    : Color.clear
                )
        )
        .contentShape(RoundedRectangle(cornerRadius: 8))
    }

    private var iconName: String {
        subject.decorations
            .first(where: { $0.kind == .icon })?
            .systemSymbolName ?? "person.fill"
    }
}
#endif

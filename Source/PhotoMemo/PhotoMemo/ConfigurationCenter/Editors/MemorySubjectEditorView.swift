#if !PHOTOMEMO_SHARE_EXTENSION
import SwiftUI

struct MemorySubjectEditorView: View {

    @ObservedObject
    var session: ConfigurationSession

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if let subject = session.state.selectedSubject {
                editorRow(
                    "Identity",
                    value: subject.identity.displayName,
                    symbol: "person.text.rectangle"
                )
                editorRow(
                    "Relationship",
                    value: subject.relationship.label,
                    symbol: "person.2"
                )
                editorRow(
                    "Reference Date",
                    value:
                        subject.referenceDate.formatted(
                            date: .abbreviated,
                            time: .omitted
                        ),
                    symbol: "calendar"
                )
                editorRow(
                    "Primary Anchor",
                    value: subject.behavior.primaryAnchor,
                    symbol: "mappin.and.ellipse"
                )
                editorRow(
                    "Icon Strategy",
                    value: subject.behavior.iconStrategy.rawValue,
                    symbol: "sparkles"
                )
                editorRow(
                    "Badge Strategy",
                    value: subject.behavior.badgeStrategy.rawValue,
                    symbol: "seal"
                )
            }
        }
    }

    private func editorRow(
        _ title: String,
        value: String,
        symbol: String
    ) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: symbol)
                .frame(width: 22)
                .foregroundStyle(Color.accentColor)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)

                Text(value)
                    .font(.body)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.gray.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}
#endif

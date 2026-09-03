#if !MEMOMARK_SHARE_EXTENSION
import SwiftUI

/// Displays immutable time-anchor rows and forwards mutations to the editor
/// that owns the draft transaction and committed persistence projection.
struct SubjectTimeAnchorSelectionCard: View {

    let anchors: [MemorySubject.TimeAnchor]
    let editingAnchorID: UUID?
    let onConfigure: (UUID) -> Void
    let onDelete: (UUID) -> Void
    let onAdd: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            ForEach(
                Array(anchors.enumerated()),
                id: \.element.id
            ) { index, anchor in
                SubjectTimeAnchorRow(
                    anchor: anchor,
                    isEditing: anchor.id == editingAnchorID,
                    canDelete: anchors.count > MemorySubjectEditingDraft.minimumTimeAnchorCount,
                    onConfigure: {
                        onConfigure(anchor.id)
                    },
                    onDelete: {
                        onDelete(anchor.id)
                    }
                )

                if index < anchors.count - 1
                    || anchors.count < MemorySubjectEditingDraft.maximumTimeAnchorCount {
                    Rectangle()
                        .fill(ConfigurationUI.faintHairline)
                        .frame(height: 0.5)
                        .padding(.leading, 58)
                }
            }

            if anchors.count < MemorySubjectEditingDraft.maximumTimeAnchorCount {
                SubjectTimeAnchorAddRow(onAdd: onAdd)
            }
        }
    }
}

struct SubjectTimeAnchorAddRow: View {

    let onAdd: () -> Void

    var body: some View {
        Button(action: onAdd) {
            HStack(spacing: 12) {
                Image(systemName: "plus.circle.fill")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(Color.accentColor)
                    .frame(width: 34)

                VStack(alignment: .leading, spacing: 3) {
                    Text("新增时间锚点")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)

                    Text("最多可维护 5 个时间锚点")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
#endif

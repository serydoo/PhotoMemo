#if !MEMOMARK_SHARE_EXTENSION
import SwiftUI

private enum SubjectTimeAnchorMetrics {
    static let rowHeight: CGFloat = 52
}

struct SubjectTimeAnchorRow: View {
    let anchor: MemorySubject.TimeAnchor
    let isEditing: Bool
    let canDelete: Bool
    let onConfigure: () -> Void
    let onDelete: () -> Void

    @State private var showsDeleteConfirmation = false

    @Environment(\.dynamicTypeSize)
    private var dynamicTypeSize

    var body: some View {
        rowContent
            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                if canDelete {
                    Button(role: .destructive) {
                        showsDeleteConfirmation = true
                    } label: {
                        Label("删除", systemImage: "trash")
                    }
                    .tint(.red)
                }

                Button(action: onConfigure) {
                    Label("配置", systemImage: "slider.horizontal.3")
                }
                .tint(.blue)
            }
            .alert(
                "删除“\(anchor.title)”？",
                isPresented: $showsDeleteConfirmation
            ) {
                Button("取消", role: .cancel) {}
                Button("删除时间锚点", role: .destructive) { onDelete() }
            } message: {
                Text("配置中心会切换到仍然保留的时间锚点。此操作无法撤销。")
            }
    }

    private var rowContent: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text(anchor.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(dynamicTypeSize.isAccessibilitySize ? 2 : 1)

                Text(anchorDateText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                if dynamicTypeSize.isAccessibilitySize {
                    Text(anchor.resolvedAnchorType.compactDisplayName)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(anchorTypeTint)
                        .lineLimit(2)
                        .accessibilityLabel(anchorTypeAccessibilityLabel)
                }
            }

            Spacer(minLength: 0)

            if !dynamicTypeSize.isAccessibilitySize {
                Text(anchor.resolvedAnchorType.compactDisplayName)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(anchorTypeTint)
                    .lineLimit(1)
                    .accessibilityLabel(anchorTypeAccessibilityLabel)
            }

            Menu {
                Button(action: onConfigure) {
                    Label("配置", systemImage: "slider.horizontal.3")
                }
                if canDelete {
                    Button(role: .destructive) {
                        showsDeleteConfirmation = true
                    } label: {
                        Label("删除", systemImage: "trash")
                    }
                }
            } label: {
                Image(systemName: "ellipsis.circle")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(Color.accentColor.opacity(0.78))
                    .frame(
                        width: ConfigurationUI.minimumInteractiveHeight,
                        height: ConfigurationUI.minimumInteractiveHeight
                    )
            }
            .accessibilityLabel(Text(
                MemoMarkLanguage.interfaceStored.localized(
                    key: "accessibility.anchor_actions",
                    fallback: "Time anchor actions"
                )
            ))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, dynamicTypeSize.isAccessibilitySize ? 8 : 0)
        .frame(minHeight: SubjectTimeAnchorMetrics.rowHeight)
        .background(ConfigurationUI.controlBackground)
    }

    private var anchorDateText: String {
        anchor.date.formatted(
            .dateTime
                .year(.defaultDigits)
                .month(.defaultDigits)
                .day(.defaultDigits)
                .locale(MemoMarkLanguage.interfaceStored.locale)
        )
    }

    private var anchorTypeAccessibilityLabel: String {
        let typeName = anchor.resolvedAnchorType.localizedDisplayName(
            for: .interfaceStored
        )
        return MemoMarkLanguage.interfaceStored == .simplifiedChinese
            ? "类型，\(typeName)"
            : "Type, \(typeName)"
    }

    private var anchorTypeTint: Color {
        switch anchor.resolvedAnchorType {
        case .birthday: return .orange
        case .relationship: return .pink
        case .marriage: return .purple
        case .exam: return .green
        case .custom: return .blue
        }
    }
}

#endif

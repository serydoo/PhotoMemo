#if os(iOS) && !PHOTOMEMO_SHARE_EXTENSION
import SwiftUI

struct V1IOSSubjectOverviewCard: View {

    let presentation:
        V1IOSSubjectOverviewPresentation

    var body: some View {
        V1CardSurface(title: "概览") {
            VStack(alignment: .leading, spacing: 10) {
                overviewRow(
                    title: "主体身份",
                    value: presentation.expressionSubjectValue,
                    detail: presentation.expressionSubjectTitle
                )
                highlightedOverviewRow(
                    title: "当前生效时间锚点",
                    value: presentation.anchorTitle
                )
            }
        }
    }

    private func highlightedOverviewRow(
        title: String,
        value: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.accentColor)

            Text(value)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)
                .multilineTextAlignment(.leading)
        }
        .padding(12)
        .background(
            RoundedRectangle(
                cornerRadius: 12,
                style: .continuous
            )
            .fill(Color.accentColor.opacity(0.08))
        )
    }

    private func overviewRow(
        title: String,
        value: String,
        detail: String? = nil
    ) -> some View {
        HStack(alignment: .top, spacing: 8) {
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if let detail,
                   !detail.isEmpty {
                    Text(detail)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }

            Spacer(minLength: 0)

            Text(value)
                .font(.subheadline.weight(.medium))
                .multilineTextAlignment(.trailing)
        }
    }
}

struct V1IOSSubjectIdentitySection: View {

    let presentation:
        V1IOSSubjectOverviewPresentation

    let subject: MemorySubject?

    var body: some View {
        V1CardSurface(title: "基本资料") {
            VStack(alignment: .leading, spacing: 10) {
                identityRow(
                    title: "显示名称",
                    value:
                        subject?
                        .identity.displayName
                        ?? presentation.title
                )
                identityRow(
                    title: "昵称",
                    value:
                        normalized(
                            subject?
                            .identity.shortName
                        )
                        ?? "未设置"
                )
                identityRow(
                    title: "关系备注",
                    value:
                        normalized(
                            subject?
                            .relationship.label
                        )
                        ?? "未设置"
                )
            }
        }
    }

    private func identityRow(
        title: String,
        value: String
    ) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)

            Spacer(minLength: 0)

            Text(value)
                .font(.subheadline.weight(.medium))
                .multilineTextAlignment(.trailing)
        }
    }

    private func normalized(
        _ text: String?
    ) -> String? {
        guard let text else {
            return nil
        }

        let trimmed =
            text.trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        return trimmed.isEmpty
            ? nil
            : trimmed
    }
}

struct V1IOSSubjectAnchorSection: View {

    let presentation:
        V1IOSSubjectOverviewPresentation

    let subject: MemorySubject?

    @Binding
    var selectedAnchorID: UUID?

    var body: some View {
        let selectedAnchor =
            resolvedAnchor

        return V1CardSurface(title: "当前生效时间锚点") {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(
                            selectedAnchor?.title
                            ?? presentation.anchorTitle
                        )
                            .font(.subheadline.weight(.semibold))

                        Text(
                            selectedAnchor?.date.formatted(
                                .dateTime
                                    .year()
                                    .month()
                                    .day()
                            )
                            ?? presentation.anchorDateLabel
                        )
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer(minLength: 0)

                    V1IOSHomeStatusBadge(
                        text: presentation.anchorCountLabel,
                        tone: .accent
                    )
                }

                Text(
                    normalizedDescription(
                        for: selectedAnchor
                    )
                )
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(
                        horizontal: false,
                        vertical: true
                    )

                if let subject,
                   !subject.timeAnchors.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("选择要立即生效的时间锚点")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)

                        Picker(
                            "当前生效时间锚点",
                            selection:
                                Binding(
                                    get: {
                                        selectedAnchorID
                                        ?? subject
                                        .primaryTimeAnchor?
                                        .id
                                        ?? subject
                                        .timeAnchors
                                        .first?
                                        .id
                                        ?? UUID()
                                    },
                                    set: {
                                        selectedAnchorID = $0
                                    }
                                )
                        ) {
                            ForEach(subject.timeAnchors) { anchor in
                                Text(anchor.title)
                                    .tag(anchor.id)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                    .padding(12)
                    .background(
                        RoundedRectangle(
                            cornerRadius: 12,
                            style: .continuous
                        )
                        .fill(Color(.secondarySystemBackground))
                    )
                }
            }
        }
    }

    private var resolvedAnchor: MemorySubject.TimeAnchor? {
        guard let subject else {
            return nil
        }

        if let selectedAnchorID {
            return subject.timeAnchors.first {
                $0.id == selectedAnchorID
            }
        }

        return subject.primaryTimeAnchor
    }

    private func normalizedDescription(
        for anchor: MemorySubject.TimeAnchor?
    ) -> String {
        let trimmedNote =
            anchor?.note
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            ) ?? ""

        if !trimmedNote.isEmpty {
            return trimmedNote
        }

        return presentation.anchorDescription
    }
}
#endif

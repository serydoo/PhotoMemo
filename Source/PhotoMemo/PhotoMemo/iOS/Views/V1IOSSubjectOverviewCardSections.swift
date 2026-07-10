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

    var body: some View {
        V1CardSurface(title: "可用时间锚点") {
            VStack(alignment: .leading, spacing: 10) {
                Text("展示当前记忆对象下可用于配置的全部时间锚点；具体使用哪个锚点，由配置中心的当前配置决定。")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                if let subject,
                   !subject.timeAnchors.isEmpty {
                    VStack(spacing: 0) {
                        ForEach(subject.timeAnchors) { anchor in
                            anchorRow(anchor)

                            if anchor.id != subject.timeAnchors.last?.id {
                                Rectangle()
                                    .fill(ConfigurationUI.faintHairline)
                                    .frame(height: 0.5)
                                    .padding(.leading, 52)
                            }
                        }
                    }
                    .background(Color.white.opacity(0.94))
                    .clipShape(
                        RoundedRectangle(
                            cornerRadius: 18,
                            style: .continuous
                        )
                    )
                    .overlay(
                        RoundedRectangle(
                            cornerRadius: 18,
                            style: .continuous
                        )
                        .stroke(ConfigurationUI.faintHairline)
                    )
                } else {
                    Text("暂无可用时间锚点。")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private func anchorRow(
        _ anchor: MemorySubject.TimeAnchor
    ) -> some View {
        let trimmedNote =
            anchor.note
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        return HStack(alignment: .center, spacing: 12) {
            RoundedRectangle(
                cornerRadius: 12,
                style: .continuous
            )
            .fill(
                Color.primary.opacity(0.045)
            )
            .frame(width: 38, height: 38)
            .overlay {
                Image(
                    systemName:
                        iconName(for: anchor.resolvedAnchorType)
                )
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(anchor.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                Text(
                    trimmedNote.isEmpty
                    ? anchor.date.formatted(
                        date: .abbreviated,
                        time: .omitted
                    )
                    : "\(anchor.date.formatted(date: .abbreviated, time: .omitted)) · \(trimmedNote)"
                )
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
            }

            Spacer(minLength: 0)

            Text(anchor.resolvedAnchorType.displayName)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .background(
                    Capsule(style: .continuous)
                        .fill(Color.primary.opacity(0.045))
                )
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 11)
    }

    private func iconName(
        for anchorType: AnchorType
    ) -> String {
        switch anchorType {
        case .birthday:
            return "birthday.cake.fill"
        case .relationship:
            return "heart.fill"
        case .marriage:
            return "sparkles"
        case .exam:
            return "flag.checkered"
        case .custom:
            return "calendar"
        }
    }
}
#endif

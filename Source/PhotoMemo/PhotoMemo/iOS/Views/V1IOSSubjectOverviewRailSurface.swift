#if os(iOS) && !PHOTOMEMO_SHARE_EXTENSION
import SwiftUI

struct V1IOSSubjectOverviewSubjectRail: View {

    let subjects: [MemorySubject]
    let selectedSubjectID: MemorySubject.ID?
    let onSelectSubject: (MemorySubject.ID) -> Void
    let onAddSubject: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center, spacing: 10) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("对象切换")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(.primary)

                    Text("左右滑动查看不同记忆对象，保持当前卡片作为生效对象。")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: 0)

                V1IOSSubjectRailAddButton(
                    compact: subjects.count > 1,
                    action: onAddSubject
                )
            }

            if subjects.count <= 1 {
                singleCardLayout
            } else {
                multiCardLayout
            }
        }
    }

    private var singleCardLayout: some View {
        HStack(spacing: 12) {
            if let subject = subjects.first {
                V1IOSSubjectRailCard(
                    subject: subject,
                    isSelected: true,
                    action: {
                        onSelectSubject(subject.id)
                    }
                )
                .frame(maxWidth: .infinity)
            } else {
                V1IOSSubjectRailEmptyState(
                    action: onAddSubject
                )
            }

            V1IOSSubjectRailAddSpacer()
        }
    }

    private var multiCardLayout: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 14) {
                ForEach(subjects) { subject in
                    V1IOSSubjectRailCard(
                        subject: subject,
                        isSelected:
                            subject.id
                            == resolvedSelectedSubjectID,
                        action: {
                            onSelectSubject(subject.id)
                        }
                    )
                    .frame(width: 286)
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
}

private struct V1IOSSubjectRailCard: View {

    let subject: MemorySubject
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .top, spacing: 12) {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 8) {
                            V1IOSHomeStatusBadge(
                                text: isSelected ? "当前对象" : "可切换",
                                tone: isSelected ? .accent : .neutral
                            )

                            Text(subjectAnchorTitle)
                                .font(.caption.weight(.medium))
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }

                        Text(subjectDisplayName)
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(.primary)
                            .lineLimit(1)

                        Text(subjectRelationship)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }

                    Spacer(minLength: 0)

                    V1SubjectAvatarView(
                        imagePath:
                            subject.identity.avatarImagePath
                            ?? subject.identity.avatarPreviewImagePath,
                        size: 56
                    )
                }

                VStack(alignment: .leading, spacing: 10) {
                    V1IOSSubjectRailMetaRow(
                        title: "显示名称",
                        value: subject.identity.displayName
                    )

                    V1IOSSubjectRailMetaRow(
                        title: "时间锚点",
                        value: "\(subject.timeAnchors.count) 个"
                    )
                }

                HStack(spacing: 8) {
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "arrow.left.arrow.right.circle")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(
                            isSelected
                            ? Color.accentColor
                            : .secondary
                        )

                    Text(
                        isSelected
                        ? "当前用于生成与预览"
                        : "点按切换到这个对象"
                    )
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)

                    Spacer(minLength: 0)
                }
            }
            .padding(18)
            .frame(maxWidth: .infinity, minHeight: 188, alignment: .topLeading)
            .background(cardBackground)
            .overlay(cardBorder)
            .shadow(
                color:
                    isSelected
                    ? ConfigurationUI.cardShadow.opacity(1.15)
                    : ConfigurationUI.cardShadow.opacity(0.5),
                radius: isSelected ? 12 : 7,
                y: isSelected ? 5 : 3
            )
        }
        .buttonStyle(.plain)
    }

    private var cardBackground: some View {
        RoundedRectangle(
            cornerRadius: 24,
            style: .continuous
        )
        .fill(
            LinearGradient(
                colors: isSelected
                    ? [
                        Color.white,
                        Color.white.opacity(0.96)
                    ]
                    : [
                        Color.white.opacity(0.93),
                        Color.white.opacity(0.88)
                    ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }

    private var cardBorder: some View {
        RoundedRectangle(
            cornerRadius: 24,
            style: .continuous
        )
        .stroke(
            isSelected
            ? Color.accentColor.opacity(0.34)
            : ConfigurationUI.faintHairline,
            lineWidth: isSelected ? 1.1 : 0.8
        )
    }

    private var subjectDisplayName: String {
        let shortName =
            subject.identity.shortName
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        if !shortName.isEmpty {
            return shortName
        }

        return subject.identity.displayName
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

    private var subjectAnchorTitle: String {
        subject.primaryTimeAnchor?.title
        ?? subject.behavior.primaryAnchor
    }
}

private struct V1IOSSubjectRailMetaRow: View {

    let title: String
    let value: String

    var body: some View {
        HStack(spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)

            Spacer(minLength: 0)

            Text(value)
                .font(.caption.weight(.medium))
                .foregroundStyle(.primary)
                .lineLimit(1)
        }
    }
}

private struct V1IOSSubjectRailAddButton: View {

    let compact: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: compact ? 0 : 6) {
                Image(systemName: "plus")
                    .font(.subheadline.weight(.semibold))

                if !compact {
                    Text("新增对象")
                        .font(.caption.weight(.semibold))
                }
            }
            .foregroundStyle(Color.accentColor)
            .frame(
                width: compact ? 36 : 88,
                height: 36
            )
            .background(
                Capsule(style: .continuous)
                    .fill(Color.white.opacity(0.94))
            )
            .overlay(
                Capsule(style: .continuous)
                    .stroke(ConfigurationUI.faintHairline)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("新增记忆对象")
    }
}

private struct V1IOSSubjectRailAddSpacer: View {

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: "plus.circle")
                .font(.title3.weight(.semibold))
                .foregroundStyle(Color.accentColor.opacity(0.72))

            Text("为新增入口留出位置")
                .font(.caption2)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
        }
        .frame(width: 78)
        .frame(minHeight: 188)
        .background(
            RoundedRectangle(
                cornerRadius: 24,
                style: .continuous
            )
            .fill(Color.white.opacity(0.45))
        )
        .overlay(
            RoundedRectangle(
                cornerRadius: 24,
                style: .continuous
            )
            .stroke(
                ConfigurationUI.faintHairline,
                style: StrokeStyle(
                    lineWidth: 0.8,
                    dash: [5, 6]
                )
            )
        )
        .accessibilityHidden(true)
    }
}

private struct V1IOSSubjectRailEmptyState: View {

    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 10) {
                Image(systemName: "person.crop.rectangle.badge.plus")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(Color.accentColor)

                Text("还没有记忆对象")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.primary)

                Text("先新增一个对象，再为它补充昵称、关系与时间锚点。")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(18)
            .frame(maxWidth: .infinity, minHeight: 188, alignment: .topLeading)
            .background(
                RoundedRectangle(
                    cornerRadius: 24,
                    style: .continuous
                )
                .fill(Color.white.opacity(0.9))
            )
            .overlay(
                RoundedRectangle(
                    cornerRadius: 24,
                    style: .continuous
                )
                .stroke(ConfigurationUI.faintHairline)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("新增记忆对象")
    }
}
#endif

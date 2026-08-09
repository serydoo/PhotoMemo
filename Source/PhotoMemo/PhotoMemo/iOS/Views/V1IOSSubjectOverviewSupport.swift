#if !PHOTOMEMO_SHARE_EXTENSION
import Foundation
import SwiftUI
#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

#if os(iOS)

struct V1IOSSubjectHomeEntryContent<StatisticsStrip: View>: View {

    let subjectSummary:
        V1IOSHomeSubjectSummaryProjection

    let subject: MemorySubject?

    let onOpenSubject: () -> Void

    let statisticsStrip: StatisticsStrip

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            V1IOSSubjectPrimaryCard(
                summary: subjectSummary,
                subject: subject,
                action: onOpenSubject,
                statisticsStrip: statisticsStrip
            )
        }
    }
}

private struct V1IOSSubjectPrimaryCard<StatisticsStrip: View>: View {

    let summary:
        V1IOSHomeSubjectSummaryProjection

    let subject: MemorySubject?

    let action: () -> Void

    let statisticsStrip: StatisticsStrip

    var body: some View {
        Button(action: action) {
            responsiveCardContent
            .padding(16)
            .background(
                RoundedRectangle(
                    cornerRadius: ConfigurationUI.cornerRadius,
                    style: .continuous
                )
                .fill(ConfigurationUI.panelBackground)
            )
            .overlay(
                RoundedRectangle(
                    cornerRadius: ConfigurationUI.cornerRadius,
                    style: .continuous
                )
                .stroke(ConfigurationUI.faintHairline)
            )
        }
        .buttonStyle(.plain)
    }

    private var responsiveCardContent: some View {
        ViewThatFits(in: .horizontal) {
            regularCardContent
            compactCardContent
        }
    }

    private var regularCardContent: some View {
        HStack(spacing: 14) {
            subjectAvatar(size: 68)

            VStack(alignment: .leading, spacing: 8) {
                subjectTitle
                subjectMetaRow
                statisticsStrip
            }
            .layoutPriority(1)

            Spacer(minLength: 8)
            disclosureIndicator
        }
    }

    private var compactCardContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                subjectAvatar(size: 60)

                VStack(alignment: .leading, spacing: 7) {
                    subjectTitle
                    subjectMetaRow
                }
                .layoutPriority(1)

                Spacer(minLength: 4)
                disclosureIndicator
            }

            statisticsStrip
        }
    }

    private var subjectTitle: some View {
        Text(summary.title)
            .font(.title3.weight(.semibold))
            .foregroundStyle(.primary)
            .lineLimit(1)
    }

    private func subjectAvatar(
        size: CGFloat
    ) -> some View {
        V1SubjectAvatarView(
            imagePath:
                subject?
                .identity.avatarImagePath
                ?? subject?
                .identity.avatarPreviewImagePath,
            size: size
        )
    }

    private var disclosureIndicator: some View {
        Image(systemName: "chevron.right")
            .font(.caption.weight(.semibold))
            .foregroundStyle(Color.accentColor)
            .frame(width: 12)
    }

    private var anchorCountText: String {
        let count = max(subject?.timeAnchors.count ?? 0, 0)
        return "\(count) 个重要日子"
    }

    private var subjectMetaRow: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 6) {
                subjectSubtitlePill
                subjectAnchorCountPill
            }

            VStack(alignment: .leading, spacing: 6) {
                subjectSubtitlePill
                subjectAnchorCountPill
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var subjectSubtitlePill: some View {
        V1IOSSubjectMetaPill(
            text: summary.subtitle,
            tone: .neutral
        )
    }

    private var subjectAnchorCountPill: some View {
        let count = max(subject?.timeAnchors.count ?? 0, 0)
        return V1IOSSubjectMetaPill(
            text: anchorCountText,
            tone: .accent
        )
        .accessibilityLabel("已设置 \(count) 个时间锚点")
    }

}

struct V1IOSTodayTimeAnswerStrip: View {

    let anchor: MemorySubject.TimeAnchor
    let subjectName: String

    var body: some View {
        TimelineView(.periodic(from: .now, by: 3_600)) { context in
            let presentation = V1TimeAnchorTodayPresenter.presentation(
                anchor: anchor,
                subjectName: subjectName,
                referenceDate: context.date
            )

            HStack(spacing: 10) {
                answerIcon

                VStack(alignment: .leading, spacing: 2) {
                    Text(presentation.title)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)

                    Text(presentation.value)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.primary)
                        .monospacedDigit()
                        .contentTransition(.numericText())
                        .lineLimit(2)
                }

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .frame(
                maxWidth: .infinity,
                minHeight: ConfigurationUI.minimumInteractiveHeight,
                alignment: .leading
            )
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(answerTint.opacity(0.07))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(answerTint.opacity(0.12))
            )
            .accessibilityElement(children: .combine)
            .accessibilityLabel(presentation.accessibilityText)
        }
    }

    private var answerIcon: some View {
        ZStack {
            Circle()
                .fill(answerTint.opacity(0.12))

            Image(systemName: "sparkles")
                .font(.caption2.weight(.bold))
                .foregroundStyle(answerTint)
        }
        .frame(width: 24, height: 24)
    }

    private var answerTint: Color {
        MemoMarkDesignTokens.Semantic.memoryStatistics
    }
}

struct V1SubjectAvatarView: View {

    let imagePath: String?
    let size: CGFloat

    var body: some View {
        ZStack {
            Circle()
                .fill(
                    Color.accentColor
                        .opacity(0.12)
                )

            if let imagePath {
                V1PlatformAvatarImage(path: imagePath)
                    .scaledToFill()
                    .clipShape(Circle())
            } else {
                Image(systemName: MemoMarkSymbol.memorySubject.name)
                    .font(.system(size: size * 0.36, weight: .medium))
                    .foregroundStyle(Color.accentColor)
            }
        }
        .frame(width: size, height: size)
        .overlay(
            Circle()
                .stroke(ConfigurationUI.faintHairline)
        )
    }
}

private struct V1PlatformAvatarImage: View {

    let path: String

    var body: some View {
#if os(macOS)
        if let image = NSImage(contentsOfFile: path) {
            Image(nsImage: image)
                .resizable()
        } else {
            Color.clear
        }
#elseif canImport(UIKit)
        if let image = UIImage(contentsOfFile: path) {
            Image(uiImage: image)
                .resizable()
        } else {
            Color.clear
        }
#endif
    }
}

private struct V1IOSHomeLinkRow: View {

    let title: String
    let subtitle: String
    let value: String
    let detail: String
    let systemImage: String
    let showsDivider: Bool
    let action: () -> Void
    let emphasizedValue: Bool

    init(
        title: String,
        subtitle: String,
        value: String,
        detail: String,
        systemImage: String,
        showsDivider: Bool = true,
        action: @escaping () -> Void,
        emphasizedValue: Bool = false
    ) {
        self.title = title
        self.subtitle = subtitle
        self.value = value
        self.detail = detail
        self.systemImage = systemImage
        self.showsDivider = showsDivider
        self.action = action
        self.emphasizedValue = emphasizedValue
    }

    var body: some View {
        VStack(spacing: 0) {
            Button(action: action) {
                HStack(alignment: .center, spacing: 12) {
                    ZStack {
                        RoundedRectangle(
                            cornerRadius: 10,
                            style: .continuous
                        )
                        .fill(ConfigurationUI.controlBackground)

                        Image(systemName: systemImage)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Color.accentColor)
                    }
                    .frame(width: 34, height: 34)

                    VStack(alignment: .leading, spacing: 3) {
                        Text(title)
                            .font(.body.weight(.semibold))
                            .foregroundStyle(.primary)
                        Text(subtitle)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }

                    Spacer(minLength: 12)

                    VStack(alignment: .trailing, spacing: 3) {
                        Text(value)
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(
                                emphasizedValue
                                ? Color.accentColor
                                : .primary
                            )
                            .lineLimit(1)

                        Text(detail)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }

                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.accentColor)
                }
                .contentShape(Rectangle())
                .padding(.horizontal, 14)
                .padding(
                    .vertical,
                    ConfigurationUI.compactRowVerticalPadding
                )
            }
            .buttonStyle(.plain)

            if showsDivider {
                V1HorizontalDivider(horizontalInset: 14)
            }
        }
    }
}

private struct V1IOSSubjectMetaPill: View {

    let text: String
    let tone: V1IOSHomeStatusBadge.Tone

    var body: some View {
        Text(text)
            .font(.caption2.weight(.semibold))
            .foregroundStyle(tone.tint)
            .lineLimit(1)
            .truncationMode(.tail)
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(
                Capsule(style: .continuous)
                    .fill(tone.background)
            )
            .fixedSize(horizontal: true, vertical: false)
    }
}

#endif
#endif

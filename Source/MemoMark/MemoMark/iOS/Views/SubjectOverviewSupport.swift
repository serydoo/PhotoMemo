#if !MEMOMARK_SHARE_EXTENSION
import Foundation
import SwiftUI
#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

#if os(iOS)

struct SubjectHomeEntryContent<StatisticsStrip: View>: View {

    let subjectSummary:
        HomeSubjectSummaryProjection

    let subject: MemorySubject?

    let onOpenSubject: () -> Void

    let statisticsStrip: StatisticsStrip

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            SubjectPrimaryCard(
                summary: subjectSummary,
                subject: subject,
                action: onOpenSubject,
                statisticsStrip: statisticsStrip
            )
        }
    }
}

private struct SubjectPrimaryCard<StatisticsStrip: View>: View {

    let summary:
        HomeSubjectSummaryProjection

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
        .accessibilityIdentifier("subject-home-entry")
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
        SubjectAvatarView(
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
        let language = MemoMarkLanguage.interfaceStored
        let format = language.localized(
            key: "home.subject.anchor_count_format",
            fallback: "%lld 个重要日子"
        )
        return String(
            format: format,
            locale: language.locale,
            Int64(count)
        )
    }

    private var subjectMetaRow: some View {
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                subjectSubtitleText
                Text("·")
                    .foregroundStyle(.tertiary)
                subjectAnchorCountText
            }

            VStack(alignment: .leading, spacing: 6) {
                subjectSubtitleText
                subjectAnchorCountText
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var subjectSubtitleText: some View {
        Text(summary.subtitle)
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .lineLimit(1)
            .minimumScaleFactor(0.85)
    }

    private var subjectAnchorCountText: some View {
        return Text(anchorCountText)
            .font(.subheadline.weight(.medium))
            .foregroundStyle(.secondary)
            .lineLimit(1)
            .minimumScaleFactor(0.85)
            .accessibilityLabel(anchorCountText)
    }

}

struct TodayTimeAnswerStrip: View {

    let anchor: MemorySubject.TimeAnchor
    let subjectName: String

    var body: some View {
        TimelineView(.periodic(from: .now, by: 3_600)) { context in
            let presentation = TimeAnchorTodayPresenter.presentation(
                anchor: anchor,
                subjectName: subjectName,
                referenceDate: context.date
            )

            VStack(alignment: .leading, spacing: 8) {
                Divider()

                HStack(spacing: 10) {
                    answerIcon

                    VStack(alignment: .leading, spacing: 2) {
                        Text(presentation.title)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)

                        Text(presentation.value)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.primary)
                            .monospacedDigit()
                            .contentTransition(.numericText())
                            .lineLimit(2)
                    }

                    Spacer(minLength: 0)
                }
            }
            .padding(.top, 2)
            .padding(.bottom, 1)
            .frame(
                maxWidth: .infinity,
                minHeight: ConfigurationUI.minimumInteractiveHeight,
                alignment: .leading
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

struct SubjectAvatarView: View {

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
                PlatformAvatarImage(path: imagePath)
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

private struct PlatformAvatarImage: View {

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

private struct HomeLinkRow: View {

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
                HorizontalDivider(horizontalInset: 14)
            }
        }
    }
}

#endif
#endif

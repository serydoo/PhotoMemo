#if !PHOTOMEMO_SHARE_EXTENSION
import Foundation
import SwiftUI
#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

#if os(iOS)

struct V1IOSSubjectHomeEntryContent: View {

    let subjectSummary:
        V1IOSHomeSubjectSummaryProjection

    let subject: MemorySubject?

    let availableConfigurationCount: Int

    let completedPhotoCount: Int

    let onOpenSubject: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            V1IOSSubjectPrimaryCard(
                summary: subjectSummary,
                subject: subject,
                availableConfigurationCount:
                    availableConfigurationCount,
                completedPhotoCount:
                    completedPhotoCount,
                action: onOpenSubject
            )
        }
    }
}

private struct V1IOSSubjectPrimaryCard: View {

    let summary:
        V1IOSHomeSubjectSummaryProjection

    let subject: MemorySubject?

    let availableConfigurationCount: Int

    let completedPhotoCount: Int

    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                V1SubjectAvatarView(
                    imagePath:
                        subject?
                        .identity.avatarImagePath
                        ?? subject?
                        .identity.avatarPreviewImagePath,
                    size: 60
                )

                VStack(alignment: .leading, spacing: 8) {
                    Text(summary.title)
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(1)

                    subjectMetaRow

                    memoryRecordStrip
                }
                .layoutPriority(1)

                Spacer(minLength: 8)

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.tertiary)
                    .frame(width: 12)
            }
            .padding(16)
            .background(
                RoundedRectangle(
                    cornerRadius: ConfigurationUI.cornerRadius,
                    style: .continuous
                )
                .fill(Color.white.opacity(0.92))
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

    private var anchorCountText: String {
        let count = max(subject?.timeAnchors.count ?? 0, 0)
        return "\(count) 个锚点"
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
        V1IOSSubjectMetaPill(
            text: anchorCountText,
            tone: .accent
        )
    }

    private var memoryRecordStrip: some View {
        HStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(Color.green.opacity(0.12))

                Image(systemName: "sparkles")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(Color.green)
            }
            .frame(width: 24, height: 24)

            statText(
                title: "可用配置",
                value:
                    "\(max(availableConfigurationCount, 0)) 个"
            )

            Rectangle()
                .fill(Color.green.opacity(0.16))
                .frame(width: 1, height: 18)

            statText(
                title: "累计完成",
                value:
                    "\(max(completedPhotoCount, 0)) 张"
            )
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 7)
        .background(
            RoundedRectangle(
                cornerRadius: 10,
                style: .continuous
            )
            .fill(Color.green.opacity(0.07))
        )
        .overlay(
            RoundedRectangle(
                cornerRadius: 10,
                style: .continuous
            )
            .stroke(Color.green.opacity(0.12))
        )
    }

    private func statText(
        title: String,
        value: String
    ) -> some View {
        HStack(spacing: 4) {
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: true, vertical: false)

            Text(value)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.primary)
                .monospacedDigit()
                .fixedSize(horizontal: true, vertical: false)
        }
        .lineLimit(1)
        .fixedSize(horizontal: true, vertical: false)
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
                Image(systemName: "person.crop.circle.fill")
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
                        .foregroundStyle(.tertiary)
                }
                .contentShape(Rectangle())
                .padding(.horizontal, 14)
                .padding(.vertical, 13)
            }
            .buttonStyle(.plain)

            if showsDivider {
                Rectangle()
                    .fill(ConfigurationUI.faintHairline)
                    .frame(height: 0.5)
                    .padding(.leading, 50)
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

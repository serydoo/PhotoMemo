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

    let onOpenSubject: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            V1IOSSubjectPrimaryCard(
                summary: subjectSummary,
                subject: subject,
                action: onOpenSubject
            )
        }
    }
}

private struct V1IOSSubjectPrimaryCard: View {

    let summary:
        V1IOSHomeSubjectSummaryProjection

    let subject: MemorySubject?

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
                    size: 68
                )

                VStack(alignment: .leading, spacing: 6) {
                    Text("当前记忆对象")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)

                    Text(summary.title)
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(1)

                    Text(summary.subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)

                    HStack(spacing: 8) {
                        V1IOSHomeStatusBadge(
                            text: "当前生效时间锚点",
                            tone: .accent
                        )

                        Text(summary.anchorTitle)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer(minLength: 0)

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.tertiary)
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

#endif
#endif

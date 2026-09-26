#if os(iOS) && !MEMOMARK_SHARE_EXTENSION
import SwiftUI
import UIKit

/// Presentation-only row for a Home preset. Selection persistence remains a
/// Home-page callback owned by the Configuration Center runtime.
struct HomeMemoryPresetRow: View {

    private var interfaceLanguage: MemoMarkLanguage { .interfaceStored }

    @Environment(\.dynamicTypeSize)
    private var dynamicTypeSize

    let preset: MemoryPreset
    let borderStyleName: String
    let anchorType: AnchorType
    let subjectTitle: String
    let subjectAvatarImagePath: String?
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            rowContent
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityLabel(presetAccessibilityLabel)
    }

    private var rowContent: some View {
        adaptivePresetRowContent
            .padding(.horizontal, ConfigurationUI.innerPanelPadding)
            .padding(.vertical, ConfigurationUI.compactRowVerticalPadding)
    }

    @ViewBuilder
    private var adaptivePresetRowContent: some View {
        if dynamicTypeSize.isAccessibilitySize {
            verticalPresetRowContent
        } else {
            ViewThatFits(in: .horizontal) {
                horizontalPresetRowContent
                verticalPresetRowContent
            }
        }
    }

    private var horizontalPresetRowContent: some View {
        HStack(alignment: .center, spacing: 12) {
            presetIdentityMark
            horizontalPresetTextContent
            Spacer(minLength: 8)
            presetSelectionMark
        }
    }

    private var verticalPresetRowContent: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 12) {
                presetIdentityMark
                verticalPresetTextContent
            }
            presetSelectionMark.frame(maxWidth: .infinity, alignment: .trailing)
        }
    }

    private var horizontalPresetTextContent: some View {
        VStack(alignment: .leading, spacing: 4) {
            presetTitleText
            horizontalPresetMetadata
        }
        .fixedSize(horizontal: false, vertical: true)
    }

    private var verticalPresetTextContent: some View {
        VStack(alignment: .leading, spacing: 4) {
            presetTitleText
            Text(presetDescriptor)
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)
                .lineLimit(2)
            Text(subjectTitle)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(2)
            Text(presetDetail)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(2)
        }
        .fixedSize(horizontal: false, vertical: true)
    }

    private var presetTitleText: some View {
        Text(preset.title)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.primary)
            .lineLimit(2)
    }

    private var horizontalPresetMetadata: some View {
        HStack(alignment: .firstTextBaseline, spacing: 6) {
            Text(presetDescriptor)
            Text("·")
                .accessibilityHidden(true)
            Text(subjectTitle)
            if isSelected {
                Text("·")
                    .accessibilityHidden(true)
                Text(presetDetail)
            }
        }
        .font(.caption.weight(.medium))
        .foregroundStyle(.secondary)
        .lineLimit(1)
        .fixedSize(horizontal: true, vertical: false)
    }

    private var presetSelectionMark: some View {
        Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
            .font(.title3.weight(.semibold))
            .foregroundStyle(isSelected ? Color.accentColor : Color.secondary.opacity(0.58))
            .frame(width: 26, height: 30)
    }

    private var presetDetail: String {
        if isSelected {
            return localized("home.preset.active")
        }
        return preset.summary
    }

    private var presetAccessibilityLabel: String {
        String(
            format: localized("home.preset.accessibility_format"),
            locale: interfaceLanguage.locale,
            preset.title,
            presetDescriptor,
            subjectTitle,
            presetDetail
        )
    }

    private var presetDescriptor: String {
        let anchorTitle = anchorType.localizedDisplayName(
            for: interfaceLanguage
        )
        let styleTitle = borderStyleName.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
        let presetTitle = preset.title.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        guard !styleTitle.isEmpty,
              styleTitle.caseInsensitiveCompare(presetTitle)
                != .orderedSame else {
            return anchorTitle
        }

        return "\(anchorTitle) · \(styleTitle)"
    }

    private var presetIdentityMark: some View {
        ZStack(alignment: .bottomTrailing) {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(anchorTint.opacity(0.11))
                .overlay {
                    Image(systemName: anchorSystemImage)
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(anchorTint)
                }
            logoBadge.offset(x: 3, y: 3)
        }
        .frame(width: 48, height: 48)
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(anchorTint.opacity(0.12))
        )
        .accessibilityLabel(
            String(
                format: localized("home.preset.identity_format"),
                locale: interfaceLanguage.locale,
                anchorType.localizedDisplayName(for: interfaceLanguage),
                localizedLogoTitle
            )
        )
    }

    @ViewBuilder
    private var logoBadge: some View {
        ZStack {
            Circle()
                .fill(MemoMarkDesignTokens.Semantic.fixedLightBackground)
                .overlay(Circle().stroke(ConfigurationUI.faintHairline))
            switch preset.logoMode {
            case .appleMini:
                Image(systemName: "apple.logo")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(.primary)
            case .customUpload:
                Image(systemName: "photo.badge.checkmark")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(Color.purple)
            case .subjectAvatar:
                if let subjectAvatarImagePath,
                   let image = UIImage(contentsOfFile: subjectAvatarImagePath) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .clipShape(Circle())
                } else {
                    Image(systemName: MemoMarkSymbol.memorySubject.name)
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(Color.pink)
                }
            }
        }
        .frame(width: 19, height: 19)
        .shadow(color: ConfigurationUI.cardShadow, radius: 3, y: 1)
        .environment(\.colorScheme, .light)
    }

    private var anchorSystemImage: String {
        switch anchorType {
        case .birthday: return "birthday.cake.fill"
        case .relationship: return "heart.fill"
        case .marriage: return "sparkles"
        case .exam: return "flag.checkered"
        case .custom: return "calendar"
        }
    }

    private var anchorTint: Color {
        switch anchorType {
        case .birthday: return .orange
        case .relationship: return .pink
        case .marriage: return .purple
        case .exam: return .green
        case .custom: return .blue
        }
    }

    private var localizedLogoTitle: String {
        switch preset.logoMode {
        case .appleMini: return localized("home.logo.apple")
        case .customUpload: return localized("home.logo.custom")
        case .subjectAvatar: return localized("home.logo.avatar")
        }
    }

    private func localized(_ key: String) -> String {
        interfaceLanguage.localized(key: key, fallback: key)
    }
}
#endif

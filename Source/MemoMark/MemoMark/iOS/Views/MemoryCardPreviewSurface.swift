#if os(iOS) && !MEMOMARK_SHARE_EXTENSION
import SwiftUI
import UIKit

struct MemoryCardPreviewSurface: View {

    let presentationStyle: RecordCardPresentationStyle
    let logoMode: ConfigurationLogoMode
    let customLogoImagePath: String?
    let subjectAvatarLogoImagePath: String?
    let regionText: String
    let timeText: String
    let contextText: String
    let memoryText: String

    @ViewBuilder
    var body: some View {
        previewSurface
            .clipShape(
                RoundedRectangle(
                    cornerRadius: ConfigurationUI.cornerRadius,
                    style: .continuous
                )
            )
            .overlay(
                RoundedRectangle(
                    cornerRadius: ConfigurationUI.cornerRadius,
                    style: .continuous
                )
                    .stroke(ConfigurationUI.faintHairline)
            )
            .shadow(
                color: ConfigurationUI.cardShadow,
                radius: 8,
                y: 3
            )
    }

    @ViewBuilder
    private var previewSurface: some View {
        switch presentationStyle {
        case .classicWhite:
            Color.clear
                .aspectRatio(compactPreviewAspectRatio, contentMode: .fit)
                .overlay {
                    GeometryReader { proxy in
                        compactPreviewCard(size: proxy.size)
                    }
                }
        case .minimal:
            Color.clear
                .aspectRatio(
                    1 / MinimalCardLayoutSpecification
                        .compactPreview.imageSliceHeightToWidth,
                    contentMode: .fit
                )
                .overlay {
                    GeometryReader { proxy in
                        minimalPreviewCard(size: proxy.size)
                    }
                }
        }
    }

    private func minimalPreviewCard(size: CGSize) -> some View {
        let layout = MinimalRenderer.layout(for: .landscape)
        let barHeight = size.width * layout.barHeightToImageWidth

        return ZStack(alignment: .bottomTrailing) {
            minimalLandscapeSlice(
                width: size.width,
                height: size.height
            )
            .frame(
                width: size.width,
                height: size.height
            )

            minimalPreviewInformationBar(
                width: size.width,
                height: barHeight,
                layout: layout
            )
            .padding(
                .trailing,
                size.width * (1 - layout.trailingAnchorX)
            )
            .padding(
                .bottom,
                size.width * layout.overlayBottomInsetToImageWidth
            )
        }
        .frame(
            width: size.width,
            height: size.height
        )
        .clipped()
    }

    private func minimalPreviewInformationBar(
        width: CGFloat,
        height: CGFloat,
        layout: MinimalRenderer.Layout
    ) -> some View {
        let capsuleHeight = height * layout.capsuleHeightToBarHeight
        let avatarSize = min(
            height * layout.avatarSizeToBarHeight,
            capsuleHeight
        )
        return HStack(spacing: height * layout.avatarTextSpacingToBarHeight) {
            minimalLogo(
                size: avatarSize
            )
            .frame(
                width: height * layout.avatarAreaWidthToBarHeight,
                height: capsuleHeight,
                alignment: .leading
            )

            Text(regionText.isEmpty ? " " : regionText)
                .font(
                    .system(
                        size: height * layout.textSizeToBarHeight,
                        weight: .medium
                    )
                )
                .monospacedDigit()
                .foregroundStyle(MinimalRenderer.foreground)
                .lineLimit(layout.textLineLimit)
                .allowsTightening(true)
                .minimumScaleFactor(0.78)
        }
        .fixedSize(horizontal: true, vertical: false)
        .padding(
            .trailing,
            height * layout.capsuleHorizontalPaddingToBarHeight
        )
        .padding(
            .leading,
            height * layout.avatarLeadingInsetToBarHeight
        )
        .padding(
            .vertical,
            height * layout.capsuleVerticalPaddingToBarHeight
        )
        .background {
            RoundedRectangle(
                cornerRadius: capsuleHeight / 2,
                style: .continuous
            )
            .fill(MinimalRenderer.capsuleSurface)
            .overlay {
                RoundedRectangle(
                    cornerRadius: capsuleHeight / 2,
                    style: .continuous
                )
                .stroke(
                    MinimalRenderer.hairline,
                    lineWidth: max(1, height * 0.006)
                )
            }
        }
        .frame(
            maxWidth: width * layout.maximumModuleWidth,
            minHeight: capsuleHeight,
            alignment: .trailing
        )
    }

    private func minimalLandscapeSlice(
        width: CGFloat,
        height: CGFloat
    ) -> some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.73, green: 0.84, blue: 0.88),
                    Color(red: 0.93, green: 0.84, blue: 0.69)
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            Circle()
                .fill(Color.white.opacity(0.68))
                .frame(width: height * 0.34)
                .position(
                    x: width * 0.78,
                    y: height * 0.26
                )

            Path { path in
                path.move(to: CGPoint(x: 0, y: height * 0.80))
                path.addLine(to: CGPoint(x: width * 0.22, y: height * 0.30))
                path.addLine(to: CGPoint(x: width * 0.43, y: height * 0.79))
                path.addLine(to: CGPoint(x: width * 0.63, y: height * 0.46))
                path.addLine(to: CGPoint(x: width, y: height * 0.82))
                path.addLine(to: CGPoint(x: width, y: height))
                path.addLine(to: CGPoint(x: 0, y: height))
                path.closeSubpath()
            }
            .fill(
                Color(
                    red: 0.38,
                    green: 0.48,
                    blue: 0.45
                )
                .opacity(0.88)
            )

            LinearGradient(
                colors: [
                    Color(red: 0.42, green: 0.56, blue: 0.50),
                    Color(red: 0.26, green: 0.38, blue: 0.35)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: height * 0.31)
            .frame(maxHeight: .infinity, alignment: .bottom)
        }
        .frame(width: width, height: height)
        .clipped()
        .accessibilityHidden(true)
    }

    @ViewBuilder
    private func minimalLogo(size: CGFloat) -> some View {
        switch logoMode {
        case .appleMini:
            Image(systemName: "apple.logo")
                .font(.system(size: size, weight: .semibold))
        case .customUpload:
            if let customLogoImagePath,
               let image = UIImage(contentsOfFile: customLogoImagePath) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: size, height: size)
                    .clipShape(Circle())
            } else {
                Image(systemName: "apple.logo")
                    .font(.system(size: size * 0.82, weight: .semibold))
            }
        case .subjectAvatar:
            if let subjectAvatarLogoImagePath,
               let image = UIImage(contentsOfFile: subjectAvatarLogoImagePath) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: size, height: size)
                    .clipShape(Circle())
            } else {
                Image(systemName: "apple.logo")
                    .font(.system(size: size * 0.82, weight: .semibold))
            }
        }
    }

    private var compactSpec: CompactInformationBarSpec {
        RendererConstants.CompactInformationBar.landscape
    }

    private var compactPreviewAspectRatio: CGFloat {
        1 / compactSpec.barHeightToWidth
    }

    private func compactPreviewCard(size: CGSize) -> some View {
        let barHeight =
            size.width
            * compactSpec.barHeightToWidth

        return compactInformationBar(
            width: size.width,
            height: barHeight
        )
        .frame(height: barHeight)
    }

    private func compactInformationBar(
        width: CGFloat,
        height: CGFloat
    ) -> some View {
        let spec = compactSpec

        return ZStack(alignment: .topLeading) {
            RendererConstants.CompactInformationBar.background

            compactTextPair(
                primary: regionText,
                secondary: timeText,
                spec: spec,
                barHeight: height,
                emphasizesPrimary: false,
                primaryMinimumScaleFactor: 0.94,
                secondaryMinimumScaleFactor: 0.90
            )
            .frame(
                width:
                    width
                    * compactPreviewLeftTextWidth(
                        spec: spec
                    ),
                height: height * 0.62,
                alignment: .leading
            )
            .position(
                x:
                    width * spec.leftX
                    + width
                    * compactPreviewLeftTextWidth(
                        spec: spec
                    ) / 2,
                y: height * spec.contentCenterY
            )

            compactLogo(
                spec: spec,
                barHeight: height
            )
            .position(
                x: width * spec.logoCenterX,
                y: height * spec.contentCenterY
            )

            Rectangle()
                .fill(RendererConstants.CompactInformationBar.divider)
                .frame(
                    width:
                        min(
                            max(
                                height
                                * spec.dividerWidthToBarHeight,
                                2
                            ),
                            8
                        ),
                    height: height * spec.dividerHeight
                )
                .position(
                    x: width * spec.dividerCenterX,
                    y:
                        height * spec.dividerTopY
                        + height * spec.dividerHeight / 2
                )

            compactTextPair(
                primary: formattedCaptureSummaryText,
                secondary: memoryText,
                spec: spec,
                barHeight: height,
                primaryFontToBarHeight:
                    spec.rightPrimaryFontToBarHeight,
                primaryMinimumScaleFactor: 0.72,
                secondaryMinimumScaleFactor: 0.82
            )
            .frame(
                width: width * spec.rightWidth,
                height: height * 0.62,
                alignment: .leading
            )
            .position(
                x:
                    width * spec.rightX
                    + width * spec.rightWidth / 2,
                y: height * spec.contentCenterY
            )
        }
    }

    private func compactPreviewLeftTextWidth(
        spec: CompactInformationBarSpec
    ) -> CGFloat {

        min(
            max(
                spec.leftWidth,
                0.46
            ),
            spec.logoCenterX
            - spec.leftX
            - 0.10
        )
    }

    private func compactTextPair(
        primary: String,
        secondary: String,
        spec: CompactInformationBarSpec,
        barHeight: CGFloat,
        emphasizesPrimary: Bool = false,
        primaryFontToBarHeight: CGFloat? = nil,
        primaryMinimumScaleFactor: CGFloat = 0.84,
        secondaryMinimumScaleFactor: CGFloat = 0.84
    ) -> some View {
        VStack(
            alignment: .leading,
            spacing: barHeight * spec.groupSpacingToBarHeight
        ) {
            compactTextLine(
                primary,
                fontSize:
                    barHeight
                    * (
                        primaryFontToBarHeight
                        ?? spec.primaryFontToBarHeight
                    )
                    * (emphasizesPrimary ? 1.08 : 1),
                weight: emphasizesPrimary ? .bold : .semibold,
                tracking: spec.primaryTracking,
                color:
                    emphasizesPrimary
                    ? Color.black.opacity(0.98)
                    :
                    RendererConstants
                    .CompactInformationBar
                    .primaryText,
                minimumScaleFactor: primaryMinimumScaleFactor
            )
            .offset(
                y:
                    barHeight
                    * spec.primaryYOffsetToBarHeight
            )

            compactTextLine(
                secondary,
                fontSize:
                    barHeight
                    * spec.secondaryFontToBarHeight,
                weight: .regular,
                tracking: spec.secondaryTracking,
                color:
                    emphasizesPrimary
                    ? Color.black.opacity(0.70)
                    :
                    RendererConstants
                    .CompactInformationBar
                    .secondaryText,
                minimumScaleFactor: secondaryMinimumScaleFactor
            )
            .offset(
                y:
                    barHeight
                    * spec.secondaryYOffsetToBarHeight
            )
        }
        .frame(
            maxWidth: .infinity,
            maxHeight: .infinity,
            alignment: .center
        )
    }

    private func compactTextLine(
        _ value: String,
        fontSize: CGFloat,
        weight: Font.Weight,
        tracking: CGFloat,
        color: Color,
        minimumScaleFactor: CGFloat
    ) -> some View {
        Text(value.isEmpty ? " " : value)
            .font(
                .system(
                    size: fontSize,
                    weight: weight
                )
            )
            .kerning(tracking)
            .foregroundStyle(color)
            .lineLimit(1)
            .minimumScaleFactor(minimumScaleFactor)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func compactLogo(
        spec: CompactInformationBarSpec,
        barHeight: CGFloat
    ) -> some View {
        let logoSize =
            barHeight
            * spec.logoSizeToBarHeight

        return Group {
            switch logoMode {
            case .appleMini:
                Image(systemName: "apple.logo")
                    .font(.system(size: logoSize, weight: .semibold))
            case .customUpload:
                if let customLogoImagePath,
                   let image = UIImage(contentsOfFile: customLogoImagePath) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(
                            width:
                                logoSize
                                * spec.customLogoScale,
                            height:
                                logoSize
                                * spec.customLogoScale
                        )
                        .clipShape(Circle())
                } else {
                    Image(systemName: "photo.badge.plus")
                        .font(.system(size: logoSize * 0.78, weight: .semibold))
                }
            case .subjectAvatar:
                if let subjectAvatarLogoImagePath,
                   let image = UIImage(contentsOfFile: subjectAvatarLogoImagePath) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(
                            width:
                                logoSize
                                * spec.customLogoScale,
                            height:
                                logoSize
                                * spec.customLogoScale
                        )
                        .clipShape(Circle())
                } else {
                    Image(systemName: "person.crop.circle")
                        .font(.system(size: logoSize * 0.82, weight: .semibold))
                }
            }
        }
        .symbolRenderingMode(.hierarchical)
        .foregroundStyle(RendererConstants.CompactInformationBar.logoTint)
        .frame(width: logoSize * 1.25, height: logoSize * 1.25)
    }

    private var formattedCaptureSummaryText: String {
        let facts =
            contextText
            .split(separator: " ")
            .map(String.init)
            .prefix(RendererConstants.CaptureSummary.allowedFactCount)

        guard !facts.isEmpty else {
            return contextText
        }

        return facts.joined(separator: " ")
    }
}

#endif

#if !MEMOMARK_SHARE_EXTENSION
import SwiftUI

struct MemoryCardPreviewSurface: View {

    let presentationStyle: RecordCardPresentationStyle
    let logoMode: ConfigurationLogoMode
    let customLogoImagePath: String?
    let subjectAvatarLogoImagePath: String?
    let regionText: String
    let timeText: String
    let contextText: String
    let memoryText: String
    let filmMarkOutputText: String
    let filmMarkConfiguration: FilmMarkConfiguration
    let filmMarkPreviewMode: FilmMarkPreviewMode
    let previewOrientation: ConfigurationPreviewBackground.Orientation?

    init(
        presentationStyle: RecordCardPresentationStyle,
        logoMode: ConfigurationLogoMode,
        customLogoImagePath: String?,
        subjectAvatarLogoImagePath: String?,
        regionText: String,
        timeText: String,
        contextText: String,
        memoryText: String,
        filmMarkOutputText: String = "",
        filmMarkConfiguration: FilmMarkConfiguration = .default,
        filmMarkPreviewMode: FilmMarkPreviewMode = .contentStrip,
        previewOrientation: ConfigurationPreviewBackground.Orientation? = nil
    ) {
        self.presentationStyle = presentationStyle
        self.logoMode = logoMode
        self.customLogoImagePath = customLogoImagePath
        self.subjectAvatarLogoImagePath = subjectAvatarLogoImagePath
        self.regionText = regionText
        self.timeText = timeText
        self.contextText = contextText
        self.memoryText = memoryText
        self.filmMarkOutputText = filmMarkOutputText
        self.filmMarkConfiguration = filmMarkConfiguration
        self.filmMarkPreviewMode = filmMarkPreviewMode
        self.previewOrientation = previewOrientation
    }

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
                .aspectRatio(classicPreviewAspectRatio, contentMode: .fit)
                .overlay {
                    GeometryReader { proxy in
                        if let previewOrientation {
                            classicPhotoPreview(
                                size: proxy.size,
                                orientation: previewOrientation
                            )
                        } else {
                            compactPreviewCard(size: proxy.size)
                        }
                    }
                }
        case .minimal:
            Color.clear
                .aspectRatio(
                    minimalPreviewAspectRatio,
                    contentMode: .fit
                )
                .frame(maxWidth: .infinity)
                .overlay {
                    GeometryReader { proxy in
                        minimalPreviewCard(size: proxy.size)
                    }
                }
        case .filmMark:
            FilmMarkPreviewSurface(
                content: FilmMarkContentProjection(
                    primaryOutput: filmMarkPreviewText
                ),
                configuration: filmMarkConfiguration,
                mode: resolvedFilmMarkPreviewMode
            )
            .frame(maxWidth: .infinity)
        }
    }

    private var resolvedFilmMarkPreviewMode: FilmMarkPreviewMode {
        guard let previewOrientation else {
            return filmMarkPreviewMode
        }

        switch filmMarkPreviewMode {
        case .fullPhotoCanvas(_, let showsGuides):
            return .fullPhotoCanvas(
                orientation: previewOrientation,
                showsGuides: showsGuides
            )
        default:
            return .fullPhotoCanvas(
                orientation: previewOrientation,
                showsGuides: filmMarkPreviewMode == .geometry
            )
        }
    }

    private var filmMarkPreviewText: String {
        // An empty FM draft must remain empty. A hard-coded authored sentence
        // would make the preview look healthy while production correctly has
        // no content to render; the preview surface shows a neutral diagnostic
        // instead of inventing memory content.
        filmMarkOutputText
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func minimalPreviewCard(size: CGSize) -> some View {
        let layout = MinimalRenderer.layout(
            for: previewOrientation.map {
                Self.minimalOrientation(for: $0)
            }
                ?? .landscape
        )
        let barHeight = size.width * layout.barHeightToImageWidth

        return ZStack(alignment: .bottomTrailing) {
            minimalPreviewPhoto(
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

    private func minimalPreviewPhoto(
        width: CGFloat,
        height: CGFloat
    ) -> some View {
        let assetName = previewOrientation.map {
            ConfigurationPreviewBackground.minimal.assetName(forOrientation: $0)
        } ?? ConfigurationPreviewBackground.minimal.assetName(
            for: ConfigurationPreviewBackground.surface(forPreviewWidth: width)
        )

        return Image(assetName)
        .resizable()
        .scaledToFill()
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
               let image = PlatformImage.loadMemoMarkImage(
                contentsOfFile: customLogoImagePath
               ) {
                image.swiftUIImage
                    .resizable()
                    .scaledToFit()
                    .frame(width: size, height: size)
                    .clipShape(Circle())
            } else {
                Image(systemName: "apple.logo")
                    .font(.system(size: size * 0.82, weight: .semibold))
            }
        case .subjectAvatar:
            if let subjectAvatarLogoImagePath,
               let image = PlatformImage.loadMemoMarkImage(
                contentsOfFile: subjectAvatarLogoImagePath
               ) {
                image.swiftUIImage
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
        let orientation: CompactInformationBarOrientation
        switch previewOrientation {
        case .landscape?:
            orientation = .landscape
        case .portrait?:
            orientation = .portrait
        case nil:
            orientation = .landscape
        }
        return RendererConstants.CompactInformationBar.spec(for: orientation)
    }

    private var compactPreviewAspectRatio: CGFloat {
        1 / compactSpec.barHeightToWidth
    }

    private var classicPreviewAspectRatio: CGFloat {
        guard let previewOrientation else {
            return compactPreviewAspectRatio
        }
        return ConfigurationPreviewViewportSpec.canvasAspectRatio(
            for: .classicWhite,
            orientation: previewOrientation
        )
    }

    private var minimalPreviewAspectRatio: CGFloat {
        guard let previewOrientation else {
            return 1
                / MinimalCardLayoutSpecification.compactPreview
                    .imageSliceHeightToWidth
        }
        return ConfigurationPreviewBackground.aspectRatio(for: previewOrientation)
    }

    private static func minimalOrientation(
        for orientation: ConfigurationPreviewBackground.Orientation
    ) -> MinimalRenderer.Orientation {
        switch orientation {
        case .landscape:
            .landscape
        case .portrait:
            .portrait
        }
    }

    private func classicPhotoPreview(
        size: CGSize,
        orientation: ConfigurationPreviewBackground.Orientation
    ) -> some View {
        let imageName = ConfigurationPreviewBackground.classicWhite
            .assetName(forOrientation: orientation)
        let barHeight = size.width * compactSpec.barHeightToWidth
        let photoHeight = max(0, size.height - barHeight)

        return VStack(spacing: 0) {
            Image(imageName)
                .resizable()
                .scaledToFit()
                .frame(width: size.width, height: photoHeight)
                .accessibilityHidden(true)

            compactInformationBar(
                width: size.width,
                height: barHeight
            )
            .frame(width: size.width, height: barHeight)
        }
        .frame(width: size.width, height: size.height)
        .clipped()
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
        let portraitGeometry = resolvedPortraitGeometry(
            width: width,
            height: height,
            spec: spec
        )
        let leftWidth = portraitGeometry?.leftTextWidth
            ?? compactPreviewLeftTextWidth(spec: spec)
        let rightWidth = portraitGeometry?.rightTextWidth ?? spec.rightWidth

        return ZStack(alignment: .topLeading) {
            RendererConstants.CompactInformationBar.background

            compactTextPair(
                primary: regionText,
                secondary: timeText,
                spec: spec,
                barHeight: height,
                textColumnWidth: leftWidth,
                emphasizesPrimary: false,
                primaryMinimumScaleFactor: portraitGeometry == nil
                    ? 0.94
                    : ClassicWhiteRenderer.primaryMinimumScaleFactor,
                secondaryMinimumScaleFactor: portraitGeometry == nil
                    ? 0.90
                    : ClassicWhiteRenderer.secondaryMinimumScaleFactor
            )
            .frame(
                width: width * leftWidth,
                height: height * 0.62,
                alignment: .leading
            )
            .position(
                x:
                    width * (portraitGeometry?.leftTextOriginX ?? spec.leftX)
                    + width * leftWidth / 2,
                y: height * spec.contentCenterY
            )

            if let portraitGeometry {
                compactLogo(
                    spec: spec,
                    barHeight: height
                )
                .frame(
                    width: width
                        * ClassicWhitePortraitLayoutSpecification.logoSlotWidth,
                    height: height,
                    alignment: .trailing
                )
                .position(
                    x: width * (
                        portraitGeometry.logoSlotOriginX
                            + ClassicWhitePortraitLayoutSpecification.logoSlotWidth / 2
                    ),
                    y: height * spec.contentCenterY
                )
            } else {
                compactLogo(
                    spec: spec,
                    barHeight: height
                )
                .position(
                    x: width * spec.logoCenterX,
                    y: height * spec.contentCenterY
                )
            }

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
                    x: width * (portraitGeometry?.dividerCenterX ?? spec.dividerCenterX),
                    y:
                        height * spec.dividerTopY
                        + height * spec.dividerHeight / 2
                )

            compactTextPair(
                primary: formattedCaptureSummaryText,
                secondary: memoryText,
                spec: spec,
                barHeight: height,
                textColumnWidth: rightWidth,
                alignment: spec.rightTextAlignment,
                primaryFontToBarHeight:
                    spec.rightPrimaryFontToBarHeight,
                primaryMinimumScaleFactor: portraitGeometry == nil
                    ? 0.72
                    : ClassicWhiteRenderer.primaryMinimumScaleFactor,
                secondaryMinimumScaleFactor: portraitGeometry == nil
                    ? 0.82
                    : ClassicWhiteRenderer.secondaryMinimumScaleFactor
            )
            .frame(
                width: width * rightWidth,
                height: height * 0.62,
                alignment: spec.rightTextAlignment.alignment
            )
            .position(
                x:
                    width * (portraitGeometry?.rightTextOriginX ?? spec.rightX)
                    + width * rightWidth / 2,
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

    private func resolvedPortraitGeometry(
        width: CGFloat,
        height: CGFloat,
        spec: CompactInformationBarSpec
    ) -> ClassicWhitePortraitResolvedLayout? {
        guard previewOrientation == .portrait else { return nil }
        func normalizedWidth(
            _ text: String,
            fontSize: CGFloat,
            tracking: CGFloat,
            isRegular: Bool = false
        ) -> CGFloat {
            ClassicWhitePortraitLayoutSpecification.measureTextWidth(
                text,
                fontSize: fontSize,
                tracking: tracking,
                weight: isRegular ? [] : .traitBold
            ) / max(width, 1)
        }

        return ClassicWhitePortraitLayoutSpecification.resolve(
            leftRowWidths: [
                normalizedWidth(
                    regionText,
                    fontSize: height * spec.primaryFontToBarHeight,
                    tracking: spec.primaryTracking
                ),
                normalizedWidth(
                    timeText,
                    fontSize: height * spec.secondaryFontToBarHeight,
                    tracking: spec.secondaryTracking,
                    isRegular: true
                )
            ],
            rightRowWidths: [
                normalizedWidth(
                    formattedCaptureSummaryText,
                    fontSize: height * spec.rightPrimaryFontToBarHeight,
                    tracking: spec.primaryTracking
                ),
                normalizedWidth(
                    memoryText,
                    fontSize: height * spec.secondaryFontToBarHeight,
                    tracking: spec.secondaryTracking,
                    isRegular: true
                )
            ],
            dividerWidthRatio: min(
                max(height * spec.dividerWidthToBarHeight, 2),
                8
            ) / max(width, 1)
        )
    }

    private func compactTextPair(
        primary: String,
        secondary: String,
        spec: CompactInformationBarSpec,
        barHeight: CGFloat,
        textColumnWidth: CGFloat,
        alignment: CompactInformationBarTextAlignment = .leading,
        emphasizesPrimary: Bool = false,
        primaryFontToBarHeight: CGFloat? = nil,
        primaryMinimumScaleFactor: CGFloat = 0.84,
        secondaryMinimumScaleFactor: CGFloat = 0.84
    ) -> some View {
        VStack(
            alignment: alignment.horizontalAlignment,
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
                minimumScaleFactor: primaryMinimumScaleFactor,
                alignment: alignment
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
                minimumScaleFactor: secondaryMinimumScaleFactor,
                alignment: alignment
            )
            .offset(
                y:
                    barHeight
                    * spec.secondaryYOffsetToBarHeight
            )
        }
        .frame(
            width: barHeight / spec.barHeightToWidth * textColumnWidth,
            alignment: .center
        )
        .frame(maxHeight: .infinity, alignment: .center)
    }

    private func compactTextLine(
        _ value: String,
        fontSize: CGFloat,
        weight: Font.Weight,
        tracking: CGFloat,
        color: Color,
        minimumScaleFactor: CGFloat,
        alignment: CompactInformationBarTextAlignment = .leading
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
            .multilineTextAlignment(alignment.textAlignment)
            .lineLimit(1)
            .minimumScaleFactor(minimumScaleFactor)
            .frame(maxWidth: .infinity, alignment: alignment.alignment)
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
                   let image = PlatformImage.loadMemoMarkImage(
                    contentsOfFile: customLogoImagePath
                   ) {
                    image.swiftUIImage
                        .resizable()
                        .scaledToFit()
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
                   let image = PlatformImage.loadMemoMarkImage(
                    contentsOfFile: subjectAvatarLogoImagePath
                   ) {
                    image.swiftUIImage
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

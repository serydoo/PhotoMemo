#if os(iOS) && !PHOTOMEMO_SHARE_EXTENSION
import SwiftUI
import UIKit

struct IOSMacStyleMemoryCardPreview: View {

    @ObservedObject
    var session: ConfigurationSession

    let onPreviewInteraction: () -> Void

    var body: some View {
        Color.clear
        .aspectRatio(compactPreviewAspectRatio, contentMode: .fit)
        .overlay {
            GeometryReader { proxy in
                compactPreviewCard(size: proxy.size)
            }
        }
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
                primaryRegion:
                    CardRegion.region(for: .leftPrimary),
                secondaryRegion:
                    CardRegion.region(for: .leftSecondary),
                primary:
                    session.previewText(
                        for: CardRegion.region(for: .leftPrimary)
                    ),
                secondary:
                    session.previewText(
                        for: CardRegion.region(for: .leftSecondary)
                    ),
                spec: spec,
                barHeight: height
            )
            .frame(
                width: width * spec.leftWidth,
                height: height * 0.62,
                alignment: .leading
            )
            .position(
                x:
                    width * spec.leftX
                    + width * spec.leftWidth / 2,
                y: height * spec.contentCenterY
            )

            compactLogoRegion(
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
                primaryRegion:
                    CardRegion.region(for: .rightPrimary),
                secondaryRegion:
                    CardRegion.region(for: .rightSecondary),
                primary: formattedCaptureSummaryText,
                secondary:
                    session.previewText(
                        for: CardRegion.region(for: .rightSecondary)
                    ),
                spec: spec,
                barHeight: height
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

    private func compactTextPair(
        primaryRegion: CardRegion,
        secondaryRegion: CardRegion,
        primary: String,
        secondary: String,
        spec: CompactInformationBarSpec,
        barHeight: CGFloat
    ) -> some View {
        VStack(
            alignment: .leading,
            spacing: barHeight * spec.groupSpacingToBarHeight
        ) {
            compactTextLine(
                primaryRegion,
                value: primary,
                fontSize:
                    barHeight
                    * primaryFontToBarHeight(
                        for: primaryRegion,
                        spec: spec
                    ),
                weight: .semibold,
                tracking: spec.primaryTracking,
                color:
                    RendererConstants
                    .CompactInformationBar
                    .primaryText
            )
            .offset(
                y:
                    barHeight
                    * spec.primaryYOffsetToBarHeight
            )

            compactTextLine(
                secondaryRegion,
                value: secondary,
                fontSize:
                    barHeight
                    * spec.secondaryFontToBarHeight,
                weight: .regular,
                tracking: spec.secondaryTracking,
                color:
                    RendererConstants
                    .CompactInformationBar
                    .secondaryText
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
        _ region: CardRegion,
        value: String,
        fontSize: CGFloat,
        weight: Font.Weight,
        tracking: CGFloat,
        color: Color
    ) -> some View {
        Button {
            applyPreviewSelectionUpdate(
                ConfigurationCenterSelectionCoordinator
                    .focusPreviewRegion(region)
            )
        } label: {
            Text(value.isEmpty ? " " : value)
                .font(
                    .system(
                        size: fontSize,
                        weight: weight
                    )
                )
                .kerning(tracking)
                .foregroundStyle(
                    region == session.state.selectedRegion
                    ? Color.accentColor
                    : color
                )
                .lineLimit(1)
                .minimumScaleFactor(0.72)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .buttonStyle(.plain)
    }

    private func primaryFontToBarHeight(
        for region: CardRegion,
        spec: CompactInformationBarSpec
    ) -> CGFloat {
        region == CardRegion.region(for: .rightPrimary)
            ? spec.rightPrimaryFontToBarHeight
            : spec.primaryFontToBarHeight
    }

    private func compactLogoRegion(
        spec: CompactInformationBarSpec,
        barHeight: CGFloat
    ) -> some View {
        let logoSize =
            barHeight
            * spec.logoSizeToBarHeight

        return Button {
            applyPreviewSelectionUpdate(
                ConfigurationCenterSelectionCoordinator
                    .focusPreviewRegion(.badge)
            )
        } label: {
            Image(systemName: selectedBadgeName)
                .font(.system(size: logoSize, weight: .semibold))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(
                    session.state.selectedRegion == .badge
                    ? Color.accentColor
                    : RendererConstants.CompactInformationBar.logoTint
                )
                .frame(width: logoSize * 1.25, height: logoSize * 1.25)
        }
        .buttonStyle(.plain)
    }

    private var formattedCaptureSummaryText: String {
        ConfigurationCenterCompactPreviewPresenter
            .formattedCaptureSummaryText(
                from:
                    session.previewText(
                        for: CardRegion.region(for: .rightPrimary)
                    ),
                allowedFactCount:
                    RendererConstants
                    .CaptureSummary
                    .allowedFactCount
            )
    }

    private var selectedBadgeName: String {
        ConfigurationCenterCompactPreviewPresenter
            .selectedBadgeName(
                subject:
                    session.state.selectedSubject
            )
    }

    private func applyPreviewSelectionUpdate(
        _ update:
            ConfigurationCenterSelectionUpdate
    ) {
        onPreviewInteraction()

        ConfigurationCenterSelectionApplier
            .applyPreviewFocus(
                update,
                session: session
            )
    }
}

struct IOSDetailPanel<Content: View>: View {

    let title: String
    let systemImage: String
    let subtitle: String?
    @ViewBuilder var content: Content

    init(
        title: String,
        systemImage: String,
        subtitle: String? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.systemImage = systemImage
        self.subtitle = subtitle
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 9) {
                Image(systemName: systemImage)
                    .font(.caption.weight(.semibold))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(.secondary)
                    .frame(width: 18)

                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(Color.primary)

                    if let subtitle {
                        Text(subtitle)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                Spacer(minLength: 0)
            }

            content
        }
        .padding(14)
        .background(Color.white.opacity(0.82))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(ConfigurationUI.faintHairline)
        )
    }
}

struct IOSRegionComposer: View {

    let region: CardRegion
    let configurationOptions: [IOSRegionConfigurationOption]
    @Binding var selectedConfigurationID: String
    @Binding var configurationName: String
    @Binding var isRenamingConfiguration: Bool
    let isSaved: Bool
    @Binding var text: String
    @Binding var continuationText: String
    @Binding var modules: [IOSInsertedModule]
    let showsMemorySystemModules: Bool
    let onSaveConfiguration: () -> Void
    let onDeleteModule: (IOSInsertedModule) -> Void

    @FocusState
    private var isFocused: Bool

    private var projection:
        ConfigurationCenterRegionComposerProjection {
        ConfigurationCenterRegionComposerPresenter
            .projection(
                for: region,
                selectedConfigurationID:
                    selectedConfigurationID,
                configurationName:
                    configurationName,
                configurationOptions:
                    configurationOptions,
                isSaved: isSaved
            )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            configurationControls

            if isRenamingConfiguration {
                TextField(
                    "配置名称",
                    text: $configurationName
                )
                .textFieldStyle(.plain)
                .font(.caption)
                .configurationFieldChrome(isActive: true)
            }

            compositionField

            if showsMemorySystemModules {
                memorySystemModuleStrip
            }
        }
        .padding(10)
        .background(Color.white.opacity(0.84))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(ConfigurationUI.faintHairline)
        )
        .onTapGesture {
            isFocused = false
        }
    }

    private var configurationControls: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .center, spacing: 8) {
                Menu {
                    ForEach(configurationOptions) { option in
                        Button {
                            selectedConfigurationID = option.id
                        } label: {
                            HStack {
                                Text(option.title)

                                if option.id == selectedConfigurationID {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    HStack(spacing: 6) {
                        Text(
                            projection
                                .selectedConfigurationTitle
                        )
                            .font(.caption.weight(.semibold))
                            .lineLimit(1)
                            .minimumScaleFactor(0.76)

                        Spacer(minLength: 0)

                        Image(systemName: "chevron.up.chevron.down")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(.secondary)
                    }
                    .foregroundStyle(Color.accentColor)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.accentColor.opacity(0.085))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.accentColor.opacity(0.16))
                    )
                }
                .frame(maxWidth: 210, alignment: .leading)

                Button {
                    isRenamingConfiguration.toggle()
                } label: {
                    Image(systemName: "pencil")
                        .font(.caption.weight(.semibold))
                        .frame(width: 22, height: 22)
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)

                Spacer(minLength: 0)

                HStack(spacing: 5) {
                    Image(
                        systemName:
                            projection
                            .statusSymbolName
                    )
                    .font(.caption2.weight(.semibold))

                    Text(
                        projection
                            .statusTitle
                    )
                        .font(.caption2.weight(.semibold))
                        .lineLimit(1)
                }
                .foregroundStyle(
                    projection
                    .usesSavedAccentStyle
                    ? Color.accentColor
                    : Color.secondary
                )
            }

            HStack(spacing: 8) {
                Text("修改后保存为当前区域配置。")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)

                Spacer(minLength: 0)

                Button {
                    onSaveConfiguration()
                } label: {
                    Label(
                        isSaved ? "已保存" : "保存配置",
                        systemImage:
                            isSaved
                            ? "checkmark.circle.fill"
                            : "checkmark.circle"
                    )
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
        }
        .font(.caption.weight(.semibold))
    }

    private var compositionField: some View {
        HStack(alignment: .top, spacing: 5) {
            TextField(
                projection.textPlaceholder,
                text: $text,
                axis: .vertical
            )
            .focused($isFocused)
            .textFieldStyle(.plain)
            .font(.subheadline)
            .lineLimit(1...3)
            .frame(minWidth: 108, maxWidth: .infinity, alignment: .leading)
            .layoutPriority(modules.isEmpty ? 1 : 0.8)

            if !modules.isEmpty {
                inlineModuleScroller
                    .frame(minWidth: 118, maxWidth: .infinity, alignment: .leading)
                    .layoutPriority(1.2)

                TextField(
                    projection
                        .continuationPlaceholder,
                    text: $continuationText,
                    axis: .vertical
                )
                .focused($isFocused)
                .textFieldStyle(.plain)
                .font(.subheadline)
                .lineLimit(1...3)
                .frame(minWidth: 82, maxWidth: .infinity, alignment: .leading)
                .layoutPriority(0.9)
            }
        }
        .padding(10)
        .configurationFieldChrome(isActive: isFocused)
    }

    private var inlineModuleScroller: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 3) {
                ForEach(modules) { module in
                    HStack(spacing: 4) {
                        Image(systemName: module.systemImage)
                            .font(.caption2.weight(.semibold))

                        Text(module.title)
                            .font(.caption2.weight(.semibold))
                            .lineLimit(1)

                        Button {
                            onDeleteModule(module)
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.caption2.weight(.semibold))
                        }
                        .buttonStyle(.plain)
                    }
                    .foregroundStyle(Color.accentColor)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 5)
                    .background(
                        RoundedRectangle(cornerRadius: 7)
                            .fill(Color.accentColor.opacity(0.10))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 7)
                            .stroke(Color.accentColor.opacity(0.18))
                    )
                }
            }
            .padding(.vertical, 1)
        }
    }

    private var memorySystemModuleStrip: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("系统模块")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)

            HStack(spacing: 6) {
                systemModuleChip(title: "对象昵称", value: "Subject")
                systemModuleChip(title: "智能结果", value: "Smart")
                systemModuleChip(title: "时间锚点", value: "Anchor")
            }
        }
    }

    private func systemModuleChip(
        title: String,
        value: String
    ) -> some View {
        Text(title)
            .font(.caption2.weight(.semibold))
            .foregroundStyle(Color.secondary)
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(
                RoundedRectangle(cornerRadius: 7)
                    .fill(Color.secondary.opacity(0.08))
            )
    }
}
#endif

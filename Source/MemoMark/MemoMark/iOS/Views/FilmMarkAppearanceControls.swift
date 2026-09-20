#if !MEMOMARK_SHARE_EXTENSION
import SwiftUI

struct FilmMarkAppearanceControls: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Binding var configuration: FilmMarkConfiguration

    let includesSubstrate: Bool
    let includesFont: Bool
    let includesFontSize: Bool
    let includesColor: Bool
    let includesCustomColor: Bool
    let horizontalInset: CGFloat
    let onChange: () -> Void

    private let palette: [(key: String, color: FilmMarkRGBAColor, fallback: String)] = [
        ("filmMark.configuration.color.amber", .amber, "琥珀"),
        ("filmMark.configuration.color.white", .white, "白色"),
        ("filmMark.configuration.color.cyan", FilmMarkRGBAColor(red: 0.36, green: 0.88, blue: 0.96), "青色"),
        ("filmMark.configuration.color.green", FilmMarkRGBAColor(red: 0.52, green: 0.88, blue: 0.45), "绿色"),
        ("filmMark.configuration.color.pink", FilmMarkRGBAColor(red: 1.0, green: 0.42, blue: 0.62), "粉色"),
        ("filmMark.configuration.color.red", FilmMarkRGBAColor(red: 1.0, green: 0.28, blue: 0.22), "红色"),
        ("filmMark.configuration.color.purple", FilmMarkRGBAColor(red: 0.70, green: 0.52, blue: 1.0), "紫色"),
        ("filmMark.configuration.color.black", FilmMarkRGBAColor(red: 0.05, green: 0.05, blue: 0.06), "黑色")
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if includesSubstrate { substrateRow }
            if includesFont {
                if includesSubstrate { controlsDivider }
                fontChoiceRow
            }
            if includesFontSize {
                if includesSubstrate || includesFont { controlsDivider }
                fontSizeChoiceRow
            }
            if includesColor {
                if includesSubstrate || includesFont || includesFontSize { controlsDivider }
                colorPalette
                if includesCustomColor { customColorRow }
            }
        }
    }

    private var controlsDivider: some View { HorizontalDivider(horizontalInset: horizontalInset) }

    private var fontChoiceRow: some View {
        configurationChoiceRow(title: "filmMark.configuration.font.title", subtitle: "filmMark.configuration.font.help") {
            Text(configuration.appearance.fontID.displayTitle)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.tint)
                .frame(minHeight: 32, alignment: .leading)
                .accessibilityLabel(filmMarkLocalized("filmMark.configuration.font.accessibility", fallback: "胶片标记字体"))
                .accessibilityValue(configuration.appearance.fontID.displayTitle)
        }
    }

    private var fontSizeChoiceRow: some View {
        configurationChoiceRow(title: "filmMark.configuration.size.title", subtitle: "filmMark.configuration.size.help") {
            FilmMarkFontSizeSlider(
                fontSize: Binding(
                    get: { configuration.appearance.fontSize },
                    set: { size in update { $0.appearance.fontSize = size } }
                )
            )
        }
    }

    private var substrateRow: some View {
        configurationChoiceRow(title: "filmMark.configuration.substrate.title", subtitle: "filmMark.configuration.substrate.help") {
            Group {
                if dynamicTypeSize.isAccessibilitySize { substratePicker.pickerStyle(.menu) }
                else { substratePicker.pickerStyle(.segmented) }
            }
            .tint(.accentColor)
            .accessibilityLabel(filmMarkLocalized("filmMark.configuration.substrate.accessibility", fallback: "胶片标记底色"))
            .accessibilityValue(configuration.appearance.substrate.displayTitle)
        }
    }

    private var substratePicker: some View {
        Picker(
            filmMarkLocalized("filmMark.configuration.substrate.accessibility", fallback: "胶片标记底色"),
            selection: Binding(
                get: { configuration.appearance.substrate },
                set: { substrate in update { $0.appearance.substrate = substrate } }
            )
        ) {
            ForEach(FilmMarkSubstrate.userSelectableCases, id: \.self) { substrate in
                Text(substrate.displayTitle).tag(substrate)
            }
        }
    }

    private var colorPalette: some View {
        VStack(alignment: .leading, spacing: 8) {
            filmMarkSectionHeader(title: "filmMark.configuration.color.title", subtitle: "filmMark.configuration.color.help")
            ViewThatFits(in: .horizontal) {
                HStack(spacing: 0) { paletteButtons }.fixedSize(horizontal: true, vertical: false)
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 0), count: 4), spacing: 4) {
                    paletteButtons
                }
            }
            .frame(maxWidth: .infinity, alignment: .center)
        }
        .padding(.horizontal, horizontalInset)
        .padding(.vertical, 8)
    }

    private var paletteButtons: some View {
        ForEach(Array(palette.enumerated()), id: \.offset) { _, item in
            Button { update { $0.appearance.color = item.color } } label: {
                ZStack {
                    Circle()
                        .fill(Color(red: item.color.red, green: item.color.green, blue: item.color.blue))
                        .frame(width: 28, height: 28)
                        .overlay { Circle().stroke(Color.primary.opacity(0.18), lineWidth: 1) }
                    if configuration.appearance.color == item.color {
                        Circle().strokeBorder(Color.primary, lineWidth: 2).frame(width: 38, height: 38)
                    }
                }
                .frame(width: ConfigurationUI.minimumInteractiveHeight, height: ConfigurationUI.minimumInteractiveHeight)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(
                filmMarkLocalized("filmMark.configuration.color.accessibility_prefix", fallback: "胶片标记颜色")
                + filmMarkLocalized(item.key, fallback: item.fallback)
            )
            .accessibilityAddTraits(configuration.appearance.color == item.color ? .isSelected : [])
        }
    }

    private var customColorRow: some View {
        HStack(spacing: 12) {
            Spacer(minLength: 0)
            Text(filmMarkLocalized("filmMark.configuration.custom_color.prompt", fallback: "上面没有喜欢的？自己调一调"))
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            ColorPicker(
                filmMarkLocalized("filmMark.configuration.custom_color.label", fallback: "胶片标记自定义颜色"),
                selection: customColorBinding,
                supportsOpacity: true
            )
            .labelsHidden()
            .frame(minWidth: ConfigurationUI.minimumInteractiveHeight, minHeight: ConfigurationUI.minimumInteractiveHeight)
            .accessibilityLabel(filmMarkLocalized("filmMark.configuration.custom_color.label", fallback: "胶片标记自定义颜色"))
            .accessibilityHint(filmMarkLocalized("filmMark.configuration.custom_color.hint", fallback: "可以在预设颜色之外选择任意颜色，并保留透明度"))
            Spacer(minLength: 0)
        }
        .padding(.horizontal, horizontalInset)
        .padding(.vertical, 4)
    }

    private func filmMarkSectionHeader(title: String, subtitle: String) -> some View {
        ConfigurationFieldHeading(title: title, subtitle: subtitle)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func configurationChoiceRow<Trailing: View>(
        title: String,
        subtitle: String,
        @ViewBuilder trailing: () -> Trailing
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            filmMarkSectionHeader(title: title, subtitle: subtitle)
            trailing()
        }
        .padding(.horizontal, horizontalInset)
        .padding(.vertical, 8)
    }

    private var customColorBinding: Binding<Color> {
        Binding(
            get: {
                Color(red: configuration.appearance.color.red, green: configuration.appearance.color.green, blue: configuration.appearance.color.blue, opacity: configuration.appearance.color.alpha)
            },
            set: { color in
                guard
                    let cgColor = color.cgColor,
                    let sRGB = CGColorSpace(name: CGColorSpace.sRGB),
                    let converted = cgColor.converted(to: sRGB, intent: .defaultIntent, options: nil),
                    let components = converted.components,
                    components.count >= 3
                else { return }

                update {
                    $0.appearance.color = FilmMarkRGBAColor(
                        red: Double(components[0]),
                        green: Double(components[1]),
                        blue: Double(components[2]),
                        alpha: Double(components.count >= 4 ? components[3] : 1)
                    )
                }
            }
        )
    }

    private func update(_ mutation: (inout FilmMarkConfiguration) -> Void) {
        var next = configuration
        mutation(&next)
        configuration = next
        onChange()
    }
}

/// A native slider with FilmMark's existing capsule footprint. The midpoint
/// represents the pre-existing prominent default, not an arbitrary average.
private struct FilmMarkFontSizeSlider: View {

    @Binding var fontSize: FilmMarkFontSize

    private var sliderPosition: Binding<Double> {
        Binding(
            get: { Double(FilmMarkFontSize.sliderPosition(for: fontSize)) },
            set: { position in
                fontSize = FilmMarkFontSize.fontSize(
                    forSliderPosition: CGFloat(position)
                )
            }
        )
    }

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "textformat.size.smaller")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.secondary)
                .frame(width: 20)

            Slider(value: sliderPosition, in: 0...1)
                .tint(.accentColor)
                .accessibilityLabel(
                    filmMarkLocalized(
                        "filmMark.configuration.size.accessibility",
                        fallback: "胶片标记字号"
                    )
                )
                .accessibilityValue(fontSize.displayTitle)
                .accessibilityHint(
                    filmMarkLocalized(
                        "filmMark.configuration.size.hint",
                        fallback: "向左缩小，向右放大；中间为默认大小。"
                    )
                )

            Image(systemName: "textformat.size.larger")
                .font(.body.weight(.semibold))
                .foregroundStyle(.primary)
                .frame(width: 20)
        }
        .padding(.horizontal, 12)
        .frame(minHeight: ConfigurationUI.minimumInteractiveHeight)
        .background {
            Capsule(style: .continuous)
                .fill(Color.primary.opacity(0.08))
        }
    }
}
#endif

#if os(iOS) && !MEMOMARK_SHARE_EXTENSION
import SwiftUI

struct SettingsExpressionGuide: View {

    let language: MemoMarkLanguage
    let onOpenTimeExpression: () -> Void

    @State
    private var expandedAnchorTypes: Set<String> = [
        AnchorType.birthday.rawValue
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            guideHeader
            compositionOverview

            HorizontalDivider()

            stylesHeader

            VStack(spacing: 0) {
                ForEach(AnchorType.allCases, id: \.rawValue) { anchorType in
                    anchorTypeSection(anchorType)

                    if anchorType.rawValue != AnchorType.allCases.last?.rawValue {
                        HorizontalDivider()
                    }
                }
            }
            .background(
                RoundedRectangle(
                    cornerRadius: 12,
                    style: .continuous
                )
                .fill(ConfigurationUI.controlBackground.opacity(0.72))
            )
            .overlay(
                RoundedRectangle(
                    cornerRadius: 12,
                    style: .continuous
                )
                .stroke(ConfigurationUI.faintHairline)
            )

            Text(
                localized(
                    "settings.expression.guide.original_note",
                    fallback: "时间结果取决于照片的拍摄时间；原图始终不变。"
                )
            )
                .font(.caption2)
                .foregroundStyle(.tertiary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var guideHeader: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(
                localized(
                    "settings.expression.guide.header",
                    fallback: "照片的拍摄时间，遇见你选定的重要日子"
                )
            )
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)

            Text(
                localized(
                    "settings.expression.guide.detail",
                    fallback: "记忆对象是谁、你想用怎样的语气，以及照片距离这个日子有多久，共同组成照片上的一句话。"
                )
            )
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var compositionOverview: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(
                localized(
                    "settings.expression.guide.composition_title",
                    fallback: "一句话，来自三个决定"
                )
            )
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.primary)

            compositionSteps

            Text(
                localized(
                    "settings.expression.guide.composition_note",
                    fallback: "记忆对象提供主角称呼；表达方式决定语气；时间结果来自照片拍摄时间与时间锚点日期的差值。"
                )
            )
                .font(.caption2)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            configurationLink
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(ConfigurationUI.controlBackground.opacity(0.5))
        )
    }

    private var compositionSteps: some View {
        VStack(alignment: .leading, spacing: 0) {
            compositionStep(
                number: "1",
                title: localized(
                    "settings.expression.guide.subject",
                    fallback: "记忆对象"
                ),
                detail: localized(
                    "settings.expression.guide.subject_detail",
                    fallback: "主角的称呼，可以是宝宝、儿子，或你自定义的名字。"
                ),
                role: .subject
            )

            compositionConnector

            compositionStep(
                number: "2",
                title: localized(
                    "settings.expression.guide.expression",
                    fallback: "表达方式"
                ),
                detail: localized(
                    "settings.expression.guide.expression_detail",
                    fallback: "语气与说法，例如自然、仪式感、成长、温馨或极简。"
                ),
                role: .smartOutput
            )

            compositionConnector

            compositionStep(
                number: "3",
                title: localized(
                    "settings.expression.guide.time_result",
                    fallback: "时间结果"
                ),
                detail: localized(
                    "settings.expression.guide.time_result_detail",
                    fallback: "照片拍摄时间与时间锚点日期的差值。"
                ),
                role: .anchorResult
            )
        }
    }

    private func compositionStep(
        number: String,
        title: String,
        detail: String,
        role: FormulaRole
    ) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Text(number)
                .font(.caption.weight(.bold))
                .foregroundStyle(color(for: role))
                .frame(width: 24, height: 24)
                .background(
                    Circle()
                        .fill(color(for: role).opacity(0.12))
                )
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.primary)

                Text(detail)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var compositionConnector: some View {
        Rectangle()
            .fill(ConfigurationUI.faintHairline)
            .frame(width: 1, height: 10)
            .padding(.leading, 11.5)
            .accessibilityHidden(true)
    }

    private var configurationLink: some View {
        Button(action: onOpenTimeExpression) {
            HStack(alignment: .center, spacing: 10) {
                Image(systemName: "slider.horizontal.3")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.accentColor)
                    .frame(width: 24, height: 24)

                VStack(alignment: .leading, spacing: 2) {
                    Text(
                        localized(
                            "settings.expression.guide.configuration.title",
                            fallback: "在配置中心自定义时间表达"
                        )
                    )
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.primary)

                    Text(configurationSummary)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 8)

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 9)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color.accentColor.opacity(0.08))
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(
            localized(
                "settings.expression.guide.configuration.title",
                fallback: "在配置中心自定义时间表达"
            )
        )
        .accessibilityHint(
            localized(
                "settings.expression.guide.configuration.detail",
                fallback: "选择当前时间锚点的表达方式，并在卡片上查看示例。"
            )
        )
    }

    private var configurationSummary: String {
        "\(localized("configuration.expression.title", fallback: "时间怎样表达")) · \(localized("configuration.expression.subtitle", fallback: "为年龄、纪念日或倒计时选择合适的语气。"))"
    }

    private var stylesHeader: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(
                localized(
                    "settings.expression.guide.styles_detail",
                    fallback: "先按时间锚点查看示例，再选择更适合这段回忆的说法。"
                )
            )
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func anchorTypeSection(
        _ anchorType: AnchorType
    ) -> some View {
        DisclosureGroup(
            isExpanded: Binding(
                get: {
                    expandedAnchorTypes.contains(anchorType.rawValue)
                },
                set: { isExpanded in
                    if isExpanded {
                        expandedAnchorTypes.insert(anchorType.rawValue)
                    } else {
                        expandedAnchorTypes.remove(anchorType.rawValue)
                    }
                }
            )
        ) {
            VStack(spacing: 0) {
                let styles =
                    MemoryAnchorExpressionStyle.availableStyles(
                        for: anchorType
                    )

                ForEach(styles) { style in
                    expressionStyleRow(style)

                    if style.id != styles.last?.id {
                        HorizontalDivider(horizontalInset: 12)
                    }
                }
            }
            .padding(.top, 6)
        } label: {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Image(systemName: iconName(for: anchorType))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.accentColor)
                    .frame(width: 22)

                VStack(alignment: .leading, spacing: 2) {
                    Text(localizedAnchorTitle(anchorType))
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)

                    Text(localizedAnchorDetail(anchorType))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
        }
        .tint(.secondary)
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }

    private func expressionStyleRow(
        _ style: MemoryAnchorExpressionStyle
    ) -> some View {
        let formula = localizedFormula(style)

        return HStack(alignment: .center, spacing: 10) {
            Text(localizedStyleTitle(style))
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.accentColor)
                .fixedSize(horizontal: false, vertical: true)
                .frame(
                    minWidth: 64,
                    maxWidth: 86,
                    alignment: .trailing
                )

            VStack(alignment: .leading, spacing: 8) {
                phaseRow(
                    title: localized(
                        "settings.expression.guide.phase.before",
                        fallback: "之前"
                    ),
                    formula: formula.before
                )
                phaseRow(
                    title: localized(
                        "settings.expression.guide.phase.on_anchor",
                        fallback: "当时 / 当日"
                    ),
                    formula: formula.onAnchor
                )
                phaseRow(
                    title: localized(
                        "settings.expression.guide.phase.after",
                        fallback: "之后"
                    ),
                    formula: formula.after
                )
            }
            .padding(.leading, 10)
            .overlay(alignment: .leading) {
                RoundedRectangle(cornerRadius: 1.5, style: .continuous)
                    .fill(styleMarkerColor(for: style))
                    .frame(width: 3)
                    .padding(.vertical, 2)
                    .accessibilityHidden(true)
            }
        }
        .padding(.leading, 12)
        .padding(.trailing, 2)
        .padding(.vertical, 9)
    }

    private func styleMarkerColor(
        for style: MemoryAnchorExpressionStyle
    ) -> Color {
        let rawValue = style.rawValue

        if rawValue.hasSuffix("Natural") {
            return .blue.opacity(0.85)
        }
        if rawValue.hasSuffix("Ceremonial") {
            return .purple.opacity(0.85)
        }
        if rawValue.hasSuffix("Growth") || rawValue.hasSuffix("Motivational") {
            return .green.opacity(0.85)
        }
        if rawValue.hasSuffix("Warm") {
            return .orange.opacity(0.85)
        }
        if rawValue.hasSuffix("Memory") {
            return .indigo.opacity(0.85)
        }
        if rawValue.hasSuffix("Record") {
            return .teal.opacity(0.85)
        }
        return .secondary.opacity(0.85)
    }

    private func phaseRow(
        title: String,
        formula: String
    ) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text(title)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: true, vertical: false)

            highlightedFormula(formula)
                .font(.caption)
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func highlightedFormula(
        _ source: String
    ) -> Text {
        var result = Text("")
        var remaining = source

        while let start = remaining.range(of: "[[") {
            let prefix = String(remaining[..<start.lowerBound])
            result = result + Text(prefix)
            remaining = String(remaining[start.upperBound...])

            guard let end = remaining.range(of: "]]") else {
                return result + Text(remaining)
            }

            let marker =
                remaining[..<end.lowerBound]
                .split(separator: ":", maxSplits: 1)
                .map(String.init)

            guard marker.count == 2 else {
                return result + Text(remaining)
            }

            let role = FormulaRole(rawValue: marker[0]) ?? .anchorResult
            result = result + Text(marker[1])
                .foregroundStyle(color(for: role))
                .fontWeight(.semibold)
            remaining = String(remaining[end.upperBound...])
        }

        return result + Text(remaining)
    }

    private func localized(
        _ key: String,
        fallback: String
    ) -> String {
        language.localized(key: key, fallback: fallback)
    }

    private func localizedAnchorTitle(
        _ anchorType: AnchorType
    ) -> String {
        localized(
            "settings.expression.anchor.\(anchorType.rawValue).title",
            fallback: anchorType.displayName
        )
    }

    private func localizedAnchorDetail(
        _ anchorType: AnchorType
    ) -> String {
        localized(
            "settings.expression.anchor.\(anchorType.rawValue).detail",
            fallback: anchorType.helperText
        )
    }

    private func localizedStyleTitle(
        _ style: MemoryAnchorExpressionStyle
    ) -> String {
        localized(style.displayTitle, fallback: style.displayTitle)
    }

    private func localizedFormula(
        _ style: MemoryAnchorExpressionStyle
    ) -> Formula {
        let fallback = Self.formulas[style] ?? .fallback
        let keyPrefix = "settings.expression.formula.\(style.rawValue)"
        return Formula(
            before: localized(
                "\(keyPrefix).before",
                fallback: fallback.before
            ),
            onAnchor: localized(
                "\(keyPrefix).on_anchor",
                fallback: fallback.onAnchor
            ),
            after: localized(
                "\(keyPrefix).after",
                fallback: fallback.after
            )
        )
    }

    private func iconName(
        for anchorType: AnchorType
    ) -> String {
        switch anchorType {
        case .birthday:
            return "birthday.cake.fill"
        case .relationship:
            return "heart.fill"
        case .marriage:
            return "sparkles"
        case .exam:
            return "flag.checkered"
        case .custom:
            return "calendar"
        }
    }

    private func color(
        for role: FormulaRole
    ) -> Color {
        switch role {
        case .subject:
            return .blue
        case .smartOutput:
            return .teal
        case .anchorResult:
            return .orange
        }
    }
}

private extension SettingsExpressionGuide {

    enum FormulaRole: String {
        case subject
        case smartOutput
        case anchorResult
    }

    struct Formula {
        let before: String
        let onAnchor: String
        let after: String

        static let fallback = Formula(
            before: "距离[[smartOutput:锚点名称]]还有[[anchorResult:锚点结果]]",
            onAnchor: "[[smartOutput:今天]]是[[smartOutput:锚点名称]]",
            after: "自[[smartOutput:锚点名称]]起，已有[[anchorResult:锚点结果]]"
        )
    }

    static let formulas: [MemoryAnchorExpressionStyle: Formula] = [
        .birthdayNatural: .init(
            before: "还有[[anchorResult:锚点结果]]，[[subject:主体]]就要出生了",
            onAnchor: "[[subject:主体]]今天来到这个世界啦！",
            after: "[[smartOutput:今天]][[subject:主体]][[anchorResult:锚点结果]]"
        ),
        .birthdayCeremonial: .init(
            before: "再过[[anchorResult:锚点结果]]，就是[[subject:主体]]来到世界的日子",
            onAnchor: "[[subject:主体]]今天来到这个世界啦！",
            after: "[[smartOutput:今天]]是[[subject:主体]][[anchorResult:锚点结果]]"
        ),
        .birthdayGrowth: .init(
            before: "距离第一次见面还有[[anchorResult:锚点结果]]",
            onAnchor: "[[subject:主体]]今天来到这个世界啦！",
            after: "[[subject:主体]]长到[[anchorResult:锚点结果]]了"
        ),
        .birthdayWarm: .init(
            before: "等待[[subject:主体]]到来，还有[[anchorResult:锚点结果]]",
            onAnchor: "[[subject:主体]]今天来到这个世界啦！",
            after: "陪[[subject:主体]]走到[[anchorResult:锚点结果]]"
        ),
        .birthdayMinimal: .init(
            before: "[[subject:主体]]出生倒计时：[[anchorResult:锚点结果]]",
            onAnchor: "[[subject:主体]]今天来到这个世界啦！",
            after: "[[subject:主体]] · [[anchorResult:锚点结果]]"
        ),
        .marriageNatural: .init(
            before: "结婚还有[[anchorResult:锚点结果]]",
            onAnchor: "[[smartOutput:今天]]是结婚的日子",
            after: "结婚已经[[anchorResult:锚点结果]]"
        ),
        .marriageCeremonial: .init(
            before: "再过[[anchorResult:锚点结果]]，就是结婚的日子",
            onAnchor: "[[smartOutput:今天]]是结婚的日子",
            after: "[[smartOutput:今天]]是婚后[[anchorResult:锚点结果]]"
        ),
        .marriageWarm: .init(
            before: "距离结婚还有[[anchorResult:锚点结果]]",
            onAnchor: "[[smartOutput:今天]]一起走进婚姻",
            after: "与你相伴[[anchorResult:锚点结果]]"
        ),
        .marriageMinimal: .init(
            before: "结婚倒计时：[[anchorResult:锚点结果]]",
            onAnchor: "结婚 · [[smartOutput:今天]]",
            after: "结婚 · [[anchorResult:锚点结果]]"
        ),
        .marriageMemory: .init(
            before: "距离那一天还有[[anchorResult:锚点结果]]",
            onAnchor: "从那一天开始",
            after: "从那一天起，已有[[anchorResult:锚点结果]]"
        ),
        .relationshipNatural: .init(
            before: "距离[[smartOutput:锚点名称]]还有[[anchorResult:锚点结果]]",
            onAnchor: "[[smartOutput:今天]]是[[smartOutput:锚点名称]]",
            after: "[[smartOutput:锚点名称]]已经[[anchorResult:锚点结果]]"
        ),
        .relationshipCeremonial: .init(
            before: "再过[[anchorResult:锚点结果]]，就是[[smartOutput:锚点名称]]",
            onAnchor: "[[smartOutput:今天]]是[[smartOutput:锚点名称]]",
            after: "[[smartOutput:今天]]是[[smartOutput:锚点名称]][[anchorResult:锚点结果]]"
        ),
        .relationshipMemory: .init(
            before: "距离[[smartOutput:锚点名称]]还有[[anchorResult:锚点结果]]",
            onAnchor: "从[[smartOutput:锚点名称]]开始",
            after: "自[[smartOutput:锚点名称]]起，已有[[anchorResult:锚点结果]]"
        ),
        .relationshipWarm: .init(
            before: "期待[[smartOutput:锚点名称]]，还有[[anchorResult:锚点结果]]",
            onAnchor: "[[smartOutput:今天]]记住[[smartOutput:锚点名称]]",
            after: "关于[[smartOutput:锚点名称]]的故事，已有[[anchorResult:锚点结果]]"
        ),
        .relationshipMinimal: .init(
            before: "[[smartOutput:锚点名称]]倒计时：[[anchorResult:锚点结果]]",
            onAnchor: "[[smartOutput:锚点名称]] · [[smartOutput:今天]]",
            after: "[[smartOutput:锚点名称]] · [[anchorResult:锚点结果]]"
        ),
        .examNatural: .init(
            before: "距离[[smartOutput:锚点名称]]还有[[anchorResult:锚点结果]]",
            onAnchor: "[[smartOutput:锚点名称]]就是[[smartOutput:今天]]",
            after: "[[smartOutput:锚点名称]]已经过去[[anchorResult:锚点结果]]"
        ),
        .examCeremonial: .init(
            before: "再过[[anchorResult:锚点结果]]，就是[[smartOutput:锚点名称]]",
            onAnchor: "[[smartOutput:今天]]是[[smartOutput:锚点名称]]",
            after: "从[[smartOutput:锚点名称]]那天起，已经[[anchorResult:锚点结果]]"
        ),
        .examMotivational: .init(
            before: "冲刺[[smartOutput:锚点名称]]，还剩[[anchorResult:锚点结果]]",
            onAnchor: "[[smartOutput:今天]]，迎接[[smartOutput:锚点名称]]",
            after: "[[smartOutput:锚点名称]]结束已经[[anchorResult:锚点结果]]"
        ),
        .examMinimal: .init(
            before: "[[smartOutput:锚点名称]]倒计时：[[anchorResult:锚点结果]]",
            onAnchor: "[[smartOutput:锚点名称]] · [[smartOutput:今天]]",
            after: "已过[[anchorResult:锚点结果]]"
        ),
        .examRecord: .init(
            before: "[[smartOutput:锚点名称]]还有[[anchorResult:锚点结果]]",
            onAnchor: "[[smartOutput:锚点名称]] · 当日记录",
            after: "自[[smartOutput:锚点名称]]以来，已有[[anchorResult:锚点结果]]"
        ),
        .customNatural: .init(
            before: "距离[[smartOutput:锚点名称]]还有[[anchorResult:锚点结果]]",
            onAnchor: "[[smartOutput:今天]]是[[smartOutput:锚点名称]]",
            after: "自[[smartOutput:锚点名称]]起，已有[[anchorResult:锚点结果]]"
        ),
        .customCeremonial: .init(
            before: "再过[[anchorResult:锚点结果]]，就是[[smartOutput:锚点名称]]",
            onAnchor: "[[smartOutput:今天]]是[[smartOutput:锚点名称]]",
            after: "今天是[[smartOutput:锚点名称]][[anchorResult:锚点结果]]"
        ),
        .customMemory: .init(
            before: "距离[[smartOutput:锚点名称]]还有[[anchorResult:锚点结果]]",
            onAnchor: "从[[smartOutput:锚点名称]]开始",
            after: "从[[smartOutput:锚点名称]]那天起，已有[[anchorResult:锚点结果]]"
        ),
        .customWarm: .init(
            before: "期待[[smartOutput:锚点名称]]，还有[[anchorResult:锚点结果]]",
            onAnchor: "[[smartOutput:今天]]记住[[smartOutput:锚点名称]]",
            after: "关于[[smartOutput:锚点名称]]，已经[[anchorResult:锚点结果]]"
        ),
        .customMinimal: .init(
            before: "[[smartOutput:锚点名称]]倒计时：[[anchorResult:锚点结果]]",
            onAnchor: "[[smartOutput:锚点名称]] · [[smartOutput:今天]]",
            after: "[[smartOutput:锚点名称]] · [[anchorResult:锚点结果]]"
        )
    ]
}

#endif

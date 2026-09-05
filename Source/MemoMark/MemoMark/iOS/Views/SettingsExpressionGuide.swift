#if os(iOS) && !MEMOMARK_SHARE_EXTENSION
import SwiftUI

struct SettingsExpressionGuide: View {

    let language: MemoMarkLanguage

    @State
    private var expandedAnchorTypes: Set<String> = [
        AnchorType.birthday.rawValue
    ]

    @State
    private var showsCompositionExplanation = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            guideHeader
            exampleOverview
            compositionExplanation

            HorizontalDivider()

            Text(
                localized(
                    "settings.expression.guide.introduction",
                    fallback: "继续看看不同时间锚点可以怎样表达。"
                )
            )
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

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
                    fallback: "拍摄时间不同，时间结果也会随之变化；原图始终不变。"
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
                    fallback: "同一个时间锚点，在到来前、当天和之后，会有不同说法。"
                )
            )
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)

            Text(
                localized(
                    "settings.expression.guide.detail",
                    fallback: "MemoMark 会根据照片的拍摄时间，选用与你选择的表达方式相符的说法。"
                )
            )
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var exampleOverview: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(
                localized(
                    "settings.expression.guide.example_title",
                    fallback: "例如：生日"
                )
            )
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.secondary)

            exampleRow(
                title: localized(
                    "settings.expression.guide.phase.before",
                    fallback: "之前"
                ),
                value: localized(
                    "settings.expression.guide.example_before",
                    fallback: "还有 6 天就 1 岁了"
                )
            )
            exampleRow(
                title: localized(
                    "settings.expression.guide.phase.on_anchor",
                    fallback: "当天"
                ),
                value: localized(
                    "settings.expression.guide.example_on_anchor",
                    fallback: "今天 1 岁了"
                )
            )
            exampleRow(
                title: localized(
                    "settings.expression.guide.phase.after",
                    fallback: "之后"
                ),
                value: localized(
                    "settings.expression.guide.example_after",
                    fallback: "已经 1 岁 3 天"
                )
            )
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(ConfigurationUI.controlBackground.opacity(0.72))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(ConfigurationUI.faintHairline)
        )
    }

    private func exampleRow(title: String, value: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            Text(title)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.secondary)
                .frame(width: 44, alignment: .leading)

            Text(value)
                .font(.body)
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var compositionExplanation: some View {
        DisclosureGroup(
            isExpanded: $showsCompositionExplanation
        ) {
            VStack(alignment: .leading, spacing: 10) {
                formulaOverview
                colorLegend
            }
            .padding(.top, 10)
        } label: {
            Text(
                localized(
                    "settings.expression.guide.composition_title",
                    fallback: "它是怎样组成的"
                )
            )
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.primary)
        }
        .tint(.secondary)
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(ConfigurationUI.controlBackground.opacity(0.5))
        )
    }

    private var formulaOverview: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(
                localized(
                    "settings.expression.guide.formula_title",
                    fallback: "一段记忆表达"
                )
            )
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            ViewThatFits(in: .horizontal) {
                HStack(spacing: 5) {
                    formulaToken(
                        localized(
                            "settings.expression.guide.subject",
                            fallback: "记忆对象"
                        ),
                        role: .subject
                    )
                    plusMark
                    formulaToken(
                        localized(
                            "settings.expression.guide.expression",
                            fallback: "表达内容"
                        ),
                        role: .smartOutput
                    )
                    plusMark
                    formulaToken(
                        localized(
                            "settings.expression.guide.time_result",
                            fallback: "时间结果"
                        ),
                        role: .anchorResult
                    )
                }

                VStack(alignment: .leading, spacing: 4) {
                    formulaToken(
                        localized(
                            "settings.expression.guide.subject",
                            fallback: "记忆对象"
                        ),
                        role: .subject
                    )
                    plusMark
                    formulaToken(
                        localized(
                            "settings.expression.guide.expression",
                            fallback: "表达内容"
                        ),
                        role: .smartOutput
                    )
                    plusMark
                    formulaToken(
                        localized(
                            "settings.expression.guide.time_result",
                            fallback: "时间结果"
                        ),
                        role: .anchorResult
                    )
                }
            }
        }
    }

    private var colorLegend: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 10) {
                legendItem(
                    localized(
                        "settings.expression.guide.subject",
                        fallback: "记忆对象"
                    ),
                    role: .subject
                )
                legendItem(
                    localized(
                        "settings.expression.guide.expression",
                        fallback: "表达内容"
                    ),
                    role: .smartOutput
                )
                legendItem(
                    localized(
                        "settings.expression.guide.time_result",
                        fallback: "时间结果"
                    ),
                    role: .anchorResult
                )
            }

            VStack(alignment: .leading, spacing: 5) {
                legendItem(
                    localized(
                        "settings.expression.guide.subject",
                        fallback: "记忆对象"
                    ),
                    role: .subject
                )
                legendItem(
                    localized(
                        "settings.expression.guide.expression",
                        fallback: "表达内容"
                    ),
                    role: .smartOutput
                )
                legendItem(
                    localized(
                        "settings.expression.guide.time_result",
                        fallback: "时间结果"
                    ),
                    role: .anchorResult
                )
            }
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
                        .lineLimit(2)
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

        return VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(
                    localized(
                        "settings.expression.guide.style_title",
                        fallback: "表达方式"
                    )
                )
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)

                Spacer(minLength: 8)

                Text(localizedStyleTitle(style))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.accentColor)
                    .lineLimit(1)
            }

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
        .padding(.leading, 34)
        .padding(.trailing, 2)
        .padding(.vertical, 9)
    }

    private func phaseRow(
        title: String,
        formula: String
    ) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text(title)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
                .frame(width: 62, alignment: .leading)

            highlightedFormula(formula)
                .font(.caption)
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)
                .multilineTextAlignment(.leading)
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

    private func formulaToken(
        _ title: String,
        role: FormulaRole
    ) -> some View {
        Text(title)
            .font(.caption.weight(.semibold))
            .foregroundStyle(color(for: role))
            .lineLimit(1)
            .padding(.horizontal, 7)
            .padding(.vertical, 5)
            .background(
                Capsule(style: .continuous)
                    .fill(color(for: role).opacity(0.10))
            )
            .overlay(
                Capsule(style: .continuous)
                    .stroke(color(for: role).opacity(0.18))
            )
    }

    private func legendItem(
        _ title: String,
        role: FormulaRole
    ) -> some View {
        HStack(spacing: 5) {
            Circle()
                .fill(color(for: role))
                .frame(width: 7, height: 7)

            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }

    private var plusMark: some View {
        Text("+")
            .font(.caption.weight(.semibold))
            .foregroundStyle(.tertiary)
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

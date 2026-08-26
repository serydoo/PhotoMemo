#if !MEMOMARK_SHARE_EXTENSION
import Foundation

struct V1PreviewCompositionContext: Hashable {

    let subject: MemorySubject?

    let birthdayDate: Date

    let captureDate: Date

    let locationDisplayConfiguration:
        ExpressionModuleConfiguration?

    let timeDisplayConfiguration:
        ExpressionModuleConfiguration?

    let language: MemoMarkLanguage

    init(
        subject: MemorySubject?,
        birthdayDate: Date,
        captureDate: Date = V1PreviewCompositionEngine.defaultCaptureDate,
        locationDisplayConfiguration:
            ExpressionModuleConfiguration? = nil,
        timeDisplayConfiguration:
            ExpressionModuleConfiguration? = nil,
        language: MemoMarkLanguage = .stored
    ) {
        self.subject = subject
        self.birthdayDate = birthdayDate
        self.captureDate = captureDate
        self.locationDisplayConfiguration =
            locationDisplayConfiguration
        self.timeDisplayConfiguration =
            timeDisplayConfiguration
        self.language = language
    }

    var subjectNameFallback: String {
        if let shortName = subject?.identity.shortName,
           !shortName.isEmpty {
            return shortName
        }

        return subject?.identity.displayName
        ?? "小宝"
    }

    var smartTimeCalendar: Calendar {
        var calendar =
            Calendar(identifier: .gregorian)
        calendar.timeZone =
            TimeZone(secondsFromGMT: 8 * 3600)
            ?? .current
        return calendar
    }
}

struct V1PreviewDraft: Hashable {

    var items: [V1PreviewDraftItem]

    var resolvedSingleLineText: String {
        InlineContentTextComposer.compose(
            items.map { item in
                InlineContentTextComposer.Piece(
                    kind: item.kind.inlineComposerKind,
                    value: item.displayValue
                )
            }
        )
    }

    var singleLineTemplateText: String {
        InlineContentTextComposer.compose(
            items.map { item in
                InlineContentTextComposer.Piece(
                    kind: item.kind.inlineComposerKind,
                    value: item.templateValue
                )
            }
        )
    }
}

struct V1PreviewRenderModel: Hashable {

    var templateSourceText: String

    var displayText: String
}

struct V1PreviewDraftItem:
    Identifiable,
    Hashable {

    enum Kind: Hashable {
        case text
        case token
        case separator
        case lineBreak
    }

    let id: UUID
    let sourceItemID: UUID?

    let kind: Kind

    var title: String

    var value: String

    var savedValue: String

    var systemImage: String

    nonisolated init(
        id: UUID,
        sourceItemID: UUID? = nil,
        kind: Kind,
        title: String,
        value: String,
        savedValue: String,
        systemImage: String
    ) {
        self.id = id
        self.sourceItemID = sourceItemID
        self.kind = kind
        self.title = title
        self.value = value
        self.savedValue = savedValue
        self.systemImage = systemImage
    }

    var displayValue: String {
        switch kind {
        case .text,
             .token,
             .separator:
            return value
        case .lineBreak:
            return "\n"
        }
    }

    var templateValue: String {
        switch kind {
        case .text,
             .separator:
            return value
        case .token:
            return savedValue
        case .lineBreak:
            return "\n"
        }
    }

    static func text(
        _ value: String
    ) -> V1PreviewDraftItem {

        V1PreviewDraftItem(
            id: UUID(),
            kind: .text,
            title: "文字",
            value: value,
            savedValue: value,
            systemImage: MemoMarkSymbol.expressionFormula.name
        )
    }

    static func token(
        _ title: String,
        value: String,
        templateValue: String,
        systemImage: String
    ) -> V1PreviewDraftItem {

        V1PreviewDraftItem(
            id: UUID(),
            kind: .token,
            title: title,
            value: value,
            savedValue: templateValue,
            systemImage: systemImage
        )
    }

    static func separator(
        _ value: String
    ) -> V1PreviewDraftItem {

        V1PreviewDraftItem(
            id: UUID(),
            kind: .separator,
            title: "分隔符",
            value: value,
            savedValue: value,
            systemImage: "circle.fill"
        )
    }
}

private extension V1PreviewDraftItem.Kind {

    var inlineComposerKind: InlineContentTextComposer.PieceKind {
        switch self {
        case .text:
            return .text
        case .token:
            return .token
        case .separator:
            return .separator
        case .lineBreak:
            return .lineBreak
        }
    }
}

typealias V1PreviewCompositionModule = MemoryCardModuleID

struct V1PreviewCompositionEngine {

    static let defaultCaptureDate: Date = {
        Calendar.current.date(
            from: DateComponents(
                year: 2026,
                month: 6,
                day: 1,
                hour: 12,
                minute: 0
            )
        ) ?? Date()
    }()

    private let captureTimeResolver =
        CaptureTimeResolver()

    func bootstrapDrafts(
        templateIDsByRegion: [CardRegion: String],
        context: V1PreviewCompositionContext
    ) -> [CardRegion: V1PreviewDraft] {

        Dictionary(
            uniqueKeysWithValues:
                CardRegion
                .memoryCardRegions
                .map { region in
                    (
                        region,
                        defaultDraft(
                            for: region,
                            templateID:
                                templateIDsByRegion[region],
                            context: context
                        )
                    )
                }
        )
    }

    func renderModel(
        for draft: V1PreviewDraft,
        context: V1PreviewCompositionContext
    ) -> V1PreviewRenderModel {

        V1PreviewRenderModel(
            templateSourceText:
                draft.singleLineTemplateText,
            displayText:
                InlineContentTextComposer.compose(
                    draft.items.map { item in
                        InlineContentTextComposer.Piece(
                            kind: item.kind.inlineComposerKind,
                            value: resolvedDisplayValue(
                                for: item,
                                context: context
                            )
                        )
                    }
                )
        )
    }

    func displayText(
        for draft: V1PreviewDraft,
        context: V1PreviewCompositionContext
    ) -> String {

        renderModel(
            for: draft,
            context: context
        )
        .displayText
    }

    func displayText(
        for item: V1PreviewDraftItem,
        context: V1PreviewCompositionContext
    ) -> String {

        renderModel(
            for:
                V1PreviewDraft(
                    items: [item]
                ),
            context: context
        )
        .displayText
    }

    func displayText(
        for module: V1PreviewCompositionModule,
        context: V1PreviewCompositionContext
    ) -> String {

        renderModel(
            for:
                V1PreviewDraft(
                    items: [
                        makeModuleItem(
                            module,
                            context: context
                        )
                    ]
                ),
            context: context
        )
        .displayText
    }

    func templateText(
        for draft: V1PreviewDraft
    ) -> String {

        draft.singleLineTemplateText
    }

    func defaultDraft(
        for region: CardRegion,
        templateID: String?,
        context: V1PreviewCompositionContext
    ) -> V1PreviewDraft {

        switch region {
        case .slotA:
            return V1PreviewDraft(
                items: [
                    .text("记录"),
                    makeModuleItem(
                        .cameraModel,
                        context: context
                    )
                ]
            )
        case .slotB:
            return V1PreviewDraft(
                items: [
                    .text("记录于"),
                    makeModuleItem(
                        .captureDate,
                        context: context
                    ),
                    makeModuleItem(
                        .captureTime,
                        context: context
                    )
                ]
            )
        case .slotC:
            return V1PreviewDraft(
                items: [
                    makeModuleItem(
                        .captureSummary,
                        context: context
                    )
                ]
            )
        case .slotD:
            return V1PreviewDraft(
                items: [
                    makeModuleItem(
                        .smartTime,
                        context: context
                    )
                ]
            )
        case .subject,
             .icon,
             .badge:
            return V1PreviewDraft(
                items: [
                    .text(
                        ConfigurationSession.defaultPreviewText(
                            for: region,
                            templateID: templateID,
                            subject: context.subject
                        )
                    )
                ]
            )
        }
    }

    func makeModuleItem(
        _ module: V1PreviewCompositionModule,
        context: V1PreviewCompositionContext
    ) -> V1PreviewDraftItem {

        .token(
            module.title,
            value: moduleDisplayText(
                module,
                context: context
            ),
            templateValue: templateToken(
                for: module,
                context: context
            ),
            systemImage: module.systemImage
        )
    }

    private func resolvedDisplayValue(
        for item: V1PreviewDraftItem,
        context: V1PreviewCompositionContext
    ) -> String {

        guard item.kind == .token else {
            return item.displayValue
        }

        if let module = MemoryCardTemplateTokenCatalog.module(
            matching: item.savedValue
        ) {
            return moduleDisplayText(
                module,
                context: context
            )
        }

        return TemplateVariableEngine().render(
            item.savedValue,
            context: previewMetadataContext(context)
        )
    }

    private func moduleDisplayText(
        _ module: V1PreviewCompositionModule,
        context: V1PreviewCompositionContext
    ) -> String {

        guard module.isProductionBacked else {
            return ""
        }

        switch module {
        case .subjectNickname:
            return context.subjectNameFallback
        case .smartTime:
            return MemoryExpressionPreviewResolver
                .previewText(
                    subject: context.subject,
                    captureDate: context.captureDate
                )
            ?? captureTimeResolver.resolveText(
                captureDate: context.captureDate,
                referenceDate: context.birthdayDate,
                calendar: context.smartTimeCalendar
            )
        case .captureDate:
            return timeDisplayText(
                for: context.captureDate,
                component: .date,
                context: context
            )
        case .captureTime:
            return timeDisplayText(
                for: context.captureDate,
                component: .time,
                context: context
            )
        case .cameraMaker:
            return "Apple"
        case .cameraModel:
            return "iPhone 17 Pro Max"
        case .lensModel:
            return ""
        case .focalLength:
            return "20mm"
        case .aperture:
            return "f/1.9"
        case .shutterSpeed:
            return "1/117s"
        case .iso:
            return "ISO80"
        case .exposureBias:
            return "0 EV"
        case .meteringMode:
            return "Pattern"
        case .flash:
            return context.language == .simplifiedChinese
                ? "未开启"
                : "Off"
        case .whiteBalance:
            return context.language == .simplifiedChinese
                ? "自动"
                : "Auto"
        case .captureSummary:
            return "20mm f/1.9 1/117s ISO80"
        case .location:
            return previewExpressionContext(
                expressionConfiguration:
                    context
                    .locationDisplayConfiguration
            )?
                .value(
                    for: LocationExpressionProvider.locationToken
                )?
                .resolvedText
            ?? ""
        case .altitude:
            return "42m"
        case .imageSize:
            return "4032 × 3024"
        case .orientation:
            return context.language == .simplifiedChinese
                ? "横向"
                : "Landscape"
        case .fileFormat:
            return "HEIC"
        case .custom:
            return context.language == .simplifiedChinese
                ? "自定义内容"
                : "Custom content"
        }
    }

    private func templateToken(
        for module: V1PreviewCompositionModule,
        context: V1PreviewCompositionContext
    ) -> String {

        if module == .custom {
            return moduleDisplayText(
                module,
                context: context
            )
        }

        return module.rendererToken
    }

    private func previewExpressionContext(
        expressionConfiguration:
            ExpressionModuleConfiguration?
    ) -> ExpressionContext? {
        let metadata =
            PhotoMetadata(
                city: " 示例市 ",
                district: " 示例区 ",
                province: " 示例省 "
            )

        let locationContext =
            LocationContextBuilder()
            .build(
                from: metadata
            )

        let providerInput =
            LocationConfigurationAdapter()
            .providerInput(
                from:
                    expressionConfiguration
                    ?? ExpressionModuleConfiguration(
                        token:
                            LocationExpressionProvider
                            .locationToken
                    )
            )
            ?? LocationProviderInput(
                requestedPresentation:
                    .provinceCity,
                resolutionConfiguration:
                    LocationResolutionConfiguration()
            )

        guard
            let locationValue =
                LocationExpressionProvider()
                .expressionValue(
                    for: LocationExpressionProvider.locationToken,
                    context: locationContext,
                    requestedPresentation:
                        providerInput
                        .requestedPresentation,
                    configuration:
                        providerInput
                        .resolutionConfiguration
                )
        else {
            return nil
        }

        return try? ExpressionContext(
            values: [
                locationValue
            ]
        )
    }

    private func previewMetadataContext(
        _ context: V1PreviewCompositionContext
    ) -> MetadataContext {
        let calendar = context.smartTimeCalendar
        let components = calendar.dateComponents(
            [.year, .month, .day, .hour, .minute, .second],
            from: context.captureDate
        )
        let relationshipLabel = context.subject?
            .relationship.label
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let resolvedRelationshipLabel: String
        if let relationshipLabel, !relationshipLabel.isEmpty {
            resolvedRelationshipLabel = relationshipLabel
        } else {
            resolvedRelationshipLabel =
                context.language == .simplifiedChinese
                ? "记录者"
                : "Recorder"
        }
        let location = previewExpressionContext(
            expressionConfiguration:
                context.locationDisplayConfiguration
        )?
            .value(for: LocationExpressionProvider.locationToken)?
            .resolvedText
            ?? ""
        let captureDateFormatter = DateFormatter()
        captureDateFormatter.locale = context.language.locale
        captureDateFormatter.timeZone = calendar.timeZone
        captureDateFormatter.dateStyle = .medium
        captureDateFormatter.timeStyle = .short
        let captureDateDisplay = captureDateFormatter.string(
            from: context.captureDate
        )
        let weekdayFormatter = DateFormatter()
        weekdayFormatter.locale = context.language.locale
        weekdayFormatter.timeZone = calendar.timeZone
        weekdayFormatter.dateFormat = "EEEE"

        return MetadataContext(values: [
            MetadataContext.Key.title:
                context.language == .simplifiedChinese
                ? "回忆标题"
                : "Memory title",
            MetadataContext.Key.story:
                context.language == .simplifiedChinese
                ? "回忆故事"
                : "Memory story",
            MetadataContext.Key.tags: "MemoMark",
            MetadataContext.Key.subjectNickname:
                context.subjectNameFallback,
            MetadataContext.Key.relationshipLabel:
                resolvedRelationshipLabel,
            MetadataContext.Key.brand: "Apple",
            MetadataContext.Key.model: "iPhone 17 Pro Max",
            MetadataContext.Key.lens: "iPhone Wide Camera",
            MetadataContext.Key.iso: "80",
            MetadataContext.Key.aperture: "1.9",
            MetadataContext.Key.shutter: "1/117",
            MetadataContext.Key.focalLength: "20mm",
            MetadataContext.Key.focalLength35mm: "24",
            MetadataContext.Key.width: "4032",
            MetadataContext.Key.height: "3024",
            MetadataContext.Key.aspectRatio: "4:3",
            MetadataContext.Key.megapixels: "12 MP",
            MetadataContext.Key.orientation:
                context.language == .simplifiedChinese
                ? "横向"
                : "Landscape",
            MetadataContext.Key.latitude: "31.2304°N",
            MetadataContext.Key.longitude: "121.4737°E",
            MetadataContext.Key.altitude: "42m",
            MetadataContext.Key.location: location,
            MetadataContext.Key.locationDisplay: location,
            MetadataContext.Key.year: "\(components.year ?? 2026)",
            MetadataContext.Key.month:
                String(format: "%02d", components.month ?? 6),
            MetadataContext.Key.day:
                String(format: "%02d", components.day ?? 1),
            MetadataContext.Key.hour:
                String(format: "%02d", components.hour ?? 12),
            MetadataContext.Key.minute:
                String(format: "%02d", components.minute ?? 0),
            MetadataContext.Key.second:
                String(format: "%02d", components.second ?? 0),
            MetadataContext.Key.weekday:
                "\(calendar.component(.weekday, from: context.captureDate))",
            MetadataContext.Key.weekdayName:
                weekdayFormatter.string(from: context.captureDate),
            MetadataContext.Key.captureDateDisplay:
                captureDateDisplay,
            MetadataContext.Key.captureTimezone:
                "UTC\(calendar.timeZone.secondsFromGMT() >= 0 ? "+" : "-")\(String(format: "%02d:%02d", abs(calendar.timeZone.secondsFromGMT()) / 3600, abs(calendar.timeZone.secondsFromGMT()) % 3600 / 60))",
            MetadataContext.Key.captureDateShort:
                timeDisplayText(
                    for: context.captureDate,
                    component: .date,
                    context: context
                ),
            MetadataContext.Key.captureTimeShort:
                timeDisplayText(
                    for: context.captureDate,
                    component: .time,
                    context: context
                ),
            MetadataContext.Key.cameraSummary:
                "20mm f/1.9 1/117s ISO80"
        ])
    }

    private enum TimeDisplayComponent {
        case date
        case time
    }

    private func timeDisplayText(
        for date: Date,
        component: TimeDisplayComponent,
        context: V1PreviewCompositionContext
    ) -> String {
        let configuration = TimeDisplayConfiguration(
            baseStyle: TimeDisplayConfiguration.BaseStyle(
                rawValue: context.timeDisplayConfiguration?.options["baseStyle"] ?? "daily"
            ) ?? .daily,
            supplement: TimeDisplayConfiguration.Supplement(
                rawValue: context.timeDisplayConfiguration?.options["supplement"] ?? "none"
            ) ?? .none
        )

        switch component {
        case .date:
            return TimeExpressionProvider.dateText(
                for: date,
                configuration: configuration,
                timeZone: context.smartTimeCalendar.timeZone,
                language: context.language
            )
        case .time:
            return TimeExpressionProvider.timeText(
                for: date,
                configuration: configuration,
                timeZone: context.smartTimeCalendar.timeZone,
                language: context.language
            )
        }
    }
}
#endif

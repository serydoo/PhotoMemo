#if !PHOTOMEMO_SHARE_EXTENSION
import Foundation

struct V1PreviewCompositionContext: Hashable {

    let subject: MemorySubject?

    let birthdayDate: Date

    let captureDate: Date

    let locationDisplayConfiguration:
        ExpressionModuleConfiguration?

    init(
        subject: MemorySubject?,
        birthdayDate: Date,
        captureDate: Date = V1PreviewCompositionEngine.defaultCaptureDate,
        locationDisplayConfiguration:
            ExpressionModuleConfiguration? = nil
    ) {
        self.subject = subject
        self.birthdayDate = birthdayDate
        self.captureDate = captureDate
        self.locationDisplayConfiguration =
            locationDisplayConfiguration
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

    let kind: Kind

    var title: String

    var value: String

    var savedValue: String

    var systemImage: String

    var displayValue: String {
        switch kind {
        case .text,
             .token,
             .separator:
            return value
        case .lineBreak:
            return " "
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
            return " "
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

enum V1PreviewCompositionModule:
    String,
    CaseIterable,
    Identifiable {

    case subjectNickname
    case smartTime
    case captureDate
    case captureTime
    case cameraMaker
    case cameraModel
    case lensModel
    case focalLength
    case aperture
    case shutterSpeed
    case iso
    case exposureBias
    case meteringMode
    case flash
    case whiteBalance
    case captureSummary
    case location
    case altitude
    case imageSize
    case orientation
    case fileFormat
    case custom

    var id: String {
        rawValue
    }

    var title: String {
        switch self {
        case .subjectNickname:
            return "对象昵称"
        case .smartTime:
            return "智能结果"
        case .captureDate:
            return "拍摄日期"
        case .captureTime:
            return "拍摄时间"
        case .cameraMaker:
            return "设备厂商"
        case .cameraModel:
            return "设备型号"
        case .lensModel:
            return "镜头型号"
        case .focalLength:
            return "焦距"
        case .aperture:
            return "光圈"
        case .shutterSpeed:
            return "快门"
        case .iso:
            return "ISO"
        case .exposureBias:
            return "曝光补偿"
        case .meteringMode:
            return "测光模式"
        case .flash:
            return "闪光灯"
        case .whiteBalance:
            return "白平衡"
        case .captureSummary:
            return "拍摄参数汇总"
        case .location:
            return "位置"
        case .altitude:
            return "海拔"
        case .imageSize:
            return "图片尺寸"
        case .orientation:
            return "方向"
        case .fileFormat:
            return "文件格式"
        case .custom:
            return "自定义"
        }
    }

    var systemImage: String {
        switch self {
        case .subjectNickname:
            return "person.fill"
        case .smartTime:
            return "calendar.badge.clock"
        case .captureDate:
            return "calendar"
        case .captureTime:
            return "clock"
        case .cameraMaker:
            return "apple.logo"
        case .cameraModel:
            return "camera.fill"
        case .lensModel:
            return "camera.macro"
        case .focalLength:
            return "scope"
        case .aperture:
            return "camera.aperture"
        case .shutterSpeed:
            return "timer"
        case .iso:
            return "dial.low"
        case .exposureBias:
            return "plusminus"
        case .meteringMode:
            return "camera.metering.center.weighted"
        case .flash:
            return "bolt.fill"
        case .whiteBalance:
            return "sun.max"
        case .captureSummary:
            return "camera.metering.center.weighted"
        case .location:
            return "location.fill"
        case .altitude:
            return "mountain.2.fill"
        case .imageSize:
            return "rectangle.inset.filled"
        case .orientation:
            return "rectangle.rotate"
        case .fileFormat:
            return "doc.fill"
        case .custom:
            return "plus.circle"
        }
    }

    var token: String {
        switch self {
        case .subjectNickname:
            return "{{subject_nickname}}"
        case .smartTime:
            return "{{age_result}}"
        case .captureDate:
            return "{{capture_date}}"
        case .captureTime:
            return "{{capture_time}}"
        case .cameraMaker:
            return "{{camera_make}}"
        case .cameraModel:
            return "{{camera_model}}"
        case .lensModel:
            return "{{lens_model}}"
        case .focalLength:
            return "{{focal_length}}"
        case .aperture:
            return "{{aperture}}"
        case .shutterSpeed:
            return "{{shutter_speed}}"
        case .iso:
            return "{{iso}}"
        case .exposureBias:
            return "{{exposure_bias}}"
        case .meteringMode:
            return "{{metering_mode}}"
        case .flash:
            return "{{flash}}"
        case .whiteBalance:
            return "{{white_balance}}"
        case .captureSummary:
            return "{{capture_parameters_summary}}"
        case .location:
            return "{{location}}"
        case .altitude:
            return "{{altitude}}"
        case .imageSize:
            return "{{image_size}}"
        case .orientation:
            return "{{orientation}}"
        case .fileFormat:
            return "{{file_format}}"
        case .custom:
            return "{{custom}}"
        }
    }

    var rendererToken: String {
        switch self {
        case .subjectNickname:
            return "{{subject_nickname}}"
        case .smartTime:
            return "{{memory_summary}}"
        case .captureDate:
            return "{{capture_date_short}}"
        case .captureTime:
            return "{{capture_time_short}}"
        case .cameraMaker:
            return "{{brand}}"
        case .cameraModel:
            return "{{model}}"
        case .lensModel:
            return "{{lens}}"
        case .focalLength:
            return "{{focal_length}}"
        case .aperture:
            return "{{aperture}}"
        case .shutterSpeed:
            return "{{shutter}}"
        case .iso:
            return "{{iso}}"
        case .captureSummary:
            return "{{camera_summary}}"
        case .location:
            return "{{location_display}}"
        case .altitude:
            return "{{altitude}}"
        case .imageSize:
            return "{{width}} × {{height}}"
        case .orientation:
            return "{{orientation}}"
        case .fileFormat:
            return "{{file_format}}"
        case .exposureBias,
             .meteringMode,
             .flash,
             .whiteBalance,
             .custom:
            return token
        }
    }
}

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

        guard let module =
            V1PreviewCompositionModule.allCases.first(where: {
                $0.rendererToken == item.savedValue
                || $0.token == item.savedValue
            })
        else {
            return item.displayValue
        }

        return moduleDisplayText(
            module,
            context: context
        )
    }

    private func moduleDisplayText(
        _ module: V1PreviewCompositionModule,
        context: V1PreviewCompositionContext
    ) -> String {

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
            return captureDateFormatter.string(
                from: context.captureDate
            )
        case .captureTime:
            return captureTimeFormatter.string(
                from: context.captureDate
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
            return "未开启"
        case .whiteBalance:
            return "自动"
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
            return "横向"
        case .fileFormat:
            return "HEIC"
        case .custom:
            return "自定义内容"
        }
    }

    private func templateToken(
        for module: V1PreviewCompositionModule,
        context: V1PreviewCompositionContext
    ) -> String {

        let token = module.rendererToken

        if module == .subjectNickname {
            return token
        }

        return token == module.token
            ? moduleDisplayText(
                module,
                context: context
            )
            : token
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

    private var captureDateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.locale =
            Locale(identifier: "zh_CN")
        formatter.dateFormat = "yyyy.MM.dd"
        return formatter
    }

    private var captureTimeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.locale =
            Locale(identifier: "zh_CN")
        formatter.dateFormat = "HH:mm:ss"
        return formatter
    }
}
#endif

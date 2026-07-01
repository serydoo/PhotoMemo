#if !PHOTOMEMO_SHARE_EXTENSION
import Foundation

enum ConfigurationCenterPreviewDefaults {

    static func defaultPreviewText(
        for region: CardRegion,
        subject: MemorySubject?
    ) -> String {
        defaultPreviewText(
            for: region,
            templateID: nil,
            subject: subject
        )
    }

    static func defaultPreviewText(
        for region: CardRegion,
        templateID: String?,
        subject: MemorySubject?
    ) -> String {
        if let templateID,
           let text =
            defaultPreviewText(
                forTemplateID: templateID,
                subject: subject
            ) {
            return text
        }

        switch region {
        case .slotA:
            return "记录"
        case .slotB:
            return "2026.05.24 14:33:13"
        case .slotC:
            return "20mm f/1.9 1/117s ISO80"
        case .slotD:
            return generatedMemoryModuleText(
                subject: subject
            ) ?? "记忆表达"
        case .subject:
            return subject?.identity.shortName
            ?? subject?.identity.displayName
            ?? "记忆对象"
        case .icon:
            return subject?
                .decorations
                .first(where: { $0.kind == .icon })?
                .title ?? "图标"
        case .badge:
            return subject?
                .decorations
                .first(where: { $0.kind == .badge })?
                .title ?? "徽标"
        }
    }

    static func generatedMemoryModuleText(
        subject: MemorySubject?,
        smartModuleCarrierRegion: CardRegion = .slotD
    ) -> String? {
        MemoryExpressionPreviewResolver
            .previewText(
                subject: subject,
                smartModuleCarrierRegion:
                    smartModuleCarrierRegion
            )
    }

    private static func defaultPreviewText(
        forTemplateID templateID: String,
        subject: MemorySubject?
    ) -> String? {
        switch templateID {
        case "recorder.configuration1":
            return "记录 iPhone 17 Pro Max"
        case "recorder.configuration2",
             "recorder.configuration3":
            return " "
        case "timeline.configuration1":
            return "2026.05.24 14:33:13"
        case "timeline.configuration2":
            return "2026.05.24"
        case "timeline.configuration3":
            return " "
        case "context.configuration1":
            return "20mm f/1.9 1/117s ISO80"
        case "context.configuration2":
            return "24mm f/1.78 1/100s ISO125"
        case "context.configuration3":
            return " "
        case "memory.configuration1":
            return ConfigurationCenterMemoryTemplateCatalog
                .birthdayAgePreviewText(
                    subject: subject
                )
        case "memory.configuration2",
             "memory.configuration3":
            return " "
        default:
            return nil
        }
    }
}
#endif

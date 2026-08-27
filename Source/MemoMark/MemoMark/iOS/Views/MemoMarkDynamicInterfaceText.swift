import Foundation

enum MemoMarkDynamicInterfaceText {

    static func subjectSwitchLabel(
        subjectName: String,
        language: MemoMarkLanguage
    ) -> String {
        formatted(
            key: "accessibility.subject.switch_format",
            fallback: "Switch to %@",
            value: subjectName,
            language: language
        )
    }

    static func moduleCandidatesLabel(
        regionTitle: String,
        language: MemoMarkLanguage
    ) -> String {
        formatted(
            key: "accessibility.region.module_candidates_format",
            fallback: "Module options for %@",
            value: regionTitle,
            language: language
        )
    }

    static func subjectConfigurationTitle(
        subjectName: String,
        language: MemoMarkLanguage
    ) -> String {
        formatted(
            key: "configuration.library.subject_title_format",
            fallback: "%@ configurations",
            value: subjectName,
            language: language
        )
    }

    private static func formatted(
        key: String,
        fallback: String,
        value: String,
        language: MemoMarkLanguage
    ) -> String {
        String(
            format: language.localized(
                key: key,
                fallback: fallback
            ),
            locale: language.locale,
            value
        )
    }
}

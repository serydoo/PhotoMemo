#if !PHOTOMEMO_SHARE_EXTENSION
import Foundation

enum ConfigurationCenterMemoryTemplateCatalog {

    static let birthdayAgeTemplateID =
        "memory.configuration1"

    static let birthdayAgeTitle =
        "配置 1：生日年龄智能模块"

    static let birthdayAgeSummary =
        "默认表达记忆对象在照片拍摄时的生日年龄智能结果，预览跟随当前冻结公式。"

    static let birthdayAgeSubjectDefault =
        "途途"

    static let birthdayAgeActionDefault =
        "今天"

    static let birthdayAgeResultDefault =
        "11个月28天啦！"

    static func birthdayAgePreviewText(
        subject: MemorySubject?
    ) -> String {
        if let text =
            MemoryExpressionPreviewResolver
            .previewText(subject: subject) {
            return text
        }

        let subjectName =
            resolvedSubjectName(
                subject: subject
            )

        return "\(subjectName)\(birthdayAgeActionDefault)\(birthdayAgeResultDefault)"
    }

    private static func resolvedSubjectName(
        subject: MemorySubject?
    ) -> String {
        let shortName =
            subject?.identity.shortName
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        if let shortName,
           !shortName.isEmpty {
            return shortName
        }

        let displayName =
            subject?.identity.displayName
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        if let displayName,
           !displayName.isEmpty {
            return displayName
        }

        return birthdayAgeSubjectDefault
    }
}
#endif

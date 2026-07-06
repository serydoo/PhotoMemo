#if !PHOTOMEMO_SHARE_EXTENSION
import Foundation

enum V1ConfigurationStatus: Hashable {
    case idle
    case dirty
    case saving
    case saved
    case subjectSynced
    case failure(message: String)
}

enum V1ConfigurationStatusContext {
    case defaultConfiguration
    case shareConfiguration
    case preset
}

extension V1ConfigurationStatus {

    var tone: V1IOSHomeStatusBadge.Tone {
        switch self {
        case .saved, .subjectSynced:
            return .accent
        case .dirty, .failure:
            return .warning
        case .saving, .idle:
            return .neutral
        }
    }

    func message(
        for context: V1ConfigurationStatusContext
    ) -> String {
        switch self {
        case .idle:
            switch context {
            case .defaultConfiguration:
                return "尚未保存为当前配置"
            case .shareConfiguration:
                return "尚未保存为分享配置"
            case .preset:
                return "尚未生效"
            }
        case .dirty:
            return "有未保存修改"
        case .saving:
            return "正在保存"
        case .saved:
            switch context {
            case .defaultConfiguration:
                return "已保存为当前配置"
            case .shareConfiguration:
                return "已保存为分享配置"
            case .preset:
                return "当前生效"
            }
        case .subjectSynced:
            return "记忆对象已同步"
        case .failure(let message):
            return message
        }
    }

    var isDirty: Bool {
        if case .dirty = self {
            return true
        }

        return false
    }

    var isSaving: Bool {
        if case .saving = self {
            return true
        }

        return false
    }
}
#endif

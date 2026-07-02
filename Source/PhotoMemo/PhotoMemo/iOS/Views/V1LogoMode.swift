#if !PHOTOMEMO_SHARE_EXTENSION
import Foundation

enum V1LogoMode:
    String,
    CaseIterable,
    Identifiable,
    Hashable {

    case appleMini
    case customUpload
    case subjectAvatar

    var id: String {
        rawValue
    }

    var title: String {
        switch self {
        case .appleMini:
            return "Apple 标识"
        case .customUpload:
            return "自选标识"
        case .subjectAvatar:
            return "使用对象头像"
        }
    }
}
#endif

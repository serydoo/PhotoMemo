#if !PHOTOMEMO_SHARE_EXTENSION
import Foundation

struct MemoryWriteOptionPresentation:
    Equatable {

    let toggleTitle: String
    let toggleDescription: String
    let inputPlaceholder: String
    let resolvedTitle: String
    let resolvedDescription: String
    let fallbackNote: String
}

enum MemoryWriteOptionPresenter {

    static func presentation(
        usesCustomText: Bool,
        resolvedText: String
    ) -> MemoryWriteOptionPresentation {
        MemoryWriteOptionPresentation(
            toggleTitle: "写入记忆信息",
            toggleDescription:
                usesCustomText
                ? "关闭后，将使用下方录入内容替换图片说明。"
                : "开启后，默认将当前智能模块结果写入图片说明。",
            inputPlaceholder:
                "输入准备替换写入到图片说明框的信息",
            resolvedTitle:
                usesCustomText
                ? "替换写入"
                : "默认写入（当前智能模块）",
            resolvedDescription: resolvedText,
            fallbackNote:
                usesCustomText
                ? "重新打开后，将恢复写入当前智能模块结果。"
                : "智能模块会结合拍摄时间、记忆对象和时间锚点生成说明。"
        )
    }
}
#endif

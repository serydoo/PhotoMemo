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
            toggleTitle: "添加自定义内容",
            toggleDescription:
                usesCustomText
                ? "开启后，将下方内容补充到智能模块结果之后。"
                : "默认仅写入当前智能模块结果。",
            inputPlaceholder:
                "输入补充到智能模块结果后的内容",
            resolvedTitle:
                usesCustomText
                ? "完整写入（智能模块 + 自定义）"
                : "默认写入（当前智能模块）",
            resolvedDescription: resolvedText,
            fallbackNote:
                usesCustomText
                ? "自定义内容不会覆盖智能模块结果。"
                : "智能模块会结合拍摄时间、记忆对象和时间锚点生成说明。"
        )
    }
}
#endif

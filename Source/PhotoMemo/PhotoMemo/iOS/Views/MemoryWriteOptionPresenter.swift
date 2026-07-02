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
            toggleTitle: "单独录入相册说明",
            toggleDescription:
                "开启后，优先写入你单独录入的内容；关闭后，默认写入当前生成的智能模块结果。",
            inputPlaceholder:
                "输入想单独写入 Apple Photos 说明栏的文字",
            resolvedTitle:
                usesCustomText
                ? "实际写入"
                : "默认写入（当前智能模块）",
            resolvedDescription: resolvedText,
            fallbackNote:
                usesCustomText
                ? "关闭后，默认写入当前生成的智能模块完整结果。"
                : "未开启单独录入时，将默认写入当前生成的智能模块完整结果。"
        )
    }
}
#endif

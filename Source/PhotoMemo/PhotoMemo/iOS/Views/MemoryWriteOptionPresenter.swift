#if !PHOTOMEMO_SHARE_EXTENSION
import Foundation

struct MemoryWriteOptionPresentation:
    Equatable {

    let toggleTitle: String
    let toggleDescription: String
    let defaultContentTitle: String
    let defaultContentDescription: String
    let inputPlaceholder: String
    let resolvedTitle: String
    let resolvedDescription: String
    let fallbackNote: String
}

enum MemoryWriteOptionPresenter {

    static func presentation(
        usesCustomText: Bool,
        resolvedText: String,
        language: MemoMarkLanguage = MemoMarkLanguage.interfaceStored
    ) -> MemoryWriteOptionPresentation {
        MemoryWriteOptionPresentation(
            toggleTitle: language.localized(
                key: "output.memory_write.custom.title",
                fallback: "添加自定义内容"
            ),
            toggleDescription:
                language.localized(
                    key: "output.memory_write.custom.description",
                    fallback: "开启后，将用户自定义内容追加写入生成照片的说明文本，不会覆盖智能模块输出。"
                ),
            defaultContentTitle: language.localized(
                key: "output.memory_write.default.title",
                fallback: "默认写入内容"
            ),
            defaultContentDescription:
                language.localized(
                    key: "output.memory_write.default.description",
                    fallback: "将当前智能模块输出写入生成照片的说明文本，便于在 Apple Photos 中检索。"
                ),
            inputPlaceholder:
                language.localized(
                    key: "output.memory_write.custom.placeholder",
                    fallback: "输入补充到智能模块结果后的内容"
                ),
            resolvedTitle: language.localized(
                key: "output.memory_write.preview.title",
                fallback: "写入预览"
            ),
            resolvedDescription: resolvedText,
            fallbackNote:
                usesCustomText
                ? language.localized(
                    key: "output.memory_write.preview.custom_note",
                    fallback: "包含当前智能模块输出与自定义内容。"
                )
                : language.localized(
                    key: "output.memory_write.preview.default_note",
                    fallback: "由当前智能模块根据拍摄时间、记忆对象和时间锚点生成。"
                )
        )
    }
}
#endif

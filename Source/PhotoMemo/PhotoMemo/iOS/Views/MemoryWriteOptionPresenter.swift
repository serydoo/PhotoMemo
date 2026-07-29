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
                fallback: "补充一句话"
            ),
            toggleDescription:
                language.localized(
                    key: "output.memory_write.custom.description",
                    fallback: "把想补充的话，写在照片说明里。"
                ),
            defaultContentTitle: language.localized(
                key: "output.memory_write.default.title",
                fallback: "照片说明"
            ),
            defaultContentDescription:
                language.localized(
                    key: "output.memory_write.default.description",
                    fallback: "把这段回忆写进照片说明，方便之后在 Apple Photos 中找到它。"
                ),
            inputPlaceholder:
                language.localized(
                    key: "output.memory_write.custom.placeholder",
                    fallback: "写下想补充的话"
                ),
            resolvedTitle: language.localized(
                key: "output.memory_write.preview.title",
                fallback: "即将写下的内容"
            ),
            resolvedDescription: resolvedText,
            fallbackNote:
                usesCustomText
                ? language.localized(
                    key: "output.memory_write.preview.custom_note",
                    fallback: "包含这段回忆和你补充的话。"
                )
                : language.localized(
                    key: "output.memory_write.preview.default_note",
                    fallback: "会根据照片拍摄时间、记忆对象和时间锚点写下这段回忆。"
                )
        )
    }
}
#endif

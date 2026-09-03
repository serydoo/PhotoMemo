#if !MEMOMARK_SHARE_EXTENSION
import Foundation
import UniformTypeIdentifiers

enum PhotoIntakeUnsupportedMessagePresenter {

    nonisolated static let fallbackMessage =
        "未找到可处理的照片"

    nonisolated static func message(
        for contentTypes: [UTType]
    ) -> String {

        let policy =
            PhotoProcessingInputPolicy.standard

        guard !contentTypes.isEmpty,
              !contentTypes.contains(
                where:
                    policy.isSupportedContentType
              ) else {
            return fallbackMessage
        }

        guard let verdict =
            contentTypes
            .map({
                policy.verdict(
                    contentType: $0,
                    pixelWidth: 1,
                    pixelHeight: 1
                )
            })
            .first(where: {
                !$0.isSupported
            }) else {
            return fallbackMessage
        }

        return [
            verdict.title,
            verdict.message
        ]
        .filter {
            !$0.isEmpty
        }
        .joined(
            separator: "\n"
        )
    }
}
#endif

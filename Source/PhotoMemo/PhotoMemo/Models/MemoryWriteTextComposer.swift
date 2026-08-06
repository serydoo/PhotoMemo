import Foundation

enum MemoryWriteTextComposer {

    static func compose(
        smartText: String?,
        usesCustomText: Bool,
        customText: String
    ) -> String? {
        let trimmedSmartText = smartText?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedCustomText = customText
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let parts = [
            trimmedSmartText.flatMap { $0.isEmpty ? nil : $0 },
            usesCustomText && !trimmedCustomText.isEmpty
                ? trimmedCustomText
                : nil
        ].compactMap { $0 }

        return parts.isEmpty
            ? nil
            : parts.joined(separator: "\n")
    }
}

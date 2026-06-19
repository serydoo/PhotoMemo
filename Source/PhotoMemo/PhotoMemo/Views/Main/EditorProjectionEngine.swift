#if !PHOTOMEMO_SHARE_EXTENSION
import Foundation

struct EditorProjectionDescriptor: Hashable {

    let token: String

    let title: String

    let category: TemplateVariableCategory
}

struct TemplateEditorModuleSpan: Hashable {

    let token: String

    var range: NSRange
}

struct EditorProjectionState: Hashable {

    let text: String

    let moduleSpans: [TemplateEditorModuleSpan]

    let selection: NSRange
}

enum EditorProjectionEngine {

    private static let tokenRegex =
        try? NSRegularExpression(
            pattern: #"\{\{[^}]+\}\}"#
        )

    private static let descriptorsByToken:
        [String: EditorProjectionDescriptor] = {

        let builtInDescriptors =
            TemplateVariableLibrary.all.map {
                EditorProjectionDescriptor(
                    token: $0.token,
                    title: $0.title,
                    category: $0.category
                )
            }

        let extraDescriptors: [EditorProjectionDescriptor] = [
            EditorProjectionDescriptor(
                token: "{{camera_summary}}",
                title: "参数摘要",
                category: .recognized
            ),
            EditorProjectionDescriptor(
                token: "{{location}}",
                title: "地点",
                category: .recognized
            ),
            EditorProjectionDescriptor(
                token: "{{latitude}}",
                title: "纬度",
                category: .recognized
            ),
            EditorProjectionDescriptor(
                token: "{{longitude}}",
                title: "经度",
                category: .recognized
            ),
            EditorProjectionDescriptor(
                token: "{{altitude}}",
                title: "海拔",
                category: .recognized
            ),
            EditorProjectionDescriptor(
                token: "{{city}}",
                title: "城市",
                category: .recognized
            ),
            EditorProjectionDescriptor(
                token: "{{province}}",
                title: "省份",
                category: .recognized
            ),
            EditorProjectionDescriptor(
                token: "{{country}}",
                title: "国家",
                category: .recognized
            ),
            EditorProjectionDescriptor(
                token: "{{memory_summary}}",
                title: "记忆摘要",
                category: .intelligent
            )
        ]

        var descriptors: [String: EditorProjectionDescriptor] = [:]

        for descriptor in builtInDescriptors + extraDescriptors {
            descriptors[descriptor.token] = descriptor
        }

        return descriptors
    }()

    static func descriptor(
        forToken token: String
    ) -> EditorProjectionDescriptor? {

        descriptorsByToken[token]
    }

    static func displayLabel(
        for variable: TemplateVariable
    ) -> String {

        displayLabel(
            for: EditorProjectionDescriptor(
                token: variable.token,
                title: variable.title,
                category: variable.category
            )
        )
    }

    static func displayLabel(
        for descriptor: EditorProjectionDescriptor
    ) -> String {

        "〔\(descriptor.title)〕"
    }

    static func displayState(
        from rawValue: String
    ) -> EditorProjectionState {

        guard let tokenRegex else {
            return EditorProjectionState(
                text: rawValue,
                moduleSpans: [],
                selection: NSRange(
                    location: (rawValue as NSString).length,
                    length: 0
                )
            )
        }

        let nsRawValue = rawValue as NSString
        let fullRange = NSRange(
            location: 0,
            length: nsRawValue.length
        )

        var renderedText = ""
        var moduleSpans: [TemplateEditorModuleSpan] = []
        var cursor = 0

        for match in tokenRegex.matches(
            in: rawValue,
            range: fullRange
        ) {

            if match.range.location > cursor {
                renderedText.append(
                    nsRawValue.substring(
                        with: NSRange(
                            location: cursor,
                            length:
                                match.range.location
                                - cursor
                        )
                    )
                )
            }

            let token =
                nsRawValue.substring(with: match.range)

            if let descriptor =
                descriptor(forToken: token) {

                let label =
                    displayLabel(for: descriptor)

                let labelRange = NSRange(
                    location:
                        (renderedText as NSString).length,
                    length:
                        (label as NSString).length
                )

                renderedText.append(label)
                moduleSpans.append(
                    TemplateEditorModuleSpan(
                        token: token,
                        range: labelRange
                    )
                )

            } else {
                renderedText.append(token)
            }

            cursor =
                match.range.location
                + match.range.length
        }

        if cursor < nsRawValue.length {
            renderedText.append(
                nsRawValue.substring(
                    with: NSRange(
                        location: cursor,
                        length: nsRawValue.length - cursor
                    )
                )
            )
        }

        return EditorProjectionState(
            text: renderedText,
            moduleSpans: moduleSpans,
            selection: NSRange(
                location:
                    (renderedText as NSString).length,
                length: 0
            )
        )
    }

    static func synchronizedState(
        from rawValue: String,
        selection: NSRange?,
        resetSelectionToEnd: Bool
    ) -> EditorProjectionState {

        let baseState =
            displayState(from: rawValue)

        let resolvedSelection: NSRange

        if resetSelectionToEnd || selection == nil {
            resolvedSelection = baseState.selection
        } else {
            resolvedSelection =
                normalizedSelectionRange(
                    selection ?? baseState.selection,
                    in: baseState.text
                )
        }

        return EditorProjectionState(
            text: baseState.text,
            moduleSpans: baseState.moduleSpans,
            selection: resolvedSelection
        )
    }

    static func rawTemplateValue(
        from displayText: String,
        moduleSpans: [TemplateEditorModuleSpan]
    ) -> String {

        let nsDisplayText =
            displayText as NSString

        let sanitizedSpans =
            sanitizedModuleSpans(
                moduleSpans,
                in: displayText
            )
            .sorted {
                $0.range.location < $1.range.location
            }

        var segments: [String] = []
        var cursor = 0

        for span in sanitizedSpans {

            if span.range.location > cursor {
                segments.append(
                    nsDisplayText.substring(
                        with: NSRange(
                            location: cursor,
                            length:
                                span.range.location
                                - cursor
                        )
                    )
                )
            }

            segments.append(span.token)
            cursor =
                span.range.location
                + span.range.length
        }

        if cursor < nsDisplayText.length {
            segments.append(
                nsDisplayText.substring(
                    with: NSRange(
                        location: cursor,
                        length:
                            nsDisplayText.length - cursor
                    )
                )
            )
        }

        return segments.joined()
    }

    static func replacementResult(
        for text: String,
        moduleSpans: [TemplateEditorModuleSpan],
        replacementRange: NSRange,
        replacementText: String,
        insertedModuleSpans:
            [TemplateEditorModuleSpan] = []
    ) -> EditorProjectionState {

        let safeRange =
            clampedRange(
                replacementRange,
                in: text
            )

        let nextText =
            (text as NSString).replacingCharacters(
                in: safeRange,
                with: replacementText
            )

        let removedUpperBound =
            safeRange.location + safeRange.length

        let delta =
            (replacementText as NSString).length
            - safeRange.length

        var nextModuleSpans: [TemplateEditorModuleSpan] = []

        for span in sanitizedModuleSpans(
            moduleSpans,
            in: text
        ) {

            if NSIntersectionRange(
                span.range,
                safeRange
            ).length > 0 {
                continue
            }

            if span.range.location
                >= removedUpperBound {

                var shiftedSpan = span
                shiftedSpan.range.location += delta
                nextModuleSpans.append(
                    shiftedSpan
                )

            } else {
                nextModuleSpans.append(span)
            }
        }

        for span in insertedModuleSpans {
            var insertedSpan = span
            insertedSpan.range.location +=
                safeRange.location
            nextModuleSpans.append(insertedSpan)
        }

        let sanitizedSpans =
            sanitizedModuleSpans(
                nextModuleSpans,
                in: nextText
            )

        return EditorProjectionState(
            text: nextText,
            moduleSpans: sanitizedSpans,
            selection: NSRange(
                location:
                    safeRange.location
                    + (replacementText as NSString).length,
                length: 0
            )
        )
    }

    static func normalizedSelectionRange(
        _ selection: NSRange,
        in text: String
    ) -> NSRange {

        clampedRange(
            selection,
            in: text
        )
    }

    static func adjustedSelectionRange(
        _ selection: NSRange,
        moduleSpans: [TemplateEditorModuleSpan],
        in text: String
    ) -> NSRange {

        let safeSelection =
            normalizedSelectionRange(
                selection,
                in: text
            )

        guard safeSelection.length == 0 else {
            return safeSelection
        }

        for span in sanitizedModuleSpans(
            moduleSpans,
            in: text
        ) {

            let upperBound =
                span.range.location
                + span.range.length

            if safeSelection.location > span.range.location,
               safeSelection.location < upperBound {
                return NSRange(
                    location: upperBound,
                    length: 0
                )
            }
        }

        return safeSelection
    }

    static func adjustedEditingRange(
        _ range: NSRange,
        moduleSpans: [TemplateEditorModuleSpan],
        in text: String
    ) -> NSRange {

        let safeRange =
            clampedRange(
                range,
                in: text
            )

        let sanitizedSpans =
            sanitizedModuleSpans(
                moduleSpans,
                in: text
            )

        if safeRange.length == 0,
           let containingSpan =
            sanitizedSpans.first(
                where: {
                    safeRange.location
                    > $0.range.location
                    && safeRange.location
                    < $0.range.location
                    + $0.range.length
                }
            ) {
            return containingSpan.range
        }

        let intersectingSpans =
            sanitizedSpans.filter {
                NSIntersectionRange(
                    safeRange,
                    $0.range
                ).length > 0
            }

        guard !intersectingSpans.isEmpty else {
            return safeRange
        }

        var lowerBound = safeRange.location
        var upperBound =
            safeRange.location
            + safeRange.length

        for span in intersectingSpans {
            lowerBound = min(
                lowerBound,
                span.range.location
            )
            upperBound = max(
                upperBound,
                span.range.location
                + span.range.length
            )
        }

        return NSRange(
            location: lowerBound,
            length: upperBound - lowerBound
        )
    }

    static func adjustedReplacementRange(
        _ range: NSRange,
        replacementText: String,
        moduleSpans: [TemplateEditorModuleSpan],
        in text: String
    ) -> NSRange {

        let adjustedRange =
            adjustedEditingRange(
                range,
                moduleSpans: moduleSpans,
                in: text
            )

        guard replacementText.isEmpty else {
            return adjustedRange
        }

        let safeRange =
            clampedRange(
                range,
                in: text
            )

        guard safeRange.length == 0 else {
            return adjustedRange
        }

        let sanitizedSpans =
            sanitizedModuleSpans(
                moduleSpans,
                in: text
            )

        if let previousSpan =
            sanitizedSpans.last(
                where: {
                    safeRange.location
                    == $0.range.location
                    + $0.range.length
                }
            ) {
            return previousSpan.range
        }

        if let nextSpan =
            sanitizedSpans.first(
                where: {
                    safeRange.location
                    == $0.range.location
                }
            ) {
            return nextSpan.range
        }

        return adjustedRange
    }

    static func sanitizedModuleSpans(
        _ moduleSpans: [TemplateEditorModuleSpan],
        in text: String
    ) -> [TemplateEditorModuleSpan] {

        let textLength =
            (text as NSString).length

        var nextCursor = 0

        return moduleSpans
            .sorted {
                if $0.range.location
                    == $1.range.location {
                    return $0.range.length
                        < $1.range.length
                }

                return $0.range.location
                    < $1.range.location
            }
            .compactMap { span in
                let safeRange =
                    clampedRange(
                        span.range,
                        length: textLength
                    )

                guard safeRange.length > 0,
                      safeRange.location
                      >= nextCursor
                else {
                    return nil
                }

                nextCursor =
                    safeRange.location
                    + safeRange.length

                return TemplateEditorModuleSpan(
                    token: span.token,
                    range: safeRange
                )
            }
    }

    private static func clampedRange(
        _ range: NSRange,
        in text: String
    ) -> NSRange {

        clampedRange(
            range,
            length: (text as NSString).length
        )
    }

    private static func clampedRange(
        _ range: NSRange,
        length: Int
    ) -> NSRange {

        let location =
            min(
                max(range.location, 0),
                length
            )

        let spanLength =
            min(
                max(range.length, 0),
                length - location
            )

        return NSRange(
            location: location,
            length: spanLength
        )
    }
}
#endif

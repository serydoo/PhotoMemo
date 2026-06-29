import Foundation

enum InlineContentTextComposer {

    enum PieceKind: Hashable {
        case text
        case token
        case separator
        case lineBreak
    }

    struct Piece: Hashable {
        let kind: PieceKind
        let value: String

        init(
            kind: PieceKind,
            value: String
        ) {
            self.kind = kind
            self.value = value
        }
    }

    static func compose(
        _ pieces: [Piece]
    ) -> String {
        var output = ""
        var previousKind: PieceKind?

        for piece in pieces {
            let value =
                normalizedValue(
                    for: piece
                )

            guard !value.isEmpty else {
                continue
            }

            if let previousKind,
               shouldInsertSpace(
                between: previousKind,
                and: piece.kind,
                currentValue: value
               ) {
                output += " "
            }

            output += value
            previousKind = piece.kind
        }

        return output
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            )
    }

    private static func normalizedValue(
        for piece: Piece
    ) -> String {
        switch piece.kind {
        case .text,
             .token,
             .separator:
            return piece.value.trimmingCharacters(
                in: .whitespacesAndNewlines
            )
        case .lineBreak:
            return "\n"
        }
    }

    private static func shouldInsertSpace(
        between previousKind: PieceKind,
        and currentKind: PieceKind,
        currentValue: String
    ) -> Bool {
        guard previousKind != .lineBreak,
              currentKind != .lineBreak,
              currentKind != .separator,
              previousKind != .separator
        else {
            return false
        }

        return previousKind == .token
            && currentKind == .token
            && !startsWithClosingPunctuation(currentValue)
    }

    private static func startsWithClosingPunctuation(
        _ value: String
    ) -> Bool {
        guard let first = value.first else {
            return false
        }

        return [
            "!",
            "?",
            ",",
            ".",
            ";",
            ":",
            "！",
            "？",
            "，",
            "。",
            "；",
            "：",
            "、",
            ")",
            "]",
            "}",
            "）",
            "】",
            "」",
            "』"
        ].contains(first)
    }
}

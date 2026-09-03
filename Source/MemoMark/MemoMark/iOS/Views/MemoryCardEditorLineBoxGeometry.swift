#if !MEMOMARK_SHARE_EXTENSION
import Foundation

/// Content-independent geometry for the Card Content Editor's one-line box.
///
/// TextKit may otherwise move a paragraph's shared baseline when an attachment
/// contributes a larger ascent or descent than ordinary glyphs. This model
/// keeps the baseline owned by the canonical line box and positions the
/// attachment canvas inside that box without making attachment presence part
/// of the baseline calculation.
enum MemoryCardEditorLineBoxGeometry {

    static func textBaselineOffset(
        lineHeight: CGFloat,
        fontLineHeight: CGFloat
    ) -> CGFloat {
        max(0, (lineHeight - fontLineHeight) / 2)
    }

    static func baseline(
        lineHeight: CGFloat,
        fontDescender: CGFloat
    ) -> CGFloat {
        lineHeight + fontDescender
    }

    static func attachmentOriginY(
        lineHeight: CGFloat,
        attachmentHeight: CGFloat,
        fontDescender: CGFloat
    ) -> CGFloat {
        let centeredAttachmentBottom =
            (lineHeight + attachmentHeight) / 2
        return baseline(
            lineHeight: lineHeight,
            fontDescender: fontDescender
        ) - centeredAttachmentBottom
    }
}
#endif

#if os(macOS)
import AppKit
import Testing
@testable import MemoMark

@Suite("V1 editor TextKit line-box geometry")
@MainActor
struct MemoryCardEditorLineBoxGeometryTests {

    private enum ProbeRun {
        case text(String)
        case attachment
    }

    private struct TextMeasurement {
        let baselineY: CGFloat
        let typographicCenterY: CGFloat
        let lineFragmentCenterY: CGFloat
        let lineFragmentHeight: CGFloat
    }

    private struct LayoutProbe {
        let textMeasurements: [TextMeasurement]
    }

    @Test(
        "plain and mixed lines keep one ordinary-text baseline",
        arguments: [
            CGFloat(10), 12, 15, 18, 22, 26, 32, 40
        ]
    )
    func plainAndMixedLinesKeepOneOrdinaryTextBaseline(
        fontSize: CGFloat
    ) {
        let textSamples = ["T", "文", "，", "A文+"]

        for sample in textSamples {
            let plain = layoutProbe(
                fontSize: fontSize,
                runs: [.text(sample)]
            )
            let mixedCases: [[ProbeRun]] = [
                [.attachment, .text(sample)],
                [.text(sample), .attachment],
                [.text(sample), .attachment, .text(sample)]
            ]

            let reference = plain.textMeasurements[0]
            for runs in mixedCases {
                let mixed = layoutProbe(
                    fontSize: fontSize,
                    runs: runs
                )

                for measurement in mixed.textMeasurements {
                    #expect(
                        abs(measurement.baselineY - reference.baselineY) <= 0.25,
                        """
                        Attachment presence or order moved the TextKit baseline.
                        fontSize=\(fontSize), sample=\(sample)
                        plain=\(reference.baselineY), mixed=\(measurement.baselineY)
                        """
                    )
                    #expect(
                        abs(
                            measurement.lineFragmentHeight
                                - reference.lineFragmentHeight
                        ) <= 0.25,
                        """
                        Attachment presence or order changed the canonical line box.
                        fontSize=\(fontSize), sample=\(sample)
                        plain=\(reference.lineFragmentHeight), mixed=\(measurement.lineFragmentHeight)
                        """
                    )
                }
            }

            for measurement in plain.textMeasurements {
                #expect(
                    abs(
                        measurement.typographicCenterY
                            - measurement.lineFragmentCenterY
                    ) <= 0.5,
                    """
                    Ordinary text is not vertically centered in the canonical line box.
                    fontSize=\(fontSize), sample=\(sample)
                    textCenter=\(measurement.typographicCenterY)
                    lineCenter=\(measurement.lineFragmentCenterY)
                    """
                )
            }
        }
    }

    private func layoutProbe(
        fontSize: CGFloat,
        runs: [ProbeRun]
    ) -> LayoutProbe {
        let storage = NSTextStorage()
        let layoutManager = NSLayoutManager()
        let container = NSTextContainer(
            size: CGSize(width: 1_000, height: 200)
        )
        container.lineFragmentPadding = 0
        container.maximumNumberOfLines = 1
        layoutManager.addTextContainer(container)
        storage.addLayoutManager(layoutManager)

        let font = NSFont.systemFont(ofSize: fontSize)
        let attachmentHeight: CGFloat = 28
        let lineHeight = max(
            attachmentHeight,
            ceil(layoutManager.defaultLineHeight(for: font))
        )
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.minimumLineHeight = lineHeight
        paragraphStyle.maximumLineHeight = lineHeight
        let textBaselineOffset =
            MemoryCardEditorLineBoxGeometry.textBaselineOffset(
                lineHeight: lineHeight,
                fontLineHeight: font.ascender - font.descender
            )
        let textAttributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .paragraphStyle: paragraphStyle,
            .baselineOffset: textBaselineOffset
        ]

        let value = NSMutableAttributedString()
        var textCharacterIndices: [Int] = []
        for run in runs {
            switch run {
            case let .text(text):
                textCharacterIndices.append(value.length)
                value.append(
                    NSAttributedString(
                        string: text,
                        attributes: textAttributes
                    )
                )
            case .attachment:
                value.append(
                    attributedAttachment(
                        font: font,
                        lineHeight: lineHeight,
                        height: attachmentHeight
                    )
                )
            }
        }
        value.append(
            NSAttributedString(
                string: "\u{200B}",
                attributes: textAttributes
            )
        )
        value.addAttribute(
            .paragraphStyle,
            value: paragraphStyle,
            range: NSRange(location: 0, length: value.length)
        )

        storage.setAttributedString(value)
        layoutManager.ensureLayout(for: container)

        return LayoutProbe(
            textMeasurements: textCharacterIndices.map { characterIndex in
                let glyphIndex = layoutManager.glyphIndexForCharacter(
                    at: characterIndex
                )
                let lineFragment = layoutManager.lineFragmentRect(
                    forGlyphAt: glyphIndex,
                    effectiveRange: nil
                )
                let glyphBaselineY =
                    lineFragment.minY
                    + layoutManager.location(
                        forGlyphAt: glyphIndex
                    ).y
                return TextMeasurement(
                    baselineY: glyphBaselineY,
                    typographicCenterY:
                        glyphBaselineY
                        - (font.ascender + font.descender) / 2,
                    lineFragmentCenterY: lineFragment.midY,
                    lineFragmentHeight: lineFragment.height
                )
            }
        )
    }

    private func attributedAttachment(
        font: NSFont,
        lineHeight: CGFloat,
        height: CGFloat
    ) -> NSAttributedString {
        let size = CGSize(width: 40, height: height)
        let image = NSImage(size: size)
        let attachment = NSTextAttachment()
        attachment.attachmentCell = NSTextAttachmentCell(
            imageCell: image
        )
        attachment.bounds = CGRect(
            x: 0,
            y: MemoryCardEditorLineBoxGeometry.attachmentOriginY(
                lineHeight: lineHeight,
                attachmentHeight: height,
                fontDescender: font.descender
            ),
            width: size.width,
            height: size.height
        )
        return NSAttributedString(attachment: attachment)
    }
}
#endif

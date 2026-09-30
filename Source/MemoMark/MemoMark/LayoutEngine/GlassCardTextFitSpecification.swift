import CoreGraphics
import CoreText
import Foundation
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

/// Research fit result shared by the drawing view and its review diagnostics.
/// Uses the system font, bounded scaling and the whole UTF-16 range. It never
/// modifies the authored string or treats a partially fitted frame as success.
enum GlassCardTextFitSpecification {
    enum Outcome: Equatable {
        case empty
        case fits
        case overflow
    }

    struct Result: Equatable {
        let pointSize: CGFloat
        let outcome: Outcome
    }

    static func resolve(
        text: String,
        frame: CGSize,
        pointSize: CGFloat,
        isPrimary: Bool,
        lineLimit: Int,
        minimumScale: CGFloat
    ) -> Result {
        let base = max(pointSize, 1)
        if text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return Result(pointSize: base, outcome: .empty)
        }
        guard frame.width > 0, frame.height > 0, lineLimit > 0 else {
            return Result(pointSize: base, outcome: .overflow)
        }
        let lower = base * min(max(minimumScale, 0.01), 1)
        func fits(_ size: CGFloat) -> Bool {
            let font = font(pointSize: size, isPrimary: isPrimary)
            let attributed = NSAttributedString(string: text, attributes: [
                kCTFontAttributeName as NSAttributedString.Key: font
            ])
            let setter = CTFramesetterCreateWithAttributedString(attributed)
            let path = CGPath(rect: CGRect(origin: .zero, size: frame), transform: nil)
            let measured = CTFramesetterCreateFrame(setter, CFRange(location: 0, length: attributed.length), path, nil)
            let visible = CTFrameGetVisibleStringRange(measured)
            let lines = CTFrameGetLines(measured) as NSArray
            let widthsFit = (lines as! [CTLine]).allSatisfy { line in
                CTLineGetTypographicBounds(line, nil, nil, nil) <= frame.width
            }
            return visible.location == 0 && visible.length == attributed.length
                && lines.count <= lineLimit && widthsFit
        }
        if fits(base) { return Result(pointSize: base, outcome: .fits) }
        guard fits(lower) else { return Result(pointSize: lower, outcome: .overflow) }
        var low = lower
        var high = base
        for _ in 0..<12 {
            let middle = (low + high) / 2
            if fits(middle) { low = middle } else { high = middle }
        }
        // Round down so drawing cannot cross the fitted boundary through
        // fractional font-size rounding.
        return Result(pointSize: max(lower, floor(low * 64) / 64), outcome: .fits)
    }

    static func font(pointSize: CGFloat, isPrimary: Bool) -> CTFont {
#if canImport(UIKit)
        let systemFont = UIFont.systemFont(ofSize: pointSize, weight: isPrimary ? .semibold : .medium)
#elseif canImport(AppKit)
        let systemFont = NSFont.systemFont(ofSize: pointSize, weight: isPrimary ? .semibold : .medium)
#endif
        return systemFont as CTFont
    }
}

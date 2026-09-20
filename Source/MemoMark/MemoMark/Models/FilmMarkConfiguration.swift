import Foundation

/// A stable identifier for a FilmMark font candidate.
///
/// These identifiers deliberately do not claim that a font is already bundled
/// or production-approved. Font registration, license evidence, and fallback
/// resolution belong to the future renderer adapter.
enum FilmMarkFontID: String, Codable, CaseIterable, Hashable {
    case systemMonospaced
    case ibmPlexMono
    case spaceMono
    case jetBrainsMono

    /// Persisted candidates remain decodable, but are not selectable until
    /// bundled assets, licenses, CoreText measurement, SwiftUI rendering, and
    /// CJK fallback are verified together.
    static let userSelectableCases: [Self] = [.systemMonospaced]

    /// Preserve historical IDs in storage; resolve all unbundled candidates
    /// to the same verified face for both measurement and drawing.
    var resolvedForRendering: Self { .systemMonospaced }
    var resolvedPostScriptName: String { "Menlo" }
}

/// A fixed-precision font size expressed as a ratio of the resolved canvas
/// short edge. The encoded property name remains width-compatible with the
/// first FM prototype for durable decoding.
struct FilmMarkFontSize: Codable, Hashable {

    private static let unitsPerWhole = 10_000
    private static let minimumRatio: CGFloat = 0.008
    private static let maximumRatio: CGFloat = 0.060

    /// The existing prominent size is the visual baseline for the editor's
    /// continuous control. Keeping it at the midpoint preserves the effective
    /// default while allowing deliberate refinement in either direction.
    private static let sliderMinimumRatio: CGFloat = 0.014
    private static let sliderMidpointRatio: CGFloat = 0.032
    private static let sliderMaximumRatio: CGFloat = 0.050

    let canvasWidthRatioUnits: Int

    init(relativeToCanvasWidth ratio: CGFloat = 0.018) {
        let finiteRatio = ratio.isFinite ? ratio : 0.018
        let bounded = min(max(finiteRatio, Self.minimumRatio), Self.maximumRatio)
        let scaled = bounded * CGFloat(Self.unitsPerWhole)
        self.canvasWidthRatioUnits = Int(scaled.rounded())
    }

    private init(ratioUnits: Int) {
        self.canvasWidthRatioUnits = min(
            max(
                ratioUnits,
                Int(Self.minimumRatio * CGFloat(Self.unitsPerWhole))
            ),
            Int(Self.maximumRatio * CGFloat(Self.unitsPerWhole))
        )
    }

    private enum CodingKeys: String, CodingKey {
        case canvasWidthRatioUnits
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            ratioUnits: try container.decode(
                Int.self,
                forKey: .canvasWidthRatioUnits
            )
        )
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(
            canvasWidthRatioUnits,
            forKey: .canvasWidthRatioUnits
        )
    }

    var relativeToCanvasWidth: CGFloat {
        CGFloat(canvasWidthRatioUnits) / CGFloat(Self.unitsPerWhole)
    }

    static let compact = FilmMarkFontSize(relativeToCanvasWidth: 0.014)
    static let standard = FilmMarkFontSize(relativeToCanvasWidth: 0.018)
    static let large = FilmMarkFontSize(relativeToCanvasWidth: 0.024)
    static let prominent = FilmMarkFontSize(relativeToCanvasWidth: 0.032)

    /// Maps the durable size ratio to the UI-only slider coordinate. The
    /// mapping is intentionally piecewise: the established `.prominent`
    /// result is centred, instead of becoming the rightmost selectable point.
    static func sliderPosition(for fontSize: Self) -> CGFloat {
        let ratio = min(
            max(fontSize.relativeToCanvasWidth, sliderMinimumRatio),
            sliderMaximumRatio
        )
        if ratio <= sliderMidpointRatio {
            return 0.5 * (
                ratio - sliderMinimumRatio
            ) / (sliderMidpointRatio - sliderMinimumRatio)
        }
        return 0.5 + 0.5 * (
            ratio - sliderMidpointRatio
        ) / (sliderMaximumRatio - sliderMidpointRatio)
    }

    /// Creates the fixed-precision durable value selected by the editor's
    /// continuous slider. This does not introduce a second stored scale.
    static func fontSize(forSliderPosition position: CGFloat) -> Self {
        let boundedPosition = min(max(position, 0), 1)
        let ratio: CGFloat
        if boundedPosition <= 0.5 {
            ratio = sliderMinimumRatio
                + (boundedPosition / 0.5)
                * (sliderMidpointRatio - sliderMinimumRatio)
        } else {
            ratio = sliderMidpointRatio
                + ((boundedPosition - 0.5) / 0.5)
                * (sliderMaximumRatio - sliderMidpointRatio)
        }
        return Self(relativeToCanvasWidth: ratio)
    }
}

enum FilmMarkSubstrate: String, Codable, CaseIterable, Hashable {
    case none
    case paperWhite
    case systemGlass
    case softShadow
    case translucentLabel

    /// The stable first-party choices shown in the editor. The legacy label
    /// remains decodable but is not offered as a new selection.
    static let userSelectableCases: [Self] = [
        .none,
        .paperWhite,
        .systemGlass,
        .softShadow
    ]

    /// All currently selectable substrates have a deterministic static recipe.
    /// `systemGlass` intentionally means a static glass-like treatment rather
    /// than SwiftUI Material, so preview, still export, and Live Photo output
    /// can share the same appearance contract.
    var deterministicExportKind: Self {
        self
    }
}

/// The only user-editable appearance payload in this slice. Alpha lives in
/// the color value; there is intentionally no second opacity field that could
/// disagree with it.
struct FilmMarkAppearanceDraft: Codable, Hashable {

    var fontID: FilmMarkFontID
    var fontSize: FilmMarkFontSize
    var color: FilmMarkRGBAColor
    var substrate: FilmMarkSubstrate

    init(
        fontID: FilmMarkFontID = .systemMonospaced,
        fontSize: FilmMarkFontSize = .standard,
        color: FilmMarkRGBAColor = .amber,
        substrate: FilmMarkSubstrate = .none
    ) {
        self.fontID = fontID
        self.fontSize = fontSize
        self.color = color
        self.substrate = substrate
    }
}

/// Style-owned settings kept separate from the legacy template payload. This
/// is the future persistence carrier for the FM route; it does not change the
/// existing Classic White or Minimal template schemas.
struct FilmMarkConfiguration: Codable, Hashable {

    var appearance: FilmMarkAppearanceDraft
    var placement: FilmMarkPlacementDraft
    var safeAreaInsets: FilmMarkNormalizedInsets

    init(
        appearance: FilmMarkAppearanceDraft = .init(),
        placement: FilmMarkPlacementDraft = .init(anchor: .bottomRight),
        safeAreaInsets: FilmMarkNormalizedInsets = .default
    ) {
        self.appearance = appearance
        self.placement = placement
        self.safeAreaInsets = safeAreaInsets
    }

    static let `default` = FilmMarkConfiguration()
}

/// The two intentional starting positions for FilmMark.
///
/// FilmMark stores one placement at a time. These anchors are starting points,
/// not two simultaneous output objects.
enum FilmMarkPlacementAnchor: String, Codable, CaseIterable, Hashable {
    case bottomLeft
    case bottomRight
}

enum FilmMarkPlacementDirection: Hashable {
    case up
    case down
    case left
    case right
}

/// A photo-relative displacement. Values are independent of preview pixels and
/// are persisted as fixed-point units so repeated nudges cannot accumulate
/// binary floating-point drift.
struct FilmMarkNormalizedOffset: Codable, Hashable {

    private static let unitsPerWhole = 10_000

    let xUnits: Int
    let yUnits: Int

    init(x: CGFloat = 0, y: CGFloat = 0) {
        self.xUnits = Self.quantized(x)
        self.yUnits = Self.quantized(y)
    }

    private init(xUnits: Int, yUnits: Int) {
        self.xUnits = min(max(xUnits, -Self.unitsPerWhole), Self.unitsPerWhole)
        self.yUnits = min(max(yUnits, -Self.unitsPerWhole), Self.unitsPerWhole)
    }

    private enum CodingKeys: String, CodingKey {
        case xUnits
        case yUnits
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            xUnits: try container.decode(Int.self, forKey: .xUnits),
            yUnits: try container.decode(Int.self, forKey: .yUnits)
        )
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(xUnits, forKey: .xUnits)
        try container.encode(yUnits, forKey: .yUnits)
    }

    var x: CGFloat {
        CGFloat(xUnits) / CGFloat(Self.unitsPerWhole)
    }

    var y: CGFloat {
        CGFloat(yUnits) / CGFloat(Self.unitsPerWhole)
    }

    private static func quantized(_ value: CGFloat) -> Int {
        guard value.isFinite else { return 0 }
        let scaled = value * CGFloat(unitsPerWhole)
        let bounded = min(max(scaled, -CGFloat(unitsPerWhole)), CGFloat(unitsPerWhole))
        return Int(bounded.rounded())
    }
}

/// The safe area is expressed as fractions of the resolved photo canvas.
struct FilmMarkNormalizedInsets: Codable, Hashable {

    let top: CGFloat
    let left: CGFloat
    let bottom: CGFloat
    let right: CGFloat

    static let `default` = FilmMarkNormalizedInsets(
        top: 0.04,
        left: 0.04,
        bottom: 0.04,
        right: 0.04
    )

    init(
        top: CGFloat,
        left: CGFloat,
        bottom: CGFloat,
        right: CGFloat
    ) {
        self.top = Self.clamped(top)
        self.left = Self.clamped(left)
        self.bottom = Self.clamped(bottom)
        self.right = Self.clamped(right)
    }

    private enum CodingKeys: String, CodingKey {
        case top
        case left
        case bottom
        case right
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            top: try container.decode(CGFloat.self, forKey: .top),
            left: try container.decode(CGFloat.self, forKey: .left),
            bottom: try container.decode(CGFloat.self, forKey: .bottom),
            right: try container.decode(CGFloat.self, forKey: .right)
        )
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(top, forKey: .top)
        try container.encode(left, forKey: .left)
        try container.encode(bottom, forKey: .bottom)
        try container.encode(right, forKey: .right)
    }

    private static func clamped(_ value: CGFloat) -> CGFloat {
        guard value.isFinite else { return 0 }
        return min(max(value, 0), 1)
    }
}

struct FilmMarkPlacementDraft: Codable, Hashable {

    var anchor: FilmMarkPlacementAnchor
    var normalizedOffset: FilmMarkNormalizedOffset

    init(
        anchor: FilmMarkPlacementAnchor,
        normalizedOffset: FilmMarkNormalizedOffset = .init()
    ) {
        self.anchor = anchor
        self.normalizedOffset = normalizedOffset
    }
}

/// A stable sRGB value for persistence and rendering. SwiftUI Color is kept at
/// the UI boundary so the stored configuration remains platform-independent.
struct FilmMarkRGBAColor: Codable, Hashable {

    let red: Double
    let green: Double
    let blue: Double
    let alpha: Double

    init(red: Double, green: Double, blue: Double, alpha: Double = 1) {
        self.red = Self.clamped(red)
        self.green = Self.clamped(green)
        self.blue = Self.clamped(blue)
        self.alpha = Self.clamped(alpha)
    }

    private enum CodingKeys: String, CodingKey {
        case red
        case green
        case blue
        case alpha
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            red: try container.decode(Double.self, forKey: .red),
            green: try container.decode(Double.self, forKey: .green),
            blue: try container.decode(Double.self, forKey: .blue),
            alpha: try container.decode(Double.self, forKey: .alpha)
        )
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(red, forKey: .red)
        try container.encode(green, forKey: .green)
        try container.encode(blue, forKey: .blue)
        try container.encode(alpha, forKey: .alpha)
    }

    static let amber = FilmMarkRGBAColor(
        red: 1,
        green: 0.59,
        blue: 0.08
    )

    static let white = FilmMarkRGBAColor(
        red: 1,
        green: 1,
        blue: 1
    )

    private static func clamped(_ value: Double) -> Double {
        guard value.isFinite else { return 0 }
        return min(max(value, 0), 1)
    }
}

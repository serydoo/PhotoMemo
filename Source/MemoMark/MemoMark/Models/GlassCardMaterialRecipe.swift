import CoreGraphics

/// Versioned research inputs for the existing transparent-layer compositor.
/// No scene or photo classification participates in choosing these values.
/// This does not establish final color/HDR handling or a production schema.
struct GlassCardMaterialRecipe: Equatable {
    struct RGBA: Equatable {
        let red: Double
        let green: Double
        let blue: Double
        let alpha: Double
    }

    let researchID: String
    let surface: RGBA
    let keyline: RGBA
    let shadow: RGBA
    let keylineWidthToPanelHeight: CGFloat
    let shadowRadiusToPanelHeight: CGFloat
    let shadowOffsetToPanelHeight: CGFloat

    /// Foreground pixels only; the source-dependent system material is composed separately.
    static let foregroundOnly = Self(
        researchID: "glasscard.native.foreground",
        surface: RGBA(red: 0, green: 0, blue: 0, alpha: 0),
        keyline: RGBA(red: 0, green: 0, blue: 0, alpha: 0),
        shadow: RGBA(red: 0, green: 0, blue: 0, alpha: 0),
        keylineWidthToPanelHeight: 0, shadowRadiusToPanelHeight: 0, shadowOffsetToPanelHeight: 0
    )

    static let lightLayerV1 = Self(
        researchID: "glasscard.light-layer.research.v1",
        surface: RGBA(red: 1, green: 1, blue: 1, alpha: 0.28),
        keyline: RGBA(red: 1, green: 1, blue: 1, alpha: 0.34),
        shadow: RGBA(red: 0, green: 0, blue: 0, alpha: 0.12),
        keylineWidthToPanelHeight: 0.006,
        shadowRadiusToPanelHeight: 0.08,
        shadowOffsetToPanelHeight: 0.025
    )

    static let darkLayerV1 = Self(
        researchID: "glasscard.dark-layer.research.v1",
        surface: RGBA(red: 0, green: 0, blue: 0, alpha: 0.42),
        keyline: lightLayerV1.keyline,
        shadow: lightLayerV1.shadow,
        keylineWidthToPanelHeight: lightLayerV1.keylineWidthToPanelHeight,
        shadowRadiusToPanelHeight: lightLayerV1.shadowRadiusToPanelHeight,
        shadowOffsetToPanelHeight: lightLayerV1.shadowOffsetToPanelHeight
    )
}

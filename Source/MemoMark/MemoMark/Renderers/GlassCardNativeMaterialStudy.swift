#if DEBUG && !MEMOMARK_SHARE_EXTENSION
import SwiftUI
import CoreGraphics

/// Native feasibility control only. Geometry and text remain the production Layout's input.
enum GlassCardNativeMaterialStudyMode: String, CaseIterable, Identifiable {
    case production, current, regular, regularDark, clear
    var id: String { rawValue }
}

struct GlassCardNativeMaterialStudyCanvas: View {
    let source: CGImage
    let plan: GlassCardResolvedPresentation
    let mode: GlassCardNativeMaterialStudyMode

    var body: some View {
        if mode == .production {
            GlassCardResolvedCanvas(image: Image(decorative: source, scale: 1), presentation: plan, badge: nil)
        } else {
            ZStack(alignment: .topLeading) {
                Image(decorative: source, scale: 1).resizable()
                    .frame(width: plan.canvasSize.width, height: plan.canvasSize.height)
                if mode == .current {
                    GlassCardOverlayLayer(presentation: plan, badge: nil, recipe: .darkLayerV1, secondaryTextOpacity: 0.96)
                } else {
                    if #available(iOS 26.0, macOS 26.0, *) { panel }
                    GlassCardOverlayLayer(presentation: plan, badge: nil, recipe: foreground, secondaryTextOpacity: 0.96)
                }
            }.frame(width: plan.canvasSize.width, height: plan.canvasSize.height)
        }
    }
    @available(iOS 26.0,macOS 26.0,*)
    private var panel: some View {
        let frame = plan.geometry.panelFrame
        return Color.clear.frame(width:frame.width,height:frame.height)
            .glassEffect(mode == .clear ? .clear : .regular,
                         in:RoundedRectangle(cornerRadius:frame.height*GlassCardLayoutSpecification.layout.cornerRadiusToPanelHeight,style:.continuous))
            .environment(\.colorScheme,mode == .regularDark ? .dark : .light)
            .offset(x:frame.minX,y:frame.minY)
    }
    private var foreground: GlassCardMaterialRecipe {
        let clear = GlassCardMaterialRecipe.RGBA(red:0,green:0,blue:0,alpha:0)
        return .init(researchID:"native.study.foreground",surface:clear,keyline:clear,shadow:clear,
                     keylineWidthToPanelHeight:0,shadowRadiusToPanelHeight:0,shadowOffsetToPanelHeight:0)
    }
}
#endif

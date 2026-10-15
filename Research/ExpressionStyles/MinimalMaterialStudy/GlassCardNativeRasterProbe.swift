import Foundation
import CoreGraphics
import SwiftUI
import ImageIO
import UniformTypeIdentifiers
import Testing
@testable import MemoMark

@Suite struct GlassCardNativeRasterProbe {
    @Test @MainActor func nativeMaterialFullCanvasRasterObservation() throws {
        guard #available(macOS 26.0, *) else { return }
        let size = CGSize(width:1080,height:1440)
        let plan = GlassCardResolvedPresentation.resolve(content:.init(leftTop:"相伴365天",leftBottom:"Our first walk",rightTop:"2026.10.01",rightBottom:"此刻值得记住"),canvasSize:size)
        let clear = GlassCardMaterialRecipe.RGBA(red:0,green:0,blue:0,alpha:0)
        let foreground = GlassCardMaterialRecipe(researchID:"native.foreground",surface:clear,keyline:clear,shadow:clear,
            keylineWidthToPanelHeight:0,shadowRadiusToPanelHeight:0,shadowOffsetToPanelHeight:0)
        var report: [[String:Any]] = []
        for dark in [false,true] {
            let context = try #require(CGContext(data:nil,width:1080,height:1440,bitsPerComponent:8,bytesPerRow:4320,
                space:CGColorSpace(name:CGColorSpace.sRGB)!,bitmapInfo:CGImageAlphaInfo.premultipliedLast.rawValue))
            for y in stride(from:0,to:1440,by:20) {
                for x in stride(from:0,to:1080,by:20) {
                    let c: CGFloat = (x/20+y/20)%2 == 0 ? (dark ? 0.08 : 0.9) : (dark ? 0.25 : 0.5)
                    context.setFillColor(CGColor(red:c,green:c*0.9,blue:c*0.7,alpha:1))
                    context.fill(CGRect(x:x,y:y,width:20,height:20))
                }
            }
            let source = try #require(context.makeImage())
            var outputs: [String:Data] = [:]
            for kind in ["none","current","regular","clear"] {
                let view = ZStack(alignment:.topLeading) {
                    Image(decorative:source,scale:1).resizable().frame(width:size.width,height:size.height)
                    if kind == "current" {
                        GlassCardOverlayLayer(presentation:plan,badge:nil)
                    } else {
                        if kind != "none" {
                            nativePanel(plan:plan,clear:kind == "clear")
                        }
                        GlassCardOverlayLayer(presentation:plan,badge:nil,recipe:foreground,secondaryTextOpacity:0.96)
                    }
                }.frame(width:size.width,height:size.height)
                let renderer = ImageRenderer(content:view)
                renderer.scale = 1
                let image = try #require(renderer.cgImage)
                #expect(image.width == 1080 && image.height == 1440)
                let pixels = try #require(image.dataProvider?.data as Data?)
                outputs[kind] = pixels
                let encoded = NSMutableData()
                let destination = try #require(CGImageDestinationCreateWithData(encoded,UTType.png.identifier as CFString,1,nil))
                CGImageDestinationAddImage(destination,image,nil)
                #expect(CGImageDestinationFinalize(destination))
                Attachment.record(encoded as Data,named:"native-raster-\(dark ? "dark" : "light")-\(kind).png")
            }
            let baseline = try #require(outputs["none"])
            for kind in ["current","regular","clear"] {
                let pixels = try #require(outputs[kind])
                #expect(pixels.count == baseline.count)
                let differences = zip(pixels,baseline).filter { $0 != $1 }.count
                report.append(["background":dark ? "dark" : "light","mode":kind,"differingBytesFromNoMaterial":differences])
            }
        }
        Attachment.record(try JSONSerialization.data(withJSONObject:report,options:[.prettyPrinted,.sortedKeys]),named:"native-raster-observations.json")
    }
    @available(macOS 26.0, *) @MainActor
    private func nativePanel(plan:GlassCardResolvedPresentation,clear:Bool) -> some View {
        let panel = plan.geometry.panelFrame
        return Color.clear.frame(width:panel.width,height:panel.height)
            .glassEffect(clear ? .clear : .regular,in:RoundedRectangle(cornerRadius:panel.height*GlassCardLayoutSpecification.layout.cornerRadiusToPanelHeight,style:.continuous))
            .offset(x:panel.minX,y:panel.minY)
    }
}

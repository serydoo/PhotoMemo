import CoreGraphics
import ImageIO
import UniformTypeIdentifiers
import Foundation
import Testing
@testable import MemoMark

@Suite("GlassCard SDR ImageIO source preparation")
struct GlassCardSDRPreparationProbe {
    private func fixture(orientation:Int,color:CFString=CGColorSpace.sRGB,alpha:UInt8=255,centerBand:Bool=false) throws -> Data {
        let w=60,h=40
        let colors:[[UInt8]]=[[255,0,0],[0,255,0],[0,0,255],[255,255,0]]
        var bytes=[UInt8](repeating:255,count:w*h*4)
        for y in 0..<h { for x in 0..<w {
            let rgb=centerBand ? (x>=10 && x<50 ? [UInt8(255),0,0] : [0,255,0]) : colors[(y>=h/2 ? 2 : 0)+(x>=w/2 ? 1 : 0)]
            let i=(y*w+x)*4
            for c in 0..<3 { bytes[i+c]=UInt8(Int(rgb[c])*Int(alpha)/255) };bytes[i+3]=alpha
        } }
        let image=try #require(CGImage(width:w,height:h,bitsPerComponent:8,bitsPerPixel:32,bytesPerRow:w*4,
            space:CGColorSpace(name:color)!,bitmapInfo:CGBitmapInfo(rawValue:CGImageAlphaInfo.premultipliedLast.rawValue|CGBitmapInfo.byteOrder32Big.rawValue),
            provider:CGDataProvider(data:Data(bytes) as CFData)!,decode:nil,shouldInterpolate:false,intent:.defaultIntent))
        let data=NSMutableData()
        let destination=try #require(CGImageDestinationCreateWithData(data,UTType.tiff.identifier as CFString,1,nil))
        CGImageDestinationAddImage(destination,image,[kCGImagePropertyOrientation:orientation] as CFDictionary)
        #expect(CGImageDestinationFinalize(destination))
        return data as Data
    }
    private func pixels(_ image:CGImage) throws -> [UInt8] {
        var bytes=[UInt8](repeating:0,count:image.width*image.height*4)
        try bytes.withUnsafeMutableBytes { buffer in
            let context=try #require(CGContext(data:buffer.baseAddress,width:image.width,height:image.height,bitsPerComponent:8,bytesPerRow:image.width*4,
                space:CGColorSpace(name:CGColorSpace.sRGB)!,bitmapInfo:CGImageAlphaInfo.premultipliedLast.rawValue|CGBitmapInfo.byteOrder32Big.rawValue))
            context.draw(image,in:CGRect(x:0,y:0,width:image.width,height:image.height))
        }
        return bytes
    }
    @Test("Eight EXIF directions match independently specified asymmetric corners")
    func orientations() throws {
        // Original corners A red / B green / C blue / D yellow. EXIF top-left order.
        let expected=[[0,1,2,3],[1,0,3,2],[3,2,1,0],[2,3,0,1],[0,2,1,3],[2,0,3,1],[3,1,2,0],[1,3,0,2]]
        let colors:[[UInt8]]=[[255,0,0],[0,255,0],[0,0,255],[255,255,0]]
        var records=["orientation,encodedWidth,encodedHeight,normalizedWidth,normalizedHeight"]
        for raw in 1...8 {
            let canvas=raw>=5 ? CGSize(width:40,height:60) : CGSize(width:60,height:40)
            let prepared=try GlassCardSDRResearchPreparation.prepareControlledFixture(fixture(orientation:raw),canvas:canvas,mapping:.exact)
            let report=prepared.report
            #expect(report.orientationRaw==raw && report.encodedSize==CGSize(width:60,height:40))
            #expect(report.normalizedSize==canvas && report.drawRect==CGRect(origin:.zero,size:canvas))
            let image=prepared.source.image,bytes=try pixels(image)
            let points=[(5,5),(image.width-6,5),(5,image.height-6),(image.width-6,image.height-6)]
            for (index,point) in points.enumerated() {
                let offset=(point.1*image.width+point.0)*4
                #expect(Array(bytes[offset..<offset+3])==colors[expected[raw-1][index]])
            }
            records.append("\(raw),60,40,\(image.width),\(image.height)")
        }
        Attachment.record(Data(records.joined(separator:"\n").utf8),named:"sdr-source-orientations.csv")
    }
    @Test("Centered aspect-fill crop is explicit; exact mapping does not silently resize")
    func mapping() throws {
        let data=try fixture(orientation:1,centerBand:true)
        #expect(throws:GlassCardSDRResearchPreparation.Failure.exactSizeMismatch) {
            try GlassCardSDRResearchPreparation.prepareControlledFixture(data,canvas:CGSize(width:40,height:40),mapping:.exact)
        }
        let result=try GlassCardSDRResearchPreparation.prepareControlledFixture(data,canvas:CGSize(width:40,height:40),mapping:.centeredAspectFill)
        #expect(result.report.drawRect==CGRect(x:-10,y:0,width:60,height:40))
        let bytes=try pixels(result.source.image)
        for y in 2..<38 { for x in 2..<38 {
            let i=(y*40+x)*4;#expect(Array(bytes[i..<i+4])==[255,0,0,255])
        } }
        #expect(throws:GlassCardSDRResearchPreparation.Failure.canvasInvalid) {
            try GlassCardSDRResearchPreparation.prepareControlledFixture(data,canvas:CGSize(width:40.5,height:40),mapping:.centeredAspectFill)
        }
        #expect(throws:GlassCardSDRResearchPreparation.Failure.colorNotSRGB) {
            try GlassCardSDRResearchPreparation.prepareControlledFixture(fixture(orientation:1,color:CGColorSpace.displayP3),canvas:CGSize(width:60,height:40),mapping:.exact)
        }
        #expect(throws:GlassCardSDRResearchAdmission.Rejection.containsTransparency) {
            try GlassCardSDRResearchPreparation.prepareControlledFixture(fixture(orientation:1,alpha:128),canvas:CGSize(width:60,height:40),mapping:.exact)
        }
    }
}

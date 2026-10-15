// Research-only source-aware ROI study. Production compositor remains unchanged.
import AppKit
import CoreGraphics
import CoreImage
import Foundation
import SwiftUI
import ImageIO
import UniformTypeIdentifiers
import Testing
@testable import MemoMark

@Suite("GlassCard SDR luminance compression")
struct GlassCardSDRLuminanceProbe {
    private func decode(_ x: Double) -> Double { GlassCardSDRResearchMaterial().decode(x) }
    private func encode(_ x: Double) -> Double { GlassCardSDRResearchMaterial().encode(x) }
    private func mapped(_ rgb: [Double], cap: Double) -> [Double] { GlassCardSDRResearchMaterial().mapped(rgb, cap: cap) }
    @Test("Soft knee is monotonic, bounded and preserves linear RGB direction")
    func curveControls() {
        for cap in [0.10,0.12,0.14] {
            var previous = -1.0
            for n in 0...10000 {
                let y = Double(n)/10000
                let output = cap*tanh(y/cap)
                #expect(output >= previous && output <= cap && output <= y+1e-15)
                previous = output
            }
            #expect(mapped([0,0,0],cap:cap) == [0,0,0])
            for rgb in [[1.0,0,0],[0,1,0],[0,0,1],[0.02,0.01,0.03],[1,0.3,0.1]] {
                let output = mapped(rgb,cap:cap)
                let scale = output.reduce(0,+)/rgb.reduce(0,+)
                #expect(zip(output,rgb).allSatisfy { abs($0-$1*scale) < 1e-14 })
            }
        }
    }
    private func compressed(_ source: CGImage, panel: CGRect, cap: Double) throws -> CGImage { try GlassCardSDRResearchMaterial().compressed(source, panel: panel, cap: cap, cornerRadius: panel.height*GlassCardLayoutSpecification.layout.cornerRadiusToPanelHeight) }
    @Test("Compare same-coordinate core contrast and dark retention through real compositor")
    @MainActor
    func renderedComparison() throws {
        let size = CGSize(width:1920,height:1080)
        let plan = compatiblePresentation(content:.init(leftTop:"HHHHHH",leftBottom:"HHHHHH",rightTop:"HHHHHH",rightBottom:"HHHHHH"),size:size,multiplier:1.4)
        let empty = compatiblePresentation(content:.init(leftTop:"",leftBottom:"",rightTop:"",rightBottom:""),size:size,multiplier:1.4)
        let clear = GlassCardMaterialRecipe.RGBA(red:0,green:0,blue:0,alpha:0)
        let base = GlassCardProductionRenderer.recipe
        func recipe(alpha:Double,mask:Bool=false) -> GlassCardMaterialRecipe {
            .init(researchID:"sdr-knee",surface:.init(red:0,green:0,blue:0,alpha:alpha),keyline:mask ? clear : base.keyline,
                shadow:mask ? clear : base.shadow,keylineWidthToPanelHeight:base.keylineWidthToPanelHeight,
                shadowRadiusToPanelHeight:base.shadowRadiusToPanelHeight,shadowOffsetToPanelHeight:base.shadowOffsetToPanelHeight)
        }
        let mask = try layer(plan,recipe:recipe(alpha:0,mask:true),opacity:0.96)
        var rows = ["pattern,candidate,slot,corePixels,minimum,p10,backgroundMean"]
        let patterns = ["black","gray32","gray128","white","red","green","blue","bright-checker","gradient"]
        for pattern in patterns {
            let colors:[String:[UInt8]] = ["black":[0,0,0],"gray32":[32,32,32],"gray128":[128,128,128],"white":[255,255,255],"red":[255,0,0],"green":[0,255,0],"blue":[0,0,255]]
            let source:CGImage
            if let c = colors[pattern] { source = try ImageEdgeAssertionSupport.solidImage(width:1920,height:1080,red:c[0],green:c[1],blue:c[2]) }
            else { source = try texture(size:size,pattern:pattern) }
            let blurred = try blurredSource(source,panel:plan.geometry.panelFrame,radius:plan.geometry.panelFrame.height*0.025)
            #expect(blurred.outsideDifference == 0 && blurred.haloDifference <= 1)
            for cap in [0.0,0.10,0.12,0.14] {
                let candidate = cap == 0 ? "fixed-056" : "knee-\(cap)"
                let photo = cap == 0 ? blurred.image : try compressed(blurred.image,panel:plan.geometry.panelFrame,cap:cap)
                let material = recipe(alpha:cap == 0 ? 0.56 : 0)
                func composite(_ p:GlassCardResolvedPresentation) throws -> CGImage {
                    let image = try layer(p,recipe:material,opacity:0.96)
                    let artifact = try PresentationArtifact(canvasSize:size,photoFrame:CGRect(origin:.zero,size:size),layers:[.init(frame:plan.artifactOverlayFrame,image:image,zIndex:100)],canvasBackground:.transparent)
                    return try #require(MemoMarkRenderedImageArtifactGuard.composingSourcePhoto(photo,with:artifact))
                }
                let output = try composite(plan), background = try composite(empty)
                for (index,slot) in plan.slots.enumerated() {
                    let region = slot.frame.offsetBy(dx:plan.geometry.panelFrame.minX,dy:plan.geometry.panelFrame.minY).integral
                    let front = try rgba(try #require(output.cropping(to:region))), back = try rgba(try #require(background.cropping(to:region)))
                    let coverage = try rgba(try #require(mask.cropping(to:region.offsetBy(dx:0,dy:-plan.overlayFrame.minY))))
                    var contrasts:[Double] = []
                    for i in stride(from:0,to:front.count,by:4) where Double(coverage[i+3]) >= 0.9*0.96*255 {
                        let f=luma(front,i),b=luma(back,i);contrasts.append((max(f,b)+0.05)/(min(f,b)+0.05))
                    }
                    contrasts.sort();#expect(!contrasts.isEmpty)
                    let mean = stride(from:0,to:back.count,by:4).map { luma(back,$0) }.reduce(0,+)/Double(back.count/4)
                    rows.append("\(pattern),\(candidate),\(index),\(contrasts.count),\(try #require(contrasts.first)),\(contrasts[Int(Double(contrasts.count-1)*0.1)]),\(mean)")
                }
                if pattern == "gradient" || pattern == "bright-checker" {
                    Attachment.record(try png(try #require(output.cropping(to:plan.geometry.panelFrame.integral))),named:"sdr-\(pattern)-\(candidate).png")
                }
            }
        }
        #expect(rows.count == 145)
        Attachment.record(Data(rows.joined(separator:"\n").utf8),named:"sdr-luminance.csv")
    }
    @Test("Quantization and bundled-photo calibration")
    @MainActor
    func colorAndCalibration() throws {
        var maxDirectionError = 0.0
        for r in stride(from:0,through:255,by:17) {
            for g in stride(from:0,through:255,by:17) {
                for b in stride(from:0,through:255,by:17) {
                    let rgb = [r,g,b].map { decode(Double($0)/255) }
                    let ideal = mapped(rgb,cap:0.12)
                    let actual = ideal.map { decode((encode($0)*255).rounded()/255) }
                    let sum = ideal.reduce(0,+), quantizedSum = actual.reduce(0,+)
                    if sum > 0 && quantizedSum > 0 {
                        for c in 0..<3 { maxDirectionError=max(maxDirectionError,abs(ideal[c]/sum-actual[c]/quantizedSum)) }
                    }
                }
            }
        }
        #expect(maxDirectionError < 0.02)
        Attachment.record(Data("{\"cap\":0.12,\"sampleCount\":4096,\"maxNormalizedLinearRGBDirectionError\":\(maxDirectionError)}".utf8),named:"sdr-color-controls.json")
        let raw = try #require(NSImage(named:ConfigurationPreviewBackground.minimal.assetName(forOrientation:.landscape))?.cgImage(forProposedRect:nil,context:nil,hints:nil))
        let size = try #require(ConfigurationPreviewBackground.glassCardPixelSize(for:.landscape))
        let color=CGColorSpace(name:CGColorSpace.sRGB)!
        func context(_ w:Int,_ h:Int) throws -> CGContext {
            try #require(CGContext(data:nil,width:w,height:h,bitsPerComponent:8,bytesPerRow:w*4,space:color,bitmapInfo:CGImageAlphaInfo.premultipliedLast.rawValue|CGBitmapInfo.byteOrder32Big.rawValue))
        }
        let normalized=try context(Int(size.width),Int(size.height));normalized.interpolationQuality = .high;normalized.draw(raw,in:CGRect(origin:.zero,size:size))
        let source=try #require(normalized.makeImage())
        let plan=compatiblePresentation(content:.init(leftTop:"一起走过的秋天",leftBottom:"相伴第365天",rightTop:"2026.10.01",rightBottom:"今天，也值得记住"),size:size,multiplier:1.4)
        #expect(!plan.isContentOverflowing)
        let blurred=try blurredSource(source,panel:plan.geometry.panelFrame,radius:plan.geometry.panelFrame.height*0.025)
        let base=GlassCardProductionRenderer.recipe
        let displayWidth=600, displayHeight=Int((600*size.height/size.width).rounded())
        let comparison=try context(displayWidth,displayHeight*2)
        for (index,cap) in [0.0,0.12].enumerated() {
            let photo=cap == 0 ? blurred.image : try compressed(blurred.image,panel:plan.geometry.panelFrame,cap:cap)
            let recipe=GlassCardMaterialRecipe(researchID:"sdr-calibration",surface:.init(red:0,green:0,blue:0,alpha:cap == 0 ? 0.56 : 0),keyline:base.keyline,shadow:base.shadow,keylineWidthToPanelHeight:base.keylineWidthToPanelHeight,shadowRadiusToPanelHeight:base.shadowRadiusToPanelHeight,shadowOffsetToPanelHeight:base.shadowOffsetToPanelHeight)
            let overlay=try layer(plan,recipe:recipe,opacity:0.96)
            let artifact=try PresentationArtifact(canvasSize:size,photoFrame:CGRect(origin:.zero,size:size),layers:[.init(frame:plan.artifactOverlayFrame,image:overlay,zIndex:100)],canvasBackground:.transparent)
            let output=try #require(MemoMarkRenderedImageArtifactGuard.composingSourcePhoto(photo,with:artifact))
            comparison.interpolationQuality = .high
            comparison.draw(output,in:CGRect(x:0,y:(1-index)*displayHeight,width:displayWidth,height:displayHeight))
        }
        Attachment.record(try png(try #require(comparison.makeImage())),named:"sdr-calibration-fixed-above-knee012-below.png")
    }
    @Test("Prepared ImageIO source flows through ROI, soft knee and real artifact composition")
    @MainActor
    func preparedComposition() throws {
        let rawSize=CGSize(width:384,height:216)
        let raw=try texture(size:rawSize,pattern:"bright-checker")
        let data=NSMutableData()
        let destination=try #require(CGImageDestinationCreateWithData(data,UTType.tiff.identifier as CFString,1,nil))
        CGImageDestinationAddImage(destination,raw,[kCGImagePropertyOrientation:6] as CFDictionary)
        #expect(CGImageDestinationFinalize(destination))
        let canvas=CGSize(width:216,height:384)
        let prepared=try GlassCardSDRResearchPreparation.prepareControlledFixture(data as Data,canvas:canvas,mapping:.exact)
        let plan=compatiblePresentation(content:.init(leftTop:"HHH",leftBottom:"HHH",rightTop:"HHH",rightBottom:"HHH"),size:canvas,multiplier:1.4)
        #expect(!plan.isContentOverflowing)
        let blurred=try blurredSource(prepared.source.image,panel:plan.geometry.panelFrame,radius:plan.geometry.panelFrame.height*0.025)
        #expect(blurred.outsideDifference==0 && blurred.haloDifference<=1)
        let photo=try compressed(blurred.image,panel:plan.geometry.panelFrame,cap:0.12)
        let base=GlassCardProductionRenderer.recipe
        let recipe=GlassCardMaterialRecipe(researchID:"prepared-sdr-knee012",surface:.init(red:0,green:0,blue:0,alpha:0),keyline:base.keyline,shadow:base.shadow,keylineWidthToPanelHeight:base.keylineWidthToPanelHeight,shadowRadiusToPanelHeight:base.shadowRadiusToPanelHeight,shadowOffsetToPanelHeight:base.shadowOffsetToPanelHeight)
        let overlay=try layer(plan,recipe:recipe,opacity:0.96)
        let artifact=try PresentationArtifact(canvasSize:canvas,photoFrame:CGRect(origin:.zero,size:canvas),layers:[.init(frame:plan.artifactOverlayFrame,image:overlay,zIndex:100)],canvasBackground:.transparent)
        let output=try #require(MemoMarkRenderedImageArtifactGuard.composingSourcePhoto(photo,with:artifact))
        #expect(output.width==216 && output.height==384)
        Attachment.record(try png(output),named:"prepared-sdr-composition.png")
        let report="orientation=\(prepared.report.orientationRaw)\nencoded=\(prepared.report.encodedSize)\nnormalized=\(prepared.report.normalizedSize)\ncanvas=\(prepared.report.canvas)\ndrawRect=\(prepared.report.drawRect)\nblurRadius=\(plan.geometry.panelFrame.height*0.025)\ncap=0.12\nprovenance=\(prepared.report.provenance)\nfinalCompositor=existing DeviceRGB; explicit output color remains unverified\n"
        Attachment.record(Data(report.utf8),named:"prepared-sdr-report.txt")
    }
    @Test("Compare explicit sRGB final composition and PNG roundtrip against current compositor")
    @MainActor
    func finalColorComparison() throws {
        let size=CGSize(width:1080,height:608)
        let plan=compatiblePresentation(content:.init(leftTop:"HHHHHH",leftBottom:"HHHHHH",rightTop:"HHHHHH",rightBottom:"HHHHHH"),size:size,multiplier:1.4)
        let empty=compatiblePresentation(content:.init(leftTop:"",leftBottom:"",rightTop:"",rightBottom:""),size:size,multiplier:1.4)
        let base=GlassCardProductionRenderer.recipe,clear=GlassCardMaterialRecipe.RGBA(red:0,green:0,blue:0,alpha:0)
        func recipe(mask:Bool) -> GlassCardMaterialRecipe {
            .init(researchID:"final-sdr",surface:clear,keyline:mask ? clear : base.keyline,shadow:mask ? clear : base.shadow,
                keylineWidthToPanelHeight:base.keylineWidthToPanelHeight,shadowRadiusToPanelHeight:base.shadowRadiusToPanelHeight,shadowOffsetToPanelHeight:base.shadowOffsetToPanelHeight)
        }
        let ink=try layer(plan,recipe:recipe(mask:false),opacity:0.96),backing=try layer(empty,recipe:recipe(mask:false),opacity:0.96)
        let mask=try layer(plan,recipe:recipe(mask:true),opacity:0.96)
        func artifact(_ image:CGImage) throws -> PresentationArtifact {
            try PresentationArtifact(canvasSize:size,photoFrame:CGRect(origin:.zero,size:size),layers:[.init(frame:plan.artifactOverlayFrame,image:image,zIndex:100)],canvasBackground:.transparent)
        }
        var rows=["pattern,slot,oldMinimum,newMinimum,oldP10,newP10,maxByteDifference,pngMaxByteDifference,outsideMaxByteDifference"]
        var records:[String:Any]=["workingColor":"sRGB","overlayColor":ink.colorSpace?.name.map { $0 as String } ?? "unnamed","bitsPerComponent":8,"canvas":"1080x608"]
        let colors:[String:[UInt8]]=["white":[255,255,255],"gray32":[32,32,32],"gray128":[128,128,128],"red":[255,0,0],"green":[0,255,0],"blue":[0,0,255]]
        for pattern in ["white","gray32","gray128","red","green","blue","bright-checker","gradient"] {
            let raw:CGImage
            if let c=colors[pattern] { raw=try ImageEdgeAssertionSupport.solidImage(width:1080,height:608,red:c[0],green:c[1],blue:c[2]) }
            else { raw=try texture(size:size,pattern:pattern) }
            let blurred=try blurredSource(raw,panel:plan.geometry.panelFrame,radius:plan.geometry.panelFrame.height*0.025)
            let photo=try compressed(blurred.image,panel:plan.geometry.panelFrame,cap:0.12)
            let admitted=try GlassCardSDRResearchAdmission.admit(photo,orientation:.up,canvas:size)
            let old=try #require(MemoMarkRenderedImageArtifactGuard.composingSourcePhoto(photo,with:artifact(ink)))
            let oldBack=try #require(MemoMarkRenderedImageArtifactGuard.composingSourcePhoto(photo,with:artifact(backing)))
            let new=try GlassCardSDRResearchCompositor.compose(admitted,artifact:artifact(ink))
            let newBack=try GlassCardSDRResearchCompositor.compose(admitted,artifact:artifact(backing))
            #expect(new.colorSpace?.name==CGColorSpace.sRGB && new.bitsPerComponent==8)
            let oldBytes=try rgba(old),newBytes=try rgba(new),sourceBytes=try rgba(photo)
            let maximum=zip(oldBytes,newBytes).map { abs(Int($0)-Int($1)) }.max()!
            var outside=0
            for i in 0..<(Int(plan.overlayFrame.minY)*1080*4) { outside=max(outside,abs(Int(sourceBytes[i])-Int(newBytes[i]))) }
            #expect(outside==0)
            let encoded=try png(new)
            let pngSource=try #require(CGImageSourceCreateWithData(encoded as CFData,nil))
            let decoded=try #require(CGImageSourceCreateImageAtIndex(pngSource,0,nil))
            #expect(decoded.colorSpace?.name==CGColorSpace.sRGB)
            let decodedBytes=try rgba(decoded)
            let pngDifference=zip(decodedBytes,newBytes).map { abs(Int($0)-Int($1)) }.max()!
            #expect(pngDifference==0)
            records["oldOutputColor"]=old.colorSpace?.name.map { $0 as String } ?? "unnamed"
            records["newOutputColor"]=new.colorSpace?.name.map { $0 as String } ?? "unnamed"
            records["pngDecodedColor"]=decoded.colorSpace?.name.map { $0 as String } ?? "unnamed"
            for (index,slot) in plan.slots.enumerated() {
                let region=slot.frame.offsetBy(dx:plan.geometry.panelFrame.minX,dy:plan.geometry.panelFrame.minY).integral
                let coverage=try rgba(try #require(mask.cropping(to:region.offsetBy(dx:0,dy:-plan.overlayFrame.minY))))
                func contrast(_ front:CGImage,_ background:CGImage) throws -> (Double,Double) {
                    let f=try rgba(try #require(front.cropping(to:region))),b=try rgba(try #require(background.cropping(to:region)))
                    var values:[Double]=[]
                    for i in stride(from:0,to:f.count,by:4) where Double(coverage[i+3])>=0.9*0.96*255 {
                        let a=luma(f,i),z=luma(b,i);values.append((max(a,z)+0.05)/(min(a,z)+0.05))
                    }
                    values.sort();return(try #require(values.first),values[Int(Double(values.count-1)*0.1)])
                }
                let a=try contrast(old,oldBack),b=try contrast(new,newBack)
                rows.append("\(pattern),\(index),\(a.0),\(b.0),\(a.1),\(b.1),\(maximum),\(pngDifference),\(outside)")
            }
            if pattern=="bright-checker" { Attachment.record(encoded,named:"final-sdr-checker.png") }
        }
        #expect(rows.count==33)
        Attachment.record(Data(rows.joined(separator:"\n").utf8),named:"final-sdr-composition.csv")
        Attachment.record(try JSONSerialization.data(withJSONObject:records,options:[.prettyPrinted,.sortedKeys]),named:"final-sdr-color-report.json")
    }
    @Test("Actual writer readback across PNG, JPEG and HEIC with inherited color metadata")
    @MainActor
    func writerReadback() throws {
        let size=CGSize(width:640,height:360)
        let plan=compatiblePresentation(content:.init(leftTop:"HHHHHH",leftBottom:"HHHHHH",rightTop:"HHHHHH",rightBottom:"HHHHHH"),size:size,multiplier:1.4)
        let empty=compatiblePresentation(content:.init(leftTop:"",leftBottom:"",rightTop:"",rightBottom:""),size:size,multiplier:1.4)
        let base=GlassCardProductionRenderer.recipe,clear=GlassCardMaterialRecipe.RGBA(red:0,green:0,blue:0,alpha:0)
        func recipe(mask:Bool) -> GlassCardMaterialRecipe {
            .init(researchID:"writer-sdr",surface:clear,keyline:mask ? clear : base.keyline,shadow:mask ? clear : base.shadow,keylineWidthToPanelHeight:base.keylineWidthToPanelHeight,shadowRadiusToPanelHeight:base.shadowRadiusToPanelHeight,shadowOffsetToPanelHeight:base.shadowOffsetToPanelHeight)
        }
        let raw=try texture(size:size,pattern:"bright-checker")
        let blurred=try blurredSource(raw,panel:plan.geometry.panelFrame,radius:plan.geometry.panelFrame.height*0.025)
        let photo=try compressed(blurred.image,panel:plan.geometry.panelFrame,cap:0.12)
        let admitted=try GlassCardSDRResearchAdmission.admit(photo,orientation:.up,canvas:size)
        func compose(_ p:GlassCardResolvedPresentation) throws -> CGImage {
            let image=try layer(p,recipe:recipe(mask:false),opacity:0.96)
            let artifact=try PresentationArtifact(canvasSize:size,photoFrame:CGRect(origin:.zero,size:size),layers:[.init(frame:plan.artifactOverlayFrame,image:image,zIndex:100)],canvasBackground:.transparent)
            return try GlassCardSDRResearchCompositor.compose(admitted,artifact:artifact)
        }
        let front=try compose(plan),back=try compose(empty)
        let mask=try layer(plan,recipe:recipe(mask:true),opacity:0.96)
        let sourceProperties:[CFString:Any]=[
            kCGImagePropertyPixelWidth:999,kCGImagePropertyPixelHeight:777,kCGImagePropertyOrientation:6,
            kCGImagePropertyProfileName:"Display P3",
            kCGImagePropertyExifDictionary:[kCGImagePropertyExifColorSpace:65535,kCGImagePropertyExifDateTimeOriginal:"2001:02:03 04:05:06",kCGImagePropertyExifExposureTime:0.01,kCGImagePropertyExifFNumber:2.8],
            kCGImagePropertyGPSDictionary:[kCGImagePropertyGPSLatitude:22.5,kCGImagePropertyGPSLatitudeRef:"N",kCGImagePropertyGPSLongitude:113.9,kCGImagePropertyGPSLongitudeRef:"E"]]
        let folder=FileManager.default.temporaryDirectory.appendingPathComponent("GlassCardWriter-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at:folder,withIntermediateDirectories:true)
        defer { try? FileManager.default.removeItem(at:folder) }
        let writer=MetadataPreservingImageWriter()
        var reports:[[String:Any]]=[]
        var rows=["format,slot,originalMinimum,decodedMinimum,decodedP10,maxByteDifference,meanByteDifference"]
        for ext in ["png","jpg","heic"] {
            var decoded:[CGImage]=[]
            for (index,image) in [front,back].enumerated() {
                let url=folder.appendingPathComponent("\(index).\(ext)")
                _ = try writer.write(cgImage:image,to:url,sourceProperties:sourceProperties,exportDescription:"Controlled SDR fixture",captureDate:Date(timeIntervalSince1970:981173106))
                let source=try #require(CGImageSourceCreateWithURL(url as CFURL,nil))
                let result=try #require(CGImageSourceCreateImageAtIndex(source,0,nil))
                #expect(result.width==640 && result.height==360)
                decoded.append(result)
                if index==0 {
                    let properties=try #require(CGImageSourceCopyPropertiesAtIndex(source,0,nil) as? [CFString:Any])
                    let exif=properties[kCGImagePropertyExifDictionary] as? [CFString:Any] ?? [:]
                    #expect(result.colorSpace?.name==CGColorSpace.sRGB)
                    #expect(exif[kCGImagePropertyExifDateTimeOriginal] as? String == "2001:02:03 04:05:06")
                    let gps=properties[kCGImagePropertyGPSDictionary] as? [CFString:Any] ?? [:]
                    let tiff=properties[kCGImagePropertyTIFFDictionary] as? [CFString:Any] ?? [:]
                    #expect((gps[kCGImagePropertyGPSLatitude] as? NSNumber)?.doubleValue==22.5)
                    #expect((gps[kCGImagePropertyGPSLongitude] as? NSNumber)?.doubleValue==113.9)
                    let orientation=(properties[kCGImagePropertyOrientation] as? NSNumber)?.intValue
                    #expect((orientation ?? 1)==1)
                    reports.append(["format":ext,"decodedColorSpace":result.colorSpace?.name.map { $0 as String } ?? "unnamed",
                        "profileName":properties[kCGImagePropertyProfileName] ?? NSNull(),"orientation":orientation.map { $0 as Any } ?? NSNull(),
                        "exifColorSpace":exif[kCGImagePropertyExifColorSpace] ?? NSNull(),"dateTimeOriginal":exif[kCGImagePropertyExifDateTimeOriginal] ?? NSNull(),
                        "exposureTime":exif[kCGImagePropertyExifExposureTime] ?? NSNull(),"fNumber":exif[kCGImagePropertyExifFNumber] ?? NSNull(),
                        "latitude":gps[kCGImagePropertyGPSLatitude] ?? NSNull(),"longitude":gps[kCGImagePropertyGPSLongitude] ?? NSNull(),
                        "userComment":exif["UserComment" as CFString] ?? NSNull(),"description":tiff[kCGImagePropertyTIFFImageDescription] ?? NSNull()])
                    Attachment.record(try Data(contentsOf:url),named:"writer-sdr.\(ext)")
                }
            }
            let original=try rgba(front),actual=try rgba(decoded[0])
            let differences=zip(original,actual).map { abs(Int($0)-Int($1)) }
            let maxDifference=differences.max()!,mean=Double(differences.reduce(0,+))/Double(differences.count)
            if ext=="png" { #expect(maxDifference==0) }
            for (index,slot) in plan.slots.enumerated() {
                let region=slot.frame.offsetBy(dx:plan.geometry.panelFrame.minX,dy:plan.geometry.panelFrame.minY).integral
                let coverage=try rgba(try #require(mask.cropping(to:region.offsetBy(dx:0,dy:-plan.overlayFrame.minY))))
                func contrast(_ ink:CGImage,_ backing:CGImage) throws -> (Double,Double) {
                    let a=try rgba(try #require(ink.cropping(to:region))),b=try rgba(try #require(backing.cropping(to:region)))
                    var values:[Double]=[]
                    for i in stride(from:0,to:a.count,by:4) where Double(coverage[i+3])>=0.9*0.96*255 {
                        let x=luma(a,i),y=luma(b,i);values.append((max(x,y)+0.05)/(min(x,y)+0.05))
                    }
                    values.sort();return(try #require(values.first),values[Int(Double(values.count-1)*0.1)])
                }
                let before=try contrast(front,back),after=try contrast(decoded[0],decoded[1])
                rows.append("\(ext),\(index),\(before.0),\(after.0),\(after.1),\(maxDifference),\(mean)")
            }
        }
        #expect(rows.count==13)
        Attachment.record(try JSONSerialization.data(withJSONObject:reports,options:[.prettyPrinted,.sortedKeys]),named:"writer-sdr-metadata.json")
        Attachment.record(Data(rows.joined(separator:"\n").utf8),named:"writer-sdr-readback.csv")
    }
    @Test("Isolate inherited EXIF color value from decoded raster color profile")
    @MainActor
    func writerColorTags() throws {
        let folder=FileManager.default.temporaryDirectory.appendingPathComponent("GlassCardColorTags-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at:folder,withIntermediateDirectories:true)
        defer { try? FileManager.default.removeItem(at:folder) }
        let image=try ImageEdgeAssertionSupport.solidImage(width:64,height:64,red:200,green:80,blue:40)
        // Support image helper is normalized explicitly to the selected research output space.
        let bytes=try rgba(image)
        let rgb=try #require(CGImage(width:64,height:64,bitsPerComponent:8,bitsPerPixel:32,bytesPerRow:64*4,
            space:CGColorSpace(name:CGColorSpace.sRGB)!,bitmapInfo:CGBitmapInfo(rawValue:CGImageAlphaInfo.premultipliedLast.rawValue|CGBitmapInfo.byteOrder32Big.rawValue),
            provider:CGDataProvider(data:Data(bytes) as CFData)!,decode:nil,shouldInterpolate:false,intent:.defaultIntent))
        var rows=["format,inputExifColor,outputExifColor,decodedColorSpace,profileName"]
        for ext in ["png","jpg","heic"] { for value in [1,65535] {
            let url=folder.appendingPathComponent("\(value).\(ext)")
            _ = try MetadataPreservingImageWriter().write(cgImage:rgb,to:url,sourceProperties:[kCGImagePropertyProfileName:"Display P3",kCGImagePropertyExifDictionary:[kCGImagePropertyExifColorSpace:value]],exportDescription:"Controlled color tag",captureDate:nil)
            let source=try #require(CGImageSourceCreateWithURL(url as CFURL,nil)),decoded=try #require(CGImageSourceCreateImageAtIndex(source,0,nil))
            let properties=try #require(CGImageSourceCopyPropertiesAtIndex(source,0,nil) as? [CFString:Any])
            let exif=properties[kCGImagePropertyExifDictionary] as? [CFString:Any] ?? [:]
            #expect(decoded.colorSpace?.name==CGColorSpace.sRGB)
            rows.append("\(ext),\(value),\((exif[kCGImagePropertyExifColorSpace] as? NSNumber)?.intValue ?? -1),\(decoded.colorSpace?.name.map { $0 as String } ?? "unnamed"),\(properties[kCGImagePropertyProfileName] as? String ?? "missing")")
        } }
        #expect(rows.count==7)
        Attachment.record(Data(rows.joined(separator:"\n").utf8),named:"writer-color-tag-controls.csv")
    }
    @Test("Shared adapter matches assembly, rejects invalid inputs and writes explicit SDR HEIC properties")
    @MainActor
    func sharedAdapter() throws {
        let size=CGSize(width:640,height:360),raw=try texture(size:size,pattern:"bright-checker")
        let encoded=NSMutableData()
        let destination=try #require(CGImageDestinationCreateWithData(encoded,UTType.tiff.identifier as CFString,1,nil))
        CGImageDestinationAddImage(destination,raw,[kCGImagePropertyOrientation:1] as CFDictionary)
        #expect(CGImageDestinationFinalize(destination))
        let prepared=try GlassCardSDRResearchPreparation.prepareControlledFixture(encoded as Data,canvas:size,mapping:.exact)
        let content=GlassCardContentProjection(leftTop:"HHHHHH",leftBottom:"HHHHHH",rightTop:"HHHHHH",rightBottom:"HHHHHH")
        let plan=compatiblePresentation(content:content,size:size,multiplier:1.4)
        let shared=try GlassCardSDRResearchAdapter.render(prepared,plan:plan)
        let material=GlassCardSDRResearchMaterial()
        let blurred=try material.blurredSource(prepared.source.image,panel:plan.geometry.panelFrame,radius:plan.geometry.panelFrame.height*0.025,cornerRadius:plan.geometry.panelFrame.height*GlassCardLayoutSpecification.layout.cornerRadiusToPanelHeight)
        let photo=try material.compressed(blurred.image,panel:plan.geometry.panelFrame,cap:0.12,cornerRadius:plan.geometry.panelFrame.height*GlassCardLayoutSpecification.layout.cornerRadiusToPanelHeight)
        let base=GlassCardProductionRenderer.recipe
        let recipe=GlassCardMaterialRecipe(researchID:"manual-reference",surface:.init(red:0,green:0,blue:0,alpha:0),keyline:base.keyline,shadow:base.shadow,keylineWidthToPanelHeight:base.keylineWidthToPanelHeight,shadowRadiusToPanelHeight:base.shadowRadiusToPanelHeight,shadowOffsetToPanelHeight:base.shadowOffsetToPanelHeight)
        let overlay=try layer(plan,recipe:recipe,opacity:0.96)
        let artifact=try PresentationArtifact(canvasSize:size,photoFrame:CGRect(origin:.zero,size:size),layers:[.init(frame:plan.artifactOverlayFrame,image:overlay,zIndex:100)],canvasBackground:.transparent)
        let reference=try GlassCardSDRResearchCompositor.compose(GlassCardSDRResearchAdmission.admit(photo,orientation:.up,canvas:size),artifact:artifact)
        #expect(try rgba(reference)==rgba(shared.image))
        #expect(shared.sourceReport.orientationRaw==1 && shared.bareHaloBytes>0)
        #expect(throws:GlassCardSDRResearchAdapter.Failure.invalidParameters) {
            try GlassCardSDRResearchAdapter.render(prepared,plan:plan,parameters:.init(blurFraction:.nan,luminanceCap:0.12,secondaryOpacity:0.96))
        }
        let wrong=GlassCardResolvedPresentation.resolve(content:content,canvasSize:CGSize(width:360,height:640))
        #expect(throws:GlassCardSDRResearchAdapter.Failure.mismatchedPlan) { try GlassCardSDRResearchAdapter.render(prepared,plan:wrong) }
        let long=String(repeating:"Long authored content ",count:100)
        let overflow=GlassCardResolvedPresentation.resolve(content:.init(leftTop:long,leftBottom:"",rightTop:"",rightBottom:""),canvasSize:size)
        #expect(overflow.isContentOverflowing)
        #expect(throws:GlassCardSDRResearchAdapter.Failure.overflowingContent) { try GlassCardSDRResearchAdapter.render(prepared,plan:overflow) }
        let inherited:[CFString:Any]=[kCGImagePropertyProfileName:"Display P3",kCGImagePropertyExifDictionary:[kCGImagePropertyExifColorSpace:65535,kCGImagePropertyExifDateTimeOriginal:"2001:02:03 04:05:06"],kCGImagePropertyGPSDictionary:[kCGImagePropertyGPSLatitude:22.5,kCGImagePropertyGPSLatitudeRef:"N"]]
        let properties=try GlassCardSDRResearchAdapter.outputProperties(for:shared.image,source:inherited)
        #expect(properties[kCGImagePropertyProfileName]==nil)
        let exif=properties[kCGImagePropertyExifDictionary] as? [CFString:Any] ?? [:]
        #expect(exif[kCGImagePropertyExifColorSpace] as? Int == 1)
        #expect(exif[kCGImagePropertyExifDateTimeOriginal] as? String == "2001:02:03 04:05:06")
        let url=FileManager.default.temporaryDirectory.appendingPathComponent("GlassCardShared-\(UUID().uuidString).heic")
        defer { try? FileManager.default.removeItem(at:url) }
        _ = try MetadataPreservingImageWriter().write(cgImage:shared.image,to:url,sourceProperties:properties,exportDescription:"Controlled adapter output",captureDate:nil)
        let source=try #require(CGImageSourceCreateWithURL(url as CFURL,nil))
        let decoded=try #require(CGImageSourceCreateImageAtIndex(source,0,nil))
        let read=try #require(CGImageSourceCopyPropertiesAtIndex(source,0,nil) as? [CFString:Any])
        let readExif=read[kCGImagePropertyExifDictionary] as? [CFString:Any] ?? [:]
        #expect(decoded.colorSpace?.name==CGColorSpace.sRGB)
        #expect((readExif[kCGImagePropertyExifColorSpace] as? NSNumber)?.intValue==1)
        #expect(readExif[kCGImagePropertyExifDateTimeOriginal] as? String == "2001:02:03 04:05:06")
        let readGPS=read[kCGImagePropertyGPSDictionary] as? [CFString:Any] ?? [:]
        #expect((readGPS[kCGImagePropertyGPSLatitude] as? NSNumber)?.doubleValue==22.5)
        let p3=try #require(CGContext(data:nil,width:2,height:2,bitsPerComponent:8,bytesPerRow:8,space:CGColorSpace(name:CGColorSpace.displayP3)!,bitmapInfo:CGImageAlphaInfo.premultipliedLast.rawValue)?.makeImage())
        #expect(throws:GlassCardSDRResearchAdapter.Failure.colorMismatch) { try GlassCardSDRResearchAdapter.outputProperties(for:p3,source:inherited) }
        Attachment.record(try png(shared.image),named:"shared-adapter-output.png")
        Attachment.record(try Data(contentsOf:url),named:"shared-adapter-output.heic")
    }
    private func displayResize(_ image:CGImage, size:CGSize) throws -> CGImage {
        let context=try #require(CGContext(data:nil,width:Int(size.width),height:Int(size.height),bitsPerComponent:8,bytesPerRow:Int(size.width)*4,
            space:CGColorSpace(name:CGColorSpace.sRGB)!,bitmapInfo:CGImageAlphaInfo.premultipliedLast.rawValue|CGBitmapInfo.byteOrder32Big.rawValue))
        context.interpolationQuality = .high
        context.draw(image,in:CGRect(origin:.zero,size:size))
        return try #require(context.makeImage())
    }
    @Test("Measure final encoded display sampling with explicit missing-core results")
    @MainActor
    func encodedDisplay() throws {
        let size=CGSize(width:1920,height:1080),raw=try texture(size:size,pattern:"bright-checker")
        let data=NSMutableData(),destination=try #require(CGImageDestinationCreateWithData(data,UTType.tiff.identifier as CFString,1,nil))
        CGImageDestinationAddImage(destination,raw,[kCGImagePropertyOrientation:1] as CFDictionary)
        #expect(CGImageDestinationFinalize(destination))
        let prepared=try GlassCardSDRResearchPreparation.prepareControlledFixture(data as Data,canvas:size,mapping:.exact)
        let folder=FileManager.default.temporaryDirectory.appendingPathComponent("GlassCardDisplay-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at:folder,withIntermediateDirectories:true)
        defer { try? FileManager.default.removeItem(at:folder) }
        let base=GlassCardProductionRenderer.recipe,clear=GlassCardMaterialRecipe.RGBA(red:0,green:0,blue:0,alpha:0)
        let maskRecipe=GlassCardMaterialRecipe(researchID:"display-mask",surface:clear,keyline:clear,shadow:clear,keylineWidthToPanelHeight:base.keylineWidthToPanelHeight,shadowRadiusToPanelHeight:base.shadowRadiusToPanelHeight,shadowOffsetToPanelHeight:base.shadowOffsetToPanelHeight)
        let backingRecipe=GlassCardMaterialRecipe(researchID:"display-background",surface:clear,keyline:base.keyline,shadow:base.shadow,keylineWidthToPanelHeight:base.keylineWidthToPanelHeight,shadowRadiusToPanelHeight:base.shadowRadiusToPanelHeight,shadowOffsetToPanelHeight:base.shadowOffsetToPanelHeight)
        var rows=["glyph,format,width,density,slot,displayFont,corePixels,minimum,p10,sampledInkMass,maxNormalizedAlpha"]
        for (glyph,text) in [("H","HHHHHH"),("zh","相伴365天")] {
            let plan=compatiblePresentation(content:.init(leftTop:text,leftBottom:text,rightTop:text,rightBottom:text),size:size,multiplier:1.4)
            let empty=compatiblePresentation(content:.init(leftTop:"",leftBottom:"",rightTop:"",rightBottom:""),size:size,multiplier:1.4)
            let result=try GlassCardSDRResearchAdapter.render(prepared,plan:plan)
            let backingLayer=try layer(empty,recipe:backingRecipe,opacity:0.96)
            let backingArtifact=try PresentationArtifact(canvasSize:size,photoFrame:CGRect(origin:.zero,size:size),layers:[.init(frame:plan.artifactOverlayFrame,image:backingLayer,zIndex:100)],canvasBackground:.transparent)
            let backing=try GlassCardSDRResearchCompositor.compose(GlassCardSDRResearchAdmission.admit(result.processedSource,orientation:.up,canvas:size),artifact:backingArtifact)
            let maskRenderer=ImageRenderer(content:GlassCardOverlayLayer(presentation:plan,badge:nil,recipe:maskRecipe,secondaryTextOpacity:0.96))
            maskRenderer.scale=1;maskRenderer.proposedSize = .init(size)
            let mask=try #require(maskRenderer.cgImage)
            for ext in ["native","png","jpg","heic","jpg90","jpg100","jpgRaster"] {
                var images=[result.image,backing]
                if ext != "native" {
                    for (index,image) in images.enumerated() {
                        let actualExtension=ext.hasPrefix("jpg") ? "jpg" : ext
                        let fileLabel=ext=="jpgRaster" ? "jpg" : ext
                        let url=folder.appendingPathComponent("\(glyph)-\(index)-\(fileLabel).\(actualExtension)")
                        var properties=try GlassCardSDRResearchAdapter.outputProperties(for:image,source:[:])
                        if ext=="jpg90" { properties[kCGImageDestinationLossyCompressionQuality]=0.9 }
                        if ext=="jpg100" { properties[kCGImageDestinationLossyCompressionQuality]=1.0 }
                        if ext != "jpgRaster" {
                            _ = try MetadataPreservingImageWriter().write(cgImage:image,to:url,sourceProperties:properties,exportDescription:"Controlled encoded display",captureDate:nil)
                        }
                        let source=try #require(CGImageSourceCreateWithURL(url as CFURL,nil))
                        images[index]=try #require(CGImageSourceCreateImageAtIndex(source,0,nil))
                        #expect(images[index].width==1920 && images[index].height==1080 && images[index].colorSpace?.name==CGColorSpace.sRGB)
                        if ext=="jpgRaster" { images[index]=try displayResize(images[index],size:size) }
                    }
                }
                for width:CGFloat in [360,600] { for density:CGFloat in [1,3] {
                    let scale=width*density/size.width,target=CGSize(width:width*density,height:(size.height*scale).rounded())
                    let sampledMask=try displayResize(mask,size:target),front=try displayResize(images[0],size:target),back=try displayResize(images[1],size:target)
                    for (index,slot) in plan.slots.enumerated() {
                        let frame=slot.frame.offsetBy(dx:plan.geometry.panelFrame.minX,dy:plan.geometry.panelFrame.minY)
                        let region=CGRect(x:frame.minX*scale,y:frame.minY*scale,width:frame.width*scale,height:frame.height*scale).integral.intersection(CGRect(origin:.zero,size:target))
                        let coverage=try rgba(try #require(sampledMask.cropping(to:region))),a=try rgba(try #require(front.cropping(to:region))),b=try rgba(try #require(back.cropping(to:region)))
                        var contrasts:[Double]=[]
                        let alpha=stride(from:3,to:coverage.count,by:4).map { Double(coverage[$0])/(255*0.96) }
                        for i in stride(from:0,to:a.count,by:4) where Double(coverage[i+3])>=0.9*0.96*255 {
                            let x=luma(a,i),y=luma(b,i);contrasts.append((max(x,y)+0.05)/(min(x,y)+0.05))
                        }
                        contrasts.sort()
                        let minimum=contrasts.first.map { String($0) } ?? "NA"
                        let p10=contrasts.isEmpty ? "NA" : String(contrasts[Int(Double(contrasts.count-1)*0.1)])
                        let mass=alpha.reduce(0,+)/Double(density*density)
                        rows.append("\(glyph),\(ext),\(width),\(density),\(index),\(slot.fit.pointSize*width/size.width),\(contrasts.count),\(minimum),\(p10),\(mass),\(alpha.max() ?? 0)")
                    }
                    if glyph=="zh" && width==360 && density==3 {
                        Attachment.record(try png(front),named:"encoded-display-\(ext)-zh-360-3x.png")
                    }
                } }
            }
        }
        #expect(rows.count==225)
        Attachment.record(Data(rows.joined(separator:"\n").utf8),named:"encoded-display.csv")
    }
    @Test("Off-main source/pixels match synchronous output and pre-cancellation publishes nothing")
    @MainActor
    func asyncStages() async throws {
        let size=CGSize(width:640,height:360),raw=try texture(size:size,pattern:"bright-checker")
        let data=NSMutableData(),destination=try #require(CGImageDestinationCreateWithData(data,UTType.tiff.identifier as CFString,1,nil))
        CGImageDestinationAddImage(destination,raw,[kCGImagePropertyOrientation:1] as CFDictionary)
        #expect(CGImageDestinationFinalize(destination))
        let bytes=data as Data
        let prepared=try await GlassCardSDRResearchWorker.prepare(bytes,canvas:size,mapping:.exact)
        #expect(prepared.ranOffMainThread)
        let plan=compatiblePresentation(content:.init(leftTop:"HHHHHH",leftBottom:"HHHHHH",rightTop:"HHHHHH",rightBottom:"HHHHHH"),size:size,multiplier:1.4)
        let panel=plan.geometry.panelFrame
        let processed=try await GlassCardSDRResearchWorker.process(.init(source:prepared.prepared.source,panel:panel,
            cornerRadius:panel.height*GlassCardLayoutSpecification.layout.cornerRadiusToPanelHeight,blurRadius:panel.height*0.025,luminanceCap:0.12))
        #expect(processed.ranOffMainThread)
        let synchronous=try GlassCardSDRResearchAdapter.render(prepared.prepared,plan:plan)
        let snapshot=GlassCardSDRResearchCompositor.Snapshot(synchronous.artifact)
        let composed=try await GlassCardSDRResearchWorker.compose(processed.source,snapshot:snapshot)
        #expect(composed.ranOffMainThread)
        #expect(try rgba(composed.image)==rgba(synchronous.image))
        let compositionTask=Task<Void,Error> { @MainActor in _ = try await GlassCardSDRResearchWorker.compose(processed.source,snapshot:snapshot) }
        compositionTask.cancel()
        await #expect(throws:CancellationError.self) { try await compositionTask.value }
        let asynchronous=try await GlassCardSDRResearchAdapter.renderAsync(prepared.prepared,plan:plan)
        #expect(try rgba(synchronous.image)==rgba(asynchronous.image))
        #expect(try rgba(processed.source.image)==rgba(asynchronous.processedSource))
        let task=Task<Void,Error> { @MainActor in _ = try await GlassCardSDRResearchAdapter.renderAsync(prepared.prepared,plan:plan) }
        task.cancel()
        await #expect(throws:CancellationError.self) { try await task.value }
        let sourceTask=Task<Void,Error> { @MainActor in _ = try await GlassCardSDRResearchWorker.prepare(bytes,canvas:size,mapping:.exact) }
        sourceTask.cancel()
        await #expect(throws:CancellationError.self) { try await sourceTask.value }
        Attachment.record(Data("sourceOffMain=true\npixelOffMain=true\ncompositionOffMain=true\npreCancelledCompositionRejected=true\nasyncSyncPixelsEqual=true\npreCancelledSourceAndAdapterRejected=true\n".utf8),named:"async-stage-controls.txt")
    }
    private func blurredSource(_ source: CGImage, panel: CGRect, radius: CGFloat) throws -> (image: CGImage, haloBytes: Int, haloDifference: Int, outsideDifference: Int) { try GlassCardSDRResearchMaterial().blurredSource(source, panel: panel, radius: radius, cornerRadius: panel.height*GlassCardLayoutSpecification.layout.cornerRadiusToPanelHeight) }

    private func texture(size: CGSize, pattern: String) throws -> CGImage {
        let width = Int(size.width), height = Int(size.height)
        var bytes = [UInt8](repeating: 255, count: width * height * 4)
        for y in 0..<height {
            for x in 0..<width {
                let value: UInt8
                switch pattern {
                case "bright-checker": value = ((x / 8 + y / 8) % 2 == 0) ? 180 : 255
                case "full-checker": value = ((x / 8 + y / 8) % 2 == 0) ? 0 : 255
                case "fine-stripes": value = x % 4 < 2 ? 180 : 255
                default: value = UInt8(x * 255 / (width - 1))
                }
                let i = (y * width + x) * 4
                bytes[i] = value; bytes[i + 1] = value; bytes[i + 2] = value
            }
        }
        let provider = try #require(CGDataProvider(data: Data(bytes) as CFData))
        return try #require(CGImage(width: width, height: height, bitsPerComponent: 8, bitsPerPixel: 32,
            bytesPerRow: width * 4, space: CGColorSpace(name: CGColorSpace.sRGB)!,
            bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue),
            provider: provider, decode: nil, shouldInterpolate: false, intent: .defaultIntent))
    }

    private func rgba(_ image: CGImage) throws -> [UInt8] { try GlassCardSDRResearchMaterial().rgba(image) }

    private func luma(_ bytes: [UInt8], _ i: Int) -> Double {
        func linear(_ b: UInt8) -> Double {
            let v = Double(b) / 255
            return v <= 0.04045 ? v / 12.92 : pow((v + 0.055) / 1.055, 2.4)
        }
        return 0.2126 * linear(bytes[i]) + 0.7152 * linear(bytes[i + 1]) + 0.0722 * linear(bytes[i + 2])
    }

    // Experimental resolved input only. Production continues using the default Layout.
    private func compatiblePresentation(content: GlassCardContentProjection, size: CGSize, multiplier: CGFloat) -> GlassCardResolvedPresentation {
        let original = GlassCardLayoutSpecification.resolvedGeometry(canvasSize: size)
        let taller = GlassCardLayoutSpecification.resolvedGeometry(canvasSize: size, panelHeightMultiplier: multiplier)
        func row(_ horizontal: CGRect, _ vertical: CGRect) -> CGRect {
            CGRect(x: horizontal.minX, y: vertical.minY, width: horizontal.width, height: vertical.height)
        }
        let geometry = GlassCardLayoutSpecification.ResolvedGeometry(
            panelFrame: taller.panelFrame,
            leftTopFrame: row(original.leftTopFrame, taller.leftTopFrame),
            leftBottomFrame: row(original.leftBottomFrame, taller.leftBottomFrame),
            badgeFrame: CGRect(x: original.badgeFrame.minX, y: (taller.panelFrame.height - original.badgeFrame.height) / 2,
                width: original.badgeFrame.width, height: original.badgeFrame.height),
            dividerFrame: CGRect(x: original.dividerFrame.minX, y: taller.dividerFrame.minY,
                width: original.dividerFrame.width, height: taller.dividerFrame.height),
            rightTopFrame: row(original.rightTopFrame, taller.rightTopFrame),
            rightBottomFrame: row(original.rightBottomFrame, taller.rightBottomFrame)
        )
        let layout = GlassCardLayoutSpecification.layout
        let values: [(String, CGRect, Bool)] = [(content.leftTop, geometry.leftTopFrame, true),
            (content.leftBottom, geometry.leftBottomFrame, false), (content.rightTop, geometry.rightTopFrame, true),
            (content.rightBottom, geometry.rightBottomFrame, false)]
        let actualMultiplier = taller.panelFrame.height / original.panelFrame.height
        return GlassCardResolvedPresentation(canvasSize: size, geometry: geometry, slots: values.map { text, frame, primary in
            let pointSize = taller.panelFrame.height * (primary ? layout.primaryFontToPanelHeight : layout.secondaryFontToPanelHeight) * (primary ? 1.12 : 1.04)
            let minimumScale = (primary ? 0.72 : 0.70) / actualMultiplier
            return .init(text: text, frame: frame, isPrimary: primary,
                fit: GlassCardTextFitSpecification.resolve(text: text, frame: frame.size, pointSize: pointSize,
                    isPrimary: primary, lineLimit: 1, minimumScale: minimumScale))
        }, isEmpty: content.isEmpty)
    }

    @MainActor
    private func layer(_ plan: GlassCardResolvedPresentation, recipe: GlassCardMaterialRecipe, opacity: Double) throws -> CGImage {
        let frame = plan.overlayFrame
        let renderer = ImageRenderer(content: GlassCardOverlayLayer(presentation: plan, badge: nil,
            recipe: recipe, secondaryTextOpacity: opacity).offset(y: -frame.minY)
            .frame(width: frame.width, height: frame.height, alignment: .topLeading).clipped())
        renderer.scale = 1
        renderer.proposedSize = .init(frame.size)
        return try #require(renderer.cgImage)
    }

    private func png(_ image: CGImage) throws -> Data {
        let bytes = NSMutableData()
        let destination = try #require(CGImageDestinationCreateWithData(bytes, UTType.png.identifier as CFString, 1, nil))
        CGImageDestinationAddImage(destination, image, nil)
        #expect(CGImageDestinationFinalize(destination))
        return bytes as Data
    }

}

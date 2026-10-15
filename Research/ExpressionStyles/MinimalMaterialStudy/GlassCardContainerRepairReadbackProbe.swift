import Foundation
import CoreGraphics
import ImageIO
import Testing

@Suite struct GlassCardContainerRepairReadbackProbe {
    @Test func readsRepairedCopiesWithoutPixelChanges() throws {
        let root=URL(fileURLWithPath:"/tmp/GlassCardContainerRepairTrial")
        let manifest=try #require(JSONSerialization.jsonObject(with:Data(contentsOf:root.appendingPathComponent("repaired/repair-manifest.json"))) as? [[String:Any]])
        #expect(manifest.count==24)
        #expect(manifest.filter { $0["status"] as? String=="rejected" }.count==2)
        var readback:[[String:Any]]=[]
        for entry in manifest where entry["status"] as? String=="patched" {
            let name=try #require(entry["file"] as? String)
            let text=try #require(entry["input"] as? String)
            func load(_ folder:String) throws -> (CGImage,[CFString:Any]) {
                let source=try #require(CGImageSourceCreateWithURL(root.appendingPathComponent(folder+"/"+name) as CFURL,nil))
                return (try #require(CGImageSourceCreateImageAtIndex(source,0,nil)),try #require(CGImageSourceCopyPropertiesAtIndex(source,0,nil) as? [CFString:Any]))
            }
            let (image,properties)=try load("repaired")
            let (original,originalProperties)=try load("originals")
            let pixels=try #require(image.dataProvider?.data as Data?)
            let originalPixels=try #require(original.dataProvider?.data as Data?)
            #expect(pixels==originalPixels)
            #expect(image.colorSpace?.name==original.colorSpace?.name)
            #expect(properties[kCGImagePropertyPixelWidth] as? Int==64)
            #expect(properties[kCGImagePropertyPixelHeight] as? Int==48)
            #expect(properties[kCGImagePropertyOrientation] as? Int==1)
            let exif=try #require(properties[kCGImagePropertyExifDictionary] as? [CFString:Any])
            let comment=try #require(exif[kCGImagePropertyExifUserComment] as? String)
            #expect(comment.unicodeScalars.map(\.value)==text.unicodeScalars.map(\.value))
            #expect(exif[kCGImagePropertyExifDateTimeOriginal] as? String=="2001:02:03 04:05:06")
            #expect(exif[kCGImagePropertyExifExposureTime] as? Double==0.01)
            for key in [kCGImagePropertyTIFFDictionary,kCGImagePropertyIPTCDictionary,kCGImagePropertyPNGDictionary] {
                let actual=properties[key] as? NSDictionary
                let before=originalProperties[key] as? NSDictionary
                #expect(actual==before)
            }
            readback.append(["file":name,"comment":comment,"pixelsEqual":pixels==originalPixels])
        }
        #expect(readback.count==22)
        Attachment.record(try JSONSerialization.data(withJSONObject:readback,options:[.prettyPrinted,.sortedKeys]),named:"repaired-readback.json")
    }
}

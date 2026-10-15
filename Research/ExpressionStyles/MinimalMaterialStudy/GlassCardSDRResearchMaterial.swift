// Research controls retained; not an optimized production kernel.
import Foundation
import CoreGraphics
import CoreImage

nonisolated struct GlassCardSDRResearchMaterial {
    enum Failure: Error { case allocationFailed, boundaryChanged }
    private func require<T>(_ value: T?) throws -> T {
        guard let value else { throw Failure.allocationFailed }
        return value
    }
    func decode(_ x: Double) -> Double { x <= 0.04045 ? x/12.92 : pow((x+0.055)/1.055,2.4) }

    func encode(_ x: Double) -> Double { x <= 0.0031308 ? 12.92*x : 1.055*pow(x,1/2.4)-0.055 }

    func mapped(_ rgb: [Double], cap: Double) -> [Double] {
        let y = 0.2126*rgb[0]+0.7152*rgb[1]+0.0722*rgb[2]
        let scale = y == 0 ? 1 : cap*tanh(y/cap)/y
        return rgb.map { $0*scale }
    }

    func compressed(_ source: CGImage, panel: CGRect, cap: Double, cornerRadius: CGFloat) throws -> CGImage {
        try Task.checkCancellation()
        let original = try rgba(source)
        var bytes = original
        for i in stride(from:0,to:bytes.count,by:4) {
            if i % (source.width*4) == 0 { try Task.checkCancellation() }
            let rgb = (0..<3).map { decode(Double(original[i+$0])/255) }
            let result = mapped(rgb,cap:cap)
            for c in 0..<3 { bytes[i+c] = UInt8(max(0,min(255,(encode(result[c])*255).rounded()))) }
        }
        let color = CGColorSpace(name:CGColorSpace.sRGB)!
        let provider = try require(CGDataProvider(data:Data(bytes) as CFData))
        let mappedImage = try require(CGImage(width:source.width,height:source.height,bitsPerComponent:8,bitsPerPixel:32,
            bytesPerRow:source.width*4,space:color,bitmapInfo:CGBitmapInfo(rawValue:CGImageAlphaInfo.premultipliedLast.rawValue|CGBitmapInfo.byteOrder32Big.rawValue),provider:provider,decode:nil,shouldInterpolate:false,intent:.defaultIntent))
        let context = try require(CGContext(data:nil,width:source.width,height:source.height,bitsPerComponent:8,bytesPerRow:source.width*4,
            space:color,bitmapInfo:CGImageAlphaInfo.premultipliedLast.rawValue|CGBitmapInfo.byteOrder32Big.rawValue))
        let bounds = CGRect(x:0,y:0,width:source.width,height:source.height)
        let rect = CGRect(x:panel.minX,y:bounds.height-panel.maxY,width:panel.width,height:panel.height)
        let path = CGPath(roundedRect:rect,cornerWidth:cornerRadius,cornerHeight:cornerRadius,transform:nil)
        context.draw(source,in:bounds)
        context.saveGState();context.addPath(path);context.clip();context.draw(mappedImage,in:bounds);context.restoreGState()
        let result = try require(context.makeImage())
        let mask = try require(CGContext(data:nil,width:source.width,height:source.height,bitsPerComponent:8,bytesPerRow:source.width*4,
            space:color,bitmapInfo:CGImageAlphaInfo.premultipliedLast.rawValue|CGBitmapInfo.byteOrder32Big.rawValue))
        mask.addPath(path);mask.setFillColor(CGColor(gray:1,alpha:1));mask.fillPath()
        let coverage = try rgba(try require(mask.makeImage())), final = try rgba(result)
        guard (stride(from:0,to:bytes.count,by:4).filter { coverage[$0+3] == 0 }.allSatisfy { i in (0..<4).allSatisfy { original[i+$0] == final[i+$0] } }) else { throw Failure.boundaryChanged }
        try Task.checkCancellation()
        return result
    }

    func blurredSource(_ source: CGImage, panel: CGRect, radius: CGFloat, cornerRadius: CGFloat) throws -> (image: CGImage, haloBytes: Int, haloDifference: Int, outsideDifference: Int) {
        try Task.checkCancellation()
        if radius == 0 { return (source, 0, 0, 0) }
        let bounds = CGRect(x: 0, y: 0, width: source.width, height: source.height)
        let halo = ceil(4 * radius + 2)
        let crop = panel.insetBy(dx: -halo, dy: -halo).integral.intersection(bounds)
        let patch = try require(source.cropping(to: crop))
        let color = CGColorSpace(name: CGColorSpace.sRGB)!
        let ciContext = CIContext(options: [.workingColorSpace: color, .outputColorSpace: color, .cacheIntermediates: false])
        func blurred(_ image: CGImage) -> CIImage {
            CIImage(cgImage: image).clampedToExtent().applyingFilter("CIGaussianBlur", parameters: [kCIInputRadiusKey: radius])
        }
        let patchExtent = CGRect(x: 0, y: 0, width: patch.width, height: patch.height)
        try Task.checkCancellation()
        let filtered = try require(ciContext.createCGImage(blurred(patch), from: patchExtent, format: .RGBA8, colorSpace: color))
        let worldCrop = CGRect(x: crop.minX, y: bounds.height-crop.maxY, width: crop.width, height: crop.height)
        let reference = try require(ciContext.createCGImage(blurred(source), from: worldCrop, format: .RGBA8, colorSpace: color))
        try Task.checkCancellation()
        let a = try rgba(filtered), b = try rgba(reference)
        let interior = panel.offsetBy(dx: -crop.minX, dy: -crop.minY).integral
        var haloDifference = 0
        for y in Int(interior.minY)..<Int(interior.maxY) {
            for x in Int(interior.minX)..<Int(interior.maxX) {
                let i = (y * patch.width + x) * 4
                for channel in 0..<3 { haloDifference = max(haloDifference, abs(Int(a[i+channel])-Int(b[i+channel]))) }
            }
        }
        func context() throws -> CGContext {
            try require(CGContext(data: nil, width: source.width, height: source.height, bitsPerComponent: 8, bytesPerRow: source.width*4,
                space: color, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Big.rawValue))
        }
        let target = try context()
        target.draw(source, in: bounds)
        let panelBottom = CGRect(x: panel.minX, y: bounds.height-panel.maxY, width: panel.width, height: panel.height)
        let path = CGPath(roundedRect: panelBottom, cornerWidth: cornerRadius, cornerHeight: cornerRadius, transform: nil)
        target.saveGState(); target.addPath(path); target.clip()
        target.draw(filtered, in: worldCrop); target.restoreGState()
        let result = try require(target.makeImage())
        let panelMask = try context()
        panelMask.addPath(path); panelMask.setFillColor(CGColor(gray: 1, alpha: 1)); panelMask.fillPath()
        let coverage = try rgba(try require(panelMask.makeImage()))
        let original = try rgba(source), processed = try rgba(result)
        var outsideDifference = 0
        for i in stride(from: 0, to: original.count, by: 4) where coverage[i+3] == 0 {
            for channel in 0..<4 { outsideDifference = max(outsideDifference, abs(Int(original[i+channel])-Int(processed[i+channel]))) }
        }
        return (result, patch.width*patch.height*4, haloDifference, outsideDifference)
    }

    func rgba(_ image: CGImage) throws -> [UInt8] {
        var bytes = [UInt8](repeating: 0, count: image.width * image.height * 4)
        let context = try require(CGContext(data: &bytes, width: image.width, height: image.height,
            bitsPerComponent: 8, bytesPerRow: image.width * 4, space: CGColorSpace(name: CGColorSpace.sRGB)!,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Big.rawValue))
        context.draw(image, in: CGRect(x: 0, y: 0, width: image.width, height: image.height))
        return bytes
    }
}

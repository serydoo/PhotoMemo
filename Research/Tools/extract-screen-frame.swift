import AVFoundation
import AppKit
import CoreGraphics
import Foundation

let assetURL = URL(fileURLWithPath: CommandLine.arguments[1])
let second = Double(CommandLine.arguments[2]) ?? 12
let asset = AVURLAsset(url: assetURL)
let generator = AVAssetImageGenerator(asset: asset)
generator.appliesPreferredTrackTransform = true
generator.requestedTimeToleranceBefore = .zero
generator.requestedTimeToleranceAfter = .zero
let image = try generator.copyCGImage(at: CMTime(seconds: second, preferredTimescale: 600), actualTime: nil)
let bitmap = NSBitmapImageRep(cgImage: image)
let data = bitmap.representation(using: .png, properties: [:])!
try data.write(to: URL(fileURLWithPath: CommandLine.arguments[3]))
print("\\(image.width)x\\(image.height)")

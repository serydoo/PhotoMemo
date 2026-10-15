import AVFoundation
import ImageIO
import UniformTypeIdentifiers
import Foundation

@main struct Readback {
    static func main() async throws {
        let asset = AVURLAsset(url: URL(fileURLWithPath: CommandLine.arguments[1]))
        let duration = try await asset.load(.duration)
        let track = try await asset.loadTracks(withMediaType: .video).first!
        let size = try await track.load(.naturalSize)
        let fps = try await track.load(.nominalFrameRate)
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        generator.requestedTimeToleranceBefore = .zero
        generator.requestedTimeToleranceAfter = .zero
        for frame in [0, 14, 15, 29] {
            let output = try await generator.image(at: CMTime(value: Int64(frame), timescale: 30))
            let url = URL(fileURLWithPath: "/tmp/GlassCardNativePhoneMotion/frame-\(frame).png")
            let destination = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil)!
            CGImageDestinationAddImage(destination, output.image, nil)
            guard CGImageDestinationFinalize(destination) else { throw CocoaError(.fileWriteUnknown) }
        }
        print("duration=\(duration.seconds), size=\(size), fps=\(fps), decodedFrames=0,14,15,29")
    }
}

#if DEBUG && os(iOS) && !MEMOMARK_SHARE_EXTENSION
import SwiftUI
import UIKit
import ImageIO
import UniformTypeIdentifiers
import AVFoundation
import CoreVideo
import Photos
import Darwin

/// Explicit DEBUG launch-only study. Optional Photos verification writes new assets through the existing writer.
struct GlassCardNativeMaterialStudyView: View {
    @State private var mode = GlassCardNativeMaterialStudyMode.production
    @State private var dark = false
    @State private var source: CGImage?
    @State private var message = "准备原生材质对照"
    let onClose: () -> Void
    private let size = CGSize(width:1080,height:1440)
    private var plan: GlassCardResolvedPresentation {
        .resolve(content:.init(leftTop:"相伴365天",leftBottom:"Our first walk",rightTop:"2026.10.01",rightBottom:"此刻值得记住"),canvasSize:size)
    }
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing:12) {
                    Text("同一照片、布局和文字的原生材质对照")
                    Picker("材质",selection:$mode) {
                        ForEach(GlassCardNativeMaterialStudyMode.allCases) { Text($0.rawValue).tag($0) }
                    }.pickerStyle(.segmented)
                    Toggle("深色纹理",isOn:$dark).onChange(of:dark) { _,value in source = fixture(dark:value) }
                    if let source {
                        GlassCardNativeMaterialStudyCanvas(source:source,plan:plan,mode:mode)
                            .scaleEffect(1/3,anchor:.topLeading)
                            .frame(width:360,height:480,alignment:.topLeading).clipped()
                    }
                    Text(message).font(.caption).accessibilityIdentifier("native-material-study-status")
                }.padding()
            }.navigationTitle("GlassCard 材质验证")
                .toolbar { Button("关闭",action:onClose) }
                .task { await exportControls() }
        }
    }
    @MainActor private func exportControls() async {
        source = fixture(dark:false)
        let root = URL.documentsDirectory.appendingPathComponent("GlassCardNativeMaterialStudy",isDirectory:true)
        let startedAt = Date.now.ISO8601Format()
        func recordStatus(_ state: String, error: String = "") throws {
            try JSONSerialization.data(withJSONObject: ["state": state, "startedAt": startedAt,
                "updatedAt": Date.now.ISO8601Format(), "error": error], options: [.prettyPrinted, .sortedKeys])
                .write(to: root.appendingPathComponent("study-status.json"), options: .atomic)
        }
        do {
            try FileManager.default.createDirectory(at:root,withIntermediateDirectories:true)
            try recordStatus("running")
            var rows: [[String:Any]] = []
            for backdrop in [false,true] {
                guard let image = fixture(dark:backdrop) else { throw CocoaError(.fileWriteUnknown) }
                for candidate in GlassCardNativeMaterialStudyMode.allCases {
                    try Task.checkCancellation()
                    let renderStart = ContinuousClock.now
                    let renderer = ImageRenderer(content:GlassCardNativeMaterialStudyCanvas(source:image,plan:plan,mode:candidate))
                    renderer.scale = 1
                    guard let output = renderer.cgImage else { throw CocoaError(.fileWriteUnknown) }
                    let renderDuration = renderStart.duration(to: .now)
                    let name = "\(backdrop ? "dark" : "light")-\(candidate.rawValue).png"
                    let url = root.appendingPathComponent(name)
                    guard let writer = CGImageDestinationCreateWithURL(url as CFURL,UTType.png.identifier as CFString,1,nil) else { throw CocoaError(.fileWriteUnknown) }
                    CGImageDestinationAddImage(writer,output,nil)
                    guard CGImageDestinationFinalize(writer) else { throw CocoaError(.fileWriteUnknown) }
                    let seconds = Double(renderDuration.components.seconds)
                        + Double(renderDuration.components.attoseconds) / 1e18
                    rows.append(["file":name,"width":output.width,"height":output.height,"system":UIDevice.current.systemVersion,
                                 "renderMilliseconds":seconds * 1000])
                    await Task.yield()
                }
            }
            try JSONSerialization.data(withJSONObject:rows,options:[.prettyPrinted,.sortedKeys])
                .write(to:root.appendingPathComponent("manifest.json"),options:.atomic)
            try await exportMotionControl(to: root)
            if ProcessInfo.processInfo.arguments.contains("--glasscard-native-repeat-study") {
                for cycle in 1...3 {
                    try Task.checkCancellation()
                    try await exportApprovedPairs(to: root)
                    let manifest = try Data(contentsOf: root.appendingPathComponent("real-pair-manifest.json"))
                    try manifest.write(to: root.appendingPathComponent("repeat-cycle-\(cycle).json"), options: .atomic)
                    await Task.yield()
                }
            } else {
                try await exportApprovedPairs(to: root)
            }
            try recordStatus("completed")
            message = "材质与照片配对验证完成，详情已保存在本地验证记录中"
        } catch {
            try? recordStatus("failed", error: error.localizedDescription)
            message = "输出失败：\(error.localizedDescription)"
        }
    }
    @MainActor private func exportApprovedPairs(to root: URL) async throws {
        let usesSDRFixture = ProcessInfo.processInfo.arguments.contains("--glasscard-native-sdr-fixture-study")
        let inputs = root.appendingPathComponent(usesSDRFixture ? "InputsSDRFixture" : "Inputs", isDirectory: true)
        var rows: [[String: Any]] = []
        let runIdentifier = UUID().uuidString
        for name in ["IMG_7027", "IMG_7033"] {
            let still = inputs.appendingPathComponent(name + ".HEIC")
            let motion = inputs.appendingPathComponent(name + ".mov")
            guard FileManager.default.fileExists(atPath: still.path),
                  FileManager.default.fileExists(atPath: motion.path) else { continue }
            try Task.checkCancellation()
            guard let source = CGImageSourceCreateWithURL(still as CFURL, nil),
                  let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any],
                  let width = properties[kCGImagePropertyPixelWidth] as? NSNumber,
                  let height = properties[kCGImagePropertyPixelHeight] as? NSNumber else {
                throw CocoaError(.fileReadCorruptFile)
            }
            let orientation = (properties[kCGImagePropertyOrientation] as? NSNumber)?.intValue ?? 1
            let portrait = (orientation >= 5 ? height.doubleValue : width.doubleValue)
                < (orientation >= 5 ? width.doubleValue : height.doubleValue)
            // Bounded device study uses 1080 short-edge output; final production-size acceptance is separate.
            let fullResolution = ProcessInfo.processInfo.arguments.contains("--glasscard-native-full-resolution-study")
            let canvas = fullResolution
                ? PresentationPixelGeometry.encoderSafeSize(CGSize(width: orientation >= 5 ? height.doubleValue : width.doubleValue,
                    height: orientation >= 5 ? width.doubleValue : height.doubleValue))
                : (portrait ? CGSize(width: 1080, height: 1440) : CGSize(width: 1440, height: 1080))
            let resolved = GlassCardResolvedPresentation.resolve(content: .init(
                leftTop: "相伴365天", leftBottom: "Our first walk", rightTop: "2026.10.01", rightBottom: "此刻值得记住"), canvasSize: canvas)
            let rail = resolved.overlayFrame
            let renderer = ImageRenderer(content: GlassCardOverlayLayer(presentation: resolved, badge: nil,
                recipe: .foregroundOnly, secondaryTextOpacity: 0.96).offset(y: -rail.minY)
                .frame(width: rail.width, height: rail.height, alignment: .topLeading).clipped())
            renderer.scale = 1
            guard let ink = renderer.cgImage else { throw CocoaError(.fileWriteUnknown) }
            let artifact = try PresentationArtifact(canvasSize: canvas, photoFrame: CGRect(origin: .zero, size: canvas),
                layers: [.init(frame: resolved.artifactOverlayFrame, image: ink)], canvasBackground: .transparent,
                backdropMaterial: GlassCardProductionRenderer.backdropMaterial(for: resolved))
            var memoryBefore = rusage()
            _ = getrusage(RUSAGE_SELF, &memoryBefore)
            let footprintBefore = physicalFootprint()
            let thermalBefore = ProcessInfo.processInfo.thermalState.rawValue
            let start = ContinuousClock.now
            let outputStill = root.appendingPathComponent(name + "-native.heic")
            let outputMotion = root.appendingPathComponent(name + "-native.mov")
            _ = try await LivePhotoPairCompositionService().composePair(sourceStillURL: still, sourceVideoURL: motion,
                overlay: artifact, outputStillURL: outputStill, outputVideoURL: outputMotion,
                outputStillType: .heic, outputDescription: "原生材质真机验证")
            let asset = AVURLAsset(url: outputMotion)
            let video = try await asset.loadTracks(withMediaType: .video)
            let audio = try await asset.loadTracks(withMediaType: .audio)
            let elapsed = start.duration(to: .now)
            var memoryAfter = rusage()
            _ = getrusage(RUSAGE_SELF, &memoryAfter)
            var savedIdentifier = ""
            var photosReadback: [String: Any] = [:]
            let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
            if ProcessInfo.processInfo.arguments.contains("--glasscard-native-photos-study"),
               status == .authorized || status == .limited {
                let result = try await PhotoKitLivePhotoAssetWriter(runtimeGate: .internalTesting(
                    allowedRoutes: [.livePhoto], permitsPhotoLibraryWrites: true)).saveAsset(.init(
                        stillPhotoFileURL: outputStill, pairedVideoFileURL: outputMotion, captureDate: nil,
                        preferredAlbumIdentifier: nil, stillPhotoOriginalFilename: name + "-native.heic",
                        pairedVideoOriginalFilename: name + "-native.mov",
                        idempotencyKey: "native-glass-device-certification-" + name + "-" + runIdentifier))
                savedIdentifier = result.assetLocalIdentifier
                photosReadback = try await verifySavedPair(identifier: savedIdentifier, name: name, root: root, sourceVideoURL: motion)
            }
            let encodedSize = try await video.first?.load(.naturalSize)
            var row: [String: Any] = ["source": name, "usesSDRVideoFixture": usesSDRFixture, "still": outputStill.lastPathComponent, "motion": outputMotion.lastPathComponent,
                "canvasWidth": Int(canvas.width), "canvasHeight": Int(canvas.height),
                "videoTracks": video.count, "audioTracks": audio.count,
                "processLifetimePeakRSSBeforeBytes": memoryBefore.ru_maxrss,
                "processLifetimePeakRSSAfterBytes": memoryAfter.ru_maxrss,
                "thermalStateBefore": thermalBefore, "thermalStateAfter": ProcessInfo.processInfo.thermalState.rawValue,
                "duration": try await asset.load(.duration).seconds,
                "seconds": Double(elapsed.components.seconds) + Double(elapsed.components.attoseconds) / 1e18,
                "savedToPhotos": !savedIdentifier.isEmpty, "photosAssetIdentifier": savedIdentifier,
                "photosAuthorization": status.rawValue, "fullResolution": fullResolution,
                "runIdentifier": runIdentifier, "photosReadback": photosReadback]
            if let encodedSize {
                row["encodedVideoWidth"] = Int(encodedSize.width)
                row["encodedVideoHeight"] = Int(encodedSize.height)
                row["encodedSizeMatchesCanvas"] = encodedSize == canvas
                row["encodedAspectMatchesCanvas"] = abs(encodedSize.width / encodedSize.height - canvas.width / canvas.height) < 0.001
            }
            if let footprintBefore { row["physicalFootprintBeforeBytes"] = footprintBefore }
            if let footprintAfter = physicalFootprint() { row["physicalFootprintAfterBytes"] = footprintAfter }
            rows.append(row)
        }
        try JSONSerialization.data(withJSONObject: rows, options: [.prettyPrinted, .sortedKeys])
            .write(to: root.appendingPathComponent("real-pair-manifest.json"), options: .atomic)
    }

    /// Current footprint complements process-lifetime peak RSS for repeated-export studies.
    private func physicalFootprint() -> UInt64? {
        var info = task_vm_info_data_t()
        var count = mach_msg_type_number_t(MemoryLayout<task_vm_info_data_t>.size / MemoryLayout<integer_t>.size)
        let result = withUnsafeMutablePointer(to: &info) { pointer in
            pointer.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                task_info(mach_task_self_, task_flavor_t(TASK_VM_INFO), $0, &count)
            }
        }
        return result == KERN_SUCCESS ? info.phys_footprint : nil
    }

    /// Inspect only this run's saved assets. Cloud downloads are never requested.
    @MainActor private func verifySavedPair(identifier: String, name: String, root: URL, sourceVideoURL: URL) async throws -> [String: Any] {
        guard let asset = PHAsset.fetchAssets(withLocalIdentifiers: [identifier], options: nil).firstObject,
              asset.mediaSubtypes.contains(.photoLive) else { throw CocoaError(.fileReadCorruptFile) }
        let resources = PHAssetResource.assetResources(for: asset)
        guard let photo = resources.first(where: { $0.type == .photo }),
              let video = resources.first(where: { $0.type == .pairedVideo }) else {
            throw CocoaError(.fileReadCorruptFile)
        }
        let directory = root.appendingPathComponent("Readback", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        var rows: [[String: Any]] = []
        for (resource, suffix) in [(photo, "heic"), (video, "mov")] {
            let url = directory.appendingPathComponent(name + "-" + UUID().uuidString + "." + suffix)
            let options = PHAssetResourceRequestOptions()
            options.isNetworkAccessAllowed = false
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, any Error>) in
                PHAssetResourceManager.default().writeData(for: resource, toFile: url, options: options) { error in
                    if let error { continuation.resume(throwing: error) }
                    else { continuation.resume() }
                }
            }
            if resource.type == .pairedVideo {
                let expected = try await LivePhotoStillImageTimeMetadata.samples(in: sourceVideoURL)
                guard !expected.isEmpty else { throw CocoaError(.fileReadCorruptFile) }
                try await LivePhotoStillImageTimeMetadata.verify(expected, in: url)
            }
            rows.append(["type": resource.type.rawValue, "uti": resource.uniformTypeIdentifier,
                         "file": url.lastPathComponent])
        }
        let options = PHLivePhotoRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.isNetworkAccessAllowed = false
        let decodes = await withCheckedContinuation { (continuation: CheckedContinuation<Bool, Never>) in
            PHImageManager.default().requestLivePhoto(for: asset, targetSize: CGSize(width: 256, height: 256),
                contentMode: .aspectFit, options: options) { livePhoto, info in
                    if info?[PHLivePhotoInfoIsDegradedKey] as? Bool == true { return }
                    continuation.resume(returning: livePhoto != nil)
                }
        }
        guard decodes else { throw CocoaError(.fileReadCorruptFile) }
        return ["isLivePhoto": true, "localLivePhotoDecoded": decodes, "timedStillMarkerMatchesSource": true,
                "networkAccessAllowed": false, "resources": rows]
    }

    @MainActor private func exportMotionControl(to root: URL) async throws {
        let url = root.appendingPathComponent("native-motion-\(UUID().uuidString).mov")
        let writer = try AVAssetWriter(outputURL: url, fileType: .mov)
        let input = AVAssetWriterInput(mediaType: .video, outputSettings: [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey: 1080, AVVideoHeightKey: 1440
        ])
        let adaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: input,
            sourcePixelBufferAttributes: [
                kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA,
                kCVPixelBufferWidthKey as String: 1080,
                kCVPixelBufferHeightKey as String: 1440,
                kCVPixelBufferCGImageCompatibilityKey as String: true,
                kCVPixelBufferCGBitmapContextCompatibilityKey as String: true
            ])
        guard writer.canAdd(input) else { throw CocoaError(.fileWriteUnknown) }
        writer.add(input)
        guard writer.startWriting() else { throw writer.error ?? CocoaError(.fileWriteUnknown) }
        writer.startSession(atSourceTime: .zero)
        let start = ContinuousClock.now
        do {
            for frame in 0..<30 {
                try Task.checkCancellation()
                let waitStart = ContinuousClock.now
                while !input.isReadyForMoreMediaData {
                    guard writer.status == .writing,
                          waitStart.duration(to: .now) < .seconds(5) else {
                        throw writer.error ?? CocoaError(.fileWriteUnknown)
                    }
                    try await Task.sleep(for: .milliseconds(5))
                }
                guard let source = fixture(dark: frame >= 15, phase: frame * 7) else {
                    throw CocoaError(.fileWriteUnknown)
                }
                let renderer = ImageRenderer(content: GlassCardNativeMaterialStudyCanvas(
                    source: source, plan: plan, mode: .production))
                renderer.scale = 1
                guard let image = renderer.cgImage, let pool = adaptor.pixelBufferPool else {
                    throw CocoaError(.fileWriteUnknown)
                }
                var buffer: CVPixelBuffer?
                guard CVPixelBufferPoolCreatePixelBuffer(nil, pool, &buffer) == kCVReturnSuccess,
                      let buffer else { throw CocoaError(.fileWriteUnknown) }
                CVPixelBufferLockBaseAddress(buffer, [])
                let context = CGContext(data: CVPixelBufferGetBaseAddress(buffer),
                    width: 1080, height: 1440, bitsPerComponent: 8,
                    bytesPerRow: CVPixelBufferGetBytesPerRow(buffer),
                    space: CGColorSpace(name: CGColorSpace.sRGB)!,
                    bitmapInfo: CGBitmapInfo.byteOrder32Little.rawValue
                        | CGImageAlphaInfo.premultipliedFirst.rawValue)
                context?.draw(image, in: CGRect(origin: .zero, size: size))
                CVPixelBufferUnlockBaseAddress(buffer, [])
                guard context != nil,
                      adaptor.append(buffer, withPresentationTime: CMTime(value: Int64(frame), timescale: 30)) else {
                    throw writer.error ?? CocoaError(.fileWriteUnknown)
                }
                await Task.yield()
            }
            input.markAsFinished()
            await writer.finishWriting()
            guard writer.status == .completed else { throw writer.error ?? CocoaError(.fileWriteUnknown) }
            let duration = start.duration(to: .now)
            let seconds = Double(duration.components.seconds)
                + Double(duration.components.attoseconds) / 1e18
            try JSONSerialization.data(withJSONObject: [
                "file": url.lastPathComponent, "frames": 30, "fps": 30,
                "secondsIncludingRasterCopyAndEncoding": seconds,
                "system": UIDevice.current.systemVersion,
                "isPairedLivePhoto": false
            ], options: [.prettyPrinted, .sortedKeys])
                .write(to: root.appendingPathComponent("motion-manifest.json"), options: .atomic)
        } catch {
            writer.cancelWriting()
            try? FileManager.default.removeItem(at: url)
            throw error
        }
    }
    @MainActor private func fixture(dark:Bool, phase:Int = 0) -> CGImage? {
        guard let context = CGContext(data:nil,width:1080,height:1440,bitsPerComponent:8,bytesPerRow:4320,
                                      space:CGColorSpace(name:CGColorSpace.sRGB)!,bitmapInfo:CGImageAlphaInfo.premultipliedLast.rawValue) else { return nil }
        for y in stride(from:0,to:1440,by:20) {
            for x in stride(from:0,to:1080,by:20) {
                let c: CGFloat = ((x+phase)/20+y/20)%2 == 0 ? (dark ? 0.08 : 0.9) : (dark ? 0.25 : 0.5)
                context.setFillColor(CGColor(red:c,green:c*0.9,blue:c*0.7,alpha:1))
                context.fill(CGRect(x:x,y:y,width:20,height:20))
            }
        }
        return context.makeImage()
    }
}
#endif

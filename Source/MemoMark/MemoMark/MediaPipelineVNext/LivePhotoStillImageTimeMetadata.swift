import AVFoundation
import Foundation

/// Carries only the temporal still marker. Source orientation/transform metadata
/// describes the old pixels and must not accompany a newly rendered canvas.
nonisolated enum LivePhotoStillImageTimeMetadata {
    static let identifier = AVMetadataIdentifier(rawValue: "mdta/com.apple.quicktime.still-image-time")

    struct Sample {
        let range: CMTimeRange
        let value: Int8
    }

    static func samples(in url: URL) async throws -> [Sample] {
        try Task.checkCancellation()
        let asset = AVURLAsset(url: url)
        let duration = try await asset.load(.duration)
        let tracks = try await asset.loadTracks(withMediaType: .metadata)
        var samples: [Sample] = []
        for track in tracks {
            try Task.checkCancellation()
            let reader = try AVAssetReader(asset: asset)
            let output = AVAssetReaderTrackOutput(track: track, outputSettings: nil)
            guard reader.canAdd(output) else { throw LivePhotoVideoCompositionError.sourceVideoUnreadable }
            reader.add(output)
            let adaptor = AVAssetReaderOutputMetadataAdaptor(assetReaderTrackOutput: output)
            guard reader.startReading() else { throw LivePhotoVideoCompositionError.sourceVideoUnreadable }
            defer { if reader.status == .reading { reader.cancelReading() } }
            while let group = adaptor.nextTimedMetadataGroup() {
                try Task.checkCancellation()
                for item in group.items where item.identifier == identifier {
                    guard let number = try await item.load(.numberValue),
                          number.doubleValue == Double(number.int8Value),
                          group.timeRange.start.isNumeric, group.timeRange.duration.isNumeric,
                          CMTimeCompare(group.timeRange.start, .zero) >= 0,
                          CMTimeCompare(group.timeRange.duration, .zero) > 0,
                          CMTimeCompare(CMTimeRangeGetEnd(group.timeRange), duration) <= 0 else {
                        throw LivePhotoVideoCompositionError.sourceVideoUnreadable
                    }
                    samples.append(Sample(range: group.timeRange, value: number.int8Value))
                }
            }
            guard reader.status == .completed else { throw reader.error ?? LivePhotoVideoCompositionError.sourceVideoUnreadable }
        }
        // A Live Photo has one still point. Conflicting markers are not guessed.
        guard samples.count <= 1 else { throw LivePhotoVideoCompositionError.sourceVideoUnreadable }
        return samples
    }

    static func adding(_ samples: [Sample], to composition: AVComposition, sidecarURL: URL) async throws -> AVComposition {
        guard !samples.isEmpty else { return composition }
        try Task.checkCancellation()
        var description: CMMetadataFormatDescription?
        let specification: [[String: Any]] = [[
            kCMMetadataFormatDescriptionMetadataSpecificationKey_Identifier as String: identifier.rawValue,
            kCMMetadataFormatDescriptionMetadataSpecificationKey_DataType as String: kCMMetadataBaseDataType_SInt8 as String
        ]]
        guard CMMetadataFormatDescriptionCreateWithMetadataSpecifications(allocator: kCFAllocatorDefault,
            metadataType: kCMMetadataFormatType_Boxed, metadataSpecifications: specification as CFArray,
            formatDescriptionOut: &description) == noErr, let description else {
            throw LivePhotoVideoCompositionError.exportFailed
        }
        let writer = try AVAssetWriter(outputURL: sidecarURL, fileType: .mov)
        let input = AVAssetWriterInput(mediaType: .metadata, outputSettings: nil, sourceFormatHint: description)
        guard writer.canAdd(input) else { throw LivePhotoVideoCompositionError.exportFailed }
        writer.add(input)
        let adaptor = AVAssetWriterInputMetadataAdaptor(assetWriterInput: input)
        guard writer.startWriting() else { throw writer.error ?? LivePhotoVideoCompositionError.exportFailed }
        writer.startSession(atSourceTime: .zero)
        defer { if writer.status == .writing { writer.cancelWriting() } }
        for sample in samples {
            try Task.checkCancellation()
            let item = AVMutableMetadataItem()
            item.identifier = identifier
            item.dataType = kCMMetadataBaseDataType_SInt8 as String
            item.value = NSNumber(value: sample.value)
            guard adaptor.append(AVTimedMetadataGroup(items: [item], timeRange: sample.range)) else {
                throw writer.error ?? LivePhotoVideoCompositionError.exportFailed
            }
        }
        input.markAsFinished()
        await writer.finishWriting()
        try Task.checkCancellation()
        guard writer.status == .completed else { throw writer.error ?? LivePhotoVideoCompositionError.exportFailed }
        let sidecar = AVURLAsset(url: sidecarURL)
        guard let sourceTrack = try await sidecar.loadTracks(withMediaType: .metadata).first,
              let result = composition.mutableCopy() as? AVMutableComposition,
              let target = result.addMutableTrack(withMediaType: .metadata, preferredTrackID: kCMPersistentTrackID_Invalid) else {
            throw LivePhotoVideoCompositionError.compositionTrackCreateFailed
        }
        let range = try await sourceTrack.load(.timeRange)
        try target.insertTimeRange(range, of: sourceTrack, at: range.start)
        return result
    }

    static func verify(_ expected: [Sample], in url: URL) async throws {
        let actual = try await samples(in: url)
        guard actual.count == expected.count,
              zip(actual, expected).allSatisfy({ lhs, rhs in
                  lhs.value == rhs.value && CMTimeCompare(lhs.range.start, rhs.range.start) == 0
                    && CMTimeCompare(lhs.range.duration, rhs.range.duration) == 0
              }) else { throw LivePhotoVideoCompositionError.exportFailed }
    }
}

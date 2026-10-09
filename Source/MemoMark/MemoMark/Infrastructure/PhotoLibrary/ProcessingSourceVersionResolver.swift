import Photos
import Foundation

/// Request only adjustment data. A complete editing input can be unavailable
/// when the Live Photo movie is not local, even though its recipe is readable.
@MainActor
enum ProcessingSourceVersionResolver {
    static func version(for identifier: String?) async throws -> String? {
        guard PhotoLibraryCapability.current.canReadVisibleAssets,
              let identifier,
              let asset = PHAsset.fetchAssets(withLocalIdentifiers: [identifier], options: nil).firstObject else { return nil }
        let capture = "\(asset.creationDate?.timeIntervalSince1970 ?? 0):\(asset.pixelWidth):\(asset.pixelHeight):\(asset.mediaSubtypes.rawValue):\(asset.location?.coordinate.latitude ?? 0):\(asset.location?.coordinate.longitude ?? 0)"
        let resources = PHAssetResource.assetResources(for: asset)
        guard let adjustment = resources.first(where: { $0.type == .adjustmentData }) else {
            return "photokit-original-v1:" + identifier + ":" + ProcessingIdentity.digest(Data(capture.utf8))
        }
        let options = PHAssetResourceRequestOptions()
        options.isNetworkAccessAllowed = false
        let buffer = AdjustmentResourceBuffer()
        let data: Data? = await withCheckedContinuation { continuation in
            PHAssetResourceManager.default().requestData(for: adjustment, options: options,
                dataReceivedHandler: { buffer.append($0) },
                completionHandler: { error in
                    continuation.resume(returning: error == nil ? buffer.result : nil)
                })
        }
        guard let data else { throw CocoaError(.fileReadUnknown) }
        return "photokit-content-v2:" + identifier + ":" + ProcessingIdentity.digest(Data(capture.utf8)) + ":" + ProcessingSourceAdjustmentIdentity.digest(data)
    }
}

/// Explicitly bounded and protected because PhotoKit invokes these callbacks
/// outside the main actor. Oversized adjustment data fails closed.
private nonisolated final class AdjustmentResourceBuffer: @unchecked Sendable {
    private let lock = NSLock()
    private var data = Data()
    private var exceededLimit = false

    func append(_ chunk: Data) {
        lock.lock()
        defer { lock.unlock() }
        guard !exceededLimit, data.count + chunk.count <= 1_048_576 else {
            exceededLimit = true
            data.removeAll()
            return
        }
        data.append(chunk)
    }

    var result: Data? {
        lock.lock()
        defer { lock.unlock() }
        return exceededLimit ? nil : data
    }
}

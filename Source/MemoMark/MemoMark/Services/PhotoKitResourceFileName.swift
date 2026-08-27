#if canImport(Photos) && !MEMOMARK_SHARE_EXTENSION
import Photos

enum PhotoKitResourceFileName {

    nonisolated static func value(
        for resource: PHAssetResource
    ) -> String {
        // `filename` is only present in newer Photos SDKs. Reading the
        // long-standing Objective-C property through KVC keeps this helper
        // source-compatible with Xcode Cloud toolchains that predate that
        // API while preserving the same filename value on current systems.
        return (resource.value(
            forKey: "originalFilename"
        ) as? String) ?? ""
    }
}
#endif

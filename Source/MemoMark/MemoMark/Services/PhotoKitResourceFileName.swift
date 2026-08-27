#if canImport(Photos) && !MEMOMARK_SHARE_EXTENSION
import Photos

enum PhotoKitResourceFileName {

    nonisolated static func value(
        for resource: PHAssetResource
    ) -> String {
        if #available(iOS 27, macOS 27, *) {
            return resource.filename ?? ""
        }

        // `filename` is unavailable before iOS/macOS 27, while the legacy
        // property is deprecated in the current SDK. Keep the old-runtime
        // fallback dynamically addressed so this compatibility path remains
        // warning-free when compiling against the new SDK.
        return (resource.value(
            forKey: "originalFilename"
        ) as? String) ?? ""
    }
}
#endif

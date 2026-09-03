import Foundation
import UniformTypeIdentifiers
#if canImport(Photos) && !MEMOMARK_SHARE_EXTENSION
import Photos
#endif

enum LivePhotoAssetIdentityResolution:
    Hashable {

    case matched(String)

    case notFound

    case ambiguous(candidateCount: Int)

    case unavailable(String)
}

protocol LivePhotoAssetIdentityResolving {

    func resolveAssetLocalIdentifier(
        for hint: LivePhotoStaticFallbackRecoveryHint
    ) -> LivePhotoAssetIdentityResolution
}

struct LivePhotoAssetIdentityCandidate:
    Hashable {

    let localIdentifier: String

    let originalFileNames: [String]

    let creationDate: Date?

    let pixelWidth: Int

    let pixelHeight: Int

    let isLivePhoto: Bool
}

enum LivePhotoAssetIdentityMatcher {

    private static let captureDateTolerance:
        TimeInterval = 300

    private static let renamedPayloadCaptureDateTolerance:
        TimeInterval = 2

    static func resolve(
        hint: LivePhotoStaticFallbackRecoveryHint,
        candidates: [LivePhotoAssetIdentityCandidate]
    ) -> LivePhotoAssetIdentityResolution {

        let datedLivePhotoCandidates =
            candidates.filter {
                $0.isLivePhoto
                && matchesCaptureDate(
                    hint.captureDate,
                    $0.creationDate,
                    tolerance:
                        captureDateTolerance
                )
            }
        let matchingFileNameCandidates =
            datedLivePhotoCandidates.filter {
                matchesFileName(
                    hint.originalFileName,
                    candidateFileNames:
                        $0.originalFileNames
                )
            }

        if !matchingFileNameCandidates.isEmpty {
            return uniqueResolution(
                matchingFileNameCandidates
            )
        }

        let renamedPayloadCandidates =
            datedLivePhotoCandidates.filter {
                matchesCaptureDate(
                    hint.captureDate,
                    $0.creationDate,
                    tolerance:
                        renamedPayloadCaptureDateTolerance
                )
                && matchesPixelSize(
                    hintWidth: hint.pixelWidth,
                    hintHeight: hint.pixelHeight,
                    candidateWidth: $0.pixelWidth,
                    candidateHeight: $0.pixelHeight
                )
            }

        return uniqueResolution(
            renamedPayloadCandidates
        )
    }

    private static func matchesCaptureDate(
        _ hintDate: Date?,
        _ candidateDate: Date?,
        tolerance: TimeInterval
    ) -> Bool {

        guard let hintDate,
              let candidateDate else {
            return false
        }

        return abs(
            hintDate.timeIntervalSince(
                candidateDate
            )
        ) <= tolerance
    }

    private static func uniqueResolution(
        _ candidates:
            [LivePhotoAssetIdentityCandidate]
    ) -> LivePhotoAssetIdentityResolution {

        guard !candidates.isEmpty else {
            return .notFound
        }

        guard candidates.count == 1,
              let match = candidates.first else {
            return .ambiguous(
                candidateCount:
                    candidates.count
            )
        }

        return .matched(
            match.localIdentifier
        )
    }

    private static func matchesPixelSize(
        hintWidth: Int?,
        hintHeight: Int?,
        candidateWidth: Int,
        candidateHeight: Int
    ) -> Bool {

        guard let hintWidth,
              let hintHeight else {
            return false
        }

        return (
            hintWidth == candidateWidth
            && hintHeight == candidateHeight
        )
        || (
            hintWidth == candidateHeight
            && hintHeight == candidateWidth
        )
    }

    private static func matchesFileName(
        _ hintFileName: String?,
        candidateFileNames: [String]
    ) -> Bool {

        guard let hintBaseName =
            normalizedBaseName(
                hintFileName
            ) else {
            return false
        }

        return candidateFileNames.contains {
            normalizedBaseName($0) == hintBaseName
        }
    }

    private static func normalizedBaseName(
        _ fileName: String?
    ) -> String? {

        let trimmed =
            fileName?
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        guard let trimmed,
              !trimmed.isEmpty else {
            return nil
        }

        return (trimmed as NSString)
            .deletingPathExtension
            .lowercased()
    }
}

enum LivePhotoStaticFallbackPolicy {

    // These transport values are intentionally repeated here because this
    // policy is compiled by the Share Extension, which does not link the main
    // app's intent and configuration-domain declarations. They are frozen
    // persisted snapshot values, not a second domain model.
    private static let staticImageModeRawValue = "staticImage"
    private static let staticImageOnlyPolicyRawValue = "staticImageOnly"

    static func allowsStaticFallback(
        mediaOutputModeRawValue: String?,
        livePhotoPolicyRawValue: String? = nil
    ) -> Bool {
        if mediaOutputModeRawValue
            == staticImageModeRawValue {
            return true
        }

        if livePhotoPolicyRawValue
            == staticImageOnlyPolicyRawValue {
            return true
        }

        // An absent or unrecognized frozen policy must not silently degrade a
        // motion-preserving request. Historical snapshots resolve their
        // explicit compatibility value before Share intake begins.
        return false
    }

    static func shouldStopAfterLiveRepresentationFailure(
        errorCode: Int?,
        mediaOutputModeRawValue: String?,
        livePhotoPolicyRawValue: String? = nil
    ) -> Bool {
        // A provider that advertises Live Photo may only vend its still image
        // to a Share Extension. That image is not an output candidate: it is
        // a temporary, local-only identity hint for the host app to resolve
        // the original Live Photo through PhotoKit. Once resolved, production
        // uses the original paired resources; if resolution is not unique,
        // ShareCoordinator preserves the Live Photo content type so the task
        // fails instead of silently rendering the still image.
        //
        // `allowsStaticFallback` remains the downstream output decision for
        // an unrecoverable hint. It must not be used to block this recovery
        // transport at the Share Extension boundary.
        _ = errorCode
        _ = mediaOutputModeRawValue
        _ = livePhotoPolicyRawValue
        return false
    }
}

#if canImport(Photos) && !MEMOMARK_SHARE_EXTENSION
struct PhotoKitLivePhotoAssetIdentityResolver:
    LivePhotoAssetIdentityResolving {

    func resolveAssetLocalIdentifier(
        for hint: LivePhotoStaticFallbackRecoveryHint
    ) -> LivePhotoAssetIdentityResolution {

        guard PhotoProcessingInputPolicy
            .livePhotoTypeIdentifiers
            .contains(
                hint.advertisedLivePhotoTypeIdentifier
            )
        else {
            return .unavailable(
                "advertisedTypeNotLivePhoto"
            )
        }

        guard let captureDate = hint.captureDate else {
            return .unavailable(
                "captureDateMissing"
            )
        }

        let status =
            PHPhotoLibrary
            .authorizationStatus(
                for: .readWrite
            )

        guard status == .authorized
              || status == .limited else {
            return .unavailable(
                "photoLibraryStatus=\(status.rawValue)"
            )
        }

        let fetchOptions =
            PHFetchOptions()
        fetchOptions.predicate =
            NSPredicate(
                format:
                    "mediaType == %d AND creationDate >= %@ AND creationDate <= %@",
                PHAssetMediaType.image.rawValue,
                captureDate.addingTimeInterval(-300) as NSDate,
                captureDate.addingTimeInterval(300) as NSDate
            )
        fetchOptions.sortDescriptors = [
            NSSortDescriptor(
                key: "creationDate",
                ascending: true
            )
        ]
        fetchOptions.fetchLimit = 80

        let assets =
            PHAsset.fetchAssets(
                with: fetchOptions
            )
        var candidates:
            [LivePhotoAssetIdentityCandidate] = []

        assets.enumerateObjects {
            asset,
            _,
            _ in

            guard asset.mediaSubtypes
                .contains(.photoLive) else {
                return
            }

            let resources =
                PHAssetResource
                .assetResources(
                    for: asset
                )

            candidates.append(
                LivePhotoAssetIdentityCandidate(
                    localIdentifier:
                        asset.localIdentifier,
                    originalFileNames:
                        resources.map(
                            {
                                PhotoKitResourceFileName.value(
                                    for: $0
                                )
                            }
                        ),
                    creationDate:
                        asset.creationDate,
                    pixelWidth:
                        asset.pixelWidth,
                    pixelHeight:
                        asset.pixelHeight,
                    isLivePhoto: true
                )
            )
        }

        return LivePhotoAssetIdentityMatcher
            .resolve(
                hint: hint,
                candidates: candidates
            )
    }
}
#else
struct PhotoKitLivePhotoAssetIdentityResolver:
    LivePhotoAssetIdentityResolving {

    func resolveAssetLocalIdentifier(
        for hint: LivePhotoStaticFallbackRecoveryHint
    ) -> LivePhotoAssetIdentityResolution {

        .unavailable(
            "photoKitUnavailable"
        )
    }
}
#endif

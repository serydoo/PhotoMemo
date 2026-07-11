import Foundation
import UniformTypeIdentifiers
#if canImport(Photos) && !PHOTOMEMO_SHARE_EXTENSION
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

    static func resolve(
        hint: LivePhotoStaticFallbackRecoveryHint,
        candidates: [LivePhotoAssetIdentityCandidate]
    ) -> LivePhotoAssetIdentityResolution {

        let matches =
            candidates.filter {
                matchScore(
                    hint: hint,
                    candidate: $0
                ) >= 4
            }

        guard !matches.isEmpty else {
            return .notFound
        }

        guard matches.count == 1,
              let match = matches.first else {
            return .ambiguous(
                candidateCount:
                    matches.count
            )
        }

        return .matched(
            match.localIdentifier
        )
    }

    private static func matchScore(
        hint: LivePhotoStaticFallbackRecoveryHint,
        candidate: LivePhotoAssetIdentityCandidate
    ) -> Int {

        guard candidate.isLivePhoto else {
            return 0
        }

        guard matchesCaptureDate(
            hint.captureDate,
            candidate.creationDate
        ) else {
            return 0
        }

        var score = 0

        score += 2

        guard matchesFileName(
            hint.originalFileName,
            candidateFileNames:
                candidate.originalFileNames
        ) else {
            return 0
        }

        score += 3

        if matchesPixelSize(
            hintWidth: hint.pixelWidth,
            hintHeight: hint.pixelHeight,
            candidateWidth: candidate.pixelWidth,
            candidateHeight: candidate.pixelHeight
        ) {
            score += 2
        }

        return score
    }

    private static func matchesCaptureDate(
        _ hintDate: Date?,
        _ candidateDate: Date?
    ) -> Bool {

        guard let hintDate,
              let candidateDate else {
            return false
        }

        return abs(
            hintDate.timeIntervalSince(
                candidateDate
            )
        ) <= captureDateTolerance
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

#if canImport(Photos) && !PHOTOMEMO_SHARE_EXTENSION
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
                            \.originalFilename
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

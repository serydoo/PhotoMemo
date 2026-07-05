import Foundation

struct LocationResolution:
    Hashable,
    Codable {

    let requestedPresentation: LocationPresentationMode

    let resolvedPresentation: LocationPresentationMode?

    let resolutionPolicy: LocationResolutionPolicy

    init(
        requestedPresentation: LocationPresentationMode,
        resolvedPresentation: LocationPresentationMode?,
        resolutionPolicy: LocationResolutionPolicy
    ) {
        self.requestedPresentation =
            requestedPresentation
        self.resolvedPresentation =
            resolvedPresentation
        self.resolutionPolicy =
            resolutionPolicy
    }
}

enum LocationResolutionPolicy:
    String,
    Hashable,
    Codable {

    case direct

    case downgraded

    case coordinateFallback

    case empty
}

struct LocationResolutionConfiguration:
    Hashable,
    Codable {

    var allowsCoordinateFallback: Bool

    init(
        allowsCoordinateFallback: Bool = false
    ) {
        self.allowsCoordinateFallback =
            allowsCoordinateFallback
    }
}

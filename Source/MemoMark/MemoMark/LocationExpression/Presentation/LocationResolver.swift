import Foundation

struct LocationResolver {

    func resolve(
        context: LocationContext,
        requestedPresentation: LocationPresentationMode,
        configuration: LocationResolutionConfiguration =
            LocationResolutionConfiguration()
    ) -> LocationResolution {

        if hasContent(
            context: context,
            presentation: requestedPresentation
        ) {
            return LocationResolution(
                requestedPresentation: requestedPresentation,
                resolvedPresentation: requestedPresentation,
                resolutionPolicy: .direct
            )
        }

        if let downgradedPresentation =
            downgradedPresentation(
                context: context,
                requestedPresentation: requestedPresentation
            ) {
            return LocationResolution(
                requestedPresentation: requestedPresentation,
                resolvedPresentation: downgradedPresentation,
                resolutionPolicy: .downgraded
            )
        }

        if
            configuration.allowsCoordinateFallback,
            hasContent(
                context: context,
                presentation: .coordinate
            ) {
            return LocationResolution(
                requestedPresentation: requestedPresentation,
                resolvedPresentation: .coordinate,
                resolutionPolicy: .coordinateFallback
            )
        }

        return LocationResolution(
            requestedPresentation: requestedPresentation,
            resolvedPresentation: nil,
            resolutionPolicy: .empty
        )
    }
}

private extension LocationResolver {

    func downgradedPresentation(
        context: LocationContext,
        requestedPresentation: LocationPresentationMode
    ) -> LocationPresentationMode? {

        switch requestedPresentation {

        case .provinceCity:
            return hasContent(
                context: context,
                presentation: .cityDistrict
            )
            ? .cityDistrict
            : nil

        case .provinceCityDistrict:
            if hasContent(
                context: context,
                presentation: .provinceCity
            ) {
                return .provinceCity
            }

            return hasContent(
                context: context,
                presentation: .cityDistrict
            )
            ? .cityDistrict
            : nil

        case .cityDistrict,
             .legacyDisplay,
             .coordinate:
            return nil
        }
    }

    func hasContent(
        context: LocationContext,
        presentation: LocationPresentationMode
    ) -> Bool {

        switch presentation {

        case .provinceCity:
            return hasValue(
                context.address?.province
            )
            && hasValue(
                context.address?.city
            )

        case .cityDistrict:
            return hasValue(
                context.address?.city
            )
            && hasValue(
                context.address?.district
            )

        case .provinceCityDistrict:
            return hasValue(
                context.address?.province
            )
            && hasValue(
                context.address?.city
            )
            && hasValue(
                context.address?.district
            )

        case .coordinate:
            return context.coordinate != nil

        case .legacyDisplay:
            return hasValue(
                context.address?.name
            )
            || hasValue(
                context.address?.country
            )
            || hasValue(
                context.address?.province
            )
            || hasValue(
                context.address?.city
            )
            || hasValue(
                context.address?.district
            )
            || context.coordinate != nil
        }
    }

    func hasValue(
        _ value: String?
    ) -> Bool {

        guard let value else {
            return false
        }

        return !value
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            )
            .isEmpty
    }
}

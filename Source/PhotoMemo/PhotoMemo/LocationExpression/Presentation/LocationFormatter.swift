import Foundation

struct LocationFormatter {

    func format(
        context: LocationContext,
        resolution: LocationResolution
    ) -> String {

        guard
            let resolvedPresentation =
                resolution.resolvedPresentation
        else {
            return ""
        }

        return format(
            context: context,
            mode: resolvedPresentation
        )
    }

    func format(
        context: LocationContext,
        mode: LocationPresentationMode
    ) -> String {
        switch mode {

        case .provinceCity:
            return formatAddressParts([
                context.address?.province,
                context.address?.city
            ])

        case .cityDistrict:
            return formatAddressParts([
                context.address?.city,
                context.address?.district
            ])

        case .provinceCityDistrict:
            return formatAddressParts([
                context.address?.province,
                context.address?.city,
                context.address?.district
            ])

        case .coordinate:
            return formatCoordinate(
                context.coordinate
            )
        }
    }
}

private extension LocationFormatter {

    func formatAddressParts(
        _ parts: [String?]
    ) -> String {

        uniqueNonEmptyParts(
            parts
        )
        .joined(
            separator: " · "
        )
    }

    func formatCoordinate(
        _ coordinate: LocationCoordinate?
    ) -> String {

        guard let coordinate else {
            return ""
        }

        return String(
            format: "%.6f, %.6f",
            coordinate.latitude,
            coordinate.longitude
        )
    }

    func uniqueNonEmptyParts(
        _ parts: [String?]
    ) -> [String] {

        var result: [String] = []

        for part in parts {
            guard
                let part =
                    part?.trimmingCharacters(
                        in: .whitespacesAndNewlines
                    ),
                !part.isEmpty,
                !result.contains(part)
            else {
                continue
            }

            result.append(
                part
            )
        }

        return result
    }
}

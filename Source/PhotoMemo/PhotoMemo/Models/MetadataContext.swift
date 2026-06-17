import Foundation

struct MetadataContext: Hashable, Codable {

    private(set) var values: [String: String] = [:]

    init(values: [String: String] = [:]) {
        self.values = values
    }

    subscript(key: String) -> String {

        values[key] ?? ""
    }

    mutating func set(
        _ value: String?,
        for key: String
    ) {

        guard let value else {
            return
        }

        guard !value.isEmpty else {
            return
        }

        values[key] = value
    }

    mutating func set(
        _ value: Int?,
        for key: String
    ) {

        guard let value else {
            return
        }

        values[key] = "\(value)"
    }

    mutating func set(
        _ value: Double?,
        for key: String
    ) {

        guard let value else {
            return
        }

        values[key] = "\(value)"
    }
}

extension MetadataContext {

    static func build(
        from metadata: PhotoMetadata
    ) -> MetadataContext {

        var context = MetadataContext()

        context.set(
            metadata.deviceBrand,
            for: "brand"
        )

        context.set(
            metadata.deviceModel,
            for: "model"
        )

        context.set(
            metadata.lensModel,
            for: "lens"
        )

        context.set(
            metadata.iso,
            for: "iso"
        )

        context.set(
            metadata.aperture,
            for: "aperture"
        )

        context.set(
            metadata.shutterSpeed,
            for: "shutter"
        )

        context.set(
            metadata.focalLength,
            for: "focal_length"
        )

        context.set(
            metadata.focalLength35mm,
            for: "focal_len_in_35mm_film"
        )

        context.set(
            metadata.imageWidth,
            for: "width"
        )

        context.set(
            metadata.imageHeight,
            for: "height"
        )

        context.set(
            metadata.latitude,
            for: "latitude"
        )

        context.set(
            metadata.longitude,
            for: "longitude"
        )

        context.set(
            metadata.altitude,
            for: "altitude"
        )

        context.set(
            metadata.city,
            for: "city"
        )

        context.set(
            metadata.district,
            for: "district"
        )

        context.set(
            metadata.province,
            for: "province"
        )

        context.set(
            metadata.country,
            for: "country"
        )

        context.set(
            metadata.locationName,
            for: "location"
        )

        if let date = metadata.captureDate {

            let calendar =
                Calendar.current

            let year =
                calendar.component(
                    .year,
                    from: date
                )

            let month =
                calendar.component(
                    .month,
                    from: date
                )

            let day =
                calendar.component(
                    .day,
                    from: date
                )

            let hour =
                calendar.component(
                    .hour,
                    from: date
                )

            let minute =
                calendar.component(
                    .minute,
                    from: date
                )

            let second =
                calendar.component(
                    .second,
                    from: date
                )

            context.set(
                "\(year)",
                for: "year"
            )

            context.set(
                padded(month),
                for: "month"
            )

            context.set(
                padded(day),
                for: "day"
            )

            context.set(
                padded(hour),
                for: "hour"
            )

            context.set(
                padded(minute),
                for: "minute"
            )

            context.set(
                padded(second),
                for: "second"
            )

            context.set(
                calendar.component(
                    .weekday,
                    from: date
                ),
                for: "weekday"
            )

            let formatter =
                DateFormatter()

            formatter.locale =
                Locale(identifier: "en_US_POSIX")

            formatter.dateFormat = "EEEE"

            context.set(
                formatter.string(from: date),
                for: "weekday_name"
            )
        }

        return context
    }

    private static func padded(
        _ value: Int
    ) -> String {

        String(format: "%02d", value)
    }
}

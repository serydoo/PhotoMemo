import Foundation

struct MetadataContext: Hashable, Codable {

    enum Key {

        static let brand = "brand"

        static let model = "model"

        static let lens = "lens"

        static let lensBrand = "lens_brand"

        static let iso = "iso"

        static let aperture = "aperture"

        static let shutter = "shutter"

        static let focalLength = "focal_length"

        static let focalLength35mm =
            "focal_len_in_35mm_film"

        static let width = "width"

        static let height = "height"

        static let orientation = "orientation"

        static let aspectRatio = "aspect_ratio"

        static let megapixels = "megapixels"

        static let latitude = "latitude"

        static let longitude = "longitude"

        static let altitude = "altitude"

        static let city = "city"

        static let district = "district"

        static let province = "province"

        static let country = "country"

        static let location = "location"

        static let locationDisplay =
            "location_display"

        static let year = "year"

        static let month = "month"

        static let day = "day"

        static let hour = "hour"

        static let minute = "minute"

        static let second = "second"

        static let weekday = "weekday"

        static let weekdayName =
            "weekday_name"

        static let captureDateShort =
            "capture_date_short"

        static let captureTimeShort =
            "capture_time_short"

        static let captureTimezone =
            "capture_timezone"

        static let title = "title"

        static let relationshipLabel =
            "relationship_label"

        static let story = "story"

        static let tags = "tags"

        static let badgeName = "badge_name"

        static let captureDateDisplay =
            "capture_date_display"

        static let cameraSummary =
            "camera_summary"

        static let daysSince =
            "days_since"

        static let yearsSince =
            "years_since"

        static let monthsSince =
            "months_since"

        static let weeksSince =
            "weeks_since"

        static let babyAge =
            "baby_age"

        static let memorySummary =
            "memory_summary"

        static let anchorTitle =
            "anchor_title"

        static let anchorPrimary =
            "anchor_primary"

        static let anchorSecondary =
            "anchor_secondary"

        static let anchorSummary =
            "anchor_summary"

        static let anchorSmartText =
            "anchor_smart_text"

        static let anchorCountdownText =
            "anchor_countdown_text"

        static let anchorAgeText =
            "anchor_age_text"

        static let anchorDurationText =
            "anchor_duration_text"

        static let anchorTotalDaysText =
            "anchor_total_days_text"

        static let anchorElapsedText =
            "anchor_elapsed_text"

        static let anchorDayIndexText =
            "anchor_day_index_text"

        static let anchorWeekText =
            "anchor_week_text"

        static let anchorMonthAgeText =
            "anchor_month_age_text"

        static let anchorMilestoneText =
            "anchor_milestone_text"

        static let anchorYears =
            "anchor_years"

        static let anchorMonths =
            "anchor_months"

        static let anchorDays =
            "anchor_days"

        static let anchorHours =
            "anchor_hours"

        static let anchorMinutes =
            "anchor_minutes"

        static let anchorSeconds =
            "anchor_seconds"

        static let anchorTotalDays =
            "anchor_total_days"
    }

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
            metadata.normalizedDeviceBrand,
            for: Key.brand
        )

        context.set(
            metadata.normalizedDeviceModel,
            for: Key.model
        )

        context.set(
            metadata.normalizedLensModel,
            for: Key.lens
        )

        context.set(
            metadata.normalizedLensBrand,
            for: Key.lensBrand
        )

        context.set(
            metadata.iso,
            for: Key.iso
        )

        context.set(
            metadata.aperture,
            for: Key.aperture
        )

        context.set(
            metadata.shutterSpeed,
            for: Key.shutter
        )

        context.set(
            metadata.focalLength,
            for: Key.focalLength
        )

        context.set(
            metadata.focalLength35mm,
            for: Key.focalLength35mm
        )

        context.set(
            metadata.imageWidth,
            for: Key.width
        )

        context.set(
            metadata.imageHeight,
            for: Key.height
        )

        context.set(
            metadata.orientationText,
            for: Key.orientation
        )

        context.set(
            metadata.aspectRatioText,
            for: Key.aspectRatio
        )

        context.set(
            metadata.megapixelsText,
            for: Key.megapixels
        )

        context.set(
            metadata.latitudeText,
            for: Key.latitude
        )

        context.set(
            metadata.longitudeText,
            for: Key.longitude
        )

        context.set(
            metadata.altitudeText,
            for: Key.altitude
        )

        context.set(
            metadata.normalizedCity,
            for: Key.city
        )

        context.set(
            metadata.normalizedDistrict,
            for: Key.district
        )

        context.set(
            metadata.normalizedProvince,
            for: Key.province
        )

        context.set(
            metadata.normalizedCountry,
            for: Key.country
        )

        context.set(
            metadata.normalizedLocationName,
            for: Key.location
        )

        context.set(
            metadata.locationDisplay,
            for: Key.locationDisplay
        )

        context.set(
            metadata.captureDateShortText,
            for: Key.captureDateShort
        )

        context.set(
            metadata.captureTimeShortText,
            for: Key.captureTimeShort
        )

        context.set(
            metadata.captureTimezoneText,
            for: Key.captureTimezone
        )

        if let date = metadata.captureDate {

            let calendar =
                metadata.captureCalendar

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
                for: Key.year
            )

            context.set(
                padded(month),
                for: Key.month
            )

            context.set(
                padded(day),
                for: Key.day
            )

            context.set(
                padded(hour),
                for: Key.hour
            )

            context.set(
                padded(minute),
                for: Key.minute
            )

            context.set(
                padded(second),
                for: Key.second
            )

            context.set(
                calendar.component(
                    .weekday,
                    from: date
                ),
                for: Key.weekday
            )

            let formatter =
                DateFormatter()

            formatter.locale =
                Locale(identifier: "en_US_POSIX")

            formatter.dateFormat = "EEEE"

            if let captureTimeZone =
                metadata.captureTimeZone {
                formatter.timeZone =
                    captureTimeZone
            }

            context.set(
                formatter.string(from: date),
                for: Key.weekdayName
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

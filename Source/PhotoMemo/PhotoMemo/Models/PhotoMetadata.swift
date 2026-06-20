import Foundation

struct PhotoMetadataFieldDefinition: Hashable {

    let fieldName: String

    let swiftType: String

    let source: String

    let owner: String

    let publicVariables: [String]

    let isInternalOnly: Bool

    let defaultValue: String

    let documentation: String
}

struct PhotoMetadata: Hashable, Codable {

    var captureDate: Date?

    var captureTimezoneOffsetSeconds: Int?

    var deviceBrand: String

    var deviceModel: String

    var lensModel: String

    var iso: String

    var aperture: String

    var shutterSpeed: String

    var focalLength: String

    var focalLength35mm: String

    var imageWidth: Int?

    var imageHeight: Int?

    var latitude: Double?

    var longitude: Double?

    var altitude: Double?

    var city: String?

    var district: String?

    var province: String?

    var country: String?

    var locationName: String?

    init(
        captureDate: Date? = nil,
        captureTimezoneOffsetSeconds: Int? = nil,
        deviceBrand: String = "",
        deviceModel: String = "",
        lensModel: String = "",
        iso: String = "",
        aperture: String = "",
        shutterSpeed: String = "",
        focalLength: String = "",
        focalLength35mm: String = "",
        imageWidth: Int? = nil,
        imageHeight: Int? = nil,
        latitude: Double? = nil,
        longitude: Double? = nil,
        altitude: Double? = nil,
        city: String? = nil,
        district: String? = nil,
        province: String? = nil,
        country: String? = nil,
        locationName: String? = nil
    ) {
        self.captureDate = captureDate
        self.captureTimezoneOffsetSeconds =
            captureTimezoneOffsetSeconds
        self.deviceBrand = deviceBrand
        self.deviceModel = deviceModel
        self.lensModel = lensModel
        self.iso = iso
        self.aperture = aperture
        self.shutterSpeed = shutterSpeed
        self.focalLength = focalLength
        self.focalLength35mm = focalLength35mm
        self.imageWidth = imageWidth
        self.imageHeight = imageHeight
        self.latitude = latitude
        self.longitude = longitude
        self.altitude = altitude
        self.city = city
        self.district = district
        self.province = province
        self.country = country
        self.locationName = locationName
    }
}

extension PhotoMetadata {

    enum Orientation: String, Codable, CaseIterable {

        case portrait

        case landscape

        case square

        var displayValue: String {

            switch self {

            case .portrait:
                return "纵向"

            case .landscape:
                return "横向"

            case .square:
                return "方形"
            }
        }
    }

    static let canonicalInventory:
        [PhotoMetadataFieldDefinition] = [

            PhotoMetadataFieldDefinition(
                fieldName: "captureDate",
                swiftType: "Date?",
                source: "TIFF DateTime, EXIF DateTimeOriginal",
                owner: "PhotoMetadata",
                publicVariables: [
                    "year",
                    "month",
                    "day",
                    "hour",
                    "minute",
                    "second",
                    "weekday",
                    "weekday_name",
                    "capture_date_display",
                    "capture_date_short",
                    "capture_time_short"
                ],
                isInternalOnly: false,
                defaultValue: "nil",
                documentation: "Canonical capture timestamp used by anchor, preview, export description, and save-back creation date."
            ),

            PhotoMetadataFieldDefinition(
                fieldName: "captureTimezoneOffsetSeconds",
                swiftType: "Int?",
                source: "Timezone suffix parsed from capture-date metadata when available",
                owner: "PhotoMetadata",
                publicVariables: [
                    "capture_timezone"
                ],
                isInternalOnly: false,
                defaultValue: "nil",
                documentation: "Optional capture-time timezone offset preserved separately so date components can be rendered consistently."
            ),

            PhotoMetadataFieldDefinition(
                fieldName: "deviceBrand",
                swiftType: "String",
                source: "TIFF Make",
                owner: "PhotoMetadata",
                publicVariables: [
                    "brand"
                ],
                isInternalOnly: false,
                defaultValue: "\"\"",
                documentation: "Normalized camera or device manufacturer."
            ),

            PhotoMetadataFieldDefinition(
                fieldName: "deviceModel",
                swiftType: "String",
                source: "TIFF Model",
                owner: "PhotoMetadata",
                publicVariables: [
                    "model"
                ],
                isInternalOnly: false,
                defaultValue: "\"\"",
                documentation: "Normalized camera or device model."
            ),

            PhotoMetadataFieldDefinition(
                fieldName: "lensModel",
                swiftType: "String",
                source: "EXIF LensModel",
                owner: "PhotoMetadata",
                publicVariables: [
                    "lens"
                ],
                isInternalOnly: false,
                defaultValue: "\"\"",
                documentation: "Normalized full lens model string."
            ),

            PhotoMetadataFieldDefinition(
                fieldName: "lensBrand",
                swiftType: "String",
                source: "Derived from lensModel",
                owner: "PhotoMetadata",
                publicVariables: [
                    "lens_brand"
                ],
                isInternalOnly: false,
                defaultValue: "\"\"",
                documentation: "Brand prefix derived from the normalized lens model when available."
            ),

            PhotoMetadataFieldDefinition(
                fieldName: "iso",
                swiftType: "String",
                source: "EXIF ISOSpeedRatings",
                owner: "PhotoMetadata",
                publicVariables: [
                    "iso"
                ],
                isInternalOnly: false,
                defaultValue: "\"\"",
                documentation: "Normalized ISO value."
            ),

            PhotoMetadataFieldDefinition(
                fieldName: "aperture",
                swiftType: "String",
                source: "EXIF FNumber",
                owner: "PhotoMetadata",
                publicVariables: [
                    "aperture"
                ],
                isInternalOnly: false,
                defaultValue: "\"\"",
                documentation: "Normalized aperture value without the f/ prefix."
            ),

            PhotoMetadataFieldDefinition(
                fieldName: "shutterSpeed",
                swiftType: "String",
                source: "EXIF ExposureTime",
                owner: "PhotoMetadata",
                publicVariables: [
                    "shutter"
                ],
                isInternalOnly: false,
                defaultValue: "\"\"",
                documentation: "Normalized shutter speed string."
            ),

            PhotoMetadataFieldDefinition(
                fieldName: "focalLength",
                swiftType: "String",
                source: "EXIF FocalLength",
                owner: "PhotoMetadata",
                publicVariables: [
                    "focal_length"
                ],
                isInternalOnly: false,
                defaultValue: "\"\"",
                documentation: "Normalized focal length."
            ),

            PhotoMetadataFieldDefinition(
                fieldName: "focalLength35mm",
                swiftType: "String",
                source: "EXIF FocalLenIn35mmFilm",
                owner: "PhotoMetadata",
                publicVariables: [
                    "focal_len_in_35mm_film"
                ],
                isInternalOnly: false,
                defaultValue: "\"\"",
                documentation: "Normalized 35mm-equivalent focal length."
            ),

            PhotoMetadataFieldDefinition(
                fieldName: "imageWidth",
                swiftType: "Int?",
                source: "ImageIO PixelWidth",
                owner: "PhotoMetadata",
                publicVariables: [
                    "width",
                    "orientation",
                    "aspect_ratio",
                    "megapixels"
                ],
                isInternalOnly: false,
                defaultValue: "nil",
                documentation: "Source image pixel width used for layout and derived photo-shape variables."
            ),

            PhotoMetadataFieldDefinition(
                fieldName: "imageHeight",
                swiftType: "Int?",
                source: "ImageIO PixelHeight",
                owner: "PhotoMetadata",
                publicVariables: [
                    "height",
                    "orientation",
                    "aspect_ratio",
                    "megapixels"
                ],
                isInternalOnly: false,
                defaultValue: "nil",
                documentation: "Source image pixel height used for layout and derived photo-shape variables."
            ),

            PhotoMetadataFieldDefinition(
                fieldName: "latitude",
                swiftType: "Double?",
                source: "GPS Latitude + LatitudeRef",
                owner: "PhotoMetadata",
                publicVariables: [
                    "latitude",
                    "location_display"
                ],
                isInternalOnly: false,
                defaultValue: "nil",
                documentation: "Normalized signed latitude."
            ),

            PhotoMetadataFieldDefinition(
                fieldName: "longitude",
                swiftType: "Double?",
                source: "GPS Longitude + LongitudeRef",
                owner: "PhotoMetadata",
                publicVariables: [
                    "longitude",
                    "location_display"
                ],
                isInternalOnly: false,
                defaultValue: "nil",
                documentation: "Normalized signed longitude."
            ),

            PhotoMetadataFieldDefinition(
                fieldName: "altitude",
                swiftType: "Double?",
                source: "GPS Altitude + AltitudeRef",
                owner: "PhotoMetadata",
                publicVariables: [
                    "altitude"
                ],
                isInternalOnly: false,
                defaultValue: "nil",
                documentation: "Normalized altitude in meters."
            ),

            PhotoMetadataFieldDefinition(
                fieldName: "country",
                swiftType: "String?",
                source: "Location enrichment or imported friendly metadata",
                owner: "PhotoMetadata",
                publicVariables: [
                    "country",
                    "location_display"
                ],
                isInternalOnly: false,
                defaultValue: "nil",
                documentation: "Friendly normalized country name when available."
            ),

            PhotoMetadataFieldDefinition(
                fieldName: "province",
                swiftType: "String?",
                source: "Location enrichment or imported friendly metadata",
                owner: "PhotoMetadata",
                publicVariables: [
                    "province",
                    "location_display"
                ],
                isInternalOnly: false,
                defaultValue: "nil",
                documentation: "Friendly normalized province or state name when available."
            ),

            PhotoMetadataFieldDefinition(
                fieldName: "city",
                swiftType: "String?",
                source: "Location enrichment or imported friendly metadata",
                owner: "PhotoMetadata",
                publicVariables: [
                    "city",
                    "location_display"
                ],
                isInternalOnly: false,
                defaultValue: "nil",
                documentation: "Friendly normalized city name when available."
            ),

            PhotoMetadataFieldDefinition(
                fieldName: "district",
                swiftType: "String?",
                source: "Location enrichment or imported friendly metadata",
                owner: "PhotoMetadata",
                publicVariables: [
                    "district",
                    "location_display"
                ],
                isInternalOnly: false,
                defaultValue: "nil",
                documentation: "Friendly normalized district name when available."
            ),

            PhotoMetadataFieldDefinition(
                fieldName: "locationName",
                swiftType: "String?",
                source: "Location enrichment or imported friendly metadata",
                owner: "PhotoMetadata",
                publicVariables: [
                    "location",
                    "location_display"
                ],
                isInternalOnly: false,
                defaultValue: "nil",
                documentation: "Friendly preferred location label when available."
            )
        ]

    var normalizedDeviceBrand: String {

        Self.normalizedBrandName(
            deviceBrand
        )
    }

    var normalizedDeviceModel: String {

        Self.normalizedDisplayString(
            deviceModel
        )
    }

    var normalizedLensModel: String {

        Self.normalizedDisplayString(
            lensModel
        )
    }

    var normalizedLensBrand: String {

        guard
            let firstToken =
                normalizedLensModel
                .split(
                    whereSeparator: \.isWhitespace
                )
                .first
        else {
            return ""
        }

        return Self.normalizedBrandName(
            String(firstToken)
        )
    }

    var normalizedCountry: String? {

        Self.optionalNormalizedDisplayString(
            country
        )
    }

    var normalizedProvince: String? {

        Self.optionalNormalizedDisplayString(
            province
        )
    }

    var normalizedCity: String? {

        Self.optionalNormalizedDisplayString(
            city
        )
    }

    var normalizedDistrict: String? {

        Self.optionalNormalizedDisplayString(
            district
        )
    }

    var normalizedLocationName: String? {

        Self.optionalNormalizedDisplayString(
            locationName
        )
    }

    var normalizedLatitude: Double? {

        Self.normalizedLatitude(
            latitude
        )
    }

    var normalizedLongitude: Double? {

        Self.normalizedLongitude(
            longitude
        )
    }

    var normalizedAltitude: Double? {

        Self.normalizedAltitude(
            altitude
        )
    }

    var latitudeText: String {

        Self.formattedCoordinate(
            normalizedLatitude
        )
    }

    var longitudeText: String {

        Self.formattedCoordinate(
            normalizedLongitude
        )
    }

    var altitudeText: String {

        Self.formattedAltitude(
            normalizedAltitude
        )
    }

    var orientation: Orientation? {

        guard
            let width = imageWidth,
            let height = imageHeight,
            width > 0,
            height > 0
        else {
            return nil
        }

        if width == height {
            return .square
        }

        return width > height
            ? .landscape
            : .portrait
    }

    var orientationText: String {

        orientation?.displayValue ?? ""
    }

    var aspectRatioText: String {

        guard
            let width = imageWidth,
            let height = imageHeight,
            width > 0,
            height > 0
        else {
            return ""
        }

        let divisor =
            Self.greatestCommonDivisor(
                width,
                height
            )

        guard divisor > 0 else {
            return ""
        }

        return "\(width / divisor):\(height / divisor)"
    }

    var megapixelsText: String {

        guard
            let width = imageWidth,
            let height = imageHeight,
            width > 0,
            height > 0
        else {
            return ""
        }

        let megapixels =
            Double(width * height)
            / 1_000_000

        guard megapixels > 0 else {
            return ""
        }

        let value =
            megapixels >= 10
            ? String(
                format: "%.1f",
                megapixels
            )
            : String(
                format: "%.2f",
                megapixels
            )

        return "\(value)MP"
    }

    var captureTimeZone: TimeZone? {

        guard
            let captureTimezoneOffsetSeconds
        else {
            return nil
        }

        return TimeZone(
            secondsFromGMT:
                captureTimezoneOffsetSeconds
        )
    }

    var captureTimezoneText: String {

        guard
            let captureTimezoneOffsetSeconds
        else {
            return ""
        }

        if captureTimezoneOffsetSeconds == 0 {
            return "UTC"
        }

        let sign =
            captureTimezoneOffsetSeconds >= 0
            ? "+"
            : "-"

        let absoluteOffset =
            abs(captureTimezoneOffsetSeconds)

        let hours =
            absoluteOffset / 3600

        let minutes =
            (absoluteOffset % 3600) / 60

        return String(
            format: "UTC%@%02d:%02d",
            sign,
            hours,
            minutes
        )
    }

    var captureDateShortText: String {

        Self.formattedDate(
            captureDate,
            timeZone: captureTimeZone,
            format: "yyyy.MM.dd"
        )
    }

    var captureTimeShortText: String {

        Self.formattedDate(
            captureDate,
            timeZone: captureTimeZone,
            format: "HH:mm"
        )
    }

    var captureDateDisplayText: String {

        Self.formattedDate(
            captureDate,
            timeZone: captureTimeZone,
            format: "yyyy.MM.dd HH:mm:ss"
        )
    }

    var captureCalendar: Calendar {

        var calendar =
            Calendar.current

        if let captureTimeZone {
            calendar.timeZone =
                captureTimeZone
        }

        return calendar
    }

    var locationDisplay: String {

        if let normalizedLocationName {
            return normalizedLocationName
        }

        let hierarchy = [
            normalizedCountry,
            normalizedProvince,
            normalizedCity,
            normalizedDistrict
        ]
        .compactMap { $0 }
        .reduce(into: [String]()) {
            partialResult,
            value in

            if !partialResult.contains(value) {
                partialResult.append(value)
            }
        }

        if !hierarchy.isEmpty {
            return hierarchy.joined(
                separator: " · "
            )
        }

        let latitudeText =
            latitudeText

        let longitudeText =
            longitudeText

        guard
            !latitudeText.isEmpty,
            !longitudeText.isEmpty
        else {
            return ""
        }

        return "\(latitudeText), \(longitudeText)"
    }

    func normalized() -> PhotoMetadata {

        var normalized = self

        normalized.deviceBrand =
            normalizedDeviceBrand

        normalized.deviceModel =
            normalizedDeviceModel

        normalized.lensModel =
            normalizedLensModel

        normalized.iso =
            Self.normalizedDisplayString(
                iso
            )

        normalized.aperture =
            Self.normalizedDisplayString(
                aperture
            )

        normalized.shutterSpeed =
            Self.normalizedDisplayString(
                shutterSpeed
            )

        normalized.focalLength =
            Self.normalizedDisplayString(
                focalLength
            )

        normalized.focalLength35mm =
            Self.normalizedDisplayString(
                focalLength35mm
            )

        normalized.imageWidth =
            Self.normalizedDimension(
                imageWidth
            )

        normalized.imageHeight =
            Self.normalizedDimension(
                imageHeight
            )

        normalized.latitude =
            normalizedLatitude

        normalized.longitude =
            normalizedLongitude

        normalized.altitude =
            normalizedAltitude

        normalized.country =
            normalizedCountry

        normalized.province =
            normalizedProvince

        normalized.city =
            normalizedCity

        normalized.district =
            normalizedDistrict

        normalized.locationName =
            normalizedLocationName

        normalized.captureTimezoneOffsetSeconds =
            Self.normalizedTimezoneOffset(
                captureTimezoneOffsetSeconds
            )

        return normalized
    }
}

private extension PhotoMetadata {

    static func normalizedBrandName(
        _ value: String
    ) -> String {

        let cleanedValue =
            normalizedDisplayString(value)

        guard !cleanedValue.isEmpty else {
            return ""
        }

        let uppercasedValue =
            cleanedValue.uppercased()

        let knownBrands: [String: String] = [
            "APPLE": "Apple",
            "CANON": "Canon",
            "FUJIFILM": "Fujifilm",
            "GOOGLE": "Google",
            "HASSELBLAD": "Hasselblad",
            "HUAWEI": "Huawei",
            "LEICA": "Leica",
            "NIKON": "Nikon",
            "OLYMPUS": "Olympus",
            "OM SYSTEM": "OM System",
            "PANASONIC": "Panasonic",
            "PENTAX": "Pentax",
            "RICOH": "Ricoh",
            "SAMSUNG": "Samsung",
            "SIGMA": "Sigma",
            "SONY": "Sony",
            "XIAOMI": "Xiaomi"
        ]

        return knownBrands[
            uppercasedValue
        ] ?? cleanedValue
    }

    static func normalizedDisplayString(
        _ value: String
    ) -> String {

        value
            .components(
                separatedBy: .whitespacesAndNewlines
            )
            .filter {
                !$0.isEmpty
            }
            .joined(separator: " ")
    }

    static func optionalNormalizedDisplayString(
        _ value: String?
    ) -> String? {

        guard let value else {
            return nil
        }

        let cleanedValue =
            normalizedDisplayString(
                value
            )

        guard !cleanedValue.isEmpty else {
            return nil
        }

        return cleanedValue
    }

    static func normalizedDimension(
        _ value: Int?
    ) -> Int? {

        guard
            let value,
            value > 0
        else {
            return nil
        }

        return value
    }

    static func normalizedLatitude(
        _ value: Double?
    ) -> Double? {

        normalizedCoordinate(
            value,
            min: -90,
            max: 90
        )
    }

    static func normalizedLongitude(
        _ value: Double?
    ) -> Double? {

        normalizedCoordinate(
            value,
            min: -180,
            max: 180
        )
    }

    static func normalizedCoordinate(
        _ value: Double?,
        min minimumValue: Double,
        max maximumValue: Double
    ) -> Double? {

        guard let value else {
            return nil
        }

        guard
            value >= minimumValue,
            value <= maximumValue
        else {
            return nil
        }

        return (
            value * 1_000_000
        ).rounded() / 1_000_000
    }

    static func normalizedAltitude(
        _ value: Double?
    ) -> Double? {

        guard let value else {
            return nil
        }

        return (
            value * 10
        ).rounded() / 10
    }

    static func normalizedTimezoneOffset(
        _ value: Int?
    ) -> Int? {

        guard let value else {
            return nil
        }

        let maximumOffsetSeconds =
            18 * 3600

        guard
            value >= -maximumOffsetSeconds,
            value <= maximumOffsetSeconds
        else {
            return nil
        }

        return value
    }

    static func formattedCoordinate(
        _ value: Double?
    ) -> String {

        guard let value else {
            return ""
        }

        return String(
            format: "%.6f",
            value
        )
    }

    static func formattedAltitude(
        _ value: Double?
    ) -> String {

        guard let value else {
            return ""
        }

        if value == value.rounded() {
            return String(
                format: "%.0f",
                value
            )
        }

        return String(
            format: "%.1f",
            value
        )
    }

    static func greatestCommonDivisor(
        _ lhs: Int,
        _ rhs: Int
    ) -> Int {

        var lhs = abs(lhs)
        var rhs = abs(rhs)

        while rhs != 0 {
            let remainder =
                lhs % rhs
            lhs = rhs
            rhs = remainder
        }

        return lhs
    }

    static func formattedDate(
        _ date: Date?,
        timeZone: TimeZone?,
        format: String
    ) -> String {

        guard let date else {
            return ""
        }

        let formatter =
            DateFormatter()

        formatter.locale =
            Locale(identifier: "en_US_POSIX")

        formatter.dateFormat =
            format

        if let timeZone {
            formatter.timeZone =
                timeZone
        }

        return formatter.string(
            from: date
        )
    }
}

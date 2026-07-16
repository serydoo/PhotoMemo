//
//  PhotoMetadataReader.swift
//  PhotoMemo
//
//  Created by MemoMark on 2026/6/17.
//


import Foundation
import ImageIO

final class PhotoMetadataReader {

    private struct ParsedDateValue {

        let date: Date

        let timezoneOffsetSeconds: Int?
    }

    private static let dateFormatters:
        [DateFormatter] = [
            makeDateFormatter(
                "yyyy:MM:dd HH:mm:ss"
            ),
            makeDateFormatter(
                "yyyy-MM-dd HH:mm:ss"
            ),
            makeDateFormatter(
                "yyyy-MM-dd'T'HH:mm:ssZ"
            ),
            makeDateFormatter(
                "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
            )
        ]

    func properties(
        from url: URL
    ) -> [CFString: Any]? {

        guard
            let source = CGImageSourceCreateWithURL(
                url as CFURL,
                nil
            )
        else {
            return nil
        }

        return properties(
            from: source
        )
    }

    func properties(
        from data: Data
    ) -> [CFString: Any]? {

        guard
            let source = CGImageSourceCreateWithData(
                data as CFData,
                nil
            )
        else {
            return nil
        }

        return properties(
            from: source
        )
    }

    func properties(
        from source: CGImageSource
    ) -> [CFString: Any]? {

        guard let properties =
            CGImageSourceCopyPropertiesAtIndex(
                source,
                0,
                nil
            ) as? [CFString: Any] else {
            return nil
        }

        return properties
    }

    func read(
        from url: URL
    ) -> PhotoMetadata {

        guard let properties = properties(from: url) else {
            return PhotoMetadata()
        }

        return read(
            from: properties
        )
    }

    func read(
        from data: Data
    ) -> PhotoMetadata {

        guard let properties = properties(from: data) else {
            return PhotoMetadata()
        }

        return read(
            from: properties
        )
    }

    func read(
        from properties: [CFString: Any]
    ) -> PhotoMetadata {

        var metadata = PhotoMetadata()

        let pixelWidth =
            properties[kCGImagePropertyPixelWidth]
            as? Int
        let pixelHeight =
            properties[kCGImagePropertyPixelHeight]
            as? Int

        if Self.orientationSwapsDisplayAxes(
            properties[kCGImagePropertyOrientation]
        ) {
            metadata.imageWidth =
                pixelHeight
            metadata.imageHeight =
                pixelWidth
        } else {
            metadata.imageWidth =
                pixelWidth
            metadata.imageHeight =
                pixelHeight
        }

        loadTIFF(
            properties,
            into: &metadata
        )

        loadEXIF(
            properties,
            into: &metadata
        )

        loadGPS(
            properties,
            into: &metadata
        )

        return metadata.normalized()
    }
}

private extension PhotoMetadataReader {

    static func orientationSwapsDisplayAxes(
        _ value: Any?
    ) -> Bool {

        let rawValue: Int?
        switch value {
        case let value as Int:
            rawValue = value
        case let value as NSNumber:
            rawValue = value.intValue
        default:
            rawValue = nil
        }

        guard let rawValue else {
            return false
        }

        return [5, 6, 7, 8].contains(rawValue)
    }

    func loadTIFF(
        _ properties: [CFString: Any],
        into metadata: inout PhotoMetadata
    ) {

        guard
            let tiff =
                properties[
                    kCGImagePropertyTIFFDictionary
                ] as? [CFString: Any]
        else {
            return
        }

        metadata.deviceBrand =
            tiff[kCGImagePropertyTIFFMake]
            as? String ?? ""

        metadata.deviceModel =
            tiff[kCGImagePropertyTIFFModel]
            as? String ?? ""

        if metadata.captureDate == nil,
           let dateString =
            tiff[kCGImagePropertyTIFFDateTime]
            as? String {

            applyParsedDate(
                parseDate(dateString),
                to: &metadata
            )
        }
    }

    func loadEXIF(
        _ properties: [CFString: Any],
        into metadata: inout PhotoMetadata
    ) {

        guard
            let exif =
                properties[
                    kCGImagePropertyExifDictionary
                ] as? [CFString: Any]
        else {
            return
        }

        if let isoValues =
            exif[
                kCGImagePropertyExifISOSpeedRatings
            ] as? [Int],
           let iso = isoValues.first {

            metadata.iso = "\(iso)"
        }

        if let aperture =
            exif[
                kCGImagePropertyExifFNumber
            ] as? Double {

            metadata.aperture =
                String(
                    format: "%.1f",
                    aperture
                )
        }

        if let shutter =
            exif[
                kCGImagePropertyExifExposureTime
            ] as? Double {

            metadata.shutterSpeed =
                shutterText(
                    shutter
                )
        }

        if let focal =
            exif[
                kCGImagePropertyExifFocalLength
            ] as? Double {

            metadata.focalLength =
                String(
                    format: "%.0f",
                    focal
                )
        }

        if let focal35 =
            exif[
                kCGImagePropertyExifFocalLenIn35mmFilm
            ] as? Int {

            metadata.focalLength35mm =
                "\(focal35)"
        }

        if let lens =
            exif[
                kCGImagePropertyExifLensModel
            ] as? String {

            metadata.lensModel = lens
        }

        if let dateString =
            exif[
                kCGImagePropertyExifDateTimeOriginal
            ] as? String {

            applyParsedDate(
                parseDate(
                    dateString
                ),
                to: &metadata
            )
        }
    }

    func loadGPS(
        _ properties: [CFString: Any],
        into metadata: inout PhotoMetadata
    ) {

        guard
            let gps =
                properties[
                    kCGImagePropertyGPSDictionary
                ] as? [CFString: Any]
        else {
            return
        }

        let latitude =
            gps[
                kCGImagePropertyGPSLatitude
            ] as? Double

        let longitude =
            gps[
                kCGImagePropertyGPSLongitude
            ] as? Double

        let altitude =
            gps[
                kCGImagePropertyGPSAltitude
            ] as? Double

        metadata.latitude =
            signedCoordinate(
                latitude,
                reference:
                    gps[
                        kCGImagePropertyGPSLatitudeRef
                    ] as? String,
                negativeReferences:
                    ["S"]
            )

        metadata.longitude =
            signedCoordinate(
                longitude,
                reference:
                    gps[
                        kCGImagePropertyGPSLongitudeRef
                    ] as? String,
                negativeReferences:
                    ["W"]
            )

        metadata.altitude =
            signedAltitude(
                altitude,
                reference:
                    gps[
                        kCGImagePropertyGPSAltitudeRef
                    ]
            )
    }

    private func parseDate(
        _ value: String
    ) -> ParsedDateValue? {

        let trimmedValue =
            value.trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        guard !trimmedValue.isEmpty else {
            return nil
        }

        let timezoneOffsetSeconds =
            timezoneOffsetSeconds(
                from: trimmedValue
            )

        for formatter in Self.dateFormatters {
            if let date =
                formatter.date(
                    from: trimmedValue
                ) {
                return ParsedDateValue(
                    date: date,
                    timezoneOffsetSeconds:
                        timezoneOffsetSeconds
                )
            }
        }

        return nil
    }

    func shutterText(
        _ value: Double
    ) -> String {

        guard value > 0 else {
            return ""
        }

        if value < 1 {

            return "1/\(Int(round(1 / value)))"
        }

        return String(
            format: "%.1fs",
            value
        )
    }

    static func makeDateFormatter(
        _ format: String
    ) -> DateFormatter {

        let formatter =
            DateFormatter()

        formatter.locale =
            Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = format
        return formatter
    }

    private func applyParsedDate(
        _ parsedDate: ParsedDateValue?,
        to metadata: inout PhotoMetadata
    ) {

        guard let parsedDate else {
            return
        }

        metadata.captureDate =
            parsedDate.date

        if let timezoneOffsetSeconds =
            parsedDate.timezoneOffsetSeconds {
            metadata.captureTimezoneOffsetSeconds =
                timezoneOffsetSeconds
        }
    }

    private func timezoneOffsetSeconds(
        from value: String
    ) -> Int? {

        let trimmedValue =
            value.trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        if trimmedValue.hasSuffix("Z") {
            return 0
        }

        guard
            let range =
                trimmedValue.range(
                    of: #"([+-]\d{2}:?\d{2})$"#,
                    options: .regularExpression
                )
        else {
            return nil
        }

        let offsetString =
            String(
                trimmedValue[range]
            )
            .replacingOccurrences(
                of: ":",
                with: ""
            )

        guard offsetString.count == 5 else {
            return nil
        }

        let signCharacter =
            offsetString.prefix(1)

        let hoursString =
            String(
                offsetString.dropFirst().prefix(2)
            )

        let minutesString =
            String(
                offsetString.suffix(2)
            )

        guard
            let hours = Int(hoursString),
            let minutes = Int(minutesString),
            hours <= 18,
            minutes < 60
        else {
            return nil
        }

        let absoluteValue =
            (hours * 3600)
            + (minutes * 60)

        return signCharacter == "-"
            ? -absoluteValue
            : absoluteValue
    }

    private func signedCoordinate(
        _ value: Double?,
        reference: String?,
        negativeReferences: Set<String>
    ) -> Double? {

        guard let value else {
            return nil
        }

        guard
            let reference =
                reference?
                .trimmingCharacters(
                    in: .whitespacesAndNewlines
                )
                .uppercased(),
            !reference.isEmpty
        else {
            return value
        }

        return negativeReferences.contains(
            reference
        )
        ? -abs(value)
        : abs(value)
    }

    private func signedAltitude(
        _ value: Double?,
        reference: Any?
    ) -> Double? {

        guard let value else {
            return nil
        }

        if let reference = reference as? UInt8 {
            return reference == 1
                ? -abs(value)
                : abs(value)
        }

        if let reference = reference as? Int {
            return reference == 1
                ? -abs(value)
                : abs(value)
        }

        return value
    }
}

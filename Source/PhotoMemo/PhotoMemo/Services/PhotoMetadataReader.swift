//
//  PhotoMetadataReader.swift
//  PhotoMemo
//
//  Created by 汪瑞 on 2026/6/17.
//


import Foundation
import ImageIO

final class PhotoMetadataReader {

    func properties(
        from url: URL
    ) -> [CFString: Any]? {

        guard
            let source = CGImageSourceCreateWithURL(
                url as CFURL,
                nil
            ),
            let properties =
                CGImageSourceCopyPropertiesAtIndex(
                    source,
                    0,
                    nil
                ) as? [CFString: Any]
        else {
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
        from properties: [CFString: Any]
    ) -> PhotoMetadata {

        var metadata = PhotoMetadata()

        metadata.imageWidth =
            properties[kCGImagePropertyPixelWidth]
            as? Int

        metadata.imageHeight =
            properties[kCGImagePropertyPixelHeight]
            as? Int

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

        return metadata
    }
}

private extension PhotoMetadataReader {

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

            metadata.captureDate =
                parseDate(
                    dateString
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

        metadata.latitude =
            gps[
                kCGImagePropertyGPSLatitude
            ] as? Double

        metadata.longitude =
            gps[
                kCGImagePropertyGPSLongitude
            ] as? Double

        metadata.altitude =
            gps[
                kCGImagePropertyGPSAltitude
            ] as? Double
    }

    func parseDate(
        _ value: String
    ) -> Date? {

        let formatter =
            DateFormatter()

        formatter.dateFormat =
            "yyyy:MM:dd HH:mm:ss"

        return formatter.date(
            from: value
        )
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
}

import Foundation
import UniformTypeIdentifiers

struct JPEGExifUserCommentPatcher {

    static func patchIfNeeded(
        at url: URL,
        outputType: UTType,
        exportDescription: String
    ) {

        guard
            outputType.conforms(to: .jpeg),
            !exportDescription.isEmpty,
            !exportDescription.canBeConverted(to: .ascii),
            var fileData =
                try? Data(contentsOf: url),
            let location =
                jpegUserCommentLocation(
                    in: fileData
                )
        else {
            return
        }

        let encodedComment =
            exifUnicodeUserCommentData(
                exportDescription
            )

        guard
            encodedComment.count
            <= location.dataRange.count
        else {
            return
        }

        var replacement =
            encodedComment

        if encodedComment.count < location.dataRange.count {
            replacement.append(
                Data(
                    repeating: 0,
                    count:
                        location.dataRange.count
                        - encodedComment.count
                )
            )
        }

        fileData.replaceSubrange(
            location.dataRange,
            with: replacement
        )
        fileData.replaceSubrange(
            location.countRange,
            with:
                encodedUInt32(
                    UInt32(
                        encodedComment.count
                    ),
                    endianness:
                        location.endianness
                )
        )

        try? fileData.write(
            to: url,
            options: .atomic
        )
    }

    private static func exifUnicodeUserCommentData(
        _ text: String
    ) -> Data {

        var data =
            Data("UNICODE\0".utf8)
        data.append(
            text.data(
                using: .utf16BigEndian
            ) ?? Data()
        )
        return data
    }

    private static func jpegUserCommentLocation(
        in data: Data
    ) -> JPEGExifUserCommentLocation? {

        guard data.count >= 4 else {
            return nil
        }

        var offset = 2

        while offset + 4 <= data.count {

            guard data[offset] == 0xFF else {
                return nil
            }

            let marker = data[offset + 1]

            if marker == 0xDA || marker == 0xD9 {
                return nil
            }

            let segmentLength =
                Int(
                    readUInt16(
                        in: data,
                        at: offset + 2,
                        endianness: .big
                    )
                )

            guard segmentLength >= 2 else {
                return nil
            }

            let segmentStart = offset + 4
            let segmentEnd =
                offset + 2 + segmentLength

            guard segmentEnd <= data.count else {
                return nil
            }

            if marker == 0xE1,
               segmentEnd - segmentStart >= 6,
               data[
                    segmentStart..<segmentStart + 6
               ] == Data("Exif\0\0".utf8),
               let location =
                exifUserCommentLocation(
                    in: data,
                    exifHeaderStart:
                        segmentStart
                ) {
                return location
            }

            offset = segmentEnd
        }

        return nil
    }

    private static func exifUserCommentLocation(
        in data: Data,
        exifHeaderStart: Int
    ) -> JPEGExifUserCommentLocation? {

        let tiffStart =
            exifHeaderStart + 6

        guard tiffStart + 8 <= data.count else {
            return nil
        }

        let endianness:
            TIFFEndianness

        switch (
            data[tiffStart],
            data[tiffStart + 1]
        ) {

        case (0x4D, 0x4D):
            endianness = .big

        case (0x49, 0x49):
            endianness = .little

        default:
            return nil
        }

        let ifd0Offset =
            Int(
                readUInt32(
                    in: data,
                    at: tiffStart + 4,
                    endianness: endianness
                )
            )
        let ifd0Start =
            tiffStart + ifd0Offset

        guard
            let exifIFDOffset =
                ifdValueOffset(
                    forTag: 0x8769,
                    in: data,
                    at: ifd0Start,
                    endianness: endianness
                )
        else {
            return nil
        }

        let exifIFDStart =
            tiffStart + exifIFDOffset

        guard
            let entry =
                ifdEntry(
                    forTag: 0x9286,
                    in: data,
                    at: exifIFDStart,
                    endianness: endianness
                )
        else {
            return nil
        }

        let dataStart =
            tiffStart + entry.valueOffset
        let dataEnd =
            dataStart + Int(entry.count)

        guard
            dataStart >= 0,
            dataEnd <= data.count
        else {
            return nil
        }

        return JPEGExifUserCommentLocation(
            dataRange:
                dataStart..<dataEnd,
            countRange:
                entry.countOffset
                ..<
                (entry.countOffset + 4),
            endianness: endianness
        )
    }

    private static func ifdValueOffset(
        forTag tag: UInt16,
        in data: Data,
        at ifdStart: Int,
        endianness: TIFFEndianness
    ) -> Int? {

        ifdEntry(
            forTag: tag,
            in: data,
            at: ifdStart,
            endianness: endianness
        )?.valueOffset
    }

    private static func ifdEntry(
        forTag tag: UInt16,
        in data: Data,
        at ifdStart: Int,
        endianness: TIFFEndianness
    ) -> TIFFIFDEntry? {

        guard ifdStart + 2 <= data.count else {
            return nil
        }

        let entryCount =
            Int(
                readUInt16(
                    in: data,
                    at: ifdStart,
                    endianness: endianness
                )
            )

        for index in 0..<entryCount {

            let entryStart =
                ifdStart + 2 + (index * 12)

            guard entryStart + 12 <= data.count else {
                return nil
            }

            let entryTag =
                readUInt16(
                    in: data,
                    at: entryStart,
                    endianness: endianness
                )

            guard entryTag == tag else {
                continue
            }

            return TIFFIFDEntry(
                count:
                    readUInt32(
                        in: data,
                        at: entryStart + 4,
                        endianness: endianness
                    ),
                countOffset:
                    entryStart + 4,
                valueOffset:
                    Int(
                        readUInt32(
                            in: data,
                            at: entryStart + 8,
                            endianness: endianness
                        )
                    )
            )
        }

        return nil
    }

    private static func readUInt16(
        in data: Data,
        at offset: Int,
        endianness: TIFFEndianness
    ) -> UInt16 {

        let bytes = data[offset..<offset + 2]

        switch endianness {

        case .big:
            return bytes.reduce(0) {
                ($0 << 8) | UInt16($1)
            }

        case .little:
            return bytes
                .reversed()
                .reduce(0) {
                    ($0 << 8) | UInt16($1)
                }
        }
    }

    private static func readUInt32(
        in data: Data,
        at offset: Int,
        endianness: TIFFEndianness
    ) -> UInt32 {

        let bytes = data[offset..<offset + 4]

        switch endianness {

        case .big:
            return bytes.reduce(0) {
                ($0 << 8) | UInt32($1)
            }

        case .little:
            return bytes
                .reversed()
                .reduce(0) {
                    ($0 << 8) | UInt32($1)
                }
        }
    }

    private static func encodedUInt32(
        _ value: UInt32,
        endianness: TIFFEndianness
    ) -> Data {

        let bytes = [
            UInt8((value >> 24) & 0xFF),
            UInt8((value >> 16) & 0xFF),
            UInt8((value >> 8) & 0xFF),
            UInt8(value & 0xFF)
        ]

        switch endianness {

        case .big:
            return Data(bytes)

        case .little:
            return Data(bytes.reversed())
        }
    }

    private enum TIFFEndianness {

        case big

        case little
    }

    private struct TIFFIFDEntry {

        let count: UInt32

        let countOffset: Int

        let valueOffset: Int
    }

    private struct JPEGExifUserCommentLocation {

        let dataRange: Range<Int>

        let countRange: Range<Int>

        let endianness: TIFFEndianness
    }
}

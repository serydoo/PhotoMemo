import Foundation

/// Bounded research kernel. No filesystem access, production callers or layout ownership.
nonisolated enum GlassCardPNGResearchRepair {
    typealias Failure = GlassCardContainerResearchFailure
    struct Result: Sendable {
        let data: Data
        let allowedRanges: [Range<Int>]
    }
    private static func crc(_ bytes: ArraySlice<UInt8>) -> UInt32 {
        var value: UInt32 = 0xFFFFFFFF
        for byte in bytes {
            value ^= UInt32(byte)
            for _ in 0..<8 { value = value & 1 == 1 ? (value >> 1) ^ 0xEDB88320 : value >> 1 }
        }
        return value ^ 0xFFFFFFFF
    }
    private static func big(_ bytes: [UInt8], _ offset: Int) throws -> Int {
        guard offset >= 0, offset <= bytes.count, 4 <= bytes.count-offset else { throw Failure.malformed }
        return bytes[offset..<offset+4].reduce(0) { ($0 << 8) | Int($1) }
    }
    private static func write(_ value: UInt32, into bytes: inout [UInt8], at offset: Int, little: Bool = false) {
        let encoded = (0..<4).map { UInt8(truncatingIfNeeded:value >> (24-$0*8)) }
        bytes.replaceSubrange(offset..<offset+4,with:little ? Array(encoded.reversed()) : encoded)
    }
    static func repair(_ data: Data, description: String) throws -> Result {
        try Task.checkCancellation()
        guard data.count <= 16*1024*1024 else { throw Failure.unsupported }
        var bytes = Array(data)
        guard bytes.starts(with:[137,80,78,71,13,10,26,10]) else { throw Failure.malformed }
        var cursor = 8, chunks = 0, exif: Range<Int>?, ended = false, hasImage = false
        while cursor < bytes.count {
            try Task.checkCancellation()
            chunks += 1
            guard chunks <= 1024 else { throw Failure.unsupported }
            let length = try big(bytes,cursor)
            guard cursor+12 <= bytes.count, length <= bytes.count-cursor-12 else { throw Failure.malformed }
            let kind = Array(bytes[cursor+4..<cursor+8])
            guard kind.allSatisfy({ (65...90).contains($0) || (97...122).contains($0) }) else { throw Failure.malformed }
            let end = cursor+8+length
            guard UInt32(try big(bytes,end)) == crc(bytes[cursor+4..<end]) else { throw Failure.checksum }
            if chunks == 1 { guard kind == Array("IHDR".utf8), length == 13 else { throw Failure.malformed } }
            if kind == Array("eXIf".utf8) {
                guard exif == nil else { throw Failure.malformed }; exif = cursor+8..<end
            }
            if kind == Array("IDAT".utf8) { hasImage = true }
            cursor = end+4
            if kind == Array("IEND".utf8) { guard length == 0, cursor == bytes.count else { throw Failure.malformed }; ended = true; break }
        }
        guard ended, hasImage, let exif, exif.count >= 8 else { throw Failure.malformed }
        let patched = try GlassCardTIFFResearchRepair.repair(Array(bytes[exif]),description:description)
        bytes.replaceSubrange(exif,with:patched.bytes)
        let ranges = patched.allowedRanges.map { $0.lowerBound+exif.lowerBound..<$0.upperBound+exif.lowerBound }
        write(crc(bytes[exif.lowerBound-4..<exif.upperBound]),into:&bytes,at:exif.upperBound)
        try Task.checkCancellation()
        return Result(data:Data(bytes),allowedRanges:ranges+[exif.upperBound..<exif.upperBound+4])
    }
}

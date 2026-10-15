import Foundation

nonisolated enum GlassCardContainerResearchFailure: Error, Equatable {
    case unsupported, malformed, checksum, overlappingFields, cyclicIFD, missingComment, insufficientCapacity
}

/// Shared research-only TIFF ownership and same-size patch. Private conventions fail closed.
nonisolated enum GlassCardTIFFResearchRepair {
    typealias Failure = GlassCardContainerResearchFailure
    struct Result: Sendable {
        let bytes: [UInt8]
        let allowedRanges: [Range<Int>]
    }
    private struct Reader {
        let bytes: [UInt8]
        let little: Bool
        var visited: Set<Int> = []
        var owned: [Range<Int>] = [0..<8]
        var comment: (storage: Range<Int>, countOffset: Int)?
        func number(_ offset: Int, _ width: Int) throws -> Int {
            guard offset >= 0, width >= 0, offset <= bytes.count, width <= bytes.count-offset else { throw Failure.malformed }
            let values = little ? Array(bytes[offset..<offset+width].reversed()) : Array(bytes[offset..<offset+width])
            return values.reduce(0) { ($0 << 8) | Int($1) }
        }
        mutating func own(_ range: Range<Int>) throws {
            guard range.lowerBound >= 0, range.upperBound <= bytes.count else { throw Failure.malformed }
            guard !owned.contains(where: { $0.overlaps(range) }) else { throw Failure.overlappingFields }
            owned.append(range)
        }
        mutating func visit(_ offset: Int, isExif: Bool = false) throws {
            guard visited.count < 32 else { throw Failure.unsupported }
            guard visited.insert(offset).inserted else { throw Failure.cyclicIFD }
            let count = try number(offset,2)
            guard count <= 1024 else { throw Failure.unsupported }
            let end = offset + 2 + count*12 + 4
            try own(offset..<end)
            var tags: Set<Int> = []
            var children: [(Int,Bool)] = []
            let widths = [1:1,2:1,3:2,4:4,5:8,6:1,7:1,8:2,9:4,10:8,11:4,12:8]
            for index in 0..<count {
                try Task.checkCancellation()
                let position = offset + 2 + index*12
                let tag = try number(position,2), type = try number(position+2,2)
                let amount = try number(position+4,4)
                guard tags.insert(tag).inserted else { throw Failure.malformed }
                guard let width = widths[type] else { throw Failure.unsupported }
                // Private/sub-IFD/thumbnail offset conventions are outside this research contract.
                guard ![0x927C,0x014A,0x0201,0x0202].contains(tag) else { throw Failure.unsupported }
                let size = amount*width
                let value = try number(position+8,4)
                if size > 4 { try own(value..<value+size) }
                if [0x8769,0x8825,0xA005].contains(tag) {
                    guard type == 4, amount == 1 else { throw Failure.malformed }
                    children.append((value,tag == 0x8769))
                }
                if tag == 0x9286, isExif {
                    guard comment == nil, type == 7, amount >= 8 else { throw Failure.malformed }
                    comment = (value..<value+amount,position+4)
                }
            }
            let next = try number(end-4,4)
            for (child,exif) in children { try visit(child,isExif:exif) }
            if next != 0 { try visit(next) }
        }
    }
    static func repair(_ tiff: [UInt8], description: String) throws -> Result {
        guard tiff.count >= 8, tiff.count <= 16*1024*1024,
              tiff.starts(with:[73,73]) || tiff.starts(with:[77,77]) else { throw Failure.unsupported }
        var reader = Reader(bytes:tiff,little:tiff[0] == 73)
        guard try reader.number(2,2) == 42 else { throw Failure.unsupported }
        let root = try reader.number(4,4)
        try reader.visit(root)
        guard let location = reader.comment else { throw Failure.missingComment }
        let raw: [UInt8]
        if description.unicodeScalars.allSatisfy({ $0.value < 128 }) {
            raw = Array("ASCII\0\0\0".utf8) + Array(description.utf8)
        } else {
            raw = Array("UNICODE\0".utf8) + description.utf16.flatMap { [UInt8($0 >> 8),UInt8(truncatingIfNeeded:$0)] }
        }
        guard raw.count <= location.storage.count else { throw Failure.insufficientCapacity }
        var result = tiff
        result.replaceSubrange(location.storage,with:raw + [UInt8](repeating:0,count:location.storage.count-raw.count))
        let count = (0..<4).map { UInt8(truncatingIfNeeded:raw.count >> (24-$0*8)) }
        result.replaceSubrange(location.countOffset..<location.countOffset+4,with:reader.little ? Array(count.reversed()) : count)
        return Result(bytes:result,allowedRanges:[location.storage,location.countOffset..<location.countOffset+4])
    }
}

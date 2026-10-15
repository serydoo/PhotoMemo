import Foundation

/// Bounded HEIC research adapter: file-backed Exif plus local idat grid, no relocation.
nonisolated enum GlassCardHEICResearchRepair {
    typealias Failure = GlassCardContainerResearchFailure
    struct Box { let type: String; let payload: Range<Int> }
    struct Extent { let item: Int; let range: Range<Int> }
    struct Location: Sendable {
        let tiff: Range<Int>
        let item: Int
        let ilocVersion: Int
    }
    struct Result: Sendable {
        let data: Data
        let allowedRanges: [Range<Int>]
    }
    private struct Reader {
        let bytes: [UInt8]
        func number(_ offset: Int,_ width: Int) throws -> Int {
            guard (0...8).contains(width), offset >= 0, offset <= bytes.count, width <= bytes.count-offset else { throw Failure.malformed }
            let value = bytes[offset..<offset+width].reduce(UInt64(0)) { ($0 << 8) | UInt64($1) }
            guard value <= UInt64(Int.max) else { throw Failure.malformed }
            return Int(value)
        }
        func type(_ offset: Int) throws -> String {
            guard offset >= 0, offset <= bytes.count, 4 <= bytes.count-offset,
                  let value = String(bytes:bytes[offset..<offset+4],encoding:.ascii) else { throw Failure.malformed }
            return value
        }
        func boxes(_ range: Range<Int>) throws -> [Box] {
            guard range.lowerBound >= 0, range.upperBound <= bytes.count else { throw Failure.malformed }
            var cursor = range.lowerBound, result: [Box] = []
            while cursor < range.upperBound {
                try Task.checkCancellation()
                guard result.count < 1024, range.upperBound-cursor >= 8 else { throw Failure.malformed }
                var size = try number(cursor,4), header = 8
                if size == 1 { guard range.upperBound-cursor >= 16 else { throw Failure.malformed }; size = try number(cursor+8,8); header = 16 }
                guard size >= header, size <= range.upperBound-cursor else { throw Failure.malformed }
                result.append(Box(type:try type(cursor+4),payload:cursor+header..<cursor+size))
                cursor += size
            }
            return result
        }
        func single(_ type: String,_ boxes: [Box]) throws -> Box {
            let matches = boxes.filter { $0.type == type }
            guard matches.count == 1 else { throw Failure.malformed }; return matches[0]
        }
        func locate() throws -> Location {
            let top = try boxes(0..<bytes.count)
            let ftyp = try single("ftyp",top)
            guard ftyp.payload.count >= 8, ["heic","heix","mif1"].contains(try type(ftyp.payload.lowerBound)) else { throw Failure.unsupported }
            let meta = try single("meta",top)
            guard meta.payload.count >= 4, try number(meta.payload.lowerBound,4) == 0 else { throw Failure.unsupported }
            let children = try boxes(meta.payload.lowerBound+4..<meta.payload.upperBound)
            let iinf = try single("iinf",children), iloc = try single("iloc",children)
            let infoStart = iinf.payload.lowerBound
            guard iinf.payload.count >= 6 else { throw Failure.malformed }
            let infoVersion = try number(infoStart,1)
            guard infoVersion <= 1 else { throw Failure.unsupported }
            let countWidth = infoVersion == 0 ? 2 : 4
            guard iinf.payload.count >= 4+countWidth else { throw Failure.malformed }
            let infoCount = try number(infoStart+4,countWidth)
            let infos = try boxes(infoStart+4+countWidth..<iinf.payload.upperBound)
            guard infos.count == infoCount else { throw Failure.malformed }
            var ids: Set<Int> = [], exifID: Int?
            var itemTypes: [Int:String] = [:]
            for info in infos {
                guard info.type == "infe", info.payload.count >= 4 else { throw Failure.unsupported }
                let start = info.payload.lowerBound, version = try number(start,1)
                guard version == 2 || version == 3 else { throw Failure.unsupported }
                let idWidth = version == 2 ? 2 : 4
                guard info.payload.count >= 4+idWidth+6 else { throw Failure.malformed }
                let id = try number(start+4,idWidth)
                guard ids.insert(id).inserted else { throw Failure.malformed }
                guard try number(start+4+idWidth,2) == 0 else { throw Failure.unsupported }
                let itemType = try type(start+6+idWidth)
                itemTypes[id] = itemType
                if itemType == "Exif" {
                    guard exifID == nil else { throw Failure.unsupported }
                    exifID = id
                }
            }
            guard let exifID else { throw Failure.missingComment }
            let start = iloc.payload.lowerBound
            guard iloc.payload.count >= 8 else { throw Failure.malformed }
            let version = try number(start,1)
            guard version <= 2 else { throw Failure.unsupported }
            var cursor = start+4
            func take(_ width: Int) throws -> Int {
                guard width <= iloc.payload.upperBound-cursor else { throw Failure.malformed }
                let value = try number(cursor,width); cursor += width; return value
            }
            let sizes = try take(2)
            let offsetWidth = sizes >> 12, lengthWidth = (sizes >> 8)&15, baseWidth = (sizes >> 4)&15
            let indexWidth = version == 0 ? 0 : sizes&15
            guard [offsetWidth,lengthWidth,baseWidth,indexWidth].allSatisfy({ [0,4,8].contains($0) }) else { throw Failure.unsupported }
            let count = try take(version < 2 ? 2 : 4)
            guard count <= 1024 else { throw Failure.unsupported }
            var seen: Set<Int> = [], extents: [Extent] = []
            var target: Range<Int>?
            for _ in 0..<count {
                try Task.checkCancellation()
                let id = try take(version < 2 ? 2 : 4)
                guard seen.insert(id).inserted, ids.contains(id) else { throw Failure.malformed }
                let method = version == 0 ? 0 : try take(2)
                let reference = try take(2), base = try take(baseWidth), extentCount = try take(2)
                guard reference == 0, extentCount <= 1024 else { throw Failure.unsupported }
                guard method == 0 || (method == 1 && itemTypes[id] == "grid") else { throw Failure.unsupported }
                if id == exifID || method == 1 { guard extentCount == 1 else { throw Failure.unsupported } }
                let localPayload: Range<Int>?
                if method == 1 { localPayload = try single("idat",children).payload }
                else { localPayload = nil }
                for _ in 0..<extentCount {
                    let extentIndex = indexWidth > 0 ? try take(indexWidth) : 0
                    if method == 1 { guard extentIndex == 0 else { throw Failure.unsupported } }
                    let offset = try take(offsetWidth), length = try take(lengthWidth)
                    let range: Range<Int>
                    if let localPayload {
                        guard base <= localPayload.count, offset <= localPayload.count-base, length > 0,
                              length <= localPayload.count-base-offset else { throw Failure.malformed }
                        let start = localPayload.lowerBound+base+offset
                        range = start..<start+length
                        guard !extents.contains(where: { $0.range.overlaps(range) }) else { throw Failure.overlappingFields }
                    } else {
                        guard base <= bytes.count, offset <= bytes.count-base, length > 0,
                              length <= bytes.count-base-offset else { throw Failure.malformed }
                        range = base+offset..<base+offset+length
                        guard top.contains(where: { $0.type == "mdat" && $0.payload.lowerBound <= range.lowerBound && range.upperBound <= $0.payload.upperBound }) else { throw Failure.malformed }
                    }
                    guard extents.count < 1024 else { throw Failure.unsupported }
                    extents.append(Extent(item:id,range:range))
                    if id == exifID { target = range }
                }
            }
            guard cursor == iloc.payload.upperBound, seen == ids, let target else { throw Failure.malformed }
            guard !extents.contains(where: { $0.item != exifID && $0.range.overlaps(target) }) else { throw Failure.overlappingFields }
            guard target.count >= 4 else { throw Failure.malformed }
            let skip = try number(target.lowerBound,4)
            guard skip <= target.count-4, target.count-4-skip >= 8 else { throw Failure.malformed }
            return Location(tiff:target.lowerBound+4+skip..<target.upperBound,item:exifID,ilocVersion:version)
        }
    }
    static func locate(_ data: Data) throws -> Location {
        guard data.count <= 16*1024*1024 else { throw Failure.unsupported }
        return try Reader(bytes:Array(data)).locate()
    }
    static func repair(_ data: Data, description: String) throws -> Result {
        try Task.checkCancellation()
        let location = try locate(data)
        let patch = try GlassCardTIFFResearchRepair.repair(Array(data[location.tiff]),description:description)
        var result = data
        result.replaceSubrange(location.tiff,with:patch.bytes)
        try Task.checkCancellation()
        return Result(data:result,allowedRanges:patch.allowedRanges.map { $0.lowerBound+location.tiff.lowerBound..<$0.upperBound+location.tiff.lowerBound })
    }
}

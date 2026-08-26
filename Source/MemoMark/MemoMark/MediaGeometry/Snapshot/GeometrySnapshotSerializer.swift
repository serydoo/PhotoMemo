import CoreGraphics
import Foundation

enum GeometrySnapshotSerializerError:
    LocalizedError,
    Equatable {

    case encodingFailed

    var errorDescription: String? {
        switch self {
        case .encodingFailed:
            return "Unable to encode canonical geometry snapshot."
        }
    }
}

struct GeometrySnapshotSerializer:
    Sendable {

    static let standard =
        GeometrySnapshotSerializer()

    func serialize(
        _ geometry: CanonicalGeometry
    ) throws -> String {
        let encoder =
            JSONEncoder()
        encoder.outputFormatting = [
            .prettyPrinted,
            .sortedKeys
        ]

        let payload =
            GeometrySnapshotPayload(
                geometry: geometry
            )
        let data =
            try encoder.encode(
                payload
            )

        guard
            let string =
                String(
                    data: data,
                    encoding: .utf8
                )
        else {
            throw GeometrySnapshotSerializerError
                .encodingFailed
        }

        return string
    }
}

private struct GeometrySnapshotPayload:
    Codable {

    let version: Int
    let geometry: GeometrySnapshot

    init(
        geometry: CanonicalGeometry
    ) {
        self.version = 1
        self.geometry =
            GeometrySnapshot(
                geometry: geometry
            )
    }
}

private struct GeometrySnapshot:
    Codable {

    let rawPixelSize: [Int]
    let displaySize: [Int]
    let orientation: String
    let canvasSize: [Int]
    let photoFrame: [Int]
    let footerFrame: [Int]

    init(
        geometry: CanonicalGeometry
    ) {
        self.rawPixelSize =
            geometry
            .facts
            .rawPixelSize
            .snapshotArray
        self.displaySize =
            geometry
            .facts
            .displaySize
            .snapshotArray
        self.orientation =
            geometry
            .facts
            .orientation
            .rawValue
        self.canvasSize =
            geometry
            .canvas
            .canvasSize
            .snapshotArray
        self.photoFrame =
            geometry
            .canvas
            .photoFrame
            .snapshotArray
        self.footerFrame =
            geometry
            .canvas
            .footerFrame
            .snapshotArray
    }
}

private extension CGSize {

    var snapshotArray: [Int] {
        [
            Int(width.rounded()),
            Int(height.rounded())
        ]
    }
}

private extension CGRect {

    var snapshotArray: [Int] {
        [
            Int(origin.x.rounded()),
            Int(origin.y.rounded()),
            Int(size.width.rounded()),
            Int(size.height.rounded())
        ]
    }
}

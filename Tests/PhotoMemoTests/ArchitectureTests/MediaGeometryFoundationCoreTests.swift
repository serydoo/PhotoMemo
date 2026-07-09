import CoreGraphics
import Foundation
import ImageIO
import Testing
import UniformTypeIdentifiers
@testable import PhotoMemo

@Suite("Media Geometry Foundation core")
struct MediaGeometryFoundationCoreTests {

    @Test("Portrait JPEG resolves to stable canonical geometry JSON")
    func portraitJPEGResolvesToStableCanonicalGeometryJSON() throws {
        let sourceURL =
            try makeImageFixture(
                fileExtension: "jpg",
                type: .jpeg,
                width: 120,
                height: 180,
                orientation: .up
            )

        let geometry =
            try MediaGeometryResolver.standard.resolve(
                fileURL: sourceURL
            )
        let issues =
            GeometryLinter.standard.lint(geometry)
        let snapshot =
            try GeometrySnapshotSerializer.standard.serialize(
                geometry
            )

        #expect(issues.isEmpty)
        #expect(
            snapshot == """
            {
              "geometry" : {
                "canvasSize" : [
                  120,
                  196
                ],
                "displaySize" : [
                  120,
                  180
                ],
                "footerFrame" : [
                  0,
                  180,
                  120,
                  16
                ],
                "orientation" : "up",
                "photoFrame" : [
                  0,
                  0,
                  120,
                  180
                ],
                "rawPixelSize" : [
                  120,
                  180
                ]
              },
              "version" : 1
            }
            """
        )
    }

    @Test("Landscape JPEG resolves to stable canonical geometry JSON")
    func landscapeJPEGResolvesToStableCanonicalGeometryJSON() throws {
        let sourceURL =
            try makeImageFixture(
                fileExtension: "jpg",
                type: .jpeg,
                width: 180,
                height: 120,
                orientation: .up
            )

        let geometry =
            try MediaGeometryResolver.standard.resolve(
                fileURL: sourceURL
            )
        let issues =
            GeometryLinter.standard.lint(geometry)
        let snapshot =
            try GeometrySnapshotSerializer.standard.serialize(
                geometry
            )

        #expect(issues.isEmpty)
        #expect(
            snapshot == """
            {
              "geometry" : {
                "canvasSize" : [
                  180,
                  131
                ],
                "displaySize" : [
                  180,
                  120
                ],
                "footerFrame" : [
                  0,
                  120,
                  180,
                  11
                ],
                "orientation" : "up",
                "photoFrame" : [
                  0,
                  0,
                  180,
                  120
                ],
                "rawPixelSize" : [
                  180,
                  120
                ]
              },
              "version" : 1
            }
            """
        )
    }

    @Test("Portrait HEIC resolves to stable canonical geometry JSON")
    func portraitHEICResolvesToStableCanonicalGeometryJSON() throws {
        let sourceURL =
            try makeImageFixture(
                fileExtension: "heic",
                type: .heic,
                width: 120,
                height: 180,
                orientation: .up
            )

        let geometry =
            try MediaGeometryResolver.standard.resolve(
                fileURL: sourceURL
            )
        let issues =
            GeometryLinter.standard.lint(geometry)
        let snapshot =
            try GeometrySnapshotSerializer.standard.serialize(
                geometry
            )

        #expect(issues.isEmpty)
        #expect(
            snapshot == """
            {
              "geometry" : {
                "canvasSize" : [
                  120,
                  196
                ],
                "displaySize" : [
                  120,
                  180
                ],
                "footerFrame" : [
                  0,
                  180,
                  120,
                  16
                ],
                "orientation" : "up",
                "photoFrame" : [
                  0,
                  0,
                  120,
                  180
                ],
                "rawPixelSize" : [
                  120,
                  180
                ]
              },
              "version" : 1
            }
            """
        )
    }

    @Test("Landscape HEIC resolves to stable canonical geometry JSON")
    func landscapeHEICResolvesToStableCanonicalGeometryJSON() throws {
        let sourceURL =
            try makeImageFixture(
                fileExtension: "heic",
                type: .heic,
                width: 180,
                height: 120,
                orientation: .up
            )

        let geometry =
            try MediaGeometryResolver.standard.resolve(
                fileURL: sourceURL
            )
        let issues =
            GeometryLinter.standard.lint(geometry)
        let snapshot =
            try GeometrySnapshotSerializer.standard.serialize(
                geometry
            )

        #expect(issues.isEmpty)
        #expect(
            snapshot == """
            {
              "geometry" : {
                "canvasSize" : [
                  180,
                  131
                ],
                "displaySize" : [
                  180,
                  120
                ],
                "footerFrame" : [
                  0,
                  120,
                  180,
                  11
                ],
                "orientation" : "up",
                "photoFrame" : [
                  0,
                  0,
                  180,
                  120
                ],
                "rawPixelSize" : [
                  180,
                  120
                ]
              },
              "version" : 1
            }
            """
        )
    }

    @Test("Portrait HEIC with right orientation resolves display space")
    func portraitHEICWithRightOrientationResolvesDisplaySpace() throws {
        let sourceURL =
            try makeImageFixture(
                fileExtension: "heic",
                type: .heic,
                width: 120,
                height: 180,
                orientation: .right
            )

        let geometry =
            try MediaGeometryResolver.standard.resolve(
                fileURL: sourceURL
            )
        let issues =
            GeometryLinter.standard.lint(geometry)

        #expect(issues.isEmpty)
        #expect(geometry.facts.rawPixelSize == CGSize(width: 120, height: 180))
        #expect(geometry.facts.displaySize == CGSize(width: 180, height: 120))
        #expect(geometry.facts.orientation == .right)
        #expect(geometry.canvas.photoFrame == CGRect(x: 0, y: 0, width: 180, height: 120))
        #expect(geometry.canvas.footerFrame == CGRect(x: 0, y: 120, width: 180, height: 11))
        #expect(geometry.canvas.canvasSize == CGSize(width: 180, height: 131))
    }

    @Test("Portrait HEIC with left orientation resolves display space")
    func portraitHEICWithLeftOrientationResolvesDisplaySpace() throws {
        let sourceURL =
            try makeImageFixture(
                fileExtension: "heic",
                type: .heic,
                width: 120,
                height: 180,
                orientation: .left
            )

        let geometry =
            try MediaGeometryResolver.standard.resolve(
                fileURL: sourceURL
            )
        let issues =
            GeometryLinter.standard.lint(geometry)

        #expect(issues.isEmpty)
        #expect(geometry.facts.rawPixelSize == CGSize(width: 120, height: 180))
        #expect(geometry.facts.displaySize == CGSize(width: 180, height: 120))
        #expect(geometry.facts.orientation == .left)
        #expect(geometry.canvas.photoFrame == CGRect(x: 0, y: 0, width: 180, height: 120))
        #expect(geometry.canvas.footerFrame == CGRect(x: 0, y: 120, width: 180, height: 11))
        #expect(geometry.canvas.canvasSize == CGSize(width: 180, height: 131))
    }

    @Test("Geometry linter reports stable issue codes")
    func geometryLinterReportsStableIssueCodes() {
        let geometry =
            CanonicalGeometry(
                facts:
                    MediaGeometryFacts(
                        rawPixelSize:
                            CGSize(
                                width: 120,
                                height: 180
                            ),
                        displaySize:
                            CGSize(
                                width: 120,
                                height: 180
                            ),
                        orientation:
                            .up
                    ),
                canvas:
                    CanvasGeometry(
                        canvasSize:
                            CGSize(
                                width: 120,
                                height: 180
                            ),
                        photoFrame:
                            CGRect(
                                x: 0,
                                y: 0,
                                width: 120,
                                height: 180
                            ),
                        footerFrame:
                            CGRect(
                                x: 0,
                                y: 181,
                                width: 120,
                                height: 16
                            )
                    )
            )

        let issues =
            GeometryLinter.standard.lint(
                geometry
            )

        #expect(
            issues.map(\.code).contains(
                .footerOutsideCanvas
            )
        )
    }

    @Test("Geometry core stays independent from UI renderer and export modules")
    func geometryCoreStaysIndependentFromUIRendererAndExportModules() throws {
        let allowedImports: Set<String> = [
            "CoreGraphics",
            "Foundation",
            "ImageIO",
            "UniformTypeIdentifiers"
        ]
        let sourceRoot =
            try repositoryRoot()
            .appendingPathComponent(
                "Source/PhotoMemo/PhotoMemo/MediaGeometry",
                isDirectory: true
            )
        let swiftFiles =
            try FileManager.default
            .swiftFiles(
                under: sourceRoot
            )

        #expect(!swiftFiles.isEmpty)

        for fileURL in swiftFiles {
            let source =
                try String(
                    contentsOf: fileURL,
                    encoding: .utf8
                )
            let imports =
                source
                .split(
                    separator: "\n"
                )
                .compactMap { line -> String? in
                    guard line.hasPrefix("import ") else {
                        return nil
                    }

                    return String(
                        line
                            .dropFirst("import ".count)
                            .split(separator: " ")
                            .first
                        ?? ""
                    )
                }
                .filter { !$0.isEmpty }

            #expect(
                Set(imports)
                    .isSubset(
                        of: allowedImports
                    ),
                "\(fileURL.lastPathComponent) imports \(imports), expected only \(allowedImports.sorted())"
            )
        }
    }
}

private extension MediaGeometryFoundationCoreTests {

    func repositoryRoot() throws -> URL {
        URL(
            fileURLWithPath: #filePath
        )
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .deletingLastPathComponent()
    }

    func makeImageFixture(
        fileExtension: String,
        type: UTType,
        width: Int,
        height: Int,
        orientation: MediaGeometryOrientation
    ) throws -> URL {
        let url =
            FileManager.default.temporaryDirectory
            .appendingPathComponent(
                "MediaGeometry-\(UUID().uuidString)"
            )
            .appendingPathExtension(
                fileExtension
            )

        guard
            let image =
                makeSolidImage(
                    width: width,
                    height: height
                ),
            let destination =
                CGImageDestinationCreateWithURL(
                    url as CFURL,
                    type.identifier as CFString,
                    1,
                    nil
                )
        else {
            throw FixtureError.imageCreateFailed
        }

        CGImageDestinationAddImage(
            destination,
            image,
            [
                kCGImagePropertyOrientation:
                    orientation
                    .rawImageIOValue
            ] as CFDictionary
        )

        guard CGImageDestinationFinalize(destination) else {
            throw FixtureError.imageWriteFailed
        }

        return url
    }

    func makeSolidImage(
        width: Int,
        height: Int
    ) -> CGImage? {
        guard
            let context =
                CGContext(
                    data: nil,
                    width: width,
                    height: height,
                    bitsPerComponent: 8,
                    bytesPerRow: 0,
                    space:
                        CGColorSpaceCreateDeviceRGB(),
                    bitmapInfo:
                        CGImageAlphaInfo
                        .premultipliedLast
                        .rawValue
                )
        else {
            return nil
        }

        context.setFillColor(
            CGColor(
                red: 0.2,
                green: 0.4,
                blue: 0.6,
                alpha: 1
            )
        )
        context.fill(
            CGRect(
                x: 0,
                y: 0,
                width: width,
                height: height
            )
        )

        return context.makeImage()
    }

    enum FixtureError:
        Error {
        case imageCreateFailed
        case imageWriteFailed
    }
}

private extension FileManager {

    func swiftFiles(
        under directoryURL: URL
    ) throws -> [URL] {
        let resourceKeys: Set<URLResourceKey> = [
            .isRegularFileKey
        ]
        guard
            let enumerator =
                enumerator(
                    at: directoryURL,
                    includingPropertiesForKeys: Array(resourceKeys)
                )
        else {
            return []
        }

        return try enumerator
            .compactMap { item -> URL? in
                guard
                    let fileURL =
                        item as? URL,
                    fileURL
                        .pathExtension == "swift"
                else {
                    return nil
                }

                let values =
                    try fileURL
                    .resourceValues(
                        forKeys: resourceKeys
                    )

                return values.isRegularFile == true
                    ? fileURL
                    : nil
            }
            .sorted {
                $0.path < $1.path
            }
    }
}

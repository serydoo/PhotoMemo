import Foundation
import Testing

@Suite("RAW input type declaration contract")
struct RawInputInfoPlistContractTests {

    @Test("RAW policy imports Apple ProRAW instead of exporting an Apple-owned type")
    func rawPolicyImportsAppleProRAW() throws {
        let repositoryRoot = URL(
            fileURLWithPath: #filePath
        )
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .deletingLastPathComponent()

        let sourcePath = repositoryRoot.appendingPathComponent(
            "Source/MemoMark/MemoMark/Models/PhotoProcessingInputPolicy.swift"
        )
        let source = try String(contentsOf: sourcePath, encoding: .utf8)
        #expect(
            source.contains("UTType(importedAs: \"com.apple.proraw\")")
        )
        #expect(
            !source.contains("UTType(exportedAs: \"com.apple.proraw\")")
        )

        let infoPlistPath = repositoryRoot.appendingPathComponent(
            "Source/MemoMark/MemoMarkiOS-Info.plist"
        )
        let infoPlistData = try Data(contentsOf: infoPlistPath)
        let propertyList = try #require(
            PropertyListSerialization.propertyList(
                from: infoPlistData,
                options: [],
                format: nil
            ) as? [String: Any]
        )
        let importedTypes = propertyList["UTImportedTypeDeclarations"]
            as? [[String: Any]] ?? []
        let exportedTypes = propertyList["UTExportedTypeDeclarations"]
            as? [[String: Any]] ?? []

        #expect(
            importedTypes.contains {
                ($0["UTTypeIdentifier"] as? String) == "com.apple.proraw"
            }
        )
        #expect(
            !exportedTypes.contains {
                ($0["UTTypeIdentifier"] as? String) == "com.apple.proraw"
            }
        )

        let macInfoPlistPath = repositoryRoot.appendingPathComponent(
            "Source/MemoMark/MemoMark-Info.plist"
        )
        let macInfoPlistData = try Data(contentsOf: macInfoPlistPath)
        let macPropertyList = try #require(
            PropertyListSerialization.propertyList(
                from: macInfoPlistData,
                options: [],
                format: nil
            ) as? [String: Any]
        )
        let macImportedTypes = macPropertyList["UTImportedTypeDeclarations"]
            as? [[String: Any]] ?? []
        let macExportedTypes = macPropertyList["UTExportedTypeDeclarations"]
            as? [[String: Any]] ?? []

        #expect(
            macImportedTypes.contains {
                ($0["UTTypeIdentifier"] as? String) == "com.apple.proraw"
            }
        )
        #expect(
            macExportedTypes.contains {
                ($0["UTTypeIdentifier"] as? String)
                    == "com.apple.live-photo-bundle"
            }
        )

        let projectPath = repositoryRoot.appendingPathComponent(
            "Source/MemoMark/MemoMark.xcodeproj/project.pbxproj"
        )
        let project = try String(contentsOf: projectPath, encoding: .utf8)
        #expect(
            project.contains("INFOPLIST_FILE = \"MemoMark-Info.plist\";")
        )
    }

}

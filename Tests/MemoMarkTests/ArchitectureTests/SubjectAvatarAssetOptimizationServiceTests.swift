import Foundation
import Testing
@testable import MemoMark

@Suite("Subject avatar asset optimization")
struct SubjectAvatarAssetOptimizationServiceTests {

    @Test("startup cleanup removes only hidden avatar staging directories")
    func startupCleanupRemovesOnlyStagingDirectories() throws {
        let root = try Self.makeTemporaryDirectory()
        defer {
            try? FileManager.default.removeItem(at: root)
        }

        let stagingDirectory = root.appendingPathComponent(
            ".memomark-subject-avatar-staging.tmp",
            isDirectory: true
        )
        let committedDirectory = root.appendingPathComponent(
            "memomark-subject-avatar-committed",
            isDirectory: true
        )
        let unrelatedDirectory = root.appendingPathComponent(
            ".other-staging-directory",
            isDirectory: true
        )

        try FileManager.default.createDirectory(
            at: stagingDirectory,
            withIntermediateDirectories: true
        )
        try FileManager.default.createDirectory(
            at: committedDirectory,
            withIntermediateDirectories: true
        )
        try FileManager.default.createDirectory(
            at: unrelatedDirectory,
            withIntermediateDirectories: true
        )

        SubjectAvatarAssetOptimizationService
            .cleanupTemporaryAssetDirectories(at: root)

        #expect(
            !FileManager.default.fileExists(
                atPath: stagingDirectory.path
            )
        )
        #expect(
            FileManager.default.fileExists(
                atPath: committedDirectory.path
            )
        )
        #expect(
            FileManager.default.fileExists(
                atPath: unrelatedDirectory.path
            )
        )
    }

    @Test("generated avatar paths are validated inside the subject asset root")
    func generatedAvatarPathsAreValidatedInsideSubjectAssetRoot() throws {
        let root = try Self.makeTemporaryDirectory()
        defer {
            try? FileManager.default.removeItem(at: root)
        }

        let transactionDirectory = root.appendingPathComponent(
            "memomark-subject-avatar-transaction",
            isDirectory: true
        )
        try FileManager.default.createDirectory(
            at: transactionDirectory,
            withIntermediateDirectories: true
        )

        let generatedURL = transactionDirectory.appendingPathComponent(
            "memomark-subject-avatar-display-transaction-512.png"
        )
        let unrelatedURL = transactionDirectory.appendingPathComponent(
            "user-file.png"
        )
        try Data("generated".utf8).write(to: generatedURL)
        try Data("unrelated".utf8).write(to: unrelatedURL)

        #expect(
            SubjectAvatarAssetOptimizationService.isGeneratedAsset(
                generatedURL,
                in: root
            )
        )
        #expect(
            !SubjectAvatarAssetOptimizationService.isGeneratedAsset(
                unrelatedURL,
                in: root
            )
        )

        SubjectAvatarAssetOptimizationService
            .discardUncommittedAsset(
                atPath: generatedURL.path,
                in: root
            )

        #expect(
            !FileManager.default.fileExists(
                atPath: transactionDirectory.path
            )
        )
    }
}

private extension SubjectAvatarAssetOptimizationServiceTests {

    static func makeTemporaryDirectory() throws -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent(
                "SubjectAvatarAssetOptimizationServiceTests-\(UUID().uuidString)",
                isDirectory: true
            )
        try FileManager.default.createDirectory(
            at: url,
            withIntermediateDirectories: true
        )
        return url
    }
}

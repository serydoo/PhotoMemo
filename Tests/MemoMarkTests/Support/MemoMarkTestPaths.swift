import Foundation

enum MemoMarkTestPaths {

    static let repositoryRoot: URL = {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
    }()

    static func path(_ repositoryRelativePath: String) -> String {
        repositoryRoot
            .appendingPathComponent(repositoryRelativePath)
            .standardizedFileURL
            .path
    }
}

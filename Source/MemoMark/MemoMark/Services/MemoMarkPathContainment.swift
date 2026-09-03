import Foundation

nonisolated enum MemoMarkPathContainment {

    static func contains(
        _ candidateURL: URL,
        root rootURL: URL
    ) -> Bool {
        let candidate = candidateURL.standardizedFileURL.path
        let root = rootURL.standardizedFileURL.path
        return candidate == root || candidate.hasPrefix(root + "/")
    }
}

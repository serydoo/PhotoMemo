import Foundation

/// One processing-intent compiler for all execution owners. A provider name
/// or a new request UUID must never stand in for the source/configuration.
@MainActor
enum BatchProcessingIdentityCompiler {
    static func prepare(_ job: BatchJob) async throws -> BatchJob {
        try Task.checkCancellation()
        let semantics = try ProcessingIdentity.canonicalSemantics(JSONEncoder().encode(job.configuration))
        var sourceVersions: [String?] = []
        for task in job.tasks {
            try Task.checkCancellation()
            sourceVersions.append(try await ProcessingSourceVersionResolver.version(for: task.sourceIdentifier))
        }
        let identities = try await ProcessingIdentityBuilder.shared.identities(
            sourceURLs: job.tasks.map(\.sourceURL), semantics: semantics,
            sourceVersions: sourceVersions,
            assetBaseURL: MemoMarkSharedContainer.baseDirectoryURL
        )
        try Task.checkCancellation()
        var prepared = job
        for index in prepared.tasks.indices {
            prepared.tasks[index].processingIdentity = identities[index]
        }
        return prepared
    }
}

import Foundation

final class IntakeCleanupService {

    private let intakeDirectoryURL:
        URL

    init(
        intakeDirectoryURL: URL
    ) {
        self.intakeDirectoryURL =
            intakeDirectoryURL
            .standardizedFileURL
    }

    func cleanupManagedSourceIfNeeded(
        at url: URL
    ) {

        let normalizedURL =
            url.standardizedFileURL

        guard isManagedIntakeURL(
            normalizedURL
        ) else {
            return
        }

        do {
            if FileManager.default.fileExists(
                atPath: normalizedURL.path
            ) {
                try FileManager.default.removeItem(
                    at: normalizedURL
                )
            }

            cleanupEmptyParentDirectories(
                startingAt:
                    normalizedURL
                    .deletingLastPathComponent()
            )
        } catch {
            return
        }
    }

    func cleanupOrphanedManagedContent(
        keepingReferencedURLs
        referencedURLs: Set<URL>
    ) {

        let normalizedReferencedURLs =
            Set(
                referencedURLs.map {
                    $0.standardizedFileURL
                }
            )

        guard
            let requestDirectories =
                try? FileManager.default
                .contentsOfDirectory(
                    at: intakeDirectoryURL,
                    includingPropertiesForKeys: nil,
                    options: [.skipsHiddenFiles]
                )
        else {
            return
        }

        for requestDirectoryURL
            in requestDirectories {

            guard
                let childURLs =
                    try? FileManager.default
                    .contentsOfDirectory(
                        at: requestDirectoryURL,
                        includingPropertiesForKeys: nil,
                        options: [.skipsHiddenFiles]
                    )
            else {
                continue
            }

            let retainedChildren =
                childURLs.filter { childURL in
                    normalizedReferencedURLs
                        .contains(
                            childURL
                            .standardizedFileURL
                        )
                }

            if retainedChildren.isEmpty {
                try? FileManager.default
                    .removeItem(
                        at: requestDirectoryURL
                    )
                continue
            }

            for childURL in childURLs
            where !normalizedReferencedURLs
                .contains(
                    childURL.standardizedFileURL
                ) {

                try? FileManager.default
                    .removeItem(
                        at: childURL
                    )
            }

            cleanupEmptyParentDirectories(
                startingAt:
                    requestDirectoryURL
            )
        }
    }
}

private extension IntakeCleanupService {

    func isManagedIntakeURL(
        _ url: URL
    ) -> Bool {

        let normalizedPath =
            url.standardizedFileURL.path
        let intakeRootPath =
            intakeDirectoryURL.path

        return normalizedPath == intakeRootPath
            || normalizedPath.hasPrefix(
                intakeRootPath + "/"
            )
    }

    func cleanupEmptyParentDirectories(
        startingAt directoryURL: URL
    ) {

        var currentDirectoryURL =
            directoryURL
            .standardizedFileURL
        let intakeRootPath =
            intakeDirectoryURL.path

        while currentDirectoryURL.path
                != intakeRootPath,
              isManagedIntakeURL(
                currentDirectoryURL
              ) {

            guard
                let children =
                    try? FileManager.default
                    .contentsOfDirectory(
                        at: currentDirectoryURL,
                        includingPropertiesForKeys: nil
                    ),
                children.isEmpty
            else {
                return
            }

            try? FileManager.default.removeItem(
                at: currentDirectoryURL
            )

            currentDirectoryURL =
                currentDirectoryURL
                .deletingLastPathComponent()
        }
    }
}

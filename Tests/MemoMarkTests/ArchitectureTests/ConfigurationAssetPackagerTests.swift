#if !MEMOMARK_SHARE_EXTENSION
import Foundation
import Testing
@testable import MemoMark

@Suite("Configuration asset packager")
struct ConfigurationAssetPackagerTests {

    @Test("avatar and logo are packaged as checksummed relative assets")
    func packagesAvatarAndLogoAsRelativeAssets() throws {
        let workspace = Self.makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: workspace) }
        let sourceDirectory = workspace.appendingPathComponent("Sources")
        let packageRoot = workspace.appendingPathComponent("Package")
        try FileManager.default.createDirectory(
            at: sourceDirectory,
            withIntermediateDirectories: true
        )
        let avatarURL = sourceDirectory.appendingPathComponent("avatar.png")
        let logoURL = sourceDirectory.appendingPathComponent("family-logo.png")
        try Data("avatar-data".utf8).write(to: avatarURL)
        try Data("logo-data".utf8).write(to: logoURL)
        var subject = Self.makeSubject()
        subject.identity.avatarImagePath = avatarURL.path
        let configuration = Self.makeConfiguration()

        let package = try ConfigurationAssetPackager().package(
            subject: subject,
            configuration: configuration,
            sourceURLs: [
                .subjectAvatar: avatarURL,
                .customLogo: logoURL
            ],
            destinationRootURL: packageRoot
        )

        let avatarPath = try #require(
            package.subject.identity.avatarImagePath
        )
        let logoReference = try #require(
            package.configuration.presentation.logo.badge?
                .assetReference
        )
        #expect(PortableAssetReference.isValid(avatarPath))
        #expect(PortableAssetReference.isValid(logoReference.relativePath))
        #expect(!avatarPath.hasPrefix("/"))
        #expect(avatarPath.contains("sha256-"))
        #expect(logoReference.relativePath.contains("sha256-"))
        #expect(package.manifest.entries.count == 2)
        #expect(Set(package.manifest.entries.map(\.role)) == [
            .subjectAvatar,
            .customLogo
        ])
        #expect(package.manifest.entries.allSatisfy {
            $0.checksum?.hasPrefix("sha256:") == true
        })
        #expect(
            try Data(contentsOf: packageRoot.appendingPathComponent(avatarPath))
            == Data("avatar-data".utf8)
        )
        #expect(
            try Data(
                contentsOf: packageRoot.appendingPathComponent(
                    logoReference.relativePath
                )
            ) == Data("logo-data".utf8)
        )
    }

    @Test("custom-logo packaging rejects a missing logo asset")
    func customLogoPackagingRejectsMissingAsset() throws {
        let workspace = Self.makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: workspace) }
        let sourceDirectory = workspace.appendingPathComponent("Sources")
        let packageRoot = workspace.appendingPathComponent("Package")
        try FileManager.default.createDirectory(
            at: sourceDirectory,
            withIntermediateDirectories: true
        )
        let avatarURL = sourceDirectory.appendingPathComponent("avatar.png")
        try Data("avatar-data".utf8).write(to: avatarURL)

        #expect(
            throws: ConfigurationAssetPackagingError
                .missingSource(.customLogo)
        ) {
            _ = try ConfigurationAssetPackager().package(
                subject: Self.makeSubject(),
                configuration: Self.makeConfiguration(),
                sourceURLs: [.subjectAvatar: avatarURL],
                destinationRootURL: packageRoot
            )
        }
        #expect(
            !FileManager.default.fileExists(
                atPath: packageRoot.path
            )
        )
    }

    @Test("custom-logo packaging rejects a missing logo descriptor")
    func customLogoPackagingRejectsMissingDescriptor() throws {
        let workspace = Self.makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: workspace) }
        let sourceDirectory = workspace.appendingPathComponent("Sources")
        let packageRoot = workspace.appendingPathComponent("Package")
        try FileManager.default.createDirectory(
            at: sourceDirectory,
            withIntermediateDirectories: true
        )
        let logoURL = sourceDirectory.appendingPathComponent("logo.png")
        try Data("logo-data".utf8).write(to: logoURL)
        var configuration = Self.makeConfiguration()
        configuration.presentation.logo.badge = nil

        #expect(
            throws: ConfigurationAssetPackagingError
                .missingSource(.customLogo)
        ) {
            _ = try ConfigurationAssetPackager().package(
                subject: Self.makeSubject(),
                configuration: configuration,
                sourceURLs: [.customLogo: logoURL],
                destinationRootURL: packageRoot
            )
        }
        #expect(
            !FileManager.default.fileExists(
                atPath: packageRoot.path
            )
        )
    }

    @Test("restore copies packaged assets and remaps live avatar and logo URLs")
    func restoresAndRemapsPackagedAssets() throws {
        let workspace = Self.makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: workspace) }
        let sourceDirectory = workspace.appendingPathComponent("Sources")
        let packageRoot = workspace.appendingPathComponent("Package")
        let restoreRoot = workspace.appendingPathComponent("Restored")
        try FileManager.default.createDirectory(
            at: sourceDirectory,
            withIntermediateDirectories: true
        )
        let avatarURL = sourceDirectory.appendingPathComponent("avatar.heic")
        let logoURL = sourceDirectory.appendingPathComponent("logo.pdf")
        try Data("avatar".utf8).write(to: avatarURL)
        try Data("logo".utf8).write(to: logoURL)
        var subject = Self.makeSubject()
        subject.identity.avatarImagePath = avatarURL.path
        let package = try ConfigurationAssetPackager().package(
            subject: subject,
            configuration: Self.makeConfiguration(),
            sourceURLs: [
                .subjectAvatar: avatarURL,
                .customLogo: logoURL
            ],
            destinationRootURL: packageRoot
        )
        let document = PortableMemoryConfigurationDocument(
            appVersion: "1.6",
            subject: package.subject,
            configuration: package.configuration,
            assetManifest: package.manifest,
            documentChecksum: "pending"
        )

        let restored = try ConfigurationAssetPackager().restoreAssets(
            in: document,
            sourceRootURL: packageRoot,
            destinationRootURL: restoreRoot
        )

        let restoredAvatarPath = try #require(
            restored.subject.identity.avatarImagePath
        )
        let restoredAvatarURL = URL(fileURLWithPath: restoredAvatarPath)
        let restoredLogoURL = try #require(
            restored.assetURL(for: .customLogo)
        )
        #expect(restoredAvatarURL.path.hasPrefix(restoreRoot.path))
        #expect(restoredLogoURL.path.hasPrefix(restoreRoot.path))
        #expect(try Data(contentsOf: restoredAvatarURL) == Data("avatar".utf8))
        #expect(try Data(contentsOf: restoredLogoURL) == Data("logo".utf8))
        #expect(
            restored.configuration.presentation.logo.badge?
                .assetReference
            == package.configuration.presentation.logo.badge?
                .assetReference
        )
    }

    @Test("restore rejects a source symlink that escapes the package root")
    func rejectsSourceSymlinkEscape() throws {
        let workspace = Self.makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: workspace) }
        let sourceDirectory = workspace.appendingPathComponent("Sources")
        let packageRoot = workspace.appendingPathComponent("Package")
        let restoreRoot = workspace.appendingPathComponent("Restored")
        let outsideURL = workspace.appendingPathComponent("outside-avatar.png")
        try FileManager.default.createDirectory(
            at: sourceDirectory,
            withIntermediateDirectories: true
        )
        let avatarURL = sourceDirectory.appendingPathComponent("avatar.png")
        try Data("packaged-avatar".utf8).write(to: avatarURL)
        let package = try ConfigurationAssetPackager().package(
            subject: Self.makeSubject(),
            configuration: Self.makeConfiguration(
                logoMode: .appleMini
            ),
            sourceURLs: [.subjectAvatar: avatarURL],
            destinationRootURL: packageRoot
        )
        let entry = try #require(package.manifest.entries.first)
        let packagedURL = packageRoot.appendingPathComponent(
            entry.reference.relativePath
        )
        try Data("outside-avatar".utf8).write(to: outsideURL)
        try FileManager.default.removeItem(at: packagedURL)
        try FileManager.default.createSymbolicLink(
            at: packagedURL,
            withDestinationURL: outsideURL
        )
        let document = PortableMemoryConfigurationDocument(
            appVersion: "1.6",
            subject: package.subject,
            configuration: package.configuration,
            assetManifest: package.manifest,
            documentChecksum: "pending"
        )

        #expect(
            throws: ConfigurationAssetPackagingError.pathEscapesRoot(
                path: outsideURL.standardizedFileURL
                    .resolvingSymlinksInPath().path,
                root: packageRoot.standardizedFileURL
                    .resolvingSymlinksInPath().path
            )
        ) {
            _ = try ConfigurationAssetPackager().restoreAssets(
                in: document,
                sourceRootURL: packageRoot,
                destinationRootURL: restoreRoot
            )
        }
    }

    @Test("restore rejects a destination symlink that escapes the restore root")
    func rejectsDestinationSymlinkEscape() throws {
        let workspace = Self.makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: workspace) }
        let sourceDirectory = workspace.appendingPathComponent("Sources")
        let packageRoot = workspace.appendingPathComponent("Package")
        let restoreRoot = workspace.appendingPathComponent("Restored")
        let outsideRoot = workspace.appendingPathComponent("Outside")
        try FileManager.default.createDirectory(
            at: sourceDirectory,
            withIntermediateDirectories: true
        )
        try FileManager.default.createDirectory(
            at: restoreRoot,
            withIntermediateDirectories: true
        )
        try FileManager.default.createDirectory(
            at: outsideRoot,
            withIntermediateDirectories: true
        )
        let avatarURL = sourceDirectory.appendingPathComponent("avatar.png")
        try Data("avatar".utf8).write(to: avatarURL)
        let package = try ConfigurationAssetPackager().package(
            subject: Self.makeSubject(),
            configuration: Self.makeConfiguration(
                logoMode: .appleMini
            ),
            sourceURLs: [.subjectAvatar: avatarURL],
            destinationRootURL: packageRoot
        )
        try FileManager.default.createSymbolicLink(
            at: restoreRoot.appendingPathComponent("Assets"),
            withDestinationURL: outsideRoot
        )
        let document = PortableMemoryConfigurationDocument(
            appVersion: "1.6",
            subject: package.subject,
            configuration: package.configuration,
            assetManifest: package.manifest,
            documentChecksum: "pending"
        )

        let escapedDestinationURL = outsideRoot
            .appendingPathComponent(
                try #require(package.manifest.entries.first)
                    .reference.relativePath
                    .replacingOccurrences(
                        of: "Assets/",
                        with: ""
                    )
            )
        #expect(
            throws: ConfigurationAssetPackagingError.pathEscapesRoot(
                path: escapedDestinationURL.standardizedFileURL
                    .resolvingSymlinksInPath().path,
                root: restoreRoot.standardizedFileURL
                    .resolvingSymlinksInPath().path
            )
        ) {
            _ = try ConfigurationAssetPackager().restoreAssets(
                in: document,
                sourceRootURL: packageRoot,
                destinationRootURL: restoreRoot
            )
        }
        #expect(
            try FileManager.default.contentsOfDirectory(
                atPath: outsideRoot.path
            ).isEmpty
        )
    }

    @Test("packaging never overwrites conflicting content-addressed assets")
    func rejectsConflictingDestinationAsset() throws {
        let workspace = Self.makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: workspace) }
        let sourceDirectory = workspace.appendingPathComponent("Sources")
        let packageRoot = workspace.appendingPathComponent("Package")
        try FileManager.default.createDirectory(
            at: sourceDirectory,
            withIntermediateDirectories: true
        )
        let avatarURL = sourceDirectory.appendingPathComponent("avatar.png")
        let avatarData = Data("avatar".utf8)
        let conflictingData = Data("conflict".utf8)
        try avatarData.write(to: avatarURL)
        let packager = ConfigurationAssetPackager()
        let firstPackage = try packager.package(
            subject: Self.makeSubject(),
            configuration: Self.makeConfiguration(
                logoMode: .appleMini
            ),
            sourceURLs: [.subjectAvatar: avatarURL],
            destinationRootURL: packageRoot
        )
        let relativePath = try #require(
            firstPackage.subject.identity.avatarImagePath
        )
        let destinationURL = packageRoot.appendingPathComponent(relativePath)
        try conflictingData.write(to: destinationURL, options: .atomic)

        #expect(
            throws: ConfigurationAssetPackagingError
                .destinationConflict(destinationURL.path)
        ) {
            _ = try packager.package(
                subject: Self.makeSubject(),
                configuration: Self.makeConfiguration(
                    logoMode: .appleMini
                ),
                sourceURLs: [.subjectAvatar: avatarURL],
                destinationRootURL: packageRoot
            )
        }
        #expect(try Data(contentsOf: destinationURL) == conflictingData)
    }

    @Test("subject-avatar packaging ignores and removes stale custom-logo state")
    func subjectAvatarPackagingKeepsOnlySubjectAssets() throws {
        let workspace = Self.makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: workspace) }
        let sourceDirectory = workspace.appendingPathComponent("Sources")
        let packageRoot = workspace.appendingPathComponent("Package")
        try FileManager.default.createDirectory(
            at: sourceDirectory,
            withIntermediateDirectories: true
        )
        let avatarURL = sourceDirectory.appendingPathComponent("avatar.png")
        let staleLogoURL = sourceDirectory.appendingPathComponent("stale.png")
        try Data("avatar".utf8).write(to: avatarURL)
        try Data("stale".utf8).write(to: staleLogoURL)
        var subject = Self.makeSubject()
        subject.identity.avatarBadgeImagePath = avatarURL.path
        var configuration = Self.makeConfiguration()
        configuration.presentation.logo.mode = .subjectAvatar

        let package = try ConfigurationAssetPackager().package(
            subject: subject,
            configuration: configuration,
            sourceURLs: [
                .subjectAvatarBadge: avatarURL,
                .customLogo: staleLogoURL
            ],
            destinationRootURL: packageRoot
        )

        #expect(
            package.manifest.entries.map(\.role)
            == [.subjectAvatarBadge]
        )
        #expect(package.configuration.presentation.logo.mode == .subjectAvatar)
        #expect(package.configuration.presentation.logo.badge == nil)
        #expect(
            package.subject.identity.avatarBadgeImagePath
            == package.manifest.entries.first?
                .reference.relativePath
        )
        #expect(
            !FileManager.default.fileExists(
                atPath: packageRoot
                    .appendingPathComponent("Assets/customLogo")
                    .path
            )
        )
    }

    @Test("subject-avatar restore ignores legacy custom-logo manifest entries")
    func subjectAvatarRestoreDoesNotCopyStaleCustomLogo() throws {
        let workspace = Self.makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: workspace) }
        let packageRoot = workspace.appendingPathComponent("Package")
        let restoreRoot = workspace.appendingPathComponent("Restored")
        let avatarReference = try PortableAssetReference(
            relativePath: "Assets/subjectAvatarBadge/avatar.png"
        )
        let staleReference = try PortableAssetReference(
            relativePath: "Assets/customLogo/stale.png"
        )
        let avatarURL = packageRoot.appendingPathComponent(
            avatarReference.relativePath
        )
        let staleURL = packageRoot.appendingPathComponent(
            staleReference.relativePath
        )
        try FileManager.default.createDirectory(
            at: avatarURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try FileManager.default.createDirectory(
            at: staleURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try Data("avatar".utf8).write(to: avatarURL)
        try Data("stale".utf8).write(to: staleURL)
        var subject = Self.makeSubject()
        subject.identity.avatarBadgeImagePath = avatarReference.relativePath
        var configuration = Self.makeConfiguration()
        configuration.presentation.logo.mode = .subjectAvatar
        let document = PortableMemoryConfigurationDocument(
            appVersion: "2.1.2",
            subject: subject,
            configuration: configuration,
            assetManifest: .init(entries: [
                .init(
                    role: .subjectAvatarBadge,
                    reference: avatarReference
                ),
                .init(
                    role: .customLogo,
                    reference: staleReference
                )
            ]),
            documentChecksum: "pending"
        )

        let restored = try ConfigurationAssetPackager().restoreAssets(
            in: document,
            sourceRootURL: packageRoot,
            destinationRootURL: restoreRoot
        )

        #expect(restored.assetURL(for: .subjectAvatarBadge) != nil)
        #expect(restored.assetURL(for: .customLogo) == nil)
        #expect(restored.configuration.presentation.logo.mode == .subjectAvatar)
        #expect(restored.configuration.presentation.logo.badge == nil)
        #expect(
            !FileManager.default.fileExists(
                atPath: restoreRoot
                    .appendingPathComponent(staleReference.relativePath)
                    .path
            )
        )
    }
}

private extension ConfigurationAssetPackagerTests {

    static func makeTemporaryDirectory() -> URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
    }

    static func makeSubject() -> MemorySubject {
        MemorySubject(
            id: UUID(uuidString: "AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAAAAA")!,
            identity: .init(displayName: "小宝", shortName: "小宝"),
            relationship: .init(role: "family", label: "成长记录"),
            referenceDate: Date(timeIntervalSince1970: 0),
            behavior: .init(
                primaryAnchor: "生日",
                iconStrategy: .autoMatch,
                badgeStrategy: .fixed,
                memoryExpression: .init(title: "默认表达", blocks: [])
            ),
            decorations: []
        )
    }

    static func makeConfiguration(
        logoMode: ConfigurationLogoMode = .customUpload
    ) -> MemoryConfigurationRecord {
        MemoryConfigurationRecord(
            id: UUID(uuidString: "BBBBBBBB-BBBB-BBBB-BBBB-BBBBBBBBBBBB")!,
            title: "成长配置",
            revision: 7,
            savedAt: Date(timeIntervalSince1970: 1_725_206_400),
            selectedTimeAnchorID: nil,
            editor: .init(
                template: .classicWhite,
                regionTemplateIDs: [:],
                memoryCopy: .init(usesCustomText: false, customText: "")
            ),
            presentation: .init(
                route: .classicWhite,
                locationConfiguration: nil,
                logo: .init(
                    mode: logoMode,
                    badge: logoMode == .customUpload
                        ? .init(
                            id: UUID(uuidString: "CCCCCCCC-CCCC-CCCC-CCCC-CCCCCCCCCCCC")!,
                            name: "家庭标识",
                            type: .customUpload
                        )
                        : nil
                )
            ),
            output: .init(
                mediaMode: .originalFormat,
                livePhotoPolicy: .preserveMotion,
                photosDescriptionPolicy: .init(
                    isEnabled: false,
                    overrideText: ""
                ),
                album: .automatic
            )
        )
    }
}
#endif

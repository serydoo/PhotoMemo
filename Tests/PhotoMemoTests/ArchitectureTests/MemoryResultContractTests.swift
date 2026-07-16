#if !PHOTOMEMO_SHARE_EXTENSION
import Foundation
import Testing
@testable import PhotoMemo

@Suite("MemoryResult contract")
struct MemoryResultContractTests {

    @Test("Configuration session projects MemoryResult through presentation adapter")
    func configurationSessionProjectsMemoryResultThroughPresentationAdapter() throws {
        let source =
            try sourceText(
                relativePath:
                    "Source/PhotoMemo/PhotoMemo/ConfigurationCenter/ConfigurationSession.swift"
            )
        let generatedModuleBody =
            try sourceBlock(
                named: "var generatedMemoryModule",
                in: source
            )

        #expect(
            generatedModuleBody.contains(
                ".generateResult("
            )
        )
        #expect(
            generatedModuleBody.contains(
                "MemoryResultPresentationAdapter"
            )
        )
        #expect(
            !generatedModuleBody.contains(
                ".generateModule("
            )
        )
    }

    @Test("Preview resolver projects MemoryResult through presentation adapter")
    func previewResolverProjectsMemoryResultThroughPresentationAdapter() throws {
        let source =
            try sourceText(
                relativePath:
                    "Source/PhotoMemo/PhotoMemo/MemoryEngine/MemoryExpressionPreviewResolver.swift"
            )

        #expect(
            source.contains(
                ".generateResult("
            )
        )
        #expect(
            source.contains(
                "MemoryResultPresentationAdapter"
            )
        )
        #expect(
            !source.contains(
                ".generateModule("
            )
        )
    }

    @Test("Memory expression engine exposes MemoryResult as its output boundary")
    func memoryExpressionEngineExposesMemoryResultAsItsOutputBoundary() throws {
        let source =
            try sourceText(
                relativePath:
                    "Source/PhotoMemo/PhotoMemo/MemoryEngine/MemoryExpressionEngine.swift"
            )

        #expect(
            source.contains(
                "func generateResult("
            )
        )
        #expect(
            !source.contains(
                "func generateModule("
            )
        )
    }

    @Test("Build service consumes direct frozen ConfigurationSnapshot when available")
    func buildServiceConsumesDirectFrozenConfigurationSnapshotWhenAvailable() throws {
        let source =
            try sourceText(
                relativePath:
                    "Source/PhotoMemo/PhotoMemo/Services/RecordCardBuildService.swift"
            )

        #expect(
            source.contains(
                "canonicalProductionSnapshot"
            )
        )
        #expect(
            source.contains(
                "frozenSnapshot:"
            )
        )
    }

    @Test("Build service completes paired frozen snapshot before legacy adapter")
    func buildServiceCompletesPairedFrozenSnapshotBeforeLegacyAdapter() throws {
        let source =
            try sourceText(
                relativePath:
                    "Source/PhotoMemo/PhotoMemo/Services/RecordCardBuildService.swift"
            )
        #expect(
            source.contains(
                "canonicalProductionSnapshot"
            )
        )

        let completedSnapshotIndex =
            try #require(
                source.range(
                    of: "canonicalProductionSnapshot"
                )?.lowerBound
            )
        let legacyAdapterIndex =
            try #require(
                source.range(
                    of: "resolveLegacyBatchConfiguration"
                )?.lowerBound
            )

        #expect(
            completedSnapshotIndex
            < legacyAdapterIndex
        )
    }

    @Test("Build service authority checks use completed frozen snapshot")
    func buildServiceAuthorityChecksUseCompletedFrozenSnapshot() throws {
        let source =
            try sourceText(
                relativePath:
                    "Source/PhotoMemo/PhotoMemo/Services/RecordCardBuildService.swift"
            )

        #expect(
            source.contains(
                "canonicalProductionSnapshot"
            )
        )
        #expect(
            !source.contains(
                "frozenConfigurationSnapshot != nil"
            )
        )
    }

    @Test("Production resolver isolates live defaults behind legacy fallback")
    func productionResolverIsolatesLiveDefaultsBehindLegacyFallback() throws {
        let source =
            try sourceText(
                relativePath:
                    "Source/PhotoMemo/PhotoMemo/MemoryEngine/ProductionMemoryResolver.swift"
            )

        #expect(
            source.contains(
                "resolveLegacyRuntimeDefaultsFallback"
            )
        )
    }

    @Test("Production resolver has no live defaults dependency")
    func productionResolverHasNoLiveDefaultsDependency() throws {
        let source =
            try sourceText(
                relativePath:
                    "Source/PhotoMemo/PhotoMemo/MemoryEngine/ProductionMemoryResolver.swift"
            )

        #expect(
            !source.contains(
                "UserDefaults"
            )
        )
        #expect(
            !source.contains(
                "legacyDefaults"
            )
        )
        #expect(
            !source.contains(
                "photomemo.personalProfile"
            )
        )
    }

    @Test("App build service does not retain live defaults dependency")
    func appBuildServiceDoesNotRetainLiveDefaultsDependency() throws {
        let buildServiceSource =
            try sourceText(
                relativePath:
                    "Source/PhotoMemo/PhotoMemo/Services/RecordCardBuildService.swift"
            )
        let environmentSource =
            try sourceText(
                relativePath:
                    "Source/PhotoMemo/PhotoMemo/Architecture/AppEnvironment.swift"
            )

        #expect(
            !buildServiceSource.contains(
                "legacyDefaults: UserDefaults?"
            )
        )
        #expect(
            !buildServiceSource.contains(
                "private let defaults: UserDefaults?"
            )
        )
        #expect(
            !buildServiceSource.contains(
                "UserDefaults"
            )
        )
        #expect(
            !buildServiceSource.contains(
                "photomemo.personalProfile"
            )
        )
        #expect(
            !environmentSource.contains(
                "RecordCardBuildService(\n                legacyDefaults: defaults"
            )
        )
    }

    @Test("Production resolver names batch configuration entry as legacy adapter")
    func productionResolverNamesBatchConfigurationEntryAsLegacyAdapter() throws {
        let source =
            try sourceText(
                relativePath:
                    "Source/PhotoMemo/PhotoMemo/MemoryEngine/ProductionMemoryResolver.swift"
            )

        #expect(
            source.contains(
                "func resolveLegacyBatchConfiguration("
            )
        )
        #expect(
            !source.contains(
                "func resolve(\n        photo: SelectedPhoto,\n        configuration: BatchConfigurationSnapshot"
            )
        )
    }

    @Test("Production resolver reads paired subject through legacy projection")
    func productionResolverReadsPairedSubjectThroughLegacyProjection() throws {
        let source =
            try sourceText(
                relativePath:
                    "Source/PhotoMemo/PhotoMemo/MemoryEngine/ProductionMemoryResolver.swift"
            )

        #expect(
            source.contains(
                ".legacyFrozenMemorySubject"
            )
        )
        #expect(
            !source.contains(
                ".frozenMemorySubject"
            )
        )
    }

    @Test("Production paths read legacy DTO fields through named projections")
    func productionPathsReadLegacyDTOFieldsThroughNamedProjections() throws {
        let resolverSource =
            try sourceText(
                relativePath:
                    "Source/PhotoMemo/PhotoMemo/MemoryEngine/ProductionMemoryResolver.swift"
            )
        let buildServiceSource =
            try sourceText(
                relativePath:
                    "Source/PhotoMemo/PhotoMemo/Services/RecordCardBuildService.swift"
            )

        #expect(
            resolverSource.contains(
                "configuration.legacyAnchor"
            )
        )
        #expect(
            !resolverSource.contains(
                "configuration.anchor"
            )
        )
        #expect(
            buildServiceSource.contains(
                "configuration.legacyAnchor"
            )
        )
        #expect(
            buildServiceSource.contains(
                "configuration.legacyMemorySubjectText"
            )
        )
        #expect(
            !buildServiceSource.contains(
                "configuration.anchor"
            )
        )
        #expect(
            !buildServiceSource.contains(
                "configuration.memorySubjectText"
            )
        )
    }

    @Test("Production source does not write legacy paired frozen subject")
    func productionSourceDoesNotWriteLegacyPairedFrozenSubject() throws {
        let providerSource =
            try sourceText(
                relativePath:
                    "Source/PhotoMemo/PhotoMemo/App/BatchConfigurationSnapshotProvider.swift"
            )
        let batchProcessingSource =
            try sourceText(
                relativePath:
                    "Source/PhotoMemo/PhotoMemo/Models/BatchProcessing.swift"
            )

        #expect(
            providerSource.contains(
                ".withCanonicalProductionSnapshot("
            )
        )
        #expect(
            batchProcessingSource.contains(
                "func withLegacyPairedFrozenMemoryConfiguration("
            )
        )
        #expect(
            batchProcessingSource.contains(
                "func withLegacyFrozenMemorySubject("
            )
        )
        #expect(
            !batchProcessingSource.contains(
                "func withFrozenMemoryConfiguration("
            )
        )
        #expect(
            !batchProcessingSource.contains(
                "func withFrozenConfigurationSnapshot("
            )
        )

        let legacyWriters = [
            ".withLegacyPairedFrozenMemoryConfiguration(",
            ".withLegacyFrozenMemorySubject(",
        ]
        let forbiddenCallSites =
            try sourceFiles()
            .filter {
                !$0.hasSuffix(
                    "Models/BatchProcessing.swift"
                )
            }
            .filter { path in
                let source =
                    try String(
                        contentsOf:
                            URL(fileURLWithPath: path),
                        encoding: .utf8
                    )

                return legacyWriters.contains { writer in
                    source.contains(writer)
                }
            }

        #expect(forbiddenCallSites.isEmpty)
    }

    @Test("Frozen DTO fields are write-protected behind named helpers")
    func frozenDTOFieldsAreWriteProtectedBehindNamedHelpers() throws {
        let source =
            try sourceText(
                relativePath:
                    "Source/PhotoMemo/PhotoMemo/Models/BatchProcessing.swift"
            )

        #expect(
            source.contains(
                "private(set) var frozenMemorySubject"
            )
        )
        #expect(
            source.contains(
                "private(set) var frozenConfigurationSnapshot"
            )
        )
    }

    @Test("BatchConfigurationSnapshot remains transport DTO for production semantics")
    func batchConfigurationSnapshotRemainsTransportDTOForProductionSemantics() throws {
        let source =
            try sourceText(
                relativePath:
                    "Source/PhotoMemo/PhotoMemo/Models/BatchProcessing.swift"
            )
        let body =
            try sourceRange(
                from: "struct BatchConfigurationSnapshot:",
                to: "\n    init(",
                in: source
            )
        let storedPropertyNames =
            body
            .components(
                separatedBy: .newlines
            )
            .compactMap(storedPropertyName)

        #expect(
            storedPropertyNames == [
                "id",
                "createdAt",
                "configurationID",
                "configurationRevision",
                "productionContractVersion",
                "template",
                "badge",
                "anchor",
                "memorySubjectText",
                "locationDisplayConfiguration",
                "usesCustomMemoryWriteText",
                "customMemoryWriteText",
                "presentationRouteRawValue",
                "logoModeRawValue",
                "frozenMemorySubject",
                "frozenConfigurationSnapshot",
                "shouldWritePhotoDescription",
                "photoDescriptionOverride",
                "selectedAlbumIdentifier",
                "mediaOutputModeRawValue",
                "livePhotoPolicyRawValue"
            ]
        )
    }

    @Test("Production paths consume canonical production snapshot projection")
    func productionPathsConsumeCanonicalProductionSnapshotProjection() throws {
        let productionFiles = [
            "Source/PhotoMemo/PhotoMemo/MemoryEngine/ProductionMemoryResolver.swift",
            "Source/PhotoMemo/PhotoMemo/Services/RecordCardBuildService.swift",
            "Source/PhotoMemo/PhotoMemo/App/PhotoMemoShareWorkflowSummary.swift",
        ]

        for relativePath in productionFiles {
            let source =
                try sourceText(
                    relativePath: relativePath
                )

            #expect(
                source.contains(
                    ".canonicalProductionSnapshot"
                ),
                "\(relativePath) should consume canonical production snapshot"
            )
            #expect(
                !source.contains(
                    ".completedFrozenConfigurationSnapshot"
                ),
                "\(relativePath) should not use legacy completed snapshot name"
            )
            #expect(
                !source.contains(
                    ".frozenConfigurationSnapshot"
                ),
                "\(relativePath) should not read raw frozen snapshot DTO field"
            )
            #expect(
                !source.contains(
                    ".frozenMemorySubject"
                ),
                "\(relativePath) should not read raw frozen subject DTO field"
            )
        }
    }

    @Test("produces structured anchor result before presentation projection")
    func producesStructuredAnchorResultBeforePresentationProjection() throws {
        let birthday =
            try #require(
                Calendar.current.date(
                    from: DateComponents(
                        year: 2025,
                        month: 5,
                        day: 26
                    )
                )
            )
        let captureDate =
            try #require(
                Calendar.current.date(
                    from: DateComponents(
                        year: 2025,
                        month: 6,
                        day: 13
                    )
                )
            )
        let subject =
            MemorySubject(
                identity:
                    .init(
                        displayName: "示例对象",
                        shortName: "小宝"
                    ),
                relationship:
                    .init(
                        role: "宝宝",
                        label: "妈妈眼里的宝宝"
                    ),
                definition: "测试对象",
                referenceDate: birthday,
                timeAnchors: [
                    .init(
                        title: "生日",
                        date: birthday,
                        note: "出生日期",
                        anchorType: .birthday,
                        expressionStyle:
                            .birthdayAgeToday
                    )
                ],
                expressionSubjectSource: .shortName,
                behavior:
                    MemoryBehavior(
                        primaryAnchor: "生日",
                        iconStrategy: .autoMatch,
                        badgeStrategy: .autoMatch,
                        memoryExpression:
                            MemoryExpression(
                                title: "生日记忆",
                                blocks: [
                                    .text("生日智能模块")
                                ]
                            )
                    ),
                decorations: []
            )
        let snapshot =
            ConfigurationSnapshotBuilder.build(
                from: subject,
                smartModuleCarrierRegion: .slotD
            )
        let context =
            MemoryExpressionContext(
                subject: subject,
                snapshot: snapshot,
                captureDate: captureDate
            )

        let result =
            MemoryExpressionEngine()
            .generateResult(context: context)
        let anchorResult =
            try #require(
                result.primaryAnchorResult
            )

        #expect(result.subjectID == subject.id)
        #expect(result.captureDate == captureDate)
        #expect(result.primaryAnchorResultID == anchorResult.id)
        #expect(anchorResult.anchorID == snapshot.primaryAnchor?.id)
        #expect(anchorResult.anchorType == .birthday)
        #expect(anchorResult.anchorTitle == "生日")
        #expect(anchorResult.anchorDate == birthday)
        #expect(anchorResult.direction == .afterAnchor)
        #expect(anchorResult.elapsed.totalDays == 18)
        #expect(anchorResult.elapsed.years == 0)
        #expect(anchorResult.elapsed.months == 0)
        #expect(anchorResult.elapsed.days == 18)
        #expect(anchorResult.status == .resolved)
        #expect(anchorResult.source == .frozenConfiguration)

        let module =
            MemoryResultPresentationAdapter()
            .makeModule(
                result: result,
                context: context
            )

        #expect(module.renderedText == "今天小宝18天")
        #expect(module.sourceAnchor == snapshot.primaryAnchor)
        #expect(module.preferredRegion == .slotD)
    }

    @Test("keeps anchor result status when capture date is missing")
    func keepsAnchorResultStatusWhenCaptureDateIsMissing() throws {
        let birthday =
            try #require(
                Calendar.current.date(
                    from: DateComponents(
                        year: 2025,
                        month: 5,
                        day: 26
                    )
                )
            )
        let subject =
            MemorySubject(
                identity:
                    .init(
                        displayName: "示例对象",
                        shortName: "小宝"
                    ),
                relationship:
                    .init(
                        role: "宝宝",
                        label: "妈妈眼里的宝宝"
                    ),
                definition: "测试对象",
                referenceDate: birthday,
                timeAnchors: [
                    .init(
                        title: "生日",
                        date: birthday,
                        note: "出生日期",
                        anchorType: .birthday
                    )
                ],
                expressionSubjectSource: .shortName,
                behavior:
                    MemoryBehavior(
                        primaryAnchor: "生日",
                        iconStrategy: .autoMatch,
                        badgeStrategy: .autoMatch,
                        memoryExpression:
                            MemoryExpression(
                                title: "生日记忆",
                                blocks: [
                                    .text("生日智能模块")
                                ]
                            )
                    ),
                decorations: []
            )
        let snapshot =
            ConfigurationSnapshotBuilder.build(
                from: subject
            )
        let context =
            MemoryExpressionContext(
                subject: subject,
                snapshot: snapshot,
                captureDate: nil
            )

        let result =
            MemoryExpressionEngine()
            .generateResult(context: context)
        let anchorResult =
            try #require(
                result.primaryAnchorResult
            )

        #expect(result.subjectID == subject.id)
        #expect(result.captureDate == nil)
        #expect(anchorResult.anchorID == snapshot.primaryAnchor?.id)
        #expect(anchorResult.anchorTitle == "生日")
        #expect(anchorResult.status == .missingCaptureDate)
        #expect(anchorResult.precision == .missingCaptureDate)
        #expect(anchorResult.elapsed.totalDays == 0)

        let module =
            MemoryResultPresentationAdapter()
            .makeModule(
                result: result,
                context: context
            )

        #expect(module.renderedText == "生日智能模块")
    }

    @Test("keeps anchor result status when primary anchor is disabled")
    func keepsAnchorResultStatusWhenPrimaryAnchorIsDisabled() throws {
        let birthday =
            try #require(
                Calendar.current.date(
                    from: DateComponents(
                        year: 2025,
                        month: 5,
                        day: 26
                    )
                )
            )
        let captureDate =
            try #require(
                Calendar.current.date(
                    from: DateComponents(
                        year: 2025,
                        month: 6,
                        day: 13
                    )
                )
            )
        let subject =
            MemorySubject(
                identity:
                    .init(
                        displayName: "示例对象",
                        shortName: "小宝"
                    ),
                relationship:
                    .init(
                        role: "宝宝",
                        label: "妈妈眼里的宝宝"
                    ),
                definition: "测试对象",
                referenceDate: birthday,
                timeAnchors: [],
                expressionSubjectSource: .shortName,
                behavior:
                    MemoryBehavior(
                        primaryAnchor: "生日",
                        iconStrategy: .autoMatch,
                        badgeStrategy: .autoMatch,
                        memoryExpression:
                            MemoryExpression(
                                title: "生日记忆",
                                blocks: [
                                    .text("生日智能模块")
                                ]
                            )
                    ),
                decorations: []
            )
        let disabledAnchor =
            MemoryAnchor(
                title: "生日",
                date: birthday,
                anchorType: .birthday,
                isEnabled: false
            )
        let snapshot =
            ConfigurationSnapshot(
                subjectID: subject.id,
                expression:
                    subject.behavior.memoryExpression,
                decorations: [],
                primaryAnchor: disabledAnchor
            )
        let context =
            MemoryExpressionContext(
                subject: subject,
                snapshot: snapshot,
                captureDate: captureDate
            )

        let result =
            MemoryExpressionEngine()
            .generateResult(context: context)
        let anchorResult =
            try #require(
                result.primaryAnchorResult
            )

        #expect(anchorResult.anchorID == disabledAnchor.id)
        #expect(anchorResult.status == .disabledAnchor)
        #expect(anchorResult.elapsed.totalDays == 0)

        let module =
            MemoryResultPresentationAdapter()
            .makeModule(
                result: result,
                context: context
            )

        #expect(module.renderedText == "生日智能模块")
    }

    @Test("keeps anchor result status when primary anchor type is unsupported")
    func keepsAnchorResultStatusWhenPrimaryAnchorTypeIsUnsupported() throws {
        let anchorDate =
            try #require(
                Calendar.current.date(
                    from: DateComponents(
                        year: 2025,
                        month: 5,
                        day: 26
                    )
                )
            )
        let captureDate =
            try #require(
                Calendar.current.date(
                    from: DateComponents(
                        year: 2025,
                        month: 6,
                        day: 13
                    )
                )
            )
        let subject =
            MemorySubject(
                identity:
                    .init(
                        displayName: "示例对象",
                        shortName: "小宝"
                    ),
                relationship:
                    .init(
                        role: "宝宝",
                        label: "妈妈眼里的宝宝"
                    ),
                definition: "测试对象",
                referenceDate: anchorDate,
                timeAnchors: [],
                expressionSubjectSource: .shortName,
                behavior:
                    MemoryBehavior(
                        primaryAnchor: "纪念日",
                        iconStrategy: .autoMatch,
                        badgeStrategy: .autoMatch,
                        memoryExpression:
                            MemoryExpression(
                                title: "纪念日记忆",
                                blocks: [
                                    .text("纪念日智能模块")
                                ]
                            )
                    ),
                decorations: []
            )
        let unsupportedAnchor =
            MemoryAnchor(
                title: "纪念日",
                date: anchorDate,
                anchorType: nil
            )
        let snapshot =
            ConfigurationSnapshot(
                subjectID: subject.id,
                expression:
                    subject.behavior.memoryExpression,
                decorations: [],
                primaryAnchor:
                    unsupportedAnchor
            )
        let context =
            MemoryExpressionContext(
                subject: subject,
                snapshot: snapshot,
                captureDate: captureDate
            )

        let result =
            MemoryExpressionEngine()
            .generateResult(context: context)
        let anchorResult =
            try #require(
                result.primaryAnchorResult
            )

        #expect(anchorResult.anchorID == unsupportedAnchor.id)
        #expect(anchorResult.anchorType == nil)
        #expect(anchorResult.status == .unsupportedAnchor)
        #expect(anchorResult.elapsed.totalDays == 0)

        let module =
            MemoryResultPresentationAdapter()
            .makeModule(
                result: result,
                context: context
            )

        #expect(module.renderedText == "纪念日智能模块")
    }
}

private extension MemoryResultContractTests {

    func sourceText(
        relativePath: String
    ) throws -> String {
        try String(
            contentsOf:
                sourceURL(relativePath: relativePath),
            encoding: .utf8
        )
    }

    func sourceURL(
        relativePath: String
    ) -> URL {
        let testsDirectory =
            URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
        let repositoryRoot =
            testsDirectory
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let sourceURL =
            repositoryRoot
            .appendingPathComponent(relativePath)

        return sourceURL
    }

    func sourceFiles() throws -> [String] {
        let sourceDirectory =
            sourceURL(
                relativePath:
                    "Source/PhotoMemo/PhotoMemo"
            )
        let enumerator =
            try #require(
                FileManager.default.enumerator(
                    at: sourceDirectory,
                    includingPropertiesForKeys: nil
                )
            )

        return enumerator
            .compactMap {
                ($0 as? URL)?.path
            }
            .filter {
                $0.hasSuffix(".swift")
            }
    }

    func sourceBlock(
        named declaration: String,
        in source: String
    ) throws -> String {
        guard
            let start = source.range(
                of: declaration
            ),
            let end = source[start.upperBound...]
                .range(
                    of: "\n    var resolvedMemoryWriteText"
                )
        else {
            throw CocoaError(.coderReadCorrupt)
        }

        return String(
            source[start.lowerBound..<end.lowerBound]
        )
    }

    func sourceRange(
        from startMarker: String,
        to endMarker: String,
        in source: String
    ) throws -> String {
        guard
            let start = source.range(
                of: startMarker
            ),
            let end = source[start.upperBound...]
                .range(
                    of: endMarker
                )
        else {
            throw CocoaError(.coderReadCorrupt)
        }

        return String(
            source[start.lowerBound..<end.lowerBound]
        )
    }

    func storedPropertyName(
        from line: String
    ) -> String? {
        let trimmed =
            line.trimmingCharacters(
                in: .whitespaces
            )

        let remainder: Substring
        if trimmed.hasPrefix("let ") {
            remainder =
                trimmed.dropFirst("let ".count)
        } else if trimmed.hasPrefix("private(set) var ") {
            remainder =
                trimmed.dropFirst(
                    "private(set) var ".count
                )
        } else if trimmed.hasPrefix("var ") {
            remainder =
                trimmed.dropFirst("var ".count)
        } else {
            return nil
        }

        return remainder
            .split(
                whereSeparator: {
                    $0 == ":"
                    || $0 == " "
                    || $0 == "\t"
                }
            )
            .first
            .map(String.init)
    }
}
#endif

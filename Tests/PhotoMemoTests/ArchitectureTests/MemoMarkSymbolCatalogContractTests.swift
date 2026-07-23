#if !PHOTOMEMO_SHARE_EXTENSION
import Foundation
import Testing

@Suite("MemoMark symbol catalog contract")
struct MemoMarkSymbolCatalogContractTests {

    @Test("catalog defines stable product semantics")
    func catalogDefinesStableProductSemantics() throws {
        let source = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/Views/MemoMarkSymbol.swift"
        )

        for semantic in [
            "home", "configurationCenter",
            "memorySubject", "timeAnchor", "memoryContent",
            "photoMetadata", "location", "configuration",
            "module", "output", "applePhotos", "localStorage",
            "processing", "completed", "privacy", "help", "settings",
            "task", "expressionFormula", "originalPhoto",
            "writingDescription"
        ] {
            #expect(source.contains("case \(semantic)"))
        }
    }

    @Test("catalog follows the approved compact icon language")
    func catalogFollowsApprovedCompactIconLanguage() throws {
        let source = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/Views/MemoMarkSymbol.swift"
        )

        for declaration in [
            "case memorySubject = \"person.crop.circle.fill\"",
            "case home = \"house.fill\"",
            "case configurationCenter = \"slider.horizontal.3\"",
            "case memoryContent = \"heart.text.square.fill\"",
            "case photoMetadata = \"doc.badge.gearshape\"",
            "case location = \"location.fill\"",
            "case localStorage = \"books.vertical.fill\"",
            "case processing = \"gearshape.2.fill\"",
            "case completed = \"checkmark.circle.fill\"",
            "case privacy = \"hand.raised.fill\"",
            "case help = \"questionmark.circle.fill\"",
            "case settings = \"gearshape.fill\"",
            "case task = \"checklist\"",
            "case expressionFormula = \"function\"",
            "case originalPhoto = \"photo.stack.fill\"",
            "case writingDescription = \"text.document.fill\"",
            "case feedback = \"bubble.left.and.bubble.right.fill\"",
            "case retention = \"archivebox.fill\"",
            "case workflow = \"point.3.connected.trianglepath.dotted\"",
            "case information = \"info.circle.fill\"",
            "case capability = \"shield.lefthalf.filled\"",
            "case welcome = \"sparkles\"",
            "case borderStyle = \"paintpalette.fill\""
        ] {
            #expect(source.contains(declaration))
        }
    }

    @Test("compact card headings accept a semantic leading icon")
    func compactCardHeadingsAcceptASemanticLeadingIcon() throws {
        let source = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/Views/V1IOSViewSupportComponents.swift"
        )

        #expect(source.contains("let systemImage: String?"))
        #expect(source.contains("V1CompactInformationRowMetrics.iconSize"))
        #expect(source.contains("V1CompactInformationRowMetrics.iconCornerRadius"))
    }

    @Test("approved headings and entries keep their semantic icons")
    func approvedHeadingsAndEntriesKeepTheirSemanticIcons() throws {
        let expectations = [
            ("iOS/Views/V1HomePageSurface.swift", "我的配置", "MemoMarkSymbol.configuration.name"),
            ("iOS/Views/V1HomePageSurface.swift", "记忆对象", "MemoMarkSymbol.memorySubject.name"),
            ("iOS/Views/V1HomePageSurface.swift", "为什么开发时光记", "MemoMarkSymbol.memoryContent.name"),
            ("iOS/Views/V1HomeFeedbackSection.swift", "意见反馈", "MemoMarkSymbol.feedback.name"),
            ("iOS/Views/V1OutputPageSurface.swift", "输出目标", "MemoMarkSymbol.output.name"),
            ("iOS/Views/V1OutputPageSurface.swift", "写入与保留", "MemoMarkSymbol.retention.name"),
            ("iOS/Views/V1OutputPageSurface.swift", "保存选项", "MemoMarkSymbol.retention.name"),
            ("iOS/Views/V1TaskPageSurface.swift", "最近任务", "MemoMarkSymbol.processing.name"),
            ("iOS/Views/V1SettingsPageSurface.swift", "为什么是时光记", "MemoMarkSymbol.memoryContent.name"),
            ("iOS/Views/V1SettingsPageSurface.swift", "使用与帮助", "MemoMarkSymbol.help.name"),
            ("iOS/Views/V1SettingsPageSurface.swift", "版本信息", "MemoMarkSymbol.information.name"),
            ("iOS/Views/V1SettingsPageSurface.swift", "能力与边界", "MemoMarkSymbol.capability.name"),
            ("iOS/Views/V1SettingsPageSurface.swift", "反馈渠道", "MemoMarkSymbol.feedback.name"),
            ("iOS/Views/V1SettingsPageSurface.swift", "隐私与数据", "MemoMarkSymbol.privacy.name"),
            ("iOS/Views/V1WelcomePresentation.swift", "初次打开你会用到", "MemoMarkSymbol.welcome.name"),
            ("iOS/Views/V1WelcomePresentation.swift", "推荐流程", "MemoMarkSymbol.workflow.name"),
            ("iOS/Views/V1WelcomePresentation.swift", "使用流程", "MemoMarkSymbol.workflow.name"),
            ("iOS/Views/V1IOSSubjectConfigurationFlow.swift", "记忆对象配置", "MemoMarkSymbol.memorySubject.name"),
            ("iOS/Views/V1IOSSubjectOverviewSheetSurface.swift", "时间锚点配置", "MemoMarkSymbol.timeAnchor.name")
        ]

        for (path, title, symbol) in expectations {
            let source = try sourceText(
                "Source/PhotoMemo/PhotoMemo/\(path)"
            )
            #expect(source.contains(title))
            #expect(source.contains(symbol))
        }
    }

    @Test("existing configuration rows use the same iconography vocabulary")
    func existingConfigurationRowsUseTheSameIconographyVocabulary() throws {
        let sources = try [
            "Source/PhotoMemo/PhotoMemo/iOS/Views/PhotoMemoiOSV1View.swift",
            "Source/PhotoMemo/PhotoMemo/iOS/Views/V1AccessoryEntrySection.swift",
            "Source/PhotoMemo/PhotoMemo/iOS/Views/V1SubjectHomeSummarySupport.swift",
            "Source/PhotoMemo/PhotoMemo/iOS/Views/ConfigurationCenteriOSView.swift"
        ]
        .map(sourceText)
        .joined(separator: "\n")

        for symbol in [
            "MemoMarkSymbol.memorySubject.name",
            "MemoMarkSymbol.memoryContent.name",
            "MemoMarkSymbol.borderStyle.name",
            "MemoMarkSymbol.timeAnchor.name",
            "MemoMarkSymbol.help.name"
        ] {
            #expect(sources.contains(symbol))
        }
    }

    @Test("non-configuration surfaces use semantic symbols")
    func nonConfigurationSurfacesUseSemanticSymbols() throws {
        let paths = [
            "Source/PhotoMemo/PhotoMemo/iOS/Views/V1HomePageSurface.swift",
            "Source/PhotoMemo/PhotoMemo/iOS/Views/V1OutputPageSurface.swift",
            "Source/PhotoMemo/PhotoMemo/iOS/Views/V1TaskPageSurface.swift",
            "Source/PhotoMemo/PhotoMemo/iOS/Views/V1SettingsPageSurface.swift",
            "Source/PhotoMemo/PhotoMemo/iOS/Views/V1LocalConfigurationLibrarySheet.swift"
        ]
        let combined = try paths.map(sourceText).joined(separator: "\n")

        #expect(combined.contains("MemoMarkSymbol.memorySubject.name"))
        #expect(combined.contains("MemoMarkSymbol.output.name"))
        #expect(combined.contains("MemoMarkSymbol.applePhotos.name"))
        #expect(combined.contains("MemoMarkSymbol.localStorage.name"))
        #expect(combined.contains("MemoMarkSymbol.processing.name"))
        #expect(combined.contains("MemoMarkSymbol.privacy.name"))
    }
}

private extension MemoMarkSymbolCatalogContractTests {

    func sourceText(_ relativePath: String) throws -> String {
        let testsDirectory = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
        let repositoryRoot = testsDirectory
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        return try String(
            contentsOf: repositoryRoot.appendingPathComponent(relativePath),
            encoding: .utf8
        )
    }
}
#endif

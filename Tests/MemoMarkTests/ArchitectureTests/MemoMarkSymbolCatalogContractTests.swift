#if !MEMOMARK_SHARE_EXTENSION
import Foundation
import Testing

@Suite("MemoMark symbol catalog contract")
struct MemoMarkSymbolCatalogContractTests {

    @Test("catalog defines stable product semantics")
    func catalogDefinesStableProductSemantics() throws {
        let source = try sourceText(
            "Source/MemoMark/MemoMark/iOS/Views/MemoMarkSymbol.swift"
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
            "Source/MemoMark/MemoMark/iOS/Views/MemoMarkSymbol.swift"
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
            "Source/MemoMark/MemoMark/iOS/Views/ConfigurationCenterViewSupportComponents.swift"
        )

        #expect(source.contains("let systemImage: String?"))
        #expect(source.contains("CompactInformationRowMetrics.iconSize"))
        #expect(source.contains("CompactInformationRowMetrics.iconCornerRadius"))
    }

    @Test("approved headings and entries keep their semantic icons outside text-only settings disclosures")
    func approvedHeadingsAndEntriesKeepTheirSemanticIcons() throws {
        let expectations = [
            (["iOS/Views/HomePageSurface.swift"], "home.presets.title", "MemoMarkSymbol.configuration.name"),
            (["iOS/Views/HomePageSurface.swift", "iOS/Views/SubjectHomeSummarySupport.swift"], "home.profile.title", "MemoMarkSymbol.memorySubject.name"),
            (["iOS/Views/HomeFeedbackSection.swift"], "home.feedback.title", "MemoMarkSymbol.feedback.name"),
            (["iOS/Views/WelcomePresentation.swift"], "welcome.introduction.title", "MemoMarkSymbol.welcome.name"),
            (["iOS/Views/WelcomePresentation.swift"], "welcome.workflow.title", "MemoMarkSymbol.workflow.name")
        ]

        let simplifiedChinese = try sourceText(
            "Source/MemoMark/MemoMark/zh-Hans.lproj/Localizable.strings"
        )

        for (paths, titleKey, symbol) in expectations {
            let source = try paths.map {
                try sourceText("Source/MemoMark/MemoMark/\($0)")
            }
            .joined(separator: "\n")
            // The stable contract is the localization key at the semantic
            // heading site, not an incidental fallback literal or an
            // unrelated call to a generic localized helper.
            #expect(source.contains(titleKey))
            #expect(simplifiedChinese.contains("\"\(titleKey)\""))
            #expect(source.contains(symbol))
        }

        let settingsSource = try sourceText(
            "Source/MemoMark/MemoMark/iOS/Views/SettingsPageSurface.swift"
        )
        #expect(!settingsSource.contains("CompactHeadingIcon"))
        #expect(settingsSource.contains("settings.getting_started.title"))
        #expect(settingsSource.contains("settings.expression_guide.title"))
        #expect(settingsSource.contains("settings.feedback.section_title"))
    }

    @Test("existing configuration rows use the same iconography vocabulary")
    func existingConfigurationRowsUseTheSameIconographyVocabulary() throws {
        let sources = try [
            "Source/MemoMark/MemoMark/iOS/Views/MemoMarkConfigurationCenterView.swift",
            "Source/MemoMark/MemoMark/iOS/Views/ConfigurationOptionList.swift",
            "Source/MemoMark/MemoMark/iOS/Views/AccessoryEntrySection.swift",
            "Source/MemoMark/MemoMark/iOS/Views/SubjectHomeSummarySupport.swift",
            "Source/MemoMark/MemoMark/iOS/Views/ConfigurationCenterDetailPresenter.swift"
        ]
        .map(sourceText)
        .joined(separator: "\n")

        for symbol in [
            "MemoMarkSymbol.memorySubject.name",
            "MemoMarkSymbol.memoryContent.name",
            "MemoMarkSymbol.timeAnchor.name",
            "MemoMarkSymbol.help.name"
        ] {
            #expect(sources.contains(symbol))
        }
    }

    @Test("non-configuration surfaces preserve approved semantic symbols")
    func nonConfigurationSurfacesPreserveApprovedSemanticSymbols() throws {
        let paths = [
            "Source/MemoMark/MemoMark/iOS/Views/HomePageSurface.swift",
            "Source/MemoMark/MemoMark/iOS/Views/HomeMemoryPresetRow.swift",
            "Source/MemoMark/MemoMark/iOS/Views/V1OutputPageSurface.swift",
            "Source/MemoMark/MemoMark/iOS/Views/TaskPageSurface.swift",
            "Source/MemoMark/MemoMark/iOS/Views/SettingsPageSurface.swift",
            "Source/MemoMark/MemoMark/iOS/Views/LocalConfigurationLibrarySheet.swift"
        ]
        let combined = try paths.map(sourceText).joined(separator: "\n")

        #expect(combined.contains("MemoMarkSymbol.memorySubject.name"))
        #expect(combined.contains("MemoMarkSymbol.output.name"))
        #expect(combined.contains("MemoMarkSymbol.applePhotos.name"))
        #expect(combined.contains("MemoMarkSymbol.localStorage.name"))
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

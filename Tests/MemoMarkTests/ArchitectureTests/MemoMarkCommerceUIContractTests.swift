import Foundation
import Testing

@Suite("MemoMark commerce UI contract")
struct MemoMarkCommerceUIContractTests {

    @Test("purchase page uses localized value and trust language")
    func purchasePageCopyMatchesDesign() throws {
        let source = try sourceText(
            "Source/MemoMark/MemoMark/iOS/Views/MemoMarkPlusPurchaseView.swift"
        )
        let simplifiedChinese = try sourceText(
            "Source/MemoMark/MemoMark/zh-Hans.lproj/Localizable.strings"
        )
        let english = try sourceText(
            "Source/MemoMark/MemoMark/en.lproj/Localizable.strings"
        )
        let japanese = try sourceText(
            "Source/MemoMark/MemoMark/ja.lproj/Localizable.strings"
        )
        let korean = try sourceText(
            "Source/MemoMark/MemoMark/ko.lproj/Localizable.strings"
        )

        for key in [
            "commerce.purchase.benefit.unlimited_records",
            "commerce.purchase.benefit.batch_40",
            "commerce.purchase.benefit.family_sharing",
            "commerce.purchase.benefit.expressions",
            "commerce.purchase.apple_code",
            "commerce.purchase.restore",
            "commerce.purchase.trust.local_processing",
            "commerce.purchase.trust.future_presets",
            "commerce.purchase.testflight.sandbox_notice",
            "commerce.purchase.testflight.deactivate",
            "commerce.purchase.retry",
            "commerce.purchase.price_note.subscription",
            "commerce.purchase.primary_format.subscription",
            "commerce.purchase.hero.subscription"
        ] {
            #expect(source.contains(key))
            #expect(simplifiedChinese.contains("\"\(key)\""))
            #expect(english.contains("\"\(key)\""))
            #expect(japanese.contains("\"\(key)\""))
            #expect(korean.contains("\"\(key)\""))
        }

        #expect(
            source.contains(
                "fallback: \"一次解锁全部内置的记忆表达方式\""
            )
        )
        #expect(
            simplifiedChinese.contains(
                "一次解锁全部内置的记忆表达方式"
            )
        )
        #expect(
            english.contains(
                "Unlock every built-in way to express memories"
            )
        )
        #expect(
            japanese.contains(
                "内蔵されたすべてのメモリー表現を利用可能に"
            )
        )
        #expect(
            korean.contains(
                "모든 기본 메모리 표현 방식을 이용"
            )
        )
        #expect(!source.contains("全部第一方表达方式一次开放"))

        #expect(!source.contains("VIP"))
        #expect(!source.contains("crown"))
        #expect(source.contains("hasFounderLifetimeEntitlement"))
        #expect(source.contains("hasActiveSubscription"))
        #expect(
            !source.contains(
                "commerce.purchase.testflight.activate"
            )
        )
        #expect(
            !source.contains(
                "commerce.purchase.testflight.purchase"
            )
        )
    }

    @Test("purchase remains actionable when the product must be reloaded")
    func missingProductKeepsPurchaseActionAvailable() throws {
        let source = try sourceText(
            "Source/MemoMark/MemoMark/iOS/Views/MemoMarkPlusPurchaseView.swift"
        )

        #expect(!source.contains("store.product == nil"))
        #expect(source.contains("await store.purchasePlus()"))
    }

    @Test("App Review Sandbox uses the real StoreKit purchase action")
    func sandboxDoesNotOfferLocalPlusActivation() throws {
        let source = try sourceText(
            "Source/MemoMark/MemoMark/iOS/Views/MemoMarkPlusPurchaseView.swift"
        )

        #expect(
            !source.contains(
                "store.canActivateTestFlightExperience"
            )
        )
        #expect(
            !source.contains(
                "store.activateTestFlightExperience()"
            )
        )
        #expect(!source.contains("sandboxPurchaseButton"))
    }

    @Test("iOS Settings presents MemoMark+ before the Settings sheet closes")
    func iOSSettingsPresentsLiveMemoMarkPlusPurchase() throws {
        let rootSource = try sourceText(
            "Source/MemoMark/MemoMark/iOS/Views/MemoMarkConfigurationCenterView.swift"
        )
        let settingsPageSource = try sourceText(
            "Source/MemoMark/MemoMark/iOS/Views/MemoMarkConfigurationCenterView+Pages.swift"
        )

        #expect(!rootSource.contains("commerceSnapshot: .initial"))
        #expect(!rootSource.contains("onOpenMemoMarkPlus: {}"))
        #expect(rootSource.contains("settingsContent: settingsPage"))
        #expect(
            settingsPageSource.contains(
                ".sheet("
            )
        )
        #expect(
            settingsPageSource.contains(
                "isPresented:"
            )
        )
        #expect(
            settingsPageSource.contains(
                "$rootPresentationState.showsMemoMarkPlus"
            )
        )
        #expect(
            settingsPageSource.contains(
                "MemoMarkPlusPurchaseView("
            )
        )
        #expect(
            settingsPageSource.contains("store: commerceStore")
        )
        #expect(
            !rootSource.contains(
                ".sheet(isPresented: $rootPresentationState.showsMemoMarkPlus)"
            )
        )
    }

    @Test("StoreKit service uses one verified product path")
    func storeKitServiceUsesVerifiedTransactions() throws {
        let source = try sourceText(
            "Source/MemoMark/MemoMark/Services/MemoMarkCommerceStore.swift"
        )

        #expect(source.contains("memomarkplus.subscription.annual"))
        #expect(source.contains("memomarkplus.lifetime"))
        #expect(source.contains("Transaction.updates"))
        #expect(source.contains("Transaction.currentEntitlements"))
        #expect(source.contains("case .verified"))
        #expect(source.contains("AppTransaction.shared"))
        #expect(source.contains("presentOfferCodeRedeemSheet"))
        #expect(source.contains("isTestFlightExperienceActive"))
        #expect(source.contains("amount: 100"))
        #expect(!source.contains("func activateTestFlightExperience"))
    }

    @Test("verified MemoMark+ identity appears in current Home chrome")
    func verifiedMemoMarkPlusIdentityAppearsInCurrentHomeChrome() throws {
        let badgeSource = try sourceText(
            "Source/MemoMark/MemoMark/iOS/Views/MemoMarkPlusBadge.swift"
        )
        let homeSource = try sourceText(
            "Source/MemoMark/MemoMark/iOS/Views/HomePageSurface.swift"
        )
        let pagesSource = try sourceText(
            "Source/MemoMark/MemoMark/iOS/Views/MemoMarkConfigurationCenterView+Pages.swift"
        )

        #expect(badgeSource.contains("MemoMark+"))
        #expect(badgeSource.contains("sparkles"))
        #expect(
            badgeSource.contains(
                "commerce.badge.accessibility.first_recorder_label"
            )
        )
        #expect(homeSource.contains("MemoMarkPlusBadge"))
        #expect(homeSource.contains("showsMemoMarkPlusBadge"))
        #expect(homeSource.contains("isFirstRecorder"))
        #expect(pagesSource.contains("showsHomeMemoMarkPlus"))
        #expect(
            pagesSource.contains(
                "commerceStore.hasVerifiedPlusEntitlement"
            )
        )
        #expect(
            pagesSource.contains(
                "commerceStore.hasFirstRecorderIdentity"
            )
        )
    }

    @Test("Home keeps the photo picker discoverable and guides first use")
    func homePhotoPickerGuidanceIsTimeBound() throws {
        let homeSource = try sourceText(
            "Source/MemoMark/MemoMark/iOS/Views/HomePageSurface.swift"
        )
        let pagesSource = try sourceText(
            "Source/MemoMark/MemoMark/iOS/Views/MemoMarkConfigurationCenterView+Pages.swift"
        )

        #expect(homeSource.contains("memomark.home.photoPickerUseCount"))
        #expect(homeSource.contains("photoPickerGuidanceStartedAt"))
        #expect(homeSource.contains("onOpenSettingsWorkflowGuide"))
        #expect(homeSource.contains("HomePhotoPickerGuidancePolicy"))
        #expect(homeSource.contains("private var shouldShowInAppPhotoPicker"))
        #expect(homeSource.contains("        true"))
        #expect(pagesSource.contains("showsSettingsWorkflowGuide"))
    }

    @Test("Home photo guidance uses a ten-use and one-day window")
    func homePhotoPickerGuidancePolicyUsesTenUseWindow() throws {
        let policySource = try sourceText(
            "Source/MemoMark/MemoMark/Models/MemoMarkCommerceModels.swift"
        )

        #expect(policySource.contains("static let useThreshold = 10"))
        #expect(
            policySource.contains(
                "static let guidanceDuration: TimeInterval = 24 * 60 * 60"
            )
        )
        #expect(policySource.contains("elapsed < guidanceDuration"))
    }

    @Test("Settings Hero makes the current membership state visible")
    func settingsHeroShowsCurrentMembershipState() throws {
        let source = try sourceText(
            "Source/MemoMark/MemoMark/iOS/Views/SettingsPageSurface.swift"
        )

        #expect(source.contains("private var memoMarkPlusStatus"))
        #expect(source.contains("commerceSnapshot.remainingRecords"))
        #expect(source.contains("commerce.settings.remaining_status"))
        #expect(source.contains("commerce.settings.upgrade_detail"))
        #expect(!source.contains("已创建 \\(commerceSnapshot.successfulRecordCount) /"))
        #expect(source.contains("commerce.settings.first_recorder_status"))
        #expect(!source.contains("remaining <= 10"))
        #expect(source.contains("accessSource"))
    }

    @Test("remaining records localization accepts the Int64 formatter")
    func remainingRecordsLocalizationUsesInt64Specifier() throws {
        for languageCode in ["en", "zh-Hans", "ja", "ko"] {
            let resource = try sourceText(
                "Source/MemoMark/MemoMark/\(languageCode).lproj/Localizable.strings"
            )
            let line = try #require(
                resource
                    .split(separator: "\n")
                    .first {
                        $0.contains("\"commerce.settings.remaining_status\"")
                    }
            )

            #expect(line.contains("%lld"))
            #expect(!line.contains("%@"))
        }
    }

    @Test("Settings separates First Recorder identity from current Access")
    func settingsFirstRecorderProjectionIsAccessFirst() throws {
        let source = try sourceText(
            "Source/MemoMark/MemoMark/iOS/Views/SettingsPageSurface.swift"
        )
        let settingsCardSource = try sourceText(
            "Source/MemoMark/MemoMark/iOS/Views/MemoMarkPlusSettingsCard.swift"
        )
        let simplifiedChinese = try sourceText(
            "Source/MemoMark/MemoMark/zh-Hans.lproj/Localizable.strings"
        )
        let english = try sourceText(
            "Source/MemoMark/MemoMark/en.lproj/Localizable.strings"
        )

        let statusStart = try #require(
            source.range(
                of: "    private var memoMarkPlusStatus: String {"
            )
        )
        let detailStart = try #require(
            source.range(
                of: "    private var memoMarkPlusStatusDetail: String {"
            )
        )
        let statusSource = String(
            source[
                statusStart.lowerBound
                ..< detailStart.lowerBound
            ]
        )
        let plusAccessPosition = try #require(
            statusSource.range(
                of: "if commerceSnapshot.isPlus"
            )?.lowerBound
        )
        let historicalIdentityPosition = try #require(
            statusSource.range(
                of: "commerce.settings.first_recorder_commemoration_status_format"
            )?.lowerBound
        )
        let hintStart = try #require(
            source.range(
                of: "    private var memoMarkPlusAccessibilityHint: String {"
            )
        )
        let testFlightAccessStart = try #require(
            source.range(
                of: "    private var isTestFlightExperienceActive: Bool {"
            )
        )
        let hintSource = String(
            source[
                hintStart.lowerBound
                ..< testFlightAccessStart.lowerBound
            ]
        )
        let plusAccessibilityPosition = try #require(
            hintSource.range(
                of: "if commerceSnapshot.isPlus"
            )?.lowerBound
        )
        let historicalAccessibilityPosition = try #require(
            hintSource.range(
                of: "commerce.settings.accessibility.first_recorder_commemoration"
            )?.lowerBound
        )

        #expect(plusAccessPosition < historicalIdentityPosition)
        #expect(
            plusAccessibilityPosition
            < historicalAccessibilityPosition
        )
        #expect(
            source.contains(
                "commerce.settings.accessibility.first_recorder_commemoration"
            )
        )
        #expect(source.contains("firstRecorderDate.formatted("))
        #expect(source.contains(".locale(interfaceLanguage.locale)"))
        #expect(settingsCardSource.contains(".accessibilityLabel(\"MemoMark+\")"))
        #expect(settingsCardSource.contains(".accessibilityValue("))

        for resource in [simplifiedChinese, english] {
            #expect(
                resource.contains(
                    "\"commerce.settings.first_recorder_commemoration_status_format\""
                )
            )
            #expect(
                resource.contains(
                    "\"commerce.settings.accessibility.first_recorder_commemoration\""
                )
            )
        }

        #expect(
            simplifiedChinese.contains(
                "\"commerce.settings.first_recorder_commemoration_status_format\" = \"首批记录纪念 · %@\";"
            )
        )
        #expect(
            english.contains(
                "\"commerce.settings.first_recorder_commemoration_status_format\" = \"First Recorder Keepsake · %@\";"
            )
        )
    }

    @Test("interface preferences appear immediately before version information")
    func interfacePreferencesPrecedeVersionInformation() throws {
        let source = try sourceText(
            "Source/MemoMark/MemoMark/iOS/Views/SettingsPageSurface.swift"
        )
        let interfacePosition = try #require(
            source.range(of: "interfacePreferencesSection")?.lowerBound
        )
        let aboutPosition = try #require(
            source.range(of: "aboutSection")?.lowerBound
        )

        #expect(interfacePosition < aboutPosition)
    }

    @Test("English and Simplified Chinese resources expose the same keys")
    func localizedResourceKeysStaySymmetric() throws {
        let simplifiedChinese = try sourceText(
            "Source/MemoMark/MemoMark/zh-Hans.lproj/Localizable.strings"
        )
        let english = try sourceText(
            "Source/MemoMark/MemoMark/en.lproj/Localizable.strings"
        )

        #expect(
            localizationKeys(in: simplifiedChinese)
            == localizationKeys(in: english)
        )
    }

    @Test("subject commerce stays on the active editing surface")
    func subjectCommercePresentationOwnershipStaysLocal() throws {
        let modifierSource = try sourceText(
            "Source/MemoMark/MemoMark/iOS/Views/SubjectPresentationModifier.swift"
        )
        let overviewSource = try sourceText(
            "Source/MemoMark/MemoMark/iOS/Views/SubjectOverviewSheetSurface.swift"
        )
        let configurationSource = try sourceText(
            "Source/MemoMark/MemoMark/iOS/Views/SubjectConfigurationFlow.swift"
        )
        let anchorSource = try sourceText(
            "Source/MemoMark/MemoMark/iOS/Views/SubjectAnchorDetailSection.swift"
        )

        #expect(!modifierSource.contains("showsCommercePurchase"))
        #expect(overviewSource.contains("@State\n    private var showsCommercePurchase"))
        #expect(configurationSource.contains("@State\n    private var showsCommercePurchase"))
        #expect(anchorSource.contains("onActivateSuggestion"))
        #expect(anchorSource.contains("time_anchor.suggestions.add"))
        #expect(anchorSource.contains("time_anchor.suggestions.customize"))
    }

    @Test("preview suggestions remain visible until explicitly materialized")
    func previewSuggestionMaterializationIsExplicit() throws {
        let source = try sourceText(
            "Source/MemoMark/MemoMark/iOS/Views/SubjectAnchorDetailSection.swift"
        )

        #expect(source.contains("if !suggestedTimeAnchors(for: subject).isEmpty"))
        #expect(source.contains("onActivateSuggestion(suggestion)"))
        #expect(source.contains("onRequestCommerce()"))
        #expect(source.contains("private func suggestedTimeAnchors("))
        #expect(source.contains("for subject: MemorySubject"))
    }

    @Test("production bootstrap never imports the mock 小宝 seed")
    func productionBootstrapUsesTheRealFirstRunFactory() throws {
        let repositorySource = try sourceText(
            "Source/MemoMark/MemoMark/Repositories/SettingsRepository.swift"
        )

        #expect(!repositorySource.contains("ConfigurationCenterMockSeed"))
        #expect(!repositorySource.contains("ConfigurationCenterState.mock"))
        #expect(repositorySource.contains("SubjectLibraryFactory"))
        #expect(repositorySource.contains("makeDefaultSubject"))
    }

    @Test("expression styles are previewable and gated at save")
    func expressionStyleSaveGateStaysOnTheConfigurationSurface() throws {
        let optionSource = try sourceText(
            "Source/MemoMark/MemoMark/iOS/Views/ConfigurationOptionList.swift"
        )
        let pagesSource = try sourceText(
            "Source/MemoMark/MemoMark/iOS/Views/MemoMarkConfigurationCenterView+Pages.swift"
        )
        let actionsSource = try sourceText(
            "Source/MemoMark/MemoMark/iOS/Views/MemoMarkConfigurationCenterView+Actions.swift"
        )
        let resource = try sourceText(
            "Source/MemoMark/MemoMark/zh-Hans.lproj/Localizable.strings"
        )

        #expect(optionSource.contains("pendingMemoryDisplayStyle"))
        #expect(optionSource.contains("commerce.expression.preview_note"))
        #expect(!optionSource.contains("showsCommercePurchase = true"))
        #expect(pagesSource.contains("pendingMemoryDisplayStyleBinding"))
        #expect(actionsSource.contains("requestCommerceForPendingExpressionStyle"))
        #expect(resource.contains("\"commerce.expression.preview_note\""))
    }

    @Test("purchase plans are compact and hidden after entitlement")
    func purchasePagePrioritizesPlansAndEntitlementState() throws {
        let source = try sourceText(
            "Source/MemoMark/MemoMark/iOS/Views/MemoMarkPlusPurchaseView.swift"
        )

        let planPosition = try #require(source.range(of: "planSection")?.lowerBound)
        let benefitPosition = try #require(source.range(of: "benefitSection")?.lowerBound)
        #expect(planPosition < benefitPosition)
        #expect(source.contains("if !store.isPlus"))
        #expect(source.contains("frame(width: 56, height: 56)"))
        #expect(source.contains("commerce.purchase.entitled"))
    }

    private func sourceText(
        _ relativePath: String
    ) throws -> String {
        try String(
            contentsOf:
                repositoryRoot
                .appendingPathComponent(
                    relativePath
                ),
            encoding: .utf8
        )
    }

    private func localizationKeys(
        in source: String
    ) -> Set<String> {
        Set(
            source.split(separator: "\n")
                .compactMap { line in
                    guard line.first == "\"",
                          let closingQuote =
                            line.dropFirst()
                            .firstIndex(of: "\"") else {
                        return nil
                    }
                    let keyStart =
                        line.index(
                            after: line.startIndex
                        )
                    return String(
                        line[keyStart..<closingQuote]
                    )
                }
        )
    }

    private var repositoryRoot: URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
    }
}

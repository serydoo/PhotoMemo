import Foundation
import Testing

@Suite("MemoMark commerce UI contract")
struct MemoMarkCommerceUIContractTests {

    @Test("purchase page uses localized value and trust language")
    func purchasePageCopyMatchesDesign() throws {
        let source = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/Views/MemoMarkPlusPurchaseView.swift"
        )
        let simplifiedChinese = try sourceText(
            "Source/PhotoMemo/PhotoMemo/zh-Hans.lproj/Localizable.strings"
        )
        let english = try sourceText(
            "Source/PhotoMemo/PhotoMemo/en.lproj/Localizable.strings"
        )

        for key in [
            "commerce.purchase.benefit.unlimited_records",
            "commerce.purchase.benefit.batch_40",
            "commerce.purchase.benefit.family_sharing",
            "commerce.purchase.apple_code",
            "commerce.purchase.restore",
            "commerce.purchase.trust.local_processing",
            "commerce.purchase.trust.future_presets",
            "commerce.purchase.testflight.sandbox_notice",
            "commerce.purchase.testflight.deactivate",
            "commerce.purchase.retry",
            "commerce.purchase.price_note.launch",
            "commerce.purchase.price_note.standard",
            "commerce.purchase.primary_format.launch",
            "commerce.purchase.primary_format.standard"
        ] {
            #expect(source.contains(key))
            #expect(simplifiedChinese.contains("\"\(key)\""))
            #expect(english.contains("\"\(key)\""))
        }

        #expect(!source.contains("VIP"))
        #expect(!source.contains("crown"))
        #expect(source.contains("isFirstRecorderCampaignOpen"))
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
            "Source/PhotoMemo/PhotoMemo/iOS/Views/MemoMarkPlusPurchaseView.swift"
        )

        #expect(!source.contains("store.product == nil"))
        #expect(source.contains("await store.purchasePlus()"))
    }

    @Test("App Review Sandbox uses the real StoreKit purchase action")
    func sandboxDoesNotOfferLocalPlusActivation() throws {
        let source = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/Views/MemoMarkPlusPurchaseView.swift"
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
        let source = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/Views/PhotoMemoiOSV1View.swift"
        )

        let bodyStart = try #require(
            source.range(
                of: "    var body: some View {"
            )
        )
        let rootNavigationStart = try #require(
            source.range(
                of: "    @ViewBuilder\n    private var rootNavigation"
            )
        )
        let settingsPageStart = try #require(
            source.range(
                of: "    private var settingsPage: some View {"
            )
        )
        let entryPresentationStart = try #require(
            source.range(
                of: "    private var entryPresentation:"
            )
        )
        let rootBodySource = String(
            source[
                bodyStart.lowerBound
                ..< rootNavigationStart.lowerBound
            ]
        )
        let settingsPageSource = String(
            source[
                settingsPageStart.lowerBound
                ..< entryPresentationStart.lowerBound
            ]
        )

        #expect(!source.contains("commerceSnapshot: .initial"))
        #expect(!source.contains("onOpenMemoMarkPlus: {}"))
        #expect(source.contains("showsMemoMarkPlus"))
        #expect(
            settingsPageSource.contains(
                ".sheet(isPresented: $showsMemoMarkPlus)"
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
            !rootBodySource.contains(
                ".sheet(isPresented: $showsMemoMarkPlus)"
            )
        )
    }

    @Test("StoreKit service uses one verified product path")
    func storeKitServiceUsesVerifiedTransactions() throws {
        let source = try sourceText(
            "Source/PhotoMemo/PhotoMemo/Services/MemoMarkCommerceStore.swift"
        )

        #expect(
            source.contains(
                "com.serydoo.PhotoMemo.iOS.memomarkplus.lifetime"
            )
        )
        #expect(source.contains("Transaction.updates"))
        #expect(source.contains("Transaction.currentEntitlements"))
        #expect(source.contains("case .verified"))
        #expect(source.contains("AppTransaction.shared"))
        #expect(source.contains("presentOfferCodeRedeemSheet"))
        #expect(source.contains("isTestFlightExperienceActive"))
        #expect(source.contains("amount: 100"))
        #expect(!source.contains("func activateTestFlightExperience"))
    }

    @Test("warm-gold badge remains app chrome")
    func warmGoldBadgeLivesOutsideRenderer() throws {
        let badgeSource = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/Views/MemoMarkPlusBadge.swift"
        )
        let headerSource = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/Views/ConfigurationCenterTopPreviewSection.swift"
        )

        #expect(badgeSource.contains("MemoMark+"))
        #expect(badgeSource.contains("sparkles"))
        #expect(headerSource.contains("MemoMarkPlusBadge"))
    }

    @Test("Settings Hero makes the current membership state visible")
    func settingsHeroShowsCurrentMembershipState() throws {
        let source = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/Views/V1SettingsPageSurface.swift"
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

    @Test("interface language appears immediately before version information")
    func interfaceLanguagePrecedesVersionInformation() throws {
        let source = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/Views/V1SettingsPageSurface.swift"
        )
        let languagePosition = try #require(
            source.range(of: "interfaceLanguageSection")?.lowerBound
        )
        let aboutPosition = try #require(
            source.range(of: "aboutSection")?.lowerBound
        )

        #expect(languagePosition < aboutPosition)
    }

    @Test("English and Simplified Chinese resources expose the same keys")
    func localizedResourceKeysStaySymmetric() throws {
        let simplifiedChinese = try sourceText(
            "Source/PhotoMemo/PhotoMemo/zh-Hans.lproj/Localizable.strings"
        )
        let english = try sourceText(
            "Source/PhotoMemo/PhotoMemo/en.lproj/Localizable.strings"
        )

        #expect(
            localizationKeys(in: simplifiedChinese)
            == localizationKeys(in: english)
        )
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

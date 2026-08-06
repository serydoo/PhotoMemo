import Foundation
import Testing
@testable import PhotoMemo

@Suite("Memory anchor text formatting")
struct MemoryAnchorTextFormatterTests {

    @Test("Formats the same relative result in Chinese and English")
    func formatsRelativeResultByLanguage() {
        let snapshot = MemoryAnchorRelativeSnapshot(
            years: 3,
            months: 2,
            days: 1,
            totalDays: 1157,
            isFutureRelative: false
        )

        #expect(snapshot.ageText == "3岁2个月1天")
        #expect(
            snapshot.ageText(language: .english)
                == "3 years, 2 months, and 1 day"
        )
        #expect(
            snapshot.durationText(language: .english)
                == "3 years, 2 months, and 1 day"
        )
        #expect(
            snapshot.countdownText(language: .english)
                == "1157 days left"
        )
        #expect(
            snapshot.countdownValueText(language: .english)
                == "1157 days"
        )
    }

    @Test("Uses natural English phrasing for generated memory sentences")
    func usesNaturalEnglishPhrasing() {
        let elapsed = MemoryAnchorRelativeSnapshot(
            years: 2,
            months: 0,
            days: 3,
            totalDays: 733,
            isFutureRelative: false
        )

        #expect(
            MemoryAnchorExpressionResolver.renderedText(
                subjectText: "Mia",
                anchorTitle: "Birthday",
                anchorType: .birthday,
                expressionStyle: .birthdayNatural,
                relativeSnapshot: elapsed,
                language: .english
            ) == "Mia is 2 years and 3 days old today"
        )

        let future = MemoryAnchorRelativeSnapshot(
            years: 0,
            months: 0,
            days: 0,
            totalDays: 10,
            isFutureRelative: true
        )

        #expect(
            MemoryAnchorExpressionResolver.renderedText(
                subjectText: "Mia",
                anchorTitle: "Birthday",
                anchorType: .birthday,
                expressionStyle: .birthdayNatural,
                relativeSnapshot: future,
                language: .english
            ) == "10 days until Mia arrives"
        )

        #expect(
            MemoryAnchorExpressionResolver.renderedText(
                subjectText: "us",
                anchorTitle: "Our first trip",
                anchorType: .relationship,
                expressionStyle: .relationshipMemory,
                relativeSnapshot: elapsed,
                language: .english
            ) == "2 years and 3 days since Our first trip"
        )
    }

    @Test("Treats the birthday calendar day as a distinct memory expression")
    func treatsBirthdayCalendarDayAsDistinctMemoryExpression() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try #require(
            TimeZone(secondsFromGMT: 8 * 60 * 60)
        )
        let birthday = try #require(
            calendar.date(
                from: DateComponents(
                    year: 2026,
                    month: 6,
                    day: 1,
                    hour: 0,
                    minute: 5
                )
            )
        )
        let captureDate = try #require(
            calendar.date(
                from: DateComponents(
                    year: 2026,
                    month: 6,
                    day: 1,
                    hour: 23,
                    minute: 30
                )
            )
        )
        let snapshot = MemoryAnchorRelativeSnapshot.resolve(
            anchorDate: birthday,
            captureDate: captureDate,
            calendar: calendar,
            comparesByCalendarDay: true
        )

        #expect(!snapshot.isFutureRelative)
        #expect(snapshot.totalDays == 0)
        #expect(
            MemoryAnchorVariableTextFormatter.babyAgeText(
                from: MemoryElapsedTime(relativeSnapshot: snapshot),
                language: .simplifiedChinese
            ) == "出生当天"
        )

        for style in MemoryAnchorExpressionStyle.availableStyles(
            for: .birthday
        ) {
            #expect(
                MemoryAnchorExpressionResolver.renderedText(
                    subjectText: "宝宝",
                    anchorTitle: "出生",
                    anchorType: .birthday,
                    expressionStyle: style,
                    relativeSnapshot: snapshot
                ) == "宝宝今天来到这个世界啦！"
            )
        }

        #expect(
            MemoryAnchorExpressionResolver.renderedText(
                subjectText: "Mia",
                anchorTitle: "Birthday",
                anchorType: .birthday,
                expressionStyle: .birthdayNatural,
                relativeSnapshot: snapshot,
                language: .english
            ) == "Mia arrived in the world today"
        )
    }

    @Test("Keeps the legacy anchor path aligned with the birthday-day expression")
    func keepsLegacyAnchorPathAlignedWithBirthdayDayExpression() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try #require(
            TimeZone(secondsFromGMT: 8 * 60 * 60)
        )
        let birthday = try #require(
            calendar.date(
                from: DateComponents(
                    year: 2026,
                    month: 6,
                    day: 1,
                    hour: 0,
                    minute: 5
                )
            )
        )
        let captureDate = try #require(
            calendar.date(
                from: DateComponents(
                    year: 2026,
                    month: 6,
                    day: 1,
                    hour: 23,
                    minute: 30
                )
            )
        )
        let result = AnchorEngine().build(
            from: Anchor(
                type: .birthday,
                title: "宝宝",
                date: birthday,
                expressionStyle: .birthdayNatural
            ),
            photoDate: captureDate
        )

        #expect(result.ageText == "出生当天")
        #expect(result.secondaryText == "出生当天")
        #expect(result.elapsedText == "出生当天")
        #expect(result.summaryText == "宝宝今天来到这个世界啦！")
        #expect(!result.summaryText.contains("0天"))
    }

    @Test("Treats every anchor on the same calendar day as the anchor day")
    func treatsEveryAnchorOnSameCalendarDayAsAnchorDay() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try #require(
            TimeZone(secondsFromGMT: 8 * 60 * 60)
        )
        let anchorDate = try #require(
            calendar.date(
                from: DateComponents(
                    year: 2026,
                    month: 6,
                    day: 1,
                    hour: 23,
                    minute: 30
                )
            )
        )
        let captureDate = try #require(
            calendar.date(
                from: DateComponents(
                    year: 2026,
                    month: 6,
                    day: 1,
                    hour: 0,
                    minute: 5
                )
            )
        )

        let snapshot = MemoryAnchorRelativeSnapshot.resolve(
            anchorDate: anchorDate,
            captureDate: captureDate,
            calendar: calendar,
            comparesByCalendarDay: true
        )

        #expect(!snapshot.isFutureRelative)
        #expect(snapshot.totalDays == 0)
    }

    @Test("Defaults legacy batch snapshots to Simplified Chinese")
    func defaultsLegacyBatchSnapshotsToChinese() throws {
        let snapshot = BatchConfigurationSnapshot(
            template: .classicWhite,
            badge: nil,
            anchor: nil,
            shouldWritePhotoDescription: true,
            photoDescriptionOverride: "",
            selectedAlbumIdentifier: ""
        )
        let encoded = try JSONEncoder().encode(snapshot)
        var object = try #require(
            JSONSerialization.jsonObject(with: encoded)
                as? [String: Any]
        )
        object.removeValue(forKey: "language")
        let legacyData = try JSONSerialization.data(
            withJSONObject: object
        )

        let decoded = try JSONDecoder().decode(
            BatchConfigurationSnapshot.self,
            from: legacyData
        )

        #expect(decoded.language == .simplifiedChinese)
    }

    @Test("Resolves only the supported launch languages")
    func resolvesSupportedLaunchLanguages() {
        #expect(
            MemoMarkLanguage.resolved(
                from: Locale(identifier: "zh-Hant-TW")
            ) == .english
        )
        #expect(
            MemoMarkLanguage.resolved(
                from: Locale(identifier: "zh-CN")
            ) == .simplifiedChinese
        )
        #expect(
            MemoMarkLanguage.resolved(
                from: Locale(identifier: "en-GB")
            ) == .english
        )
        #expect(
            MemoMarkLanguage.resolved(
                from: Locale(identifier: "fr-FR")
            ) == .english
        )
    }

    @Test("Uses system preference unless an app override is selected")
    func languagePreferenceResolvesToLaunchLanguage() {
        #expect(
            MemoMarkLanguagePreference.system.resolvedLanguage
                == .simplifiedChinese
                || MemoMarkLanguagePreference.system.resolvedLanguage
                    == .english
        )
        #expect(
            MemoMarkLanguagePreference.simplifiedChinese
                .resolvedLanguage == .simplifiedChinese
        )
        #expect(
            MemoMarkLanguagePreference.english.resolvedLanguage
                == .english
        )
    }

    @Test("App interface language is independent from output language")
    func appInterfaceLanguageUsesIndependentPreference() {
        #expect(
            MemoMarkLanguage.interfacePreferenceStorageKey
                != MemoMarkLanguage.preferenceStorageKey
        )
        #expect(
            MemoMarkInterfaceLanguagePreference.simplifiedChinese
                .resolvedLanguage == .simplifiedChinese
        )
        #expect(
            MemoMarkInterfaceLanguagePreference.english
                .resolvedLanguage == .english
        )
    }

    @Test("Keeps RTL languages behind layout direction support")
    func defersRTLLanguagesUntilLayoutSupportExists() {
        let arabic = Locale(identifier: "ar-SA")
        let hebrew = Locale(identifier: "he-IL")

        #expect(
            !MemoMarkLanguage.isSupported(
                locale: arabic,
                layoutDirectionSupport: false
            )
        )
        #expect(
            !MemoMarkLanguage.isSupported(
                locale: hebrew,
                layoutDirectionSupport: false
            )
        )
        #expect(
            MemoMarkLanguage.isSupported(
                locale: arabic,
                layoutDirectionSupport: true
            )
        )
    }

    @Test("Binds variable identity to its stable token")
    func variableIdentityUsesStableToken() {
        #expect(
            TemplateVariable.all.allSatisfy {
                $0.id == $0.token
            }
        )
        #expect(
            TemplatePreset.classicWhite.displayName(
                for: .english
            ) == "Classic White"
        )
        #expect(
            Template.classicWhite.name
                == TemplatePreset.classicWhite.rawValue
        )
        #expect(
            Template.classicWhite.displayName(
                for: .english
            ) == "Classic White"
        )
    }

    @Test("Defaults legacy durable configuration language to Chinese")
    func defaultsLegacyConfigurationLanguageToChinese() throws {
        let configuration = MemoryConfigurationRecord(
            id: UUID(),
            title: "Saved",
            revision: 1,
            savedAt: Date(timeIntervalSince1970: 1),
            selectedTimeAnchorID: nil,
            editor: .init(
                template: .classicWhite,
                regionTemplateIDs: [:],
                memoryCopy: .init(
                    usesCustomText: false,
                    customText: ""
                )
            ),
            presentation: .init(
                route: .classicWhite,
                locationConfiguration: nil,
                logo: .init(
                    mode: .appleMini,
                    badge: nil
                )
            ),
            output: .init(
                mediaMode: .originalFormat,
                livePhotoPolicy: .staticImageOnly,
                photosDescriptionPolicy: .init(
                    isEnabled: false,
                    overrideText: ""
                ),
                album: .automatic
            )
        )
        let encoded = try JSONEncoder().encode(configuration)
        var object = try #require(
            JSONSerialization.jsonObject(with: encoded)
                as? [String: Any]
        )
        object.removeValue(forKey: "language")
        let legacyData = try JSONSerialization.data(
            withJSONObject: object
        )

        let decoded = try JSONDecoder().decode(
            MemoryConfigurationRecord.self,
            from: legacyData
        )

        #expect(decoded.language == .simplifiedChinese)

        var english = configuration
        english.language = .english
        let roundTrip = try JSONDecoder().decode(
            MemoryConfigurationRecord.self,
            from: JSONEncoder().encode(english)
        )
        #expect(roundTrip.language == .english)
    }
}

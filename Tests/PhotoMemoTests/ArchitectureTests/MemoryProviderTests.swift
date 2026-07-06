#if !PHOTOMEMO_SHARE_EXTENSION
import Foundation
import Testing
@testable import PhotoMemo

@Suite("PI-3 Memory Provider")
struct MemoryProviderTests {

    @Test("Given memory context When provider compiles memory Then expression context stores memory value")
    func givenMemoryContextWhenProviderCompilesMemoryThenExpressionContextStoresMemoryValue() throws {
        let context =
            memoryExpressionContext()

        let expressionValue =
            try #require(
                MemoryProvider()
                    .expressionValue(
                        for: MemoryProvider.memoryToken,
                        context: context
                    )
            )

        let expressionContext =
            try ExpressionContext(
                values: [
                    expressionValue
                ]
            )

        #expect(
            expressionContext
                .value(
                    for: MemoryProvider.memoryToken
                )?
                .resolvedText
            == "这一天，途途18天"
        )
    }

    @Test("Given memory provider When canonical tokens inspected Then only memory is supported in PI three")
    func givenMemoryProviderWhenCanonicalTokensInspectedThenOnlyMemoryIsSupportedInPIThree() {
        let provider =
            MemoryProvider()

        #expect(
            provider.canonicalTokens
                == [
                    MemoryProvider.memoryToken
                ]
        )
    }

    @Test("Given memory subtoken When provider asked for value Then PI three returns nil")
    func givenMemorySubtokenWhenProviderAskedForValueThenPIThreeReturnsNil() {
        let value =
            MemoryProvider()
            .expressionValue(
                for: ExpressionToken(
                    rawValue: "baby_age"
                ),
                context: memoryExpressionContext()
            )

        #expect(value == nil)
    }

    @Test("Boundary Given memory provider When inspected Then it stores only engine and adapter")
    func boundaryGivenMemoryProviderWhenInspectedThenItStoresOnlyEngineAndAdapter() {
        let provider =
            MemoryProvider()

        let labels =
            Mirror(
                reflecting: provider
            )
            .children
            .compactMap(\.label)

        #expect(
            labels
                == [
                    "engine",
                    "presentationAdapter"
                ]
        )
    }

    @Test("Boundary Given memory provider source When inspected Then it does not cross production or renderer seams")
    func boundaryGivenMemoryProviderSourceWhenInspectedThenItDoesNotCrossProductionOrRendererSeams() throws {
        let source =
            try String(
                contentsOfFile:
                    "/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/MemoryEngine/MemoryProvider.swift",
                encoding: .utf8
            )

        #expect(source.contains("MemoryExpressionEngine"))
        #expect(source.contains("MemoryResultPresentationAdapter"))
        #expect(source.contains("ExpressionValue"))
        #expect(!source.contains("MetadataContext"))
        #expect(!source.contains("CardVariableProvider"))
        #expect(!source.contains("RecordCardBuildService"))
        #expect(!source.contains("RecordCardRenderer"))
        #expect(
            source.range(
                of: "\\bExpressionContext\\b",
                options: .regularExpression
            ) == nil
        )
    }
}

private func memoryExpressionContext() -> MemoryExpressionContext {
    let birthday =
        Calendar.current.date(
            from: DateComponents(
                year: 2025,
                month: 5,
                day: 26
            )
        ) ?? Date()
    let captureDate =
        Calendar.current.date(
            from: DateComponents(
                year: 2025,
                month: 6,
                day: 13
            )
        ) ?? Date()
    let subject =
        MemorySubject(
            identity: .init(
                displayName: "王途途",
                shortName: "途途"
            ),
            relationship: .init(
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
            activeTimeAnchorID: nil,
            expressionSubjectSource: .shortName,
            behavior: MemoryBehavior(
                primaryAnchor: "生日",
                iconStrategy: .autoMatch,
                badgeStrategy: .autoMatch,
                memoryExpression: MemoryExpression(
                    title: "生日记忆",
                    blocks: [
                        .text("生日智能模块")
                    ]
                )
            ),
            decorations: []
        )
    let snapshot =
        ConfigurationSnapshotBuilder
        .build(
            from: subject,
            smartModuleCarrierRegion: .slotD
        )

    return MemoryExpressionContext(
        subject: subject,
        snapshot: snapshot,
        captureDate: captureDate
    )
}
#endif

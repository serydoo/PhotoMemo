import Foundation
import Testing

@Suite("MemoMark commerce UI contract")
struct MemoMarkCommerceUIContractTests {

    @Test("purchase page preserves approved value and trust language")
    func purchasePageCopyMatchesDesign() throws {
        let source = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/Views/MemoMarkPlusPurchaseView.swift"
        )

        for requiredText in [
            "无限创建成长记录",
            "单次最多处理 40 张照片",
            "支持家庭共享",
            "兑换 MemoMark+ 代码",
            "恢复购买",
            "所有照片仍在设备本地处理",
            "部分未来联名 Preset 可能单独提供",
            "TestFlight / Sandbox 测试交易"
        ] {
            #expect(source.contains(requiredText))
        }

        #expect(!source.contains("VIP"))
        #expect(!source.contains("crown"))
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

    @Test("Settings keeps the free allowance quiet until the final ten records")
    func settingsUsesProgressiveAllowanceDisclosure() throws {
        let source = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/Views/V1SettingsPageSurface.swift"
        )

        #expect(source.contains("继续保存那些未来值得回看的瞬间"))
        #expect(source.contains("remaining <= 10"))
        #expect(source.contains("还有 \\(remaining) 张免费成长记录"))
        #expect(!source.contains("已创建 \\(commerceSnapshot.successfulRecordCount) /"))
        #expect(source.contains("愿今天留下的时光，在未来仍然清晰而温暖"))
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

    private var repositoryRoot: URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
    }
}

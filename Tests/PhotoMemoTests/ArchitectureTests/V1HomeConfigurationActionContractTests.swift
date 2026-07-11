import Foundation
import Testing
@testable import PhotoMemo

@Suite("V1 home configuration action contract")
struct V1HomeConfigurationActionContractTests {

    @Test("swipe presentation changes continuously with row reveal")
    func swipePresentationIsContinuous() {
        let hidden = V1HomeConfigurationSwipePresenter.presentation(
            isActionsRevealed: false,
            dragTranslation: 0
        )
        let quarter = V1HomeConfigurationSwipePresenter.presentation(
            isActionsRevealed: false,
            dragTranslation: -37
        )
        let half = V1HomeConfigurationSwipePresenter.presentation(
            isActionsRevealed: false,
            dragTranslation: -74
        )
        let revealed = V1HomeConfigurationSwipePresenter.presentation(
            isActionsRevealed: false,
            dragTranslation: -148
        )

        #expect(hidden.rowOffset == 0)
        #expect(hidden.actionLayerOffset == 0)
        #expect(hidden.actionOpacity == 0)
        #expect(quarter.rowOffset == -37)
        #expect(quarter.actionLayerOffset == 0)
        #expect(quarter.actionOpacity == 0.5)
        #expect(half.rowOffset == -74)
        #expect(half.actionOpacity == 1)
        #expect(half.allowsActionHitTesting)
        #expect(revealed.rowOffset == -148)
        #expect(revealed.actionOpacity == 1)
    }

    @Test("swipe row offset clamps predictably from either settled state")
    func swipeRowOffsetClampsPredictably() {
        let closedOvershoot =
            V1HomeConfigurationSwipePresenter.presentation(
                isActionsRevealed: false,
                dragTranslation: -220
            )
        let closedWrongDirection =
            V1HomeConfigurationSwipePresenter.presentation(
                isActionsRevealed: false,
                dragTranslation: 60
            )
        let revealedOvershoot =
            V1HomeConfigurationSwipePresenter.presentation(
                isActionsRevealed: true,
                dragTranslation: 220
            )
        let revealedWrongDirection =
            V1HomeConfigurationSwipePresenter.presentation(
                isActionsRevealed: true,
                dragTranslation: -60
            )

        #expect(closedOvershoot.rowOffset == -148)
        #expect(closedWrongDirection.rowOffset == 0)
        #expect(revealedOvershoot.rowOffset == 0)
        #expect(revealedWrongDirection.rowOffset == -148)
    }

    @Test("swipe snaps using the projected half-width threshold")
    func swipeSnapUsesProjectedThreshold() {
        #expect(
            !V1HomeConfigurationSwipePresenter.shouldRevealActions(
                isActionsRevealed: false,
                predictedEndTranslation: -73
            )
        )
        #expect(
            V1HomeConfigurationSwipePresenter.shouldRevealActions(
                isActionsRevealed: false,
                predictedEndTranslation: -75
            )
        )
        #expect(
            V1HomeConfigurationSwipePresenter.shouldRevealActions(
                isActionsRevealed: true,
                predictedEndTranslation: 73
            )
        )
        #expect(
            !V1HomeConfigurationSwipePresenter.shouldRevealActions(
                isActionsRevealed: true,
                predictedEndTranslation: 75
            )
        )
    }

    @Test("configuration rows expose blue save and red delete actions")
    func rowSwipeActionsExposeSaveAndDelete() throws {
        let source = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/Views/V1HomePageSurface.swift"
        )

        #expect(source.contains("Text(\"保存\")"))
        #expect(source.contains("background(Color.blue)"))
        #expect(source.contains("Text(\"删除\")"))
        #expect(source.contains("background(Color.red)"))
        #expect(source.contains("accessibilityLabel(\"保存配置到本地库\")"))
        #expect(source.contains("accessibilityLabel(\"删除配置\")"))
    }

    @Test("configuration card footer opens the current subject local library")
    func footerPlusOpensLocalLibrary() throws {
        let source = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/Views/V1HomePageSurface.swift"
        )

        #expect(source.contains("Image(systemName: \"plus\")"))
        #expect(source.contains("accessibilityLabel(\"打开当前记忆对象的本地配置库\")"))
        #expect(source.contains("onOpenLocalConfigurationLibrary"))
    }

    @Test("home surfaces local backup and deletion feedback")
    func homeSurfacesConfigurationActionFeedback() throws {
        let source = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/Views/PhotoMemoiOSV1View.swift"
        )

        #expect(source.contains("showsHomeConfigurationActionFeedback"))
        #expect(source.contains(".alert("))
        #expect(source.contains("presentHomeConfigurationActionFeedback"))
    }
}

private extension V1HomeConfigurationActionContractTests {

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

import Foundation
import Photos
import XCTest

final class MemoMarkDeviceQAHarnessTests: XCTestCase {

    private var application: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false

        application = XCUIApplication()
        application.launchArguments += [
            "-uiTesting",
            "-uiTestingHarnessOnly"
        ]
    }

    func testHarnessLaunchesTheiOSHost() throws {
        launchHostAndWait()

        let screenshot = XCTAttachment(
            screenshot: application.screenshot()
        )
        screenshot.name = "device-qa-harness-launch"
        screenshot.lifetime = .keepAlways
        add(screenshot)
    }

    func testInterfaceLanguageMatrixJapaneseAndKorean() throws {
        launchHostAndWait()
        openSettingsFromHome()

        restoreSimplifiedChineseInterfaceIfNeeded()

        selectInterfaceLanguage(
            option: "日本語",
            sectionTitle: "界面"
        )
        XCTAssertTrue(
            application.navigationBars["設定"].waitForExistence(timeout: 20)
                || application.staticTexts["設定"].waitForExistence(timeout: 5),
            "The Settings surface did not switch to Japanese."
        )
        attachCurrentScreenshot(named: "qa-interface-japanese-settings")

        selectInterfaceLanguage(
            option: "한국어",
            sectionTitle: "インターフェース"
        )
        XCTAssertTrue(
            application.navigationBars["설정"].waitForExistence(timeout: 20)
                || application.staticTexts["설정"].waitForExistence(timeout: 5),
            "The Settings surface did not switch to Korean."
        )
        attachCurrentScreenshot(named: "qa-interface-korean-settings")

        // Restore the known pre-test interface preference without changing
        // any Preset, task, or PhotoKit state.
        selectInterfaceLanguage(
            option: "简体中文",
            sectionTitle: "인터페이스"
        )
        XCTAssertTrue(
            application.navigationBars["设置"].waitForExistence(timeout: 20)
                || application.staticTexts["设置"].waitForExistence(timeout: 5),
            "The Settings surface did not restore Simplified Chinese."
        )
        attachCurrentScreenshot(named: "qa-interface-chinese-restored")
    }

    func testTaskPageJapaneseInterfaceSurface() throws {
        launchHostAndWait()
        openSettingsFromHome()
        restoreSimplifiedChineseInterfaceIfNeeded()

        selectInterfaceLanguage(
            option: "日本語",
            sectionTitle: "界面"
        )
        XCTAssertTrue(
            application.navigationBars["設定"].waitForExistence(timeout: 20)
                || application.staticTexts["設定"].waitForExistence(timeout: 5),
            "The Settings surface did not switch to Japanese before opening Task."
        )

        let doneButton = application.navigationBars["設定"].buttons.firstMatch
        XCTAssertTrue(
            doneButton.waitForExistence(timeout: 20),
            "The Japanese Settings surface did not expose its Done action."
        )
        doneButton.tap()

        let taskTab = application.buttons["checklist"]
        XCTAssertTrue(
            taskTab.waitForExistence(timeout: 20),
            "The iOS host did not expose the Task tab after closing Settings."
        )
        taskTab.tap()

        XCTAssertTrue(
            application.staticTexts["進行状況"].waitForExistence(timeout: 20),
            "The Task page did not expose its Japanese page title."
        )
        attachCurrentScreenshot(named: "qa-task-japanese-interface")

        // Return the interface preference to the known Chinese baseline.
        let homeTab = application.buttons["house.fill"]
        XCTAssertTrue(
            homeTab.waitForExistence(timeout: 20),
            "The Japanese Task page did not expose the Home tab."
        )
        homeTab.tap()
        openSettingsFromHome()
        selectInterfaceLanguage(
            option: "简体中文",
            sectionTitle: "インターフェース"
        )
        XCTAssertTrue(
            application.navigationBars["设置"].waitForExistence(timeout: 20)
                || application.staticTexts["设置"].waitForExistence(timeout: 5),
            "The interface language could not be restored after the Japanese Task check."
        )
    }

    func testConfigurationCenterIsReachable() throws {
        launchHostAndWait()

        let configurationTab = application.buttons["slider.horizontal.3"]
        if configurationTab.waitForExistence(timeout: 30) {
            configurationTab.tap()
        } else {
            // The identifier is stable in the product, but the first launch
            // of a signed device build can expose the localized tab label a
            // little later than the rest of the host hierarchy.
            let localizedConfigurationTab = application.buttons["配置"]
            XCTAssertTrue(
                localizedConfigurationTab.waitForExistence(timeout: 10),
                "The Configuration Center tab was not exposed by the iOS host."
            )
            localizedConfigurationTab.tap()
        }

        let configurationRoot = application
            .descendants(matching: .any)
            .matching(identifier: "configuration-center-root")
            .firstMatch
        XCTAssertTrue(
            configurationRoot.waitForExistence(timeout: 20),
            "The iOS host did not reach the Configuration Center page."
        )

        // The frozen Configuration Center architecture presents its primary
        // editing responsibilities as expandable sections. Test their real
        // VoiceOver labels in every supported interface language, rather than
        // adding test-only production behavior to a grouped SwiftUI element.
        guard let layoutSection = configurationButton(
            titles: [
                "布局与内容",
                "Layout & Content",
                "レイアウトと内容",
                "레이아웃 및 콘텐츠"
            ]
        ) else {
            XCTFail(
                "The Configuration Center did not expose layout and content editing."
            )
            return
        }
        XCTAssertTrue(
            layoutSection.exists,
            "The Configuration Center did not expose layout and content editing."
        )

        guard let saveDestination = configurationButton(
            titles: ["保存位置", "Save Location", "保存先", "저장 위치"]
        ) else {
            XCTFail(
                "The Configuration Center did not expose save destination editing."
            )
            return
        }
        XCTAssertTrue(
            saveDestination.exists,
            "The Configuration Center did not expose save destination editing."
        )

        var cardEditor = configurationButton(
            titles: ["卡片内容", "Card Content", "カードの内容", "카드 내용"],
            timeout: 3
        )
        if cardEditor == nil {
            layoutSection.tap()
        }
        cardEditor = configurationButton(
            titles: ["卡片内容", "Card Content", "カードの内容", "카드 내용"]
        )
        guard let cardEditor else {
            XCTFail(
                "The expanded layout section did not expose card content editing."
            )
            return
        }
        revealConfigurationOption(cardEditor)
        XCTAssertTrue(
            cardEditor.exists,
            "The expanded layout section did not expose card content editing."
        )

        cardEditor.tap()
        let editorDone = application.buttons["card-editor-done"]
        XCTAssertTrue(
            editorDone.waitForExistence(timeout: 20),
            "The card-content editing presentation did not open."
        )
        editorDone.tap()

        let screenshot = XCTAttachment(
            screenshot: application.screenshot()
        )
        screenshot.name = "qa-01-configuration-center"
        screenshot.lifetime = .keepAlways
        add(screenshot)
    }

    private func revealConfigurationOption(_ option: XCUIElement) {
        for _ in 0..<3 where !option.exists {
            application.swipeUp()
            RunLoop.current.run(until: Date().addingTimeInterval(0.35))
        }
    }

    private func configurationButton(
        titles: [String],
        timeout: TimeInterval = 20
    ) -> XCUIElement? {
        let deadline = Date().addingTimeInterval(timeout)
        repeat {
            for title in titles {
                let candidate = application.buttons.matching(
                    NSPredicate(
                        format: "label == %@ OR label BEGINSWITH %@",
                        title,
                        title
                    )
                ).firstMatch
                if candidate.exists {
                    return candidate
                }
            }
            RunLoop.current.run(until: Date().addingTimeInterval(0.25))
        } while Date() < deadline
        return nil
    }

    func testSubjectAndAnchorEditorLayoutContract() throws {
        launchHostAndWait()
        prepareSubjectEditor()

        let configurationFlow = application
            .descendants(matching: .any)
            .matching(identifier: "subject-configuration-flow")
            .firstMatch
        XCTAssertTrue(
            configurationFlow.waitForExistence(timeout: 20),
            "The Subject configuration flow was not exposed."
        )

        let identityGroup = application
            .descendants(matching: .any)
            .matching(identifier: "subject-identity-fields-group")
            .firstMatch
        XCTAssertTrue(
            identityGroup.waitForExistence(timeout: 20),
            "The identity fields group was not exposed."
        )

        for identifier in [
            "subject-field-display-name",
            "subject-field-short-name",
            "subject-field-relationship-role",
            "subject-field-relationship-label"
        ] {
            let field = application
                .textFields[identifier]
            XCTAssertTrue(
                field.waitForExistence(timeout: 10),
                "The Subject editor did not expose text field \(identifier)."
            )
        }

        let anchorGroup = application
            .descendants(matching: .any)
            .matching(identifier: "subject-anchor-group")
            .firstMatch
        XCTAssertTrue(
            anchorGroup.waitForExistence(timeout: 20),
            "The grouped time-anchor surface was not exposed."
        )

        // The identity editor occupies the first viewport on a physical
        // iPhone. SwiftUI only publishes the descendants of the off-screen
        // portion after the scroll view advances, so settle the anchor panel
        // before asserting its row contract.
        anchorGroup.swipeUp()
        application.swipeUp()
        RunLoop.current.run(
            until: Date().addingTimeInterval(0.35)
        )

        let anchorRows = application
            .descendants(matching: .any)
            .matching(identifier: "subject-anchor-row")
        if anchorRows.count > 0 {
            assertNonOverlappingFrames(
                for: anchorRows,
                context: "time-anchor rows",
                allowedOverlap: 16
            )
            anchorRows.element(boundBy: 0).tap()
        } else {
            // A legacy subject may still enter the editor with an empty
            // anchor collection while the draft repair is settling. The
            // empty-state add action is the valid first row in that case and
            // must open the same anchor editor surface.
            let addAnchor = application.buttons["subject-add-anchor"]
            XCTAssertTrue(
                addAnchor.waitForExistence(timeout: 10),
                "The Subject editor must expose either a time-anchor row or its empty-state add action."
            )
            addAnchor.tap()
        }

        let anchorEditor = application
            .descendants(matching: .any)
            .matching(identifier: "subject-anchor-editor")
            .firstMatch
        XCTAssertTrue(
            anchorEditor.waitForExistence(timeout: 20),
            "Tapping a time-anchor row did not open its editor."
        )
        XCTAssertTrue(
            application.textFields["anchor-editor-name"]
                .waitForExistence(timeout: 10),
            "The time-anchor editor did not expose its name field."
        )
        XCTAssertTrue(
            application.buttons["anchor-type-birthday"]
                .waitForExistence(timeout: 10),
            "The time-anchor editor did not expose its type choices."
        )
        let saveButton = application.buttons["anchor-editor-save"]
        XCTAssertTrue(
            saveButton.waitForExistence(timeout: 10),
            "The time-anchor editor did not expose its save action."
        )
        saveButton.tap()

        XCTAssertTrue(
            application.navigationBars["编辑记忆对象"]
                .waitForExistence(timeout: 20),
            "Saving the time-anchor editor did not return to Subject configuration."
        )

        attachCurrentScreenshot(named: "qa-subject-anchor-editor-layout")
    }

    func testSubjectAvatarCropCanvasIsSquareAndCanCancel() throws {
        launchHostAndWait()
        prepareSubjectEditor()

        let avatarPicker = application.buttons["subject-avatar-picker"]
        XCTAssertTrue(
            avatarPicker.waitForExistence(timeout: 20),
            "The Subject editor did not expose its avatar picker."
        )
        avatarPicker.tap()

        openPreparedInputAlbumFromCurrentPicker()
        let inputImages = application.images
            .matching(identifier: "PXGGridLayout-Info")
            .matching(
                NSPredicate(
                    format: "label BEGINSWITH %@",
                    "照片"
                )
            )
        XCTAssertGreaterThan(
            inputImages.count,
            0,
            "The prepared QA album did not expose a still image for avatar cropping."
        )
        let inputImage = inputImages.element(boundBy: 0)
        XCTAssertTrue(
            inputImage.waitForExistence(timeout: 20),
            "The selected avatar input image did not become available."
        )
        inputImage.tap()

        let cropCanvas = application
            .descendants(matching: .any)
            .matching(identifier: "subject-avatar-crop-canvas")
            .firstMatch
        // PhotosPicker can either require its explicit completion action or
        // transition directly to the crop flow after a one-item selection.
        // Do not query a global `完成` button here: the crop sheet and the
        // suspended Subject flow both legitimately expose that localized
        // label at the same time.
        if !cropCanvas.waitForExistence(timeout: 5) {
            let pickerDoneButton = application.buttons
                .matching(
                    NSPredicate(
                        format: "label == %@",
                        "完成"
                    )
                )
                .firstMatch
            XCTAssertTrue(
                pickerDoneButton.waitForExistence(timeout: 20),
                "The avatar picker did not expose its completion action."
            )
            XCTAssertTrue(
                pickerDoneButton.isEnabled,
                "Selecting the avatar input did not enable picker completion."
            )
            pickerDoneButton.tap()
        }
        XCTAssertTrue(
            cropCanvas.waitForExistence(timeout: 30),
            "Selecting an avatar did not present the crop canvas."
        )
        XCTAssertGreaterThan(
            cropCanvas.frame.width,
            0,
            "The crop canvas has no visible width."
        )
        XCTAssertEqual(
            cropCanvas.frame.width,
            cropCanvas.frame.height,
            accuracy: 2,
            "The crop canvas must be square before image geometry is measured."
        )
        attachCurrentScreenshot(named: "qa-subject-avatar-crop-square")

        let cancelButton = application
            .navigationBars["调整对象头像"]
            .buttons["取消"]
        XCTAssertTrue(
            cancelButton.waitForExistence(timeout: 10),
            "The crop surface did not expose cancellation."
        )
        cancelButton.tap()

        XCTAssertTrue(
            application.navigationBars["编辑记忆对象"]
                .waitForExistence(timeout: 20),
            "Cancelling the crop did not return to the Subject editor."
        )
    }

    func testMemoMarkQAInputsInventory() throws {
        let inventory = try inventoryAlbum(
            titled: "MemoMark QA Inputs",
            attachmentName: "qa-inputs-inventory.json"
        )

        XCTAssertFalse(
            inventory.assets.isEmpty,
            "The PhotoKit album contains no assets: \(inventory.albumTitle)"
        )
    }

    func testMemoMarkQAOutputsInventory() throws {
        let inventory = try inventoryAlbum(
            titled: "MemoMark QA Outputs",
            attachmentName: "qa-outputs-inventory.json"
        )

        let outputCandidates = inventory.assets.filter {
            $0.classification == "jpegStill"
                || $0.classification == "livePhoto"
        }
        let observedClassifications = inventory.assets.map {
            $0.classification
        }
        XCTAssertGreaterThan(
            outputCandidates.count,
            0,
            "The output album has no JPEG still or Live Photo candidate; observed classifications: \(observedClassifications)"
        )
    }

    func testMemoMarkQAInputMediaMatrix() throws {
        let inventory = try inventoryAlbum(
            titled: "MemoMark QA Inputs",
            attachmentName: "qa-input-media-matrix.json"
        )

        let classifications = Set(
            inventory.assets.map(\.classification)
        )
        XCTAssertTrue(
            classifications.contains("livePhoto"),
            "The input album must contain a complete Live Photo."
        )
        XCTAssertTrue(
            classifications.contains("jpegStill"),
            "The input album must contain an independent JPEG still for QA-02 and TX-001-D1."
        )
        XCTAssertTrue(
            inventory.assets.contains(where: { asset in
                asset.classification == "livePhoto"
                    && asset.resources.contains(where: {
                        $0.type == "photo"
                            && ($0.uniformTypeIdentifier == "public.heic"
                                || $0.uniformTypeIdentifier == "public.heif")
                    })
            }),
            "The input album must contain a Live Photo with a HEIC still resource."
        )
        // Apple Photos may expose a paired Live Photo with an HEIC/HEIF still
        // resource rather than a JPEG rendition.  The production contract is
        // the paired still + motion resource, not one particular codec.
        XCTAssertTrue(
            inventory.assets.contains(where: { asset in
                asset.classification == "livePhoto"
                    && asset.resources.contains(where: {
                        $0.type == "photo"
                            && [
                                "public.jpeg",
                                "public.heic",
                                "public.heif"
                            ].contains($0.uniformTypeIdentifier)
                    })
            }),
            "The input album must contain a Live Photo with a supported still resource."
        )
        XCTAssertTrue(
            classifications.contains("rawWithJPEGRepresentation"),
            "The input album must contain a RAW asset with a Photos JPEG rendition."
        )

        // On the connected iPhone 17 Pro Max, the device's highest-quality
        // capture path is represented in Photos as RAW/ProRAW with a JPEG
        // rendition. The QA product label is "48MP"; the exact PhotoKit
        // pixel area is recorded separately because the device may expose a
        // cropped aspect ratio (for example, 8064x4536) rather than a
        // mathematical 48,000,000-pixel rectangle.
        let rawHighestQualityAssets = inventory.assets.filter {
            $0.classification == "rawWithJPEGRepresentation"
                && Int64($0.pixelWidth) * Int64($0.pixelHeight) >= 30_000_000
        }
        XCTAssertFalse(
            rawHighestQualityAssets.isEmpty,
            "The input album must contain the device's highest-quality RAW/ProRAW asset with a Photos JPEG rendition for the bounded 48MP QA run."
        )

        let maxRawPixelArea = rawHighestQualityAssets
            .map { Int64($0.pixelWidth) * Int64($0.pixelHeight) }
            .max() ?? 0
        let exact48MPPixelAreaAvailable = rawHighestQualityAssets.contains {
            Int64($0.pixelWidth) * Int64($0.pixelHeight) >= 45_000_000
        }

        let evidence = QAInputMediaMatrixEvidence(
            albumTitle: inventory.albumTitle,
            assetCount: inventory.assetCount,
            classifications: classifications.sorted(),
            rawHighestQualityInputAvailable: !rawHighestQualityAssets.isEmpty,
            exact48MPPixelAreaAvailable: exact48MPPixelAreaAvailable,
            maxRawPixelArea: maxRawPixelArea,
            rawHighestQualityAssets: rawHighestQualityAssets.map {
                QAInputHighResolutionAsset(
                    localIdentifier: $0.localIdentifier,
                    classification: $0.classification,
                    pixelWidth: $0.pixelWidth,
                    pixelHeight: $0.pixelHeight,
                    pixelArea: Int64($0.pixelWidth) * Int64($0.pixelHeight)
                )
            }
        )
        let data = try JSONEncoder().encode(evidence)
        let attachment = XCTAttachment(
            data: data,
            uniformTypeIdentifier: "public.json"
        )
        attachment.name = "qa-input-media-matrix-evidence.json"
        attachment.lifetime = .keepAlways
        add(attachment)

        print(
            "MemoMark input media matrix: classifications=\(classifications.sorted()), rawHighestQualityInputAvailable=true, exact48MPPixelAreaAvailable=\(exact48MPPixelAreaAvailable), rawHighestQualityAssets=\(rawHighestQualityAssets.count), maxRawPixelArea=\(maxRawPixelArea)"
        )
    }

    func testPhotoPickerCanBePresentedAndCancelled() throws {
        launchHostAndWait()

        let pickerButton = application.buttons["home-photo-picker"].exists
            ? application.buttons["home-photo-picker"]
            : application.buttons["App 内选择照片"]
        XCTAssertTrue(
            pickerButton.waitForExistence(timeout: 20),
            "The iOS home page did not expose the in-app photo picker."
        )
        pickerButton.tap()

        let cancelButton = application.buttons["取消"]
        XCTAssertTrue(
            cancelButton.waitForExistence(timeout: 20),
            "The system photo picker did not become reachable from the production flow."
        )

        let screenshot = XCTAttachment(
            screenshot: XCUIScreen.main.screenshot()
        )
        screenshot.name = "qa-photo-picker-presented"
        screenshot.lifetime = .keepAlways
        add(screenshot)

        cancelButton.tap()
        XCTAssertTrue(
            pickerButton.waitForExistence(timeout: 10),
            "The production flow did not return to the iOS home page after cancelling the picker."
        )
    }

    func testPhotoPickerCanReachTheQAInputAlbumWithoutSelection() throws {
        openPreparedInputAlbum()

        // This tap is intentionally on the input album only. The output album
        // is never selected by the production-input route; it is inspected by
        // the separate PhotoKit readback tests below.
        let screenshot = XCTAttachment(
            screenshot: XCUIScreen.main.screenshot()
        )
        screenshot.name = "qa-photo-picker-input-album"
        screenshot.lifetime = .keepAlways
        add(screenshot)

        let backButton = application.buttons["返回"]
        XCTAssertTrue(
            backButton.waitForExistence(timeout: 10),
            "The system photo picker did not expose the back action after opening the QA input album."
        )
        backButton.tap()

        let cancelButton = application.buttons["取消"]
        XCTAssertTrue(
            cancelButton.waitForExistence(timeout: 10),
            "The system photo picker did not return to its album list after leaving the QA input album."
        )
        cancelButton.tap()
    }

    func testMemoMarkQA02CanProcessPreparedJPEGFromTheInputAlbum() throws {
        let inputBefore = try inventoryAlbum(
            titled: "MemoMark QA Inputs",
            attachmentName: "qa-02-jpeg-input-before.json"
        )
        guard let jpegInput = inputBefore.assets.first(where: {
            $0.classification == "jpegStill"
        }) else {
            XCTFail("QA-02 requires an independent JPEG still input.")
            return
        }

        let outputBefore = try inventoryAlbum(
            titled: "MemoMark QA Outputs",
            attachmentName: "qa-02-jpeg-outputs-before.json"
        )
        let outputIdentifiersBefore = Set(
            outputBefore.assets.map(\.localIdentifier)
        )

        let jpegGridImages = preparedInputPhotoGridImages()
        let selectableInputAssets = inputBefore.assets.filter {
            $0.classification != "livePhoto"
        }
        guard let selectionIndex = selectableInputAssets.firstIndex(where: {
            $0.localIdentifier == jpegInput.localIdentifier
        }) else {
            XCTFail("The JPEG input was not present in the selectable PhotoKit grid order.")
            return
        }

        XCTAssertGreaterThan(
            jpegGridImages.count,
            selectionIndex,
            "The photo picker did not expose the JPEG input at its PhotoKit inventory position."
        )
        let jpegGridImage = jpegGridImages.element(boundBy: selectionIndex)
        XCTAssertTrue(
            jpegGridImage.waitForExistence(timeout: 20),
            "The prepared JPEG input cell did not become reachable."
        )
        print(
            "MemoMark QA-02 selecting JPEG input cell index=\(selectionIndex), label=\(jpegGridImage.label)"
        )
        jpegGridImage.tap()

        let doneButton = application.buttons["完成"]
        XCTAssertTrue(
            doneButton.waitForExistence(timeout: 20),
            "The photo picker did not expose its completion action for the JPEG input."
        )
        XCTAssertTrue(
            doneButton.isEnabled,
            "The photo picker did not register the JPEG input selection."
        )
        doneButton.tap()

        let outputDeadline = Date().addingTimeInterval(300)
        var observedOutputCount = outputBefore.assetCount
        while Date() < outputDeadline {
            observedOutputCount = albumAssetCount(titled: "MemoMark QA Outputs")
            if observedOutputCount > outputBefore.assetCount {
                break
            }
            RunLoop.current.run(
                until: Date().addingTimeInterval(2)
            )
        }
        XCTAssertEqual(
            observedOutputCount,
            outputBefore.assetCount + 1,
            "The JPEG processing run must create exactly one new output asset."
        )

        let inputAfter = try inventoryAlbum(
            titled: "MemoMark QA Inputs",
            attachmentName: "qa-02-jpeg-input-after.json"
        )
        let outputAfter = try inventoryAlbum(
            titled: "MemoMark QA Outputs",
            attachmentName: "qa-02-jpeg-outputs-after.json"
        )
        let newOutputs = outputAfter.assets.filter {
            !outputIdentifiersBefore.contains($0.localIdentifier)
        }

        XCTAssertEqual(
            newOutputs.count,
            1,
            "The JPEG run must bind exactly one new PhotoKit output identifier."
        )
        guard let newOutput = newOutputs.first else {
            return
        }
        XCTAssertNotEqual(
            newOutput.localIdentifier,
            jpegInput.localIdentifier,
            "MemoMark must save a new output asset and must not mutate the JPEG input."
        )
        XCTAssertEqual(
            newOutput.classification,
            "jpegStill",
            "The JPEG processing output must be a generated JPEG still."
        )

        guard let preservedInput = inputAfter.assets.first(where: {
            $0.localIdentifier == jpegInput.localIdentifier
        }) else {
            XCTFail("The JPEG input disappeared from MemoMark QA Inputs after processing.")
            return
        }
        XCTAssertEqual(
            preservedInput.classification,
            "jpegStill",
            "The original JPEG input classification changed after processing."
        )
        XCTAssertEqual(
            preservedInput.pixelWidth,
            jpegInput.pixelWidth,
            "The original JPEG input width changed after processing."
        )
        XCTAssertEqual(
            preservedInput.pixelHeight,
            jpegInput.pixelHeight,
            "The original JPEG input height changed after processing."
        )

        let evidence = QA02ProcessingEvidence(
            inputLocalIdentifier: jpegInput.localIdentifier,
            outputLocalIdentifier: newOutput.localIdentifier,
            inputClassification: jpegInput.classification,
            outputClassification: newOutput.classification,
            inputPixelWidth: jpegInput.pixelWidth,
            inputPixelHeight: jpegInput.pixelHeight,
            outputPixelWidth: newOutput.pixelWidth,
            outputPixelHeight: newOutput.pixelHeight,
            pickerSelectionIndex: selectionIndex,
            outputCountBefore: outputBefore.assetCount,
            outputCountAfter: outputAfter.assetCount
        )
        let data = try JSONEncoder().encode(evidence)
        let attachment = XCTAttachment(
            data: data,
            uniformTypeIdentifier: "public.json"
        )
        attachment.name = "qa-02-jpeg-processing-evidence.json"
        attachment.lifetime = .keepAlways
        add(attachment)

        print(
            "MemoMark QA-02 JPEG processing: input=\(jpegInput.localIdentifier), output=\(newOutput.localIdentifier), input=\(jpegInput.pixelWidth)x\(jpegInput.pixelHeight), output=\(newOutput.pixelWidth)x\(newOutput.pixelHeight), outputClassification=\(newOutput.classification), originalPreserved=true"
        )
    }

    func testMemoMarkQA04CanProcessPreparedLivePhotoFromTheInputAlbum() throws {
        let inputBefore = try inventoryAlbum(
            titled: "MemoMark QA Inputs",
            attachmentName: "qa-04-live-photo-input-before.json"
        )
        guard let livePhotoInput = inputBefore.assets.first(where: {
            $0.classification == "livePhoto"
        }) else {
            XCTFail("QA-04 requires a complete Live Photo input.")
            return
        }

        let outputBefore = try inventoryAlbum(
            titled: "MemoMark QA Outputs",
            attachmentName: "qa-04-live-photo-outputs-before.json"
        )
        let outputIdentifiersBefore = Set(
            outputBefore.assets.map(\.localIdentifier)
        )

        guard let selectionIndex = selectPreparedLivePhotoCell() else {
            XCTFail("The photo picker did not expose a selectable Live Photo cell.")
            return
        }
        print(
            "MemoMark QA-04 selected Live Photo picker cell index=\(selectionIndex)"
        )

        let doneButton = application.buttons["完成"]
        XCTAssertTrue(
            doneButton.waitForExistence(timeout: 20),
            "The photo picker did not expose its completion action for the Live Photo input."
        )
        waitForPickerCompletionEnabled(doneButton)
        XCTAssertTrue(
            doneButton.isEnabled,
            "The photo picker did not register the Live Photo input selection."
        )
        doneButton.tap()

        let outputDeadline = Date().addingTimeInterval(300)
        var observedOutputCount = outputBefore.assetCount
        while Date() < outputDeadline {
            observedOutputCount = albumAssetCount(titled: "MemoMark QA Outputs")
            if observedOutputCount > outputBefore.assetCount {
                break
            }
            RunLoop.current.run(
                until: Date().addingTimeInterval(2)
            )
        }
        XCTAssertEqual(
            observedOutputCount,
            outputBefore.assetCount + 1,
            "The Live Photo processing run must create exactly one new output asset."
        )

        let inputAfter = try inventoryAlbum(
            titled: "MemoMark QA Inputs",
            attachmentName: "qa-04-live-photo-input-after.json"
        )
        let outputAfter = try inventoryAlbum(
            titled: "MemoMark QA Outputs",
            attachmentName: "qa-04-live-photo-outputs-after.json"
        )
        let newOutputs = outputAfter.assets.filter {
            !outputIdentifiersBefore.contains($0.localIdentifier)
        }

        XCTAssertEqual(
            newOutputs.count,
            1,
            "The Live Photo run must bind exactly one new PhotoKit output identifier."
        )
        guard let newOutput = newOutputs.first else {
            return
        }
        XCTAssertNotEqual(
            newOutput.localIdentifier,
            livePhotoInput.localIdentifier,
            "MemoMark must save a new Live Photo asset and must not mutate the input asset."
        )
        XCTAssertEqual(
            newOutput.classification,
            "livePhoto",
            "The Live Photo processing output must remain a complete Live Photo."
        )
        XCTAssertTrue(
            newOutput.resources.contains(where: { $0.type == "pairedVideo" }),
            "The Live Photo processing output must expose its paired motion resource."
        )

        guard let preservedInput = inputAfter.assets.first(where: {
            $0.localIdentifier == livePhotoInput.localIdentifier
        }) else {
            XCTFail("The Live Photo input disappeared from MemoMark QA Inputs after processing.")
            return
        }
        XCTAssertEqual(
            preservedInput.classification,
            "livePhoto",
            "The original Live Photo input classification changed after processing."
        )
        XCTAssertTrue(
            preservedInput.resources.contains(where: { $0.type == "pairedVideo" }),
            "The original Live Photo input no longer exposes its paired motion resource."
        )
        XCTAssertEqual(
            preservedInput.pixelWidth,
            livePhotoInput.pixelWidth,
            "The original Live Photo input width changed after processing."
        )
        XCTAssertEqual(
            preservedInput.pixelHeight,
            livePhotoInput.pixelHeight,
            "The original Live Photo input height changed after processing."
        )

        if let inputCaptureDate = Self.date(from: livePhotoInput.creationDate),
           let outputCaptureDate = Self.date(from: newOutput.creationDate) {
            XCTAssertEqual(
                outputCaptureDate.timeIntervalSince(inputCaptureDate),
                0,
                accuracy: 1,
                "The Live Photo output did not retain the input capture date."
            )
        } else {
            XCTFail("QA-04 requires capture dates on both the Live Photo input and output.")
        }

        let evidence = QA04ProcessingEvidence(
            inputLocalIdentifier: livePhotoInput.localIdentifier,
            outputLocalIdentifier: newOutput.localIdentifier,
            inputClassification: livePhotoInput.classification,
            outputClassification: newOutput.classification,
            inputPixelWidth: livePhotoInput.pixelWidth,
            inputPixelHeight: livePhotoInput.pixelHeight,
            outputPixelWidth: newOutput.pixelWidth,
            outputPixelHeight: newOutput.pixelHeight,
            inputCaptureDate: livePhotoInput.creationDate,
            outputCaptureDate: newOutput.creationDate,
            inputResourceTypes: livePhotoInput.resources.map(\.type),
            outputResourceTypes: newOutput.resources.map(\.type),
            pickerSelectionIndex: selectionIndex,
            outputCountBefore: outputBefore.assetCount,
            outputCountAfter: outputAfter.assetCount
        )
        let data = try JSONEncoder().encode(evidence)
        let attachment = XCTAttachment(
            data: data,
            uniformTypeIdentifier: "public.json"
        )
        attachment.name = "qa-04-live-photo-processing-evidence.json"
        attachment.lifetime = .keepAlways
        add(attachment)

        print(
            "MemoMark QA-04 Live Photo processing: input=\(livePhotoInput.localIdentifier), output=\(newOutput.localIdentifier), input=\(livePhotoInput.pixelWidth)x\(livePhotoInput.pixelHeight), output=\(newOutput.pixelWidth)x\(newOutput.pixelHeight), outputClassification=\(newOutput.classification), pairedVideo=true, captureDatePreserved=true, originalPreserved=true"
        )
    }

    func testMemoMarkQA05CanProcessHighestQualityRawFromThePreparedInputAlbum() throws {
        let inputBefore = try inventoryAlbum(
            titled: "MemoMark QA Inputs",
            attachmentName: "qa-05-raw-input-before.json"
        )
        guard let rawInput = inputBefore.assets
            .filter({
                $0.classification == "rawWithJPEGRepresentation"
            })
            .max(by: { lhs, rhs in
                let lhsArea = Int64(lhs.pixelWidth) * Int64(lhs.pixelHeight)
                let rhsArea = Int64(rhs.pixelWidth) * Int64(rhs.pixelHeight)
                return lhsArea < rhsArea
            }) else {
            XCTFail("QA-05 requires a RAW/ProRAW input with a Photos JPEG rendition.")
            return
        }

        let outputBefore = try inventoryAlbum(
            titled: "MemoMark QA Outputs",
            attachmentName: "qa-05-outputs-before.json"
        )
        let outputIdentifiersBefore = Set(
            outputBefore.assets.map(\.localIdentifier)
        )

        // The picker grid contains all non-Live-Photo assets under the
        // "照片" accessibility label. Derive the cell position from the
        // PhotoKit inventory instead of assuming that the first cell is RAW;
        // QA-02's independent JPEG inputs intentionally precede the RAW set.
        let selectableInputAssets = inputBefore.assets.filter {
            $0.classification != "livePhoto"
        }
        guard let selectionIndex = selectableInputAssets.firstIndex(where: {
            $0.localIdentifier == rawInput.localIdentifier
        }) else {
            XCTFail("The RAW input was not present in the selectable PhotoKit grid order.")
            return
        }

        let rawGridImages = preparedInputPhotoGridImages()
        XCTAssertGreaterThan(
            rawGridImages.count,
            selectionIndex,
            "The prepared input album did not expose a selectable RAW/ProRAW photo cell."
        )
        let rawGridImage = rawGridImages.element(boundBy: selectionIndex)
        XCTAssertTrue(
            rawGridImage.waitForExistence(timeout: 20),
            "The highest-quality RAW/ProRAW input cell did not become reachable."
        )
        print("MemoMark QA-05 selecting RAW input cell: \(rawGridImage.label)")
        rawGridImage.tap()

        let doneButton = application.buttons["完成"]
        XCTAssertTrue(
            doneButton.waitForExistence(timeout: 20),
            "The system photo picker did not expose its completion action."
        )
        XCTAssertTrue(
            doneButton.isEnabled,
            "The system photo picker did not register the selected RAW/ProRAW input."
        )
        doneButton.tap()

        let outputDeadline = Date().addingTimeInterval(300)
        var observedOutputCount = outputBefore.assetCount
        while Date() < outputDeadline {
            observedOutputCount = albumAssetCount(titled: "MemoMark QA Outputs")
            if observedOutputCount > outputBefore.assetCount {
                break
            }
            RunLoop.current.run(
                until: Date().addingTimeInterval(2)
            )
        }
        XCTAssertEqual(
            observedOutputCount,
            outputBefore.assetCount + 1,
            "The RAW/ProRAW submission must create exactly one new asset in MemoMark QA Outputs within five minutes."
        )

        // A high-resolution RAW submission may keep the app on its processing
        // or completion surface while the PhotoKit transaction finishes. The
        // durable contract is the new output plus original preservation; only
        // check the home surface after that transaction has been observed.
        let returnedToHome: Bool
        if application.buttons["home-photo-picker"].exists {
            returnedToHome = true
        } else {
            returnedToHome = application.buttons["App 内选择照片"]
                .waitForExistence(timeout: 15)
        }
        print(
            "MemoMark QA-05 completion surface: returnedToHome=\(returnedToHome)"
        )

        let inputAfter = try inventoryAlbum(
            titled: "MemoMark QA Inputs",
            attachmentName: "qa-05-raw-input-after.json"
        )
        let outputAfter = try inventoryAlbum(
            titled: "MemoMark QA Outputs",
            attachmentName: "qa-05-outputs-after.json"
        )
        let newOutputs = outputAfter.assets.filter {
            !outputIdentifiersBefore.contains($0.localIdentifier)
        }
        XCTAssertEqual(
            newOutputs.count,
            1,
            "The RAW/ProRAW run must bind exactly one new PhotoKit local identifier."
        )

        guard let newOutput = newOutputs.first else {
            return
        }
        XCTAssertNotEqual(
            newOutput.localIdentifier,
            rawInput.localIdentifier,
            "MemoMark must save a new output asset and must not mutate the RAW/ProRAW input."
        )
        XCTAssertNotEqual(
            newOutput.classification,
            "rawWithJPEGRepresentation",
            "The QA-05 output must be a generated still/Live Photo result, not the RAW source resource."
        )

        guard let preservedInput = inputAfter.assets.first(where: {
            $0.localIdentifier == rawInput.localIdentifier
        }) else {
            XCTFail("The RAW/ProRAW input disappeared from MemoMark QA Inputs after processing.")
            return
        }
        XCTAssertEqual(
            preservedInput.classification,
            "rawWithJPEGRepresentation",
            "The original RAW/ProRAW input classification changed after processing."
        )
        XCTAssertEqual(
            preservedInput.pixelWidth,
            rawInput.pixelWidth,
            "The original RAW/ProRAW input width changed after processing."
        )
        XCTAssertEqual(
            preservedInput.pixelHeight,
            rawInput.pixelHeight,
            "The original RAW/ProRAW input height changed after processing."
        )

        let evidence = QA05ProcessingEvidence(
            inputLocalIdentifier: rawInput.localIdentifier,
            outputLocalIdentifier: newOutput.localIdentifier,
            inputClassification: rawInput.classification,
            outputClassification: newOutput.classification,
            inputPixelWidth: rawInput.pixelWidth,
            inputPixelHeight: rawInput.pixelHeight,
            outputPixelWidth: newOutput.pixelWidth,
            outputPixelHeight: newOutput.pixelHeight,
            outputCountBefore: outputBefore.assetCount,
            outputCountAfter: outputAfter.assetCount
        )
        let data = try JSONEncoder().encode(evidence)
        let attachment = XCTAttachment(
            data: data,
            uniformTypeIdentifier: "public.json"
        )
        attachment.name = "qa-05-raw-processing-evidence.json"
        attachment.lifetime = .keepAlways
        add(attachment)

        print(
            "MemoMark QA-05 RAW processing: input=\(rawInput.localIdentifier), output=\(newOutput.localIdentifier), input=\(rawInput.pixelWidth)x\(rawInput.pixelHeight), output=\(newOutput.pixelWidth)x\(newOutput.pixelHeight), outputClassification=\(newOutput.classification), originalPreserved=true"
        )
    }

    func testMemoMarkQA07StaticPostCommitTerminationAndRestartIdempotency() throws {
        let inputBefore = try inventoryAlbum(
            titled: "MemoMark QA Inputs",
            attachmentName: "qa-07-static-input-before.json"
        )
        guard let jpegInput = inputBefore.assets.first(where: {
            $0.classification == "jpegStill"
        }) else {
            XCTFail("QA-07 requires an independent JPEG still input.")
            return
        }

        let outputBefore = try inventoryAlbum(
            titled: "MemoMark QA Outputs",
            attachmentName: "qa-07-static-outputs-before.json"
        )
        let outputIdentifiersBefore = Set(
            outputBefore.assets.map(\.localIdentifier)
        )
        application.launchArguments.append(
            "-qaPauseAfterPhotoLibraryCommit"
        )

        let pickerGridImages = preparedInputPhotoGridImages()
        let selectableInputAssets = inputBefore.assets.filter {
            $0.classification != "livePhoto"
        }
        guard let selectionIndex = selectableInputAssets.firstIndex(where: {
            $0.localIdentifier == jpegInput.localIdentifier
        }) else {
            XCTFail("The JPEG input was not present in the selectable PhotoKit grid order.")
            return
        }
        XCTAssertGreaterThan(
            pickerGridImages.count,
            selectionIndex,
            "The photo picker did not expose the QA-07 JPEG input cell."
        )
        let jpegGridImage = pickerGridImages.element(boundBy: selectionIndex)
        XCTAssertTrue(
            jpegGridImage.waitForExistence(timeout: 20),
            "The QA-07 JPEG input cell did not become reachable."
        )
        jpegGridImage.tap()

        let doneButton = application.buttons["完成"]
        XCTAssertTrue(
            doneButton.waitForExistence(timeout: 20),
            "The photo picker did not expose completion for the QA-07 JPEG input."
        )
        XCTAssertTrue(
            doneButton.isEnabled,
            "The photo picker did not register the QA-07 JPEG selection."
        )
        doneButton.tap()

        let commitDeadline = Date().addingTimeInterval(300)
        var outputCountAtTermination = outputBefore.assetCount
        while Date() < commitDeadline {
            outputCountAtTermination = albumAssetCount(
                titled: "MemoMark QA Outputs"
            )
            if outputCountAtTermination > outputBefore.assetCount {
                break
            }
            RunLoop.current.run(
                until: Date().addingTimeInterval(2)
            )
        }
        XCTAssertEqual(
            outputCountAtTermination,
            outputBefore.assetCount + 1,
            "QA-07 must observe the PhotoKit output before forced termination."
        )

        application.terminate()
        XCTAssertTrue(
            application.wait(for: .notRunning, timeout: 20),
            "The QA-07 host process did not terminate after the controlled test termination."
        )

        application.launch()
        XCTAssertTrue(
            application.wait(for: .runningForeground, timeout: 30),
            "MemoMark did not relaunch after the QA-07 forced termination."
        )

        let recoveryDeadline = Date().addingTimeInterval(30)
        var outputCountAfterRelaunch = albumAssetCount(
            titled: "MemoMark QA Outputs"
        )
        while Date() < recoveryDeadline {
            outputCountAfterRelaunch = albumAssetCount(
                titled: "MemoMark QA Outputs"
            )
            if outputCountAfterRelaunch > outputBefore.assetCount + 1 {
                break
            }
            RunLoop.current.run(
                until: Date().addingTimeInterval(2)
            )
        }
        XCTAssertEqual(
            outputCountAfterRelaunch,
            outputBefore.assetCount + 1,
            "QA-07 restart recovery must not create a duplicate output."
        )
        assertSubsequentLaunchesDoNotDuplicateOutput(
            expectedOutputCount: outputBefore.assetCount + 1,
            scenario: "QA-07 static recovery"
        )

        let inputAfter = try inventoryAlbum(
            titled: "MemoMark QA Inputs",
            attachmentName: "qa-07-static-input-after.json"
        )
        let outputAfter = try inventoryAlbum(
            titled: "MemoMark QA Outputs",
            attachmentName: "qa-07-static-outputs-after.json"
        )
        let newOutputs = outputAfter.assets.filter {
            !outputIdentifiersBefore.contains($0.localIdentifier)
        }
        XCTAssertEqual(
            newOutputs.count,
            1,
            "QA-07 must bind exactly one output to the interrupted static task."
        )
        guard let newOutput = newOutputs.first else {
            return
        }
        XCTAssertEqual(
            newOutput.classification,
            "jpegStill",
            "QA-07 must recover the generated static JPEG output."
        )
        guard let preservedInput = inputAfter.assets.first(where: {
            $0.localIdentifier == jpegInput.localIdentifier
        }) else {
            XCTFail("The QA-07 JPEG input disappeared after restart recovery.")
            return
        }
        XCTAssertEqual(
            preservedInput.classification,
            "jpegStill",
            "The QA-07 restart changed the original JPEG classification."
        )
        XCTAssertEqual(
            preservedInput.pixelWidth,
            jpegInput.pixelWidth,
            "The QA-07 restart changed the original JPEG width."
        )
        XCTAssertEqual(
            preservedInput.pixelHeight,
            jpegInput.pixelHeight,
            "The QA-07 restart changed the original JPEG height."
        )

        let evidence = QA07RecoveryEvidence(
            inputLocalIdentifier: jpegInput.localIdentifier,
            outputLocalIdentifier: newOutput.localIdentifier,
            inputClassification: jpegInput.classification,
            outputClassification: newOutput.classification,
            inputPixelWidth: jpegInput.pixelWidth,
            inputPixelHeight: jpegInput.pixelHeight,
            outputPixelWidth: newOutput.pixelWidth,
            outputPixelHeight: newOutput.pixelHeight,
            pickerSelectionIndex: selectionIndex,
            outputCountBefore: outputBefore.assetCount,
            outputCountAtTermination: outputCountAtTermination,
            outputCountAfterRelaunch: outputCountAfterRelaunch,
            controlledTermination: true,
            originalPreserved: true,
            duplicateOutput: false
        )
        let data = try JSONEncoder().encode(evidence)
        let attachment = XCTAttachment(
            data: data,
            uniformTypeIdentifier: "public.json"
        )
        attachment.name = "qa-07-static-recovery-evidence.json"
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    func testMemoMarkQA08LivePhotoPostCommitTerminationAndRestartIdempotency() throws {
        let inputBefore = try inventoryAlbum(
            titled: "MemoMark QA Inputs",
            attachmentName: "qa-08-live-photo-input-before.json"
        )
        guard let livePhotoInput = inputBefore.assets.first(where: {
            $0.classification == "livePhoto"
        }) else {
            XCTFail("QA-08 requires a complete Live Photo input.")
            return
        }

        let outputBefore = try inventoryAlbum(
            titled: "MemoMark QA Outputs",
            attachmentName: "qa-08-live-photo-outputs-before.json"
        )
        let outputIdentifiersBefore = Set(
            outputBefore.assets.map(\.localIdentifier)
        )
        application.launchArguments.append(
            "-qaPauseAfterPhotoLibraryCommit"
        )

        guard let selectionIndex = selectPreparedLivePhotoCell() else {
            XCTFail("The photo picker did not expose a selectable QA-08 Live Photo cell.")
            return
        }

        let doneButton = application.buttons["完成"]
        XCTAssertTrue(
            doneButton.waitForExistence(timeout: 20),
            "The photo picker did not expose completion for the QA-08 Live Photo input."
        )
        waitForPickerCompletionEnabled(doneButton)
        XCTAssertTrue(
            doneButton.isEnabled,
            "The photo picker did not register the QA-08 Live Photo selection."
        )
        doneButton.tap()

        let commitDeadline = Date().addingTimeInterval(300)
        var outputCountAtTermination = outputBefore.assetCount
        while Date() < commitDeadline {
            outputCountAtTermination = albumAssetCount(
                titled: "MemoMark QA Outputs"
            )
            if outputCountAtTermination > outputBefore.assetCount {
                break
            }
            RunLoop.current.run(
                until: Date().addingTimeInterval(2)
            )
        }
        XCTAssertEqual(
            outputCountAtTermination,
            outputBefore.assetCount + 1,
            "QA-08 must observe the Live Photo output before forced termination."
        )

        application.terminate()
        XCTAssertTrue(
            application.wait(for: .notRunning, timeout: 20),
            "The QA-08 host process did not terminate after the controlled test termination."
        )

        application.launch()
        XCTAssertTrue(
            application.wait(for: .runningForeground, timeout: 30),
            "MemoMark did not relaunch after the QA-08 forced termination."
        )

        let recoveryDeadline = Date().addingTimeInterval(30)
        var outputCountAfterRelaunch = albumAssetCount(
            titled: "MemoMark QA Outputs"
        )
        while Date() < recoveryDeadline {
            outputCountAfterRelaunch = albumAssetCount(
                titled: "MemoMark QA Outputs"
            )
            if outputCountAfterRelaunch > outputBefore.assetCount + 1 {
                break
            }
            RunLoop.current.run(
                until: Date().addingTimeInterval(2)
            )
        }
        XCTAssertEqual(
            outputCountAfterRelaunch,
            outputBefore.assetCount + 1,
            "QA-08 restart recovery must not create a duplicate Live Photo output."
        )
        assertSubsequentLaunchesDoNotDuplicateOutput(
            expectedOutputCount: outputBefore.assetCount + 1,
            scenario: "QA-08 Live Photo recovery"
        )

        let inputAfter = try inventoryAlbum(
            titled: "MemoMark QA Inputs",
            attachmentName: "qa-08-live-photo-input-after.json"
        )
        let outputAfter = try inventoryAlbum(
            titled: "MemoMark QA Outputs",
            attachmentName: "qa-08-live-photo-outputs-after.json"
        )
        let newOutputs = outputAfter.assets.filter {
            !outputIdentifiersBefore.contains($0.localIdentifier)
        }
        XCTAssertEqual(
            newOutputs.count,
            1,
            "QA-08 must bind exactly one output to the interrupted Live Photo task."
        )
        guard let newOutput = newOutputs.first else {
            return
        }
        XCTAssertEqual(
            newOutput.classification,
            "livePhoto",
            "QA-08 must recover a complete Live Photo output."
        )
        XCTAssertTrue(
            newOutput.resources.contains(where: { $0.type == "pairedVideo" }),
            "QA-08 recovered output must keep its paired motion resource."
        )
        guard let preservedInput = inputAfter.assets.first(where: {
            $0.localIdentifier == livePhotoInput.localIdentifier
        }) else {
            XCTFail("The QA-08 Live Photo input disappeared after restart recovery.")
            return
        }
        XCTAssertEqual(
            preservedInput.classification,
            "livePhoto",
            "The QA-08 restart changed the original Live Photo classification."
        )
        XCTAssertTrue(
            preservedInput.resources.contains(where: { $0.type == "pairedVideo" }),
            "The QA-08 restart removed the original paired motion resource."
        )

        let evidence = QA08RecoveryEvidence(
            inputLocalIdentifier: livePhotoInput.localIdentifier,
            outputLocalIdentifier: newOutput.localIdentifier,
            inputClassification: livePhotoInput.classification,
            outputClassification: newOutput.classification,
            inputPixelWidth: livePhotoInput.pixelWidth,
            inputPixelHeight: livePhotoInput.pixelHeight,
            outputPixelWidth: newOutput.pixelWidth,
            outputPixelHeight: newOutput.pixelHeight,
            pickerSelectionIndex: selectionIndex,
            outputCountBefore: outputBefore.assetCount,
            outputCountAtTermination: outputCountAtTermination,
            outputCountAfterRelaunch: outputCountAfterRelaunch,
            controlledTermination: true,
            originalPreserved: true,
            duplicateOutput: false
        )
        let data = try JSONEncoder().encode(evidence)
        let attachment = XCTAttachment(
            data: data,
            uniformTypeIdentifier: "public.json"
        )
        attachment.name = "qa-08-live-photo-recovery-evidence.json"
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    func testMemoMarkQA04LivePhotoOutputReadbackAndOriginalPreservation() throws {
        let inputInventory = try inventoryAlbum(
            titled: "MemoMark QA Inputs",
            attachmentName: "qa-04-inputs-readback.json"
        )
        let outputInventory = try inventoryAlbum(
            titled: "MemoMark QA Outputs",
            attachmentName: "qa-04-outputs-readback.json"
        )

        let inputLivePhotos = inputInventory.assets.filter {
            $0.classification == "livePhoto"
        }
        let outputLivePhotos = outputInventory.assets.filter {
            $0.classification == "livePhoto"
        }

        XCTAssertFalse(
            inputLivePhotos.isEmpty,
            "QA-04 requires at least one complete Live Photo input."
        )
        XCTAssertFalse(
            outputLivePhotos.isEmpty,
            "QA-04 requires at least one complete Live Photo output."
        )

        let matches = outputLivePhotos.compactMap { output -> QA04ReadbackMatch? in
            guard let outputCaptureDate = Self.date(from: output.creationDate) else {
                return nil
            }

            let candidates = inputLivePhotos.filter { input in
                guard let inputCaptureDate = Self.date(from: input.creationDate) else {
                    return false
                }
                return abs(outputCaptureDate.timeIntervalSince(inputCaptureDate)) <= 1
                    && Self.resourceStem(for: output) == Self.resourceStem(for: input)
            }

            guard let input = candidates.first else {
                return nil
            }
            return QA04ReadbackMatch(input: input, output: output)
        }

        XCTAssertFalse(
            matches.isEmpty,
            "No Live Photo output could be paired with a Live Photo input by capture date and resource stem."
        )

        guard let match = matches.first else {
            return
        }

        XCTAssertNotEqual(
            match.input.localIdentifier,
            match.output.localIdentifier,
            "MemoMark must save a new PhotoKit asset and must not mutate the input asset."
        )
        XCTAssertEqual(
            match.input.classification,
            "livePhoto",
            "The original input must remain a complete Live Photo."
        )
        XCTAssertEqual(
            match.output.classification,
            "livePhoto",
            "The saved output must remain a complete Live Photo."
        )
        XCTAssertTrue(
            match.input.resources.contains(where: { $0.type == "pairedVideo" }),
            "The original input no longer exposes its paired motion resource."
        )
        XCTAssertTrue(
            match.output.resources.contains(where: { $0.type == "pairedVideo" }),
            "The saved output does not expose a paired motion resource."
        )

        if let inputCaptureDate = Self.date(from: match.input.creationDate),
           let outputCaptureDate = Self.date(from: match.output.creationDate) {
            XCTAssertEqual(
                outputCaptureDate.timeIntervalSince(inputCaptureDate),
                0,
                accuracy: 1,
                "The saved output did not retain the input capture date."
            )
        } else {
            XCTFail("QA-04 requires capture dates on both the input and output assets.")
        }

        let readback = QA04ReadbackEvidence(
            inputLocalIdentifier: match.input.localIdentifier,
            outputLocalIdentifier: match.output.localIdentifier,
            inputClassification: match.input.classification,
            outputClassification: match.output.classification,
            inputPixelWidth: match.input.pixelWidth,
            inputPixelHeight: match.input.pixelHeight,
            outputPixelWidth: match.output.pixelWidth,
            outputPixelHeight: match.output.pixelHeight,
            inputCaptureDate: match.input.creationDate,
            outputCaptureDate: match.output.creationDate,
            inputResourceTypes: match.input.resources.map(\.type),
            outputResourceTypes: match.output.resources.map(\.type)
        )
        let data = try JSONEncoder().encode(readback)
        let attachment = XCTAttachment(
            data: data,
            uniformTypeIdentifier: "public.json"
        )
        attachment.name = "qa-04-live-photo-readback-evidence.json"
        attachment.lifetime = .keepAlways
        add(attachment)

        print(
            "MemoMark QA-04 readback: input=\(match.input.localIdentifier), output=\(match.output.localIdentifier), source=\(Self.resourceStem(for: match.input) ?? "nil"), captureDatePreserved=true, inputLivePhoto=true, outputLivePhoto=true"
        )
    }

    private func inventoryAlbum(
        titled albumTitle: String,
        attachmentName: String
    ) throws -> QAAlbumInventory {
        let authorizationStatus = requestPhotoLibraryAccessIfNeeded()
        XCTAssertTrue(
            authorizationStatus == .authorized
                || authorizationStatus == .limited,
            "Photo library access is not available for the QA inventory: \(authorizationStatusDescription(authorizationStatus))"
        )

        let albums = PHAssetCollection.fetchAssetCollections(
            with: .album,
            subtype: .albumRegular,
            options: nil
        )

        var matchedAlbum: PHAssetCollection?
        albums.enumerateObjects { album, _, stop in
            guard album.localizedTitle == albumTitle else {
                return
            }

            matchedAlbum = album
            stop.pointee = true
        }

        guard let matchedAlbum else {
            XCTFail("The PhotoKit album was not found: \(albumTitle)")
            throw QAInventoryError.albumNotFound(albumTitle)
        }

        let options = PHFetchOptions()
        options.sortDescriptors = [
            NSSortDescriptor(
                key: #keyPath(PHAsset.creationDate),
                ascending: true
            )
        ]

        let assets = PHAsset.fetchAssets(
            in: matchedAlbum,
            options: options
        )
        var inventoryAssets: [QAAlbumInventoryAsset] = []
        inventoryAssets.reserveCapacity(assets.count)

        assets.enumerateObjects { asset, _, _ in
            inventoryAssets.append(
                QAAlbumInventoryAsset(
                    localIdentifier: asset.localIdentifier,
                    originalAssetIdentifier: asset.localIdentifier,
                    classification: Self.classification(for: asset),
                    mediaType: Self.mediaTypeDescription(asset.mediaType),
                    mediaSubtypes: Self.mediaSubtypeDescriptions(asset.mediaSubtypes),
                    pixelWidth: asset.pixelWidth,
                    pixelHeight: asset.pixelHeight,
                    duration: asset.duration,
                    creationDate: Self.iso8601String(asset.creationDate),
                    modificationDate: Self.iso8601String(asset.modificationDate),
                    resources: PHAssetResource.assetResources(for: asset).map {
                        QAAlbumInventoryResource(
                            type: Self.resourceTypeDescription($0.type),
                            originalFilename: $0.originalFilename,
                            uniformTypeIdentifier: $0.uniformTypeIdentifier
                        )
                    }
                )
            )
        }

        let inventory = QAAlbumInventory(
            albumTitle: albumTitle,
            albumLocalIdentifier: matchedAlbum.localIdentifier,
            authorization: authorizationStatusDescription(authorizationStatus),
            assetCount: inventoryAssets.count,
            assets: inventoryAssets
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(inventory)
        let attachment = XCTAttachment(
            data: data,
            uniformTypeIdentifier: "public.json"
        )
        attachment.name = attachmentName
        attachment.lifetime = .keepAlways
        add(attachment)

        print(
            "MemoMark PhotoKit inventory: album=\(albumTitle), assets=\(inventoryAssets.count), authorization=\(authorizationStatusDescription(authorizationStatus))"
        )

        return inventory
    }

    private func launchHostAndWait() {
        application.launch()

        XCTAssertTrue(
            application.wait(
                for: .runningForeground,
                timeout: 30
            ),
            "MemoMarkiOS did not reach the foreground within the device QA timeout."
        )
    }

    private func prepareSubjectEditor() {
        completeFirstRunConfigurationIfNeeded()

        let homeTab = application.buttons["house.fill"]
        if homeTab.waitForExistence(timeout: 10), !homeTab.isSelected {
            homeTab.tap()
        }

        let subjectEntry = application.buttons["subject-home-entry"]
        XCTAssertTrue(
            subjectEntry.waitForExistence(timeout: 20),
            "The home page did not expose the Subject entry for UI testing."
        )
        subjectEntry.tap()

        let subjectOverview = application
            .descendants(matching: .any)
            .matching(identifier: "subject-overview")
            .firstMatch
        XCTAssertTrue(
            subjectOverview.waitForExistence(timeout: 20),
            "The Subject overview did not open."
        )

        let editButton = application.buttons["subject-edit"]
        XCTAssertTrue(
            editButton.waitForExistence(timeout: 20),
            "The Subject overview did not expose its edit action."
        )
        editButton.tap()
    }

    private func completeFirstRunConfigurationIfNeeded() {
        let startButton = application.buttons["开始使用"]
        if startButton.waitForExistence(timeout: 5) {
            startButton.tap()
        }

        let subjectField = application.textFields["对象名称，必填"]
        guard subjectField.waitForExistence(timeout: 10) else {
            return
        }

        subjectField.tap()
        subjectField.typeText("自动化对象")

        let completeButton = application.buttons["完成设置"]
        XCTAssertTrue(
            completeButton.waitForExistence(timeout: 10),
            "The first-run configuration sheet did not expose completion."
        )
        completeButton.tap()

        XCTAssertTrue(
            application.buttons["subject-home-entry"]
                .waitForExistence(timeout: 30),
            "The first-run configuration did not return to the Subject home entry."
        )
    }

    private func assertNonOverlappingFrames(
        for elements: XCUIElementQuery,
        context: String,
        allowedOverlap: CGFloat = 1
    ) {
        var frames: [CGRect] = []
        frames.reserveCapacity(elements.count)

        for index in 0 ..< elements.count {
            let element = elements.element(boundBy: index)
            XCTAssertTrue(
                element.exists,
                "The \(context) element at index \(index) disappeared."
            )
            frames.append(element.frame)
        }

        let sortedFrames = frames.sorted {
            if $0.minY == $1.minY {
                return $0.minX < $1.minX
            }
            return $0.minY < $1.minY
        }

        for pair in zip(sortedFrames, sortedFrames.dropFirst()) {
            XCTAssertGreaterThanOrEqual(
                pair.1.minY,
                pair.0.maxY - allowedOverlap,
                "The \(context) contain overlapping accessibility frames: \(pair.0) and \(pair.1)."
            )
        }
    }

    private func openSettingsFromHome() {
        if application.navigationBars["设置"].exists
            || application.navigationBars["設定"].exists
            || application.navigationBars["설정"].exists
            || application.navigationBars["Settings"].exists {
            return
        }

        let homeTab = application.buttons["house.fill"]
        if homeTab.waitForExistence(timeout: 10), !homeTab.isSelected {
            homeTab.tap()
        }

        let settingsLabels = [
            "打开设置",
            "設定を開く",
            "설정 열기",
            "Open Settings"
        ]
        var didOpenSettings = false
        for label in settingsLabels {
            let settingsButton = application.buttons[label]
            if settingsButton.waitForExistence(timeout: 3) {
                settingsButton.tap()
                didOpenSettings = true
                break
            }
        }
        XCTAssertTrue(
            didOpenSettings,
            "The home surface did not expose a localized Settings action."
        )
        XCTAssertTrue(
            application.navigationBars["设置"].waitForExistence(timeout: 20)
                || application.navigationBars["設定"].waitForExistence(timeout: 5)
                || application.navigationBars["설정"].waitForExistence(timeout: 5)
                || application.navigationBars["Settings"].waitForExistence(timeout: 5),
            "The iOS host did not reach a localized Settings surface from Home."
        )
    }

    private func restoreSimplifiedChineseInterfaceIfNeeded() {
        if application.navigationBars["设置"].exists {
            return
        }

        if application.navigationBars["設定"].exists {
            selectInterfaceLanguage(
                option: "简体中文",
                sectionTitle: "インターフェース"
            )
        } else if application.navigationBars["설정"].exists {
            selectInterfaceLanguage(
                option: "简体中文",
                sectionTitle: "인터페이스"
            )
        } else if application.navigationBars["Settings"].exists {
            selectInterfaceLanguage(
                option: "简体中文",
                sectionTitle: "Interface"
            )
        }

        XCTAssertTrue(
            application.navigationBars["设置"].waitForExistence(timeout: 20)
                || application.staticTexts["设置"].waitForExistence(timeout: 5),
            "The interface language could not be normalized to Simplified Chinese."
        )
    }

    private func selectInterfaceLanguage(
        option: String,
        sectionTitle: String
    ) {
        let section = application.buttons[sectionTitle]
        XCTAssertTrue(
            section.waitForExistence(timeout: 20),
            "The interface-language Settings section was not exposed: \(sectionTitle)"
        )

        if !application.buttons[option].exists
            && !application.segmentedControls.buttons[option].exists
            && !application.staticTexts[option].exists {
            section.tap()
        }

        let optionButton: XCUIElement
        if application.buttons[option].exists {
            optionButton = application.buttons[option].firstMatch
        } else if application.segmentedControls.buttons[option].exists {
            optionButton = application.segmentedControls.buttons[option].firstMatch
        } else {
            optionButton = application.staticTexts[option].firstMatch
        }
        XCTAssertTrue(
            optionButton.waitForExistence(timeout: 20),
            "The interface-language option was not exposed: \(option)"
        )
        optionButton.tap()

        // AppStorage updates the interface language in place. The next
        // localized section lookup provides the settling point.
    }

    private func attachCurrentScreenshot(named name: String) {
        let screenshot = XCTAttachment(screenshot: application.screenshot())
        screenshot.name = name
        screenshot.lifetime = .keepAlways
        add(screenshot)
    }

    private func preparedInputPhotoGridImages() -> XCUIElementQuery {
        openPreparedInputAlbum()

        let photoGridImages = application.images
            .matching(identifier: "PXGGridLayout-Info")
            .matching(
                NSPredicate(
                    format: "label BEGINSWITH %@",
                    "照片"
                )
            )
        XCTAssertGreaterThan(
            photoGridImages.count,
            0,
            "The prepared input album did not expose a selectable still-photo grid."
        )
        return photoGridImages
    }

    private func preparedInputPhotoGridCells() -> XCUIElementQuery {
        openPreparedInputAlbum()

        let gridCells = application.images.matching(
            identifier: "PXGGridLayout-Info"
        )
        XCTAssertGreaterThan(
            gridCells.count,
            0,
            "The prepared input album did not expose selectable photo grid cells."
        )
        return gridCells
    }

    /// Finds a Live Photo by the system picker's semantic accessibility label
    /// instead of assuming that PHPicker's lazily-loaded visual order matches
    /// PhotoKit's fetch order. The latter is not a stable contract and caused
    /// valid Live Photos near the end of the QA album to be skipped.
    private func selectPreparedLivePhotoCell() -> Int? {
        let gridCells = preparedInputPhotoGridCells()
        let livePhotoMarkers = [
            "实况",
            "Live Photo",
            "Live"
        ]

        for pass in 0..<20 {
            let visibleCellCount = gridCells.count
            if pass < 3 {
                print(
                    "MemoMark QA Live Photo picker pass=\(pass) visibleCellCount=\(visibleCellCount)"
                )
            }
            for index in 0..<visibleCellCount {
                let cell = gridCells.element(boundBy: index)
                // PHPicker virtualizes its grid as it settles. A count taken
                // one accessibility snapshot earlier does not guarantee that
                // the same indexed cell is still retained in the next one.
                // Skip a reclaimed entry and continue the bounded search;
                // never let diagnostic enumeration fail the media scenario.
                guard cell.exists else {
                    continue
                }
                let label = cell.label
                if livePhotoMarkers.contains(where: {
                    label.localizedCaseInsensitiveContains($0)
                }) {
                    print(
                        "MemoMark QA selected Live Photo picker cell index=\(index), label=\(label), hittable=\(cell.isHittable), frame=\(cell.frame)"
                    )
                    print("MemoMark QA Live Photo accessibility cell=\(cell.debugDescription)")
                    // On some iOS releases the accessibility image is a
                    // child of the selectable button. Prefer that button so
                    // the picker records the selection (tapping the child
                    // alone can leave 完成 disabled for Live Photos).
                    let selectableCell = application.cells.matching(
                        NSPredicate(format: "label == %@", label)
                    ).firstMatch
                    let selectableButton = application.buttons.matching(
                        NSPredicate(format: "label == %@", label)
                    ).firstMatch
                    // Prefer a hittable selectable ancestor. `exists` alone
                    // is insufficient in PHPicker: it can retain an
                    // off-screen accessibility node while the visible tile
                    // has already moved to a different reuse cell. Tapping
                    // that stale node reports success to XCTest but does not
                    // change the picker's selection state.
                    if selectableButton.exists && selectableButton.isHittable {
                        selectableButton.tap()
                    } else if selectableCell.exists && selectableCell.isHittable {
                        selectableCell.tap()
                    } else {
                        cell.tap()
                        // PHPicker's image node is sometimes exposed as a
                        // non-selectable accessibility child. A centered
                        // coordinate tap targets the tile's hit region while
                        // retaining the semantic lookup above.
                        if !cell.isHittable {
                            cell.coordinate(
                                withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)
                            ).tap()
                        }
                    }
                    let completion = application.buttons["完成"]
                    if pickerCompletionIsEnabled(completion, timeout: 1.5) {
                        return index
                    }

                    // A Live Photo tile can expose its image and selectable
                    // ancestor in separate accessibility transactions. Retry
                    // exactly once against the currently visible tile, then
                    // accept the candidate only after PHPicker confirms the
                    // selection by enabling its completion control. This
                    // avoids returning a false-positive selection index.
                    if cell.isHittable {
                        cell.coordinate(
                            withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)
                        ).tap()
                    }
                    if pickerCompletionIsEnabled(completion, timeout: 1.5) {
                        return index
                    }

                    print(
                        "MemoMark QA Live Photo picker cell did not enable completion; continuing bounded search."
                    )
                }
            }

            // PHPicker virtualizes the grid. Swiping advances the visible
            // window, after which the same query resolves the newly visible
            // cells without relying on a private Photos ordering detail.
            application.swipeUp()
            RunLoop.current.run(
                until: Date().addingTimeInterval(0.25)
            )
        }

        return nil
    }

    private func waitForPickerCompletionEnabled(
        _ doneButton: XCUIElement,
        timeout: TimeInterval = 10
    ) {
        let deadline = Date().addingTimeInterval(timeout)
        while !doneButton.isEnabled, Date() < deadline {
            RunLoop.current.run(
                until: Date().addingTimeInterval(0.25)
            )
        }
    }

    private func pickerCompletionIsEnabled(
        _ doneButton: XCUIElement,
        timeout: TimeInterval
    ) -> Bool {
        guard doneButton.waitForExistence(timeout: timeout) else {
            return false
        }
        let deadline = Date().addingTimeInterval(timeout)
        while !doneButton.isEnabled, Date() < deadline {
            RunLoop.current.run(
                until: Date().addingTimeInterval(0.25)
            )
        }
        return doneButton.isEnabled
    }

    private func assertSubsequentLaunchesDoNotDuplicateOutput(
        expectedOutputCount: Int,
        scenario: String,
        additionalLaunches: Int = 2
    ) {
        for launchIndex in 1...additionalLaunches {
            application.terminate()
            XCTAssertTrue(
                application.wait(for: .notRunning, timeout: 20),
                "\(scenario) additional restart \(launchIndex) did not terminate the host."
            )

            application.launch()
            XCTAssertTrue(
                application.wait(for: .runningForeground, timeout: 30),
                "\(scenario) additional restart \(launchIndex) did not relaunch the host."
            )

            let deadline = Date().addingTimeInterval(15)
            var observedOutputCount = albumAssetCount(
                titled: "MemoMark QA Outputs"
            )
            while Date() < deadline,
                  observedOutputCount < expectedOutputCount {
                RunLoop.current.run(
                    until: Date().addingTimeInterval(1)
                )
                observedOutputCount = albumAssetCount(
                    titled: "MemoMark QA Outputs"
                )
            }
            XCTAssertEqual(
                observedOutputCount,
                expectedOutputCount,
                "\(scenario) additional restart \(launchIndex) changed the output count."
            )
        }
    }

    private func openPreparedInputAlbum() {
        launchHostAndWait()

        // The selected tab survives a signed-device relaunch. Always return
        // to the production home surface before opening the picker so a
        // previous Configuration Center test cannot leave this flow in an
        // unrelated tab.
        let homeTab = application.buttons["house.fill"]
        if homeTab.waitForExistence(timeout: 10), !homeTab.isSelected {
            homeTab.tap()
        }

        let pickerButton = application.buttons["home-photo-picker"].exists
            ? application.buttons["home-photo-picker"]
            : application.buttons["App 内选择照片"]
        XCTAssertTrue(
            pickerButton.waitForExistence(timeout: 20),
            "The iOS home page did not expose the in-app photo picker."
        )
        pickerButton.tap()

        openPreparedInputAlbumFromCurrentPicker()
    }

    private func openPreparedInputAlbumFromCurrentPicker() {
        // On iOS 27, the system PHPicker may expose 照片/精选集 as segments of
        // a segmented control. The picker can also restore the last library
        // location and open directly in the album, in which case neither
        // segment is present. Treat the segment as an optional navigation
        // affordance and make the album the actual readiness gate.
        let curatedSegment = application.segmentedControls.buttons["精选集"]
        if curatedSegment.waitForExistence(timeout: 20) {
            curatedSegment.tap()
        } else {
            let legacyCuratedButton = application.buttons["精选集"]
            if legacyCuratedButton.waitForExistence(timeout: 5) {
                legacyCuratedButton.tap()
            } else {
                print(
                    "MemoMark QA picker restored a direct library location; skipping optional 精选集 segment."
                )
            }
        }

        let qaAlbum = application.buttons["MemoMark QA Inputs"]
        XCTAssertTrue(
            qaAlbum.waitForExistence(timeout: 20),
            "The system photo picker did not expose the prepared QA input album."
        )
        qaAlbum.tap()
    }

    private func albumAssetCount(titled albumTitle: String) -> Int {
        let albums = PHAssetCollection.fetchAssetCollections(
            with: .album,
            subtype: .albumRegular,
            options: nil
        )
        var matchedAlbum: PHAssetCollection?
        albums.enumerateObjects { album, _, stop in
            guard album.localizedTitle == albumTitle else {
                return
            }
            matchedAlbum = album
            stop.pointee = true
        }
        guard let matchedAlbum else {
            return 0
        }
        return PHAsset.fetchAssets(
            in: matchedAlbum,
            options: nil
        ).count
    }

    private func requestPhotoLibraryAccessIfNeeded() -> PHAuthorizationStatus {
        let currentStatus = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        guard currentStatus == .notDetermined else {
            return currentStatus
        }

        let authorizationExpectation = expectation(
            description: "Photo library authorization request completes"
        )
        var resolvedStatus = currentStatus
        PHPhotoLibrary.requestAuthorization(for: .readWrite) { status in
            resolvedStatus = status
            authorizationExpectation.fulfill()
        }
        wait(
            for: [authorizationExpectation],
            timeout: 30
        )
        return resolvedStatus
    }

    private static func classification(for asset: PHAsset) -> String {
        let resources = PHAssetResource.assetResources(for: asset)
        let resourceUTIs = resources.map(\.uniformTypeIdentifier)
        let isLivePhoto = asset.mediaSubtypes.contains(.photoLive)

        if isLivePhoto {
            return resources.contains(where: { $0.type == .pairedVideo })
                ? "livePhoto"
                : "livePhotoMissingPairedVideo"
        }

        if asset.mediaType == .image {
            let primaryPhotoUTI = resources
                .first(where: { $0.type == .photo })?
                .uniformTypeIdentifier

            if primaryPhotoUTI == "public.jpeg" {
                return "jpegStill"
            }

            if primaryPhotoUTI == "public.heic"
                || primaryPhotoUTI == "public.heif" {
                return "heicStill"
            }

            if primaryPhotoUTI == "com.adobe.raw-image",
               resourceUTIs.contains(where: { $0 == "public.jpeg" }) {
                return "rawWithJPEGRepresentation"
            }

            return "imageOther"
        }

        if asset.mediaType == .video {
            return "video"
        }

        return "other"
    }

    private static func mediaTypeDescription(
        _ mediaType: PHAssetMediaType
    ) -> String {
        switch mediaType {
        case .image:
            return "image"
        case .video:
            return "video"
        case .audio:
            return "audio"
        case .unknown:
            return "unknown"
        @unknown default:
            return "unknown"
        }
    }

    private static func mediaSubtypeDescriptions(
        _ subtypes: PHAssetMediaSubtype
    ) -> [String] {
        var descriptions: [String] = []
        if subtypes.contains(.photoPanorama) {
            descriptions.append("photoPanorama")
        }
        if subtypes.contains(.photoHDR) {
            descriptions.append("photoHDR")
        }
        if subtypes.contains(.photoScreenshot) {
            descriptions.append("photoScreenshot")
        }
        if subtypes.contains(.photoLive) {
            descriptions.append("photoLive")
        }
        if subtypes.contains(.photoDepthEffect) {
            descriptions.append("photoDepthEffect")
        }
        if subtypes.contains(.videoStreamed) {
            descriptions.append("videoStreamed")
        }
        if subtypes.contains(.videoHighFrameRate) {
            descriptions.append("videoHighFrameRate")
        }
        if subtypes.contains(.videoTimelapse) {
            descriptions.append("videoTimelapse")
        }
        return descriptions
    }

    private static func resourceTypeDescription(
        _ type: PHAssetResourceType
    ) -> String {
        if type == .photo {
            return "photo"
        }
        if type == .fullSizePhoto {
            return "fullSizePhoto"
        }
        if type == .video {
            return "video"
        }
        if type == .fullSizeVideo {
            return "fullSizeVideo"
        }
        if type == .pairedVideo {
            return "pairedVideo"
        }
        if type == .alternatePhoto {
            return "alternatePhoto"
        }
        if type == .adjustmentData {
            return "adjustmentData"
        }
        if type == .adjustmentBasePhoto {
            return "adjustmentBasePhoto"
        }
        return "other"
    }

    private static func iso8601String(_ date: Date?) -> String? {
        guard let date else {
            return nil
        }
        return ISO8601DateFormatter().string(from: date)
    }

    private static func date(from value: String?) -> Date? {
        guard let value else {
            return nil
        }
        return ISO8601DateFormatter().date(from: value)
    }

    private static func resourceStem(
        for asset: QAAlbumInventoryAsset
    ) -> String? {
        guard let resource = asset.resources.first(where: {
            $0.type == "photo" || $0.type == "fullSizePhoto"
        }) else {
            return nil
        }

        let baseName = URL(fileURLWithPath: resource.originalFilename)
            .deletingPathExtension()
            .lastPathComponent
        let normalized = baseName.replacingOccurrences(
            of: #"\s+\(\d+\)$"#,
            with: "",
            options: .regularExpression
        )
        return normalized.lowercased()
    }

    private func authorizationStatusDescription(
        _ status: PHAuthorizationStatus
    ) -> String {
        switch status {
        case .notDetermined:
            return "notDetermined"
        case .restricted:
            return "restricted"
        case .denied:
            return "denied"
        case .authorized:
            return "authorized"
        case .limited:
            return "limited"
        @unknown default:
            return "unknown"
        }
    }

    private enum QAInventoryError: Error {
        case albumNotFound(String)
    }

    private struct QAAlbumInventory: Codable {
        let albumTitle: String
        let albumLocalIdentifier: String
        let authorization: String
        let assetCount: Int
        let assets: [QAAlbumInventoryAsset]
    }

    private struct QAAlbumInventoryAsset: Codable {
        let localIdentifier: String
        let originalAssetIdentifier: String
        let classification: String
        let mediaType: String
        let mediaSubtypes: [String]
        let pixelWidth: Int
        let pixelHeight: Int
        let duration: TimeInterval
        let creationDate: String?
        let modificationDate: String?
        let resources: [QAAlbumInventoryResource]
    }

    private struct QAAlbumInventoryResource: Codable {
        let type: String
        let originalFilename: String
        let uniformTypeIdentifier: String
    }

    private struct QA04ReadbackMatch {
        let input: QAAlbumInventoryAsset
        let output: QAAlbumInventoryAsset
    }

    private struct QA04ReadbackEvidence: Codable {
        let inputLocalIdentifier: String
        let outputLocalIdentifier: String
        let inputClassification: String
        let outputClassification: String
        let inputPixelWidth: Int
        let inputPixelHeight: Int
        let outputPixelWidth: Int
        let outputPixelHeight: Int
        let inputCaptureDate: String?
        let outputCaptureDate: String?
        let inputResourceTypes: [String]
        let outputResourceTypes: [String]
    }

    private struct QA05ProcessingEvidence: Codable {
        let inputLocalIdentifier: String
        let outputLocalIdentifier: String
        let inputClassification: String
        let outputClassification: String
        let inputPixelWidth: Int
        let inputPixelHeight: Int
        let outputPixelWidth: Int
        let outputPixelHeight: Int
        let outputCountBefore: Int
        let outputCountAfter: Int
    }

    private struct QA02ProcessingEvidence: Codable {
        let inputLocalIdentifier: String
        let outputLocalIdentifier: String
        let inputClassification: String
        let outputClassification: String
        let inputPixelWidth: Int
        let inputPixelHeight: Int
        let outputPixelWidth: Int
        let outputPixelHeight: Int
        let pickerSelectionIndex: Int
        let outputCountBefore: Int
        let outputCountAfter: Int
    }

    private struct QA04ProcessingEvidence: Codable {
        let inputLocalIdentifier: String
        let outputLocalIdentifier: String
        let inputClassification: String
        let outputClassification: String
        let inputPixelWidth: Int
        let inputPixelHeight: Int
        let outputPixelWidth: Int
        let outputPixelHeight: Int
        let inputCaptureDate: String?
        let outputCaptureDate: String?
        let inputResourceTypes: [String]
        let outputResourceTypes: [String]
        let pickerSelectionIndex: Int
        let outputCountBefore: Int
        let outputCountAfter: Int
    }

    private struct QA07RecoveryEvidence: Codable {
        let inputLocalIdentifier: String
        let outputLocalIdentifier: String
        let inputClassification: String
        let outputClassification: String
        let inputPixelWidth: Int
        let inputPixelHeight: Int
        let outputPixelWidth: Int
        let outputPixelHeight: Int
        let pickerSelectionIndex: Int
        let outputCountBefore: Int
        let outputCountAtTermination: Int
        let outputCountAfterRelaunch: Int
        let controlledTermination: Bool
        let originalPreserved: Bool
        let duplicateOutput: Bool
    }

    private struct QA08RecoveryEvidence: Codable {
        let inputLocalIdentifier: String
        let outputLocalIdentifier: String
        let inputClassification: String
        let outputClassification: String
        let inputPixelWidth: Int
        let inputPixelHeight: Int
        let outputPixelWidth: Int
        let outputPixelHeight: Int
        let pickerSelectionIndex: Int
        let outputCountBefore: Int
        let outputCountAtTermination: Int
        let outputCountAfterRelaunch: Int
        let controlledTermination: Bool
        let originalPreserved: Bool
        let duplicateOutput: Bool
    }

    private struct QAInputMediaMatrixEvidence: Codable {
        let albumTitle: String
        let assetCount: Int
        let classifications: [String]
        let rawHighestQualityInputAvailable: Bool
        let exact48MPPixelAreaAvailable: Bool
        let maxRawPixelArea: Int64
        let rawHighestQualityAssets: [QAInputHighResolutionAsset]
    }

    private struct QAInputHighResolutionAsset: Codable {
        let localIdentifier: String
        let classification: String
        let pixelWidth: Int
        let pixelHeight: Int
        let pixelArea: Int64
    }
}

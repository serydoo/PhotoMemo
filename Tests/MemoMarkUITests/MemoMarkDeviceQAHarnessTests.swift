import Foundation
import CryptoKit
import Photos
import ImageIO
import AVFoundation
import XCTest
import UIKit

final class MemoMarkDeviceQAHarnessTests: XCTestCase {

    private var application: XCUIApplication!
    private var assistiveTouchWasMovedForShare = false

    override func setUpWithError() throws {
        continueAfterFailure = false

        application = XCUIApplication()
        application.launchArguments = [
            "-uiTesting",
            "-uiTestingHarnessOnly"
        ]
    }

    func testSourceVersionProbe() throws {
        application.launchArguments += ["-processingSourceVersionProbe"]
        application.launch()
        XCTAssertTrue(application.wait(for: .runningForeground, timeout: 30))
        let observation = expectation(description: "Read source versions for the prepared QA album")
        DispatchQueue.main.asyncAfter(deadline: .now() + 12) { observation.fulfill() }
        wait(for: [observation], timeout: 15)
        XCUIDevice.shared.press(.home)
    }

    func testRootReliabilitySnapshot() throws {
        application.launchArguments += ["-disableContinuedProcessingSpike", "-processingReliabilityDiagnostics"]
        application.launch()
        XCTAssertTrue(application.wait(for: .runningForeground, timeout: 30))
        let observation = expectation(description: "Read latest durable configuration diagnostics")
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) { observation.fulfill() }
        wait(for: [observation], timeout: 8)
        XCUIDevice.shared.press(.home)
    }

    func testFreshInstallEmptyQueueBaseline() throws {
        application.launchArguments += ["-disableContinuedProcessingSpike"]
        launchHostAndWait()
        completeFirstRunConfigurationIfNeeded()
        attachCurrentScreenshot(named: "fresh-install-home-baseline")
        let hierarchy = XCTAttachment(string: application.debugDescription)
        hierarchy.name = "fresh-install-home-hierarchy"
        hierarchy.lifetime = .keepAlways
        add(hierarchy)
        XCTAssertFalse(application.descendants(matching: .any).matching(identifier: "task-processing-card").firstMatch.exists)
        XCUIDevice.shared.press(.home)
        let outputs = try inventoryAlbum(titled: "MemoMark QA Outputs", attachmentName: "fresh-install-output-baseline.json")
        XCTAssertEqual(outputs.assetCount, 0)
    }

    func testQAInputsEditingRecipeAudit() throws {
        let inventory = try inventoryAlbum(titled: "MemoMark QA Inputs", attachmentName: "recipe-input-inventory.json")
        for (index, row) in inventory.assets.enumerated() {
            let asset = try XCTUnwrap(PHAsset.fetchAssets(withLocalIdentifiers: [row.localIdentifier], options: nil).firstObject)
            let options = PHContentEditingInputRequestOptions()
            options.isNetworkAccessAllowed = false
            options.canHandleAdjustmentData = { _ in true }
            let ready = expectation(description: "Read local editing recipe")
            asset.requestContentEditingInput(with: options) { input, _ in
                let report: [String: Any] = [
                    "sourceIdentifier": row.localIdentifier,
                    "creation": asset.creationDate?.timeIntervalSince1970 ?? 0,
                    "modification": asset.modificationDate?.timeIntervalSince1970 ?? 0,
                    "width": asset.pixelWidth, "height": asset.pixelHeight,
                    "subtypes": asset.mediaSubtypes.rawValue,
                    "inputAvailable": input != nil,
                    "format": input?.adjustmentData?.formatIdentifier ?? "",
                    "version": input?.adjustmentData?.formatVersion ?? "",
                    "recipe": input?.adjustmentData?.data.base64EncodedString() ?? ""
                ]
                if let data = try? JSONSerialization.data(withJSONObject: report, options: [.sortedKeys]) {
                    let attachment = XCTAttachment(data: data, uniformTypeIdentifier: "public.json")
                    attachment.name = "recipe-input-\(index).json"
                    attachment.lifetime = .keepAlways
                    self.add(attachment)
                }
                ready.fulfill()
            }
            wait(for: [ready], timeout: 15)
            if let resource = PHAssetResource.assetResources(for: asset).first(where: { $0.type == .adjustmentData }) {
                let received = expectation(description: "Read adjustment data independently of movie availability")
                let options = PHAssetResourceRequestOptions()
                options.isNetworkAccessAllowed = false
                let buffer = NSMutableData()
                PHAssetResourceManager.default().requestData(for: resource, options: options, dataReceivedHandler: { data in
                    buffer.append(data)
                }, completionHandler: { error in
                    let report: [String: Any] = ["sourceIdentifier": row.localIdentifier,
                        "recipe": (buffer as Data).base64EncodedString(),
                        "error": error.map { String(describing: $0) } ?? ""]
                    if let data = try? JSONSerialization.data(withJSONObject: report, options: [.sortedKeys]) {
                        let attachment = XCTAttachment(data: data, uniformTypeIdentifier: "public.json")
                        attachment.name = "resource-recipe-input-\(index).json"
                        attachment.lifetime = .keepAlways
                        self.add(attachment)
                    }
                    received.fulfill()
                })
                wait(for: [received], timeout: 15)
            }
        }
    }

    func testContinuedFormalHostForegroundControl() throws {
        application.launchArguments += ["-disableContinuedProcessingSpike", "-continuedFormalHostForegroundControl"]
        application.launch()
        XCTAssertTrue(application.wait(for: .runningForeground, timeout: 30))
        let observation = expectation(description: "Observe formal host scheduler callback independently")
        DispatchQueue.main.asyncAfter(deadline: .now() + 12) { observation.fulfill() }
        wait(for: [observation], timeout: 15)
        // Launch is only the stimulus. Read host.continuedQueueCallback from
        // App Group without relaunching to certify the exact registered entry.
        XCUIDevice.shared.press(.home)
    }

    func testContinuedFormalHostUniqueForegroundControl() throws {
        application.launchArguments += ["-continuedFormalHostUniqueIdentifierControl"]
        try testContinuedFormalHostForegroundControl()
    }

    func testContinuedProcessingForegroundMarkerControl() throws {
        application.launchArguments += ["-continuedProcessingForegroundProbe"]
        application.launch()
        XCTAssertTrue(application.wait(for: .runningForeground, timeout: 30))
        let observation = expectation(description: "Allow independent marker callback evidence")
        DispatchQueue.main.asyncAfter(deadline: .now() + 12) { observation.fulfill() }
        wait(for: [observation], timeout: 15)
        // UI launch is only the control stimulus; App Group acknowledgement
        // is the independent acceptance gate, read without another launch.
        XCUIDevice.shared.press(.home)
    }

    func testContinuedProcessingPhotosMarkerSpike() throws {
        application.launchArguments += ["-continuedProcessingSpike"]
        application.launch()
        XCTAssertTrue(application.wait(for: .runningForeground, timeout: 30))
        XCUIDevice.shared.press(.home)
        let photos = XCUIApplication(bundleIdentifier: "com.apple.mobileslideshow")
        photos.launch()
        XCTAssertTrue(photos.wait(for: .runningForeground, timeout: 20))
        let hierarchy = XCTAttachment(string: photos.debugDescription)
        hierarchy.name = "continued-spike-photos-navigation"
        hierarchy.lifetime = .keepAlways
        add(hierarchy)
        // Do not select arbitrary personal media. The named QA album is the
        // only authorized input boundary for this system handoff probe.
        let album = photos.staticTexts["MemoMark QA Inputs"].firstMatch
        if !album.exists {
            let collections = photos.buttons["CollectionsTab"]
            if collections.exists { collections.tap() }
            for _ in 0..<8 where !album.isHittable { photos.swipeUp() }
        }
        guard album.waitForExistence(timeout: 5), album.isHittable else {
            XCTFail("Named QA album is not visible; Photos handoff remains NOT VERIFIED. No personal asset was selected.")
            return
        }
        album.tap()
        let select = photos.buttons["选择"]
        XCTAssertTrue(select.waitForExistence(timeout: 10))
        select.tap()
        let cells = photos.images.matching(identifier: "PXGGridLayout-Info")
        XCTAssertEqual(cells.count, 7)
        for index in [0, 2, 4] { cells.element(boundBy: index).tap() }
        // AssistiveTouch may cover the lower-left Photos Share control.
        let assistiveTouch = photos.coordinate(withNormalizedOffset: CGVector(dx: 0.06, dy: 0.95))
        let clearShareArea = photos.coordinate(withNormalizedOffset: CGVector(dx: 0.50, dy: 0.20))
        assistiveTouch.press(forDuration: 0.35, thenDragTo: clearShareArea)
        assistiveTouchWasMovedForShare = true
        let share = photos.buttons.matching(NSPredicate(format: "label IN %@", ["共享", "分享", "Share"])).firstMatch
        XCTAssertTrue(share.waitForExistence(timeout: 10))
        share.tap()
        let memoMark = photos.cells.matching(NSPredicate(format: "label IN %@", ["时光记", "MemoMark"])).firstMatch
        XCTAssertTrue(memoMark.waitForExistence(timeout: 10))
        memoMark.tap()
        let confirm = photos.buttons["开始记录"].firstMatch
        XCTAssertTrue(confirm.waitForExistence(timeout: 15))
        confirm.tap()
        let submitting = photos.buttons["正在提交"]
        _ = submitting.waitForExistence(timeout: 3)
        XCTAssertEqual(XCTWaiter.wait(for: [XCTNSPredicateExpectation(predicate: NSPredicate(format: "exists == false"), object: submitting)], timeout: 30), .completed)
        XCTAssertFalse(confirm.exists)
        XCTAssertTrue(photos.wait(for: .runningForeground, timeout: 30))
        XCTAssertNotEqual(application.state, .runningForeground)
        let finalState = XCTAttachment(string: photos.debugDescription)
        finalState.name = "continued-spike-share-return"
        finalState.lifetime = .keepAlways
        add(finalState)
        let observation = expectation(description: "Observe Photos-origin marker without host activation")
        DispatchQueue.main.asyncAfter(deadline: .now() + 55) { observation.fulfill() }
        wait(for: [observation], timeout: 60)
        XCTAssertNotEqual(application.state, .runningForeground)
        // Host callback/marker acknowledgement require independent App Group
        // readback; foreground return alone never certifies background execution.
    }

    override func tearDownWithError() throws {
        if assistiveTouchWasMovedForShare {
            let photos = XCUIApplication(bundleIdentifier: "com.apple.mobileslideshow")
            if photos.state != .notRunning {
                photos.activate()
                let safe = photos.coordinate(withNormalizedOffset: CGVector(dx: 0.50, dy: 0.20))
                let original = photos.coordinate(withNormalizedOffset: CGVector(dx: 0.06, dy: 0.95))
                safe.press(forDuration: 0.35, thenDragTo: original)
            }
        }
        try super.tearDownWithError()
    }

    func testContinuedProcessingPhotosMarkerColdProbe() throws {
        XCTAssertNotEqual(application.state, .runningForeground)
        let photos = XCUIApplication(bundleIdentifier: "com.apple.mobileslideshow")
        photos.launch()
        XCTAssertTrue(photos.wait(for: .runningForeground, timeout: 20))
        let hierarchy = XCTAttachment(string: photos.debugDescription)
        hierarchy.name = "continued-spike-photos-navigation"
        hierarchy.lifetime = .keepAlways
        add(hierarchy)
        // Do not select arbitrary personal media. The named QA album is the
        // only authorized input boundary for this system handoff probe.
        let album = photos.staticTexts["MemoMark QA Inputs"].firstMatch
        if !album.exists {
            let collections = photos.buttons["CollectionsTab"]
            if collections.exists { collections.tap() }
            for _ in 0..<8 where !album.isHittable { photos.swipeUp() }
        }
        guard album.waitForExistence(timeout: 5), album.isHittable else {
            XCTFail("Named QA album is not visible; Photos handoff remains NOT VERIFIED. No personal asset was selected.")
            return
        }
        album.tap()

        func submitShare(_ indices: [Int]) {
            let select = photos.buttons["选择"]
            XCTAssertTrue(select.waitForExistence(timeout: 10))
            select.tap()
            let cells = photos.images.matching(identifier: "PXGGridLayout-Info")
            XCTAssertEqual(cells.count, 7)
            for index in indices { cells.element(boundBy: index).tap() }
            // AssistiveTouch can float directly over Photos' lower-left Share
            // button. Move it temporarily, then restore it from tearDown.
            if !assistiveTouchWasMovedForShare {
                let assistiveTouch = photos.coordinate(withNormalizedOffset: CGVector(dx: 0.06, dy: 0.95))
                let clearShareArea = photos.coordinate(withNormalizedOffset: CGVector(dx: 0.50, dy: 0.20))
                assistiveTouch.press(forDuration: 0.35, thenDragTo: clearShareArea)
                assistiveTouchWasMovedForShare = true
            }
            let share = photos.buttons.matching(NSPredicate(format: "label IN %@", ["共享", "分享", "Share"])).firstMatch
            XCTAssertTrue(share.waitForExistence(timeout: 10))
            share.tap()
            let memoMark = photos.cells.matching(NSPredicate(format: "label IN %@", ["时光记", "MemoMark"])).firstMatch
            XCTAssertTrue(memoMark.waitForExistence(timeout: 10))
            memoMark.tap()
            let confirm = photos.buttons["开始记录"].firstMatch
            XCTAssertTrue(confirm.waitForExistence(timeout: 15))
            confirm.tap()
            let submitting = photos.buttons["正在提交"]
            _ = submitting.waitForExistence(timeout: 3)
            XCTAssertEqual(XCTWaiter.wait(for: [XCTNSPredicateExpectation(predicate: NSPredicate(format: "exists == false"), object: submitting)], timeout: 30), .completed)
            XCTAssertFalse(confirm.exists)
            XCTAssertTrue(photos.wait(for: .runningForeground, timeout: 30))
            XCTAssertNotEqual(application.state, .runningForeground)
        }

        // Two disjoint groups make any repeated output attributable to the
        // selected source set, while the first system task is still active.
        submitShare([0, 3, 5])
        submitShare([1, 2, 6])
        let finalState = XCTAttachment(string: photos.debugDescription)
        finalState.name = "continued-spike-two-share-return"
        finalState.lifetime = .keepAlways
        add(finalState)
        let observation = expectation(description: "Observe queued Photos-origin markers without host activation")
        DispatchQueue.main.asyncAfter(deadline: .now() + 75) { observation.fulfill() }
        wait(for: [observation], timeout: 80)
        XCTAssertNotEqual(application.state, .runningForeground)
        // Host callback/marker acknowledgement require independent App Group
        // readback; foreground return alone never certifies background execution.
    }

    func testBackgroundNotificationCenterReadback() throws {
        let photos = XCUIApplication(bundleIdentifier: "com.apple.mobileslideshow")
        photos.activate()
        let hostBackground = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
            self.application.state != .runningForeground
        }, object: nil)
        XCTAssertEqual(XCTWaiter.wait(for: [hostBackground], timeout: 10), .completed)
        XCTAssertNotEqual(application.state, .runningForeground)
        photos.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.01))
            .press(forDuration: 0.1, thenDragTo: photos.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.85)))
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        // Reveal notification history from the large-clock cover sheet before
        // querying groups. Stay inside the list, away from the Home gesture.
        springboard.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.76))
            .press(forDuration: 0.1, thenDragTo: springboard.coordinate(
                withNormalizedOffset: CGVector(dx: 0.5, dy: 0.40)))
        let count = springboard.buttons.matching(NSPredicate(format: "label MATCHES %@", "[0-9]+个通知")).firstMatch
        if count.exists, count.isHittable { count.tap() }
        let memoMarkFocusGroup = springboard.buttons.matching(NSPredicate(
            format: "(label CONTAINS %@ OR label CONTAINS %@) AND label CONTAINS %@", "专注模式期间", "来自", "时光记"
        )).firstMatch
        if memoMarkFocusGroup.exists, memoMarkFocusGroup.isHittable { memoMarkFocusGroup.tap() }
        let screenshot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        screenshot.name = "background-notification-center"
        screenshot.lifetime = .keepAlways
        add(screenshot)
        let state = XCTAttachment(string: springboard.debugDescription)
        state.name = "background-notification-center-state"
        state.lifetime = .keepAlways
        add(state)
        XCTAssertNotEqual(application.state, .runningForeground)
    }

    private func attachSystemScreenshot(named name: String) {
        let evidence = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        evidence.name = name
        evidence.lifetime = .keepAlways
        add(evidence)
    }

    func testClearMemoMarkNotificationHistoryForCardRound() throws {
        try clearMemoMarkNotificationHistoryForCardRound()
    }

    private func clearMemoMarkNotificationHistoryForCardRound() throws {
        try testBackgroundNotificationCenterReadback()
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        let notification = springboard.buttons.matching(NSPredicate(
            format: "identifier == %@ AND label BEGINSWITH %@", "ListCell", "时光记,"))
        let activity = springboard.buttons.matching(identifier: "ListCell").containing(
            .staticText, identifier: "时光记")
        for _ in 0..<80 {
            let target = notification.allElementsBoundByIndex.first { $0.isHittable }
                ?? activity.allElementsBoundByIndex.first { $0.isHittable }
            guard let target else {
                if notification.count == 0 && activity.count == 0 { break }
                springboard.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.72))
                    .press(forDuration: 0.1, thenDragTo: springboard.coordinate(
                        withNormalizedOffset: CGVector(dx: 0.5, dy: 0.40)))
                continue
            }
            target.coordinate(withNormalizedOffset: CGVector(dx: 0.85, dy: 0.5))
                .press(forDuration: 0.1, thenDragTo: target.coordinate(
                    withNormalizedOffset: CGVector(dx: 0.45, dy: 0.5)))
            let rowFrame = target.frame
            let clear = springboard.buttons.matching(NSPredicate(
                format: "label IN %@", ["清除", "删除", "Clear"])).allElementsBoundByIndex.first {
                    $0.isHittable && $0.identifier != "clear-button"
                        && abs($0.frame.midY - rowFrame.midY) <= rowFrame.height / 2 + 8
                }
            guard let clear else {
                attachSystemScreenshot(named: "notification-clear-control-missing")
                throw CocoaError(.userCancelled)
            }
            clear.tap()
        }
        guard springboard.otherElements["lockscreen-date-view"].exists else {
            attachSystemScreenshot(named: "notification-center-unexpectedly-dismissed")
            throw CocoaError(.userCancelled)
        }
        let evidence = XCTAttachment(string: springboard.debugDescription)
        evidence.name = "four-card-notification-clean-baseline-state"
        evidence.lifetime = .keepAlways
        add(evidence)
        attachSystemScreenshot(named: "four-card-notification-clean-baseline")
        XCTAssertEqual(notification.count, 0, "MemoMark notification history must be cleared before Share.")
        XCTAssertEqual(activity.count, 0, "MemoMark activity history must be cleared before Share.")
        guard notification.count == 0, activity.count == 0 else { throw CocoaError(.userCancelled) }
        springboard.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.97))
            .press(forDuration: 0.1, thenDragTo: springboard.coordinate(
                withNormalizedOffset: CGVector(dx: 0.5, dy: 0.2)))
    }

    func testFourCardConfigurationSurfaceReadback() throws {
        launchHostAndWait()
        application.buttons["配置"].tap()
        for _ in 0..<5 { application.scrollViews.firstMatch.swipeDown() }
        attachCurrentScreenshot(named: "four-card-configuration-surface")
        let evidence = XCTAttachment(string: application.debugDescription)
        evidence.name = "four-card-configuration-surface-state"
        evidence.lifetime = .keepAlways
        add(evidence)
    }

    func testMultiplePhotosBackgroundWithoutHostActivation() throws {
        try performMultiplePhotosBackgroundWithoutHostActivation(indices: [0, 2, 4])
    }

    func testDismissOnlyMemoMarkSystemActivityResidue() throws {
        try testBackgroundNotificationCenterReadback()
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        let title = springboard.staticTexts["时光记正在处理照片"].firstMatch
        if title.exists {
            title.swipeLeft()
            let clear = springboard.buttons["清除"].firstMatch
            if clear.exists, clear.isHittable { clear.tap() }
        }
        let screenshot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        screenshot.name = "memoMark-system-activity-residue-after-dismissal"
        screenshot.lifetime = .keepAlways
        add(screenshot)
        let hierarchy = XCTAttachment(string: springboard.debugDescription)
        hierarchy.name = "memoMark-system-activity-residue-after-dismissal-state"
        hierarchy.lifetime = .keepAlways
        add(hierarchy)
        XCTAssertFalse(title.exists, "Dismiss only the MemoMark activity, preserving other applications' notifications.")
        XCTAssertNotEqual(application.state, .runningForeground)
        springboard.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.97))
            .press(forDuration: 0.1, thenDragTo: springboard.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.2)))
    }

    func testReleaseFourCardClassicShare() throws { try verifyFourCardShare(style: "经典白") }
    func testReleaseFourCardMinimalShare() throws { try verifyFourCardShare(style: "极简") }
    func testReleaseFourCardFilmMarkShare() throws { try verifyFourCardShare(style: "胶片时间") }
    func testReleaseFourCardGlassShare() throws { try verifyFourCardShare(style: "玻璃卡片") }

    private func cardStyleHeaderForQA() -> XCUIElement {
        application.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "卡片样式、")).firstMatch
    }

    private func selectCardStyleForQA(_ style: String) throws {
        application.buttons["配置"].tap()
        for _ in 0..<6 where !cardStyleHeaderForQA().isHittable {
            application.scrollViews.firstMatch.swipeDown()
        }
        let header = cardStyleHeaderForQA()
        XCTAssertTrue(header.waitForExistence(timeout: 10))
        if header.value as? String == style { return }
        let picker = application.segmentedControls.firstMatch
        if !picker.exists { header.tap() }
        let choice = application.segmentedControls.buttons[style].firstMatch
        guard choice.waitForExistence(timeout: 5), choice.isHittable else {
            attachCurrentScreenshot(named: "four-card-style-choice-missing")
            let evidence = XCTAttachment(string: application.debugDescription)
            evidence.name = "four-card-style-choice-missing-state"
            evidence.lifetime = .keepAlways
            add(evidence)
            throw CocoaError(.userCancelled)
        }
        choice.tap()
        try saveDescriptionConfigurationForQA()
        XCTAssertEqual(header.value as? String, style)
        attachCurrentScreenshot(named: "four-card-saved-style-" + style)
    }

    private func verifyFourCardShare(style: String) throws {
        continueAfterFailure = true
        let baseline = try inventoryAlbum(titled: "MemoMark QA Outputs", attachmentName: "four-card-empty-output-baseline.json")
        guard baseline.assetCount == 0 else { throw CocoaError(.fileWriteFileExists) }
        launchHostAndWait()
        application.buttons["配置"].tap()
        for _ in 0..<6 where !cardStyleHeaderForQA().isHittable {
            application.scrollViews.firstMatch.swipeDown()
        }
        let originalStyle = try XCTUnwrap(cardStyleHeaderForQA().value as? String)
        var restored = false
        let restore = { [self] in
            guard !restored else { return }
            application.activate()
            do { try selectCardStyleForQA(originalStyle); restored = true }
            catch { XCTFail("Could not restore the user's card style: \(error)") }
            XCUIDevice.shared.press(.home)
        }
        addTeardownBlock { restore() }
        defer { restore() }
        try selectCardStyleForQA(style)
        try verifyReleaseMixedShare(selectAllInputs: true, cardStyle: style)
    }

    func testReleaseMixedShareWithoutHostActivation() throws {
        try verifyReleaseMixedShare(selectAllInputs: false)
    }

    func testReadPinnedClassicOutputContent() throws {
        let inputs = try inventoryAlbum(titled: "MemoMark QA Inputs", attachmentName: "visible-content-source-inventory.json")
        let outputs = try inventoryAlbum(titled: "MemoMark QA Outputs", attachmentName: "visible-content-output-inventory.json")
        XCTAssertEqual(outputs.assetCount, inputs.assetCount)
        try verifySavedClassicFooter(outputs, sources: inputs.assets)
    }

    func testReleaseAllPreparedSourcesWithoutHostActivation() throws {
        try verifyReleaseMixedShare(selectAllInputs: true)
    }

    func testReleaseLocalMaterialShareWithoutHostActivation() throws {
        try verifyReleaseMixedShare(selectAllInputs: true, inputAlbum: "MemoMark QA Local Inputs", verifyOriginalBytes: true)
    }

    func testReleaseLocalStaticSourcesWithoutHostActivation() throws {
        try verifyReleaseMixedShare(selectAllInputs: false, inputAlbum: "MemoMark QA Local Inputs", verifyOriginalBytes: true, staticInputsOnly: true)
    }

    func testReleaseSinglePreparedStaticSourceWithoutHostActivation() throws {
        try verifyReleaseMixedShare(selectAllInputs: false, singleInput: true, staticInputsOnly: true)
    }

    func testReleaseSinglePreparedSourceWithoutHostActivation() throws {
        try verifyReleaseMixedShare(selectAllInputs: false, singleInput: true)
    }

    func testReleaseSingleLocalSourceWithoutHostActivation() throws {
        try verifyReleaseMixedShare(selectAllInputs: false, inputAlbum: "MemoMark QA Local Inputs", verifyOriginalBytes: true, singleInput: true)
    }

    func testPrepareLocalMaterialQAAlbum() throws {
        struct Fixture: Decodable {
            let stillFilename: String
            let movieFilename: String?
        }
        let folder = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask,
            appropriateFor: nil, create: false).appendingPathComponent("MemoMarkQA Local20261011")
        let manifest = folder.appendingPathComponent("manifest.json")
        guard FileManager.default.fileExists(atPath: manifest.path) else {
            throw XCTSkip("Copy explicitly selected private local materials to the QA runner before preparing this album.")
        }
        let fixtures = try JSONDecoder().decode([Fixture].self, from: Data(contentsOf: manifest))
        let options = PHFetchOptions()
        options.predicate = NSPredicate(format: "title == %@", "MemoMark QA Local Inputs")
        if let existing = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: options).firstObject {
            XCTAssertEqual(PHAsset.fetchAssets(in: existing, options: nil).count, fixtures.count)
            return
        }
        XCTAssertEqual(PHPhotoLibrary.authorizationStatus(for: .readWrite), .authorized)
        for fixture in fixtures {
            XCTAssertTrue(FileManager.default.fileExists(atPath: folder.appendingPathComponent(fixture.stillFilename).path))
            if let movie = fixture.movieFilename {
                XCTAssertTrue(FileManager.default.fileExists(atPath: folder.appendingPathComponent(movie).path))
            }
        }
        let prepared = expectation(description: "Prepare isolated real local Photos materials")
        PHPhotoLibrary.shared().performChanges {
            let album = PHAssetCollectionChangeRequest.creationRequestForAssetCollection(withTitle: "MemoMark QA Local Inputs")
            var placeholders: [PHObjectPlaceholder] = []
            for fixture in fixtures {
                let request = PHAssetCreationRequest.forAsset()
                request.addResource(with: .photo, fileURL: folder.appendingPathComponent(fixture.stillFilename), options: nil)
                if let movie = fixture.movieFilename {
                    request.addResource(with: .pairedVideo, fileURL: folder.appendingPathComponent(movie), options: nil)
                }
                if let placeholder = request.placeholderForCreatedAsset { placeholders.append(placeholder) }
            }
            album.addAssets(placeholders as NSArray)
        } completionHandler: { success, error in
            XCTAssertTrue(success, "Local QA preparation failed: \(String(describing: error))")
            prepared.fulfill()
        }
        wait(for: [prepared], timeout: 120)
        let inventory = try inventoryAlbum(titled: "MemoMark QA Local Inputs", attachmentName: "prepared-local-materials.json")
        XCTAssertEqual(inventory.assetCount, fixtures.count)
        XCTAssertEqual(inventory.assets.filter { $0.classification == "livePhoto" }.count,
            fixtures.filter { $0.movieFilename != nil }.count)
    }

    private func verifyReleaseMixedShare(selectAllInputs: Bool, inputAlbum: String = "MemoMark QA Inputs", verifyOriginalBytes: Bool = false, singleInput: Bool = false, staticInputsOnly: Bool = false, cardStyle: String? = nil) throws {
#if DEBUG
        throw XCTSkip("This gate requires the signed Release export path.")
#else
        // Keep restoration running after a recorded assertion failure. Every
        // changed setting is read before editing and restored through the UI.
        continueAfterFailure = true
        XCUIDevice.shared.orientation = .portrait
        let inputs = try inventoryAlbum(titled: inputAlbum, attachmentName: "release-source-baseline.json")
        let baseline = try inventoryAlbum(titled: "MemoMark QA Outputs", attachmentName: "release-output-baseline.json")
        let eligible = staticInputsOnly ? inputs.assets.indices.filter { inputs.assets[$0].classification != "livePhoto" } : Array(inputs.assets.indices)
        let indices = singleInput ? [try XCTUnwrap(eligible.first)] : staticInputsOnly ? eligible : selectAllInputs ? Array(inputs.assets.indices) : try [
            XCTUnwrap(inputs.assets.firstIndex { $0.classification == "livePhoto" }),
            XCTUnwrap(inputs.assets.firstIndex { $0.classification == "rawWithJPEGRepresentation" }),
            XCTUnwrap(inputs.assets.firstIndex { $0.classification == "jpegStill" })
        ]
        let selected = indices.map { inputs.assets[$0] }
        launchHostAndWait()
        try openDescriptionSettingsForQA()
        let toggle = descriptionSupplementToggle()
        let originalUsesCustom = toggle.value as? String == "1"
        var originalText: String?
        var configurationRestored = false
        let restoreConfiguration = { [self] in
            guard !configurationRestored else { return }
            application.activate()
            do {
                try openDescriptionSettingsForQA()
                let restoreToggle = descriptionSupplementToggle()
                if restoreToggle.value as? String != "1" { restoreToggle.tap() }
                if let originalText { try replaceDescriptionSupplement(with: originalText) }
                if !originalUsesCustom { restoreToggle.tap() }
                try saveDescriptionConfigurationForQA()
                configurationRestored = true
            } catch { XCTFail("Could not restore the user's description configuration: \(error)") }
            XCUIDevice.shared.press(.home)
        }
        // XCTest UI exceptions can bypass Swift defers. Keep an independent
        // test teardown recovery as well as restoration after normal return.
        addTeardownBlock { restoreConfiguration() }
        defer { restoreConfiguration() }
        if !originalUsesCustom { toggle.tap() }
        let field = descriptionSupplementField()
        XCTAssertTrue(field.waitForExistence(timeout: 10))
        let configurationState = XCTAttachment(string: application.debugDescription)
        configurationState.name = "release-configuration-before-edit"
        configurationState.lifetime = .keepAlways
        add(configurationState)
        // An empty native text field exposes its placeholder without a value.
        let originalValue = try XCTUnwrap((field.value as? String) ?? field.placeholderValue)
        originalText = originalValue == field.placeholderValue ? "" : originalValue
        let caption = "Q" + String(Int(Date().timeIntervalSince1970), radix: 36)
        try replaceDescriptionSupplement(with: caption)
        try saveDescriptionConfigurationForQA()
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent("ReleaseMixedReadback-" + UUID().uuidString)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: folder) }
        func sourceHashes() throws -> [String: SHA256.Digest] {
            var hashes: [String: SHA256.Digest] = [:]
            for item in selected {
                let asset = try XCTUnwrap(PHAsset.fetchAssets(withLocalIdentifiers: [item.localIdentifier], options: nil).firstObject)
                // Hash original image/movie bytes rather than Photos' internal
                // adjustment envelopes. Inventory preserves the full catalogue.
                for resource in PHAssetResource.assetResources(for: asset) where
                    [.photo, .pairedVideo, .alternatePhoto].contains(resource.type) {
                    let url = try savedResourceURL(resource, in: folder)
                    let stream = try XCTUnwrap(InputStream(url: url))
                    stream.open()
                    defer { stream.close(); try? FileManager.default.removeItem(at: url) }
                    var digest = SHA256()
                    var buffer = [UInt8](repeating: 0, count: 65536)
                    while true {
                        let count = stream.read(&buffer, maxLength: buffer.count)
                        if count == 0 { break }
                        guard count > 0 else { throw stream.streamError ?? CocoaError(.fileReadUnknown) }
                        digest.update(data: Data(buffer.prefix(count)))
                    }
                    hashes[item.localIdentifier + ":" + String(resource.type.rawValue) + ":" + resource.originalFilename] = digest.finalize()
                }
            }
            return hashes
        }
        // Existing QA inputs may have optimized-away iCloud originals. This
        // gate always verifies identity/catalogue, and requires byte equality
        // separately for the locally prepared material album.
        let before = verifyOriginalBytes ? try sourceHashes() : nil
        let expectedCount = baseline.assetCount + selected.count
        if cardStyle != nil { try clearMemoMarkNotificationHistoryForCardRound() }
        try performMultiplePhotosBackgroundWithoutHostActivation(indices: selectAllInputs ? [] : indices,
            expectedOutputCount: expectedCount, expectedBaselineCount: baseline.assetCount,
            expectedInputCount: inputs.assetCount, selectAllInputs: selectAllInputs, inputAlbumTitle: inputAlbum)
        let outputs = try inventoryAlbum(titled: "MemoMark QA Outputs", attachmentName: "release-new-output-readback.json")
        let baselineIDs = Set(baseline.assets.map(\.localIdentifier))
        let added = outputs.assets.filter { !baselineIDs.contains($0.localIdentifier) }
        let newOutputs = QAAlbumInventory(albumTitle: outputs.albumTitle, albumLocalIdentifier: outputs.albumLocalIdentifier,
            authorization: outputs.authorization, assetCount: added.count, assets: added)
        XCTAssertEqual(added.count, selected.count)
        guard added.count == selected.count else { throw CocoaError(.fileReadUnknown) }
        XCTAssertEqual(added.compactMap(\.creationDate).sorted(), selected.compactMap(\.creationDate).sorted())
        try verifySavedStillMetadata(newOutputs, expectedDescription: caption)
        if cardStyle == nil || cardStyle == "经典白" { try verifySavedClassicFooter(newOutputs, sources: selected) }
        if let cardStyle { try attachSavedCardCompositions(newOutputs, style: cardStyle) }
        verifySavedMoviePairingSynchronously(newOutputs, expectedPairCount: selected.filter { $0.classification == "livePhoto" }.count)
        if let before { XCTAssertEqual(try sourceHashes(), before, "All selected original resource bytes must remain unchanged.") }
        let originalReadback = try inventoryAlbum(titled: inputAlbum, attachmentName: "release-original-identity-readback.json")
        // PhotoKit modificationDate is catalogue state, and changed during
        // this Photos Share even though every original resource SHA matched.
        // Keep it in both evidence attachments; require all content/identity
        // fields plus the separate original-byte gate to remain equal.
        XCTAssertEqual(originalReadback.assets.map(\.contentIdentity), inputs.assets.map(\.contentIdentity))
        XCTAssertNotEqual(application.state, .runningForeground)
        if singleInput || cardStyle != nil { return }
        try performMultiplePhotosBackgroundWithoutHostActivation(indices: selectAllInputs ? [] : indices,
            expectedOutputCount: outputs.assetCount, expectedBaselineCount: outputs.assetCount,
            expectedInputCount: inputs.assetCount, selectAllInputs: selectAllInputs, inputAlbumTitle: inputAlbum,
            minimumObservationCheckpoints: 4)
        let repeated = try inventoryAlbum(titled: "MemoMark QA Outputs", attachmentName: "release-repeat-identity-readback.json")
        XCTAssertEqual(Set(repeated.assets.map(\.localIdentifier)), Set(outputs.assets.map(\.localIdentifier)))
        if let before { XCTAssertEqual(try sourceHashes(), before) }
        let finalSurface = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        finalSurface.name = "ordinary-share-completion-system-surface"
        finalSurface.lifetime = .keepAlways
        add(finalSurface)
        // Keep all existing and newly generated QA outputs for inspection.
#endif
    }

    func testReleaseShareProgressIsVisibleAfterReturningToHost() throws {
#if DEBUG
        throw XCTSkip("This gate requires the signed Release export path.")
#else
        XCUIDevice.shared.orientation = .portrait
        let inputs = try inventoryAlbum(titled: "MemoMark QA Inputs", attachmentName: "host-progress-source-baseline.json")
        let index = try XCTUnwrap(inputs.assets.firstIndex { $0.classification == "jpegStill" })
        launchHostAndWait()
        try performMultiplePhotosBackgroundWithoutHostActivation(
            indices: [index],
            observeOutputs: false,
            activateHostAfterSubmission: true
        )
#endif
    }

    func testContinuedProductionThreePhotosWithoutHostActivation() throws {
        application.launchArguments += ["-continuedProductionPipelineProbe"]
        application.launch()
        XCTAssertTrue(application.wait(for: .runningForeground, timeout: 20))
        try performMultiplePhotosBackgroundWithoutHostActivation(indices: [1, 3, 5])
    }

    func testContinuedGlassThreePhotosWithDescriptionVariant() throws {
        application.launchArguments += ["-continuedProductionPipelineProbe"]
        launchHostAndWait()
        try openDescriptionSettingsForQA()
        let toggle = descriptionSupplementToggle()
        XCTAssertTrue(toggle.waitForExistence(timeout: 10))
        let originalUsesCustom = toggle.value as? String == "1"
        if !originalUsesCustom { toggle.tap() }
        let field = descriptionSupplementField()
        XCTAssertTrue(field.waitForExistence(timeout: 10))
        let originalValue = field.value as? String ?? ""
        let originalText = originalValue == "写下想补充的话" || originalValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "" : originalValue
        defer {
            application.activate()
            do {
                try openDescriptionSettingsForQA()
                let restoreToggle = descriptionSupplementToggle()
                if restoreToggle.value as? String != "1" { restoreToggle.tap() }
                try replaceDescriptionSupplement(with: originalText)
                if !originalUsesCustom { restoreToggle.tap() }
                try saveDescriptionConfigurationForQA()
            } catch { XCTFail("Could not restore the user's description configuration: \(error)") }
        }
        try replaceDescriptionSupplement(with: "后台验证记录")
        try saveDescriptionConfigurationForQA()
        try performMultiplePhotosBackgroundWithoutHostActivation(indices: [1, 3, 5])
        let outputs = try inventoryAlbum(titled: "MemoMark QA Outputs", attachmentName: "fresh-glass-description-outputs.json")
        XCTAssertEqual(outputs.assetCount, 3)
        try deleteOutputsAddedSince([], attachmentPrefix: "fresh-glass-description-cleanup")
    }

    func testContinuedGlassMixedMediaWithDescriptionVariant() throws {
        application.launchArguments += ["-continuedProductionPipelineProbe"]
        launchHostAndWait()
        try openDescriptionSettingsForQA()
        let toggle = descriptionSupplementToggle()
        XCTAssertTrue(toggle.waitForExistence(timeout: 10))
        let originalUsesCustom = toggle.value as? String == "1"
        if !originalUsesCustom { toggle.tap() }
        let field = descriptionSupplementField()
        XCTAssertTrue(field.waitForExistence(timeout: 10))
        let originalValue = field.value as? String ?? ""
        let originalText = originalValue == "写下想补充的话" || originalValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "" : originalValue
        defer {
            application.activate()
            do {
                try openDescriptionSettingsForQA()
                let restoreToggle = descriptionSupplementToggle()
                if restoreToggle.value as? String != "1" { restoreToggle.tap() }
                try replaceDescriptionSupplement(with: originalText)
                if !originalUsesCustom { restoreToggle.tap() }
                try saveDescriptionConfigurationForQA()
            } catch { XCTFail("Could not restore the user's description configuration: \(error)") }
        }
        try replaceDescriptionSupplement(with: "后台混合素材验证")
        try saveDescriptionConfigurationForQA()
        try performMultiplePhotosBackgroundWithoutHostActivation(indices: [0, 2, 4])
        let outputs = try inventoryAlbum(titled: "MemoMark QA Outputs", attachmentName: "fresh-glass-mixed-outputs.json")
        XCTAssertEqual(outputs.assetCount, 3)
        XCTAssertEqual(outputs.assets.filter { $0.classification == "livePhoto" }.count, 1)
        try deleteOutputsAddedSince([], attachmentPrefix: "fresh-glass-mixed-cleanup")
    }

    func testContinuedMixedAdmissionDiagnostics() throws {
        application.launchArguments += ["-continuedProductionPipelineProbe"]
        launchHostAndWait()
        try openDescriptionSettingsForQA()
        let toggle = descriptionSupplementToggle()
        XCTAssertTrue(toggle.waitForExistence(timeout: 10))
        let originalUsesCustom = toggle.value as? String == "1"
        if !originalUsesCustom { toggle.tap() }
        let field = descriptionSupplementField()
        XCTAssertTrue(field.waitForExistence(timeout: 10))
        let originalValue = field.value as? String ?? ""
        let originalText = originalValue == "写下想补充的话" || originalValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "" : originalValue
        defer {
            application.activate()
            do {
                try openDescriptionSettingsForQA()
                let restoreToggle = descriptionSupplementToggle()
                if restoreToggle.value as? String != "1" { restoreToggle.tap() }
                try replaceDescriptionSupplement(with: originalText)
                if !originalUsesCustom { restoreToggle.tap() }
                try saveDescriptionConfigurationForQA()
            } catch { XCTFail("Could not restore the user's description configuration: \(error)") }
        }
        try replaceDescriptionSupplement(with: "后台资源诊断")
        try saveDescriptionConfigurationForQA()
        try performMultiplePhotosBackgroundWithoutHostActivation(indices: [0, 2, 4], expectedOutputCount: 0)
        let outputs = try inventoryAlbum(titled: "MemoMark QA Outputs", attachmentName: "fresh-glass-mixed-outputs.json")
        XCTAssertEqual(outputs.assetCount, 0)
        try deleteOutputsAddedSince([], attachmentPrefix: "fresh-glass-mixed-cleanup")
    }

    func testContinuedMixedReadbackAndRepeatedIntent() throws {
        application.launchArguments += ["-continuedProductionPipelineProbe"]
        launchHostAndWait()
        try openDescriptionSettingsForQA()
        let toggle = descriptionSupplementToggle()
        XCTAssertTrue(toggle.waitForExistence(timeout: 10))
        let originalUsesCustom = toggle.value as? String == "1"
        if !originalUsesCustom { toggle.tap() }
        let field = descriptionSupplementField()
        XCTAssertTrue(field.waitForExistence(timeout: 10))
        let originalValue = field.value as? String ?? ""
        let originalText = originalValue == "写下想补充的话" || originalValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "" : originalValue
        defer {
            application.activate()
            do {
                try openDescriptionSettingsForQA()
                let restoreToggle = descriptionSupplementToggle()
                if restoreToggle.value as? String != "1" { restoreToggle.tap() }
                try replaceDescriptionSupplement(with: originalText)
                if !originalUsesCustom { restoreToggle.tap() }
                try saveDescriptionConfigurationForQA()
            } catch { XCTFail("Could not restore the user's description configuration: \(error)") }
        }
        try replaceDescriptionSupplement(with: "后台配对读回验证")
        try saveDescriptionConfigurationForQA()
        try performMultiplePhotosBackgroundWithoutHostActivation(indices: [0, 2, 4])
        let outputs = try inventoryAlbum(titled: "MemoMark QA Outputs", attachmentName: "fresh-glass-mixed-outputs.json")
        XCTAssertEqual(outputs.assetCount, 3)
        XCTAssertEqual(outputs.assets.filter { $0.classification == "livePhoto" }.count, 1)
        try testMemoMarkQA04LivePhotoOutputReadbackAndOriginalPreservation()
        try verifySavedStillMetadata(outputs, expectedDescription: "后台配对读回验证")
        let identifiers = Set(outputs.assets.map(\.localIdentifier))
        try performMultiplePhotosBackgroundWithoutHostActivation(indices: [0, 2, 4], expectedBaselineCount: 3)
        let repeated = try inventoryAlbum(titled: "MemoMark QA Outputs", attachmentName: "mixed-repeated-intent-outputs.json")
        XCTAssertEqual(Set(repeated.assets.map(\.localIdentifier)), identifiers)
        try deleteOutputsAddedSince([], attachmentPrefix: "fresh-glass-mixed-cleanup")
    }

    func testContinuedMixedRepeatedIntent() throws {
        application.launchArguments += ["-continuedProductionPipelineProbe"]
        launchHostAndWait()
        try openDescriptionSettingsForQA()
        let toggle = descriptionSupplementToggle()
        XCTAssertTrue(toggle.waitForExistence(timeout: 10))
        let originalUsesCustom = toggle.value as? String == "1"
        if !originalUsesCustom { toggle.tap() }
        let field = descriptionSupplementField()
        XCTAssertTrue(field.waitForExistence(timeout: 10))
        let originalValue = field.value as? String ?? ""
        let originalText = originalValue == "写下想补充的话" || originalValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "" : originalValue
        defer {
            application.activate()
            do {
                try openDescriptionSettingsForQA()
                let restoreToggle = descriptionSupplementToggle()
                if restoreToggle.value as? String != "1" { restoreToggle.tap() }
                try replaceDescriptionSupplement(with: originalText)
                if !originalUsesCustom { restoreToggle.tap() }
                try saveDescriptionConfigurationForQA()
            } catch { XCTFail("Could not restore the user's description configuration: \(error)") }
        }
        try replaceDescriptionSupplement(with: "后台配对读回验证")
        try saveDescriptionConfigurationForQA()
        try performMultiplePhotosBackgroundWithoutHostActivation(indices: [0, 2, 4])
        let outputs = try inventoryAlbum(titled: "MemoMark QA Outputs", attachmentName: "fresh-glass-mixed-outputs.json")
        XCTAssertEqual(outputs.assetCount, 3)
        XCTAssertEqual(outputs.assets.filter { $0.classification == "livePhoto" }.count, 1)
        try testMemoMarkQA04LivePhotoOutputReadbackAndOriginalPreservation()
        try verifySavedStillMetadata(outputs, expectedDescription: "后台配对读回验证", requireDescription: false)
        let identifiers = Set(outputs.assets.map(\.localIdentifier))
        try performMultiplePhotosBackgroundWithoutHostActivation(indices: [0, 2, 4], expectedBaselineCount: 3)
        let repeated = try inventoryAlbum(titled: "MemoMark QA Outputs", attachmentName: "mixed-repeated-intent-outputs.json")
        XCTAssertEqual(Set(repeated.assets.map(\.localIdentifier)), identifiers)
        try deleteOutputsAddedSince([], attachmentPrefix: "fresh-glass-mixed-cleanup")
    }

    func testContinuedFrozenDescriptionReadbackAndRepeatedIntent() throws {
        application.launchArguments += ["-continuedProductionPipelineProbe",
            "-continuedPhotoDescriptionOverrideProbe", "后台配对读回验证"]
        launchHostAndWait()
        let roundStartedAt = Date().timeIntervalSince1970
        defer {
            application.launchArguments = ["-uiTesting", "-uiTestingHarnessOnly", "-disableContinuedProcessingSpike"]
            launchHostAndWait()
            XCUIDevice.shared.press(.home)
        }
        try performMultiplePhotosBackgroundWithoutHostActivation(indices: [0, 2, 4])
        let outputs = try inventoryAlbum(titled: "MemoMark QA Outputs", attachmentName: "frozen-description-mixed-outputs.json")
        XCTAssertEqual(outputs.assetCount, 3)
        try testMemoMarkQA04LivePhotoOutputReadbackAndOriginalPreservation()
        try verifySavedStillMetadata(outputs, expectedDescription: "后台配对读回验证")
        let identifiers = Set(outputs.assets.map(\.localIdentifier))
        try performMultiplePhotosBackgroundWithoutHostActivation(indices: [0, 2, 4], expectedBaselineCount: 3)
        let repeated = try inventoryAlbum(titled: "MemoMark QA Outputs", attachmentName: "frozen-description-repeated-outputs.json")
        XCTAssertEqual(Set(repeated.assets.map(\.localIdentifier)), identifiers)
        try observeContinuedCompletionWindow(requestCount: 2, since: roundStartedAt)
        try deleteOutputsAddedSince([], attachmentPrefix: "frozen-description-mixed-cleanup")
    }

    func testContinuedSavedLivePhotoMoviePairing() throws {
        application.launchArguments += ["-continuedProductionPipelineProbe",
            "-continuedPhotoDescriptionOverrideProbe", "后台配对与轨道验证"]
        launchHostAndWait()
        let roundStartedAt = Date().timeIntervalSince1970
        defer {
            application.launchArguments = ["-uiTesting", "-uiTestingHarnessOnly", "-disableContinuedProcessingSpike"]
            launchHostAndWait()
            XCUIDevice.shared.press(.home)
        }
        try performMultiplePhotosBackgroundWithoutHostActivation(indices: [0, 1, 5])
        let outputs = try inventoryAlbum(titled: "MemoMark QA Outputs", attachmentName: "movie-pairing-outputs.json")
        XCTAssertEqual(outputs.assetCount, 3)
        try verifySavedStillMetadata(outputs, expectedDescription: "后台配对与轨道验证")
        verifySavedMoviePairingSynchronously(outputs)
        try observeContinuedCompletionWindow(requestCount: 1, since: roundStartedAt)
        try deleteOutputsAddedSince([], attachmentPrefix: "movie-pairing-cleanup")
    }

    func testSavedLivePhotoMoviePairingReadback() throws {
        let outputs = try inventoryAlbum(titled: "MemoMark QA Outputs", attachmentName: "saved-pair-readback-outputs.json")
        XCTAssertEqual(outputs.assetCount, 3)
        verifySavedMoviePairingSynchronously(outputs)
        try deleteOutputsAddedSince([], attachmentPrefix: "saved-pair-readback-cleanup")
    }

    func testContinuedBackToBackOverlappingSourceShares() throws {
        let caption = "连续会话执行完成验证 \(Int(Date().timeIntervalSince1970))"
        application.launchArguments += ["-continuedProductionPipelineProbe",
            "-continuedPhotoDescriptionOverrideProbe", caption]
        launchHostAndWait()
        let roundStartedAt = Date().timeIntervalSince1970
        defer {
            application.launchArguments = ["-uiTesting", "-uiTestingHarnessOnly", "-disableContinuedProcessingSpike"]
            launchHostAndWait()
            XCUIDevice.shared.press(.home)
        }
        try performMultiplePhotosBackgroundWithoutHostActivation(indices: [0, 1, 2, 3, 4, 5, 6], observeOutputs: false)
        try performMultiplePhotosBackgroundWithoutHostActivation(indices: [2, 3, 4, 5, 6],
            expectedOutputCount: 7, expectedBaselineCount: nil)
        let outputs = try inventoryAlbum(titled: "MemoMark QA Outputs", attachmentName: "back-to-back-share-outputs.json")
        XCTAssertEqual(outputs.assetCount, 7, "Twelve selections contain seven distinct source intents.")
        try verifySavedStillMetadata(outputs, expectedDescription: caption)
        try observeContinuedCompletionWindow(requestCount: 2, since: roundStartedAt)
        try deleteOutputsAddedSince([], attachmentPrefix: "back-to-back-share-cleanup")
    }

    func testContinuedSameSourcesWithDifferentFrozenDescription() throws {
        let round = Int(Date().timeIntervalSince1970)
        let firstCaption = "配置身份甲 \(round)"
        let secondCaption = "配置身份乙 \(round)"
        func configureProbe(_ caption: String) {
            application.launchArguments = ["-uiTesting", "-uiTestingHarnessOnly",
                "-continuedProductionPipelineProbe", "-continuedPhotoDescriptionOverrideProbe", caption]
            launchHostAndWait()
        }
        defer {
            application.launchArguments = ["-uiTesting", "-uiTestingHarnessOnly", "-disableContinuedProcessingSpike"]
            launchHostAndWait()
            XCUIDevice.shared.press(.home)
        }
        configureProbe(firstCaption)
        try performMultiplePhotosBackgroundWithoutHostActivation(indices: [0, 1, 2])
        let first = try inventoryAlbum(titled: "MemoMark QA Outputs", attachmentName: "different-config-first.json")
        XCTAssertEqual(first.assetCount, 3)
        try verifySavedStillMetadata(first, expectedDescription: firstCaption)
        let firstIDs = Set(first.assets.map(\.localIdentifier))
        try performMultiplePhotosBackgroundWithoutHostActivation(indices: [0, 1, 2], expectedBaselineCount: 3)
        let repeated = try inventoryAlbum(titled: "MemoMark QA Outputs", attachmentName: "different-config-repeated.json")
        XCTAssertEqual(Set(repeated.assets.map(\.localIdentifier)), firstIDs)
        // Intentional configuration phase between rounds, never during an active Share.
        configureProbe(secondCaption)
        try performMultiplePhotosBackgroundWithoutHostActivation(indices: [0, 1, 2],
            expectedOutputCount: 6, expectedBaselineCount: 3)
        let allOutputs = try inventoryAlbum(titled: "MemoMark QA Outputs", attachmentName: "different-config-all.json")
        let second = QAAlbumInventory(albumTitle: allOutputs.albumTitle,
            albumLocalIdentifier: allOutputs.albumLocalIdentifier, authorization: allOutputs.authorization,
            assetCount: 3, assets: allOutputs.assets.filter { !firstIDs.contains($0.localIdentifier) })
        XCTAssertEqual(allOutputs.assetCount, 6)
        XCTAssertTrue(firstIDs.isSubset(of: Set(allOutputs.assets.map(\.localIdentifier))))
        XCTAssertEqual(second.assets.count, 3)
        try verifySavedStillMetadata(second, expectedDescription: secondCaption)
        verifySavedMoviePairingSynchronously(second)
        XCTAssertEqual(try inventoryAlbum(titled: "MemoMark QA Inputs", attachmentName: "different-config-originals.json").assetCount, 15)
        try deleteOutputsAddedSince([], attachmentPrefix: "different-config-cleanup")
    }

    func testContinuedAppendNewSourcesAndDuplicate() throws {
        let caption = "追加新素材会话验证 \(Int(Date().timeIntervalSince1970))"
        application.launchArguments += ["-continuedProductionPipelineProbe",
            "-continuedPhotoDescriptionOverrideProbe", caption]
        launchHostAndWait()
        let roundStartedAt = Date().timeIntervalSince1970
        defer {
            application.launchArguments = ["-uiTesting", "-uiTestingHarnessOnly", "-disableContinuedProcessingSpike"]
            launchHostAndWait()
            XCUIDevice.shared.press(.home)
        }
        try performMultiplePhotosBackgroundWithoutHostActivation(indices: [0, 1, 2], observeOutputs: false)
        try performMultiplePhotosBackgroundWithoutHostActivation(indices: [2, 3, 4],
            expectedOutputCount: 5, expectedBaselineCount: nil)
        let outputs = try inventoryAlbum(titled: "MemoMark QA Outputs", attachmentName: "append-new-sources-outputs.json")
        let sourceInventory = try inventoryAlbum(titled: "MemoMark QA Inputs", attachmentName: "append-source-identity-readback.json")
        XCTAssertEqual(outputs.assets.compactMap(\.creationDate).sorted(),
                       Array(sourceInventory.assets.prefix(5)).compactMap(\.creationDate).sorted(),
                       "Saved capture dates must match the five selected source assets.")
        XCTAssertEqual(outputs.assetCount, 5, "A+B+C then C+D+E must save five distinct source intents.")
        try verifySavedStillMetadata(outputs, expectedDescription: caption)
        XCTAssertEqual(try inventoryAlbum(titled: "MemoMark QA Inputs",
            attachmentName: "append-new-sources-originals.json").assetCount, 15)
        verifySavedMoviePairingSynchronously(outputs)
        try observeContinuedCompletionWindow(requestCount: 2, since: roundStartedAt)
        try deleteOutputsAddedSince([], attachmentPrefix: "append-new-sources-cleanup")
    }

    func testContinuedAppendNewSourcesDuringSevenInputOwner() throws {
        let caption = "七张处理中追加新素材验证 \(Int(Date().timeIntervalSince1970))"
        application.launchArguments += ["-continuedProductionPipelineProbe",
            "-continuedPhotoDescriptionOverrideProbe", caption]
        launchHostAndWait()
        let roundStartedAt = Date().timeIntervalSince1970
        defer {
            application.launchArguments = ["-uiTesting", "-uiTestingHarnessOnly", "-disableContinuedProcessingSpike"]
            launchHostAndWait()
            XCUIDevice.shared.press(.home)
        }
        try performMultiplePhotosBackgroundWithoutHostActivation(indices: [0, 1, 2, 3, 4, 5, 6], observeOutputs: false)
        try performMultiplePhotosBackgroundWithoutHostActivation(indices: [2, 7, 8],
            expectedOutputCount: 9, expectedBaselineCount: nil)
        let outputs = try inventoryAlbum(titled: "MemoMark QA Outputs", attachmentName: "append-nine-new-sources-outputs.json")
        let sourceInventory = try inventoryAlbum(titled: "MemoMark QA Inputs", attachmentName: "append-nine-source-identity-readback.json")
        XCTAssertEqual(outputs.assets.compactMap(\.creationDate).sorted(),
                       Array(sourceInventory.assets.prefix(9)).compactMap(\.creationDate).sorted(),
                       "Saved capture dates must match the nine selected source assets.")
        XCTAssertEqual(outputs.assetCount, 9, "Seven initial sources plus one duplicate and two new sources must save nine distinct intents.")
        try verifySavedStillMetadata(outputs, expectedDescription: caption)
        XCTAssertEqual(try inventoryAlbum(titled: "MemoMark QA Inputs",
            attachmentName: "append-nine-new-sources-originals.json").assetCount, 15)
        verifySavedMoviePairingSynchronously(outputs)
        try observeContinuedCompletionWindow(requestCount: 2, since: roundStartedAt)
        try deleteOutputsAddedSince([], attachmentPrefix: "append-nine-new-sources-cleanup")
    }

    func testContinuedAppendNewSourcesDuringNineInputOwner() throws {
        let caption = "九张处理中追加新素材验证 \(Int(Date().timeIntervalSince1970))"
        application.launchArguments += ["-continuedProductionPipelineProbe",
            "-continuedPhotoDescriptionOverrideProbe", caption]
        launchHostAndWait()
        let roundStartedAt = Date().timeIntervalSince1970
        defer {
            application.launchArguments = ["-uiTesting", "-uiTestingHarnessOnly", "-disableContinuedProcessingSpike"]
            launchHostAndWait()
            XCUIDevice.shared.press(.home)
        }
        try performMultiplePhotosBackgroundWithoutHostActivation(indices: [0, 1, 2, 3, 4, 5, 6, 7, 8], observeOutputs: false)
        try performMultiplePhotosBackgroundWithoutHostActivation(indices: [2, 9, 10],
            expectedOutputCount: 11, expectedBaselineCount: nil)
        let outputs = try inventoryAlbum(titled: "MemoMark QA Outputs", attachmentName: "append-eleven-new-sources-outputs.json")
        let sourceInventory = try inventoryAlbum(titled: "MemoMark QA Inputs", attachmentName: "append-eleven-source-identity-readback.json")
        XCTAssertEqual(outputs.assets.compactMap(\.creationDate).sorted(),
                       Array(sourceInventory.assets.prefix(11)).compactMap(\.creationDate).sorted(),
                       "Saved capture dates must match the eleven selected source assets.")
        XCTAssertEqual(outputs.assetCount, 11, "Nine initial sources plus one duplicate and two new sources must save eleven distinct intents.")
        try verifySavedStillMetadata(outputs, expectedDescription: caption)
        XCTAssertEqual(try inventoryAlbum(titled: "MemoMark QA Inputs",
            attachmentName: "append-eleven-new-sources-originals.json").assetCount, 15)
        verifySavedMoviePairingSynchronously(outputs)
        try observeContinuedCompletionWindow(requestCount: 2, since: roundStartedAt)
        try deleteOutputsAddedSince([], attachmentPrefix: "append-eleven-new-sources-cleanup")
    }

    func testContinuedAppendDuplicateWhileOwnerRuns() throws {
        let caption = "处理中追加重复素材验证 \(Int(Date().timeIntervalSince1970))"
        application.launchArguments += ["-continuedProductionPipelineProbe",
            "-continuedPhotoDescriptionOverrideProbe", caption]
        launchHostAndWait()
        let roundStartedAt = Date().timeIntervalSince1970
        defer {
            application.launchArguments = ["-uiTesting", "-uiTestingHarnessOnly", "-disableContinuedProcessingSpike"]
            launchHostAndWait()
            XCUIDevice.shared.press(.home)
        }
        try performMultiplePhotosBackgroundWithoutHostActivation(indices: [0, 1, 2, 3, 4, 5, 6], observeOutputs: false)
        try performMultiplePhotosBackgroundWithoutHostActivation(indices: [2],
            expectedOutputCount: 7, expectedBaselineCount: nil)
        let outputs = try inventoryAlbum(titled: "MemoMark QA Outputs", attachmentName: "append-duplicate-share-outputs.json")
        XCTAssertEqual(outputs.assetCount, 7, "Eight selections contain seven distinct source intents.")
        try verifySavedStillMetadata(outputs, expectedDescription: caption)
        try observeContinuedCompletionWindow(requestCount: 2, since: roundStartedAt)
        try deleteOutputsAddedSince([], attachmentPrefix: "append-duplicate-share-cleanup")
    }

    func testContinuedCanonicalFifteenSourcesWithoutHostActivation() throws {
        // XCTest's stop-on-first-failure exception bypasses Swift defer. Keep
        // assertions recording failures so the real configuration is restored.
        continueAfterFailure = true
        // This field also contributes visible GlassCard text. Keep the unique
        // fixture within its layout budget instead of bypassing overflow checks.
        let caption = "Q" + String(Int(Date().timeIntervalSince1970), radix: 36)
        application.launchArguments += ["-continuedProductionPipelineProbe"]
        launchHostAndWait()
        try openDescriptionSettingsForQA()
        let toggle = descriptionSupplementToggle()
        XCTAssertTrue(toggle.waitForExistence(timeout: 10))
        let originalUsesCustom = toggle.value as? String == "1"
        if !originalUsesCustom { toggle.tap() }
        let field = descriptionSupplementField()
        XCTAssertTrue(field.waitForExistence(timeout: 10))
        let originalValue = field.value as? String ?? ""
        let originalText = originalValue == "写下想补充的话" ? "" : originalValue
        defer {
            application.activate()
            do {
                try openDescriptionSettingsForQA()
                let restoreToggle = descriptionSupplementToggle()
                if restoreToggle.value as? String != "1" { restoreToggle.tap() }
                try replaceDescriptionSupplement(with: originalText)
                if !originalUsesCustom { restoreToggle.tap() }
                try saveDescriptionConfigurationForQA()
            } catch { XCTFail("Could not restore the user's description configuration: \(error)") }
            application.launchArguments = ["-uiTesting", "-uiTestingHarnessOnly", "-disableContinuedProcessingSpike"]
            launchHostAndWait()
            XCUIDevice.shared.press(.home)
        }
        try replaceDescriptionSupplement(with: caption)
        try saveDescriptionConfigurationForQA()
        let roundStartedAt = Date().timeIntervalSince1970
        try performMultiplePhotosBackgroundWithoutHostActivation(indices: [], expectedOutputCount: 15, selectAllInputs: true)
        let outputs = try inventoryAlbum(titled: "MemoMark QA Outputs", attachmentName: "canonical-fifteen-outputs.json")
        let inputs = try inventoryAlbum(titled: "MemoMark QA Inputs", attachmentName: "canonical-fifteen-originals.json")
        XCTAssertEqual(inputs.assetCount, 15)
        XCTAssertEqual(outputs.assetCount, 15)
        XCTAssertEqual(outputs.assets.compactMap(\.creationDate).sorted(), inputs.assets.compactMap(\.creationDate).sorted())
        try verifySavedStillMetadata(outputs, expectedDescription: caption)
        verifySavedMoviePairingSynchronously(outputs)
        try observeContinuedCompletionWindow(requestCount: 1, since: roundStartedAt)
        XCTAssertNotEqual(application.state, .runningForeground)
        try deleteOutputsAddedSince([], attachmentPrefix: "canonical-fifteen-cleanup")
    }

    func testContinuedAllFifteenSourcesWithoutHostActivation() throws {
        let caption = "十五张混合素材后台验证 \(Int(Date().timeIntervalSince1970))"
        application.launchArguments += ["-continuedProductionPipelineProbe",
            "-continuedPhotoDescriptionOverrideProbe", caption]
        launchHostAndWait()
        let roundStartedAt = Date().timeIntervalSince1970
        defer {
            application.launchArguments = ["-uiTesting", "-uiTestingHarnessOnly", "-disableContinuedProcessingSpike"]
            launchHostAndWait()
            XCUIDevice.shared.press(.home)
        }
        try performMultiplePhotosBackgroundWithoutHostActivation(indices: [], expectedOutputCount: 15,
            selectAllInputs: true)
        let outputs = try inventoryAlbum(titled: "MemoMark QA Outputs", attachmentName: "all-fifteen-outputs.json")
        let inputs = try inventoryAlbum(titled: "MemoMark QA Inputs", attachmentName: "all-fifteen-originals.json")
        XCTAssertEqual(inputs.assetCount, 15)
        XCTAssertEqual(outputs.assetCount, 15)
        XCTAssertEqual(outputs.assets.compactMap(\.creationDate).sorted(), inputs.assets.compactMap(\.creationDate).sorted())
        try verifySavedStillMetadata(outputs, expectedDescription: caption)
        verifySavedMoviePairingSynchronously(outputs)
        try observeContinuedCompletionWindow(requestCount: 1, since: roundStartedAt)
        try deleteOutputsAddedSince([], attachmentPrefix: "all-fifteen-cleanup")
    }

    func testContinuedNativeProgressSurfaceSevenPhotos() throws {
        application.launchArguments = ["-uiTesting", "-uiTestingHarnessOnly", "-continuedProductionPipelineProbe",
            "-continuedPhotoDescriptionOverrideProbe", "专注模式原生通知验证"]
        launchHostAndWait()
        let roundStartedAt = Date().timeIntervalSince1970
        defer {
            application.launchArguments = ["-uiTesting", "-uiTestingHarnessOnly", "-disableContinuedProcessingSpike"]
            launchHostAndWait()
            XCUIDevice.shared.press(.home)
        }
        try performMultiplePhotosBackgroundWithoutHostActivation(indices: [0, 1, 2, 3, 4, 5, 6], observeOutputs: false)
        let settled = expectation(description: "System Share dismissal animation settles before the top-status capture")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { settled.fulfill() }
        wait(for: [settled], timeout: 3)
        XCTAssertNotEqual(application.state, .runningForeground)
        let island = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        island.name = "share-dismissed-dynamic-island"
        island.lifetime = .keepAlways
        add(island)
        try testBackgroundNotificationCenterReadback()
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        XCTAssertFalse(springboard.staticTexts["处理已完成"].exists,
            "A historical custom ActivityKit completion card must not coexist with the system processing experiment.")
        springboard.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.97))
            .press(forDuration: 0.1, thenDragTo: springboard.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.2)))
        try observeCompletedPhotoOutputs(expectedOutputCount: 7)
        try observeContinuedCompletionWindow(requestCount: 1, since: roundStartedAt)
        let outputs = try inventoryAlbum(titled: "MemoMark QA Outputs", attachmentName: "native-progress-output-readback.json")
        XCTAssertEqual(outputs.assetCount, 7)
        try verifySavedStillMetadata(outputs, expectedDescription: "专注模式原生通知验证")
        try testBackgroundNotificationCenterReadback()
        XCTAssertTrue(springboard.descendants(matching: .any).matching(
            NSPredicate(format: "label CONTAINS %@", "已保存到「MemoMark QA Outputs」。")).firstMatch.exists,
            "The native result notification must identify the saved output album.")
        let clock = DateFormatter()
        clock.locale = Locale(identifier: "zh_CN")
        clock.dateFormat = "HH:mm"
        let firstMinute = Int(roundStartedAt / 60)
        let lastMinute = Int(Date().timeIntervalSince1970 / 60)
        let currentRoundTitles = (firstMinute...lastMinute).map { minute in
            clock.string(from: Date(timeIntervalSince1970: Double(minute * 60))) + " 处理 7 张照片已完成"
        }
        let freshTitle = springboard.staticTexts.matching(NSPredicate(format: "label IN %@", currentRoundTitles)).firstMatch
        XCTAssertTrue(freshTitle.exists && freshTitle.isHittable,
            "A historical notification cannot certify this round; the current round's result must be visibly exposed.")
        springboard.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.97))
            .press(forDuration: 0.1, thenDragTo: springboard.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.2)))
        try deleteOutputsAddedSince([], attachmentPrefix: "native-progress-cleanup")
    }

    func testContinuedDynamicIslandWithPhotosBackgrounded() throws {
        let roundCaption = "灵动岛后台切换验证 \(Int(Date().timeIntervalSince1970))"
        application.launchArguments = ["-uiTesting", "-uiTestingHarnessOnly", "-continuedProductionPipelineProbe",
            "-continuedPhotoDescriptionOverrideProbe", roundCaption]
        launchHostAndWait()
        let roundStartedAt = Date().timeIntervalSince1970
        defer {
            application.launchArguments = ["-uiTesting", "-uiTestingHarnessOnly", "-disableContinuedProcessingSpike"]
            launchHostAndWait()
            XCUIDevice.shared.press(.home)
        }
        try performMultiplePhotosBackgroundWithoutHostActivation(indices: [0, 1, 2, 3, 4, 5, 6], observeOutputs: false)
        let settled = expectation(description: "Photos Share dismissal settles before comparison")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { settled.fulfill() }
        wait(for: [settled], timeout: 3)
        let photosScreenshot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        photosScreenshot.name = "continued-island-photos-foreground"
        photosScreenshot.lifetime = .keepAlways
        add(photosScreenshot)
        XCUIDevice.shared.press(.home)
        let homeSettled = expectation(description: "System Home transition settles while processing continues")
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { homeSettled.fulfill() }
        wait(for: [homeSettled], timeout: 4)
        XCTAssertNotEqual(application.state, .runningForeground)
        let homeScreenshot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        homeScreenshot.name = "continued-island-photos-background"
        homeScreenshot.lifetime = .keepAlways
        add(homeScreenshot)
        let state = XCTAttachment(string: XCUIApplication(bundleIdentifier: "com.apple.springboard").debugDescription)
        state.name = "continued-island-photos-background-state"
        state.lifetime = .keepAlways
        add(state)
        try observeCompletedPhotoOutputs(expectedOutputCount: 7)
        try observeContinuedCompletionWindow(requestCount: 1, since: roundStartedAt)
        let outputs = try inventoryAlbum(titled: "MemoMark QA Outputs", attachmentName: "island-round-output-readback.json")
        XCTAssertEqual(outputs.assetCount, 7)
        try verifySavedStillMetadata(outputs, expectedDescription: roundCaption)
        try deleteOutputsAddedSince([], attachmentPrefix: "island-round-cleanup")
    }

    func testContinuedStopWaitingShareWithoutHostActivation() throws {
        application.launchArguments = ["-uiTesting", "-uiTestingHarnessOnly", "-continuedProductionPipelineProbe",
            "-continuedPhotoDescriptionOverrideProbe", "等待执行权停止 \(Int(Date().timeIntervalSince1970))"]
        launchHostAndWait()
        try performMultiplePhotosBackgroundWithoutHostActivation(indices: [], expectedOutputCount: 15,
            observeOutputs: false, selectAllInputs: true)
        try performMultiplePhotosBackgroundWithoutHostActivation(indices: [0, 1, 2],
            expectedBaselineCount: nil, observeOutputs: false)
        XCUIDevice.shared.press(.home)
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        let cards = springboard.otherElements.matching(NSPredicate(
            format: "identifier == %@ AND label CONTAINS %@", "regular.view", "时光记正在处理照片"))
        let pending = cards.containing(.staticText, identifier: "正在准备照片").firstMatch
        let state = XCTAttachment(string: springboard.debugDescription)
        state.name = "waiting-share-system-state-before-stop"
        state.lifetime = .keepAlways
        add(state)
        XCTAssertTrue(pending.waitForExistence(timeout: 5), "Stop only the preparing request; never guess by card order.")
        let pendingState = XCTAttachment(string: pending.debugDescription)
        pendingState.name = "waiting-share-card-before-cancel"
        pendingState.lifetime = .keepAlways
        add(pendingState)
        let visibleStop = NSPredicate(format: "exists == true AND hittable == true")
        let ready = expectation(for: visibleStop, evaluatedWith: pending.buttons["取消"])
        wait(for: [ready], timeout: 5)
        XCTAssertTrue(pending.buttons["取消"].isHittable)
        pending.buttons["取消"].tap()
        XCTAssertNotEqual(application.state, .runningForeground)
        try observeCompletedPhotoOutputs(expectedOutputCount: 15)
        let outputs = try inventoryAlbum(titled: "MemoMark QA Outputs", attachmentName: "waiting-stop-owner-outputs.json")
        XCTAssertEqual(outputs.assetCount, 15)
        application.launchArguments = ["-uiTesting", "-uiTestingHarnessOnly", "-disableContinuedProcessingSpike"]
        launchHostAndWait()
        let resume = application.buttons["继续处理"]
        XCTAssertTrue(resume.waitForExistence(timeout: 10), "Cancelled waiting intake must become a held job.")
        application.terminate()
        launchHostAndWait()
        XCTAssertTrue(resume.waitForExistence(timeout: 10))
        let held = try inventoryAlbum(titled: "MemoMark QA Outputs", attachmentName: "waiting-stop-host-held-outputs.json")
        XCTAssertEqual(Set(held.assets.map(\.localIdentifier)), Set(outputs.assets.map(\.localIdentifier)))
        resume.tap()
        waitForProcessingCompletionSurface(scenario: "waiting-share-explicit-resume", timeout: 240)
        let resumed = try inventoryAlbum(titled: "MemoMark QA Outputs", attachmentName: "waiting-stop-resumed-outputs.json")
        XCTAssertEqual(Set(resumed.assets.map(\.localIdentifier)), Set(outputs.assets.map(\.localIdentifier)))
        XCTAssertEqual(try inventoryAlbum(titled: "MemoMark QA Inputs", attachmentName: "waiting-stop-originals.json").assetCount, 15)
        try deleteOutputsAddedSince([], attachmentPrefix: "waiting-stop-cleanup")
        XCUIDevice.shared.press(.home)
    }

    func testContinuedStopThenResendWithoutHostActivation() throws {
        let caption = "中断后重新分享验证 \(Int(Date().timeIntervalSince1970))"
        application.launchArguments = ["-uiTesting", "-uiTestingHarnessOnly", "-continuedProductionPipelineProbe",
            "-continuedPhotoDescriptionOverrideProbe", caption]
        launchHostAndWait()
        XCTAssertEqual(try inventoryAlbum(titled: "MemoMark QA Outputs", attachmentName: "resend-empty-baseline.json").assetCount, 0)
        try performMultiplePhotosBackgroundWithoutHostActivation(indices: [], expectedOutputCount: 15,
            observeOutputs: false, selectAllInputs: true)
        XCUIDevice.shared.press(.home)
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        let card = springboard.otherElements.matching(NSPredicate(
            format: "identifier == %@ AND label CONTAINS %@", "regular.view", "时光记正在处理照片")).firstMatch
        XCTAssertTrue(card.waitForExistence(timeout: 10))
        var savedCount = 0
        for checkpoint in 1...10 {
            let interval = expectation(description: "Wait for real partial output before stopping")
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) { interval.fulfill() }
            wait(for: [interval], timeout: 5)
            savedCount = try inventoryAlbum(titled: "MemoMark QA Outputs", attachmentName: "resend-partial-\(checkpoint).json").assetCount
            if savedCount > 0 { break }
        }
        XCTAssertGreaterThan(savedCount, 0, "A zero-output stop cannot prove partial-save idempotency.")
        XCTAssertLessThan(savedCount, 15)
        let stop = card.buttons["取消"]
        XCTAssertTrue(stop.isHittable)
        stop.tap()
        let settle = expectation(description: "Settle native cancellation and submitted save")
        DispatchQueue.main.asyncAfter(deadline: .now() + 10) { settle.fulfill() }
        wait(for: [settle], timeout: 15)
        let stopped = try inventoryAlbum(titled: "MemoMark QA Outputs", attachmentName: "resend-stopped-assets.json")
        let hold = expectation(description: "Cancelled work must stop independently")
        DispatchQueue.main.asyncAfter(deadline: .now() + 10) { hold.fulfill() }
        wait(for: [hold], timeout: 15)
        let stable = try inventoryAlbum(titled: "MemoMark QA Outputs", attachmentName: "resend-stable-assets.json")
        XCTAssertEqual(Set(stopped.assets.map(\.localIdentifier)), Set(stable.assets.map(\.localIdentifier)))
        XCTAssertNotEqual(application.state, .runningForeground)
        try performMultiplePhotosBackgroundWithoutHostActivation(indices: [], expectedOutputCount: 15,
            expectedBaselineCount: nil, selectAllInputs: true)
        let outputs = try inventoryAlbum(titled: "MemoMark QA Outputs", attachmentName: "resend-final-assets.json")
        XCTAssertEqual(outputs.assetCount, 15)
        XCTAssertTrue(Set(stable.assets.map(\.localIdentifier)).isSubset(of: Set(outputs.assets.map(\.localIdentifier))))
        try verifySavedStillMetadata(outputs, expectedDescription: caption)
        verifySavedMoviePairingSynchronously(outputs)
        XCTAssertEqual(try inventoryAlbum(titled: "MemoMark QA Inputs", attachmentName: "resend-originals.json").assetCount, 15)
        XCTAssertNotEqual(application.state, .runningForeground)
        try deleteOutputsAddedSince([], attachmentPrefix: "resend-cleanup")
        application.launchArguments = ["-uiTesting", "-uiTestingHarnessOnly", "-disableContinuedProcessingSpike"]
        launchHostAndWait()
        XCUIDevice.shared.press(.home)
    }

    func testContinuedNativeStopWithoutHostActivation() throws {
        application.launchArguments = ["-uiTesting", "-uiTestingHarnessOnly", "-continuedProductionPipelineProbe",
            "-continuedPhotoDescriptionOverrideProbe", "原生停止验证 \(Int(Date().timeIntervalSince1970))"]
        launchHostAndWait()
        try performMultiplePhotosBackgroundWithoutHostActivation(indices: [], expectedOutputCount: 15,
            observeOutputs: false, selectAllInputs: true)
        XCUIDevice.shared.press(.home)
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        let card = springboard.otherElements.matching(NSPredicate(
            format: "identifier == %@ AND label CONTAINS %@", "regular.view", "时光记正在处理照片")).firstMatch
        XCTAssertTrue(card.waitForExistence(timeout: 10), "Stop testing requires the actual MemoMark system card.")
        let stop = card.buttons["取消"]
        XCTAssertTrue(stop.isHittable)
        let before = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        before.name = "continued-native-stop-before"
        before.lifetime = .keepAlways
        add(before)
        stop.tap()
        XCTAssertNotEqual(application.state, .runningForeground)
        let settle = expectation(description: "Allow system stop and any already submitted save to settle")
        DispatchQueue.main.asyncAfter(deadline: .now() + 10) { settle.fulfill() }
        wait(for: [settle], timeout: 15)
        let first = try inventoryAlbum(titled: "MemoMark QA Outputs", attachmentName: "native-stop-first-output-check.json")
        let observe = expectation(description: "Observe no further output without foreground recovery")
        DispatchQueue.main.asyncAfter(deadline: .now() + 15) { observe.fulfill() }
        wait(for: [observe], timeout: 20)
        let second = try inventoryAlbum(titled: "MemoMark QA Outputs", attachmentName: "native-stop-second-output-check.json")
        XCTAssertEqual(Set(first.assets.map(\.localIdentifier)), Set(second.assets.map(\.localIdentifier)))
        XCTAssertLessThan(second.assetCount, 15, "Stopping must interrupt the round before all inputs finish.")
        XCTAssertNotEqual(application.state, .runningForeground)
        let after = XCTAttachment(string: springboard.debugDescription)
        after.name = "continued-native-stop-after-state"
        after.lifetime = .keepAlways
        add(after)
        try testBackgroundNotificationCenterReadback()
        let pausedNotice = springboard.staticTexts.matching(NSPredicate(
            format: "label CONTAINS %@", "时光记处理已暂停")).firstMatch
        XCTAssertTrue(pausedNotice.waitForExistence(timeout: 10),
                      "System interruption must provide the native durable pause notice.")
        XCUIDevice.shared.press(.home)
        // Background stop proof ends above. Opening MemoMark must now expose
        // explicit resume rather than automatically restarting the stopped work.
        application.launchArguments = ["-uiTesting", "-uiTestingHarnessOnly", "-disableContinuedProcessingSpike", "-processingQueueSnapshotProbe"]
        launchHostAndWait()
        let resume = application.buttons["继续处理"]
        XCTAssertTrue(resume.waitForExistence(timeout: 10))
        let held = expectation(description: "Opening MemoMark must not resume system-stopped work")
        DispatchQueue.main.asyncAfter(deadline: .now() + 15) { held.fulfill() }
        wait(for: [held], timeout: 20)
        let heldOutputs = try inventoryAlbum(titled: "MemoMark QA Outputs", attachmentName: "native-stop-host-open-held-output-check.json")
        XCTAssertEqual(Set(heldOutputs.assets.map(\.localIdentifier)), Set(second.assets.map(\.localIdentifier)))
        application.terminate()
        launchHostAndWait()
        XCTAssertTrue(resume.waitForExistence(timeout: 10))
        attachCurrentScreenshot(named: "native-stop-hold-survives-relaunch")
        XCUIDevice.shared.press(.home)
    }

    func testExplicitResumeOfSystemStoppedSessionFromHome() throws {
        application.launchArguments = ["-uiTesting", "-uiTestingHarnessOnly", "-disableContinuedProcessingSpike"]
        launchHostAndWait()
        let before = try inventoryAlbum(titled: "MemoMark QA Outputs", attachmentName: "explicit-system-stop-resume-before.json")
        XCTAssertLessThan(before.assetCount, 15)
        let resume = application.buttons["继续处理"]
        XCTAssertTrue(resume.waitForExistence(timeout: 10), "A held session requires the explicit Home resume action.")
        resume.tap()
        waitForProcessingCompletionSurface(scenario: "explicit-system-stop-resume", timeout: 240)
        let after = try inventoryAlbum(titled: "MemoMark QA Outputs", attachmentName: "explicit-system-stop-resume-after.json")
        XCTAssertEqual(after.assetCount, 15)
        XCTAssertTrue(Set(before.assets.map(\.localIdentifier)).isSubset(of: Set(after.assets.map(\.localIdentifier))),
            "Resume must retain previously saved assets rather than replacing or duplicating them.")
        XCTAssertEqual(after.assets.filter { $0.classification == "livePhoto" }.count, 1)
        XCTAssertEqual(try inventoryAlbum(titled: "MemoMark QA Inputs", attachmentName: "explicit-resume-original-inputs.json").assetCount, 15)
        try deleteOutputsAddedSince([], attachmentPrefix: "explicit-system-stop-resume-cleanup")
        XCUIDevice.shared.press(.home)
    }

    func testSavedPhotoKitDescriptionDiagnostics() throws {
        let outputs = try inventoryAlbum(titled: "MemoMark QA Outputs", attachmentName: "saved-description-diagnostic-outputs.json")
        XCTAssertEqual(outputs.assetCount, 3)
        try verifySavedStillMetadata(outputs, expectedDescription: "后台配对读回验证", requireDescription: false)
    }

    func testRestoreOriginalQADescriptionConfiguration() throws {
        launchHostAndWait()
        try openDescriptionSettingsForQA()
        let toggle = descriptionSupplementToggle()
        if toggle.value as? String != "1" { toggle.tap() }
        try replaceDescriptionSupplement(with: "")
        if toggle.value as? String == "1" { toggle.tap() }
        try saveDescriptionConfigurationForQA()
        XCUIDevice.shared.press(.home)
    }

    private func openDescriptionSettingsForQA() throws {
        XCTAssertTrue(application.wait(for: .runningForeground, timeout: 15))
        let config = application.buttons["配置"]
        XCTAssertTrue(config.waitForExistence(timeout: 10))
        let configReady = XCTNSPredicateExpectation(predicate: NSPredicate(format: "hittable == true"), object: config)
        XCTAssertEqual(XCTWaiter.wait(for: [configReady], timeout: 10), .completed)
        config.tap()
        let expand = application.buttons.matching(NSPredicate(
            format: "label == %@ OR label BEGINSWITH %@", "展开照片说明设置", "照片说明")).firstMatch
        for _ in 0..<6 where !(expand.exists && expand.isHittable)
            && !(descriptionSupplementToggle().exists && descriptionSupplementToggle().isHittable) {
            let scroll = application.scrollViews.firstMatch
            if scroll.exists { scroll.swipeUp() } else { application.swipeUp() }
        }
        if expand.exists && expand.isHittable && !descriptionSupplementToggle().exists { expand.tap() }
        if !descriptionSupplementToggle().exists {
            let state = XCTAttachment(string: application.debugDescription)
            state.name = "description-settings-missing-control-hierarchy"
            state.lifetime = .keepAlways
            add(state)
            attachCurrentScreenshot(named: "description-settings-missing-control")
        }
        XCTAssertTrue(descriptionSupplementToggle().waitForExistence(timeout: 10))
    }

    private func descriptionSupplementToggle() -> XCUIElement {
        application.switches.matching(NSPredicate(format: "label CONTAINS %@", "补充一句话")).firstMatch
    }

    private func descriptionSupplementField() -> XCUIElement {
        let identifier = "output-photo-description-input"
        let textView = application.textViews.matching(identifier: identifier).firstMatch
        if textView.exists { return textView }
        let textField = application.textFields.matching(identifier: identifier).firstMatch
        if textField.exists { return textField }
        let container = application.descendants(matching: .any).matching(identifier: identifier).firstMatch
        let nestedTextField = container.descendants(matching: .textField).firstMatch
        if nestedTextField.exists { return nestedTextField }
        let nestedTextView = container.descendants(matching: .textView).firstMatch
        return nestedTextView.exists ? nestedTextView : container
    }

    private func replaceDescriptionSupplement(with text: String) throws {
        let field = descriptionSupplementField()
        XCTAssertTrue(field.waitForExistence(timeout: 10))
        field.tap()
        if !application.keyboards.firstMatch.waitForExistence(timeout: 3) {
            field.coordinate(withNormalizedOffset: CGVector(dx: 0.1, dy: 0.5)).tap()
        }
        XCTAssertTrue(application.keyboards.firstMatch.waitForExistence(timeout: 5))
        let value = field.value as? String ?? ""
        let current = value == "写下想补充的话" ? "" : value
        if !current.isEmpty {
            field.press(forDuration: 1.2)
            var selectAll = application.menuItems.matching(NSPredicate(format: "label IN %@", ["全选", "Select All"])).firstMatch
            if !selectAll.waitForExistence(timeout: 2) {
                selectAll = application.buttons.matching(NSPredicate(format: "label IN %@", ["全选", "Select All"])).firstMatch
            }
            XCTAssertTrue(selectAll.waitForExistence(timeout: 5), "Clear the field through native selection rather than deleting at an unknown caret position.")
            selectAll.tap()
            field.typeText(XCUIKeyboardKey.delete.rawValue)
        }
        if !text.isEmpty { field.typeText(text) }
        let replaced = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
            let value = field.value as? String ?? ""
            return text.isEmpty ? value == "写下想补充的话" || value.isEmpty : value == text
        }, object: nil)
        XCTAssertEqual(XCTWaiter.wait(for: [replaced], timeout: 5), .completed)
        // Temporarily removing the local FocusState field dismisses the
        // keyboard without Return, page-switch guards or modifying its text.
        let toggle = descriptionSupplementToggle()
        toggle.tap()
        XCTAssertEqual(XCTWaiter.wait(for: [XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "exists == false"), object: descriptionSupplementField()
        )], timeout: 5), .completed)
        toggle.tap()
        XCTAssertTrue(descriptionSupplementField().waitForExistence(timeout: 5))

    }

    private func saveDescriptionConfigurationForQA() throws {
        let save = application.buttons["保存配置"]
        if save.waitForExistence(timeout: 5), save.isEnabled { save.tap() }
        XCTAssertTrue(application.buttons["已保存"].waitForExistence(timeout: 15))
    }

    func testContinuedProductionRepeatedIntentAfterDismissal() throws {
        application.launchArguments += ["-continuedProductionPipelineProbe"]
        application.launch()
        XCTAssertTrue(application.wait(for: .runningForeground, timeout: 20))
        // These three exact source/configuration intents already completed.
        // This only observes duplicate submission after the dismissal gate;
        // zero outputs is not proof of fresh production processing completion.
        try performMultiplePhotosBackgroundWithoutHostActivation(indices: [1, 3, 5], expectedOutputCount: 0)
    }

    func testCleanupThreeHostMarkerOutputs() throws {
        XCTAssertEqual(try inventoryAlbum(titled: "MemoMark QA Inputs", attachmentName: "host-marker-originals.json").assetCount, 15)
        XCTAssertEqual(try inventoryAlbum(titled: "MemoMark QA Outputs", attachmentName: "host-marker-cleanup-before.json").assetCount, 3)
        try deleteOutputsAddedSince([], attachmentPrefix: "host-marker-recovery-cleanup")
    }

    func testCleanupRootDiagnosisOutputs() throws {
        XCTAssertEqual(try inventoryAlbum(titled: "MemoMark QA Inputs", attachmentName: "root-originals.json").assetCount, 15)
        let outputs = try inventoryAlbum(titled: "MemoMark QA Outputs", attachmentName: "root-cleanup-before.json")
        guard outputs.assetCount <= 3 else {
            XCTFail("Root diagnosis cleanup must contain only this three-input round's QA outputs")
            return
        }
        try deleteOutputsAddedSince([], attachmentPrefix: "root-diagnosis-cleanup")
    }

    func testHostQueueFixtureForegroundRecovery() throws {
        let caption = "主程序恢复验证 \(Int(Date().timeIntervalSince1970))"
        application.launchArguments += ["-continuedHostQueueProbe", "-continuedProductionPipelineProbe",
            "-continuedPhotoDescriptionOverrideProbe", caption]
        launchHostAndWait()
        try performMultiplePhotosBackgroundWithoutHostActivation(indices: [0, 3, 6],
            expectedOutputCount: 3, observeOutputs: false)
        application.activate()
        XCTAssertTrue(application.wait(for: .runningForeground, timeout: 20))
        var outputs = try inventoryAlbum(titled: "MemoMark QA Outputs", attachmentName: "host-fixture-first-readback.json")
        for checkpoint in 1...12 where outputs.assetCount < 3 {
            let interval = expectation(description: "Observe actual foreground saved outputs")
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) { interval.fulfill() }
            wait(for: [interval], timeout: 8)
            outputs = try inventoryAlbum(titled: "MemoMark QA Outputs", attachmentName: "host-fixture-output-\(checkpoint).json")
        }
        XCTAssertEqual(outputs.assetCount, 3)
        try verifySavedStillMetadata(outputs, expectedDescription: caption)
        verifySavedMoviePairingSynchronously(outputs)
        try deleteOutputsAddedSince([], attachmentPrefix: "host-fixture-recovery-cleanup")
        XCUIDevice.shared.press(.home)
    }

    func testContinuedUniqueHostQueueWithoutHostActivation() throws {
        application.launchArguments += ["-continuedHostUniqueQueueProbe"]
        try testContinuedHostQueueWithoutHostActivation()
    }

    func testContinuedHostQueueWithoutHostActivation() throws {
        application.launchArguments += ["-continuedHostQueueProbe", "-continuedProductionPipelineProbe",
            "-continuedPhotoDescriptionOverrideProbe", "正式后台入口验证 \(Int(Date().timeIntervalSince1970))"]
        launchHostAndWait()
        try performMultiplePhotosBackgroundWithoutHostActivation(indices: [0, 3, 6], expectedOutputCount: 3)
        let outputs = try inventoryAlbum(titled: "MemoMark QA Outputs", attachmentName: "host-queue-output-readback.json")
        XCTAssertEqual(outputs.assetCount, 3)
        verifySavedMoviePairingSynchronously(outputs)
        XCTAssertNotEqual(application.state, .runningForeground)
        try deleteOutputsAddedSince([], attachmentPrefix: "host-queue-cleanup")
    }

    func testContinuedHostHandoffSubmissionWithoutHostActivation() throws {
        application.launchArguments += ["-continuedHostHandoffProbe"]
        application.launch()
        XCTAssertTrue(application.wait(for: .runningForeground, timeout: 20))
        try performMultiplePhotosBackgroundWithoutHostActivation(indices: [0, 3, 6], hostMarkerOnly: true)
        // Submission/UI assertions alone are not certification. Independently
        // read hostCallback + markerCompleted from the App Group after this test.
    }

    func testIsolatedContinuedHostSelfSubmission() throws {
        application.launchArguments += ["-isolatedPrepare", "-isolatedSelfSubmit"]
        application.launch()
        XCTAssertTrue(application.staticTexts["host-handoff-isolated-home"].waitForExistence(timeout: 20))
        let observation = expectation(description: "Observe isolated self-submission marker")
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) { observation.fulfill() }
        wait(for: [observation], timeout: 10)
        XCUIDevice.shared.press(.home)
    }

    func testIsolatedContinuedHostHandoffAsync() throws {
        try performIsolatedHostHandoff(arguments: [])
    }

    func testIsolatedContinuedHostHandoffLegacy() throws {
        try performIsolatedHostHandoff(arguments: ["-isolatedLegacySubmission"])
    }

    func testIsolatedContinuedExtensionOwnerAsync() throws {
        try performIsolatedHostHandoff(arguments: ["-isolatedExtensionOwner"])
    }

    private func performIsolatedHostHandoff(arguments: [String]) throws {
        application.launchArguments += ["-isolatedPrepare"] + arguments
        application.launch()
        XCTAssertTrue(application.staticTexts["host-handoff-isolated-home"].waitForExistence(timeout: 20))
        try performMultiplePhotosBackgroundWithoutHostActivation(indices: [0, 3, 6], hostMarkerOnly: true)
    }

    private func performMultiplePhotosBackgroundWithoutHostActivation(indices: [Int], hostMarkerOnly: Bool = false, expectedOutputCount: Int = 3, expectedBaselineCount: Int? = 0, observeOutputs: Bool = true, expectedInputCount: Int = 15, selectAllInputs: Bool = false, activateHostAfterSubmission: Bool = false, inputAlbumTitle: String = "MemoMark QA Inputs", minimumObservationCheckpoints: Int = 1) throws {
        let inputs = try inventoryAlbum(titled: inputAlbumTitle, attachmentName: "background-input-baseline.json")
        let baseline = try inventoryAlbum(titled: "MemoMark QA Outputs", attachmentName: "background-output-baseline.json")
        if let expectedBaselineCount {
            XCTAssertEqual(baseline.assetCount, expectedBaselineCount, "Use the expected explicitly controlled QA album baseline.")
            guard baseline.assetCount == expectedBaselineCount else { throw CocoaError(.fileReadUnknown) }
        }
        XCTAssertEqual(inputs.assetCount, expectedInputCount)
        // Xcode starts the target when attaching the UI harness. Background
        // it before submitting any intake; no host activation is allowed
        // after submission. This proves warm background, not cold launch.
        XCUIDevice.shared.press(.home)
        let photos = XCUIApplication(bundleIdentifier: "com.apple.mobileslideshow")
        photos.activate()
        XCTAssertTrue(photos.wait(for: .runningForeground, timeout: 10))
        if photos.otherElements["photosSearchBar"].exists, photos.buttons["关闭"].exists {
            photos.buttons["关闭"].tap()
        }
        XCTAssertEqual(XCTWaiter.wait(for: [XCTNSPredicateExpectation(
            predicate: NSPredicate { _, _ in self.application.state != .runningForeground }, object: nil
        )], timeout: 10), .completed, "MemoMark must leave the foreground before any Share is submitted.")
        let cancelSelection = photos.buttons["取消"]
        if cancelSelection.exists {
            cancelSelection.tap()
            if !photos.buttons["选择"].waitForExistence(timeout: 3), cancelSelection.exists {
                // Photos can expose a valid navigation-button frame while
                // XCTest's automatic scrolling computes the hit point (-1,-1).
                // Retry only this observed, non-destructive selection control.
                cancelSelection.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
            }
            XCTAssertTrue(photos.buttons["选择"].waitForExistence(timeout: 10))
        }
        // A one-up photo surface can retain the album's AX subtree. Close
        // that surface before treating collectionTitle as an active grid.
        if photos.buttons["PUOneUpBarButtonItemIdentifierShare"].exists {
            let back = photos.buttons["BackButton"]
            guard back.isHittable else { throw CocoaError(.fileReadUnknown) }
            back.tap()
        }
        let alreadyInInputs = photos.staticTexts.matching(NSPredicate(
            format: "identifier == %@ AND label == %@", "collectionTitle", inputAlbumTitle
        )).firstMatch.exists
        if !alreadyInInputs {
            let collections = photos.buttons["CollectionsTab"]
            if !collections.exists {
                let back = photos.navigationBars.buttons.matching(NSPredicate(
                    format: "label IN %@", ["返回", "精选集", "Back", "Collections"]
                )).firstMatch
                if back.exists { back.tap() }
            }
            guard collections.waitForExistence(timeout: 10) else { throw CocoaError(.fileReadUnknown) }
            collections.tap()
            let album = photos.buttons.matching(NSPredicate(format: "identifier == %@ AND label == %@", "bookmarks", inputAlbumTitle)).firstMatch
            if album.exists {
                for _ in 0..<8 where !album.isHittable { photos.swipeDown() }
                guard album.isHittable else { throw CocoaError(.fileReadUnknown) }
                album.tap()
            } else {
                // A new isolated QA album is not in the user's pinned shelf.
                // Search its exact title without changing Photos preferences.
                let search = photos.buttons["SearchTab"]
                guard search.waitForExistence(timeout: 10) else { throw CocoaError(.fileReadUnknown) }
                search.tap()
                // Current iOS 27 Photos exposes its focused search bar as an
                // Other element rather than SearchField/TextField.
                let field = photos.otherElements["photosSearchBar"]
                guard field.waitForExistence(timeout: 10) else { throw CocoaError(.fileReadUnknown) }
                field.tap()
                guard photos.keyboards.firstMatch.waitForExistence(timeout: 5) else { throw CocoaError(.fileReadUnknown) }
                if photos.buttons["清除"].exists { photos.buttons["清除"].tap() }
                photos.typeText(inputAlbumTitle + "\n")
                // Album matches appear under Collections, while Photos is
                // selected by default even when its result count is zero.
                let collectionResults = photos.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "精选集(")).firstMatch
                if collectionResults.waitForExistence(timeout: 5) { collectionResults.tap() }
                let result = photos.staticTexts[inputAlbumTitle].firstMatch
                guard result.waitForExistence(timeout: 30) else {
                    let state = XCTAttachment(string: photos.debugDescription)
                    state.name = "named-qa-album-search-not-ready"
                    state.lifetime = .keepAlways
                    add(state)
                    throw CocoaError(.fileReadUnknown)
                }
                result.tap()
            }
        }
        let select = photos.buttons["选择"]
        guard select.waitForExistence(timeout: 10), select.isHittable else {
            throw CocoaError(.fileReadUnknown)
        }
        // Photos' synthesized AX tap has entered one-up instead of selection
        // on a second visit. Use the observed control's own current frame.
        select.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        let selectionReady = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
            photos.buttons["全选"].isHittable || photos.buttons["取消"].isHittable
        }, object: nil)
        guard XCTWaiter.wait(for: [selectionReady], timeout: 10) == .completed else {
            let state = XCTAttachment(string: photos.debugDescription)
            state.name = "background-selection-mode-not-ready"
            state.lifetime = .keepAlways
            add(state)
            throw CocoaError(.fileReadUnknown)
        }
        let grid = photos.otherElements.matching(identifier: "PXGGridLayout-Group").firstMatch
            .images.matching(identifier: "PXGGridLayout-Info")
        let minimumGridCount = selectAllInputs ? 1 : (indices.max() ?? -1) + 1
        let anchorDate = try XCTUnwrap(Self.date(from: inputs.assets.first?.creationDate))
        let anchorFormatter = DateFormatter()
        anchorFormatter.locale = Locale(identifier: "zh_CN")
        anchorFormatter.dateFormat = Calendar.current.component(.year, from: anchorDate) == Calendar.current.component(.year, from: Date())
            ? "M月dd日, HH:mm" : "yyyy年M月d日, HH:mm"
        let anchor = anchorFormatter.string(from: anchorDate)
        for _ in 0..<4 where grid.count > 0 && !grid.firstMatch.label.contains(anchor) {
            photos.swipeDown()
        }
        for _ in 0..<3 where grid.count > 0 && grid.count < minimumGridCount {
            photos.swipeUp()
        }
        let ready = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
            grid.count >= minimumGridCount && grid.count <= inputs.assetCount
                && grid.firstMatch.label.contains(anchor)
        }, object: nil)
        let readyResult = XCTWaiter.wait(for: [ready], timeout: 15)
        if readyResult != .completed {
            let state = XCTAttachment(string: photos.debugDescription)
            state.name = "background-input-grid-not-ready"
            state.lifetime = .keepAlways
            add(state)
        }
        XCTAssertEqual(readyResult, .completed, "Wait for the named QA input grid before touching any asset.")
        guard readyResult == .completed else { throw CocoaError(.fileReadUnknown) }
        XCTAssertGreaterThanOrEqual(grid.count, minimumGridCount)
        XCTAssertTrue(grid.firstMatch.label.contains(anchor), "Positional selection must start at the independently inventoried first asset.")
        // Scope to one Photos grid and verify its first-source anchor.
        // Visible-cell offsets alone must never stand in for global identity.
        if let firstIndex = indices.first {
            let firstItem = grid.element(boundBy: firstIndex)
            for _ in 0..<4 where !firstItem.isHittable { photos.swipeDown() }
        }
        if selectAllInputs {
            let selectAll = photos.buttons["全选"]
            guard selectAll.isHittable else { throw CocoaError(.fileReadUnknown) }
            selectAll.tap()
        }
        for index in indices {
            let date = try XCTUnwrap(Self.date(from: inputs.assets[index].creationDate))
            anchorFormatter.dateFormat = Calendar.current.component(.year, from: date) == Calendar.current.component(.year, from: Date())
                ? "M月dd日, HH:mm" : "yyyy年M月d日, HH:mm"
            let matches = grid.matching(NSPredicate(format: "label CONTAINS %@", anchorFormatter.string(from: date)))
            guard matches.count == 1 else { throw CocoaError(.fileReadUnknown) }
            let item = matches.firstMatch
            if item.frame.maxY > photos.frame.maxY - 120 { photos.swipeUp() }
            XCTAssertTrue(grid.firstMatch.label.contains(anchor), "Scrolling must retain the source-index anchor.")
            XCTAssertTrue(item.isHittable, "Each intended QA input must be reachable before selection.")
            item.tap()
        }
        let selectedState = XCTAttachment(string: photos.debugDescription)
        selectedState.name = "background-selected-photos-state"
        selectedState.lifetime = .keepAlways
        add(selectedState)
        let share = photos.buttons.matching(NSPredicate(format: "label IN %@", ["共享", "分享", "Share"])).firstMatch
        XCTAssertTrue(share.waitForExistence(timeout: 10))
        share.tap()
        let receiver = photos.cells.matching(NSPredicate(format: "label IN %@", ["时光记", "MemoMark"])).firstMatch
        XCTAssertTrue(receiver.waitForExistence(timeout: 10))
        receiver.tap()
        let confirm = photos.buttons["开始记录"]
        XCTAssertTrue(confirm.waitForExistence(timeout: 15))
        confirm.tap()
        let submitting = photos.buttons["正在提交"]
        XCTAssertEqual(XCTWaiter.wait(for: [XCTNSPredicateExpectation(predicate: NSPredicate(format: "exists == false"), object: submitting)], timeout: 120), .completed)
        XCTAssertEqual(XCTWaiter.wait(for: [XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "exists == false"), object: photos.staticTexts["本次分享"]
        )], timeout: 120), .completed, "Capture post-Share status only after the extension sheet has actually closed.")
        if activateHostAfterSubmission {
            XCTAssertTrue(
                application.wait(for: .runningForeground, timeout: 30),
                "Share must open MemoMark through the foreground handoff without a manual app switch."
            )
            let activityCard = application.descendants(matching: .any)
                .matching(NSPredicate(format: "identifier BEGINSWITH %@", "home-activity-record-"))
                .firstMatch
            XCTAssertTrue(
                activityCard.waitForExistence(timeout: 30),
                "Returning to MemoMark after Share must publish the active processing record on Home."
            )
            attachCurrentScreenshot(named: "share-return-home-activity-progress")
            let hierarchy = XCTAttachment(string: application.debugDescription)
            hierarchy.name = "share-return-home-activity-progress-hierarchy"
            hierarchy.lifetime = .keepAlways
            add(hierarchy)
            return
        }
        XCTAssertNotEqual(application.state, .runningForeground)
        let systemSurface = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        systemSurface.name = "ordinary-share-system-progress"
        systemSurface.lifetime = .keepAlways
        add(systemSurface)
        let systemState = XCTAttachment(string: XCUIApplication(bundleIdentifier: "com.apple.springboard").debugDescription)
        systemState.name = "ordinary-share-system-progress-state"
        systemState.lifetime = .keepAlways
        add(systemState)
        if !observeOutputs { return }
        XCUIDevice.shared.press(.home)
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        // The actual paired-device screenshot places the task's compact bubble
        // at this normalized point, to the right of the microphone activity.
        springboard.coordinate(withNormalizedOffset: CGVector(dx: 0.70, dy: 0.034)).press(forDuration: 1)
        let expanded = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        expanded.name = "ordinary-share-expanded-system-surface"
        expanded.lifetime = .keepAlways
        add(expanded)
        let expandedState = XCTAttachment(string: springboard.debugDescription)
        expandedState.name = "ordinary-share-expanded-system-state"
        expandedState.lifetime = .keepAlways
        add(expandedState)
        XCTAssertNotEqual(application.state, .runningForeground)
        try observeCompletedPhotoOutputs(expectedOutputCount: expectedOutputCount, hostMarkerOnly: hostMarkerOnly,
            minimumCheckpoints: minimumObservationCheckpoints)
    }

    private func observeCompletedPhotoOutputs(expectedOutputCount: Int, hostMarkerOnly: Bool = false, minimumCheckpoints: Int = 1) throws {
        var completed = false
        for checkpoint in 1...8 {
            XCTAssertNotEqual(application.state, .runningForeground, "Host foreground invalidates background certification.")
            let pause = expectation(description: "Background observation interval")
            DispatchQueue.main.asyncAfter(deadline: .now() + 30) { pause.fulfill() }
            wait(for: [pause], timeout: 35)
            let outputs = try inventoryAlbum(titled: "MemoMark QA Outputs", attachmentName: "background-output-checkpoint-\(checkpoint).json")
            if checkpoint == 1 {
                let progressSurface = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
                progressSurface.name = "ordinary-share-observed-progress"
                progressSurface.lifetime = .keepAlways
                add(progressSurface)
            }
            XCTAssertNotEqual(application.state, .runningForeground)
            if hostMarkerOnly {
                XCTAssertEqual(outputs.assetCount, 0, "The host handoff marker must not render or save Photos.")
                return
            }
            if outputs.assetCount > expectedOutputCount {
                XCTFail("Unexpected extra output identity; stop this acceptance round immediately.")
                throw CocoaError(.fileReadUnknown)
            }
            if outputs.assetCount == expectedOutputCount && checkpoint >= minimumCheckpoints { completed = true; break }
        }
        XCTAssertTrue(completed, "No foreground recovery is allowed: expected output count must be independently observed within the four-minute probe. Failure is evidence, not an iOS scheduling guarantee.")
        guard completed else { throw CocoaError(.fileReadUnknown) }
    }

    func testPendingShareRequestsResumeAfterHostActivation() throws {
        let baseline = try inventoryAlbum(
            titled: "MemoMark QA Outputs",
            attachmentName: "host-recovery-output-baseline.json"
        )
        XCTAssertEqual(baseline.assetCount, 0, "The named QA Outputs album must be empty before host recovery begins.")

        // Prior marker rounds intentionally persisted intake without consuming
        // it. Launching the host is the recovery action under test.
        application.launchArguments += ["-disableContinuedProcessingSpike"]
        launchHostAndWait()
        waitForProcessingCompletionSurface(
            scenario: "pending-share-host-recovery",
            timeout: 240
        )

        let processed = try inventoryAlbum(
            titled: "MemoMark QA Outputs",
            attachmentName: "host-recovery-output-readback.json"
        )
        XCTAssertGreaterThan(processed.assetCount, 0, "Opening MemoMark should resume persisted Photos shares and save verified output.")
        XCTAssertLessThanOrEqual(processed.assetCount, 7, "Global processing identity must not create more than one output per distinct QA source intent.")

        let outputIdentifiers = processed.assets.map(\.localIdentifier)
        let outputAssets = PHAsset.fetchAssets(
            withLocalIdentifiers: outputIdentifiers,
            options: nil
        )
        XCTAssertEqual(outputAssets.count, outputIdentifiers.count)
        // Reuse the system-confirmation-aware cleanup instead of waiting on
        // performChanges while the deletion permission alert is unanswered.
        try deleteOutputsAddedSince([], attachmentPrefix: "host-recovery-output-cleanup")
        let cleaned = try inventoryAlbum(
            titled: "MemoMark QA Outputs",
            attachmentName: "host-recovery-output-cleanup.json"
        )
        XCTAssertEqual(cleaned.assetCount, 0, "The QA output album must be empty after this round.")
        XCUIDevice.shared.press(.home)
    }

    func testMultiplePhotosShareAndRepeatIntent() throws {
        let inputs = try inventoryAlbum(titled: "MemoMark QA Inputs", attachmentName: "multi-input-baseline.json")
        let baseline = try inventoryAlbum(titled: "MemoMark QA Outputs", attachmentName: "multi-output-baseline.json")
        XCTAssertGreaterThan(inputs.assetCount, 1)
        application.launchArguments += ["-disableContinuedProcessingSpike"]
        launchHostAndWait()
        var previousOutputs = Set(baseline.assets.map(\.localIdentifier))
        let selections = [[0, 1], [2, 3], [4, 5], [5, 6]]
        XCTAssertEqual(inputs.assetCount, 7, "The prepared seven-input matrix must remain unchanged.")
        for pass in 1...8 {
            XCUIDevice.shared.press(.home)
            let photos = XCUIApplication(bundleIdentifier: "com.apple.mobileslideshow")
            photos.launch()
            let collections = photos.buttons["CollectionsTab"]
            XCTAssertTrue(collections.waitForExistence(timeout: 10))
            collections.tap()
            let album = photos.staticTexts["MemoMark QA Inputs"].firstMatch
            for _ in 0..<8 where !album.isHittable { photos.swipeUp() }
            XCTAssertTrue(album.isHittable)
            album.tap()
            let select = photos.buttons["选择"]
            XCTAssertTrue(select.waitForExistence(timeout: 10))
            select.tap()
            let grid = photos.images.matching(identifier: "PXGGridLayout-Info")
            XCTAssertEqual(grid.count, inputs.assetCount)
            for index in selections[(pass - 1) / 2] { grid.element(boundBy: index).tap() }
            let share = photos.buttons.matching(NSPredicate(format: "label IN %@", ["共享", "分享", "Share"])).firstMatch
            XCTAssertTrue(share.waitForExistence(timeout: 10))
            share.tap()
            let receiver = photos.cells.matching(NSPredicate(format: "label IN %@", ["时光记", "MemoMark"])).firstMatch
            XCTAssertTrue(receiver.waitForExistence(timeout: 10))
            receiver.tap()
            let confirm = photos.buttons["开始记录"]
            XCTAssertTrue(confirm.waitForExistence(timeout: 15))
            confirm.tap()
            let submitting = photos.buttons["正在提交"]
            _ = submitting.waitForExistence(timeout: 5)
            XCTAssertTrue(XCTWaiter.wait(for: [XCTNSPredicateExpectation(predicate: NSPredicate(format: "exists == false"), object: submitting)], timeout: 120) == .completed)
            application.activate()
            waitForProcessingCompletionSurface(scenario: "multi-share-pass-\(pass)", timeout: 240)
            let outputs = try inventoryAlbum(titled: "MemoMark QA Outputs", attachmentName: "multi-output-pass-\(pass).json")
            let identifiers = Set(outputs.assets.map(\.localIdentifier))
            let added = identifiers.subtracting(previousOutputs)
            if pass % 2 == 1 {
                XCTAssertLessThanOrEqual(added.count, 2, "At most one fresh output per input is permitted.")
                let addedAssets = outputs.assets.filter { added.contains($0.localIdentifier) }
                if !addedAssets.isEmpty {
                    for input in inputs.assets {
                        XCTAssertLessThanOrEqual(addedAssets.filter { $0.creationDate == input.creationDate }.count, 1, "No input may add more than one output.")
                    }
                    XCTAssertLessThanOrEqual(addedAssets.filter { $0.classification == "livePhoto" }.count, inputs.assets.filter { $0.classification == "livePhoto" }.count)
                }
            } else {
                XCTAssertTrue(added.isEmpty, "Repeating identical frozen intent must add no duplicate output.")
            }
            previousOutputs = identifiers
        }
        let preserved = try inventoryAlbum(titled: "MemoMark QA Inputs", attachmentName: "multi-input-after.json")
        XCTAssertEqual(Set(preserved.assets.map(\.localIdentifier)), Set(inputs.assets.map(\.localIdentifier)))
    }

    func testDeleteExistingInterruptedSessionWithoutCancelStep() throws {
        application.launchArguments += ["-disableContinuedProcessingSpike", "-processingQueueSnapshotProbe"]
        launchHostAndWait()
        let record = application.otherElements.matching(NSPredicate(
            format: "identifier BEGINSWITH %@", "home-activity-record-")).firstMatch
        XCTAssertTrue(record.waitForExistence(timeout: 15))
        let identifier = record.identifier
        let delete = application.buttons["home-activity-delete-record"]
        XCTAssertTrue(delete.waitForExistence(timeout: 15))
        attachCurrentScreenshot(named: "compact-home-before-direct-delete")
        delete.tap()
        let labels = ["删除任务记录", "Delete task record", "タスク履歴を削除", "작업 기록 삭제"]
        let confirm = application.alerts.buttons.matching(NSPredicate(format: "label IN %@", labels)).firstMatch
        XCTAssertTrue(confirm.waitForExistence(timeout: 10))
        confirm.tap()
        XCTAssertEqual(XCTWaiter.wait(for: [XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "exists == false"), object: application.otherElements[identifier])], timeout: 20), .completed)
        application.terminate()
        launchHostAndWait()
        XCTAssertFalse(application.otherElements[identifier].exists)
        attachCurrentScreenshot(named: "direct-delete-stays-deleted")
        XCUIDevice.shared.press(.home)
    }

    func testCancelDeleteExistingSessionWithoutNewShare() throws {
        application.launchArguments += ["-disableContinuedProcessingSpike", "-processingQueueSnapshotProbe"]
        launchHostAndWait()
        let pauseLabels = ["暂停处理", "Pause processing", "処理を一時停止", "처리 일시 정지"]
        let resumeLabels = ["继续处理", "Resume processing", "処理を再開", "처리 재개"]
        let pause = application.buttons.matching(NSPredicate(format: "label IN %@", pauseLabels)).firstMatch
        if pause.exists { pause.tap() }
        let controlState = XCTAttachment(string: application.debugDescription)
        controlState.name = "scoped-delete-current-home-state"
        controlState.lifetime = .keepAlways
        add(controlState)
        let cancelLabels = ["取消本轮", "Cancel session", "セッションをキャンセル", "세션 취소"]
        let cancel = application.buttons.matching(NSPredicate(format: "label IN %@", cancelLabels)).firstMatch
        if cancel.waitForExistence(timeout: 5) {
            cancel.tap()
            let confirm = application.alerts.buttons.matching(NSPredicate(format: "label IN %@", cancelLabels)).firstMatch
            XCTAssertTrue(confirm.waitForExistence(timeout: 10))
            confirm.tap()
        } else {
            XCTAssertTrue(application.buttons["home-activity-delete-record"].exists,
                "A session that has already terminated must expose its delete action.")
        }
        let controls = application.buttons.matching(NSPredicate(format: "label IN %@", pauseLabels + resumeLabels)).firstMatch
        XCTAssertEqual(XCTWaiter.wait(for: [XCTNSPredicateExpectation(predicate: NSPredicate(format: "exists == false"), object: controls)], timeout: 60), .completed)
        let delete = application.buttons["home-activity-delete-record"]
        XCTAssertTrue(delete.waitForExistence(timeout: 15))
        attachCurrentScreenshot(named: "existing-session-cancelled-delete-enabled")
        let record = application.otherElements.matching(NSPredicate(
            format: "identifier BEGINSWITH %@", "home-activity-record-")).firstMatch
        XCTAssertTrue(record.exists)
        let deletedRecordIdentifier = record.identifier
        delete.tap()
        let deleteLabels = ["删除任务记录", "Delete task record", "タスク履歴を削除", "작업 기록 삭제"]
        let deleteConfirm = application.alerts.buttons.matching(NSPredicate(format: "label IN %@", deleteLabels)).firstMatch
        XCTAssertTrue(deleteConfirm.waitForExistence(timeout: 10))
        deleteConfirm.tap()
        XCTAssertEqual(XCTWaiter.wait(for: [XCTNSPredicateExpectation(predicate: NSPredicate(format: "exists == false"), object: application.otherElements[deletedRecordIdentifier])], timeout: 20), .completed)
        attachCurrentScreenshot(named: "existing-session-history-deleted")
        application.terminate()
        launchHostAndWait()
        // Other retained history may legitimately become the Home projection.
        XCTAssertFalse(application.otherElements[deletedRecordIdentifier].exists)
        attachCurrentScreenshot(named: "deleted-session-stays-deleted-after-relaunch")
        XCUIDevice.shared.press(.home)
    }

    func testHomeActivityCancelWithAllFifteenQAInputs() throws {
        let inputs = try inventoryAlbum(
            titled: "MemoMark QA Inputs",
            attachmentName: "home-controls-input-baseline.json"
        )
        XCTAssertEqual(inputs.assetCount, 15)
        let outputsBefore = try inventoryAlbum(
            titled: "MemoMark QA Outputs",
            attachmentName: "home-controls-output-baseline.json"
        )
        XCTAssertEqual(outputsBefore.assetCount, 0)
        let baselineIdentifiers = Set(outputsBefore.assets.map(\.localIdentifier))
        var cleanupCompleted = false
        defer {
            if !cleanupCompleted {
                do {
                    try deleteOutputsAddedSince(
                        baselineIdentifiers,
                        attachmentPrefix: "home-controls-failure-cleanup"
                    )
                } catch {
                    XCTFail("Could not clean this round's outputs: \(error)")
                }
            }
        }

        application.launchArguments += ["-disableContinuedProcessingSpike"]
        launchHostAndWait()
        XCUIDevice.shared.press(.home)

        let photos = XCUIApplication(bundleIdentifier: "com.apple.mobileslideshow")
        photos.activate()
        if !photos.buttons["CollectionsTab"].exists {
            let cancelSelection = photos.buttons["取消"]
            if cancelSelection.exists { cancelSelection.tap() }
            let back = photos.navigationBars.buttons.firstMatch
            if back.exists { back.tap() }
        }
        let collections = photos.buttons["CollectionsTab"]
        XCTAssertTrue(collections.waitForExistence(timeout: 10))
        collections.tap()
        // Photos may restore a one-up viewer, and Featured Collections can
        // expose an album title as a card caption. Only accept the actual
        // album row in Collections; a title on the Featured page is not a
        // navigation target for this test.
        let album = photos.buttons.matching(
            NSPredicate(format: "identifier == %@ AND label == %@", "bookmarks", "MemoMark QA Inputs")
        ).firstMatch
        // The restored Photos collection view can retain a deep scroll offset.
        // The QA album is in the pinned shelf at the top, so scroll back up.
        for _ in 0..<8 where !album.isHittable { photos.swipeDown() }
        guard album.waitForExistence(timeout: 10), album.isHittable else {
            attachCurrentScreenshot(named: "home-controls-qa-album-not-visible")
            XCTFail("MemoMark QA Inputs album row was not visible in Collections; no media was selected.")
            return
        }
        album.tap()

        let select = photos.buttons["选择"]
        XCTAssertTrue(select.waitForExistence(timeout: 10))
        select.tap()
        let cells = photos.images.matching(identifier: "PXGGridLayout-Info")
        // Photos virtualizes offscreen cells; inventory above is the count authority.
        // The named QA album is the only input boundary for Select All.
        XCTAssertGreaterThan(cells.count, 0)
        let selectAll = photos.buttons["全选"]
        XCTAssertTrue(selectAll.waitForExistence(timeout: 10))
        selectAll.tap()
        let assistiveTouch = photos.coordinate(withNormalizedOffset: CGVector(dx: 0.06, dy: 0.95))
        let clearShareArea = photos.coordinate(withNormalizedOffset: CGVector(dx: 0.50, dy: 0.20))
        assistiveTouch.press(forDuration: 0.35, thenDragTo: clearShareArea)
        assistiveTouchWasMovedForShare = true
        let share = photos.buttons.matching(
            NSPredicate(format: "label IN %@", ["共享", "分享", "Share"])
        ).firstMatch
        XCTAssertTrue(share.waitForExistence(timeout: 10))
        share.tap()
        let memoMark = photos.cells.matching(
            NSPredicate(format: "label IN %@", ["时光记", "MemoMark"])
        ).firstMatch
        XCTAssertTrue(memoMark.waitForExistence(timeout: 10))
        memoMark.tap()
        let begin = photos.buttons["开始记录"].firstMatch
        XCTAssertTrue(begin.waitForExistence(timeout: 15))
        begin.tap()
        let submitting = photos.buttons["正在提交"]
        _ = submitting.waitForExistence(timeout: 5)
        XCTAssertEqual(
            XCTWaiter.wait(
                for: [XCTNSPredicateExpectation(predicate: NSPredicate(format: "exists == false"), object: submitting)],
                timeout: 60
            ),
            .completed
        )
        XCTAssertNotEqual(application.state, .runningForeground)

        application.activate()
        XCTAssertTrue(application.wait(for: .runningForeground, timeout: 30))
        let pauseLabels = ["暂停处理", "Pause processing", "処理を一時停止", "처리 일시 정지"]
        let pause = application.buttons.matching(
            NSPredicate(format: "label IN %@", pauseLabels)
        ).firstMatch
        XCTAssertFalse(pause.exists, "The simple processing surface must not offer a manual pause action.")
        let resumeLabels = ["继续处理", "Resume processing", "処理を再開", "처리 재개"]
        XCTAssertFalse(application.buttons["home-activity-retry"].exists,
            "Resending from Photos is the intended recovery action; Home must not add retry controls.")

        let cancelLabels = ["取消本轮", "Cancel session", "セッションをキャンセル", "세션 취소"]
        let cancel = application.buttons.matching(
            NSPredicate(format: "label IN %@", cancelLabels)
        ).firstMatch
        XCTAssertTrue(cancel.waitForExistence(timeout: 15))
        cancel.tap()
        let confirmationLabels = cancelLabels
        let confirmation = application.alerts.buttons.matching(
            NSPredicate(format: "label IN %@", confirmationLabels)
        ).firstMatch
        XCTAssertTrue(confirmation.waitForExistence(timeout: 10))
        confirmation.tap()
        let processingControls = application.buttons.matching(
            NSPredicate(format: "label IN %@", pauseLabels + resumeLabels)
        ).firstMatch
        let cancellationSettled = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "exists == false"),
            object: processingControls
        )
        XCTAssertEqual(
            XCTWaiter.wait(for: [cancellationSettled], timeout: 20),
            .completed,
            "Confirming cancel must durably move the task out of active processing and remove pause/resume controls."
        )
        XCTAssertFalse(
            application.alerts.buttons.matching(
                NSPredicate(format: "label IN %@", confirmationLabels)
            ).firstMatch.exists,
            "Cancel confirmation should dismiss after the command is accepted."
        )
        let cancelScreenshot = XCTAttachment(screenshot: application.screenshot())
        cancelScreenshot.name = "home-controls-cancelled-seven-photos"
        cancelScreenshot.lifetime = .keepAlways
        add(cancelScreenshot)

        let settled = expectation(description: "Let any already-submitted Photos write settle")
        DispatchQueue.main.asyncAfter(deadline: .now() + 8) { settled.fulfill() }
        wait(for: [settled], timeout: 10)
        try deleteOutputsAddedSince(
            baselineIdentifiers,
            attachmentPrefix: "home-controls-success-cleanup"
        )
        cleanupCompleted = true
        XCUIDevice.shared.press(.home)
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

    func testSettingsInformationPushReturnsToSettings() throws {
        launchHostAndWait()
        openSettingsFromHome()
        restoreSimplifiedChineseInterfaceIfNeeded()

        let destinations = [
            "MemoMark 怎么讲述时间",
            "关于 MemoMark 的诞生",
            "查看日常使用流程",
            "重看欢迎介绍"
        ]
        for title in destinations {
            let action = application.buttons.containing(
                NSPredicate(format: "label CONTAINS %@", title)
            ).firstMatch
            if !action.exists {
                application.buttons["开始使用"].tap()
            }
            XCTAssertTrue(action.waitForExistence(timeout: 10))
            for _ in 0..<10 where !action.isHittable {
                application.swipeUp()
            }
            XCTAssertTrue(action.isHittable)
            action.tap()
            if title == "重看欢迎介绍" {
                attachCurrentScreenshot(named: "qa-welcome-entry-state")
                let hierarchy = XCTAttachment(string: application.debugDescription)
                hierarchy.name = "qa-welcome-entry-hierarchy"
                hierarchy.lifetime = .keepAlways
                add(hierarchy)
                XCTAssertTrue(application.navigationBars["欢迎"].waitForExistence(timeout: 10))
                let workflow = application.buttons["查看使用流程"]
                for _ in 0..<15 where !workflow.isHittable {
                    application.swipeUp()
                }
                XCTAssertTrue(workflow.isHittable)
                workflow.tap()
                XCTAssertTrue(application.navigationBars["怎么记录"].waitForExistence(timeout: 10))
                application.navigationBars.buttons.element(boundBy: 0).tap()
                XCTAssertTrue(application.navigationBars["欢迎"].waitForExistence(timeout: 10))
            }
            let back = application.navigationBars.buttons.element(boundBy: 0)
            XCTAssertTrue(back.waitForExistence(timeout: 10))
            XCTAssertNotEqual(back.label, "完成", "Information pages must expose native Back.")
            back.tap()
            XCTAssertTrue(application.navigationBars["设置"].waitForExistence(timeout: 10))
            XCTAssertTrue(application.buttons["开始使用"].exists)
        }
        let about = application.buttons["关于"]
        for _ in 0..<5 where !about.isHittable {
            application.swipeUp()
        }
        XCTAssertTrue(about.isHittable)
        // Disclosure preferences persist across launches and must not be reset.
        if (about.value as? String)?.contains("已展开") != true {
            about.tap()
        }
        let releaseNotes = application.buttons.containing(
            NSPredicate(format: "label CONTAINS %@", "更新日志")
        ).firstMatch
        for _ in 0..<4 where !releaseNotes.isHittable {
            application.swipeUp()
        }
        XCTAssertTrue(releaseNotes.isHittable)
        releaseNotes.tap()
        XCTAssertTrue(application.navigationBars["更新日志"].waitForExistence(timeout: 10))
        application.navigationBars.buttons.element(boundBy: 0).tap()
        XCTAssertTrue(application.navigationBars["设置"].waitForExistence(timeout: 10))
        XCTAssertTrue(releaseNotes.exists)
        attachCurrentScreenshot(named: "qa-stage3-settings-information-return")
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
                "卡片布局与内容",
                "Layout & Content",
                "Card Layout & Content",
                "レイアウトと内容",
                "カードのレイアウトと内容",
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
            titles: [
                "保存位置",
                "存放地点",
                "Save Location",
                "Save Destination",
                "保存先",
                "저장 위치"
            ]
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
            revealConfigurationOption(layoutSection)
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
            cardEditor.isHittable,
            "The expanded layout section did not expose a tappable card content editor."
        )

        cardEditor.tap()
        let editorDone = application.buttons.matching(
            NSPredicate(format: "identifier == %@ OR label IN %@", "card-editor-done", ["完成", "Done", "完了", "완료"])
        ).firstMatch
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

    func testFeedbackLandscapeBothDirections() throws {
        XCUIDevice.shared.orientation = .portrait
        defer { XCUIDevice.shared.orientation = .portrait }
        launchHostAndWait()
        var viewportWidths: [String: CGFloat] = [:]

        for (orientation, direction) in [
            (UIDeviceOrientation.landscapeLeft, "left"),
            (UIDeviceOrientation.landscapeRight, "right")
        ] {
            XCUIDevice.shared.orientation = orientation
            let rotated = XCTNSPredicateExpectation(
                predicate: NSPredicate { _, _ in self.application.frame.width > self.application.frame.height },
                object: nil
            )
            XCTAssertEqual(XCTWaiter.wait(for: [rotated], timeout: 10), .completed)
            for (identifier, name) in [("house.fill", "home"), ("slider.horizontal.3", "configuration"), ("checklist", "progress")] {
                let action = application.buttons[identifier]
                XCTAssertTrue(action.waitForExistence(timeout: 10))
                let ready = XCTNSPredicateExpectation(
                    predicate: NSPredicate { _, _ in action.isHittable }, object: nil
                )
                XCTAssertEqual(XCTWaiter.wait(for: [ready], timeout: 10), .completed)
                if !action.isSelected { action.tap() }
                XCTAssertTrue(application.scrollViews.firstMatch.waitForExistence(timeout: 10))
                let edgeGap = application.frame.maxX - action.frame.maxX
                let contentReady = XCTNSPredicateExpectation(
                    predicate: NSPredicate { _, _ in
                        self.application.scrollViews.allElementsBoundByIndex.contains { $0.frame.width > 200 }
                    }, object: nil
                )
                XCTAssertEqual(XCTWaiter.wait(for: [contentReady], timeout: 10), .completed)
                let viewport = try XCTUnwrap(application.scrollViews.allElementsBoundByIndex.first { $0.frame.width > 200 })
                if direction == "left" {
                    viewportWidths[name] = viewport.frame.width
                } else {
                    XCTAssertEqual(try XCTUnwrap(viewportWidths[name]) - viewport.frame.width, 50, accuracy: 2)
                }
                let geometry = XCTAttachment(string: "direction=\(direction); page=\(name); buttonFrame=\(action.frame); edgeGap=\(edgeGap); contentViewport=\(viewport.frame)")
                geometry.name = "feedback-\(name)-geometry-\(direction)"
                geometry.lifetime = .keepAlways
                add(geometry)
                let hierarchy = XCTAttachment(string: application.debugDescription)
                hierarchy.name = "feedback-\(name)-hierarchy-\(direction)"
                hierarchy.lifetime = .keepAlways
                add(hierarchy)
                if orientation == .landscapeLeft {
                    // The portrait-top camera is on the left in this pose.
                    // The plain right edge keeps page spacing + rail margin,
                    // plus the capsule's inset around its 46pt button.
                    let expectedGap = 12.0 + 10.0 + (56.0 - 46.0) / 2
                    XCTAssertEqual(edgeGap, expectedGap, accuracy: 2)
                }
                attachCurrentScreenshot(named: "feedback-\(name)-landscape-\(direction)")

                if name == "configuration" {
                    let preview = application.buttons["configuration.preview.rail-visibility"]
                    XCTAssertTrue(preview.waitForExistence(timeout: 10))
                    XCTAssertTrue(preview.isHittable)
                    preview.tap()
                    attachCurrentScreenshot(named: "feedback-configuration-preview-toggled-\(direction)")
                    preview.tap()
                }
            }
        }
        application.terminate()
        launchHostAndWait()
        XCTAssertEqual(application.state, .runningForeground)
        attachCurrentScreenshot(named: "feedback-relaunch")
    }

    func testFeedbackSingleSaveSurvivesRelaunch() throws {
        XCUIDevice.shared.orientation = .landscapeLeft
        defer { XCUIDevice.shared.orientation = .portrait }
        launchHostAndWait()

        func openNoteSwitch() throws -> XCUIElement {
            let configuration = application.buttons["slider.horizontal.3"]
            XCTAssertTrue(configuration.waitForExistence(timeout: 10))
            if !configuration.isSelected { configuration.tap() }
            let preview = application.buttons["configuration.preview.rail-visibility"]
            if preview.exists && preview.label == "收起预览" { preview.tap() }
            // Configuration owns an inner option scroller below the outer
            // retained-preview scroller; target the options, not the rail.
            let contentScroll = application.scrollViews.element(boundBy: 1)
            let note = application.switches.matching(
                NSPredicate(format: "label BEGINSWITH %@", "补充一句话")
            ).firstMatch
            if !note.exists {
                let section = application.buttons.matching(
                    NSPredicate(format: "label BEGINSWITH %@", "照片说明")
                ).firstMatch
                for _ in 0..<8 where !section.exists { contentScroll.swipeUp() }
                XCTAssertTrue(section.waitForExistence(timeout: 5))
                revealConfigurationOption(section)
                section.tap()
            }
            for _ in 0..<8 where !note.isHittable {
                let scroll = contentScroll
                if note.exists && note.frame.midY < scroll.frame.midY {
                    scroll.swipeDown()
                } else {
                    scroll.swipeUp()
                }
            }
            let hierarchy = XCTAttachment(string: application.debugDescription)
            hierarchy.name = "feedback-note-switch-before-edit"
            hierarchy.lifetime = .keepAlways
            add(hierarchy)
            XCTAssertTrue(note.waitForExistence(timeout: 5))
            XCTAssertTrue(note.isHittable)
            return note
        }

        func saveOnce() -> Bool {
            let save = application.buttons["configuration.rail.save"]
            let enabled = XCTNSPredicateExpectation(
                predicate: NSPredicate { _, _ in save.exists && save.isEnabled && save.isHittable }, object: nil
            )
            guard XCTWaiter.wait(for: [enabled], timeout: 10) == .completed else { return false }
            save.tap()
            let saved = XCTNSPredicateExpectation(
                predicate: NSPredicate { _, _ in save.label == "已保存" && !save.isEnabled }, object: nil
            )
            return XCTWaiter.wait(for: [saved], timeout: 15) == .completed
        }

        let note = try openNoteSwitch()
        let original = try XCTUnwrap(note.value as? String)
        note.tap()
        let edited = try XCTUnwrap(note.value as? String)
        let firstSaveSucceeded = saveOnce()
        attachCurrentScreenshot(named: "feedback-single-save")
        application.terminate()
        launchHostAndWait()
        let restored = try openNoteSwitch()
        let reloaded = restored.value as? String
        attachCurrentScreenshot(named: "feedback-saved-setting-after-relaunch")

        // Restore the existing user preference before asserting the outcome.
        if reloaded != original { restored.tap() }
        let restorationSucceeded = reloaded == original || saveOnce()
        application.terminate()
        launchHostAndWait()
        let finalValue = try openNoteSwitch().value as? String
        attachCurrentScreenshot(named: "feedback-original-setting-restored")
        XCTAssertNotEqual(edited, original)
        XCTAssertTrue(firstSaveSucceeded, "A single save should settle to durable saved state.")
        XCTAssertEqual(reloaded, edited, "The edited setting should survive a fresh host launch.")
        XCTAssertTrue(restorationSucceeded)
        XCTAssertEqual(finalValue, original, "Restore the existing preference after QA.")
    }

    func testAdaptiveNavigationAndHomeRestoreAfterPhysicalRotation() throws {
        XCUIDevice.shared.orientation = .portrait
        defer { XCUIDevice.shared.orientation = .portrait }
        launchHostAndWait()

        let home = application.buttons["首页"]
        XCTAssertTrue(home.waitForExistence(timeout: 15))
        if !home.isSelected { home.tap() }
        let portraitTabs = application.tabBars.firstMatch
        XCTAssertTrue(portraitTabs.waitForExistence(timeout: 10))
        XCTAssertTrue(portraitTabs.isHittable)
        let homeViewport = application.scrollViews.firstMatch
        XCTAssertTrue(homeViewport.waitForExistence(timeout: 10))
        let homePortraitWidth = homeViewport.frame.width
        attachCurrentScreenshot(named: "adaptive-home-portrait-before-rotation")

        XCUIDevice.shared.orientation = .landscapeLeft
        let landscapeRailHome = application.buttons.matching(
            NSPredicate(format: "label == %@", "首页")
        )
        let landscapeRailProgress = application.buttons.matching(
            NSPredicate(format: "label == %@", "进展")
        )
        XCTAssertTrue(landscapeRailHome.firstMatch.waitForExistence(timeout: 10))
        XCTAssertTrue(landscapeRailProgress.firstMatch.waitForExistence(timeout: 10))
        let landscapeRailIsVisible = landscapeRailHome.allElementsBoundByIndex.contains(where: \.isHittable)
            && landscapeRailProgress.allElementsBoundByIndex.contains(where: \.isHittable)
        let landscapeTabsHidden = !portraitTabs.isHittable
        attachCurrentScreenshot(named: "adaptive-home-landscape-rail")

        XCUIDevice.shared.orientation = .portrait
        let portraitViewport = application.scrollViews.firstMatch
        let portraitRestored = XCTNSPredicateExpectation(
            predicate: NSPredicate { _, _ in
                portraitTabs.isHittable
                    && !landscapeRailProgress.allElementsBoundByIndex.contains(where: \.isHittable)
                    && abs(portraitViewport.frame.width - homePortraitWidth) < 2
            },
            object: nil
        )
        XCTAssertEqual(XCTWaiter.wait(for: [portraitRestored], timeout: 10), .completed)
        attachCurrentScreenshot(named: "adaptive-home-portrait-restored")
        let hierarchy = XCTAttachment(string: application.debugDescription)
        hierarchy.name = "adaptive-home-portrait-restored-hierarchy"
        hierarchy.lifetime = .keepAlways
        add(hierarchy)
        XCTAssertTrue(landscapeRailIsVisible, "Landscape must expose the side rail controls.")
        XCTAssertTrue(landscapeTabsHidden, "Landscape must hide the system tab bar while the side rail is active.")

        for (tabTitle, label) in [("配置", "configuration"), ("进展", "progress")] {
            let tab = application.buttons[tabTitle]
            XCTAssertTrue(tab.waitForExistence(timeout: 10), "Missing (tabTitle) navigation action.")
            if !tab.isSelected { tab.tap() }
            let viewport = application.scrollViews.firstMatch
            XCTAssertTrue(viewport.waitForExistence(timeout: 10))
            let portraitWidth = viewport.frame.width

            XCUIDevice.shared.orientation = .landscapeLeft
            let landscapeTab = application.buttons[tabTitle]
            let landscapeReady = XCTNSPredicateExpectation(
                predicate: NSPredicate { _, _ in
                    landscapeTab.exists && landscapeTab.isHittable
                        && viewport.frame.width > portraitWidth * 1.35
                },
                object: nil
            )
            XCTAssertEqual(XCTWaiter.wait(for: [landscapeReady], timeout: 10), .completed,
                           "(tabTitle) should use the wide content viewport in landscape.")
            attachCurrentScreenshot(named: "adaptive-\(label)-landscape")

            XCUIDevice.shared.orientation = .portrait
            let restored = XCTNSPredicateExpectation(
                predicate: NSPredicate { _, _ in
                    portraitTabs.isHittable && abs(viewport.frame.width - portraitWidth) < 2
                },
                object: nil
            )
            XCTAssertEqual(XCTWaiter.wait(for: [restored], timeout: 10), .completed,
                           "\(tabTitle) did not recover its portrait viewport width.")
            attachCurrentScreenshot(named: "adaptive-\(label)-portrait-restored")
        }
        XCTAssertEqual(application.state, .runningForeground)
    }

    func testCardEditorFocusSurvivesPhysicalRotation() throws {
        XCUIDevice.shared.orientation = .portrait
        defer {
            XCUIDevice.shared.orientation = .portrait
            let dismiss = application.buttons["card-editor-dismiss-keyboard"]
            if dismiss.exists { dismiss.tap() }
            let done = application.buttons["card-editor-done"]
            if done.exists { done.tap() }
        }
        launchHostAndWait()
        let config = application.buttons.matching(NSPredicate(format: "label IN %@", ["配置", "Configuration", "設定", "설정"])).firstMatch
        XCTAssertTrue(config.waitForExistence(timeout: 15))
        config.tap()
        let edit = application.buttons.matching(NSPredicate(format: "label IN %@", ["卡片内容", "Card Content", "カード内容", "카드 내용"])).firstMatch
        if !edit.exists, let layout = configurationButton(titles: ["卡片布局与内容", "布局与内容", "Card Layout & Content", "Layout & Content", "カードのレイアウトと内容", "レイアウトと内容", "레이아웃 및 콘텐츠"]) {
            revealConfigurationOption(layout)
            layout.tap()
        }
        revealConfigurationOption(edit)
        XCTAssertTrue(edit.waitForExistence(timeout: 10))
        edit.tap()
        let field = application.textViews.firstMatch
        XCTAssertTrue(field.waitForExistence(timeout: 10))
        field.tap()
        XCTAssertTrue(application.keyboards.firstMatch.waitForExistence(timeout: 5))
        let originalValue = field.value as? String
        let before = XCTAttachment(string: application.debugDescription)
        before.name = "editor-native-identity-before-rotation"
        before.lifetime = .keepAlways
        add(before)
        attachCurrentScreenshot(named: "editor-before-rotation")
        XCUIDevice.shared.orientation = .landscapeLeft
        let landscapeKeepsKeyboard = application.keyboards.firstMatch.waitForExistence(timeout: 5)
        let landscapeValue = application.textViews.firstMatch.value as? String
        let after = XCTAttachment(string: application.debugDescription)
        after.name = "editor-native-identity-after-rotation"
        after.lifetime = .keepAlways
        add(after)
        attachCurrentScreenshot(named: "editor-landscape-focus")
        XCUIDevice.shared.orientation = .portrait
        let portraitKeepsKeyboard = application.keyboards.firstMatch.waitForExistence(timeout: 5)
        let portraitValue = application.textViews.firstMatch.value as? String
        attachCurrentScreenshot(named: "editor-restored-portrait-focus")
        let dismiss = application.buttons["card-editor-dismiss-keyboard"]
        if dismiss.exists { dismiss.tap() }
        let done = application.buttons["card-editor-done"]
        if done.exists { done.tap() }
        // Restore the physical pose before assertions: XCTest can stop a
        // failed UI test without unwinding Swift defer blocks.
        XCTAssertTrue(landscapeKeepsKeyboard, "Rotation must retain the TextKit first responder.")
        XCTAssertTrue(portraitKeepsKeyboard)
        XCTAssertEqual(landscapeValue, originalValue)
        XCTAssertEqual(portraitValue, originalValue)
    }

    func testConfigurationPreviewAndAccessoryLifecycle() throws {
        launchHostAndWait()
        XCUIDevice.shared.orientation = .portrait
        let config = application.buttons["配置"]
        XCTAssertTrue(config.waitForExistence(timeout: 10))
        config.tap()
        let toggle = application.buttons["configuration.preview.visibility"]
        XCTAssertTrue(toggle.waitForExistence(timeout: 10))
        let originalLabel = toggle.label
        defer {
            if toggle.exists && toggle.label != originalLabel { toggle.tap() }
        }
        if toggle.label == "展开预览" { toggle.tap() }
        attachCurrentScreenshot(named: "qa-preview-visible")
        let direction = application.buttons.matching(
            NSPredicate(format: "label IN %@", ["切换为竖图", "切换为横图"])
        ).firstMatch
        XCTAssertTrue(direction.waitForExistence(timeout: 10))
        let originalDirection = direction.label
        direction.tap()
        let opposite = originalDirection == "切换为竖图" ? "切换为横图" : "切换为竖图"
        let reverse = application.buttons[opposite].firstMatch
        XCTAssertTrue(reverse.waitForExistence(timeout: 10))
        attachCurrentScreenshot(named: "qa-preview-alternate-orientation")
        reverse.tap()
        toggle.tap()
        attachCurrentScreenshot(named: "qa-preview-collapsed")
        let more = application.buttons["更多配置操作"]
        XCTAssertTrue(more.isHittable)
        more.tap()
        XCTAssertTrue(application.buttons["另存为新配置"].waitForExistence(timeout: 10))
        attachCurrentScreenshot(named: "qa-configuration-more-actions")
        application.tap()
        application.buttons["首页"].tap()
        XCTAssertFalse(more.exists)
        application.buttons["进展"].tap()
        XCTAssertFalse(more.exists)
        config.tap()
        XCTAssertTrue(more.waitForExistence(timeout: 10))
    }

    private func revealConfigurationOption(_ option: XCUIElement) {
        // `exists` and even `isHittable` can remain true while the element's
        // center sits inside the fixed save-action/TabView region. Keep the
        // target comfortably above that region before tapping it.
        let preferredBottom = application.frame.maxY - 180
        for _ in 0..<5 where
            !option.isHittable || option.frame.maxY > preferredBottom {
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

        let anchorRows = anchorGroup
            .descendants(matching: .any)
            .matching(identifier: "subject-anchor-row")
        if anchorRows.count > 0 {
            assertNonOverlappingFrames(
                for: anchorRows,
                context: "time-anchor rows",
                allowedOverlap: 16
            )

            var hittableAnchorRow: XCUIElement?
            for _ in 0 ..< 3 {
                for index in 0 ..< anchorRows.count {
                    let candidate = anchorRows.element(boundBy: index)
                    if candidate.isHittable {
                        hittableAnchorRow = candidate
                        break
                    }
                }
                if hittableAnchorRow != nil {
                    break
                }

                application.swipeDown()
                RunLoop.current.run(
                    until: Date().addingTimeInterval(0.35)
                )
            }

            XCTAssertNotNil(
                hittableAnchorRow,
                "The current subject-anchor group did not expose a tappable time-anchor row."
            )
            hittableAnchorRow?.tap()
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

        // A clean QA run is expected to start with an empty output album.
        // Processing tests establish their own before/after count and verify
        // that each new output is a supported still or Live Photo. Inventory
        // must therefore prove that the prepared album exists without forcing
        // a pre-existing output or a synthetic fixture into Photos.
        XCTAssertTrue(
            inventory.assets.allSatisfy {
                $0.classification == "jpegStill"
                    || $0.classification == "livePhoto"
            },
            "The output album contains an unsupported classification: \(inventory.assets.map(\.classification))"
        )
    }

    func testClearNamedQAOutputsBeforeBackgroundRound() throws {
        // Owner explicitly authorizes clearing this fixed output test album.
        // Keep independent before/after evidence and refuse any input overlap.
        let inputs = try inventoryAlbum(titled: "MemoMark QA Inputs", attachmentName: "cleanup-original-inputs-before.json")
        let outputs = try inventoryAlbum(titled: "MemoMark QA Outputs", attachmentName: "cleanup-output-identity-before.json")
        guard inputs.albumLocalIdentifier != outputs.albumLocalIdentifier,
              Set(inputs.assets.map(\.localIdentifier)).isDisjoint(with: outputs.assets.map(\.localIdentifier)) else {
            XCTFail("Refusing cleanup: output selection overlaps protected original inputs.")
            throw CocoaError(.fileWriteNoPermission)
        }
        try deleteOutputsAddedSince([], attachmentPrefix: "background-round-cleanup")
        let preserved = try inventoryAlbum(titled: "MemoMark QA Inputs", attachmentName: "cleanup-original-inputs-after.json")
        XCTAssertEqual(preserved.assets.map(\.contentIdentity), inputs.assets.map(\.contentIdentity))
        XCTAssertEqual(try inventoryAlbum(titled: "MemoMark QA Outputs", attachmentName: "cleanup-zero-output-baseline.json").assetCount, 0)
        XCUIDevice.shared.press(.home)
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
        // Apple Photos may expose a paired Live Photo with a JPEG, HEIC, or
        // HEIF still resource. The production contract is the paired still +
        // motion resource, not one particular still codec.
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
        // rendition. This RAW/ProRAW presence is the required high-resolution
        // input for the bounded QA run. The exact PhotoKit pixel area is
        // recorded as evidence, but is not a hard 48MP gate: Photos may expose
        // a cropped aspect ratio (for example, 8064x4536) rather than a
        // mathematical 48,000,000-pixel rectangle.
        let rawHighestQualityAssets = inventory.assets.filter {
            $0.classification == "rawWithJPEGRepresentation"
                && Int64($0.pixelWidth) * Int64($0.pixelHeight) >= 30_000_000
        }
        XCTAssertFalse(
            rawHighestQualityAssets.isEmpty,
            "The input album must contain the device's highest-quality RAW/ProRAW asset with a Photos JPEG rendition for the bounded high-resolution QA run."
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
        let completionSignatureBeforeSubmit = taskCompletionSurfaceSignature()
        doneButton.tap()

        waitForProcessingCompletionSurface(
            scenario: "QA-02 JPEG",
            previousSignature: completionSignatureBeforeSubmit
        )

        let outputAfter = try inventoryAlbum(
            titled: "MemoMark QA Outputs",
            attachmentName: "qa-02-jpeg-outputs-after.json"
        )
        let inputAfter = try inventoryAlbum(
            titled: "MemoMark QA Inputs",
            attachmentName: "qa-02-jpeg-input-after.json"
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

    func testMemoMarkQAFilmMarkPresetCanProcessPreparedJPEGFromTheInputAlbum() throws {
        launchHostAndWait()

        let homeTab = application.buttons["house.fill"].exists
            ? application.buttons["house.fill"]
            : application.buttons["首页"]
        XCTAssertTrue(
            homeTab.waitForExistence(timeout: 20),
            "The iOS host did not expose the Home tab before the FilmMark run."
        )
        if !homeTab.isSelected {
            homeTab.tap()
        }

        let filmMarkPreset = application.buttons.matching(
            NSPredicate(
                format: "label CONTAINS %@",
                "胶片时间"
            )
        ).firstMatch
        XCTAssertTrue(
            filmMarkPreset.waitForExistence(timeout: 20),
            "The prepared FilmMark preset was not exposed on the Home surface."
        )
        XCTAssertTrue(
            filmMarkPreset.isHittable,
            "The prepared FilmMark preset was exposed but not hittable."
        )
        if !filmMarkPreset.isSelected {
            filmMarkPreset.coordinate(
                withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)
            ).tap()
        }
        let saveAndSwitchButton = application.buttons["保存并切换"]
        if saveAndSwitchButton.waitForExistence(timeout: 5) {
            saveAndSwitchButton.tap()
        }
        let selectedFilmMarkPreset = application.buttons.matching(
            NSPredicate(
                format: "label CONTAINS %@ AND selected == true",
                "胶片时间"
            )
        ).firstMatch
        XCTAssertTrue(
            selectedFilmMarkPreset.waitForExistence(timeout: 10),
            "The FilmMark preset could not be activated before processing."
        )

        // Reuse the same JPEG -> completion surface -> PhotoKit readback
        // contract as QA-02, now with the FilmMark preset explicitly active.
        try testMemoMarkQA02CanProcessPreparedJPEGFromTheInputAlbum()
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
        let completionSignatureBeforeSubmit = taskCompletionSurfaceSignature()
        doneButton.tap()

        waitForProcessingCompletionSurface(
            scenario: "QA-04 Live Photo",
            previousSignature: completionSignatureBeforeSubmit
        )

        let outputAfter = try inventoryAlbum(
            titled: "MemoMark QA Outputs",
            attachmentName: "qa-04-live-photo-outputs-after.json"
        )
        let inputAfter = try inventoryAlbum(
            titled: "MemoMark QA Inputs",
            attachmentName: "qa-04-live-photo-input-after.json"
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
        let completionSignatureBeforeSubmit = taskCompletionSurfaceSignature()
        doneButton.tap()

        waitForProcessingCompletionSurface(
            scenario: "QA-05 RAW/ProRAW",
            previousSignature: completionSignatureBeforeSubmit
        )

        let outputAfter = try inventoryAlbum(
            titled: "MemoMark QA Outputs",
            attachmentName: "qa-05-outputs-after.json"
        )
        let inputAfter = try inventoryAlbum(
            titled: "MemoMark QA Inputs",
            attachmentName: "qa-05-raw-input-after.json"
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

    /// The controlled current classic-white fixture must contain foreground
    /// in its newly added footer; EXIF text and a decodable white bar do not pass.
    private func attachSavedCardCompositions(_ inventory: QAAlbumInventory, style: String) throws {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent("SavedCards-" + UUID().uuidString)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: folder) }
        for item in inventory.assets {
            let asset = try XCTUnwrap(PHAsset.fetchAssets(withLocalIdentifiers: [item.localIdentifier], options: nil).firstObject)
            let resource = try XCTUnwrap(PHAssetResource.assetResources(for: asset).first { $0.type == .photo })
            let url = try savedResourceURL(resource, in: folder)
            let source = try XCTUnwrap(CGImageSourceCreateWithURL(url as CFURL, nil))
            let image = try XCTUnwrap(CGImageSourceCreateThumbnailAtIndex(source, 0, [
                kCGImageSourceCreateThumbnailFromImageAlways: true,
                kCGImageSourceThumbnailMaxPixelSize: 2048,
                kCGImageSourceCreateThumbnailWithTransform: true
            ] as CFDictionary))
            let evidence = XCTAttachment(image: UIImage(cgImage: image))
            evidence.name = "saved-card-composition-" + style + "-" + item.localIdentifier.replacingOccurrences(of: "/", with: "-")
            evidence.lifetime = .keepAlways
            add(evidence)
            try? FileManager.default.removeItem(at: url)
        }
        // These real saved compositions require per-image visual acceptance.
        // Decode alone is deliberately not a nonblank-content assertion.
    }

    private func verifySavedClassicFooter(_ inventory: QAAlbumInventory, sources: [QAAlbumInventoryAsset]) throws {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent("VisibleFooter-" + UUID().uuidString)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: folder) }
        for item in inventory.assets {
            let matches = sources.filter { $0.creationDate == item.creationDate }
            guard matches.count == 1, let original = matches.first,
                  item.pixelWidth == original.pixelWidth, item.pixelHeight > original.pixelHeight else {
                throw CocoaError(.fileReadUnknown)
            }
            let asset = try XCTUnwrap(PHAsset.fetchAssets(withLocalIdentifiers: [item.localIdentifier], options: nil).firstObject)
            let resource = try XCTUnwrap(PHAssetResource.assetResources(for: asset).first { $0.type == .photo })
            let url = try savedResourceURL(resource, in: folder)
            let source = try XCTUnwrap(CGImageSourceCreateWithURL(url as CFURL, nil))
            let thumbnail = try XCTUnwrap(CGImageSourceCreateThumbnailAtIndex(source, 0, [
                kCGImageSourceCreateThumbnailFromImageAlways: true,
                kCGImageSourceThumbnailMaxPixelSize: 2048,
                kCGImageSourceCreateThumbnailWithTransform: true
            ] as CFDictionary))
            let photoHeight = Int((CGFloat(original.pixelHeight) / CGFloat(item.pixelHeight) * CGFloat(thumbnail.height)).rounded(.up))
            let footer = try XCTUnwrap(thumbnail.cropping(to: CGRect(x: 0, y: photoHeight,
                width: thumbnail.width, height: thumbnail.height - photoHeight)))
            let evidence = XCTAttachment(image: UIImage(cgImage: footer))
            evidence.name = "saved-classic-footer-" + item.localIdentifier.replacingOccurrences(of: "/", with: "-")
            evidence.lifetime = .keepAlways
            add(evidence)
            let context = try XCTUnwrap(CGContext(data: nil, width: footer.width, height: footer.height,
                bitsPerComponent: 8, bytesPerRow: footer.width * 4,
                space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue))
            context.draw(footer, in: CGRect(x: 0, y: 0, width: footer.width, height: footer.height))
            let bytes = try XCTUnwrap(context.data).assumingMemoryBound(to: UInt8.self)
            var foreground = 0
            var background = 0
            for i in stride(from: 0, to: footer.width * footer.height * 4, by: 4) {
                if bytes[i] < 170 && bytes[i + 1] < 170 && bytes[i + 2] < 170 && bytes[i + 3] > 127 { foreground += 1 }
                if bytes[i] > 200 && bytes[i + 1] > 200 && bytes[i + 2] > 200 && bytes[i + 3] > 127 { background += 1 }
            }
            XCTAssertGreaterThan(background, footer.width * footer.height / 2,
                "Classic footer must retain its light background; a black raster is not visible content.")
            XCTAssertGreaterThan(foreground, 0, "Blank Renderer footer for output \(item.localIdentifier); metadata-only success is invalid.")
            try? FileManager.default.removeItem(at: url)
        }
    }

    private func verifySavedStillMetadata(_ inventory: QAAlbumInventory, expectedDescription: String, requireDescription: Bool = true) throws {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent("PhotoKitReadback-\(UUID())")
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: folder) }
        for item in inventory.assets {
            let asset = try XCTUnwrap(PHAsset.fetchAssets(withLocalIdentifiers: [item.localIdentifier], options: nil).firstObject)
            let resource = try XCTUnwrap(PHAssetResource.assetResources(for: asset).first { $0.type == .photo })
            let url = folder.appendingPathComponent(UUID().uuidString).appendingPathExtension("image")
            let options = PHAssetResourceRequestOptions()
            options.isNetworkAccessAllowed = false
            let ready = expectation(description: "Read saved PhotoKit image resource")
            PHAssetResourceManager.default().writeData(for: resource, toFile: url, options: options) { error in
                if let error { XCTFail("PhotoKit resource read failed: \(error)") }
                ready.fulfill()
            }
            wait(for: [ready], timeout: 30)
            let source = try XCTUnwrap(CGImageSourceCreateWithURL(url as CFURL, nil))
            let thumbnailOptions: [CFString: Any] = [
                kCGImageSourceCreateThumbnailFromImageAlways: true,
                kCGImageSourceThumbnailMaxPixelSize: 256,
                kCGImageSourceCreateThumbnailWithTransform: true
            ]
            let decoded = try XCTUnwrap(CGImageSourceCreateThumbnailAtIndex(source, 0, thumbnailOptions as CFDictionary))
            XCTAssertGreaterThan(decoded.width, 0)
            XCTAssertGreaterThan(decoded.height, 0)
            let raster = XCTAttachment(image: UIImage(cgImage: decoded))
            raster.name = "saved-photo-decoded-\(item.classification)"
            raster.lifetime = .keepAlways
            add(raster)
            let properties = try XCTUnwrap(CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any])
            XCTAssertEqual((properties[kCGImagePropertyPixelWidth] as? NSNumber)?.intValue, item.pixelWidth)
            XCTAssertEqual((properties[kCGImagePropertyPixelHeight] as? NSNumber)?.intValue, item.pixelHeight)
            let tiff = properties[kCGImagePropertyTIFFDictionary] as? [CFString: Any]
            let tiffDescription = tiff?[kCGImagePropertyTIFFImageDescription] as? String
            let exif = properties[kCGImagePropertyExifDictionary] as? [CFString: Any]
            let comment = exif?[kCGImagePropertyExifUserComment] as? String
            let evidence: [String: Any] = ["classification": item.classification,
                "tiffDescriptionPresent": tiffDescription != nil,
                "tiffDescriptionContainsExpected": tiffDescription?.contains(expectedDescription) == true,
                "exifCommentPresent": comment != nil,
                "exifCommentContainsExpected": comment?.contains(expectedDescription) == true,
                "exifCommentLength": comment?.count ?? 0]
            let attachment = XCTAttachment(data: try JSONSerialization.data(withJSONObject: evidence), uniformTypeIdentifier: "public.json")
            attachment.name = "saved-image-metadata-fields-\(item.classification).json"
            attachment.lifetime = .keepAlways
            add(attachment)
            if requireDescription {
                XCTAssertTrue(tiffDescription?.contains(expectedDescription) == true)
            }
            if item.classification == "livePhoto" {
                let apple = try XCTUnwrap(properties[kCGImagePropertyMakerAppleDictionary] as? [String: Any])
                XCTAssertFalse((apple["17"] as? String ?? "").isEmpty)
            }
        }
    }

    private func observeContinuedCompletionWindow(requestCount: Int, since startedAt: TimeInterval) throws {
        // The UI runner has no App Group entitlement. CoreDevice reads the
        // submitted/completed records independently during this Photos-only
        // window; a passing UI test alone does not certify owner completion.
        let interval = expectation(description: "Observe owners before cleanup and host activation")
        DispatchQueue.main.asyncAfter(deadline: .now() + 60) { interval.fulfill() }
        wait(for: [interval], timeout: 65)
        XCTAssertNotEqual(application.state, .runningForeground)
        let evidence: [String: Any] = ["expectedRequestCount": requestCount,
            "roundStartedAt": startedAt, "observationEndedAt": Date().timeIntervalSince1970,
            "hostForeground": application.state == .runningForeground]
        let attachment = XCTAttachment(data: try JSONSerialization.data(withJSONObject: evidence), uniformTypeIdentifier: "public.json")
        attachment.name = "external-owner-completion-observation-window.json"
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    private func savedResourceURL(_ resource: PHAssetResource, in folder: URL) throws -> URL {
        let url = folder.appendingPathComponent(UUID().uuidString).appendingPathExtension(resource.type == .pairedVideo ? "mov" : "image")
        let options = PHAssetResourceRequestOptions()
        options.isNetworkAccessAllowed = false
        let ready = expectation(description: "Read saved pairing resource")
        PHAssetResourceManager.default().writeData(for: resource, toFile: url, options: options) { error in
            if let error { XCTFail("PhotoKit pairing resource read failed: \(error)") }
            ready.fulfill()
        }
        wait(for: [ready], timeout: 30)
        return url
    }

    private func verifySavedMoviePairingSynchronously(_ inventory: QAAlbumInventory, expectedPairCount: Int = 1) {
        let ready = expectation(description: "Read saved Live Photo movie pairing")
        let operation = Task { @MainActor in
            defer { ready.fulfill() }
            do { try await verifySavedMoviePairing(inventory, expectedPairCount: expectedPairCount) }
            catch { XCTFail("Saved movie readback failed: \(error)") }
        }
        wait(for: [ready], timeout: 90)
        operation.cancel()
    }

    @MainActor
    private func verifySavedMoviePairing(_ inventory: QAAlbumInventory, expectedPairCount: Int = 1) async throws {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent("MoviePairReadback-\(UUID())")
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: folder) }
        let pairs = inventory.assets.filter { $0.classification == "livePhoto" }
        XCTAssertEqual(pairs.count, expectedPairCount)
        for item in pairs {
            let asset = try XCTUnwrap(PHAsset.fetchAssets(withLocalIdentifiers: [item.localIdentifier], options: nil).firstObject)
            let resources = PHAssetResource.assetResources(for: asset)
            let stillURL = try savedResourceURL(try XCTUnwrap(resources.first { $0.type == .photo }), in: folder)
            let movieURL = try savedResourceURL(try XCTUnwrap(resources.first { $0.type == .pairedVideo }), in: folder)
            let source = try XCTUnwrap(CGImageSourceCreateWithURL(stillURL as CFURL, nil))
            let properties = try XCTUnwrap(CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any])
            let apple = try XCTUnwrap(properties[kCGImagePropertyMakerAppleDictionary] as? [String: Any])
            let stillIdentifier = try XCTUnwrap(apple["17"] as? String)
            XCTAssertFalse(stillIdentifier.isEmpty)
            let movie = AVURLAsset(url: movieURL)
            let metadata = try await movie.load(.metadata)
            let identifier = try XCTUnwrap(metadata.first { $0.identifier == .quickTimeMetadataContentIdentifier })
            let movieIdentifier = try await identifier.load(.stringValue)
            XCTAssertEqual(movieIdentifier, stillIdentifier, "Saved still and movie must contain the same pairing identity.")
            let duration = try await movie.load(.duration).seconds
            XCTAssertTrue(duration.isFinite && duration > 0)
            let videoTracks = try await movie.loadTracks(withMediaType: .video)
            XCTAssertEqual(videoTracks.count, 1)
            var markerTimes: [Double] = []
            for track in try await movie.loadTracks(withMediaType: .metadata) {
                let reader = try AVAssetReader(asset: movie)
                let output = AVAssetReaderTrackOutput(track: track, outputSettings: nil)
                XCTAssertTrue(reader.canAdd(output))
                reader.add(output)
                let adaptor = AVAssetReaderOutputMetadataAdaptor(assetReaderTrackOutput: output)
                XCTAssertTrue(reader.startReading())
                while let group = adaptor.nextTimedMetadataGroup() {
                    if group.items.contains(where: { $0.identifier?.rawValue.hasSuffix("still-image-time") == true }) {
                        markerTimes.append(group.timeRange.start.seconds)
                    }
                }
                XCTAssertEqual(reader.status, .completed)
            }
            XCTAssertEqual(markerTimes.count, 1)
            XCTAssertTrue(markerTimes.allSatisfy { $0.isFinite && $0 >= 0 && $0 < duration })
            let evidence: [String: Any] = ["pairingIdentifiersEqual": movieIdentifier == stillIdentifier,
                "videoTrackCount": videoTracks.count, "durationSeconds": duration, "stillMarkerTimesSeconds": markerTimes]
            let attachment = XCTAttachment(data: try JSONSerialization.data(withJSONObject: evidence), uniformTypeIdentifier: "public.json")
            attachment.name = "saved-movie-pairing-readback.json"
            attachment.lifetime = .keepAlways
            add(attachment)
        }
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

        var matches: [PHAssetCollection] = []
        albums.enumerateObjects { album, _, _ in
            if album.localizedTitle == albumTitle { matches.append(album) }
        }
        guard matches.count == 1, let matchedAlbum = matches.first else {
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

    private func deleteOutputsAddedSince(
        _ baselineIdentifiers: Set<String>,
        attachmentPrefix: String
    ) throws {
        let current = try inventoryAlbum(
            titled: "MemoMark QA Outputs",
            attachmentName: "\(attachmentPrefix)-before.json"
        )
        let addedIdentifiers = current.assets
            .map(\.localIdentifier)
            .filter { !baselineIdentifiers.contains($0) }
        guard !addedIdentifiers.isEmpty else { return }

        let assets = PHAsset.fetchAssets(
            withLocalIdentifiers: addedIdentifiers,
            options: nil
        )
        XCTAssertEqual(assets.count, addedIdentifiers.count)
        let deletion = expectation(description: "Permanently delete only this run's QA outputs")
        var succeeded = false
        var deletionError: Error?
        PHPhotoLibrary.shared().performChanges({
            PHAssetChangeRequest.deleteAssets(assets)
        }) { success, error in
            succeeded = success
            deletionError = error
            deletion.fulfill()
        }
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        let confirmDelete = springboard.alerts.buttons.matching(
            NSPredicate(format: "label IN %@", ["删除", "Delete", "允许", "Allow"])
        ).firstMatch
        if confirmDelete.waitForExistence(timeout: 5) { confirmDelete.tap() }
        wait(for: [deletion], timeout: 60)
        XCTAssertTrue(succeeded, "Could not delete this test's QA outputs: \(String(describing: deletionError))")

        let after = try inventoryAlbum(
            titled: "MemoMark QA Outputs",
            attachmentName: "\(attachmentPrefix)-after.json"
        )
        XCTAssertTrue(
            after.assets.allSatisfy { baselineIdentifiers.contains($0.localIdentifier) },
            "QA Outputs still contains an asset created during this round."
        )
    }

    private func launchHostAndWait() {
        // Explicitly discard Xcode's automatic host launch before applying
        // this scenario's arguments; preserve the app's durable data.
        application.terminate()
        application.launch()

        XCTAssertTrue(
            application.wait(
                for: .runningForeground,
                timeout: 30
            ),
            "MemoMarkiOS did not reach the foreground within the device QA timeout."
        )
    }

    /// Waits for the production Task page to publish its completed state. The
    /// completion surface is the synchronization point for PhotoKit readback;
    /// the harness must not poll the output album while the app is still
    /// processing or saving.
    private func waitForProcessingCompletionSurface(
        scenario: String,
        previousSignature: String? = nil,
        timeout: TimeInterval = 120
    ) {
        let taskTab = application.buttons["checklist"]
        if taskTab.waitForExistence(timeout: 5), !taskTab.isSelected {
            taskTab.tap()
        } else if !taskTab.exists {
            let localizedTaskTab = application.buttons["进展"]
            if localizedTaskTab.waitForExistence(timeout: 5), !localizedTaskTab.isSelected {
                localizedTaskTab.tap()
            }
        }

        let completedCard = application
            .descendants(matching: .any)
            .matching(identifier: "task-completed-card")
            .firstMatch
        let hadCompletedCardBefore = completedCard.exists
        let completedValueBefore = hadCompletedCardBefore ? (completedCard.value as? String ?? "") : ""
        let completedLabelBefore = hadCompletedCardBefore ? completedCard.label : ""
        var sawProcessingCard = false
        var sawCompletedCardDisappear = !hadCompletedCardBefore
        let attentionCard = application
            .descendants(matching: .any)
            .matching(identifier: "task-needs-attention-card")
            .firstMatch
        let deadline = Date().addingTimeInterval(timeout)
        // A JPEG can complete before XCTest observes the transient processing
        // card. Give that fast path a short UI-settling window, then require
        // the completed surface. If a real processing card appears, the
        // stricter transition checks below remain in force.
        let fastCompletionGraceDeadline = Date().addingTimeInterval(2)

        while Date() < deadline {
            if application
                .descendants(matching: .any)
                .matching(identifier: "task-processing-card")
                .firstMatch
                .exists {
                sawProcessingCard = true
            }
            if !completedCard.exists {
                sawCompletedCardDisappear = true
            }

            let hasCompletedCard = completedCard.exists
            let completedValue = hasCompletedCard ? (completedCard.value as? String ?? "") : ""
            let completedLabel = hasCompletedCard ? completedCard.label : ""
            let currentSignature = "task-completed-card|\(completedLabel)|\(completedValue)"
            let publishedNewSurface = previousSignature.map {
                currentSignature != $0
            } ?? false
            let publishedNewTask = hadCompletedCardBefore
                && !completedValueBefore.isEmpty
                && completedValue != completedValueBefore
            let publishedNewLabel = hadCompletedCardBefore
                && !completedLabelBefore.isEmpty
                && completedLabel != completedLabelBefore
            let publishedCompletion = completedCard.exists
                && (
                    sawProcessingCard
                        || sawCompletedCardDisappear
                        || publishedNewTask
                        || publishedNewLabel
                        || publishedNewSurface
                )
            let fastCompletionSurface = completedCard.exists
                && !sawProcessingCard
                && Date() >= fastCompletionGraceDeadline

            if publishedCompletion || fastCompletionSurface {
                print(
                    "MemoMark \(scenario) reached task-completed-card; reading QA Outputs immediately."
                )
                return
            }

            if attentionCard.exists {
                attachCurrentScreenshot(
                    named: "\(scenario)-needs-attention"
                )
                XCTFail(
                    "\(scenario) reached the Task page, but the result requires attention instead of reporting completion."
                )
                return
            }

            RunLoop.current.run(
                until: Date().addingTimeInterval(0.25)
            )
        }

        attachCurrentScreenshot(named: "\(scenario)-completion-timeout")
        XCTFail(
            "\(scenario) did not expose task-completed-card within \(Int(timeout)) seconds; output album readback was intentionally not used as a processing wait."
        )
    }

    private func taskCompletionSurfaceSignature() -> String? {
        let completedCard = application
            .descendants(matching: .any)
            .matching(identifier: "task-completed-card")
            .firstMatch
        guard completedCard.exists else {
            return nil
        }

        let value = completedCard.value as? String ?? ""
        return "\(completedCard.identifier)|\(completedCard.label)|\(value)"
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

    private struct QAAlbumInventoryAsset: Codable, Equatable {
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

        var contentIdentity: Self {
            Self(localIdentifier: localIdentifier, originalAssetIdentifier: originalAssetIdentifier,
                 classification: classification, mediaType: mediaType, mediaSubtypes: mediaSubtypes,
                 pixelWidth: pixelWidth, pixelHeight: pixelHeight, duration: duration,
                 creationDate: creationDate, modificationDate: nil, resources: resources)
        }
    }

    private struct QAAlbumInventoryResource: Codable, Equatable {
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

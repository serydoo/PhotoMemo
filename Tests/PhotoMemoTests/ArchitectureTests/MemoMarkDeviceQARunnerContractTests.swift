import Foundation
import Testing

@Suite("MemoMark device QA runner")
struct MemoMarkDeviceQARunnerContractTests {

    @Test("runner resolves a human-readable device before invoking xcodebuild")
    func runnerResolvesDeviceIdentifierBeforeXcodebuild() throws {
        let source = try sourceText(
            "scripts/memomark-device-qa.sh"
        )

        #expect(
            source.contains(
                "resolve_device_identifier"
            )
        )
        #expect(
            source.contains(
                "-destination \"platform=iOS,id=${DEVICE_IDENTIFIER}\""
            )
        )
        #expect(
            !source.contains(
                "-destination \"platform=iOS,id=${DEVICE}\""
            )
        )
    }

    @Test("runner hard-gates the result bundle and passed test summary")
    func runnerHardGatesResultEvidence() throws {
        let source = try sourceText(
            "scripts/memomark-device-qa.sh"
        )
        let verifier = try sourceText(
            "scripts/memomark-device-qa-verify.py"
        )

        #expect(source.contains("-resultBundlePath"))
        #expect(source.contains("--write-metadata"))
        #expect(verifier.contains("summary_result == \"Passed\""))
        #expect(verifier.contains("summary_failed_tests == 0"))
        #expect(verifier.contains("testSummaryTotalTests"))
        #expect(verifier.contains("resultBundlePresent"))
    }

    @Test("runner classifies signing setup failures as blocked evidence")
    func runnerClassifiesSigningSetupFailures() throws {
        let verifier = try sourceText(
            "scripts/memomark-device-qa-verify.py"
        )

        #expect(verifier.contains("failureClass"))
        #expect(verifier.contains("signing-blocked"))
        #expect(verifier.contains("No profiles for"))
        #expect(verifier.contains("No Accounts"))
        #expect(verifier.contains("run_passed"))
    }

    @Test("runner does not duplicate the device capture argument")
    func runnerDoesNotDuplicateCaptureDeviceArgument() throws {
        let source = try sourceText(
            "scripts/memomark-device-qa.sh"
        )
        let captureStart = source.range(of: "capture_device() {")!.lowerBound
        let captureEnd = source.range(of: "resolve_process_id() {")!.lowerBound
        let captureSection = source[captureStart..<captureEnd]

        #expect(
            captureSection.components(
                separatedBy: "--device \"${DEVICE}\""
            ).count
                == 2
        )
    }

    @Test("runner keeps the default signing path safe under set -u")
    func runnerKeepsDefaultSigningPathSafe() throws {
        let source = try sourceText(
            "scripts/memomark-device-qa.sh"
        )

        #expect(source.contains("if [[ \"${ALLOW_PROVISIONING_UPDATES}\" == \"YES\" ]]"))
        #expect(!source.contains("${provisioning_arguments[@]}"))
    }

    @Test("runner rejects simulator targets before a device test")
    func runnerRequiresPhysicalDevice() throws {
        let source = try sourceText(
            "scripts/memomark-device-qa.sh"
        )

        #expect(source.contains("validate_physical_device"))
        #expect(source.contains("reality"))
        #expect(source.contains("physical"))
        #expect(source.contains("Physical device required"))
    }

    @Test("offline verification requires physical device evidence")
    func verifierRequiresPhysicalDeviceEvidence() throws {
        let verifier = try sourceText(
            "scripts/memomark-device-qa-verify.py"
        )

        #expect(verifier.contains("device-details.json"))
        #expect(verifier.contains("physical_device"))
        #expect(verifier.contains("device-target-invalid"))
    }

    @Test("runner exposes read-only signing readiness diagnostics")
    func runnerExposesSigningReadinessDiagnostics() throws {
        let source = try sourceText(
            "scripts/memomark-device-qa.sh"
        )
        let diagnostic = try sourceText(
            "scripts/memomark-device-qa-signing.py"
        )

        #expect(source.contains("signing-status"))
        #expect(source.contains("memomark-device-qa-signing.py"))
        #expect(diagnostic.contains("find-identity"))
        #expect(diagnostic.contains("provisioning"))
        #expect(diagnostic.contains("read-only"))
        #expect(diagnostic.contains("profile_matches"))
        #expect(diagnostic.contains("com.apple.developer.team-identifier"))
        #expect(diagnostic.contains("\"-target\""))
        #expect(diagnostic.contains("PRODUCT_BUNDLE_IDENTIFIER"))
        #expect(diagnostic.contains(".xctrunner"))
        #expect(source.contains("--target \"${TARGET}\""))
    }

    @Test("runner exposes offline verification for an existing run directory")
    func runnerExposesOfflineRunVerification() throws {
        let source = try sourceText(
            "scripts/memomark-device-qa.sh"
        )
        let verifier = try sourceText(
            "scripts/memomark-device-qa-verify.py"
        )

        #expect(source.contains("verify --run-dir <directory>"))
        #expect(source.contains("--run-dir"))
        #expect(source.contains("memomark-device-qa-verify.py"))
        #expect(verifier.contains("xcodebuildExitStatus"))
        #expect(verifier.contains("failureClass"))
        #expect(verifier.contains("signing-status.json"))
        #expect(verifier.contains("verify_early_signing_artifact"))
        #expect(verifier.contains("qaTarget"))
        #expect(verifier.contains("qaRunnerBundleIdentifier"))
        #expect(verifier.contains("defaultScheme"))
        #expect(verifier.contains("PhotoMemo.xcodeproj"))
        #expect(verifier.contains("EARLY_SIGNING_ALLOWED_ARTIFACTS"))
        #expect(verifier.contains("unexpected files"))
        #expect(verifier.contains("is_symlink"))
        #expect(verifier.contains("regular file"))
        #expect(verifier.contains("run_directory.is_symlink"))
        #expect(verifier.contains("run metadata scheme"))
        #expect(verifier.contains("run metadata target"))
        #expect(verifier.contains("device identifier"))
        #expect(verifier.contains("validate_regular_run_shape"))
        #expect(verifier.contains("REGULAR_RUN_REQUIRED_FILES"))
        #expect(verifier.contains("REGULAR_RUN_ALLOWED_ARTIFACTS"))
        #expect(verifier.contains("validate_regular_run_metadata"))
        #expect(verifier.contains("REGULAR_RUN_METADATA_REQUIRED_STRING_FIELDS"))
        #expect(verifier.contains("validate_regular_run_summary"))
        #expect(verifier.contains("validate_regular_run_device_evidence"))
        #expect(verifier.contains("if not path.exists()"))
        #expect(verifier.contains("run metadata write target must not be a symlink"))
        #expect(verifier.contains("isinstance(stored_status, bool)"))
        #expect(verifier.contains("regular run directory"))
        #expect(verifier.contains("run metadata project"))
        #expect(verifier.contains("QA manifest identity fields"))
        #expect(verifier.contains("defaultScheme must be"))
        #expect(source.contains("\"schemaVersion\": 1"))
        #expect(source.contains("\"runID\": run_id"))
        #expect(source.contains("\"device\": device"))
        #expect(source.contains("\"deviceIdentifier\": device_identifier"))
        #expect(source.contains("\"scheme\": scheme"))
        #expect(source.contains("\"configuration\": configuration"))
        #expect(source.contains("\"project\": \"MemoMark\""))
        #expect(source.contains("\"target\": target"))
        #expect(source.contains("\"${TARGET}\""))
    }

    @Test("regular runs retain the signing diagnostic evidence")
    func regularRunsAllowSigningStatusEvidence() throws {
        let verifier = try sourceText(
            "scripts/memomark-device-qa-verify.py"
        )
        let optionalStart = verifier.range(
            of: "REGULAR_RUN_OPTIONAL_FILES = frozenset("
        )!.lowerBound
        let allowedStart = verifier.range(
            of: "REGULAR_RUN_ALLOWED_ARTIFACTS = ("
        )!.lowerBound
        let optionalSection = verifier[optionalStart..<allowedStart]

        #expect(optionalSection.contains("\"signing-status.json\""))
    }

    @Test("default run checks signing before touching the physical device")
    func defaultRunChecksSigningBeforePhysicalPreflight() throws {
        let source = try sourceText(
            "scripts/memomark-device-qa.sh"
        )
        #expect(
            source.contains(
                """
                    run)
                        if [[ "${ALLOW_PROVISIONING_UPDATES}" != "YES" ]]; then
                            run_signing_status
                        fi
                        preflight
                        run_tests
                """
            )
        )
    }

    @Test("early signing blockers leave a machine-readable run artifact")
    func earlySigningBlockerLeavesMachineReadableArtifact() throws {
        let source = try sourceText(
            "scripts/memomark-device-qa.sh"
        )

        #expect(source.contains("SIGNING_STATUS_JSON"))
        #expect(source.contains("signing-status.json"))
        #expect(source.contains("run_signing_status"))
        #expect(source.contains("> \"${SIGNING_STATUS_JSON}\""))
    }

    @Test("runner exposes an unsigned iOS test-build gate")
    func runnerExposesUnsignedTestBuildGate() throws {
        let source = try sourceText(
            "scripts/memomark-device-qa.sh"
        )

        #expect(source.contains("build-check"))
        #expect(source.contains("build-for-testing"))
        #expect(source.contains("CODE_SIGNING_ALLOWED=NO"))
        #expect(source.contains("${TARGET}-Runner.app"))
        #expect(source.contains("${TARGET}.xctest"))
    }

    @Test("runner exposes a four-gate read-only readiness report")
    func runnerExposesFourGateReadinessReport() throws {
        let source = try sourceText(
            "scripts/memomark-device-qa.sh"
        )
        let readiness = try sourceText(
            "scripts/memomark-device-qa-readiness.py"
        )

        #expect(source.contains("readiness"))
        #expect(source.contains("run_readiness"))
        #expect(source.contains("readiness.json"))
        #expect(source.contains("memomark-device-qa-readiness.py"))
        #expect(source.contains("build_check"))
        #expect(source.contains("run_signing_status"))
        #expect(source.contains("preflight"))
        #expect(readiness.contains("overallResult"))
        #expect(readiness.contains("structuralBuild"))
        #expect(readiness.contains("physicalDevice"))

        let readinessStart = source.range(of: "run_readiness() {")!.lowerBound
        let readinessEnd = source.range(of: "require_process_id() {")!.lowerBound
        let readinessSection = source[readinessStart..<readinessEnd]
        let buildCall = readinessSection.range(of: "build_check")!.lowerBound
        let signingCall = readinessSection.range(of: "run_signing_status")!.lowerBound
        let preflightCall = readinessSection.range(of: "preflight")!.lowerBound
        #expect(buildCall < signingCall)
        #expect(signingCall < preflightCall)
    }

    @Test("device QA exposes a distinct JPEG processing scenario")
    func deviceQAExposesJPEGProcessingScenario() throws {
        let harness = try sourceText(
            "Tests/PhotoMemoUITests/MemoMarkDeviceQAHarnessTests.swift"
        )

        #expect(
            harness.contains(
                "testMemoMarkQA02CanProcessPreparedJPEGFromTheInputAlbum"
            )
        )
        #expect(harness.contains("classification == \"jpegStill\""))
        #expect(harness.contains("qa-02-jpeg-processing-evidence.json"))
    }

    @Test("device QA exposes a distinct Live Photo processing scenario")
    func deviceQAExposesLivePhotoProcessingScenario() throws {
        let harness = try sourceText(
            "Tests/PhotoMemoUITests/MemoMarkDeviceQAHarnessTests.swift"
        )

        #expect(
            harness.contains(
                "testMemoMarkQA04CanProcessPreparedLivePhotoFromTheInputAlbum"
            )
        )
        #expect(harness.contains("classification == \"livePhoto\""))
        #expect(harness.contains("qa-04-live-photo-processing-evidence.json"))
    }

    @Test("device QA navigates the iOS 27 picker segmented control without reopening it")
    func deviceQAPickerNavigationIsStable() throws {
        let harness = try sourceText(
            "Tests/PhotoMemoUITests/MemoMarkDeviceQAHarnessTests.swift"
        )

        #expect(
            harness.contains(
                "application.segmentedControls.buttons[\"精选集\"]"
            )
        )
        #expect(
            harness.contains(
                "let rawGridImages = preparedInputPhotoGridImages()"
            )
        )
        #expect(harness.contains("private func openPreparedInputAlbum()"))
        #expect(!harness.contains("let curatedTab = application.buttons[\"精选集\"]"))

        let qa05Start = harness.range(
            of: "func testMemoMarkQA05CanProcessHighestQualityRawFromThePreparedInputAlbum()"
        )!.lowerBound
        let qa07Start = harness.range(
            of: "func testMemoMarkQA07StaticPostCommitTerminationAndRestartIdempotency()"
        )!.lowerBound
        let qa05Section = harness[qa05Start..<qa07Start]
        #expect(qa05Section.contains("preparedInputPhotoGridImages()"))
        #expect(!qa05Section.contains("launchHostAndWait()"))
    }

    @Test("device QA exposes forced-termination recovery scenarios")
    func deviceQAExposesForcedTerminationRecoveryScenarios() throws {
        let harness = try sourceText(
            "Tests/PhotoMemoUITests/MemoMarkDeviceQAHarnessTests.swift"
        )
        let exportService = try sourceText(
            "Source/PhotoMemo/PhotoMemo/Services/PhotoLibraryExportService.swift"
        )
        let livePhotoWriter = try sourceText(
            "Source/PhotoMemo/PhotoMemo/MediaPipelineVNext/PhotoKitLivePhotoAssetWriter.swift"
        )

        #expect(
            harness.contains(
                "testMemoMarkQA07StaticPostCommitTerminationAndRestartIdempotency"
            )
        )
        #expect(
            harness.contains(
                "testMemoMarkQA08LivePhotoPostCommitTerminationAndRestartIdempotency"
            )
        )
        #expect(harness.contains("-qaPauseAfterPhotoLibraryCommit"))
        #expect(harness.contains("application.terminate()"))
        #expect(exportService.contains("PhotoLibraryCommitInterruptionTestHook"))
        #expect(exportService.contains("pauseIfRequested()"))
        #expect(livePhotoWriter.contains("PhotoLibraryCommitInterruptionTestHook"))
        #expect(livePhotoWriter.contains("pauseIfRequested()"))
    }

    @Test("runner exposes offline readiness replay without device tools")
    func runnerExposesOfflineReadinessReplay() throws {
        let source = try sourceText(
            "scripts/memomark-device-qa.sh"
        )
        let readiness = try sourceText(
            "scripts/memomark-device-qa-readiness.py"
        )

        #expect(source.contains("verify-readiness --run-dir <directory>"))
        #expect(source.contains("python3 \"${READINESS_REPORT_PATH}\" --verify"))
        #expect(readiness.contains("def verify_report"))
        #expect(readiness.contains("READINESS_GATE_NAMES"))
        #expect(readiness.contains("overallResult does not match"))
        #expect(readiness.contains("physical device reality is invalid"))
    }

    @Test("readiness refuses to reuse a directory with old evidence")
    func readinessRefusesStaleRunDirectoryReuse() throws {
        let source = try sourceText(
            "scripts/memomark-device-qa.sh"
        )
        let readiness = try sourceText(
            "scripts/memomark-device-qa-readiness.py"
        )

        #expect(source.contains("--check-fresh"))
        #expect(readiness.contains("def assert_fresh_run_directory"))
        #expect(readiness.contains("FRESH_READINESS_ALLOWED_ARTIFACTS"))
        #expect(readiness.contains("use a new run ID instead"))
    }

    @Test("readiness replay keeps blocked and malformed status nonzero")
    func readinessReplayExitContract() throws {
        let source = try sourceText(
            "scripts/memomark-device-qa-readiness.py"
        )

        #expect(source.contains("return result_exit_status(report[\"overallResult\"])"))
        #expect(source.contains("READINESS_OVERALL_RESULTS"))
        #expect(source.contains("SystemExit(2)"))
        #expect(source.contains("readiness error:"))
    }

    @Test("readiness separates CoreDevice failures from app failures")
    func readinessClassifiesPhysicalToolFailures() throws {
        let source = try sourceText(
            "scripts/memomark-device-qa.sh"
        )
        let readiness = try sourceText(
            "scripts/memomark-device-qa-readiness.py"
        )

        #expect(source.contains("--classify-preflight-failure"))
        #expect(source.contains("physical_device_reason"))
        #expect(readiness.contains("device-unavailable"))
        #expect(readiness.contains("coredevice-usage-assertion-failed"))
        #expect(readiness.contains("physical-device-preflight-failed"))
        #expect(readiness.contains("without treating them as app failures"))
    }

    @Test("readiness keeps the positive ready artifact path explicit")
    func readinessKeepsReadyArtifactPathExplicit() throws {
        let readiness = try sourceText(
            "scripts/memomark-device-qa-readiness.py"
        )

        #expect(readiness.contains("if physical_result == \"passed\""))
        #expect(readiness.contains("physical device identifier"))
        #expect(readiness.contains("reality") && readiness.contains("physical"))
        #expect(readiness.contains("return result_exit_status(report[\"overallResult\"])") )
    }

    @Test("build-check emits a manifest-bound machine-readable receipt")
    func buildCheckEmitsReceipt() throws {
        let source = try sourceText(
            "scripts/memomark-device-qa.sh"
        )
        let readiness = try sourceText(
            "scripts/memomark-device-qa-readiness.py"
        )

        #expect(source.contains("BUILD_CHECK_RECEIPT"))
        #expect(source.contains("build-check.json"))
        #expect(source.contains("MemoMarkDeviceQABuildCheck"))
        #expect(source.contains("\"runID\": run_id_value"))
        #expect(readiness.contains("validate_build_check_receipt"))
        #expect(readiness.contains("build-check receipt run ID does not match"))
        #expect(readiness.contains("qaHostProduct"))
        #expect(readiness.contains("hostBundleIdentifier"))
        #expect(readiness.contains("runnerBundleIdentifier"))
        #expect(readiness.contains("testBundleIdentifier"))
    }

    @Test("default run refuses to reuse an evidence directory")
    func defaultRunRefusesToReuseEvidenceDirectory() throws {
        let source = try sourceText("scripts/memomark-device-qa.sh")

        #expect(
            source.contains(
                "if [[ \"${COMMAND}\" == \"readiness\" || \"${COMMAND}\" == \"run\" ]]"
            )
        )
        #expect(source.contains("--check-fresh"))
    }

    private func sourceText(
        _ relativePath: String
    ) throws -> String {
        try String(
            contentsOf:
                repositoryRoot
                .appendingPathComponent(relativePath),
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

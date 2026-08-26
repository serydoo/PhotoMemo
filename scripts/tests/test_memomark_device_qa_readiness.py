from __future__ import annotations

import importlib.util
import json
import tempfile
import unittest
from pathlib import Path


SCRIPT_PATH = (
    Path(__file__).resolve().parents[1]
    / "memomark-device-qa-readiness.py"
)
SPEC = importlib.util.spec_from_file_location(
    "memomark_device_qa_readiness",
    SCRIPT_PATH,
)
if SPEC is None or SPEC.loader is None:
    raise RuntimeError("Unable to load readiness report module")
READINESS = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(READINESS)


class ReadinessReportTests(unittest.TestCase):
    def manifest(self) -> dict[str, object]:
        return {
            "schemaVersion": 1,
            "name": "MemoMark Device QA",
            "appBundleIdentifier": "com.serydoo.PhotoMemo",
            "defaultScheme": "MemoMarkDeviceQA",
            "qaTarget": "MemoMarkDeviceQA",
            "qaHostProduct": "MemoMarkiOS.app",
            "qaRunnerBundleIdentifier":
                "com.serydoo.PhotoMemo.MemoMarkDeviceQA.xctrunner",
            "scenarios": [
                {"id": f"QA-{index:02d}", "name": f"Scenario {index}"}
                for index in range(1, 9)
            ],
        }

    def signing(self, **overrides: object) -> dict[str, object]:
        payload: dict[str, object] = {
            "schemaVersion": 1,
            "mode": "read-only",
            "result": "blocked",
            "failureClass": "provisioning-profile-missing",
            "scheme": "MemoMarkDeviceQA",
            "target": "MemoMarkDeviceQA",
        }
        payload.update(overrides)
        return payload

    def test_blocked_signing_skips_physical_device(self) -> None:
        report = READINESS.compose_report(
            manifest=self.manifest(),
            run_id="blocked-run",
            device="iPhone7",
            device_identifier=None,
            scheme="MemoMarkDeviceQA",
            target="MemoMarkDeviceQA",
            configuration="Debug",
            manifest_result="passed",
            build_result="passed",
            build_log="build-check.log",
            signing=self.signing(),
            physical_device_result="skipped",
            physical_device_reason="signing-blocked",
            physical_device_details=None,
        )

        self.assertEqual(report["overallResult"], "blocked")
        self.assertEqual(report["gates"]["structuralBuild"]["result"], "passed")
        self.assertEqual(report["gates"]["signing"]["result"], "blocked")
        self.assertEqual(
            report["gates"]["physicalDevice"]["result"],
            "skipped",
        )
        self.assertEqual(
            report["gates"]["physicalDevice"]["reason"],
            "signing-blocked",
        )

    def test_ready_report_requires_a_completed_physical_device_gate(self) -> None:
        report = READINESS.compose_report(
            manifest=self.manifest(),
            run_id="ready-run",
            device="iPhone7",
            device_identifier="device-udid",
            scheme="MemoMarkDeviceQA",
            target="MemoMarkDeviceQA",
            configuration="Debug",
            manifest_result="passed",
            build_result="passed",
            build_log="build-check.log",
            signing=self.signing(result="ready", failureClass=None),
            physical_device_result="passed",
            physical_device_reason=None,
            physical_device_details={
                "result": {
                    "identifier": "device-udid",
                    "properties": {
                        "hardware": {
                            "reality": "physical",
                        },
                    },
                },
            },
        )

        self.assertEqual(report["overallResult"], "ready")
        self.assertEqual(
            report["gates"]["physicalDevice"]["identifier"],
            "device-udid",
        )

    def test_failed_structural_build_is_not_blocked_signing(self) -> None:
        report = READINESS.compose_report(
            manifest=self.manifest(),
            run_id="build-failed-run",
            device="iPhone7",
            device_identifier=None,
            scheme="MemoMarkDeviceQA",
            target="MemoMarkDeviceQA",
            configuration="Debug",
            manifest_result="passed",
            build_result="failed",
            build_log="build-check.log",
            signing=self.signing(),
            physical_device_result="skipped",
            physical_device_reason="structural-build-failed",
            physical_device_details=None,
        )

        self.assertEqual(report["overallResult"], "failed")
        self.assertEqual(
            report["gates"]["physicalDevice"]["reason"],
            "structural-build-failed",
        )

    def test_ready_claim_without_physical_evidence_is_downgraded(self) -> None:
        report = READINESS.compose_report(
            manifest=self.manifest(),
            run_id="missing-device-evidence",
            device="iPhone7",
            device_identifier="device-udid",
            scheme="MemoMarkDeviceQA",
            target="MemoMarkDeviceQA",
            configuration="Debug",
            manifest_result="passed",
            build_result="passed",
            build_log="build-check.log",
            signing=self.signing(result="ready", failureClass=None),
            physical_device_result="passed",
            physical_device_reason=None,
            physical_device_details=None,
        )

        self.assertEqual(report["overallResult"], "failed")
        self.assertEqual(
            report["gates"]["physicalDevice"]["reason"],
            "physical-device-evidence-invalid",
        )

    def test_write_report_uses_a_regular_json_file(self) -> None:
        report = READINESS.compose_report(
            manifest=self.manifest(),
            run_id="write-run",
            device="iPhone7",
            device_identifier=None,
            scheme="MemoMarkDeviceQA",
            target="MemoMarkDeviceQA",
            configuration="Debug",
            manifest_result="failed",
            build_result="skipped",
            build_log=None,
            signing=None,
            physical_device_result="skipped",
            physical_device_reason="manifest-invalid",
            physical_device_details=None,
        )

        with tempfile.TemporaryDirectory() as directory:
            output = Path(directory) / "readiness.json"
            READINESS.write_report(output, report)
            self.assertTrue(output.is_file())
            self.assertEqual(json.loads(output.read_text()), report)

    def test_verify_report_replays_a_generated_report(self) -> None:
        report = READINESS.compose_report(
            manifest=self.manifest(),
            run_id="replay-run",
            device="iPhone7",
            device_identifier=None,
            scheme="MemoMarkDeviceQA",
            target="MemoMarkDeviceQA",
            configuration="Debug",
            manifest_result="passed",
            build_result="passed",
            build_log="build-check.log",
            signing=self.signing(),
            physical_device_result="skipped",
            physical_device_reason="signing-blocked",
            physical_device_details=None,
        )

        with tempfile.TemporaryDirectory() as directory:
            output = Path(directory) / "readiness.json"
            READINESS.write_report(output, report)
            replayed = READINESS.verify_report(output)
            self.assertEqual(replayed["overallResult"], "blocked")

    def test_verify_report_rejects_tampered_overall_result(self) -> None:
        report = READINESS.compose_report(
            manifest=self.manifest(),
            run_id="tampered-run",
            device="iPhone7",
            device_identifier=None,
            scheme="MemoMarkDeviceQA",
            target="MemoMarkDeviceQA",
            configuration="Debug",
            manifest_result="passed",
            build_result="passed",
            build_log="build-check.log",
            signing=self.signing(),
            physical_device_result="skipped",
            physical_device_reason="signing-blocked",
            physical_device_details=None,
        )
        report["overallResult"] = "ready"

        with tempfile.TemporaryDirectory() as directory:
            output = Path(directory) / "readiness.json"
            output.write_text(json.dumps(report), encoding="utf-8")
            with self.assertRaisesRegex(ValueError, "overallResult"):
                READINESS.verify_report(output)

    def test_verify_report_rejects_an_extra_gate(self) -> None:
        report = READINESS.compose_report(
            manifest=self.manifest(),
            run_id="extra-gate-run",
            device="iPhone7",
            device_identifier=None,
            scheme="MemoMarkDeviceQA",
            target="MemoMarkDeviceQA",
            configuration="Debug",
            manifest_result="passed",
            build_result="passed",
            build_log="build-check.log",
            signing=self.signing(),
            physical_device_result="skipped",
            physical_device_reason="signing-blocked",
            physical_device_details=None,
        )
        report["gates"]["photos"] = {"result": "passed"}

        with tempfile.TemporaryDirectory() as directory:
            output = Path(directory) / "readiness.json"
            output.write_text(json.dumps(report), encoding="utf-8")
            with self.assertRaisesRegex(ValueError, "gate names"):
                READINESS.verify_report(output)

    def _blocked_report(self) -> dict[str, object]:
        return READINESS.compose_report(
            manifest=self.manifest(),
            run_id="directory-run",
            device="iPhone7",
            device_identifier=None,
            scheme="MemoMarkDeviceQA",
            target="MemoMarkDeviceQA",
            configuration="Debug",
            manifest_result="passed",
            build_result="passed",
            build_log="build-check.log",
            signing=self.signing(),
            physical_device_result="skipped",
            physical_device_reason="signing-blocked",
            physical_device_details=None,
        )

    def _write_readiness_directory(self, directory: Path) -> None:
        (directory / "MemoMarkDeviceQA.json").write_text(
            json.dumps(self.manifest()),
            encoding="utf-8",
        )
        READINESS.write_report(
            directory / "readiness.json",
            self._blocked_report(),
        )
        for name in (
            "manifest-validation.log",
            "build-check.log",
            "signing-output.log",
        ):
            (directory / name).write_text("diagnostic", encoding="utf-8")
        (directory / "build-check.json").write_text(
            json.dumps(
                {
                    "schemaVersion": 1,
                    "kind": "MemoMarkDeviceQABuildCheck",
                    "mode": "unsigned-structural",
                    "project": "MemoMark",
                    "scheme": "MemoMarkDeviceQA",
                    "target": "MemoMarkDeviceQA",
                    "configuration": "Debug",
                    "runID": "directory-run",
                    "result": "passed",
                    "hostProduct": "MemoMarkiOS.app",
                    "hostBundleIdentifier": "com.serydoo.PhotoMemo",
                    "runnerProduct": "MemoMarkDeviceQA-Runner.app",
                    "runnerBundleIdentifier":
                        "com.serydoo.PhotoMemo.MemoMarkDeviceQA.xctrunner",
                    "testBundleProduct": "MemoMarkDeviceQA.xctest",
                    "testBundleIdentifier":
                        "com.serydoo.PhotoMemo.MemoMarkDeviceQA",
                }
            ),
            encoding="utf-8",
        )
        (directory / "signing-status.json").write_text(
            json.dumps(self.signing()),
            encoding="utf-8",
        )

    def test_verify_run_directory_replays_a_valid_readiness_bundle(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            run_directory = Path(directory)
            self._write_readiness_directory(run_directory)
            report = READINESS.verify_run_directory(run_directory)
            self.assertEqual(report["overallResult"], "blocked")

    def test_verify_run_directory_rejects_private_or_unknown_artifact(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            run_directory = Path(directory)
            self._write_readiness_directory(run_directory)
            (run_directory / "private-photo.heic").write_bytes(b"private")
            with self.assertRaisesRegex(ValueError, "unexpected"):
                READINESS.verify_run_directory(run_directory)

    def test_verify_run_directory_rejects_manifest_identity_mismatch(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            run_directory = Path(directory)
            self._write_readiness_directory(run_directory)
            manifest_path = run_directory / "MemoMarkDeviceQA.json"
            manifest = json.loads(manifest_path.read_text())
            manifest["defaultScheme"] = "OtherDeviceQA"
            manifest_path.write_text(json.dumps(manifest), encoding="utf-8")
            with self.assertRaisesRegex(ValueError, "scheme"):
                READINESS.verify_run_directory(run_directory)

    def test_verify_run_directory_rejects_non_object_scenario(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            run_directory = Path(directory)
            self._write_readiness_directory(run_directory)
            manifest_path = run_directory / "MemoMarkDeviceQA.json"
            manifest = json.loads(manifest_path.read_text())
            manifest["scenarios"].append("not-a-scenario")
            manifest_path.write_text(json.dumps(manifest), encoding="utf-8")
            with self.assertRaisesRegex(ValueError, "scenarios"):
                READINESS.verify_run_directory(run_directory)

    def test_verify_run_directory_rejects_symlinked_readiness_report(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            run_directory = Path(directory)
            self._write_readiness_directory(run_directory)
            external_report = run_directory.parent / "readiness-outside.json"
            external_report.write_text(
                (run_directory / "readiness.json").read_text(),
                encoding="utf-8",
            )
            (run_directory / "readiness.json").unlink()
            (run_directory / "readiness.json").symlink_to(external_report)
            with self.assertRaisesRegex(ValueError, "regular file"):
                READINESS.verify_run_directory(run_directory)

    def test_fresh_run_directory_allows_an_empty_directory(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            READINESS.assert_fresh_run_directory(Path(directory))

    def test_fresh_run_directory_allows_only_a_regular_manifest(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            run_directory = Path(directory)
            (run_directory / "MemoMarkDeviceQA.json").write_text(
                json.dumps(self.manifest()),
                encoding="utf-8",
            )
            READINESS.assert_fresh_run_directory(run_directory)

    def test_fresh_run_directory_rejects_stale_evidence(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            run_directory = Path(directory)
            (run_directory / "readiness.json").write_text(
                "stale",
                encoding="utf-8",
            )
            with self.assertRaisesRegex(
                ValueError,
                "device QA run directory is not fresh",
            ):
                READINESS.assert_fresh_run_directory(run_directory)

    def test_fresh_run_directory_rejects_a_manifest_symlink(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            run_directory = Path(directory)
            external_manifest = run_directory.parent / "manifest-outside.json"
            external_manifest.write_text(
                json.dumps(self.manifest()),
                encoding="utf-8",
            )
            (run_directory / "MemoMarkDeviceQA.json").symlink_to(
                external_manifest
            )
            with self.assertRaisesRegex(ValueError, "regular file"):
                READINESS.assert_fresh_run_directory(run_directory)

    def test_result_exit_status_is_ready_only_for_ready_reports(self) -> None:
        self.assertEqual(READINESS.result_exit_status("ready"), 0)
        self.assertEqual(READINESS.result_exit_status("blocked"), 1)
        self.assertEqual(READINESS.result_exit_status("failed"), 1)

    def test_result_exit_status_rejects_unknown_results(self) -> None:
        with self.assertRaisesRegex(ValueError, "result"):
            READINESS.result_exit_status("unknown")

    def test_result_exit_status_rejects_non_string_json_values(self) -> None:
        with self.assertRaisesRegex(ValueError, "result"):
            READINESS.result_exit_status([])

    def test_verify_report_rejects_non_string_gate_result(self) -> None:
        report = self._blocked_report()
        report["gates"]["manifest"]["result"] = {}

        with tempfile.TemporaryDirectory() as directory:
            output = Path(directory) / "readiness.json"
            output.write_text(json.dumps(report), encoding="utf-8")
            with self.assertRaisesRegex(ValueError, "manifest has an invalid result"):
                READINESS.verify_report(output)

    def test_verify_report_rejects_ready_manifest_gate(self) -> None:
        report = self._blocked_report()
        report["gates"]["manifest"]["result"] = "ready"
        report["overallResult"] = "blocked"

        with tempfile.TemporaryDirectory() as directory:
            output = Path(directory) / "readiness.json"
            output.write_text(json.dumps(report), encoding="utf-8")
            with self.assertRaisesRegex(ValueError, "manifest result"):
                READINESS.verify_report(output)

    def test_verify_report_requires_parseable_generated_at(self) -> None:
        report = self._blocked_report()
        report.pop("generatedAt")

        with tempfile.TemporaryDirectory() as directory:
            output = Path(directory) / "readiness.json"
            output.write_text(json.dumps(report), encoding="utf-8")
            with self.assertRaisesRegex(ValueError, "generatedAt"):
                READINESS.verify_report(output)

    def test_verify_report_rejects_a_future_generated_at(self) -> None:
        report = self._blocked_report()
        report["generatedAt"] = "2999-01-01T00:00:00+00:00"

        with tempfile.TemporaryDirectory() as directory:
            output = Path(directory) / "readiness.json"
            output.write_text(json.dumps(report), encoding="utf-8")
            with self.assertRaisesRegex(ValueError, "future"):
                READINESS.verify_report(output)

    def test_verify_report_rejects_a_naive_generated_at(self) -> None:
        report = self._blocked_report()
        report["generatedAt"] = "2026-08-13T12:00:00"

        with tempfile.TemporaryDirectory() as directory:
            output = Path(directory) / "readiness.json"
            output.write_text(json.dumps(report), encoding="utf-8")
            with self.assertRaisesRegex(ValueError, "timezone"):
                READINESS.verify_report(output)

    def test_classifies_unavailable_device_from_preflight_log(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            log = Path(directory) / "preflight.log"
            log.write_text(
                "iPhone7 863C... unavailable physical\n",
                encoding="utf-8",
            )
            self.assertEqual(
                READINESS.classify_preflight_failure(log, "iPhone7"),
                "device-unavailable",
            )

    def test_classifies_coredevice_usage_assertion_failure(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            log = Path(directory) / "preflight.log"
            log.write_text(
                "CoreDeviceError error 4016 usage assertion requirements\n",
                encoding="utf-8",
            )
            self.assertEqual(
                READINESS.classify_preflight_failure(log, "iPhone7"),
                "coredevice-usage-assertion-failed",
            )

    def test_classifies_unknown_preflight_failure_conservatively(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            log = Path(directory) / "preflight.log"
            log.write_text("unexpected preflight failure\n", encoding="utf-8")
            self.assertEqual(
                READINESS.classify_preflight_failure(log, "iPhone7"),
                "physical-device-preflight-failed",
            )

    def test_verify_run_directory_accepts_a_complete_ready_bundle(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            run_directory = Path(directory)
            manifest = self.manifest()
            (run_directory / "MemoMarkDeviceQA.json").write_text(
                json.dumps(manifest),
                encoding="utf-8",
            )
            signing = self.signing(result="ready", failureClass=None)
            report = READINESS.compose_report(
                manifest=manifest,
                run_id="ready-directory-run",
                device="iPhone7",
                device_identifier="device-udid",
                scheme="MemoMarkDeviceQA",
                target="MemoMarkDeviceQA",
                configuration="Debug",
                manifest_result="passed",
                build_result="passed",
                build_log="build-check.log",
                signing=signing,
                physical_device_result="passed",
                physical_device_reason=None,
                physical_device_details={
                    "result": {
                        "identifier": "device-udid",
                        "properties": {
                            "hardware": {
                                "reality": "physical",
                            },
                        },
                    },
                },
            )
            READINESS.write_report(run_directory / "readiness.json", report)
            (run_directory / "build-check.log").write_text(
                "TEST BUILD SUCCEEDED",
                encoding="utf-8",
            )
            (run_directory / "build-check.json").write_text(
                json.dumps(
                    {
                        "schemaVersion": 1,
                        "kind": "MemoMarkDeviceQABuildCheck",
                        "mode": "unsigned-structural",
                        "project": "MemoMark",
                        "scheme": "MemoMarkDeviceQA",
                        "target": "MemoMarkDeviceQA",
                        "configuration": "Debug",
                        "runID": "ready-directory-run",
                        "result": "passed",
                        "hostProduct": "MemoMarkiOS.app",
                        "hostBundleIdentifier": "com.serydoo.PhotoMemo",
                        "runnerProduct": "MemoMarkDeviceQA-Runner.app",
                        "runnerBundleIdentifier":
                            "com.serydoo.PhotoMemo.MemoMarkDeviceQA.xctrunner",
                        "testBundleProduct": "MemoMarkDeviceQA.xctest",
                        "testBundleIdentifier":
                            "com.serydoo.PhotoMemo.MemoMarkDeviceQA",
                    }
                ),
                encoding="utf-8",
            )
            (run_directory / "signing-status.json").write_text(
                json.dumps(signing),
                encoding="utf-8",
            )
            (run_directory / "preflight.log").write_text(
                "iPhone7 available physical\nunlockedSinceBoot: true",
                encoding="utf-8",
            )
            (run_directory / "device-details.json").write_text(
                json.dumps(
                    {
                        "result": {
                            "identifier": "device-udid",
                            "properties": {
                                "hardware": {
                                    "reality": "physical",
                                },
                            },
                        },
                    }
                ),
                encoding="utf-8",
            )

            replayed = READINESS.verify_run_directory(run_directory)
            self.assertEqual(replayed["overallResult"], "ready")
            self.assertEqual(READINESS.result_exit_status("ready"), 0)

    def test_build_check_receipt_requires_manifest_bound_products(self) -> None:
        receipt = {
            "schemaVersion": 1,
            "kind": "MemoMarkDeviceQABuildCheck",
            "mode": "unsigned-structural",
            "project": "MemoMark",
            "scheme": "MemoMarkDeviceQA",
            "target": "MemoMarkDeviceQA",
            "configuration": "Debug",
            "runID": "current-run",
            "result": "passed",
            "hostBundleIdentifier": "com.serydoo.PhotoMemo",
            "runnerBundleIdentifier":
                "com.serydoo.PhotoMemo.MemoMarkDeviceQA.xctrunner",
            "testBundleIdentifier": "com.serydoo.PhotoMemo.MemoMarkDeviceQA",
            "hostProduct": "MemoMarkiOS.app",
            "runnerProduct": "MemoMarkDeviceQA-Runner.app",
            "testBundleProduct": "MemoMarkDeviceQA.xctest",
        }
        self.assertTrue(READINESS.validate_build_check_receipt(
            receipt,
            self.manifest(),
            "MemoMarkDeviceQA",
            "MemoMarkDeviceQA",
            "Debug",
            "current-run",
        ))

    def test_build_check_receipt_rejects_a_foreign_runner(self) -> None:
        receipt = {
            "schemaVersion": 1,
            "kind": "MemoMarkDeviceQABuildCheck",
            "mode": "unsigned-structural",
            "project": "MemoMark",
            "scheme": "MemoMarkDeviceQA",
            "target": "MemoMarkDeviceQA",
            "configuration": "Debug",
            "runID": "current-run",
            "result": "passed",
            "hostBundleIdentifier": "com.serydoo.PhotoMemo",
            "runnerBundleIdentifier": "com.example.Foreign.xctrunner",
            "testBundleIdentifier": "com.serydoo.PhotoMemo.MemoMarkDeviceQA",
            "hostProduct": "MemoMarkiOS.app",
            "runnerProduct": "MemoMarkDeviceQA-Runner.app",
            "testBundleProduct": "MemoMarkDeviceQA.xctest",
        }
        with self.assertRaisesRegex(ValueError, "runner Bundle ID"):
            READINESS.validate_build_check_receipt(
                receipt,
                self.manifest(),
                "MemoMarkDeviceQA",
                "MemoMarkDeviceQA",
                "Debug",
                "current-run",
            )

    def test_build_check_receipt_rejects_a_foreign_product_name(self) -> None:
        receipt = {
            "schemaVersion": 1,
            "kind": "MemoMarkDeviceQABuildCheck",
            "mode": "unsigned-structural",
            "project": "MemoMark",
            "scheme": "MemoMarkDeviceQA",
            "target": "MemoMarkDeviceQA",
            "configuration": "Debug",
            "runID": "current-run",
            "result": "passed",
            "hostProduct": "foreign-host.app",
            "hostBundleIdentifier": "com.serydoo.PhotoMemo",
            "runnerProduct": "MemoMarkDeviceQA-Runner.app",
            "runnerBundleIdentifier":
                "com.serydoo.PhotoMemo.MemoMarkDeviceQA.xctrunner",
            "testBundleProduct": "MemoMarkDeviceQA.xctest",
            "testBundleIdentifier": "com.serydoo.PhotoMemo.MemoMarkDeviceQA",
        }
        with self.assertRaisesRegex(ValueError, "host product"):
            READINESS.validate_build_check_receipt(
                receipt,
                self.manifest(),
                "MemoMarkDeviceQA",
                "MemoMarkDeviceQA",
                "Debug",
                "current-run",
            )

    def test_build_check_receipt_rejects_a_receipt_from_another_run(self) -> None:
        receipt = {
            "schemaVersion": 1,
            "kind": "MemoMarkDeviceQABuildCheck",
            "mode": "unsigned-structural",
            "project": "MemoMark",
            "scheme": "MemoMarkDeviceQA",
            "target": "MemoMarkDeviceQA",
            "configuration": "Debug",
            "runID": "old-run",
            "result": "passed",
            "hostProduct": "MemoMarkiOS.app",
            "hostBundleIdentifier": "com.serydoo.PhotoMemo",
            "runnerProduct": "MemoMarkDeviceQA-Runner.app",
            "runnerBundleIdentifier":
                "com.serydoo.PhotoMemo.MemoMarkDeviceQA.xctrunner",
            "testBundleProduct": "MemoMarkDeviceQA.xctest",
            "testBundleIdentifier": "com.serydoo.PhotoMemo.MemoMarkDeviceQA",
        }
        with self.assertRaisesRegex(ValueError, "run ID"):
            READINESS.validate_build_check_receipt(
                receipt,
                self.manifest(),
                "MemoMarkDeviceQA",
                "MemoMarkDeviceQA",
                "Debug",
                "current-run",
            )


if __name__ == "__main__":
    unittest.main()

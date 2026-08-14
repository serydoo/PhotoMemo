from __future__ import annotations

import importlib.util
import json
import shutil
import tempfile
import unittest
from pathlib import Path


SCRIPT_PATH = (
    Path(__file__).resolve().parents[1] / "memomark-device-qa-verify.py"
)
SPEC = importlib.util.spec_from_file_location(
    "memomark_device_qa_verify",
    SCRIPT_PATH,
)
if SPEC is None or SPEC.loader is None:
    raise RuntimeError("Unable to load device QA verifier module")
VERIFIER = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(VERIFIER)


class EarlySigningArtifactTests(unittest.TestCase):
    MANIFEST = (
        Path(__file__).resolve().parents[2] / "QA" / "MemoMarkDeviceQA.json"
    )

    def setUp(self) -> None:
        self.temporary_directory = tempfile.TemporaryDirectory()
        self.run_directory = Path(self.temporary_directory.name)
        shutil.copy(self.MANIFEST, self.run_directory / "MemoMarkDeviceQA.json")

    def tearDown(self) -> None:
        self.temporary_directory.cleanup()

    def write_signing_status(self, **overrides: object) -> None:
        payload: dict[str, object] = {
            "schemaVersion": 1,
            "mode": "read-only",
            "project": str(
                Path(__file__).resolve().parents[2]
                / "Source"
                / "PhotoMemo"
                / "PhotoMemo.xcodeproj"
            ),
            "scheme": "MemoMarkDeviceQA",
            "configuration": "Debug",
            "target": "MemoMarkDeviceQA",
            "runnerBundleIdentifier":
                "com.serydoo.PhotoMemo.MemoMarkDeviceQA.xctrunner",
            "result": "blocked",
            "failureClass": "provisioning-profile-missing",
        }
        payload.update(overrides)
        with (self.run_directory / "signing-status.json").open(
            "w",
            encoding="utf-8",
        ) as file:
            json.dump(payload, file)

    def test_accepts_blocked_signing_artifact_without_device_evidence(self) -> None:
        self.write_signing_status()

        result = VERIFIER.verify_early_signing_artifact(self.run_directory)

        self.assertEqual(result["result"], "blocked")
        self.assertEqual(
            result["failureClass"],
            "provisioning-profile-missing",
        )
        self.assertTrue(result["manifestIdentityBound"])

    def test_rejects_early_artifact_with_device_evidence(self) -> None:
        self.write_signing_status()
        (self.run_directory / "device-details.json").write_text(
            "{}",
            encoding="utf-8",
        )

        with self.assertRaisesRegex(ValueError, "device evidence"):
            VERIFIER.verify_early_signing_artifact(self.run_directory)

    def test_rejects_unexpected_extra_file_in_early_artifact(self) -> None:
        self.write_signing_status()
        (self.run_directory / "unexpected.txt").write_text(
            "private or stale evidence",
            encoding="utf-8",
        )

        with self.assertRaisesRegex(ValueError, "unexpected"):
            VERIFIER.verify_early_signing_artifact(self.run_directory)

    def test_rejects_unexpected_extra_directory_in_early_artifact(self) -> None:
        self.write_signing_status()
        (self.run_directory / "private-media").mkdir()

        with self.assertRaisesRegex(ValueError, "unexpected"):
            VERIFIER.verify_early_signing_artifact(self.run_directory)

    def test_rejects_allowed_manifest_directory(self) -> None:
        manifest_path = self.run_directory / "MemoMarkDeviceQA.json"
        manifest_path.unlink()
        manifest_path.mkdir()
        self.write_signing_status()

        with self.assertRaisesRegex(ValueError, "regular file"):
            VERIFIER.verify_early_signing_artifact(self.run_directory)

    def test_rejects_manifest_symlink_to_outside_run_directory(self) -> None:
        manifest_path = self.run_directory / "MemoMarkDeviceQA.json"
        manifest_copy = self.run_directory.parent / "manifest-outside-run.json"
        manifest_copy.write_text(
            manifest_path.read_text(encoding="utf-8"),
            encoding="utf-8",
        )
        manifest_path.unlink()
        manifest_path.symlink_to(manifest_copy)
        self.write_signing_status()

        with self.assertRaisesRegex(ValueError, "symlink"):
            VERIFIER.verify_early_signing_artifact(self.run_directory)

    def test_rejects_signing_status_symlink_to_outside_run_directory(self) -> None:
        self.write_signing_status()
        signing_status_path = self.run_directory / "signing-status.json"
        signing_status_copy = self.run_directory.parent / "signing-status-outside-run.json"
        signing_status_copy.write_text(
            signing_status_path.read_text(encoding="utf-8"),
            encoding="utf-8",
        )
        signing_status_path.unlink()
        signing_status_path.symlink_to(signing_status_copy)

        with self.assertRaisesRegex(ValueError, "symlink"):
            VERIFIER.verify_early_signing_artifact(self.run_directory)

    def test_rejects_symlinked_run_directory(self) -> None:
        self.write_signing_status()
        run_alias = self.run_directory.parent / (
            self.run_directory.name + "-alias"
        )
        run_alias.symlink_to(self.run_directory, target_is_directory=True)

        try:
            with self.assertRaisesRegex(ValueError, "symlink"):
                VERIFIER.verify_early_signing_artifact(run_alias)
        finally:
            run_alias.unlink()

    def test_rejects_ready_signing_status_as_early_blocked_evidence(self) -> None:
        self.write_signing_status(result="ready", failureClass=None)

        with self.assertRaisesRegex(ValueError, "blocked"):
            VERIFIER.verify_early_signing_artifact(self.run_directory)

    def test_rejects_signing_status_for_another_target(self) -> None:
        self.write_signing_status(target="OtherDeviceQA")

        with self.assertRaisesRegex(ValueError, "target"):
            VERIFIER.verify_early_signing_artifact(self.run_directory)

    def test_rejects_signing_status_for_another_runner_bundle(self) -> None:
        self.write_signing_status(
            runnerBundleIdentifier="com.example.OtherDeviceQA.xctrunner"
        )

        with self.assertRaisesRegex(ValueError, "runner Bundle ID"):
            VERIFIER.verify_early_signing_artifact(self.run_directory)

    def test_replays_legacy_manifest_without_identity_fields(self) -> None:
        manifest_path = self.run_directory / "MemoMarkDeviceQA.json"
        manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
        manifest.pop("qaTarget")
        manifest.pop("qaRunnerBundleIdentifier")
        manifest_path.write_text(
            json.dumps(manifest),
            encoding="utf-8",
        )
        self.write_signing_status()

        result = VERIFIER.verify_early_signing_artifact(self.run_directory)

        self.assertFalse(result["manifestIdentityBound"])

    def test_rejects_signing_status_for_another_scheme(self) -> None:
        self.write_signing_status(scheme="OtherDeviceQA")

        with self.assertRaisesRegex(ValueError, "scheme"):
            VERIFIER.verify_early_signing_artifact(self.run_directory)

    def test_rejects_signing_status_for_another_project(self) -> None:
        self.write_signing_status(project="/tmp/OtherMemoMark.xcodeproj")

        with self.assertRaisesRegex(ValueError, "project"):
            VERIFIER.verify_early_signing_artifact(self.run_directory)


class RegularRunMetadataIdentityTests(unittest.TestCase):
    MANIFEST = (
        Path(__file__).resolve().parents[2] / "QA" / "MemoMarkDeviceQA.json"
    )

    def setUp(self) -> None:
        self.temporary_directory = tempfile.TemporaryDirectory()
        self.run_directory = Path(self.temporary_directory.name)
        self.external_directory = (
            self.run_directory.parent / f"{self.run_directory.name}-external"
        )
        self.external_directory.mkdir()
        shutil.copy(self.MANIFEST, self.run_directory / "MemoMarkDeviceQA.json")
        self.write_json(
            "run-metadata.json",
            {
                "schemaVersion": 1,
                "runID": "regular-run",
                "device": "iPhone7",
                "deviceIdentifier": "device-udid",
                "scheme": "MemoMarkDeviceQA",
                "configuration": "Debug",
                "target": "MemoMarkDeviceQA",
                "project": "MemoMark",
                "xcodebuildExitStatus": 0,
            },
        )
        self.write_json(
            "test-summary.json",
            {
                "result": "Passed",
                "failedTests": 0,
                "totalTestCount": 1,
            },
        )
        self.write_json(
            "device-details.json",
            {
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
        (self.run_directory / "xcodebuild.log").write_text(
            "xcodebuild completed",
            encoding="utf-8",
        )
        result_bundle = self.run_directory / "MemoMarkDeviceQA.xcresult"
        result_bundle.mkdir()
        (result_bundle / "Info.plist").write_text(
            "{}",
            encoding="utf-8",
        )

    def tearDown(self) -> None:
        shutil.rmtree(self.external_directory)
        self.temporary_directory.cleanup()

    def write_json(self, name: str, payload: dict[str, object]) -> None:
        with (self.run_directory / name).open("w", encoding="utf-8") as file:
            json.dump(payload, file)

    def update_metadata(self, **overrides: object) -> None:
        path = self.run_directory / "run-metadata.json"
        metadata = json.loads(path.read_text(encoding="utf-8"))
        metadata.update(overrides)
        path.write_text(json.dumps(metadata), encoding="utf-8")

    def test_accepts_manifest_bound_regular_run(self) -> None:
        _, result = VERIFIER.verify_run(self.run_directory, None)

        self.assertEqual(result["result"], "pass")

    def test_accepts_regular_run_with_signing_status_evidence(self) -> None:
        self.write_json("signing-status.json", {})

        _, result = VERIFIER.verify_run(self.run_directory, None)

        self.assertEqual(result["result"], "pass")

    def test_rejects_regular_run_for_another_scheme(self) -> None:
        self.update_metadata(scheme="PhotoMemo")

        with self.assertRaisesRegex(ValueError, "scheme"):
            VERIFIER.verify_run(self.run_directory, None)

    def test_rejects_regular_run_for_another_target(self) -> None:
        self.update_metadata(target="OtherDeviceQA")

        with self.assertRaisesRegex(ValueError, "target"):
            VERIFIER.verify_run(self.run_directory, None)

    def test_rejects_regular_run_for_another_device_identifier(self) -> None:
        self.update_metadata(deviceIdentifier="another-device")

        with self.assertRaisesRegex(ValueError, "device identifier"):
            VERIFIER.verify_run(self.run_directory, None)

    def test_rejects_regular_run_for_another_project(self) -> None:
        self.update_metadata(project="OtherMemoMark")

        with self.assertRaisesRegex(ValueError, "project"):
            VERIFIER.verify_run(self.run_directory, None)

    def test_rejects_regular_run_with_unsupported_metadata_schema(self) -> None:
        self.update_metadata(schemaVersion=2)

        with self.assertRaisesRegex(ValueError, "schemaVersion"):
            VERIFIER.verify_run(self.run_directory, None)

    def test_rejects_regular_run_without_device_identifier(self) -> None:
        path = self.run_directory / "run-metadata.json"
        metadata = json.loads(path.read_text(encoding="utf-8"))
        metadata.pop("deviceIdentifier")
        path.write_text(json.dumps(metadata), encoding="utf-8")

        with self.assertRaisesRegex(ValueError, "device identifier"):
            VERIFIER.verify_run(self.run_directory, None)

    def test_rejects_regular_run_without_run_id(self) -> None:
        path = self.run_directory / "run-metadata.json"
        metadata = json.loads(path.read_text(encoding="utf-8"))
        metadata.pop("runID")
        path.write_text(json.dumps(metadata), encoding="utf-8")

        with self.assertRaisesRegex(ValueError, "runID"):
            VERIFIER.verify_run(self.run_directory, None)

    def test_rejects_boolean_xcodebuild_exit_status(self) -> None:
        self.update_metadata(xcodebuildExitStatus=True)

        with self.assertRaisesRegex(ValueError, "integer xcodebuildExitStatus"):
            VERIFIER.verify_run(self.run_directory, None)

    def test_rejects_regular_run_summary_with_wrong_result_type(self) -> None:
        self.write_json(
            "test-summary.json",
            {
                "result": 1,
                "failedTests": 0,
                "totalTestCount": 1,
            },
        )

        with self.assertRaisesRegex(ValueError, "test summary result"):
            VERIFIER.verify_run(self.run_directory, None)

    def test_rejects_regular_run_with_malformed_summary_json(self) -> None:
        (self.run_directory / "test-summary.json").write_text(
            "{ malformed",
            encoding="utf-8",
        )

        with self.assertRaisesRegex(ValueError, "invalid JSON artifact"):
            VERIFIER.verify_run(self.run_directory, None)

    def test_rejects_regular_run_summary_with_negative_counts(self) -> None:
        self.write_json(
            "test-summary.json",
            {
                "result": "Passed",
                "failedTests": -1,
                "totalTestCount": 1,
            },
        )

        with self.assertRaisesRegex(ValueError, "test summary failedTests"):
            VERIFIER.verify_run(self.run_directory, None)

    def test_accepts_unknown_summary_for_incomplete_regular_run(self) -> None:
        self.write_json(
            "test-summary.json",
            {
                "result": "unknown",
                "failedTests": 0,
                "totalTestCount": 0,
            },
        )

        _, result = VERIFIER.verify_run(self.run_directory, None)

        self.assertEqual(result["result"], "fail")
        self.assertEqual(result["failureClass"], "runner-failed")

    def test_rejects_regular_run_device_evidence_without_identifier(self) -> None:
        self.write_json(
            "device-details.json",
            {
                "result": {
                    "properties": {
                        "hardware": {
                            "reality": "physical",
                        },
                    },
                },
            },
        )

        with self.assertRaisesRegex(ValueError, "device evidence identifier"):
            VERIFIER.verify_run(self.run_directory, None)

    def test_rejects_regular_run_with_malformed_device_evidence_json(self) -> None:
        (self.run_directory / "device-details.json").write_text(
            "{ malformed",
            encoding="utf-8",
        )

        with self.assertRaisesRegex(ValueError, "invalid JSON artifact"):
            VERIFIER.verify_run(self.run_directory, None)

    def test_write_metadata_updates_regular_run_atomically(self) -> None:
        metadata, result = VERIFIER.verify_run(self.run_directory, None)

        VERIFIER.write_metadata(
            self.run_directory / "run-metadata.json",
            metadata,
            result,
        )

        updated = json.loads(
            (self.run_directory / "run-metadata.json").read_text(
                encoding="utf-8"
            )
        )
        self.assertEqual(updated["result"], "pass")
        self.assertEqual(updated["failureClass"], None)
        self.assertIsInstance(updated["finishedAt"], str)

    def test_write_metadata_rejects_symlinked_target(self) -> None:
        metadata, result = VERIFIER.verify_run(self.run_directory, None)
        metadata_path = self.run_directory / "run-metadata.json"
        metadata_copy = self.external_directory / metadata_path.name
        shutil.copy(metadata_path, metadata_copy)
        metadata_path.unlink()
        metadata_path.symlink_to(metadata_copy)

        with self.assertRaisesRegex(ValueError, "symlink"):
            VERIFIER.write_metadata(metadata_path, metadata, result)

    def test_rejects_regular_run_device_evidence_with_non_physical_reality(self) -> None:
        self.write_json(
            "device-details.json",
            {
                "result": {
                    "identifier": "device-udid",
                    "properties": {
                        "hardware": {
                            "reality": "simulator",
                        },
                    },
                },
            },
        )

        with self.assertRaisesRegex(ValueError, "physical"):
            VERIFIER.verify_run(self.run_directory, None)

    def test_replays_legacy_regular_run_without_target(self) -> None:
        path = self.run_directory / "run-metadata.json"
        metadata = json.loads(path.read_text(encoding="utf-8"))
        metadata.pop("target")
        path.write_text(json.dumps(metadata), encoding="utf-8")

        _, result = VERIFIER.verify_run(self.run_directory, None)

        self.assertEqual(result["result"], "pass")

    def test_rejects_symlinked_regular_run_directory(self) -> None:
        run_alias = self.run_directory.parent / (
            self.run_directory.name + "-alias"
        )
        run_alias.symlink_to(self.run_directory, target_is_directory=True)

        try:
            with self.assertRaisesRegex(ValueError, "symlink"):
                VERIFIER.verify_run(run_alias, None)
        finally:
            run_alias.unlink()

    def test_rejects_regular_run_manifest_symlink(self) -> None:
        manifest_path = self.run_directory / "MemoMarkDeviceQA.json"
        manifest_copy = self.external_directory / manifest_path.name
        shutil.copy(manifest_path, manifest_copy)
        manifest_path.unlink()
        manifest_path.symlink_to(manifest_copy)

        with self.assertRaisesRegex(ValueError, "symlink"):
            VERIFIER.verify_run(self.run_directory, None)

    def test_rejects_regular_run_metadata_symlink(self) -> None:
        metadata_path = self.run_directory / "run-metadata.json"
        metadata_copy = self.external_directory / metadata_path.name
        shutil.copy(metadata_path, metadata_copy)
        metadata_path.unlink()
        metadata_path.symlink_to(metadata_copy)

        with self.assertRaisesRegex(ValueError, "symlink"):
            VERIFIER.verify_run(self.run_directory, None)

    def test_rejects_regular_run_optional_device_evidence_symlink(self) -> None:
        device_details_path = self.run_directory / "device-details.json"
        device_details_copy = self.external_directory / device_details_path.name
        shutil.copy(device_details_path, device_details_copy)
        device_details_path.unlink()
        device_details_path.symlink_to(device_details_copy)

        with self.assertRaisesRegex(ValueError, "symlink"):
            VERIFIER.verify_run(self.run_directory, None)

    def test_rejects_regular_run_result_bundle_symlink(self) -> None:
        result_bundle_path = self.run_directory / "MemoMarkDeviceQA.xcresult"
        result_bundle_copy = self.external_directory / result_bundle_path.name
        shutil.copytree(result_bundle_path, result_bundle_copy)
        shutil.rmtree(result_bundle_path)
        result_bundle_path.symlink_to(result_bundle_copy, target_is_directory=True)

        with self.assertRaisesRegex(ValueError, "symlink"):
            VERIFIER.verify_run(self.run_directory, None)

    def test_rejects_regular_run_result_bundle_info_plist_symlink(self) -> None:
        info_plist_path = (
            self.run_directory / "MemoMarkDeviceQA.xcresult" / "Info.plist"
        )
        info_plist_copy = self.external_directory / "Info.plist"
        shutil.copy(info_plist_path, info_plist_copy)
        info_plist_path.unlink()
        info_plist_path.symlink_to(info_plist_copy)

        with self.assertRaisesRegex(ValueError, "Info.plist"):
            VERIFIER.verify_run(self.run_directory, None)

    def test_rejects_directory_shaped_regular_run_manifest(self) -> None:
        manifest_path = self.run_directory / "MemoMarkDeviceQA.json"
        manifest_path.unlink()
        manifest_path.mkdir()

        with self.assertRaisesRegex(ValueError, "regular file"):
            VERIFIER.verify_run(self.run_directory, None)

    def test_rejects_unexpected_regular_run_file(self) -> None:
        (self.run_directory / "unexpected.txt").write_text(
            "undeclared evidence",
            encoding="utf-8",
        )

        with self.assertRaisesRegex(ValueError, "unexpected"):
            VERIFIER.verify_run(self.run_directory, None)

    def test_rejects_unexpected_regular_run_directory(self) -> None:
        (self.run_directory / "private-media").mkdir()

        with self.assertRaisesRegex(ValueError, "unexpected"):
            VERIFIER.verify_run(self.run_directory, None)

    def test_rejects_regular_run_manifest_with_partial_identity_fields(self) -> None:
        manifest_path = self.run_directory / "MemoMarkDeviceQA.json"
        manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
        manifest.pop("qaTarget")
        manifest_path.write_text(json.dumps(manifest), encoding="utf-8")

        with self.assertRaisesRegex(ValueError, "identity fields"):
            VERIFIER.verify_run(self.run_directory, None)

    def test_rejects_regular_run_manifest_with_empty_default_scheme(self) -> None:
        manifest_path = self.run_directory / "MemoMarkDeviceQA.json"
        manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
        manifest["defaultScheme"] = ""
        manifest_path.write_text(json.dumps(manifest), encoding="utf-8")

        with self.assertRaisesRegex(ValueError, "defaultScheme"):
            VERIFIER.verify_run(self.run_directory, None)


if __name__ == "__main__":
    unittest.main()

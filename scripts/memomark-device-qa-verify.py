#!/usr/bin/env python3

"""Verify MemoMark Device QA artifacts without touching a device.

The runner uses this module after xcodebuild to write the final run metadata.
The standalone ``verify`` command invokes the same logic in read-only mode so
an existing run directory can be audited again later.
"""

from __future__ import annotations

import argparse
import json
import os
import sys
import tempfile
from datetime import datetime, timezone
from pathlib import Path
from typing import Any


SIGNING_MARKERS = (
    "No profiles for",
    "No Accounts",
    "Signing requires a development team",
    "requires a provisioning profile",
)

SIGNING_FAILURE_CLASSES = frozenset(
    {
        "show-build-settings-failed",
        "codesigning-identity-query-failed",
        "development-identity-missing",
        "provisioning-profile-missing",
    }
)

MEMOMARK_PROJECT_PATH = (
    Path(__file__).resolve().parents[1]
    / "Source"
    / "PhotoMemo"
    / "PhotoMemo.xcodeproj"
)

EARLY_SIGNING_FORBIDDEN_ARTIFACTS = (
    "preflight.log",
    "device-details.json",
    "xcodebuild.log",
    "test-summary.json",
    "processes.json",
    "device-final.png",
    "capture.log",
    "xcresulttool.log",
    "MemoMarkDeviceQA.xcresult",
)

EARLY_SIGNING_ALLOWED_ARTIFACTS = frozenset(
    {
        "MemoMarkDeviceQA.json",
        "signing-status.json",
    }
)

REGULAR_RUN_REQUIRED_FILES = frozenset(
    {
        "MemoMarkDeviceQA.json",
        "run-metadata.json",
    }
)

REGULAR_RUN_OPTIONAL_FILES = frozenset(
    {
        "test-summary.json",
        "device-details.json",
        "signing-status.json",
        "xcodebuild.log",
        "preflight.log",
        "xcresulttool.log",
        "capture.log",
        "processes.json",
        "device-final.png",
        "MemoMarkDeviceQA.xcresult",
    }
)

REGULAR_RUN_ALLOWED_ARTIFACTS = (
    REGULAR_RUN_REQUIRED_FILES | REGULAR_RUN_OPTIONAL_FILES
)

REGULAR_RUN_METADATA_REQUIRED_STRING_FIELDS = (
    "runID",
    "device",
    "deviceIdentifier",
    "scheme",
    "configuration",
    "project",
)


def read_json(path: Path) -> dict[str, Any]:
    try:
        with path.open(encoding="utf-8") as file:
            value = json.load(file)
    except FileNotFoundError as error:
        raise ValueError(f"missing JSON artifact: {path.name}") from error
    except json.JSONDecodeError as error:
        raise ValueError(f"invalid JSON artifact: {path.name}") from error

    if not isinstance(value, dict):
        raise ValueError(f"JSON artifact must contain an object: {path.name}")
    return value


def read_optional_json(path: Path) -> dict[str, Any]:
    if not path.exists():
        return {}
    return read_json(path)


def validate_manifest(manifest: dict[str, Any]) -> None:
    if manifest.get("schemaVersion") != 1:
        raise ValueError("unsupported QA manifest schemaVersion")

    scenarios = manifest.get("scenarios")
    if not isinstance(scenarios, list):
        raise ValueError("QA manifest scenarios must be an array")

    if any(not isinstance(scenario, dict) for scenario in scenarios):
        raise ValueError("QA manifest scenarios must contain objects")

    scenario_ids = [scenario.get("id") for scenario in scenarios]
    expected_ids = [f"QA-{index:02d}" for index in range(1, 9)]
    if scenario_ids != expected_ids:
        raise ValueError("QA manifest scenarios must be QA-01 through QA-08")

    default_scheme = manifest.get("defaultScheme")
    if not isinstance(default_scheme, str) or not default_scheme:
        raise ValueError("QA manifest defaultScheme must be a non-empty string")

    qa_target = manifest.get("qaTarget")
    qa_runner_bundle_identifier = manifest.get("qaRunnerBundleIdentifier")
    if (qa_target is None) != (qa_runner_bundle_identifier is None):
        raise ValueError("QA manifest identity fields must be complete")
    if qa_target is not None and (
        not isinstance(qa_target, str) or not qa_target
    ):
        raise ValueError("QA manifest qaTarget must be a non-empty string")
    if qa_runner_bundle_identifier is not None and (
        not isinstance(qa_runner_bundle_identifier, str)
        or not qa_runner_bundle_identifier
    ):
        raise ValueError(
            "QA manifest qaRunnerBundleIdentifier must be a non-empty string"
        )

    result_policy = manifest.get("resultPolicy", {})
    if not isinstance(result_policy, dict):
        raise ValueError("QA manifest resultPolicy must be an object")
    if result_policy.get("resultBundle") != "required":
        raise ValueError("QA manifest must require an xcresult bundle")


def validate_regular_run_identity(
    metadata: dict[str, Any],
    manifest: dict[str, Any],
    device_details: dict[str, Any],
) -> None:
    if metadata.get("project") != "MemoMark":
        raise ValueError("run metadata project does not match MemoMark")

    expected_scheme = manifest.get("defaultScheme")
    if metadata.get("scheme") != expected_scheme:
        raise ValueError("run metadata scheme does not match QA manifest")

    expected_target = manifest.get("qaTarget")
    actual_target = metadata.get("target")
    if actual_target is not None:
        if not isinstance(actual_target, str) or not actual_target:
            raise ValueError("run metadata target is invalid")
        if actual_target != expected_target:
            raise ValueError("run metadata target does not match QA manifest")

    result = device_details.get("result", {})
    observed_identifier = (
        result.get("identifier")
        if isinstance(result, dict)
        else None
    )
    metadata_identifier = metadata.get("deviceIdentifier")
    if (
        isinstance(metadata_identifier, str)
        and metadata_identifier
        and isinstance(observed_identifier, str)
        and observed_identifier
        and metadata_identifier != observed_identifier
    ):
        raise ValueError(
            "run metadata device identifier does not match device evidence"
        )


def validate_regular_run_metadata(metadata: dict[str, Any]) -> None:
    if metadata.get("schemaVersion") != 1:
        raise ValueError("unsupported regular run metadata schemaVersion")

    for field_name in REGULAR_RUN_METADATA_REQUIRED_STRING_FIELDS:
        field_value = metadata.get(field_name)
        if not isinstance(field_value, str) or not field_value.strip():
            field_label = (
                "device identifier"
                if field_name == "deviceIdentifier"
                else field_name
            )
            raise ValueError(
                "regular run metadata requires non-empty " + field_label
            )


def validate_regular_run_summary(summary: dict[str, Any]) -> None:
    if not summary:
        return

    summary_result = summary.get("result")
    if summary_result not in {"Passed", "Failed", "unknown"}:
        raise ValueError("regular run test summary result is invalid")

    for field_name in ("failedTests", "totalTestCount"):
        field_value = summary.get(field_name)
        if not isinstance(field_value, int) or isinstance(field_value, bool):
            raise ValueError(
                "regular run test summary " + field_name + " must be an integer"
            )
        if field_value < 0:
            raise ValueError(
                "regular run test summary " + field_name + " must be non-negative"
            )


def validate_regular_run_device_evidence(
    device_details: dict[str, Any],
) -> None:
    if not device_details:
        return

    result = device_details.get("result")
    if not isinstance(result, dict):
        raise ValueError("regular run device evidence result is invalid")

    identifier = result.get("identifier")
    if not isinstance(identifier, str) or not identifier.strip():
        raise ValueError("regular run device evidence identifier is missing")

    properties = result.get("properties", {})
    if not isinstance(properties, dict):
        raise ValueError("regular run device evidence properties are invalid")
    hardware = properties.get("hardware", {})
    if not isinstance(hardware, dict):
        raise ValueError("regular run device evidence hardware is invalid")
    reality = hardware.get("reality")
    if reality is None:
        legacy_hardware = result.get("hardwareProperties", {})
        if isinstance(legacy_hardware, dict):
            reality = legacy_hardware.get("reality")
    if reality != "physical":
        raise ValueError(
            "regular run device evidence must identify a physical device"
        )


def validate_regular_run_shape(run_directory: Path) -> None:
    if run_directory.is_symlink():
        raise ValueError("regular run directory must not be a symlink")
    if not run_directory.is_dir():
        raise ValueError("regular run directory is invalid")

    unexpected_artifacts = sorted(
        path.name
        for path in run_directory.iterdir()
        if path.name not in REGULAR_RUN_ALLOWED_ARTIFACTS
    )
    if unexpected_artifacts:
        raise ValueError(
            "regular run contains unexpected files: "
            + ", ".join(unexpected_artifacts)
        )

    for artifact_name in REGULAR_RUN_REQUIRED_FILES:
        artifact_path = run_directory / artifact_name
        if artifact_path.is_symlink():
            raise ValueError(
                "regular run artifact must not contain symlinks: "
                + artifact_name
            )
        if not artifact_path.is_file():
            raise ValueError(
                "regular run artifact must contain regular file: "
                + artifact_name
            )

    for artifact_name in REGULAR_RUN_OPTIONAL_FILES:
        artifact_path = run_directory / artifact_name
        if artifact_path.is_symlink():
            raise ValueError(
                "regular run artifact must not contain symlinks: "
                + artifact_name
            )
        if not artifact_path.exists():
            continue
        if artifact_name == "MemoMarkDeviceQA.xcresult":
            if not artifact_path.is_dir():
                raise ValueError(
                    "regular run result bundle must be a directory"
                )
            info_plist = artifact_path / "Info.plist"
            if info_plist.is_symlink():
                raise ValueError(
                    "regular run result bundle Info.plist must not be a symlink"
                )
            if not info_plist.is_file():
                raise ValueError(
                    "regular run result bundle must contain regular Info.plist"
                )
        elif not artifact_path.is_file():
            raise ValueError(
                "regular run artifact must contain regular file: "
                + artifact_name
            )



def verify_early_signing_artifact(
    run_directory: Path,
) -> dict[str, Any]:
    if run_directory.is_symlink():
        raise ValueError(
            "early signing artifact run directory must not be a symlink"
        )
    if not run_directory.is_dir():
        raise ValueError("early signing artifact run directory is invalid")

    for artifact_name in EARLY_SIGNING_ALLOWED_ARTIFACTS:
        artifact_path = run_directory / artifact_name
        if artifact_path.is_symlink():
            raise ValueError(
                "early signing artifact must not contain symlinks: "
                + artifact_name
            )
        if not artifact_path.is_file():
            raise ValueError(
                "early signing artifact must contain regular file: "
                + artifact_name
            )

    manifest = read_json(run_directory / "MemoMarkDeviceQA.json")
    validate_manifest(manifest)
    signing_status = read_json(run_directory / "signing-status.json")

    for artifact_name in EARLY_SIGNING_FORBIDDEN_ARTIFACTS:
        if (run_directory / artifact_name).exists():
            raise ValueError(
                "early signing artifact contains device evidence: "
                + artifact_name
            )

    unexpected_artifacts = sorted(
        path.name
        for path in run_directory.iterdir()
        if path.name not in EARLY_SIGNING_ALLOWED_ARTIFACTS
    )
    if unexpected_artifacts:
        raise ValueError(
            "early signing artifact contains unexpected files: "
            + ", ".join(unexpected_artifacts)
        )

    if signing_status.get("schemaVersion") != 1:
        raise ValueError("unsupported signing-status schemaVersion")
    if signing_status.get("mode") != "read-only":
        raise ValueError("early signing artifact must be read-only")
    if signing_status.get("result") != "blocked":
        raise ValueError("early signing artifact must be blocked")

    failure_class = signing_status.get("failureClass")
    if failure_class not in SIGNING_FAILURE_CLASSES:
        raise ValueError(
            "early signing artifact has an unknown signing failure class"
        )

    target = signing_status.get("target")
    runner_bundle_identifier = signing_status.get("runnerBundleIdentifier")
    project = signing_status.get("project")
    scheme = signing_status.get("scheme")
    if not isinstance(target, str) or not target:
        raise ValueError("early signing artifact has no target")
    if not isinstance(runner_bundle_identifier, str) or not runner_bundle_identifier:
        raise ValueError(
            "early signing artifact has no runner bundle identifier"
        )
    if not isinstance(project, str) or not project:
        raise ValueError("early signing artifact has no project")
    if not isinstance(scheme, str) or not scheme:
        raise ValueError("early signing artifact has no scheme")
    try:
        project_matches = Path(project).resolve() == MEMOMARK_PROJECT_PATH.resolve()
    except OSError as error:
        raise ValueError("early signing artifact project is invalid") from error
    if not project_matches:
        raise ValueError("early signing artifact project does not match MemoMark")
    expected_scheme = manifest.get("defaultScheme")
    if scheme != expected_scheme:
        raise ValueError("early signing artifact scheme does not match QA manifest")
    expected_target = manifest.get("qaTarget")
    expected_runner_bundle_identifier = manifest.get(
        "qaRunnerBundleIdentifier"
    )
    if (expected_target is None) != (
        expected_runner_bundle_identifier is None
    ):
        raise ValueError("QA manifest identity fields must be complete")
    if expected_target is not None and target != expected_target:
        raise ValueError("early signing artifact target does not match QA manifest")
    if (
        expected_runner_bundle_identifier is not None
        and runner_bundle_identifier != expected_runner_bundle_identifier
    ):
        raise ValueError(
            "early signing artifact runner Bundle ID does not match QA manifest"
        )

    return {
        "signingStatusPresent": True,
        "deviceEvidencePresent": False,
        "manifestIdentityBound": expected_target is not None,
        "projectIdentityBound": True,
        "failureClass": failure_class,
        "result": "blocked",
    }


def is_physical_device(device_details: dict[str, Any]) -> bool:
    result = device_details.get("result", {})
    if not isinstance(result, dict):
        return False

    properties = result.get("properties", {})
    if not isinstance(properties, dict):
        properties = {}
    hardware = properties.get("hardware", {})
    if not isinstance(hardware, dict):
        hardware = {}

    reality = hardware.get("reality")
    if reality is None:
        legacy_hardware = result.get("hardwareProperties", {})
        if isinstance(legacy_hardware, dict):
            reality = legacy_hardware.get("reality")
    return reality == "physical"


def classify_result(
    *,
    metadata: dict[str, Any],
    summary: dict[str, Any],
    xcodebuild_log: str,
    result_bundle_present: bool,
    physical_device: bool,
    xcodebuild_status_override: int | None,
) -> dict[str, Any]:
    status = xcodebuild_status_override
    if status is None:
        stored_status = metadata.get("xcodebuildExitStatus")
        if not isinstance(stored_status, int) or isinstance(stored_status, bool):
            raise ValueError("run metadata has no integer xcodebuildExitStatus")
        status = stored_status

    summary_result = summary.get("result")
    summary_failed_tests = summary.get("failedTests")
    summary_total_tests = summary.get("totalTestCount")
    summary_passed = (
        summary_result == "Passed"
        and summary_failed_tests == 0
        and isinstance(summary_total_tests, int)
        and summary_total_tests > 0
    )
    run_passed = (
        status == 0
        and result_bundle_present
        and physical_device
        and summary_passed
    )

    failure_class: str | None = None
    if not run_passed:
        if not physical_device:
            failure_class = "device-target-invalid"
        elif any(marker in xcodebuild_log for marker in SIGNING_MARKERS):
            failure_class = "signing-blocked"
        elif summary_result == "Failed" or (
            isinstance(summary_failed_tests, int) and summary_failed_tests > 0
        ):
            failure_class = "test-failed"
        else:
            failure_class = "runner-failed"

    return {
        "xcodebuildExitStatus": status,
        "resultBundlePresent": result_bundle_present,
        "testSummaryPresent": bool(summary),
        "testSummaryResult": summary_result,
        "testSummaryFailedTests": summary_failed_tests,
        "testSummaryTotalTests": summary_total_tests,
        "failureClass": failure_class,
        "result": (
            "pass"
            if run_passed
            else "blocked"
            if failure_class == "signing-blocked"
            else "fail"
        ),
    }


def write_metadata(path: Path, metadata: dict[str, Any], result: dict[str, Any]) -> None:
    if path.is_symlink():
        raise ValueError("run metadata write target must not be a symlink")
    if not path.is_file():
        raise ValueError("run metadata write target must be a regular file")

    metadata.update(result)
    metadata["finishedAt"] = datetime.now(timezone.utc).isoformat()

    temporary_path: Path | None = None
    try:
        with tempfile.NamedTemporaryFile(
            mode="w",
            encoding="utf-8",
            dir=path.parent,
            prefix=f".{path.name}.",
            suffix=".tmp",
            delete=False,
        ) as file:
            temporary_path = Path(file.name)
            json.dump(metadata, file, ensure_ascii=False, indent=2)
            file.write("\n")
        os.replace(temporary_path, path)
    finally:
        if temporary_path is not None and temporary_path.exists():
            temporary_path.unlink()


def verify_run(
    run_directory: Path,
    status_override: int | None,
) -> tuple[dict[str, Any], dict[str, Any]]:
    validate_regular_run_shape(run_directory)

    metadata_path = run_directory / "run-metadata.json"
    manifest_path = run_directory / "MemoMarkDeviceQA.json"
    summary_path = run_directory / "test-summary.json"
    log_path = run_directory / "xcodebuild.log"
    device_details_path = run_directory / "device-details.json"
    result_bundle_path = run_directory / "MemoMarkDeviceQA.xcresult"

    metadata = read_json(metadata_path)
    validate_regular_run_metadata(metadata)
    manifest = read_json(manifest_path)
    validate_manifest(manifest)
    summary = read_optional_json(summary_path)
    device_details = read_optional_json(device_details_path)
    validate_regular_run_summary(summary)
    validate_regular_run_device_evidence(device_details)
    validate_regular_run_identity(metadata, manifest, device_details)

    try:
        xcodebuild_log = log_path.read_text(encoding="utf-8")
    except FileNotFoundError:
        xcodebuild_log = ""

    result_bundle_present = (
        result_bundle_path.is_dir()
        and (result_bundle_path / "Info.plist").is_file()
    )
    result = classify_result(
        metadata=metadata,
        summary=summary,
        xcodebuild_log=xcodebuild_log,
        result_bundle_present=result_bundle_present,
        physical_device=is_physical_device(device_details),
        xcodebuild_status_override=status_override,
    )
    return metadata, result


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Verify MemoMark Device QA artifacts without device access."
    )
    parser.add_argument("--run-dir", required=True, type=Path)
    parser.add_argument("--xcodebuild-exit-status", type=int)
    parser.add_argument("--write-metadata", action="store_true")
    arguments = parser.parse_args()

    early_signing_status_path = arguments.run_dir / "signing-status.json"
    metadata_path = arguments.run_dir / "run-metadata.json"
    if early_signing_status_path.is_file() and not metadata_path.exists():
        try:
            result = verify_early_signing_artifact(arguments.run_dir)
        except ValueError as error:
            print(
                f"Device QA artifact verification failed: {error}",
                file=sys.stderr,
            )
            return 1

        print(
            "Device QA evidence verified: "
            + str(result["result"])
            + " ("
            + str(result["failureClass"])
            + ")"
        )
        return 1

    try:
        metadata, result = verify_run(
            arguments.run_dir,
            arguments.xcodebuild_exit_status,
        )
    except ValueError as error:
        print(f"Device QA artifact verification failed: {error}", file=sys.stderr)
        return 1

    if arguments.write_metadata:
        write_metadata(
            arguments.run_dir / "run-metadata.json",
            metadata,
            result,
        )
    else:
        stored_values = {
            key: metadata.get(key)
            for key in result
            if key in metadata
        }
        if stored_values != result:
            print(
                "Device QA artifact verification failed: run metadata does not "
                "match the recomputed evidence",
                file=sys.stderr,
            )
            return 1

    print(
        "Device QA evidence verified: "
        + str(result["result"])
        + (" (" + str(result["failureClass"]) + ")" if result["failureClass"] else "")
    )
    return 0 if result["result"] == "pass" else 1


if __name__ == "__main__":
    raise SystemExit(main())

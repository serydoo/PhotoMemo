#!/usr/bin/env python3

"""Compose a machine-readable, read-only MemoMark Device QA readiness report.

This module does not invoke Xcode, CoreDevice, signing tools, or Photos. The
shell runner owns execution order; this module owns the small, deterministic
report contract that turns each gate into explicit evidence or an explicit
skip reason.
"""

from __future__ import annotations

import argparse
import json
import os
import sys
import tempfile
from datetime import datetime, timedelta, timezone
from pathlib import Path
from typing import Any


PASSING_STAGE_RESULTS = frozenset({"passed", "ready"})
KNOWN_STAGE_RESULTS = frozenset(
    {"passed", "ready", "failed", "blocked", "skipped"}
)
READINESS_GATE_NAMES = frozenset(
    {"manifest", "structuralBuild", "signing", "physicalDevice"}
)
READINESS_REQUIRED_ARTIFACTS = frozenset(
    {"MemoMarkDeviceQA.json", "readiness.json"}
)
READINESS_OPTIONAL_ARTIFACTS = frozenset(
    {
        "manifest-validation.log",
        "build-check.log",
        "build-check.json",
        "signing-output.log",
        "signing-status.json",
        "preflight-output.log",
        "preflight.log",
        "device-details.json",
    }
)
READINESS_ALLOWED_ARTIFACTS = (
    READINESS_REQUIRED_ARTIFACTS | READINESS_OPTIONAL_ARTIFACTS
)
FRESH_READINESS_ALLOWED_ARTIFACTS = frozenset({"MemoMarkDeviceQA.json"})
READINESS_OVERALL_RESULTS = frozenset({"ready", "blocked", "failed"})
MANIFEST_GATE_RESULTS = frozenset({"passed", "failed"})
BUILD_GATE_RESULTS = frozenset({"passed", "failed", "skipped"})
SIGNING_GATE_RESULTS = frozenset({"ready", "blocked", "failed", "skipped"})
PHYSICAL_DEVICE_GATE_RESULTS = frozenset(
    {"passed", "failed", "skipped"}
)


def result_exit_status(result: str) -> int:
    if not isinstance(result, str) or result not in READINESS_OVERALL_RESULTS:
        raise ValueError("readiness result is invalid")
    return 0 if result == "ready" else 1


def classify_preflight_failure(log_path: Path, device: str) -> str:
    """Classify known CoreDevice failures without treating them as app failures."""

    if not log_path.is_file() or log_path.is_symlink():
        return "physical-device-preflight-failed"
    text = log_path.read_text(encoding="utf-8", errors="replace")
    lowered = text.lower()
    if "coredeviceerror error 4016" in lowered or (
        "usage assertion" in lowered
        and "requesteddevicestates" in lowered
    ):
        return "coredevice-usage-assertion-failed"
    device_lines = [
        line.lower()
        for line in text.splitlines()
        if device.lower() in line.lower()
    ]
    if any("unavailable" in line for line in device_lines):
        return "device-unavailable"
    return "physical-device-preflight-failed"


def validate_build_check_receipt(
    receipt: dict[str, Any],
    manifest: dict[str, Any],
    scheme: str,
    target: str,
    configuration: str,
    run_id: str,
) -> bool:
    if receipt.get("schemaVersion") != 1:
        raise ValueError("build-check receipt schemaVersion is invalid")
    if receipt.get("kind") != "MemoMarkDeviceQABuildCheck":
        raise ValueError("build-check receipt kind is invalid")
    if receipt.get("mode") != "unsigned-structural":
        raise ValueError("build-check receipt mode is invalid")
    if receipt.get("project") != "MemoMark":
        raise ValueError("build-check receipt project is invalid")
    if receipt.get("scheme") != scheme:
        raise ValueError("build-check receipt scheme does not match")
    if receipt.get("target") != target:
        raise ValueError("build-check receipt target does not match")
    if receipt.get("configuration") != configuration:
        raise ValueError("build-check receipt configuration does not match")
    if not isinstance(run_id, str) or not run_id:
        raise ValueError("build-check run ID is invalid")
    if receipt.get("runID") != run_id:
        raise ValueError("build-check receipt run ID does not match")
    if receipt.get("result") != "passed":
        raise ValueError("build-check receipt result is invalid")

    expected_host = manifest.get("appBundleIdentifier")
    expected_host_product = manifest.get("qaHostProduct")
    expected_runner = manifest.get("qaRunnerBundleIdentifier")
    if not isinstance(expected_host, str) or not expected_host:
        raise ValueError("build-check manifest host Bundle ID is missing")
    if not isinstance(expected_runner, str) or not expected_runner:
        raise ValueError("build-check manifest runner Bundle ID is missing")
    if not isinstance(expected_host_product, str) or not expected_host_product:
        raise ValueError("build-check manifest host product is missing")
    expected_test = expected_runner.removesuffix(".xctrunner")

    if receipt.get("hostBundleIdentifier") != expected_host:
        raise ValueError("build-check host Bundle ID does not match")
    if receipt.get("hostProduct") != expected_host_product:
        raise ValueError("build-check host product does not match")
    if receipt.get("runnerBundleIdentifier") != expected_runner:
        raise ValueError("build-check runner Bundle ID does not match")
    if receipt.get("testBundleIdentifier") != expected_test:
        raise ValueError("build-check test Bundle ID does not match")
    if receipt.get("runnerProduct") != f"{target}-Runner.app":
        raise ValueError("build-check runner product does not match")
    if receipt.get("testBundleProduct") != f"{target}.xctest":
        raise ValueError("build-check test bundle product does not match")
    return True


def _validate_stage_result(value: str, label: str) -> str:
    if not isinstance(value, str) or value not in KNOWN_STAGE_RESULTS:
        raise ValueError(f"{label} has an invalid result: {value}")
    return value


def _validate_gate_result(
    value: str,
    label: str,
    allowed_results: frozenset[str],
) -> str:
    result = _validate_stage_result(value, label)
    if result not in allowed_results:
        raise ValueError(f"{label} result is invalid: {result}")
    return result


def _overall_result(gates: dict[str, dict[str, Any]]) -> str:
    results = [gate["result"] for gate in gates.values()]
    if any(result == "failed" for result in results):
        return "failed"
    if all(result in PASSING_STAGE_RESULTS for result in results):
        return "ready"
    return "blocked"


def _compact_device_details(
    device_details: dict[str, Any] | None,
    fallback_identifier: str | None,
) -> dict[str, Any]:
    if not device_details:
        return {
            "identifier": fallback_identifier,
            "reality": None,
        }

    result = device_details.get("result", {})
    if not isinstance(result, dict):
        return {
            "identifier": fallback_identifier,
            "reality": None,
        }

    properties = result.get("properties", {})
    hardware = properties.get("hardware", {}) if isinstance(properties, dict) else {}
    reality = hardware.get("reality") if isinstance(hardware, dict) else None
    if reality is None:
        legacy_hardware = result.get("hardwareProperties", {})
        if isinstance(legacy_hardware, dict):
            reality = legacy_hardware.get("reality")

    identifier = result.get("identifier")
    if not isinstance(identifier, str) or not identifier.strip():
        identifier = fallback_identifier

    return {
        "identifier": identifier,
        "reality": reality,
    }


def compose_report(
    *,
    manifest: dict[str, Any],
    run_id: str,
    device: str,
    device_identifier: str | None,
    scheme: str,
    target: str,
    configuration: str,
    manifest_result: str,
    build_result: str,
    build_log: str | None,
    signing: dict[str, Any] | None,
    physical_device_result: str,
    physical_device_reason: str | None,
    physical_device_details: dict[str, Any] | None,
) -> dict[str, Any]:
    manifest_result = _validate_gate_result(
        manifest_result,
        "manifest",
        MANIFEST_GATE_RESULTS,
    )
    build_result = _validate_gate_result(
        build_result,
        "structural build",
        BUILD_GATE_RESULTS,
    )
    physical_device_result = _validate_gate_result(
        physical_device_result,
        "physical device",
        PHYSICAL_DEVICE_GATE_RESULTS,
    )

    scenario_count = manifest.get("scenarios")
    if not isinstance(scenario_count, list):
        scenario_count = []

    manifest_gate: dict[str, Any] = {
        "result": manifest_result,
        "artifact": "MemoMarkDeviceQA.json",
        "schemaVersion": manifest.get("schemaVersion"),
        "scenarioCount": len(scenario_count),
    }

    build_gate: dict[str, Any] = {
        "result": build_result,
        "mode": "unsigned-structural",
    }
    if build_log:
        build_gate["log"] = build_log

    if signing is None:
        signing_gate: dict[str, Any] = {
            "result": "skipped",
            "reason": "manifest-invalid",
        }
    else:
        signing_gate = dict(signing)
        signing_result = signing_gate.get("result")
        if signing_result not in {"ready", "blocked"}:
            signing_gate["result"] = "failed"
            signing_gate["failureClass"] = "invalid-signing-diagnostic"

    compact_device = _compact_device_details(
        physical_device_details,
        device_identifier,
    )
    if physical_device_result == "passed" and (
        not compact_device.get("identifier")
        or compact_device.get("reality") != "physical"
    ):
        physical_device_result = "failed"
        physical_device_reason = "physical-device-evidence-invalid"

    physical_gate: dict[str, Any] = {
        "result": physical_device_result,
        "device": device,
    }
    if physical_device_reason:
        physical_gate["reason"] = physical_device_reason
    if physical_device_result == "passed":
        physical_gate.update(compact_device)

    gates = {
        "manifest": manifest_gate,
        "structuralBuild": build_gate,
        "signing": signing_gate,
        "physicalDevice": physical_gate,
    }

    return {
        "schemaVersion": 1,
        "kind": "MemoMarkDeviceQAReadiness",
        "mode": "read-only",
        "runID": run_id,
        "generatedAt": datetime.now(timezone.utc).isoformat(),
        "project": "MemoMark",
        "device": device,
        "deviceIdentifier": device_identifier or None,
        "scheme": scheme,
        "target": target,
        "configuration": configuration,
        "overallResult": _overall_result(gates),
        "gates": gates,
    }


def _read_json(path: Path) -> dict[str, Any]:
    if path.is_symlink() or not path.is_file():
        raise ValueError(f"readiness input must be a regular file: {path}")
    try:
        with path.open(encoding="utf-8") as file:
            payload = json.load(file)
    except json.JSONDecodeError as error:
        raise ValueError(f"invalid readiness JSON: {path}") from error
    if not isinstance(payload, dict):
        raise ValueError(f"readiness JSON must contain an object: {path}")
    return payload


def _read_manifest(path: Path) -> dict[str, Any]:
    try:
        return _read_json(path)
    except ValueError:
        # The report must still explain that the manifest gate failed. The
        # shell runner records the detailed validation output separately.
        return {}


def write_report(output: Path, report: dict[str, Any]) -> None:
    if output.is_symlink():
        raise ValueError("readiness report output must not be a symlink")
    output.parent.mkdir(parents=True, exist_ok=True)
    temporary_path: Path | None = None
    try:
        descriptor, temporary_name = tempfile.mkstemp(
            prefix=f".{output.name}.",
            suffix=".tmp",
            dir=output.parent,
        )
        temporary_path = Path(temporary_name)
        with os.fdopen(descriptor, "w", encoding="utf-8") as file:
            json.dump(report, file, ensure_ascii=False, indent=2)
            file.write("\n")
        os.replace(temporary_path, output)
        temporary_path = None
    finally:
        if temporary_path is not None:
            temporary_path.unlink(missing_ok=True)


def assert_fresh_run_directory(run_directory: Path) -> None:
    """Reject reuse that could mix old evidence into a new Device QA run."""

    if run_directory.is_symlink():
        raise ValueError("fresh device QA run directory must not be a symlink")
    if not run_directory.is_dir():
        raise ValueError("fresh device QA run directory is invalid")

    unexpected_artifacts = sorted(
        path.name
        for path in run_directory.iterdir()
        if path.name not in FRESH_READINESS_ALLOWED_ARTIFACTS
    )
    if unexpected_artifacts:
        raise ValueError(
            "device QA run directory is not fresh; use a new run ID instead of "
            + ", ".join(unexpected_artifacts)
        )

    manifest_path = run_directory / "MemoMarkDeviceQA.json"
    if manifest_path.exists() or manifest_path.is_symlink():
        if manifest_path.is_symlink() or not manifest_path.is_file():
            raise ValueError(
                "fresh device QA manifest must be a regular file"
            )


def _require_non_empty_string(
    payload: dict[str, Any],
    field_name: str,
    label: str,
) -> str:
    value = payload.get(field_name)
    if not isinstance(value, str) or not value.strip():
        raise ValueError(f"readiness {label} must be a non-empty string")
    return value


def verify_report(path: Path) -> dict[str, Any]:
    """Replay a readiness report without invoking any external tool."""

    report = _read_json(path)
    if report.get("schemaVersion") != 1:
        raise ValueError("unsupported readiness schemaVersion")
    if report.get("kind") != "MemoMarkDeviceQAReadiness":
        raise ValueError("readiness kind is invalid")
    if report.get("mode") != "read-only":
        raise ValueError("readiness report must be read-only")
    if report.get("project") != "MemoMark":
        raise ValueError("readiness project is invalid")

    for field_name in (
        "runID",
        "device",
        "scheme",
        "target",
        "configuration",
    ):
        _require_non_empty_string(report, field_name, field_name)

    generated_at = _require_non_empty_string(
        report,
        "generatedAt",
        "generatedAt",
    )
    try:
        generated_at_date = datetime.fromisoformat(generated_at)
    except ValueError as error:
        raise ValueError("readiness generatedAt is not ISO-8601") from error
    if generated_at_date.tzinfo is None:
        raise ValueError("readiness generatedAt must include a timezone")
    if generated_at_date.astimezone(timezone.utc) > (
        datetime.now(timezone.utc) + timedelta(minutes=5)
    ):
        raise ValueError("readiness generatedAt is in the future")

    device_identifier = report.get("deviceIdentifier")
    if device_identifier is not None and (
        not isinstance(device_identifier, str) or not device_identifier.strip()
    ):
        raise ValueError("readiness deviceIdentifier is invalid")

    gates = report.get("gates")
    if not isinstance(gates, dict) or set(gates) != READINESS_GATE_NAMES:
        raise ValueError("readiness gate names are invalid")

    manifest_gate = gates["manifest"]
    if not isinstance(manifest_gate, dict):
        raise ValueError("readiness manifest gate is invalid")
    manifest_result = _validate_gate_result(
        manifest_gate.get("result"),
        "manifest",
        MANIFEST_GATE_RESULTS,
    )
    if manifest_result == "passed":
        if manifest_gate.get("schemaVersion") != 1:
            raise ValueError("readiness manifest schemaVersion is invalid")
        if manifest_gate.get("scenarioCount") != 8:
            raise ValueError("readiness manifest scenarioCount is invalid")

    build_gate = gates["structuralBuild"]
    if not isinstance(build_gate, dict):
        raise ValueError("readiness structural build gate is invalid")
    build_result = _validate_gate_result(
        build_gate.get("result"),
        "structural build",
        BUILD_GATE_RESULTS,
    )
    if build_gate.get("mode") != "unsigned-structural":
        raise ValueError("readiness structural build mode is invalid")
    if build_result == "passed":
        _require_non_empty_string(build_gate, "log", "structural build log")

    signing_gate = gates["signing"]
    if not isinstance(signing_gate, dict):
        raise ValueError("readiness signing gate is invalid")
    signing_result = _validate_gate_result(
        signing_gate.get("result"),
        "signing",
        SIGNING_GATE_RESULTS,
    )
    if signing_result != "skipped":
        if signing_gate.get("mode") != "read-only":
            raise ValueError("readiness signing mode is invalid")
        if signing_gate.get("scheme") != report["scheme"]:
            raise ValueError("readiness signing scheme does not match")
        if signing_gate.get("target") != report["target"]:
            raise ValueError("readiness signing target does not match")
    if signing_result == "blocked":
        _require_non_empty_string(
            signing_gate,
            "failureClass",
            "signing failureClass",
        )

    physical_gate = gates["physicalDevice"]
    if not isinstance(physical_gate, dict):
        raise ValueError("readiness physical device gate is invalid")
    physical_result = _validate_gate_result(
        physical_gate.get("result"),
        "physical device",
        PHYSICAL_DEVICE_GATE_RESULTS,
    )
    if physical_gate.get("device") != report["device"]:
        raise ValueError("readiness physical device name does not match")
    if physical_result == "passed":
        identifier = _require_non_empty_string(
            physical_gate,
            "identifier",
            "physical device identifier",
        )
        if physical_gate.get("reality") != "physical":
            raise ValueError("readiness physical device reality is invalid")
        if device_identifier != identifier:
            raise ValueError(
                "readiness physical device identifier does not match"
            )
    elif physical_result in {"failed", "skipped"}:
        _require_non_empty_string(
            physical_gate,
            "reason",
            "physical device reason",
        )

    expected_overall = _overall_result(gates)
    if report.get("overallResult") != expected_overall:
        raise ValueError("readiness overallResult does not match its gates")

    return report


def verify_run_directory(run_directory: Path) -> dict[str, Any]:
    """Replay a readiness directory and reject undeclared evidence."""

    if run_directory.is_symlink():
        raise ValueError("readiness run directory must not be a symlink")
    if not run_directory.is_dir():
        raise ValueError("readiness run directory is invalid")

    unexpected_artifacts = sorted(
        path.name
        for path in run_directory.iterdir()
        if path.name not in READINESS_ALLOWED_ARTIFACTS
    )
    if unexpected_artifacts:
        raise ValueError(
            "readiness run contains unexpected files: "
            + ", ".join(unexpected_artifacts)
        )

    for artifact_name in READINESS_REQUIRED_ARTIFACTS:
        artifact_path = run_directory / artifact_name
        if artifact_path.is_symlink() or not artifact_path.is_file():
            raise ValueError(
                "readiness required artifact must be a regular file: "
                + artifact_name
            )
    for artifact_name in READINESS_OPTIONAL_ARTIFACTS:
        artifact_path = run_directory / artifact_name
        if artifact_path.is_symlink():
            raise ValueError(
                "readiness optional artifact must not be a symlink: "
                + artifact_name
            )
        if artifact_path.exists() and not artifact_path.is_file():
            raise ValueError(
                "readiness optional artifact must be a regular file: "
                + artifact_name
            )

    manifest = _read_json(run_directory / "MemoMarkDeviceQA.json")
    report = verify_report(run_directory / "readiness.json")
    if manifest.get("schemaVersion") != 1:
        raise ValueError("readiness manifest schemaVersion is invalid")
    expected_scenario_ids = [
        f"QA-{index:02d}" for index in range(1, 9)
    ]
    scenarios = manifest.get("scenarios")
    if (
        not isinstance(scenarios, list)
        or any(not isinstance(scenario, dict) for scenario in scenarios)
        or [scenario.get("id") for scenario in scenarios]
        != expected_scenario_ids
    ):
        raise ValueError("readiness manifest scenarios are invalid")
    if manifest.get("defaultScheme") != report["scheme"]:
        raise ValueError("readiness manifest scheme does not match")
    if manifest.get("qaTarget") != report["target"]:
        raise ValueError("readiness manifest target does not match")

    gates = report["gates"]
    signing_status_path = run_directory / "signing-status.json"
    if gates["manifest"]["result"] == "passed":
        if not signing_status_path.is_file():
            raise ValueError("readiness signing-status.json is missing")
    if signing_status_path.exists():
        signing_status = _read_json(signing_status_path)
        if signing_status != gates["signing"]:
            raise ValueError("readiness signing status does not match report")

    build_result = gates["structuralBuild"]["result"]
    build_log_path = run_directory / "build-check.log"
    if build_result in {"passed", "failed"} and not build_log_path.is_file():
        raise ValueError("readiness build-check.log is missing")
    build_receipt_path = run_directory / "build-check.json"
    if build_result == "passed":
        if build_receipt_path.is_symlink() or not build_receipt_path.is_file():
            raise ValueError("readiness build-check.json is missing")
        validate_build_check_receipt(
            _read_json(build_receipt_path),
            manifest,
            report["scheme"],
            report["target"],
            report["configuration"],
            report["runID"],
        )
    elif build_receipt_path.exists():
        raise ValueError("readiness contains a build receipt for a failed build")

    device_details_path = run_directory / "device-details.json"
    physical_result = gates["physicalDevice"]["result"]
    if physical_result == "passed":
        if not device_details_path.is_file():
            raise ValueError("readiness device-details.json is missing")
        device_details = _read_json(device_details_path)
        compact_device = _compact_device_details(
            device_details,
            report["deviceIdentifier"],
        )
        physical_gate = gates["physicalDevice"]
        if (
            compact_device.get("identifier") != physical_gate.get("identifier")
            or compact_device.get("reality") != physical_gate.get("reality")
        ):
            raise ValueError(
                "readiness physical device evidence does not match report"
            )
    elif device_details_path.exists():
        raise ValueError("readiness contains physical device evidence")

    return report


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Compose a read-only MemoMark Device QA readiness report."
    )
    parser.add_argument("--verify", type=Path, default=None)
    parser.add_argument("--check-fresh", type=Path, default=None)
    parser.add_argument(
        "--classify-preflight-failure",
        action="store_true",
    )
    parser.add_argument("--preflight-log", type=Path, default=None)
    parser.add_argument("--device-name", default=None)
    parser.add_argument("--manifest", type=Path, default=None)
    parser.add_argument("--output", type=Path, default=None)
    parser.add_argument("--run-id", default=None)
    parser.add_argument("--device", default=None)
    parser.add_argument("--device-identifier", default=None)
    parser.add_argument("--scheme", default=None)
    parser.add_argument("--target", default=None)
    parser.add_argument("--configuration", default=None)
    parser.add_argument("--manifest-result", default=None)
    parser.add_argument("--build-result", default=None)
    parser.add_argument("--build-log", default=None)
    parser.add_argument("--signing-status", type=Path, default=None)
    parser.add_argument("--physical-device-result", default=None)
    parser.add_argument("--physical-device-reason", default=None)
    parser.add_argument("--device-details", type=Path, default=None)
    arguments = parser.parse_args()

    if arguments.check_fresh is not None:
        assert_fresh_run_directory(arguments.check_fresh)
        return 0

    if arguments.classify_preflight_failure:
        if arguments.preflight_log is None or arguments.device_name is None:
            parser.error(
                "--classify-preflight-failure requires "
                "--preflight-log and --device-name"
            )
        print(
            classify_preflight_failure(
                arguments.preflight_log,
                arguments.device_name,
            )
        )
        return 0

    if arguments.verify is not None:
        report = (
            verify_run_directory(arguments.verify)
            if arguments.verify.is_dir()
            else verify_report(arguments.verify)
        )
        print(json.dumps(report, ensure_ascii=False, indent=2))
        return result_exit_status(report["overallResult"])

    required_arguments = {
        "--manifest": arguments.manifest,
        "--output": arguments.output,
        "--run-id": arguments.run_id,
        "--device": arguments.device,
        "--scheme": arguments.scheme,
        "--target": arguments.target,
        "--configuration": arguments.configuration,
        "--manifest-result": arguments.manifest_result,
        "--build-result": arguments.build_result,
        "--physical-device-result": arguments.physical_device_result,
    }
    missing_arguments = [
        name for name, value in required_arguments.items() if value is None
    ]
    if missing_arguments:
        parser.error("missing arguments: " + ", ".join(missing_arguments))

    signing = (
        _read_json(arguments.signing_status)
        if arguments.signing_status is not None
        and arguments.signing_status.exists()
        else None
    )
    device_details = (
        _read_json(arguments.device_details)
        if arguments.device_details is not None
        and arguments.device_details.exists()
        else None
    )
    report = compose_report(
        manifest=_read_manifest(arguments.manifest),
        run_id=arguments.run_id,
        device=arguments.device,
        device_identifier=arguments.device_identifier,
        scheme=arguments.scheme,
        target=arguments.target,
        configuration=arguments.configuration,
        manifest_result=arguments.manifest_result,
        build_result=arguments.build_result,
        build_log=arguments.build_log,
        signing=signing,
        physical_device_result=arguments.physical_device_result,
        physical_device_reason=arguments.physical_device_reason,
        physical_device_details=device_details,
    )
    write_report(arguments.output, report)
    print(json.dumps(report, ensure_ascii=False, indent=2))
    return result_exit_status(report["overallResult"])


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except ValueError as error:
        print(f"MemoMark Device QA readiness error: {error}", file=sys.stderr)
        raise SystemExit(2) from error

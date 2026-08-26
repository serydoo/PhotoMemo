#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
PROJECT_PATH="${REPO_ROOT}/Source/MemoMark/MemoMark.xcodeproj"
MANIFEST_PATH="${REPO_ROOT}/QA/MemoMarkDeviceQA.json"
VERIFIER_PATH="${REPO_ROOT}/scripts/memomark-device-qa-verify.py"
SIGNING_DIAGNOSTIC_PATH="${REPO_ROOT}/scripts/memomark-device-qa-signing.py"
READINESS_REPORT_PATH="${REPO_ROOT}/scripts/memomark-device-qa-readiness.py"

DEVICE="${MEMOMARK_DEVICE_QA_DEVICE:-iPhone7}"
SCHEME="${MEMOMARK_DEVICE_QA_SCHEME:-MemoMarkDeviceQA}"
TARGET="${MEMOMARK_DEVICE_QA_TARGET:-MemoMarkDeviceQA}"
CONFIGURATION="${MEMOMARK_DEVICE_QA_CONFIGURATION:-Debug}"
RESULTS_ROOT="${MEMOMARK_DEVICE_QA_RESULTS:-/tmp/MemoMarkDeviceQA}"
DERIVED_DATA_ROOT="${MEMOMARK_DEVICE_QA_DERIVED_DATA:-/tmp/MemoMarkDeviceQADerivedData}"
RUN_ID="$(date -u +%Y%m%dT%H%M%SZ)"
SKIP_SCREENSHOT="NO"
PROCESS_ID=""
DEVICE_IDENTIFIER=""
ALLOW_PROVISIONING_UPDATES="NO"
RUN_DIRECTORY_OVERRIDE=""
JSON_OUTPUT="NO"

usage() {
    cat <<'USAGE'
Usage:
  scripts/memomark-device-qa.sh preflight [options]
  scripts/memomark-device-qa.sh validate [options]
  scripts/memomark-device-qa.sh build-check [options]
  scripts/memomark-device-qa.sh readiness [options]
  scripts/memomark-device-qa.sh verify --run-dir <directory>
  scripts/memomark-device-qa.sh verify-readiness --run-dir <directory>
  scripts/memomark-device-qa.sh signing-status [options]
  scripts/memomark-device-qa.sh run [options]
  scripts/memomark-device-qa.sh capture [options]
  scripts/memomark-device-qa.sh processes [options]
  scripts/memomark-device-qa.sh memory-warning --pid <pid> [options]
  scripts/memomark-device-qa.sh terminate --pid <pid> [options]

Options:
  --device <name-or-udid>  Physical device name or identifier. Default: iPhone7
  --scheme <scheme>        Test scheme. Default: MemoMarkDeviceQA
  --target <target>        QA UI test target. Default: MemoMarkDeviceQA
  --results <directory>    Local result root. Default: /tmp/MemoMarkDeviceQA
  --derived-data <dir>     DerivedData root. Default: /tmp/MemoMarkDeviceQADerivedData
  --run-dir <directory>    Existing run directory for the verify command.
  --json                   Emit machine-readable JSON for signing-status.
  --run-id <id>            Stable run identifier for orchestration.
  --skip-screenshot        Do not request a final device screenshot.
  --allow-provisioning-updates
                           Allow Xcode to create or refresh development
                           profiles through the configured Apple account.
  --pid <pid>              Optional device process ID override. If omitted,
                           MemoMark's app process is discovered automatically.
  -h, --help               Show this help.
USAGE
}

COMMAND="${1:-run}"
if [[ $# -gt 0 ]]; then
    shift
fi

if [[ "${COMMAND}" == "-h" || "${COMMAND}" == "--help" ]]; then
    usage
    exit 0
fi

while [[ $# -gt 0 ]]; do
    case "$1" in
        --device)
            DEVICE="$2"
            shift 2
            ;;
        --scheme)
            SCHEME="$2"
            shift 2
            ;;
        --target)
            TARGET="$2"
            shift 2
            ;;
        --results)
            RESULTS_ROOT="$2"
            shift 2
            ;;
        --derived-data)
            DERIVED_DATA_ROOT="$2"
            shift 2
            ;;
        --run-dir)
            RUN_DIRECTORY_OVERRIDE="$2"
            shift 2
            ;;
        --json)
            JSON_OUTPUT="YES"
            shift
            ;;
        --run-id)
            RUN_ID="$2"
            shift 2
            ;;
        --skip-screenshot)
            SKIP_SCREENSHOT="YES"
            shift
            ;;
        --allow-provisioning-updates)
            ALLOW_PROVISIONING_UPDATES="YES"
            shift
            ;;
        --pid)
            PROCESS_ID="$2"
            shift 2
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            echo "Unknown option: $1" >&2
            usage >&2
            exit 2
            ;;
    esac
done

if [[ "${COMMAND}" == "verify" || "${COMMAND}" == "verify-readiness" ]]; then
    if [[ -z "${RUN_DIRECTORY_OVERRIDE}" ]]; then
        echo "${COMMAND} requires --run-dir <directory>" >&2
        usage >&2
        exit 2
    fi
    RUN_DIRECTORY="${RUN_DIRECTORY_OVERRIDE}"
else
    RUN_DIRECTORY="${RESULTS_ROOT}/${RUN_ID}"
fi

RESULT_BUNDLE="${RUN_DIRECTORY}/MemoMarkDeviceQA.xcresult"
XCODEBUILD_LOG="${RUN_DIRECTORY}/xcodebuild.log"
PREFLIGHT_LOG="${RUN_DIRECTORY}/preflight.log"
SCREENSHOT_PATH="${RUN_DIRECTORY}/device-final.png"
DEVICE_DETAILS_JSON="${RUN_DIRECTORY}/device-details.json"
TEST_SUMMARY_JSON="${RUN_DIRECTORY}/test-summary.json"
PROCESS_DETAILS_JSON="${RUN_DIRECTORY}/processes.json"
SIGNING_STATUS_JSON="${RUN_DIRECTORY}/signing-status.json"
READINESS_JSON="${RUN_DIRECTORY}/readiness.json"
BUILD_CHECK_ROOT="${DERIVED_DATA_ROOT}/build-check"
BUILD_CHECK_RECEIPT="${BUILD_CHECK_ROOT}/build-check.json"

if [[ "${COMMAND}" != "verify" && "${COMMAND}" != "verify-readiness" ]]; then
    mkdir -p "${RUN_DIRECTORY}"
    if [[ "${COMMAND}" == "readiness" || "${COMMAND}" == "run" ]]; then
        python3 "${READINESS_REPORT_PATH}" \
            --check-fresh "${RUN_DIRECTORY}"
    fi
    cp "${MANIFEST_PATH}" "${RUN_DIRECTORY}/MemoMarkDeviceQA.json"
fi

write_metadata() {
    python3 "-" "${RUN_DIRECTORY}/run-metadata.json" "${RUN_ID}" "${DEVICE}" "${DEVICE_IDENTIFIER}" "${SCHEME}" "${CONFIGURATION}" "${ALLOW_PROVISIONING_UPDATES}" "${TARGET}" <<'PY'
import json
import platform
import subprocess
import sys
from datetime import datetime, timezone

output_path, run_id, device, device_identifier, scheme, configuration, allow_provisioning_updates, target = sys.argv[1:]

def command_output(*command):
    try:
        return subprocess.check_output(command, text=True, stderr=subprocess.STDOUT).strip()
    except Exception as error:
        return f"unavailable: {error}"

metadata = {
    "schemaVersion": 1,
    "runID": run_id,
    "startedAt": datetime.now(timezone.utc).isoformat(),
    "device": device,
    "deviceIdentifier": device_identifier,
    "scheme": scheme,
    "target": target,
    "configuration": configuration,
    "allowProvisioningUpdates": allow_provisioning_updates == "YES",
    "project": "MemoMark",
    "host": platform.node(),
    "xcode": command_output("xcodebuild", "-version"),
    "xcodeSelect": command_output("xcode-select", "-p"),
}

with open(output_path, "w", encoding="utf-8") as file:
    json.dump(metadata, file, ensure_ascii=False, indent=2)
    file.write("\n")
PY
}

resolve_device_identifier() {
    DEVICE_IDENTIFIER="$(python3 "-" "${DEVICE_DETAILS_JSON}" <<'PY'
import json
import sys

with open(sys.argv[1], encoding="utf-8") as file:
    payload = json.load(file)

identifier = payload.get("result", {}).get("identifier")
if not isinstance(identifier, str) or not identifier.strip():
    raise SystemExit("Device details did not contain a CoreDevice identifier")

print(identifier.strip())
PY
)"

    if [[ -z "${DEVICE_IDENTIFIER}" ]]; then
        echo "Unable to resolve a physical device identifier: ${DEVICE}" >&2
        return 1
    fi

}

validate_physical_device() {
    python3 "-" "${DEVICE_DETAILS_JSON}" <<'PY'
import json
import sys

with open(sys.argv[1], encoding="utf-8") as file:
    payload = json.load(file)

result = payload.get("result", {})
properties = result.get("properties", {})
hardware = properties.get("hardware", {})
reality = hardware.get("reality")
if reality is None:
    reality = result.get("hardwareProperties", {}).get("reality")

if reality != "physical":
    raise SystemExit(
        "Physical device required; detected reality: " + str(reality)
    )

print("Physical device confirmed")
PY
}

validate_manifest() {
    python3 "-" "${MANIFEST_PATH}" <<'PY'
import json
import sys

manifest_path = sys.argv[1]
with open(manifest_path, encoding="utf-8") as file:
    manifest = json.load(file)

required = {
    "schemaVersion",
    "name",
    "appBundleIdentifier",
    "shareExtensionBundleIdentifier",
    "appGroupIdentifier",
    "defaultDeviceName",
    "defaultScheme",
    "qaTarget",
    "qaHostProduct",
    "qaRunnerBundleIdentifier",
    "inputPolicy",
    "resultPolicy",
    "scenarios",
}
missing = sorted(required.difference(manifest))
if missing:
    raise SystemExit("QA manifest is missing: " + ", ".join(missing))

if manifest["schemaVersion"] != 1:
    raise SystemExit("Unsupported QA manifest schemaVersion")
if not isinstance(manifest["qaTarget"], str) or not manifest["qaTarget"]:
    raise SystemExit("QA manifest qaTarget must be a non-empty string")
if (
    not isinstance(manifest["qaRunnerBundleIdentifier"], str)
    or not manifest["qaRunnerBundleIdentifier"]
):
    raise SystemExit(
        "QA manifest qaRunnerBundleIdentifier must be a non-empty string"
    )

input_policy = manifest["inputPolicy"]
if input_policy.get("originalAssetMutation") != "forbidden":
    raise SystemExit("Original asset mutation must remain forbidden")
if input_policy.get("automaticLibraryScan") != "forbidden":
    raise SystemExit("Automatic library scan must remain forbidden")
if input_policy.get("automaticPersonalAssetDeletion") != "forbidden":
    raise SystemExit("Automatic personal asset deletion must remain forbidden")

result_policy = manifest["resultPolicy"]
if result_policy.get("resultBundle") != "required":
    raise SystemExit("The result bundle must be required")
if result_policy.get("privateMediaExport") != "forbidden":
    raise SystemExit("Private media export must remain forbidden")

scenarios = manifest["scenarios"]
scenario_ids = [scenario.get("id") for scenario in scenarios]
expected_ids = [f"QA-{index:02d}" for index in range(1, 9)]
if scenario_ids != expected_ids:
    raise SystemExit(
        "QA scenarios must be exactly QA-01 through QA-08 in order"
    )
if any(not scenario.get("name") for scenario in scenarios):
    raise SystemExit("Every QA scenario must have a name")

print("QA manifest valid: " + ", ".join(scenario_ids))
PY
}

build_check() {
    validate_manifest

    local build_root="${BUILD_CHECK_ROOT}"
    local products_root="${build_root}/Build/Products/${CONFIGURATION}-iphoneos"
    local runner_app="${products_root}/${TARGET}-Runner.app"
    local test_bundle="${runner_app}/PlugIns/${TARGET}.xctest"

    xcodebuild \
        -project "${PROJECT_PATH}" \
        -scheme "${SCHEME}" \
        -configuration "${CONFIGURATION}" \
        -sdk iphoneos \
        -destination "generic/platform=iOS" \
        -derivedDataPath "${build_root}" \
        CODE_SIGNING_ALLOWED=NO \
        CODE_SIGNING_REQUIRED=NO \
        COMPILER_INDEX_STORE_ENABLE=NO \
        -parallel-testing-enabled NO \
        -jobs 1 \
        build-for-testing

    python3 "-" \
        "${MANIFEST_PATH}" \
        "${products_root}" \
        "${runner_app}" \
        "${test_bundle}" \
        "${BUILD_CHECK_RECEIPT}" \
        "${SCHEME}" \
        "${TARGET}" \
        "${CONFIGURATION}" \
        "${RUN_ID}" <<'PY'
import json
import plistlib
import sys
from pathlib import Path

(
    manifest_path,
    products_root_value,
    runner_app_value,
    test_bundle_value,
    receipt_path_value,
    scheme_value,
    target_value,
    configuration_value,
    run_id_value,
) = sys.argv[1:]
products_root = Path(products_root_value)
runner_app = Path(runner_app_value)
test_bundle = Path(test_bundle_value)
receipt_path = Path(receipt_path_value)

with open(manifest_path, encoding="utf-8") as file:
    manifest = json.load(file)

def require_directory(path, label):
    if path.is_symlink() or not path.is_dir():
        raise SystemExit(f"{label} is not a regular bundle directory: {path}")

def bundle_identifier(path, label):
    info_path = path / "Info.plist"
    if info_path.is_symlink() or not info_path.is_file():
        raise SystemExit(f"{label} Info.plist is not a regular file: {info_path}")
    with open(info_path, "rb") as file:
        payload = plistlib.load(file)
    identifier = payload.get("CFBundleIdentifier")
    if not isinstance(identifier, str) or not identifier:
        raise SystemExit(f"{label} has no CFBundleIdentifier")
    return identifier

require_directory(products_root, "iPhoneOS products")
require_directory(runner_app, "QA runner")
require_directory(test_bundle, "QA test bundle")

runner_identifier = bundle_identifier(runner_app, "QA runner")
test_identifier = bundle_identifier(test_bundle, "QA test bundle")
expected_runner_identifier = manifest["qaRunnerBundleIdentifier"]
expected_test_identifier = expected_runner_identifier.removesuffix(".xctrunner")
if runner_identifier != expected_runner_identifier:
    raise SystemExit(
        "QA runner Bundle ID mismatch: "
        + runner_identifier
        + " != "
        + expected_runner_identifier
    )
if test_identifier != expected_test_identifier:
    raise SystemExit(
        "QA test bundle Bundle ID mismatch: "
        + test_identifier
        + " != "
        + expected_test_identifier
    )

host_candidates = []
for candidate in products_root.glob("*.app"):
    if candidate == runner_app or candidate.is_symlink() or not candidate.is_dir():
        continue
    try:
        if bundle_identifier(candidate, "iOS host") == manifest["appBundleIdentifier"]:
            host_candidates.append(candidate)
    except SystemExit:
        continue

if len(host_candidates) != 1:
    raise SystemExit(
        "Expected exactly one iOS host app matching the manifest, found "
        + str(len(host_candidates))
    )

host_app = host_candidates[0]
receipt = {
    "schemaVersion": 1,
    "kind": "MemoMarkDeviceQABuildCheck",
    "mode": "unsigned-structural",
    "project": "MemoMark",
    "scheme": scheme_value,
    "target": target_value,
    "configuration": configuration_value,
    "runID": run_id_value,
    "result": "passed",
    "hostProduct": host_app.name,
    "hostBundleIdentifier": manifest["appBundleIdentifier"],
    "runnerProduct": runner_app.name,
    "runnerBundleIdentifier": runner_identifier,
    "testBundleProduct": test_bundle.name,
    "testBundleIdentifier": test_identifier,
}
with receipt_path.open("w", encoding="utf-8") as file:
    json.dump(receipt, file, ensure_ascii=False, indent=2)
    file.write("\n")

print(
    "MemoMark device QA build check passed: "
    + f"host={host_app.name}, "
    + f"runner={runner_app.name}, "
    + f"testBundle={test_bundle.name}"
)
PY
}

preflight() {
    validate_manifest
    {
        echo "MemoMark Device QA preflight"
        echo "repo=${REPO_ROOT}"
        echo "project=${PROJECT_PATH}"
        echo "device=${DEVICE}"
        echo "scheme=${SCHEME}"
        echo "configuration=${CONFIGURATION}"
        echo
        xcode-select -p
        xcodebuild -version
        echo
        xcrun devicectl list devices
        echo
        xcodebuild \
            -project "${PROJECT_PATH}" \
            -scheme "${SCHEME}" \
            -showdestinations
        echo
        xcrun devicectl device info lockState --device "${DEVICE}"
        xcrun devicectl device info details \
            --device "${DEVICE}" \
            --json-output "${DEVICE_DETAILS_JSON}" \
            --quiet
    } 2>&1 | tee "${PREFLIGHT_LOG}"

    resolve_device_identifier
    validate_physical_device | tee -a "${PREFLIGHT_LOG}"
    echo "Resolved device identifier: ${DEVICE_IDENTIFIER}" \
        | tee -a "${PREFLIGHT_LOG}"

    if ! grep -F "${DEVICE}" "${PREFLIGHT_LOG}" >/dev/null; then
        echo "Device was not found by devicectl: ${DEVICE}" >&2
        return 1
    fi

    if ! grep -F "unlockedSinceBoot: true" "${PREFLIGHT_LOG}" >/dev/null; then
        echo "The device is not currently unlocked: ${DEVICE}" >&2
        return 1
    fi
}

capture_device() {
    if [[ "${SKIP_SCREENSHOT}" == "YES" ]]; then
        return 0
    fi

    xcrun devicectl device capture screenshot \
        --device "${DEVICE}" \
        --destination "${SCREENSHOT_PATH}" \
        --timeout 30 \
        > "${RUN_DIRECTORY}/capture.log" 2>&1 || true
}

resolve_process_id() {
    if [[ -n "${PROCESS_ID}" ]]; then
        printf '%s\n' "${PROCESS_ID}"
        return 0
    fi

    xcrun devicectl device info processes \
        --device "${DEVICE}" \
        --search "MemoMark" \
        --json-output "${PROCESS_DETAILS_JSON}" \
        --quiet >/dev/null

    python3 "-" "${PROCESS_DETAILS_JSON}" <<'PY'
import json
import sys

with open(sys.argv[1], encoding="utf-8") as file:
    payload = json.load(file)

matches = []
for process in payload.get("result", {}).get("runningProcesses", []):
    executable = process.get("executable", "")
    if executable.endswith("/MemoMarkiOS.app/MemoMarkiOS"):
        matches.append(str(process["processIdentifier"]))

if len(matches) != 1:
    raise SystemExit(
        "Expected exactly one running MemoMarkiOS process, found "
        + str(len(matches))
    )

print(matches[0])
PY
}

run_tests() {
    write_metadata
    rm -rf "${RESULT_BUNDLE}"

    set +e
    if [[ "${ALLOW_PROVISIONING_UPDATES}" == "YES" ]]; then
        xcodebuild \
            -project "${PROJECT_PATH}" \
            -scheme "${SCHEME}" \
            -configuration "${CONFIGURATION}" \
            -destination "platform=iOS,id=${DEVICE_IDENTIFIER}" \
            -derivedDataPath "${DERIVED_DATA_ROOT}" \
            -resultBundlePath "${RESULT_BUNDLE}" \
            -allowProvisioningUpdates \
            -allowProvisioningDeviceRegistration \
            test 2>&1 | tee "${XCODEBUILD_LOG}"
    else
        xcodebuild \
            -project "${PROJECT_PATH}" \
            -scheme "${SCHEME}" \
            -configuration "${CONFIGURATION}" \
            -destination "platform=iOS,id=${DEVICE_IDENTIFIER}" \
            -derivedDataPath "${DERIVED_DATA_ROOT}" \
            -resultBundlePath "${RESULT_BUNDLE}" \
            test 2>&1 | tee "${XCODEBUILD_LOG}"
    fi
    local test_status="${PIPESTATUS[0]}"
    set -e

    capture_device

    if [[ -d "${RESULT_BUNDLE}" ]]; then
        xcrun xcresulttool get test-results summary \
            --path "${RESULT_BUNDLE}" \
            --compact \
            > "${TEST_SUMMARY_JSON}" \
            2> "${RUN_DIRECTORY}/xcresulttool.log" || true
    fi

    set +e
    python3 "${VERIFIER_PATH}" \
        --run-dir "${RUN_DIRECTORY}" \
        --xcodebuild-exit-status "${test_status}" \
        --write-metadata
    local verification_status="$?"
    set -e

    if [[ "${verification_status}" -ne 0 ]]; then
        if [[ "${test_status}" -ne 0 ]]; then
            return "${test_status}"
        fi
        return "${verification_status}"
    fi

    if [[ "${test_status}" -ne 0 ]]; then
        return "${test_status}"
    fi

    return 0
}

verify_run() {
    python3 "${VERIFIER_PATH}" --run-dir "${RUN_DIRECTORY}"
}

signing_status() {
    set +e
    if [[ "${JSON_OUTPUT}" == "YES" ]]; then
        python3 "${SIGNING_DIAGNOSTIC_PATH}" \
            --project "${PROJECT_PATH}" \
            --scheme "${SCHEME}" \
            --target "${TARGET}" \
            --configuration "${CONFIGURATION}" \
            --json
    else
        python3 "${SIGNING_DIAGNOSTIC_PATH}" \
            --project "${PROJECT_PATH}" \
            --scheme "${SCHEME}" \
            --target "${TARGET}" \
            --configuration "${CONFIGURATION}"
    fi
    local diagnostic_status="$?"
    set -e
    return "${diagnostic_status}"
}

run_signing_status() {
    set +e
    python3 "${SIGNING_DIAGNOSTIC_PATH}" \
        --project "${PROJECT_PATH}" \
        --scheme "${SCHEME}" \
        --target "${TARGET}" \
        --configuration "${CONFIGURATION}" \
        --json > "${SIGNING_STATUS_JSON}" 2>&1
    local diagnostic_status="$?"
    set -e
    cat "${SIGNING_STATUS_JSON}"
    return "${diagnostic_status}"
}

run_readiness() {
    local manifest_status=0
    local build_status=125
    local signing_exit_status=125
    local physical_device_status=125
    local build_result="skipped"
    local physical_device_result="skipped"
    local physical_device_reason="manifest-invalid"

    set +e
    validate_manifest > "${RUN_DIRECTORY}/manifest-validation.log" 2>&1
    manifest_status="$?"
    set -e

    if [[ "${manifest_status}" -eq 0 ]]; then
        build_result="failed"
        set +e
        build_check > "${RUN_DIRECTORY}/build-check.log" 2>&1
        build_status="$?"
        set -e
        if [[ "${build_status}" -eq 0 ]]; then
            if [[ -f "${BUILD_CHECK_RECEIPT}" ]]; then
                cp "${BUILD_CHECK_RECEIPT}" "${RUN_DIRECTORY}/build-check.json"
                build_result="passed"
            else
                build_status=1
                build_result="failed"
            fi
        fi

        # Signing remains an independent read-only gate. It is useful to
        # diagnose both local structural and account/profile state in one run.
        if run_signing_status > "${RUN_DIRECTORY}/signing-output.log" 2>&1; then
            signing_exit_status=0
        else
            signing_exit_status="$?"
        fi
    fi

    if [[ "${manifest_status}" -eq 0 \
        && "${build_status}" -eq 0 \
        && "${signing_exit_status}" -eq 0 ]]; then
        physical_device_reason=""
        set +e
        preflight > "${RUN_DIRECTORY}/preflight-output.log" 2>&1
        physical_device_status="$?"
        set -e
        if [[ "${physical_device_status}" -eq 0 ]]; then
            physical_device_result="passed"
        else
            physical_device_result="failed"
            physical_device_reason="$(
                python3 "${READINESS_REPORT_PATH}" \
                    --classify-preflight-failure \
                    --preflight-log "${PREFLIGHT_LOG}" \
                    --device-name "${DEVICE}"
            )"
        fi
    elif [[ "${manifest_status}" -ne 0 ]]; then
        physical_device_reason="manifest-invalid"
    elif [[ "${build_status}" -ne 0 ]]; then
        physical_device_reason="structural-build-failed"
    else
        physical_device_reason="signing-blocked"
    fi

    local report_status=0
    local -a signing_status_argument=(
        --signing-status "${SIGNING_STATUS_JSON}"
    )
    local -a device_details_argument=(
        --device-details "${DEVICE_DETAILS_JSON}"
    )

    set +e
    python3 "${READINESS_REPORT_PATH}" \
        --manifest "${RUN_DIRECTORY}/MemoMarkDeviceQA.json" \
        --output "${READINESS_JSON}" \
        --run-id "${RUN_ID}" \
        --device "${DEVICE}" \
        --device-identifier "${DEVICE_IDENTIFIER}" \
        --scheme "${SCHEME}" \
        --target "${TARGET}" \
        --configuration "${CONFIGURATION}" \
        --manifest-result "$([[ "${manifest_status}" -eq 0 ]] && echo passed || echo failed)" \
        --build-result "${build_result}" \
        --build-log "build-check.log" \
        "${signing_status_argument[@]}" \
        --physical-device-result "${physical_device_result}" \
        --physical-device-reason "${physical_device_reason}" \
        "${device_details_argument[@]}"
    report_status="$?"
    set -e

    return "${report_status}"
}

require_process_id() {
    PROCESS_ID="$(resolve_process_id)"
}

case "${COMMAND}" in
    preflight)
        preflight
        ;;
    validate)
        validate_manifest
        ;;
    build-check)
        build_check
        ;;
    readiness)
        run_readiness
        ;;
    verify)
        verify_run
        ;;
    verify-readiness)
        python3 "${READINESS_REPORT_PATH}" --verify "${RUN_DIRECTORY}"
        ;;
    signing-status)
        signing_status
        ;;
    capture)
        capture_device
        ;;
    processes)
        preflight
        xcrun devicectl device info processes \
            --device "${DEVICE}" \
            --search "MemoMark"
        ;;
    memory-warning)
        preflight
        require_process_id
        xcrun devicectl device process sendMemoryWarning \
            --device "${DEVICE}" \
            --pid "${PROCESS_ID}"
        ;;
    terminate)
        preflight
        require_process_id
        xcrun devicectl device process terminate \
            --device "${DEVICE}" \
            --pid "${PROCESS_ID}" \
            --kill
        ;;
    run)
        if [[ "${ALLOW_PROVISIONING_UPDATES}" != "YES" ]]; then
            run_signing_status
        fi
        preflight
        run_tests
        ;;
    *)
        echo "Unknown command: ${COMMAND}" >&2
        usage >&2
        exit 2
        ;;
esac

#!/usr/bin/env python3

"""Report MemoMark device-QA signing readiness without changing signing state."""

from __future__ import annotations

import argparse
import json
import plistlib
import re
import subprocess
from pathlib import Path
from typing import Any


DEFAULT_RUNNER_BUNDLE_ID = "com.serydoo.PhotoMemo.MemoMarkDeviceQA.xctrunner"
DEFAULT_TARGET = "MemoMarkDeviceQA"


def command_output(*command: str) -> tuple[int, str]:
    completed = subprocess.run(
        command,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        check=False,
    )
    return completed.returncode, completed.stdout


def build_settings(
    project: Path,
    target: str,
    configuration: str,
) -> tuple[dict[str, str], str | None]:
    status, output = command_output(
        "xcodebuild",
        "-project",
        str(project),
        "-target",
        target,
        "-configuration",
        configuration,
        "-sdk",
        "iphoneos",
        "-showBuildSettings",
    )
    settings: dict[str, str] = {}
    for line in output.splitlines():
        match = re.match(r"^\s+([A-Z0-9_]+) = (.*)$", line)
        if match:
            settings.setdefault(match.group(1), match.group(2))

    return settings, None if status == 0 else "show-build-settings-failed"


def runner_bundle_identifier(product_bundle_identifier: str) -> str:
    if product_bundle_identifier.endswith(".xctrunner"):
        return product_bundle_identifier
    return product_bundle_identifier + ".xctrunner"


def signing_identity_count() -> tuple[int, str | None]:
    status, output = command_output(
        "security",
        "find-identity",
        "-v",
        "-p",
        "codesigning",
    )
    count = sum(
        1
        for line in output.splitlines()
        if re.search(r"\) [0-9A-F]{40} \"Apple Development:", line)
    )
    return count, None if status == 0 else "codesigning-identity-query-failed"


def profile_entitlements(profile: Path) -> dict[str, Any] | None:
    status, output = command_output(
        "security",
        "cms",
        "-D",
        "-i",
        str(profile),
    )
    if status != 0:
        return None

    try:
        decoded = plistlib.loads(output.encode())
    except (plistlib.InvalidFileException, ValueError):
        return None

    entitlements = decoded.get("Entitlements")
    return entitlements if isinstance(entitlements, dict) else None


def profile_matches(
    entitlements: dict[str, Any],
    bundle_identifier: str,
    development_team: str,
) -> bool:
    expected_application_identifier = (
        development_team + "." + bundle_identifier
    )
    accepted_application_identifiers = {
        expected_application_identifier,
        development_team + ".*",
    }
    if entitlements.get("application-identifier") not in accepted_application_identifiers:
        return False

    return (
        entitlements.get("com.apple.developer.team-identifier")
        == development_team
        and entitlements.get("get-task-allow") is True
    )


def provisioning_profile_directories(home: Path | None = None) -> tuple[Path, ...]:
    profile_home = Path.home() if home is None else home
    return (
        profile_home
        / "Library"
        / "Developer"
        / "Xcode"
        / "UserData"
        / "Provisioning Profiles",
        profile_home / "Library" / "MobileDevice" / "Provisioning Profiles",
    )


def matching_profile_count(
    bundle_identifier: str,
    development_team: str,
) -> tuple[int, int]:
    readable_profiles = 0
    matching_profiles = 0
    seen_profiles: set[Path] = set()
    for profile_directory in provisioning_profile_directories():
        if not profile_directory.is_dir():
            continue
        for profile in profile_directory.glob("*.mobileprovision"):
            resolved_profile = profile.resolve()
            if resolved_profile in seen_profiles:
                continue
            seen_profiles.add(resolved_profile)
            entitlements = profile_entitlements(profile)
            if entitlements is None:
                continue
            readable_profiles += 1
            if profile_matches(
                entitlements,
                bundle_identifier,
                development_team,
            ):
                matching_profiles += 1

    return readable_profiles, matching_profiles


def diagnose(
    *,
    project: Path,
    scheme: str,
    target: str,
    configuration: str,
    runner_bundle_identifier_override: str | None,
) -> dict[str, Any]:
    settings, settings_failure = build_settings(
        project,
        target,
        configuration,
    )
    identity_count, identity_failure = signing_identity_count()
    development_team = settings.get("DEVELOPMENT_TEAM", "")
    product_bundle_identifier = settings.get("PRODUCT_BUNDLE_IDENTIFIER", "")
    resolved_runner_bundle_identifier = runner_bundle_identifier_override
    if resolved_runner_bundle_identifier is None and product_bundle_identifier:
        resolved_runner_bundle_identifier = runner_bundle_identifier(
            product_bundle_identifier
        )
    if resolved_runner_bundle_identifier is None:
        resolved_runner_bundle_identifier = DEFAULT_RUNNER_BUNDLE_ID
    readable_profiles, matching_profiles = matching_profile_count(
        resolved_runner_bundle_identifier,
        development_team,
    )

    failure_class = None
    if settings_failure:
        failure_class = settings_failure
    elif identity_failure:
        failure_class = identity_failure
    elif identity_count == 0:
        failure_class = "development-identity-missing"
    elif matching_profiles == 0:
        failure_class = "provisioning-profile-missing"

    return {
        "schemaVersion": 1,
        "mode": "read-only",
        "project": str(project),
        "scheme": scheme,
        "target": target,
        "configuration": configuration,
        "runnerBundleIdentifier": resolved_runner_bundle_identifier,
        "productBundleIdentifier": product_bundle_identifier or None,
        "codeSignStyle": settings.get("CODE_SIGN_STYLE"),
        "developmentTeam": development_team or None,
        "codeSignIdentity": settings.get("CODE_SIGN_IDENTITY"),
        "developmentIdentityCount": identity_count,
        "readableProvisioningProfileCount": readable_profiles,
        "matchingProvisioningProfileCount": matching_profiles,
        "allowProvisioningUpdatesRecommended": matching_profiles == 0,
        "failureClass": failure_class,
        "result": "ready" if failure_class is None else "blocked",
    }


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Report device-QA signing readiness without modifying signing state."
    )
    parser.add_argument("--project", required=True, type=Path)
    parser.add_argument("--scheme", required=True)
    parser.add_argument("--target", default=DEFAULT_TARGET)
    parser.add_argument("--configuration", default="Debug")
    parser.add_argument(
        "--runner-bundle-id",
        default=None,
    )
    parser.add_argument("--json", action="store_true")
    arguments = parser.parse_args()

    result = diagnose(
        project=arguments.project,
        scheme=arguments.scheme,
        target=arguments.target,
        configuration=arguments.configuration,
        runner_bundle_identifier_override=arguments.runner_bundle_id,
    )
    if arguments.json:
        print(json.dumps(result, ensure_ascii=False, indent=2))
    else:
        print(
            "MemoMark Device QA signing status: "
            + str(result["result"])
            + (
                " (" + str(result["failureClass"]) + ")"
                if result["failureClass"]
                else ""
            )
        )
        print(
            "developmentIdentityCount="
            + str(result["developmentIdentityCount"])
            + " matchingProvisioningProfileCount="
            + str(result["matchingProvisioningProfileCount"])
        )

    return 0 if result["result"] == "ready" else 1


if __name__ == "__main__":
    raise SystemExit(main())

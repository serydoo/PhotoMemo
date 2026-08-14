from __future__ import annotations

import importlib.util
import unittest
from pathlib import Path


SCRIPT_PATH = (
    Path(__file__).resolve().parents[1] / "memomark-device-qa-signing.py"
)
SPEC = importlib.util.spec_from_file_location(
    "memomark_device_qa_signing",
    SCRIPT_PATH,
)
if SPEC is None or SPEC.loader is None:
    raise RuntimeError("Unable to load signing diagnostic module")
SIGNING = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(SIGNING)


class ProfileMatchingTests(unittest.TestCase):
    BUNDLE_ID = "com.serydoo.PhotoMemo.MemoMarkDeviceQA.xctrunner"
    TEAM_ID = "UK7ZR8G564"

    def entitlements(self, **overrides: object) -> dict[str, object]:
        values: dict[str, object] = {
            "application-identifier": f"{self.TEAM_ID}.{self.BUNDLE_ID}",
            "com.apple.developer.team-identifier": self.TEAM_ID,
            "get-task-allow": True,
        }
        values.update(overrides)
        return values

    def test_requires_exact_team_bound_application_identifier(self) -> None:
        self.assertTrue(
            SIGNING.profile_matches(
                self.entitlements(),
                self.BUNDLE_ID,
                self.TEAM_ID,
            )
        )

        self.assertFalse(
            SIGNING.profile_matches(
                self.entitlements(
                    **{
                        "application-identifier":
                            "OTHERTEAM." + self.BUNDLE_ID,
                    }
                ),
                self.BUNDLE_ID,
                self.TEAM_ID,
            )
        )

    def test_requires_matching_team_identifier_entitlement(self) -> None:
        self.assertFalse(
            SIGNING.profile_matches(
                self.entitlements(
                    **{"com.apple.developer.team-identifier": "OTHERTEAM"}
                ),
                self.BUNDLE_ID,
                self.TEAM_ID,
            )
        )

    def test_requires_development_profile_entitlement(self) -> None:
        self.assertFalse(
            SIGNING.profile_matches(
                self.entitlements(**{"get-task-allow": False}),
                self.BUNDLE_ID,
                self.TEAM_ID,
            )
        )

    def test_runner_bundle_identifier_is_derived_from_qa_target(self) -> None:
        self.assertEqual(
            SIGNING.runner_bundle_identifier(
                "com.serydoo.PhotoMemo.MemoMarkDeviceQA"
            ),
            self.BUNDLE_ID,
        )
        self.assertEqual(
            SIGNING.runner_bundle_identifier(
                self.BUNDLE_ID
            ),
            self.BUNDLE_ID,
        )

        self.assertFalse(
            SIGNING.profile_matches(
                {
                    "application-identifier":
                        f"{self.TEAM_ID}.{self.BUNDLE_ID}"
                },
                self.BUNDLE_ID,
                self.TEAM_ID,
            )
        )

    def test_accepts_team_wildcard_development_profile(self) -> None:
        self.assertTrue(
            SIGNING.profile_matches(
                self.entitlements(
                    **{
                        "application-identifier":
                            f"{self.TEAM_ID}.*"
                    }
                ),
                self.BUNDLE_ID,
                self.TEAM_ID,
            )
        )


class ProfileDiscoveryTests(unittest.TestCase):
    def test_prefers_current_xcode_profile_directory_and_keeps_legacy_fallback(
        self,
    ) -> None:
        home = Path("/tmp/memomark-signing-test-home")

        self.assertEqual(
            SIGNING.provisioning_profile_directories(home),
            (
                home
                / "Library"
                / "Developer"
                / "Xcode"
                / "UserData"
                / "Provisioning Profiles",
                home / "Library" / "MobileDevice" / "Provisioning Profiles",
            ),
        )


if __name__ == "__main__":
    unittest.main()

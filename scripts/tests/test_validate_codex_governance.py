import importlib.util
import unittest
from pathlib import Path


SCRIPT_PATH = Path(__file__).resolve().parents[1] / "validate_codex_governance.py"
SPEC = importlib.util.spec_from_file_location("validate_codex_governance", SCRIPT_PATH)
governance = importlib.util.module_from_spec(SPEC)
assert SPEC.loader is not None
SPEC.loader.exec_module(governance)


class ValidateCodexGovernanceTests(unittest.TestCase):
    def test_current_repository_has_no_governance_findings(self):
        root = Path(__file__).resolve().parents[2]
        self.assertEqual(governance.collect_findings(root), [])

    def test_reports_missing_current_brief(self):
        root = Path(__file__).resolve().parents[2]
        findings = governance.collect_findings(
            root, required_files={"Docs/DOES_NOT_EXIST.md"}
        )
        self.assertIn("missing: Docs/DOES_NOT_EXIST.md", findings)


if __name__ == "__main__":
    unittest.main()

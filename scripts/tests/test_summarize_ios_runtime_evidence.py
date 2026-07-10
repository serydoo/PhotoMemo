import importlib.util
import json
import tempfile
import unittest
from pathlib import Path


SCRIPT_PATH = Path(__file__).resolve().parents[1] / "summarize-ios-runtime-evidence.py"
SPEC = importlib.util.spec_from_file_location("summarize_ios_runtime_evidence", SCRIPT_PATH)
summarizer = importlib.util.module_from_spec(SPEC)
assert SPEC.loader is not None
SPEC.loader.exec_module(summarizer)


class RuntimeEvidencePerformanceSummaryTests(unittest.TestCase):
    def test_new_jobs_include_duration_and_saved_throughput(self):
        with tempfile.TemporaryDirectory() as current_dir, tempfile.TemporaryDirectory() as baseline_dir:
            current = Path(current_dir)
            baseline = Path(baseline_dir)
            (current / "decoded").mkdir()
            (baseline / "decoded").mkdir()

            self.write_json(baseline / "decoded" / "batchQueue.jobs.json", [])
            self.write_json(baseline / "decoded" / "shareDiagnostics.events.json", [])
            self.write_json(baseline / "decoded" / "externalIntake.requests.json", [])

            tasks = [
                {
                    "id": f"task-{index}",
                    "phase": "completed",
                    "savedAssetIdentifier": f"asset-{index}",
                }
                for index in range(20)
            ]
            self.write_json(
                current / "decoded" / "batchQueue.jobs.json",
                [
                    {
                        "id": "job-20",
                        "title": "20 photos",
                        "launchSource": "shareExtension",
                        "state": "completed",
                        "createdAt": 100.0,
                        "updatedAt": 125.0,
                        "tasks": tasks,
                    }
                ],
            )
            self.write_json(current / "decoded" / "shareDiagnostics.events.json", [])
            self.write_json(current / "decoded" / "externalIntake.requests.json", [])

            summary = summarizer.build_summary(
                evidence_dir=current,
                baseline_dir=baseline,
                scenario="manual",
            )

            self.assertEqual(summary["newJobs"][0]["durationSeconds"], 25.0)
            self.assertEqual(summary["newJobs"][0]["savedTasksPerMinute"], 48.0)

    def test_new_task_duration_events_are_structured(self):
        with tempfile.TemporaryDirectory() as current_dir, tempfile.TemporaryDirectory() as baseline_dir:
            current = Path(current_dir)
            baseline = Path(baseline_dir)
            (current / "decoded").mkdir()
            (baseline / "decoded").mkdir()

            self.write_json(baseline / "decoded" / "batchQueue.jobs.json", [])
            self.write_json(baseline / "decoded" / "shareDiagnostics.events.json", [])
            self.write_json(baseline / "decoded" / "externalIntake.requests.json", [])
            self.write_json(current / "decoded" / "batchQueue.jobs.json", [])
            self.write_json(current / "decoded" / "externalIntake.requests.json", [])
            self.write_json(
                current / "decoded" / "shareDiagnostics.events.json",
                [
                    {
                        "id": "event-1",
                        "timestamp": 200.0,
                        "stage": "batch.task.duration",
                        "message": (
                            "taskID=task-1, fileName=IMG_0001.jpg, "
                            "contentType=public.jpeg, route=staticImage, "
                            "phase=completed, durationSeconds=1.234"
                        ),
                        "jobID": "job-1",
                    }
                ],
            )

            summary = summarizer.build_summary(
                evidence_dir=current,
                baseline_dir=baseline,
                scenario="manual",
            )

            self.assertEqual(
                summary["newTaskDurations"],
                [
                    {
                        "timestamp": 200.0,
                        "timestampISO": "2001-01-01T00:03:20+00:00",
                        "jobID": "job-1",
                        "taskID": "task-1",
                        "fileName": "IMG_0001.jpg",
                        "contentType": "public.jpeg",
                        "route": "staticImage",
                        "phase": "completed",
                        "durationSeconds": 1.234,
                    }
                ],
            )

    @staticmethod
    def write_json(path: Path, value):
        path.write_text(json.dumps(value), encoding="utf-8")


if __name__ == "__main__":
    unittest.main()

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
                            "runtimeStage=total, phase=completed, "
                            "durationSeconds=1.234"
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
                        "runtimeStage": "total",
                        "phase": "completed",
                        "durationSeconds": 1.234,
                    }
                ],
            )

    def test_key_value_parser_preserves_comma_space_inside_values(self):
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
                        "id": "event-comma-filename",
                        "timestamp": 220.0,
                        "stage": "batch.task.duration",
                        "message": (
                            "taskID=task-1, fileName=Summer, Beach.HEIC, "
                            "contentType=public.heic, route=staticImage, "
                            "runtimeStage=total, phase=completed, "
                            "durationSeconds=1.234"
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
                summary["newTaskDurations"][0]["fileName"],
                "Summer, Beach.HEIC",
            )

    def test_task_duration_parser_preserves_key_like_text_inside_file_name(self):
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
                        "id": "event-key-like-filename",
                        "timestamp": 240.0,
                        "stage": "batch.task.duration",
                        "message": (
                            "taskID=task-1, fileName=Summer, route=home.HEIC, "
                            "contentType=public.heic, route=staticImage, "
                            "runtimeStage=total, phase=completed, "
                            "durationSeconds=1.234"
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
                summary["newTaskDurations"][0]["fileName"],
                "Summer, route=home.HEIC",
            )
            self.assertEqual(
                summary["newTaskDurations"][0]["route"],
                "staticImage",
            )

    def test_new_task_stage_duration_events_are_structured(self):
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
                        "id": "event-stage-1",
                        "timestamp": 260.0,
                        "stage": "batch.task.stageDuration",
                        "message": (
                            "taskID=task-1, fileName=IMG_0001.jpg, "
                            "contentType=public.jpeg, route=staticImage, "
                            "stageName=notificationAttachment, outcome=completed, "
                            "durationSeconds=2.345, attachmentCreated=true, "
                            "isMainThread=false, "
                            "peakResidentMemoryBytes=123456789, "
                            "threadName=batch-worker"
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
                summary["newTaskStageDurations"],
                [
                    {
                        "timestamp": 260.0,
                        "timestampISO": "2001-01-01T00:04:20+00:00",
                        "jobID": "job-1",
                        "taskID": "task-1",
                        "fileName": "IMG_0001.jpg",
                        "contentType": "public.jpeg",
                        "route": "staticImage",
                        "stageName": "notificationAttachment",
                        "outcome": "completed",
                        "attachmentCreated": "true",
                        "isMainThread": "false",
                        "threadName": "batch-worker",
                        "peakResidentMemoryBytes": 123456789,
                        "durationSeconds": 2.345,
                    }
                ],
            )

    def test_task_stage_duration_parser_preserves_key_like_text_inside_file_name(self):
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
                        "id": "event-stage-key-like-file",
                        "timestamp": 265.0,
                        "stage": "batch.task.stageDuration",
                        "message": (
                            "taskID=task-1, fileName=IMG, stageName=family.jpg, "
                            "contentType=public.jpeg, route=staticImage, "
                            "stageName=notificationAttachment, outcome=completed, "
                            "durationSeconds=2.345, attachmentCreated=true, "
                            "isMainThread=false, "
                            "peakResidentMemoryBytes=123456789, "
                            "threadName=batch-worker"
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
                summary["newTaskStageDurations"][0]["fileName"],
                "IMG, stageName=family.jpg",
            )
            self.assertEqual(
                summary["newTaskStageDurations"][0]["stageName"],
                "notificationAttachment",
            )

    def test_new_task_admission_events_are_structured(self):
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
                        "id": "event-admission-1",
                        "timestamp": 300.0,
                        "stage": "batch.task.admission",
                        "message": (
                            "taskID=task-48, fileName=IMG_4800.HEIC, "
                            "contentType=public.heic, isRAW=false, "
                            "pixelWidth=8064, pixelHeight=6048, "
                            "pixelCount=48771072, "
                            "estimatedDecodedByteCount=195084288, "
                            "memoryTier=critical, "
                            "requiresExtendedPreviewPreparation=true, "
                            "maxConcurrentDecodes=1, maxConcurrentRenders=1, "
                            "maxConcurrentExports=1, schedulerMode=singleTaskLoop, "
                            "admission=queued"
                        ),
                        "jobID": "job-48",
                    }
                ],
            )

            summary = summarizer.build_summary(
                evidence_dir=current,
                baseline_dir=baseline,
                scenario="manual",
            )

            self.assertEqual(
                summary["newTaskAdmissionEvents"],
                [
                    {
                        "timestamp": 300.0,
                        "timestampISO": "2001-01-01T00:05:00+00:00",
                        "jobID": "job-48",
                        "taskID": "task-48",
                        "fileName": "IMG_4800.HEIC",
                        "contentType": "public.heic",
                        "isRAW": "false",
                        "pixelWidth": 8064,
                        "pixelHeight": 6048,
                        "pixelCount": 48771072,
                        "estimatedDecodedByteCount": 195084288,
                        "memoryTier": "critical",
                        "requiresExtendedPreviewPreparation": "true",
                        "maxConcurrentDecodes": 1,
                        "maxConcurrentRenders": 1,
                        "maxConcurrentExports": 1,
                        "schedulerMode": "singleTaskLoop",
                        "admission": "queued",
                    }
                ],
            )
            self.assertIn(
                "## New Task Admission Events",
                summarizer.render_markdown(summary),
            )

    def test_task_admission_parser_preserves_key_like_text_inside_file_name(self):
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
                        "id": "event-admission-key-like-file",
                        "timestamp": 305.0,
                        "stage": "batch.task.admission",
                        "message": (
                            "taskID=task-48, fileName=IMG, memoryTier=trip.HEIC, "
                            "contentType=public.heic, isRAW=false, "
                            "pixelWidth=8064, pixelHeight=6048, "
                            "pixelCount=48771072, "
                            "estimatedDecodedByteCount=195084288, "
                            "memoryTier=critical, "
                            "requiresExtendedPreviewPreparation=true, "
                            "maxConcurrentDecodes=1, maxConcurrentRenders=1, "
                            "maxConcurrentExports=1, schedulerMode=singleTaskLoop, "
                            "admission=queued"
                        ),
                        "jobID": "job-48",
                    }
                ],
            )

            summary = summarizer.build_summary(
                evidence_dir=current,
                baseline_dir=baseline,
                scenario="manual",
            )

            self.assertEqual(
                summary["newTaskAdmissionEvents"][0]["fileName"],
                "IMG, memoryTier=trip.HEIC",
            )
            self.assertEqual(
                summary["newTaskAdmissionEvents"][0]["memoryTier"],
                "critical",
            )

    def test_new_task_route_events_are_structured(self):
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
                        "id": "event-route-bundle",
                        "timestamp": 330.0,
                        "stage": "batch.task.route",
                        "message": (
                            "taskID=task-live-photo, "
                            "fileName=SharedLivePhoto.livephoto, "
                            "contentType=com.apple.live-photo-bundle, "
                            "hasSourceIdentifier=false, "
                            "sourceURLIsLivePhotoBundle=true, "
                            "route=livePhoto"
                        ),
                        "jobID": "job-live-photo",
                    }
                ],
            )

            summary = summarizer.build_summary(
                evidence_dir=current,
                baseline_dir=baseline,
                scenario="manual",
            )

            self.assertEqual(
                summary["newTaskRouteEvents"],
                [
                    {
                        "timestamp": 330.0,
                        "timestampISO": "2001-01-01T00:05:30+00:00",
                        "jobID": "job-live-photo",
                        "taskID": "task-live-photo",
                        "fileName": "SharedLivePhoto.livephoto",
                        "contentType": "com.apple.live-photo-bundle",
                        "hasSourceIdentifier": "false",
                        "sourceURLIsLivePhotoBundle": "true",
                        "route": "livePhoto",
                    }
                ],
            )
            self.assertIn(
                "## New Task Route Events",
                summarizer.render_markdown(summary),
            )

    def test_task_route_parser_preserves_key_like_text_inside_file_name(self):
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
                        "id": "event-route-key-like-filename",
                        "timestamp": 335.0,
                        "stage": "batch.task.route",
                        "message": (
                            "taskID=task-live-photo, "
                            "fileName=Shared, route=memory.livephoto, "
                            "contentType=com.apple.live-photo-bundle, "
                            "hasSourceIdentifier=false, "
                            "sourceURLIsLivePhotoBundle=true, "
                            "route=livePhoto"
                        ),
                        "jobID": "job-live-photo",
                    }
                ],
            )

            summary = summarizer.build_summary(
                evidence_dir=current,
                baseline_dir=baseline,
                scenario="manual",
            )

            self.assertEqual(
                summary["newTaskRouteEvents"][0]["fileName"],
                "Shared, route=memory.livephoto",
            )
            self.assertEqual(
                summary["newTaskRouteEvents"][0]["route"],
                "livePhoto",
            )

    def test_share_scenario_needs_review_when_readiness_event_is_missing(self):
        with tempfile.TemporaryDirectory() as current_dir, tempfile.TemporaryDirectory() as baseline_dir:
            current = Path(current_dir)
            baseline = Path(baseline_dir)
            (current / "decoded").mkdir()
            (baseline / "decoded").mkdir()

            self.write_json(baseline / "decoded" / "batchQueue.jobs.json", [])
            self.write_json(baseline / "decoded" / "shareDiagnostics.events.json", [])
            self.write_json(baseline / "decoded" / "externalIntake.requests.json", [])
            self.write_json(current / "decoded" / "shareDiagnostics.events.json", [])
            self.write_json(current / "decoded" / "externalIntake.requests.json", [])
            self.write_json(
                current / "decoded" / "batchQueue.jobs.json",
                [
                    self.completed_share_job(
                        job_id="job-share-1",
                        task_count=1,
                    )
                ],
            )

            summary = summarizer.build_summary(
                evidence_dir=current,
                baseline_dir=baseline,
                scenario="share-1",
            )

            self.assertEqual(summary["evaluation"]["status"], "needs-review")
            self.assertIn(
                "shared-container readiness",
                summary["evaluation"]["reason"],
            )

    def test_share_scenario_fails_when_readiness_is_false(self):
        with tempfile.TemporaryDirectory() as current_dir, tempfile.TemporaryDirectory() as baseline_dir:
            current = Path(current_dir)
            baseline = Path(baseline_dir)
            (current / "decoded").mkdir()
            (baseline / "decoded").mkdir()

            self.write_json(baseline / "decoded" / "batchQueue.jobs.json", [])
            self.write_json(baseline / "decoded" / "shareDiagnostics.events.json", [])
            self.write_json(baseline / "decoded" / "externalIntake.requests.json", [])
            self.write_json(current / "decoded" / "externalIntake.requests.json", [])
            self.write_json(
                current / "decoded" / "batchQueue.jobs.json",
                [
                    self.completed_share_job(
                        job_id="job-share-1",
                        task_count=1,
                    )
                ],
            )
            self.write_json(
                current / "decoded" / "shareDiagnostics.events.json",
                [
                    {
                        "id": "readiness-false",
                        "timestamp": 340.0,
                        "stage": "app.sharedContainerReadiness",
                        "message": (
                            "appGroup=group.com.serydoo.PhotoMemo, "
                            "handoffReady=false, "
                            "userDefaultsSuiteAvailable=false, "
                            "appGroupContainerAvailable=false, "
                            "usesFallbackUserDefaults=true, "
                            "usesFallbackBaseDirectory=true, "
                            "baseDirectory=/fallback"
                        ),
                        "requestID": "request-1",
                    }
                ],
            )

            summary = summarizer.build_summary(
                evidence_dir=current,
                baseline_dir=baseline,
                scenario="share-1",
            )

            self.assertEqual(summary["evaluation"]["status"], "fail")
            self.assertIn(
                "handoffReady=false",
                summary["evaluation"]["reason"],
            )

    def test_21_photo_reject_scenario_passes_with_too_many_photos_event(self):
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
                        "id": "too-many-photos",
                        "timestamp": 365.0,
                        "stage": "extension.input.tooManyPhotos",
                        "message": "supportedPhotos=21, max=20",
                    }
                ],
            )

            summary = summarizer.build_summary(
                evidence_dir=current,
                baseline_dir=baseline,
                scenario="share-21-reject",
            )

            self.assertEqual(summary["evaluation"]["status"], "pass")
            self.assertIn("too-many-photos", summary["evaluation"]["reason"])

    def test_21_photo_reject_scenario_needs_review_without_too_many_photos_event(self):
        with tempfile.TemporaryDirectory() as current_dir, tempfile.TemporaryDirectory() as baseline_dir:
            current = Path(current_dir)
            baseline = Path(baseline_dir)
            (current / "decoded").mkdir()
            (baseline / "decoded").mkdir()

            self.write_json(baseline / "decoded" / "batchQueue.jobs.json", [])
            self.write_json(baseline / "decoded" / "shareDiagnostics.events.json", [])
            self.write_json(baseline / "decoded" / "externalIntake.requests.json", [])
            self.write_json(current / "decoded" / "batchQueue.jobs.json", [])
            self.write_json(current / "decoded" / "shareDiagnostics.events.json", [])
            self.write_json(current / "decoded" / "externalIntake.requests.json", [])

            summary = summarizer.build_summary(
                evidence_dir=current,
                baseline_dir=baseline,
                scenario="share-21-reject",
            )

            self.assertEqual(summary["evaluation"]["status"], "needs-review")
            self.assertIn(
                "extension.input.tooManyPhotos",
                summary["evaluation"]["reason"],
            )

    def test_share_scenario_needs_review_when_task_duration_evidence_is_missing(self):
        with tempfile.TemporaryDirectory() as current_dir, tempfile.TemporaryDirectory() as baseline_dir:
            current = Path(current_dir)
            baseline = Path(baseline_dir)
            (current / "decoded").mkdir()
            (baseline / "decoded").mkdir()

            self.write_json(baseline / "decoded" / "batchQueue.jobs.json", [])
            self.write_json(baseline / "decoded" / "shareDiagnostics.events.json", [])
            self.write_json(baseline / "decoded" / "externalIntake.requests.json", [])
            self.write_json(current / "decoded" / "externalIntake.requests.json", [])
            self.write_json(
                current / "decoded" / "batchQueue.jobs.json",
                [
                    self.completed_share_job(
                        job_id="job-share-1",
                        task_count=1,
                    )
                ],
            )
            self.write_json(
                current / "decoded" / "shareDiagnostics.events.json",
                [self.shared_container_ready_event()],
            )

            summary = summarizer.build_summary(
                evidence_dir=current,
                baseline_dir=baseline,
                scenario="share-1",
            )

            self.assertEqual(summary["evaluation"]["status"], "needs-review")
            self.assertIn("task duration", summary["evaluation"]["reason"])

    def test_share_20_scenario_passes_with_per_task_duration_evidence(self):
        with tempfile.TemporaryDirectory() as current_dir, tempfile.TemporaryDirectory() as baseline_dir:
            current = Path(current_dir)
            baseline = Path(baseline_dir)
            (current / "decoded").mkdir()
            (baseline / "decoded").mkdir()

            self.write_json(baseline / "decoded" / "batchQueue.jobs.json", [])
            self.write_json(baseline / "decoded" / "shareDiagnostics.events.json", [])
            self.write_json(baseline / "decoded" / "externalIntake.requests.json", [])
            self.write_json(current / "decoded" / "externalIntake.requests.json", [])
            self.write_json(
                current / "decoded" / "batchQueue.jobs.json",
                [
                    self.completed_share_job(
                        job_id="job-share-20",
                        task_count=20,
                    )
                ],
            )
            self.write_json(
                current / "decoded" / "shareDiagnostics.events.json",
                [
                    self.shared_container_ready_event(),
                    *[
                        self.task_duration_event(
                            event_id=f"duration-{index}",
                            job_id="job-share-20",
                            task_id=f"job-share-20-task-{index}",
                        )
                        for index in range(20)
                    ],
                ],
            )

            summary = summarizer.build_summary(
                evidence_dir=current,
                baseline_dir=baseline,
                scenario="share-20",
            )

            self.assertEqual(summary["evaluation"]["status"], "pass")
            self.assertIn("task duration", summary["evaluation"]["reason"])

    def test_mixed_live_photo_share_scenario_passes_with_live_and_static_routes(self):
        with tempfile.TemporaryDirectory() as current_dir, tempfile.TemporaryDirectory() as baseline_dir:
            current = Path(current_dir)
            baseline = Path(baseline_dir)
            (current / "decoded").mkdir()
            (baseline / "decoded").mkdir()

            self.write_json(baseline / "decoded" / "batchQueue.jobs.json", [])
            self.write_json(baseline / "decoded" / "shareDiagnostics.events.json", [])
            self.write_json(baseline / "decoded" / "externalIntake.requests.json", [])
            self.write_json(current / "decoded" / "externalIntake.requests.json", [])
            self.write_json(
                current / "decoded" / "batchQueue.jobs.json",
                [
                    self.completed_share_job(
                        job_id="job-mixed-live",
                        task_count=2,
                    )
                ],
            )
            self.write_json(
                current / "decoded" / "shareDiagnostics.events.json",
                [
                    self.shared_container_ready_event(),
                    {
                        "id": "route-live",
                        "timestamp": 370.0,
                        "stage": "batch.task.route",
                        "message": (
                            "taskID=task-live, fileName=Live.livephoto, "
                            "contentType=com.apple.live-photo-bundle, "
                            "hasSourceIdentifier=false, "
                            "sourceURLIsLivePhotoBundle=true, "
                            "route=livePhoto"
                        ),
                        "jobID": "job-mixed-live",
                    },
                    {
                        "id": "route-still",
                        "timestamp": 371.0,
                        "stage": "batch.task.route",
                        "message": (
                            "taskID=task-still, fileName=Still.HEIC, "
                            "contentType=public.heic, "
                            "hasSourceIdentifier=false, "
                            "sourceURLIsLivePhotoBundle=false, "
                            "route=staticImage"
                        ),
                        "jobID": "job-mixed-live",
                    },
                    self.task_duration_event(
                        event_id="duration-live",
                        job_id="job-mixed-live",
                        task_id="task-live",
                    ),
                    self.task_duration_event(
                        event_id="duration-still",
                        job_id="job-mixed-live",
                        task_id="task-still",
                    ),
                ],
            )

            summary = summarizer.build_summary(
                evidence_dir=current,
                baseline_dir=baseline,
                scenario="share-livephoto-mixed",
            )

            self.assertEqual(summary["evaluation"]["status"], "pass")
            self.assertIn("Live Photo and still routes", summary["evaluation"]["reason"])

    def test_mixed_live_photo_share_scenario_needs_review_without_duration_evidence(self):
        with tempfile.TemporaryDirectory() as current_dir, tempfile.TemporaryDirectory() as baseline_dir:
            current = Path(current_dir)
            baseline = Path(baseline_dir)
            (current / "decoded").mkdir()
            (baseline / "decoded").mkdir()

            self.write_json(baseline / "decoded" / "batchQueue.jobs.json", [])
            self.write_json(baseline / "decoded" / "shareDiagnostics.events.json", [])
            self.write_json(baseline / "decoded" / "externalIntake.requests.json", [])
            self.write_json(current / "decoded" / "externalIntake.requests.json", [])
            self.write_json(
                current / "decoded" / "batchQueue.jobs.json",
                [
                    self.completed_share_job(
                        job_id="job-mixed-live",
                        task_count=2,
                    )
                ],
            )
            self.write_json(
                current / "decoded" / "shareDiagnostics.events.json",
                [
                    self.shared_container_ready_event(),
                    {
                        "id": "route-live",
                        "timestamp": 370.0,
                        "stage": "batch.task.route",
                        "message": (
                            "taskID=task-live, fileName=Live.livephoto, "
                            "contentType=com.apple.live-photo-bundle, "
                            "hasSourceIdentifier=false, "
                            "sourceURLIsLivePhotoBundle=true, "
                            "route=livePhoto"
                        ),
                        "jobID": "job-mixed-live",
                    },
                    {
                        "id": "route-still",
                        "timestamp": 371.0,
                        "stage": "batch.task.route",
                        "message": (
                            "taskID=task-still, fileName=Still.HEIC, "
                            "contentType=public.heic, "
                            "hasSourceIdentifier=false, "
                            "sourceURLIsLivePhotoBundle=false, "
                            "route=staticImage"
                        ),
                        "jobID": "job-mixed-live",
                    },
                ],
            )

            summary = summarizer.build_summary(
                evidence_dir=current,
                baseline_dir=baseline,
                scenario="share-livephoto-mixed",
            )

            self.assertEqual(summary["evaluation"]["status"], "needs-review")
            self.assertIn("task duration", summary["evaluation"]["reason"])

    def test_mixed_live_photo_share_scenario_fails_bad_routes_even_without_duration(self):
        with tempfile.TemporaryDirectory() as current_dir, tempfile.TemporaryDirectory() as baseline_dir:
            current = Path(current_dir)
            baseline = Path(baseline_dir)
            (current / "decoded").mkdir()
            (baseline / "decoded").mkdir()

            self.write_json(baseline / "decoded" / "batchQueue.jobs.json", [])
            self.write_json(baseline / "decoded" / "shareDiagnostics.events.json", [])
            self.write_json(baseline / "decoded" / "externalIntake.requests.json", [])
            self.write_json(current / "decoded" / "externalIntake.requests.json", [])
            self.write_json(
                current / "decoded" / "batchQueue.jobs.json",
                [
                    self.completed_share_job(
                        job_id="job-mixed-live",
                        task_count=2,
                    )
                ],
            )
            self.write_json(
                current / "decoded" / "shareDiagnostics.events.json",
                [
                    self.shared_container_ready_event(),
                    {
                        "id": "route-static-1",
                        "timestamp": 370.0,
                        "stage": "batch.task.route",
                        "message": (
                            "taskID=task-live, fileName=Live.HEIC, "
                            "contentType=public.heic, "
                            "hasSourceIdentifier=false, "
                            "sourceURLIsLivePhotoBundle=false, "
                            "route=staticImage"
                        ),
                        "jobID": "job-mixed-live",
                    },
                    {
                        "id": "route-static-2",
                        "timestamp": 371.0,
                        "stage": "batch.task.route",
                        "message": (
                            "taskID=task-still, fileName=Still.HEIC, "
                            "contentType=public.heic, "
                            "hasSourceIdentifier=false, "
                            "sourceURLIsLivePhotoBundle=false, "
                            "route=staticImage"
                        ),
                        "jobID": "job-mixed-live",
                    },
                ],
            )

            summary = summarizer.build_summary(
                evidence_dir=current,
                baseline_dir=baseline,
                scenario="share-livephoto-mixed",
            )

            self.assertEqual(summary["evaluation"]["status"], "fail")
            self.assertIn("livePhoto route", summary["evaluation"]["reason"])

    def test_mixed_live_photo_share_scenario_scopes_routes_to_completed_job(self):
        with tempfile.TemporaryDirectory() as current_dir, tempfile.TemporaryDirectory() as baseline_dir:
            current = Path(current_dir)
            baseline = Path(baseline_dir)
            (current / "decoded").mkdir()
            (baseline / "decoded").mkdir()

            self.write_json(baseline / "decoded" / "batchQueue.jobs.json", [])
            self.write_json(baseline / "decoded" / "shareDiagnostics.events.json", [])
            self.write_json(baseline / "decoded" / "externalIntake.requests.json", [])
            self.write_json(current / "decoded" / "externalIntake.requests.json", [])
            self.write_json(
                current / "decoded" / "batchQueue.jobs.json",
                [
                    self.completed_share_job(
                        job_id="job-mixed-live",
                        task_count=2,
                    )
                ],
            )
            self.write_json(
                current / "decoded" / "shareDiagnostics.events.json",
                [
                    self.shared_container_ready_event(),
                    {
                        "id": "route-unrelated-live",
                        "timestamp": 370.0,
                        "stage": "batch.task.route",
                        "message": (
                            "taskID=task-live, fileName=Live.livephoto, "
                            "contentType=com.apple.live-photo-bundle, "
                            "hasSourceIdentifier=false, "
                            "sourceURLIsLivePhotoBundle=true, "
                            "route=livePhoto"
                        ),
                        "jobID": "job-unrelated",
                    },
                    {
                        "id": "route-completed-still",
                        "timestamp": 371.0,
                        "stage": "batch.task.route",
                        "message": (
                            "taskID=task-still, fileName=Still.HEIC, "
                            "contentType=public.heic, "
                            "hasSourceIdentifier=false, "
                            "sourceURLIsLivePhotoBundle=false, "
                            "route=staticImage"
                        ),
                        "jobID": "job-mixed-live",
                    },
                    self.task_duration_event(
                        event_id="duration-live",
                        job_id="job-mixed-live",
                        task_id="task-live",
                    ),
                    self.task_duration_event(
                        event_id="duration-still",
                        job_id="job-mixed-live",
                        task_id="task-still",
                    ),
                ],
            )

            summary = summarizer.build_summary(
                evidence_dir=current,
                baseline_dir=baseline,
                scenario="share-livephoto-mixed",
            )

            self.assertEqual(summary["evaluation"]["status"], "fail")
            self.assertIn("completed Share job", summary["evaluation"]["reason"])

    def test_mixed_live_photo_share_scenario_needs_review_without_route_evidence(self):
        with tempfile.TemporaryDirectory() as current_dir, tempfile.TemporaryDirectory() as baseline_dir:
            current = Path(current_dir)
            baseline = Path(baseline_dir)
            (current / "decoded").mkdir()
            (baseline / "decoded").mkdir()

            self.write_json(baseline / "decoded" / "batchQueue.jobs.json", [])
            self.write_json(baseline / "decoded" / "shareDiagnostics.events.json", [])
            self.write_json(baseline / "decoded" / "externalIntake.requests.json", [])
            self.write_json(current / "decoded" / "externalIntake.requests.json", [])
            self.write_json(
                current / "decoded" / "batchQueue.jobs.json",
                [
                    self.completed_share_job(
                        job_id="job-mixed-live",
                        task_count=2,
                    )
                ],
            )
            self.write_json(
                current / "decoded" / "shareDiagnostics.events.json",
                [
                    self.shared_container_ready_event(),
                    self.task_duration_event(
                        event_id="duration-live",
                        job_id="job-mixed-live",
                        task_id="task-live",
                    ),
                    self.task_duration_event(
                        event_id="duration-still",
                        job_id="job-mixed-live",
                        task_id="task-still",
                    ),
                ],
            )

            summary = summarizer.build_summary(
                evidence_dir=current,
                baseline_dir=baseline,
                scenario="share-livephoto-mixed",
            )

            self.assertEqual(summary["evaluation"]["status"], "needs-review")
            self.assertIn("route evidence", summary["evaluation"]["reason"])

    def test_single_live_photo_share_scenario_passes_with_live_photo_route(self):
        with tempfile.TemporaryDirectory() as current_dir, tempfile.TemporaryDirectory() as baseline_dir:
            current = Path(current_dir)
            baseline = Path(baseline_dir)
            (current / "decoded").mkdir()
            (baseline / "decoded").mkdir()

            self.write_json(baseline / "decoded" / "batchQueue.jobs.json", [])
            self.write_json(baseline / "decoded" / "shareDiagnostics.events.json", [])
            self.write_json(baseline / "decoded" / "externalIntake.requests.json", [])
            self.write_json(current / "decoded" / "externalIntake.requests.json", [])
            self.write_json(
                current / "decoded" / "batchQueue.jobs.json",
                [
                    self.completed_share_job(
                        job_id="job-live-1",
                        task_count=1,
                    )
                ],
            )
            self.write_json(
                current / "decoded" / "shareDiagnostics.events.json",
                [
                    self.shared_container_ready_event(),
                    {
                        "id": "route-live",
                        "timestamp": 372.0,
                        "stage": "batch.task.route",
                        "message": (
                            "taskID=task-live, fileName=Live.livephoto, "
                            "contentType=com.apple.live-photo-bundle, "
                            "hasSourceIdentifier=false, "
                            "sourceURLIsLivePhotoBundle=true, "
                            "route=livePhoto"
                        ),
                        "jobID": "job-live-1",
                    },
                    self.task_duration_event(
                        event_id="duration-live",
                        job_id="job-live-1",
                        task_id="task-live",
                    ),
                ],
            )

            summary = summarizer.build_summary(
                evidence_dir=current,
                baseline_dir=baseline,
                scenario="share-livephoto-1",
            )

            self.assertEqual(summary["evaluation"]["status"], "pass")
            self.assertIn("single Live Photo route", summary["evaluation"]["reason"])

    def test_single_live_photo_share_scenario_needs_review_without_duration_evidence(self):
        with tempfile.TemporaryDirectory() as current_dir, tempfile.TemporaryDirectory() as baseline_dir:
            current = Path(current_dir)
            baseline = Path(baseline_dir)
            (current / "decoded").mkdir()
            (baseline / "decoded").mkdir()

            self.write_json(baseline / "decoded" / "batchQueue.jobs.json", [])
            self.write_json(baseline / "decoded" / "shareDiagnostics.events.json", [])
            self.write_json(baseline / "decoded" / "externalIntake.requests.json", [])
            self.write_json(current / "decoded" / "externalIntake.requests.json", [])
            self.write_json(
                current / "decoded" / "batchQueue.jobs.json",
                [
                    self.completed_share_job(
                        job_id="job-live-1",
                        task_count=1,
                    )
                ],
            )
            self.write_json(
                current / "decoded" / "shareDiagnostics.events.json",
                [
                    self.shared_container_ready_event(),
                    {
                        "id": "route-live",
                        "timestamp": 372.0,
                        "stage": "batch.task.route",
                        "message": (
                            "taskID=task-live, fileName=Live.livephoto, "
                            "contentType=com.apple.live-photo-bundle, "
                            "hasSourceIdentifier=false, "
                            "sourceURLIsLivePhotoBundle=true, "
                            "route=livePhoto"
                        ),
                        "jobID": "job-live-1",
                    },
                ],
            )

            summary = summarizer.build_summary(
                evidence_dir=current,
                baseline_dir=baseline,
                scenario="share-livephoto-1",
            )

            self.assertEqual(summary["evaluation"]["status"], "needs-review")
            self.assertIn("task duration", summary["evaluation"]["reason"])

    def test_single_live_photo_share_scenario_fails_static_route_even_without_duration(self):
        with tempfile.TemporaryDirectory() as current_dir, tempfile.TemporaryDirectory() as baseline_dir:
            current = Path(current_dir)
            baseline = Path(baseline_dir)
            (current / "decoded").mkdir()
            (baseline / "decoded").mkdir()

            self.write_json(baseline / "decoded" / "batchQueue.jobs.json", [])
            self.write_json(baseline / "decoded" / "shareDiagnostics.events.json", [])
            self.write_json(baseline / "decoded" / "externalIntake.requests.json", [])
            self.write_json(current / "decoded" / "externalIntake.requests.json", [])
            self.write_json(
                current / "decoded" / "batchQueue.jobs.json",
                [
                    self.completed_share_job(
                        job_id="job-live-1",
                        task_count=1,
                    )
                ],
            )
            self.write_json(
                current / "decoded" / "shareDiagnostics.events.json",
                [
                    self.shared_container_ready_event(),
                    {
                        "id": "route-static",
                        "timestamp": 372.0,
                        "stage": "batch.task.route",
                        "message": (
                            "taskID=task-live, fileName=Live.HEIC, "
                            "contentType=public.heic, "
                            "hasSourceIdentifier=false, "
                            "sourceURLIsLivePhotoBundle=false, "
                            "route=staticImage"
                        ),
                        "jobID": "job-live-1",
                    },
                ],
            )

            summary = summarizer.build_summary(
                evidence_dir=current,
                baseline_dir=baseline,
                scenario="share-livephoto-1",
            )

            self.assertEqual(summary["evaluation"]["status"], "fail")
            self.assertIn("static", summary["evaluation"]["reason"])

    def test_single_live_photo_share_scenario_fails_when_route_is_static(self):
        with tempfile.TemporaryDirectory() as current_dir, tempfile.TemporaryDirectory() as baseline_dir:
            current = Path(current_dir)
            baseline = Path(baseline_dir)
            (current / "decoded").mkdir()
            (baseline / "decoded").mkdir()

            self.write_json(baseline / "decoded" / "batchQueue.jobs.json", [])
            self.write_json(baseline / "decoded" / "shareDiagnostics.events.json", [])
            self.write_json(baseline / "decoded" / "externalIntake.requests.json", [])
            self.write_json(current / "decoded" / "externalIntake.requests.json", [])
            self.write_json(
                current / "decoded" / "batchQueue.jobs.json",
                [
                    self.completed_share_job(
                        job_id="job-live-1",
                        task_count=1,
                    )
                ],
            )
            self.write_json(
                current / "decoded" / "shareDiagnostics.events.json",
                [
                    self.shared_container_ready_event(),
                    {
                        "id": "route-static",
                        "timestamp": 372.0,
                        "stage": "batch.task.route",
                        "message": (
                            "taskID=task-live, fileName=Live.HEIC, "
                            "contentType=public.heic, "
                            "hasSourceIdentifier=false, "
                            "sourceURLIsLivePhotoBundle=false, "
                            "route=staticImage"
                        ),
                        "jobID": "job-live-1",
                    },
                    self.task_duration_event(
                        event_id="duration-live",
                        job_id="job-live-1",
                        task_id="task-live",
                    ),
                ],
            )

            summary = summarizer.build_summary(
                evidence_dir=current,
                baseline_dir=baseline,
                scenario="share-livephoto-1",
            )

            self.assertEqual(summary["evaluation"]["status"], "fail")
            self.assertIn("static", summary["evaluation"]["reason"])

    def test_48mp_share_scenario_passes_with_critical_single_lane_admission(self):
        with tempfile.TemporaryDirectory() as current_dir, tempfile.TemporaryDirectory() as baseline_dir:
            current = Path(current_dir)
            baseline = Path(baseline_dir)
            (current / "decoded").mkdir()
            (baseline / "decoded").mkdir()

            self.write_json(baseline / "decoded" / "batchQueue.jobs.json", [])
            self.write_json(baseline / "decoded" / "shareDiagnostics.events.json", [])
            self.write_json(baseline / "decoded" / "externalIntake.requests.json", [])
            self.write_json(current / "decoded" / "externalIntake.requests.json", [])
            self.write_json(
                current / "decoded" / "batchQueue.jobs.json",
                [
                    self.completed_share_job(
                        job_id="job-48mp",
                        task_count=1,
                    )
                ],
            )
            self.write_json(
                current / "decoded" / "shareDiagnostics.events.json",
                [
                    self.shared_container_ready_event(),
                    {
                        "id": "admission-48mp",
                        "timestamp": 380.0,
                        "stage": "batch.task.admission",
                        "message": (
                            "taskID=task-48mp, fileName=IMG_4800.HEIC, "
                            "contentType=public.heic, isRAW=false, "
                            "pixelWidth=8064, pixelHeight=6048, "
                            "pixelCount=48771072, "
                            "estimatedDecodedByteCount=195084288, "
                            "memoryTier=critical, "
                            "requiresExtendedPreviewPreparation=true, "
                            "maxConcurrentDecodes=1, maxConcurrentRenders=1, "
                            "maxConcurrentExports=1, schedulerMode=singleTaskLoop, "
                            "admission=queued"
                        ),
                        "jobID": "job-48mp",
                    },
                    self.task_duration_event(
                        event_id="duration-48mp",
                        job_id="job-48mp",
                        task_id="task-48mp",
                    ),
                ],
            )

            summary = summarizer.build_summary(
                evidence_dir=current,
                baseline_dir=baseline,
                scenario="share-48mp",
            )

            self.assertEqual(summary["evaluation"]["status"], "pass")
            self.assertIn("critical single-lane", summary["evaluation"]["reason"])

    def test_48mp_share_scenario_needs_review_without_duration_evidence(self):
        with tempfile.TemporaryDirectory() as current_dir, tempfile.TemporaryDirectory() as baseline_dir:
            current = Path(current_dir)
            baseline = Path(baseline_dir)
            (current / "decoded").mkdir()
            (baseline / "decoded").mkdir()

            self.write_json(baseline / "decoded" / "batchQueue.jobs.json", [])
            self.write_json(baseline / "decoded" / "shareDiagnostics.events.json", [])
            self.write_json(baseline / "decoded" / "externalIntake.requests.json", [])
            self.write_json(current / "decoded" / "externalIntake.requests.json", [])
            self.write_json(
                current / "decoded" / "batchQueue.jobs.json",
                [
                    self.completed_share_job(
                        job_id="job-48mp",
                        task_count=1,
                    )
                ],
            )
            self.write_json(
                current / "decoded" / "shareDiagnostics.events.json",
                [
                    self.shared_container_ready_event(),
                    {
                        "id": "admission-48mp",
                        "timestamp": 380.0,
                        "stage": "batch.task.admission",
                        "message": (
                            "taskID=task-48mp, fileName=IMG_4800.HEIC, "
                            "contentType=public.heic, isRAW=false, "
                            "pixelWidth=8064, pixelHeight=6048, "
                            "pixelCount=48771072, "
                            "estimatedDecodedByteCount=195084288, "
                            "memoryTier=critical, "
                            "requiresExtendedPreviewPreparation=true, "
                            "maxConcurrentDecodes=1, maxConcurrentRenders=1, "
                            "maxConcurrentExports=1, schedulerMode=singleTaskLoop, "
                            "admission=queued"
                        ),
                        "jobID": "job-48mp",
                    },
                ],
            )

            summary = summarizer.build_summary(
                evidence_dir=current,
                baseline_dir=baseline,
                scenario="share-48mp",
            )

            self.assertEqual(summary["evaluation"]["status"], "needs-review")
            self.assertIn("task duration", summary["evaluation"]["reason"])

    def test_48mp_share_scenario_ignores_unrelated_admission_evidence(self):
        with tempfile.TemporaryDirectory() as current_dir, tempfile.TemporaryDirectory() as baseline_dir:
            current = Path(current_dir)
            baseline = Path(baseline_dir)
            (current / "decoded").mkdir()
            (baseline / "decoded").mkdir()

            self.write_json(baseline / "decoded" / "batchQueue.jobs.json", [])
            self.write_json(baseline / "decoded" / "shareDiagnostics.events.json", [])
            self.write_json(baseline / "decoded" / "externalIntake.requests.json", [])
            self.write_json(current / "decoded" / "externalIntake.requests.json", [])
            self.write_json(
                current / "decoded" / "batchQueue.jobs.json",
                [
                    self.completed_share_job(
                        job_id="job-48mp",
                        task_count=1,
                    )
                ],
            )
            self.write_json(
                current / "decoded" / "shareDiagnostics.events.json",
                [
                    self.shared_container_ready_event(),
                    self.task_duration_event(
                        event_id="duration-48mp",
                        job_id="job-48mp",
                        task_id="task-48mp",
                    ),
                    {
                        "id": "admission-unrelated-48mp",
                        "timestamp": 380.0,
                        "stage": "batch.task.admission",
                        "message": (
                            "taskID=task-48mp, fileName=IMG_4800.HEIC, "
                            "contentType=public.heic, isRAW=false, "
                            "pixelWidth=8064, pixelHeight=6048, "
                            "pixelCount=48771072, "
                            "estimatedDecodedByteCount=195084288, "
                            "memoryTier=critical, "
                            "requiresExtendedPreviewPreparation=true, "
                            "maxConcurrentDecodes=1, maxConcurrentRenders=1, "
                            "maxConcurrentExports=1, schedulerMode=singleTaskLoop, "
                            "admission=queued"
                        ),
                        "jobID": "job-unrelated",
                    },
                ],
            )

            summary = summarizer.build_summary(
                evidence_dir=current,
                baseline_dir=baseline,
                scenario="share-48mp",
            )

            self.assertEqual(summary["evaluation"]["status"], "needs-review")
            self.assertIn("No 48MP task admission", summary["evaluation"]["reason"])

    def test_48mp_share_scenario_fails_when_admission_is_not_single_lane(self):
        with tempfile.TemporaryDirectory() as current_dir, tempfile.TemporaryDirectory() as baseline_dir:
            current = Path(current_dir)
            baseline = Path(baseline_dir)
            (current / "decoded").mkdir()
            (baseline / "decoded").mkdir()

            self.write_json(baseline / "decoded" / "batchQueue.jobs.json", [])
            self.write_json(baseline / "decoded" / "shareDiagnostics.events.json", [])
            self.write_json(baseline / "decoded" / "externalIntake.requests.json", [])
            self.write_json(current / "decoded" / "externalIntake.requests.json", [])
            self.write_json(
                current / "decoded" / "batchQueue.jobs.json",
                [
                    self.completed_share_job(
                        job_id="job-48mp",
                        task_count=1,
                    )
                ],
            )
            self.write_json(
                current / "decoded" / "shareDiagnostics.events.json",
                [
                    self.shared_container_ready_event(),
                    {
                        "id": "admission-48mp",
                        "timestamp": 380.0,
                        "stage": "batch.task.admission",
                        "message": (
                            "taskID=task-48mp, fileName=IMG_4800.HEIC, "
                            "contentType=public.heic, isRAW=false, "
                            "pixelWidth=8064, pixelHeight=6048, "
                            "pixelCount=48771072, "
                            "estimatedDecodedByteCount=195084288, "
                            "memoryTier=large, "
                            "requiresExtendedPreviewPreparation=true, "
                            "maxConcurrentDecodes=2, maxConcurrentRenders=1, "
                            "maxConcurrentExports=1, schedulerMode=balanced, "
                            "admission=queued"
                        ),
                        "jobID": "job-48mp",
                    },
                    self.task_duration_event(
                        event_id="duration-48mp",
                        job_id="job-48mp",
                        task_id="task-48mp",
                    ),
                ],
            )

            summary = summarizer.build_summary(
                evidence_dir=current,
                baseline_dir=baseline,
                scenario="share-48mp",
            )

            self.assertEqual(summary["evaluation"]["status"], "fail")
            self.assertIn("single-lane", summary["evaluation"]["reason"])

    def test_new_shared_container_readiness_events_are_structured(self):
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
                        "id": "event-readiness-1",
                        "timestamp": 360.0,
                        "stage": "app.sharedContainerReadiness",
                        "message": (
                            "appGroup=group.com.serydoo.PhotoMemo, "
                            "handoffReady=false, "
                            "userDefaultsSuiteAvailable=true, "
                            "appGroupContainerAvailable=false, "
                            "usesFallbackUserDefaults=false, "
                            "usesFallbackBaseDirectory=true, "
                            "baseDirectory=/var/mobile/Containers/Data/Application/PhotoMemo"
                        ),
                        "requestID": "request-1",
                    }
                ],
            )

            summary = summarizer.build_summary(
                evidence_dir=current,
                baseline_dir=baseline,
                scenario="manual",
            )

            self.assertEqual(
                summary["newSharedContainerReadinessEvents"],
                [
                    {
                        "timestamp": 360.0,
                        "timestampISO": "2001-01-01T00:06:00+00:00",
                        "requestID": "request-1",
                        "appGroup": "group.com.serydoo.PhotoMemo",
                        "handoffReady": "false",
                        "userDefaultsSuiteAvailable": "true",
                        "appGroupContainerAvailable": "false",
                        "usesFallbackUserDefaults": "false",
                        "usesFallbackBaseDirectory": "true",
                        "baseDirectory": "/var/mobile/Containers/Data/Application/PhotoMemo",
                    }
                ],
            )
            self.assertIn(
                "## New Shared Container Readiness",
                summarizer.render_markdown(summary),
            )

    def test_new_live_photo_static_payload_events_are_structured(self):
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
                        "id": "event-static-live-photo",
                        "timestamp": 420.0,
                        "stage": "extension.livePhotoRepresentation.staticPayload",
                        "message": (
                            "index=0, requestedType=com.apple.live-photo, "
                            "fileName=IMG_9558.HEIC, contentType=public.jpeg, "
                            "managedPayload=directory, hasStillImage=true, "
                            "hasPairedMovie=false, "
                            "routeWillFallbackToStaticWithoutAssetIdentity=true"
                        ),
                        "requestID": "request-live-photo",
                    }
                ],
            )

            summary = summarizer.build_summary(
                evidence_dir=current,
                baseline_dir=baseline,
                scenario="manual",
            )

            self.assertEqual(
                summary["newLivePhotoStaticPayloadEvents"],
                [
                    {
                        "timestamp": 420.0,
                        "timestampISO": "2001-01-01T00:07:00+00:00",
                        "requestID": "request-live-photo",
                        "index": 0,
                        "requestedType": "com.apple.live-photo",
                        "fileName": "IMG_9558.HEIC",
                        "contentType": "public.jpeg",
                        "managedPayload": "directory",
                        "pathExtension": None,
                        "enumerable": None,
                        "hasStillImage": "true",
                        "hasPairedMovie": "false",
                        "routeWillFallbackToStaticWithoutAssetIdentity": "true",
                    }
                ],
            )
            self.assertIn(
                "## New Live Photo Static Payloads",
                summarizer.render_markdown(summary),
            )

    def test_new_live_photo_identity_recovery_events_are_structured(self):
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
                        "id": "event-recovery",
                        "timestamp": 480.0,
                        "stage": "app.livePhotoIdentityRecovery",
                        "message": (
                            "result=ambiguous, candidateCount=2, "
                            "fileName=IMG_9558.HEIC, fallback=static"
                        ),
                        "requestID": "request-live-photo",
                    }
                ],
            )

            summary = summarizer.build_summary(
                evidence_dir=current,
                baseline_dir=baseline,
                scenario="manual",
            )

            self.assertEqual(
                summary["newLivePhotoIdentityRecoveryEvents"],
                [
                    {
                        "timestamp": 480.0,
                        "timestampISO": "2001-01-01T00:08:00+00:00",
                        "requestID": "request-live-photo",
                        "result": "ambiguous",
                        "fileName": "IMG_9558.HEIC",
                        "contentType": None,
                        "candidateCount": 2,
                        "reason": None,
                        "assetIdentifierRecovered": None,
                        "fallback": "static",
                    }
                ],
            )
            self.assertIn(
                "## New Live Photo Identity Recovery",
                summarizer.render_markdown(summary),
            )

    def test_new_requests_include_live_photo_recovery_hint_counts(self):
        with tempfile.TemporaryDirectory() as current_dir, tempfile.TemporaryDirectory() as baseline_dir:
            current = Path(current_dir)
            baseline = Path(baseline_dir)
            (current / "decoded").mkdir()
            (baseline / "decoded").mkdir()

            self.write_json(baseline / "decoded" / "batchQueue.jobs.json", [])
            self.write_json(baseline / "decoded" / "shareDiagnostics.events.json", [])
            self.write_json(baseline / "decoded" / "externalIntake.requests.json", [])
            self.write_json(current / "decoded" / "batchQueue.jobs.json", [])
            self.write_json(current / "decoded" / "shareDiagnostics.events.json", [])
            self.write_json(
                current / "decoded" / "externalIntake.requests.json",
                [
                    {
                        "id": "request-live-photo",
                        "launchSource": "shareExtension",
                        "receivedAt": 540.0,
                        "items": [
                            {
                                "contentTypeIdentifier": "public.jpeg",
                                "sourceIdentifier": "asset-1",
                                "livePhotoRecoveryHint": {
                                    "originalFileName": "IMG_9558.HEIC"
                                },
                            },
                            {
                                "contentTypeIdentifier": "public.heic",
                                "sourceIdentifier": None,
                            },
                        ],
                    }
                ],
            )

            summary = summarizer.build_summary(
                evidence_dir=current,
                baseline_dir=baseline,
                scenario="manual",
            )

            self.assertEqual(summary["newRequests"][0]["sourceIdentifierCount"], 1)
            self.assertEqual(summary["newRequests"][0]["livePhotoRecoveryHintCount"], 1)

    @staticmethod
    def write_json(path: Path, value):
        path.write_text(json.dumps(value), encoding="utf-8")

    @staticmethod
    def completed_share_job(job_id: str, task_count: int):
        return {
            "id": job_id,
            "title": f"{task_count} photos",
            "launchSource": "shareExtension",
            "state": "completed",
            "createdAt": 100.0,
            "updatedAt": 105.0,
            "tasks": [
                {
                    "id": f"{job_id}-task-{index}",
                    "phase": "completed",
                    "savedAssetIdentifier": f"asset-{index}",
                }
                for index in range(task_count)
            ],
        }

    @staticmethod
    def shared_container_ready_event():
        return {
            "id": "readiness-true",
            "timestamp": 360.0,
            "stage": "app.sharedContainerReadiness",
            "message": (
                "appGroup=group.com.serydoo.PhotoMemo, "
                "handoffReady=true, "
                "userDefaultsSuiteAvailable=true, "
                "appGroupContainerAvailable=true, "
                "usesFallbackUserDefaults=false, "
                "usesFallbackBaseDirectory=false, "
                "baseDirectory=/private/var/mobile/Containers/Shared/AppGroup"
            ),
            "requestID": "request-1",
        }

    @staticmethod
    def task_duration_event(event_id: str, job_id: str, task_id: str):
        return {
            "id": event_id,
            "timestamp": 600.0,
            "stage": "batch.task.duration",
            "message": (
                f"taskID={task_id}, fileName={task_id}.HEIC, "
                "contentType=public.heic, route=staticImage, "
                "runtimeStage=total, phase=completed, durationSeconds=1.234"
            ),
            "jobID": job_id,
        }


if __name__ == "__main__":
    unittest.main()

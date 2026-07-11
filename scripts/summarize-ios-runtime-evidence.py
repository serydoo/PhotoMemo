#!/usr/bin/env python3

"""Summarize MemoMark iOS runtime evidence without copying private media."""

from __future__ import annotations

import argparse
import json
import re
from collections import Counter
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

APPLE_EPOCH_OFFSET = 978307200


def load_json(path: Path, fallback: Any) -> Any:
    if not path.exists():
        return fallback
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except Exception as error:
        return {"decodeError": str(error), "path": str(path)}


def load_array(path: Path) -> list[dict[str, Any]]:
    value = load_json(path, [])
    return value if isinstance(value, list) else []


def format_apple_time(value: Any) -> str | None:
    if not isinstance(value, (int, float)):
        return None
    timestamp = value + APPLE_EPOCH_OFFSET
    return datetime.fromtimestamp(timestamp, timezone.utc).isoformat()


def crash_names(path: Path) -> list[str]:
    if not path.exists():
        return []
    names: list[str] = []
    for line in path.read_text(errors="replace").splitlines():
        match = re.search(r"(PhotoMemo\S+\.ips)", line)
        if match:
            names.append(match.group(1))
    return sorted(set(names))


def phase_counts(tasks: list[dict[str, Any]]) -> dict[str, int]:
    return dict(Counter(str(task.get("phase") or "unknown") for task in tasks))


def job_duration_seconds(job: dict[str, Any]) -> float | None:
    created_at = job.get("createdAt")
    updated_at = job.get("updatedAt")
    if not isinstance(created_at, (int, float)) or not isinstance(updated_at, (int, float)):
        return None
    duration = updated_at - created_at
    if duration < 0:
        return None
    return round(duration, 3)


def saved_tasks_per_minute(saved_task_count: int, duration_seconds: float | None) -> float | None:
    if not duration_seconds or duration_seconds <= 0:
        return None
    return round(saved_task_count / duration_seconds * 60, 2)


def compact_job(job: dict[str, Any]) -> dict[str, Any]:
    tasks = job.get("tasks") if isinstance(job.get("tasks"), list) else []
    saved_task_count = sum(1 for task in tasks if task.get("savedAssetIdentifier"))
    duration_seconds = job_duration_seconds(job)
    return {
        "jobID": job.get("id"),
        "title": job.get("title"),
        "launchSource": job.get("launchSource"),
        "state": job.get("state"),
        "createdAt": job.get("createdAt"),
        "createdAtISO": format_apple_time(job.get("createdAt")),
        "updatedAt": job.get("updatedAt"),
        "updatedAtISO": format_apple_time(job.get("updatedAt")),
        "taskCount": len(tasks),
        "phaseCounts": phase_counts(tasks),
        "savedTaskCount": saved_task_count,
        "durationSeconds": duration_seconds,
        "savedTasksPerMinute": saved_tasks_per_minute(
            saved_task_count=saved_task_count,
            duration_seconds=duration_seconds,
        ),
    }


def compact_event(event: dict[str, Any]) -> dict[str, Any]:
    return {
        "id": event.get("id"),
        "timestamp": event.get("timestamp"),
        "timestampISO": format_apple_time(event.get("timestamp")),
        "stage": event.get("stage"),
        "message": event.get("message"),
        "requestID": event.get("requestID"),
        "jobID": event.get("jobID"),
    }


def compact_request(request: dict[str, Any]) -> dict[str, Any]:
    items = request.get("items") if isinstance(request.get("items"), list) else []
    summary = request.get("importSummary")
    if not isinstance(summary, dict):
        summary = {}
    source_identifier_count = sum(
        1
        for item in items
        if isinstance(item, dict) and item.get("sourceIdentifier")
    )
    live_photo_recovery_hint_count = sum(
        1
        for item in items
        if isinstance(item, dict) and item.get("livePhotoRecoveryHint")
    )

    return {
        "requestID": request.get("id"),
        "launchSource": request.get("launchSource"),
        "receivedAt": request.get("receivedAt"),
        "receivedAtISO": format_apple_time(request.get("receivedAt")),
        "itemCount": len(items),
        "importedCount": summary.get("importedCount"),
        "skippedCount": summary.get("skippedCount"),
        "failedCount": summary.get("failedCount"),
        "sourceIdentifierCount": source_identifier_count,
        "livePhotoRecoveryHintCount": live_photo_recovery_hint_count,
        "contentTypes": sorted(
            {
                str(item.get("contentTypeIdentifier"))
                for item in items
                if item.get("contentTypeIdentifier")
            }
        ),
    }


def parse_key_value_message(message: Any) -> dict[str, str]:
    if not isinstance(message, str):
        return {}
    pairs: dict[str, str] = {}
    for part in re.split(r", (?=[A-Za-z][A-Za-z0-9_]*=)", message):
        key, separator, value = part.partition("=")
        if separator:
            pairs[key] = value
    return pairs


def parse_ordered_key_value_message(
    message: Any,
    keys: list[str],
) -> dict[str, str]:
    if not isinstance(message, str):
        return {}

    pairs: dict[str, str] = {}
    search_start = 0

    for index, key in enumerate(keys):
        key_start = find_delimited_key_start(
            message=message,
            key=key,
            start=search_start,
        )
        if key_start is None:
            continue

        value_start = key_start + len(key) + 1
        next_key_start = None
        for next_key in keys[index + 1:]:
            candidate = find_delimited_key_start(
                message=message,
                key=next_key,
                start=value_start,
            )
            if candidate is not None:
                next_key_start = candidate
                break

        value_end = (
            delimiter_start_for_key(message, next_key_start)
            if next_key_start is not None
            else len(message)
        )
        pairs[key] = message[value_start:value_end].strip()
        search_start = value_end

    return pairs


def find_delimited_key_start(
    message: str,
    key: str,
    start: int,
) -> int | None:
    prefix = f"{key}="
    if start <= 0 and message.startswith(prefix):
        return 0

    pattern = f", {prefix}"
    index = message.find(pattern, max(start, 0))
    if index == -1:
        return None
    return index + 2


def delimiter_start_for_key(
    message: str,
    key_start: int | None,
) -> int:
    if key_start is None:
        return len(message)
    delimiter_start = key_start - 2
    if delimiter_start >= 0 and message[delimiter_start:key_start] == ", ":
        return delimiter_start
    return key_start


def parse_int(value: str | None) -> int | None:
    if value is None:
        return None
    try:
        return int(value)
    except (TypeError, ValueError):
        return None


def compact_live_photo_static_payload_event(
    event: dict[str, Any]
) -> dict[str, Any] | None:
    if event.get("stage") != "extension.livePhotoRepresentation.staticPayload":
        return None

    pairs = parse_key_value_message(event.get("message"))

    return {
        "timestamp": event.get("timestamp"),
        "timestampISO": format_apple_time(event.get("timestamp")),
        "requestID": event.get("requestID"),
        "index": parse_int(pairs.get("index")),
        "requestedType": pairs.get("requestedType"),
        "fileName": pairs.get("fileName"),
        "contentType": pairs.get("contentType"),
        "managedPayload": pairs.get("managedPayload"),
        "pathExtension": pairs.get("pathExtension"),
        "enumerable": pairs.get("enumerable"),
        "hasStillImage": pairs.get("hasStillImage"),
        "hasPairedMovie": pairs.get("hasPairedMovie"),
        "routeWillFallbackToStaticWithoutAssetIdentity": pairs.get(
            "routeWillFallbackToStaticWithoutAssetIdentity"
        ),
    }


def compact_live_photo_identity_recovery_event(
    event: dict[str, Any]
) -> dict[str, Any] | None:
    if event.get("stage") != "app.livePhotoIdentityRecovery":
        return None

    pairs = parse_key_value_message(event.get("message"))

    return {
        "timestamp": event.get("timestamp"),
        "timestampISO": format_apple_time(event.get("timestamp")),
        "requestID": event.get("requestID"),
        "result": pairs.get("result"),
        "fileName": pairs.get("fileName"),
        "contentType": pairs.get("contentType"),
        "candidateCount": parse_int(pairs.get("candidateCount")),
        "reason": pairs.get("reason"),
        "assetIdentifierRecovered": pairs.get("assetIdentifierRecovered"),
        "fallback": pairs.get("fallback"),
    }


def compact_task_admission_event(event: dict[str, Any]) -> dict[str, Any] | None:
    if event.get("stage") != "batch.task.admission":
        return None

    pairs = parse_ordered_key_value_message(
        event.get("message"),
        [
            "taskID",
            "fileName",
            "contentType",
            "isRAW",
            "pixelWidth",
            "pixelHeight",
            "pixelCount",
            "estimatedDecodedByteCount",
            "memoryTier",
            "requiresExtendedPreviewPreparation",
            "maxConcurrentDecodes",
            "maxConcurrentRenders",
            "maxConcurrentExports",
            "schedulerMode",
            "admission",
        ],
    )

    return {
        "timestamp": event.get("timestamp"),
        "timestampISO": format_apple_time(event.get("timestamp")),
        "jobID": event.get("jobID"),
        "taskID": pairs.get("taskID"),
        "fileName": pairs.get("fileName"),
        "contentType": pairs.get("contentType"),
        "isRAW": pairs.get("isRAW"),
        "pixelWidth": parse_int(pairs.get("pixelWidth")),
        "pixelHeight": parse_int(pairs.get("pixelHeight")),
        "pixelCount": parse_int(pairs.get("pixelCount")),
        "estimatedDecodedByteCount": parse_int(
            pairs.get("estimatedDecodedByteCount")
        ),
        "memoryTier": pairs.get("memoryTier"),
        "requiresExtendedPreviewPreparation": pairs.get(
            "requiresExtendedPreviewPreparation"
        ),
        "maxConcurrentDecodes": parse_int(pairs.get("maxConcurrentDecodes")),
        "maxConcurrentRenders": parse_int(pairs.get("maxConcurrentRenders")),
        "maxConcurrentExports": parse_int(pairs.get("maxConcurrentExports")),
        "schedulerMode": pairs.get("schedulerMode"),
        "admission": pairs.get("admission"),
    }


def compact_task_route_event(event: dict[str, Any]) -> dict[str, Any] | None:
    if event.get("stage") != "batch.task.route":
        return None

    pairs = parse_ordered_key_value_message(
        event.get("message"),
        [
            "taskID",
            "fileName",
            "contentType",
            "hasSourceIdentifier",
            "sourceURLIsLivePhotoBundle",
            "route",
        ],
    )

    return {
        "timestamp": event.get("timestamp"),
        "timestampISO": format_apple_time(event.get("timestamp")),
        "jobID": event.get("jobID"),
        "taskID": pairs.get("taskID"),
        "fileName": pairs.get("fileName"),
        "contentType": pairs.get("contentType"),
        "hasSourceIdentifier": pairs.get("hasSourceIdentifier"),
        "sourceURLIsLivePhotoBundle": pairs.get("sourceURLIsLivePhotoBundle"),
        "route": pairs.get("route"),
    }


def compact_shared_container_readiness_event(
    event: dict[str, Any]
) -> dict[str, Any] | None:
    if event.get("stage") != "app.sharedContainerReadiness":
        return None

    pairs = parse_key_value_message(event.get("message"))

    return {
        "timestamp": event.get("timestamp"),
        "timestampISO": format_apple_time(event.get("timestamp")),
        "requestID": event.get("requestID"),
        "appGroup": pairs.get("appGroup"),
        "handoffReady": pairs.get("handoffReady"),
        "userDefaultsSuiteAvailable": pairs.get("userDefaultsSuiteAvailable"),
        "appGroupContainerAvailable": pairs.get("appGroupContainerAvailable"),
        "usesFallbackUserDefaults": pairs.get("usesFallbackUserDefaults"),
        "usesFallbackBaseDirectory": pairs.get("usesFallbackBaseDirectory"),
        "baseDirectory": pairs.get("baseDirectory"),
    }


def compact_task_duration_event(event: dict[str, Any]) -> dict[str, Any] | None:
    if event.get("stage") != "batch.task.duration":
        return None

    pairs = parse_ordered_key_value_message(
        event.get("message"),
        [
            "taskID",
            "fileName",
            "contentType",
            "route",
            "runtimeStage",
            "phase",
            "durationSeconds",
        ],
    )
    duration: float | None = None
    try:
        duration = float(pairs["durationSeconds"])
    except (KeyError, TypeError, ValueError):
        duration = None

    return {
        "timestamp": event.get("timestamp"),
        "timestampISO": format_apple_time(event.get("timestamp")),
        "jobID": event.get("jobID"),
        "taskID": pairs.get("taskID"),
        "fileName": pairs.get("fileName"),
        "contentType": pairs.get("contentType"),
        "route": pairs.get("route"),
        "runtimeStage": pairs.get("runtimeStage"),
        "phase": pairs.get("phase"),
        "durationSeconds": duration,
    }


def compact_task_stage_duration_event(event: dict[str, Any]) -> dict[str, Any] | None:
    if event.get("stage") != "batch.task.stageDuration":
        return None

    pairs = parse_ordered_key_value_message(
        event.get("message"),
        [
            "taskID",
            "fileName",
            "contentType",
            "route",
            "stageName",
            "outcome",
            "durationSeconds",
            "attachmentCreated",
            "isMainThread",
            "peakResidentMemoryBytes",
            "threadName",
        ],
    )
    duration: float | None = None
    try:
        duration = float(pairs["durationSeconds"])
    except (KeyError, TypeError, ValueError):
        duration = None

    return {
        "timestamp": event.get("timestamp"),
        "timestampISO": format_apple_time(event.get("timestamp")),
        "jobID": event.get("jobID"),
        "taskID": pairs.get("taskID"),
        "fileName": pairs.get("fileName"),
        "contentType": pairs.get("contentType"),
        "route": pairs.get("route"),
        "stageName": pairs.get("stageName"),
        "outcome": pairs.get("outcome"),
        "attachmentCreated": pairs.get("attachmentCreated"),
        "isMainThread": pairs.get("isMainThread"),
        "threadName": pairs.get("threadName"),
        "peakResidentMemoryBytes": parse_int(pairs.get("peakResidentMemoryBytes")),
        "durationSeconds": duration,
    }


def evidence_paths(directory: Path) -> dict[str, Path]:
    decoded = directory / "decoded"
    return {
        "events": decoded / "shareDiagnostics.events.json",
        "jobs": decoded / "batchQueue.jobs.json",
        "requests": decoded / "externalIntake.requests.json",
        "crashes": directory / "crash-files.txt",
    }


def load_evidence(directory: Path) -> dict[str, Any]:
    paths = evidence_paths(directory)
    return {
        "directory": str(directory),
        "events": load_array(paths["events"]),
        "jobs": load_array(paths["jobs"]),
        "requests": load_array(paths["requests"]),
        "crashes": crash_names(paths["crashes"]),
    }


def ids(values: list[dict[str, Any]]) -> set[str]:
    return {str(value.get("id")) for value in values if value.get("id")}


def new_values(
    current: list[dict[str, Any]],
    baseline: list[dict[str, Any]],
) -> list[dict[str, Any]]:
    baseline_ids = ids(baseline)
    return [value for value in current if str(value.get("id")) not in baseline_ids]


def build_summary(
    evidence_dir: Path,
    baseline_dir: Path | None,
    scenario: str,
) -> dict[str, Any]:
    current = load_evidence(evidence_dir)
    baseline = load_evidence(baseline_dir) if baseline_dir else None

    jobs = current["jobs"]
    events = current["events"]
    requests = current["requests"]

    if baseline:
        new_jobs = new_values(jobs, baseline["jobs"])
        new_events = new_values(events, baseline["events"])
        new_requests = new_values(requests, baseline["requests"])
        new_crashes = sorted(set(current["crashes"]) - set(baseline["crashes"]))
    else:
        new_jobs = jobs[-5:]
        new_events = events[-30:]
        new_requests = requests[-5:]
        new_crashes = current["crashes"]

    compact_jobs = [compact_job(job) for job in jobs[-5:]]
    compact_new_jobs = [compact_job(job) for job in new_jobs]
    compact_new_events = [compact_event(event) for event in new_events[-30:]]
    compact_new_task_durations = [
        duration
        for event in new_events
        if (duration := compact_task_duration_event(event)) is not None
    ]
    compact_new_task_admission_events = [
        admission
        for event in new_events
        if (admission := compact_task_admission_event(event)) is not None
    ]
    compact_new_task_route_events = [
        route
        for event in new_events
        if (route := compact_task_route_event(event)) is not None
    ]
    compact_new_shared_container_readiness_events = [
        readiness
        for event in new_events
        if (
            readiness := compact_shared_container_readiness_event(event)
        ) is not None
    ]
    compact_new_live_photo_static_payload_events = [
        static_payload
        for event in new_events
        if (
            static_payload := compact_live_photo_static_payload_event(event)
        ) is not None
    ]
    compact_new_live_photo_identity_recovery_events = [
        recovery
        for event in new_events
        if (
            recovery := compact_live_photo_identity_recovery_event(event)
        ) is not None
    ]
    compact_new_task_stage_durations = [
        duration
        for event in new_events
        if (duration := compact_task_stage_duration_event(event)) is not None
    ]

    evaluation = evaluate_scenario(
        scenario=scenario,
        new_jobs=compact_new_jobs,
        new_events=new_events,
        new_requests=new_requests,
        new_crashes=new_crashes,
    )

    return {
        "evidenceDir": str(evidence_dir),
        "baselineDir": str(baseline_dir) if baseline_dir else None,
        "scenario": scenario,
        "counts": {
            "shareEventCount": len(events),
            "requestCount": len(requests),
            "jobCount": len(jobs),
            "crashCount": len(current["crashes"]),
            "newShareEventCount": len(new_events),
            "newRequestCount": len(new_requests),
            "newJobCount": len(new_jobs),
            "newCrashCount": len(new_crashes),
        },
        "latestJobs": compact_jobs,
        "newJobs": compact_new_jobs,
        "newShareEventsTail": compact_new_events,
        "newTaskDurations": compact_new_task_durations,
        "newTaskAdmissionEvents": compact_new_task_admission_events,
        "newTaskRouteEvents": compact_new_task_route_events,
        "newSharedContainerReadinessEvents": (
            compact_new_shared_container_readiness_events
        ),
        "newLivePhotoStaticPayloadEvents": (
            compact_new_live_photo_static_payload_events
        ),
        "newLivePhotoIdentityRecoveryEvents": (
            compact_new_live_photo_identity_recovery_events
        ),
        "newTaskStageDurations": compact_new_task_stage_durations,
        "newRequests": [
            compact_request(request)
            for request in new_requests
        ],
        "newRequestIDs": [request.get("id") for request in new_requests],
        "newCrashes": new_crashes,
        "evaluation": evaluation,
    }


def evaluate_scenario(
    scenario: str,
    new_jobs: list[dict[str, Any]],
    new_events: list[dict[str, Any]],
    new_requests: list[dict[str, Any]],
    new_crashes: list[str],
) -> dict[str, Any]:
    if scenario == "baseline":
        return {
            "status": "informational",
            "reason": "Baseline collection does not assert a user flow.",
        }

    if scenario in {"share-1", "share-20"}:
        expected_count = 1 if scenario == "share-1" else 20
        matching = [
            job
            for job in new_jobs
            if job.get("launchSource") == "shareExtension"
            and job.get("taskCount") == expected_count
        ]
        if not matching:
            return {
                "status": "fail",
                "reason": (
                    f"No new shareExtension job with taskCount={expected_count} "
                    "was found relative to the baseline."
                ),
            }
        readiness_events = [
            readiness
            for event in new_events
            if (
                readiness := compact_shared_container_readiness_event(event)
            ) is not None
        ]
        if any(
            readiness.get("handoffReady") == "false"
            for readiness in readiness_events
        ):
            return {
                "status": "fail",
                "reason": (
                    "A signed Share run recorded shared-container "
                    "readiness with handoffReady=false."
                ),
            }
        if not readiness_events:
            return {
                "status": "needs-review",
                "reason": (
                    "No new shared-container readiness event was found; "
                    "signed App Group handoff evidence needs review."
                ),
            }
        completed = [
            job
            for job in matching
            if job.get("state") == "completed"
            and job.get("phaseCounts", {}).get("completed") == expected_count
            and job.get("savedTaskCount") == expected_count
        ]
        completed_with_durations = [
            job
            for job in completed
            if completed_task_duration_count_for_job(
                new_events=new_events,
                job=job,
            ) >= expected_count
        ]
        if completed and not completed_with_durations:
            return {
                "status": "needs-review",
                "reason": (
                    f"Found completed shareExtension job with {expected_count} "
                    "saved task(s), but per-task duration evidence is missing "
                    "or incomplete."
                ),
            }
        if completed_with_durations and not new_crashes:
            return {
                "status": "pass",
                "reason": (
                    f"Found completed shareExtension job with {expected_count} "
                    "saved task(s), matching task duration evidence, and no "
                    "new PhotoMemo crash."
                ),
            }
        return {
            "status": "needs-review",
            "reason": (
                f"Found shareExtension job with taskCount={expected_count}, "
                "but completion/save/crash evidence still needs review."
            ),
        }

    if scenario == "share-21-reject":
        if new_jobs or new_requests:
            return {
                "status": "fail",
                "reason": (
                    "A 21-photo rejection run should not create new handoff "
                    "requests or batch jobs relative to the baseline."
                ),
            }
        if new_crashes:
            return {
                "status": "fail",
                "reason": "A new PhotoMemo crash appeared during the rejection run.",
            }
        too_many_events = [
            event
            for event in new_events
            if event.get("stage") == "extension.input.tooManyPhotos"
        ]
        if too_many_events:
            return {
                "status": "pass",
                "reason": (
                    "The Share Extension recorded the too-many-photos "
                    "preflight rejection, and no new handoff request, batch "
                    "job, or PhotoMemo crash was found relative to the baseline."
                ),
            }
        return {
            "status": "needs-review",
            "reason": (
                "No new handoff request, batch job, or PhotoMemo crash was "
                "found relative to the baseline, but no "
                "extension.input.tooManyPhotos diagnostic event was found. "
                "Confirm the UI showed the split-batch rejection copy."
            ),
        }

    if scenario == "share-livephoto-1":
        readiness_result = evaluate_shared_container_readiness(new_events)
        if readiness_result is not None:
            return readiness_result
        if new_crashes:
            return {
                "status": "fail",
                "reason": "A new PhotoMemo crash appeared during the single Live Photo Share run.",
            }

        completed_jobs = [
            job
            for job in completed_share_extension_jobs(new_jobs)
            if job.get("taskCount") == 1
        ]
        if not completed_jobs:
            return {
                "status": "fail",
                "reason": "No completed one-task shareExtension job was found for the single Live Photo Share run.",
            }

        route_events = task_route_events_for_jobs(
            new_events,
            completed_jobs,
        )
        if not route_events:
            return {
                "status": "needs-review",
                "reason": (
                    "No task route evidence was found for the completed "
                    "single Live Photo Share job."
                ),
            }
        if any(route.get("route") == "staticImage" for route in route_events):
            return {
                "status": "fail",
                "reason": (
                    "Single Live Photo Share completed, but route evidence "
                    "shows static fallback instead of livePhoto."
                ),
            }
        live_route_job_ids = {
            route.get("jobID")
            for route in route_events
            if route.get("route") == "livePhoto"
        }
        if not live_route_job_ids:
            return {
                "status": "fail",
                "reason": "Single Live Photo Share route evidence did not include livePhoto.",
            }

        completed_live_route_jobs_with_durations = [
            job
            for job in completed_jobs
            if job.get("jobID") in live_route_job_ids
            if completed_task_duration_count_for_job(
                new_events=new_events,
                job=job,
            ) >= (job.get("taskCount") or 0)
        ]
        if not completed_live_route_jobs_with_durations:
            return {
                "status": "needs-review",
                "reason": (
                    "The completed single Live Photo Share job is missing "
                    "matching task duration evidence."
                ),
            }
        return {
            "status": "pass",
            "reason": (
                "Completed Share run includes a single Live Photo route, "
                "matching task duration evidence, and no new PhotoMemo "
                "crash."
            ),
        }

    if scenario == "share-livephoto-mixed":
        readiness_result = evaluate_shared_container_readiness(new_events)
        if readiness_result is not None:
            return readiness_result
        if new_crashes:
            return {
                "status": "fail",
                "reason": "A new PhotoMemo crash appeared during the mixed Live Photo Share run.",
            }

        completed_jobs = completed_share_extension_jobs(new_jobs)
        if not completed_jobs:
            return {
                "status": "fail",
                "reason": "No completed shareExtension job was found for the mixed Live Photo Share run.",
            }

        route_events = task_route_events_for_jobs(
            new_events,
            completed_jobs,
        )
        if not route_events:
            return {
                "status": "needs-review",
                "reason": (
                    "No task route evidence was found for the completed Share "
                    "job; mixed Live Photo Share routing needs review."
                ),
            }
        route_events_by_job_id: dict[Any, list[dict[str, Any]]] = {}
        for route in route_events:
            route_events_by_job_id.setdefault(route.get("jobID"), []).append(route)
        mixed_route_job_ids = {
            job_id
            for job_id, job_routes in route_events_by_job_id.items()
            if "livePhoto" in {route.get("route") for route in job_routes}
            and any(route.get("route") != "livePhoto" for route in job_routes)
        }
        if not mixed_route_job_ids:
            return {
                "status": "fail",
                "reason": (
                    "Mixed Live Photo Share route evidence for the completed Share "
                    "job did not include both a livePhoto route and a still-image route."
                ),
            }

        completed_mixed_route_jobs_with_durations = [
            job
            for job in completed_jobs
            if job.get("jobID") in mixed_route_job_ids
            if completed_task_duration_count_for_job(
                new_events=new_events,
                job=job,
            ) >= (job.get("taskCount") or 0)
        ]
        if not completed_mixed_route_jobs_with_durations:
            return {
                "status": "needs-review",
                "reason": (
                    "The completed mixed Live Photo Share job is missing "
                    "matching task duration evidence."
                ),
            }
        return {
            "status": "pass",
            "reason": (
                "Completed Share run includes both Live Photo and still "
                "routes, matching task duration evidence, and no new "
                "PhotoMemo crash."
            ),
        }

    if scenario == "share-48mp":
        readiness_result = evaluate_shared_container_readiness(new_events)
        if readiness_result is not None:
            return readiness_result
        if new_crashes:
            return {
                "status": "fail",
                "reason": "A new PhotoMemo crash appeared during the 48MP Share run.",
            }

        completed_jobs = completed_share_extension_jobs(new_jobs)
        if not completed_jobs:
            return {
                "status": "fail",
                "reason": "No completed shareExtension job was found for the 48MP Share run.",
            }
        completed_jobs_with_durations = [
            job
            for job in completed_jobs
            if completed_task_duration_count_for_job(
                new_events=new_events,
                job=job,
            ) >= (job.get("taskCount") or 0)
        ]
        if not completed_jobs_with_durations:
            return {
                "status": "needs-review",
                "reason": (
                    "The completed 48MP Share job is missing matching task "
                    "duration evidence."
                ),
            }

        completed_job_ids_with_durations = {
            job.get("jobID")
            for job in completed_jobs_with_durations
        }
        admissions = [
            admission
            for event in new_events
            if (admission := compact_task_admission_event(event)) is not None
            and admission.get("jobID") in completed_job_ids_with_durations
        ]
        critical_admissions = [
            admission
            for admission in admissions
            if (admission.get("pixelCount") or 0) >= 48_000_000
        ]
        if not critical_admissions:
            return {
                "status": "needs-review",
                "reason": "No 48MP task admission evidence was found for this Share run.",
            }

        single_lane_admissions = [
            admission
            for admission in critical_admissions
            if admission.get("memoryTier") == "critical"
            and admission.get("schedulerMode") == "singleTaskLoop"
            and admission.get("maxConcurrentDecodes") == 1
            and admission.get("maxConcurrentRenders") == 1
            and admission.get("maxConcurrentExports") == 1
        ]
        if single_lane_admissions:
            return {
                "status": "pass",
                "reason": (
                    "48MP admission evidence used critical single-lane "
                    "scheduling, the Share job completed with matching task "
                    "duration evidence, and no new PhotoMemo crash was found."
                ),
            }

        return {
            "status": "fail",
            "reason": (
                "48MP admission evidence was present but did not use critical "
                "single-lane scheduling."
            ),
        }

    return {
        "status": "informational",
        "reason": "Unknown scenario; summary generated without pass/fail rules.",
    }


def completed_share_extension_jobs(
    new_jobs: list[dict[str, Any]]
) -> list[dict[str, Any]]:
    return [
        job
        for job in new_jobs
        if job.get("launchSource") == "shareExtension"
        and job.get("state") == "completed"
        and job.get("taskCount") == job.get("savedTaskCount")
        and job.get("phaseCounts", {}).get("completed") == job.get("taskCount")
    ]


def task_route_events_for_jobs(
    new_events: list[dict[str, Any]],
    jobs: list[dict[str, Any]],
) -> list[dict[str, Any]]:
    job_ids = {job.get("jobID") for job in jobs}
    return [
        route
        for event in new_events
        if (route := compact_task_route_event(event)) is not None
        and route.get("jobID") in job_ids
    ]


def completed_task_duration_count_for_job(
    new_events: list[dict[str, Any]],
    job: dict[str, Any],
) -> int:
    task_ids = {
        duration.get("taskID")
        for event in new_events
        if (duration := compact_task_duration_event(event)) is not None
        and duration.get("jobID") == job.get("jobID")
        and duration.get("runtimeStage") == "total"
        and duration.get("phase") == "completed"
        and duration.get("durationSeconds") is not None
        and duration.get("taskID")
    }
    return len(task_ids)


def evaluate_shared_container_readiness(
    new_events: list[dict[str, Any]]
) -> dict[str, Any] | None:
    readiness_events = [
        readiness
        for event in new_events
        if (readiness := compact_shared_container_readiness_event(event)) is not None
    ]
    if any(
        readiness.get("handoffReady") == "false"
        for readiness in readiness_events
    ):
        return {
            "status": "fail",
            "reason": (
                "A signed Share run recorded shared-container readiness with "
                "handoffReady=false."
            ),
        }
    if not readiness_events:
        return {
            "status": "needs-review",
            "reason": (
                "No new shared-container readiness event was found; signed "
                "App Group handoff evidence needs review."
            ),
        }
    return None


def render_markdown(summary: dict[str, Any]) -> str:
    counts = summary["counts"]
    evaluation = summary["evaluation"]
    lines = [
        "# MemoMark Runtime Evidence Summary",
        "",
        f"- Evidence: `{summary['evidenceDir']}`",
        f"- Baseline: `{summary['baselineDir'] or 'none'}`",
        f"- Scenario: `{summary['scenario']}`",
        f"- Evaluation: `{evaluation['status']}` - {evaluation['reason']}",
        "",
        "## Counts",
        "",
        f"- Share events: {counts['shareEventCount']} "
        f"(new: {counts['newShareEventCount']})",
        f"- External intake requests: {counts['requestCount']} "
        f"(new: {counts['newRequestCount']})",
        f"- Batch jobs: {counts['jobCount']} (new: {counts['newJobCount']})",
        f"- PhotoMemo crashes: {counts['crashCount']} "
        f"(new: {counts['newCrashCount']})",
        "",
        "## New Jobs",
        "",
    ]

    if summary["newJobs"]:
        for job in summary["newJobs"]:
            lines.append(
                "- "
                f"`{job.get('jobID')}` "
                f"source={job.get('launchSource')} "
                f"state={job.get('state')} "
                f"tasks={job.get('taskCount')} "
                f"saved={job.get('savedTaskCount')} "
                f"duration={job.get('durationSeconds')}s "
                f"throughput={job.get('savedTasksPerMinute')}/min "
                f"phases={job.get('phaseCounts')}"
            )
    else:
        lines.append("- none")

    lines.extend(["", "## New Requests", ""])
    if summary["newRequests"]:
        for request in summary["newRequests"]:
            lines.append(
                "- "
                f"`{request.get('requestID')}` "
                f"source={request.get('launchSource')} "
                f"items={request.get('itemCount')} "
                f"imported={request.get('importedCount')} "
                f"skipped={request.get('skippedCount')} "
                f"failed={request.get('failedCount')} "
                f"sourceIDs={request.get('sourceIdentifierCount')} "
                f"recoveryHints={request.get('livePhotoRecoveryHintCount')} "
                f"types={request.get('contentTypes')}"
            )
    else:
        lines.append("- none")

    lines.extend(["", "## New Task Durations", ""])
    if summary["newTaskDurations"]:
        for duration in summary["newTaskDurations"]:
            lines.append(
                "- "
                f"{duration.get('timestampISO') or duration.get('timestamp')}: "
                f"job={duration.get('jobID')} "
                f"task={duration.get('taskID')} "
                f"route={duration.get('route')} "
                f"stage={duration.get('runtimeStage')} "
                f"phase={duration.get('phase')} "
                f"duration={duration.get('durationSeconds')}s"
            )
    else:
        lines.append("- none")

    lines.extend(["", "## New Task Route Events", ""])
    if summary["newTaskRouteEvents"]:
        for route in summary["newTaskRouteEvents"]:
            lines.append(
                "- "
                f"{route.get('timestampISO') or route.get('timestamp')}: "
                f"job={route.get('jobID')} "
                f"task={route.get('taskID')} "
                f"file={route.get('fileName')} "
                f"type={route.get('contentType')} "
                f"sourceID={route.get('hasSourceIdentifier')} "
                f"sourceBundle={route.get('sourceURLIsLivePhotoBundle')} "
                f"route={route.get('route')}"
            )
    else:
        lines.append("- none")

    lines.extend(["", "## New Task Admission Events", ""])
    if summary["newTaskAdmissionEvents"]:
        for admission in summary["newTaskAdmissionEvents"]:
            lines.append(
                "- "
                f"{admission.get('timestampISO') or admission.get('timestamp')}: "
                f"job={admission.get('jobID')} "
                f"task={admission.get('taskID')} "
                f"file={admission.get('fileName')} "
                f"type={admission.get('contentType')} "
                f"raw={admission.get('isRAW')} "
                f"pixels={admission.get('pixelWidth')}x{admission.get('pixelHeight')} "
                f"tier={admission.get('memoryTier')} "
                f"decodedBytes={admission.get('estimatedDecodedByteCount')} "
                f"scheduler={admission.get('schedulerMode')} "
                f"admission={admission.get('admission')}"
            )
    else:
        lines.append("- none")

    lines.extend(["", "## New Shared Container Readiness", ""])
    if summary["newSharedContainerReadinessEvents"]:
        for readiness in summary["newSharedContainerReadinessEvents"]:
            lines.append(
                "- "
                f"{readiness.get('timestampISO') or readiness.get('timestamp')}: "
                f"request={readiness.get('requestID')} "
                f"handoffReady={readiness.get('handoffReady')} "
                f"defaults={readiness.get('userDefaultsSuiteAvailable')} "
                f"container={readiness.get('appGroupContainerAvailable')} "
                f"fallbackDefaults={readiness.get('usesFallbackUserDefaults')} "
                f"fallbackDirectory={readiness.get('usesFallbackBaseDirectory')} "
                f"baseDirectory={readiness.get('baseDirectory')}"
            )
    else:
        lines.append("- none")

    lines.extend(["", "## New Live Photo Static Payloads", ""])
    if summary["newLivePhotoStaticPayloadEvents"]:
        for payload in summary["newLivePhotoStaticPayloadEvents"]:
            lines.append(
                "- "
                f"{payload.get('timestampISO') or payload.get('timestamp')}: "
                f"request={payload.get('requestID')} "
                f"index={payload.get('index')} "
                f"file={payload.get('fileName')} "
                f"type={payload.get('contentType')} "
                f"requested={payload.get('requestedType')} "
                f"payload={payload.get('managedPayload')} "
                f"ext={payload.get('pathExtension')} "
                f"enumerable={payload.get('enumerable')} "
                f"still={payload.get('hasStillImage')} "
                f"movie={payload.get('hasPairedMovie')} "
                f"fallbackStatic={payload.get('routeWillFallbackToStaticWithoutAssetIdentity')}"
            )
    else:
        lines.append("- none")

    lines.extend(["", "## New Live Photo Identity Recovery", ""])
    if summary["newLivePhotoIdentityRecoveryEvents"]:
        for recovery in summary["newLivePhotoIdentityRecoveryEvents"]:
            lines.append(
                "- "
                f"{recovery.get('timestampISO') or recovery.get('timestamp')}: "
                f"request={recovery.get('requestID')} "
                f"result={recovery.get('result')} "
                f"file={recovery.get('fileName')} "
                f"type={recovery.get('contentType')} "
                f"candidates={recovery.get('candidateCount')} "
                f"assetRecovered={recovery.get('assetIdentifierRecovered')} "
                f"fallback={recovery.get('fallback')} "
                f"reason={recovery.get('reason')}"
            )
    else:
        lines.append("- none")

    lines.extend(["", "## New Task Stage Durations", ""])
    if summary["newTaskStageDurations"]:
        for duration in summary["newTaskStageDurations"]:
            lines.append(
                "- "
                f"{duration.get('timestampISO') or duration.get('timestamp')}: "
                f"job={duration.get('jobID')} "
                f"task={duration.get('taskID')} "
                f"route={duration.get('route')} "
                f"stage={duration.get('stageName')} "
                f"outcome={duration.get('outcome')} "
                f"attachmentCreated={duration.get('attachmentCreated')} "
                f"mainThread={duration.get('isMainThread')} "
                f"thread={duration.get('threadName')} "
                f"peakRSS={duration.get('peakResidentMemoryBytes')} "
                f"duration={duration.get('durationSeconds')}s"
            )
    else:
        lines.append("- none")

    lines.extend(["", "## New Share Event Tail", ""])
    if summary["newShareEventsTail"]:
        for event in summary["newShareEventsTail"]:
            lines.append(
                "- "
                f"{event.get('timestampISO') or event.get('timestamp')}: "
                f"`{event.get('stage')}` "
                f"{event.get('message') or ''}"
            )
    else:
        lines.append("- none")

    lines.extend(["", "## New Crashes", ""])
    if summary["newCrashes"]:
        lines.extend(f"- `{name}`" for name in summary["newCrashes"])
    else:
        lines.append("- none")

    return "\n".join(lines) + "\n"


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Summarize MemoMark iOS runtime evidence.",
    )
    parser.add_argument("evidence_dir", type=Path)
    parser.add_argument("--baseline", type=Path)
    parser.add_argument(
        "--scenario",
        choices=[
            "baseline",
            "share-1",
            "share-20",
            "share-21-reject",
            "share-livephoto-1",
            "share-livephoto-mixed",
            "share-48mp",
            "manual",
        ],
        default="manual",
    )
    parser.add_argument(
        "--write",
        action="store_true",
        help="Write runtime-evidence-summary.json and .md into evidence_dir.",
    )
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    summary = build_summary(
        evidence_dir=args.evidence_dir,
        baseline_dir=args.baseline,
        scenario=args.scenario,
    )
    markdown = render_markdown(summary)

    if args.write:
        args.evidence_dir.mkdir(parents=True, exist_ok=True)
        (args.evidence_dir / "runtime-evidence-summary.json").write_text(
            json.dumps(summary, ensure_ascii=False, indent=2),
            encoding="utf-8",
        )
        (args.evidence_dir / "runtime-evidence-summary.md").write_text(
            markdown,
            encoding="utf-8",
        )

    print(markdown, end="")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

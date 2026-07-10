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

    return {
        "requestID": request.get("id"),
        "launchSource": request.get("launchSource"),
        "receivedAt": request.get("receivedAt"),
        "receivedAtISO": format_apple_time(request.get("receivedAt")),
        "itemCount": len(items),
        "importedCount": summary.get("importedCount"),
        "skippedCount": summary.get("skippedCount"),
        "failedCount": summary.get("failedCount"),
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
    for part in message.split(", "):
        key, separator, value = part.partition("=")
        if separator:
            pairs[key] = value
    return pairs


def compact_task_duration_event(event: dict[str, Any]) -> dict[str, Any] | None:
    if event.get("stage") != "batch.task.duration":
        return None

    pairs = parse_key_value_message(event.get("message"))
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
        "phase": pairs.get("phase"),
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

    evaluation = evaluate_scenario(
        scenario=scenario,
        new_jobs=compact_new_jobs,
        new_events=compact_new_events,
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
        completed = [
            job
            for job in matching
            if job.get("state") == "completed"
            and job.get("phaseCounts", {}).get("completed") == expected_count
            and job.get("savedTaskCount") == expected_count
        ]
        if completed and not new_crashes:
            return {
                "status": "pass",
                "reason": (
                    f"Found completed shareExtension job with {expected_count} "
                    "saved task(s), and no new PhotoMemo crash."
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
            "status": "pass",
            "reason": (
                "No new handoff request, batch job, or PhotoMemo crash was "
                "found relative to the baseline. Confirm the UI showed the "
                "split-batch rejection copy."
            ),
        }

    return {
        "status": "informational",
        "reason": "Unknown scenario; summary generated without pass/fail rules.",
    }


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
                f"phase={duration.get('phase')} "
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
        choices=["baseline", "share-1", "share-20", "share-21-reject", "manual"],
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

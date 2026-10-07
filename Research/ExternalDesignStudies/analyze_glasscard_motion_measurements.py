#!/usr/bin/env python3
"""Summarize the existing large-output test attachment; never infer device gates."""
import argparse
import json
import math
from pathlib import Path


def summarize(rows):
    if not isinstance(rows, list) or not rows:
        raise ValueError("Expected a nonempty measurement array")
    required = ("width", "height", "sourceFrames", "sourceFPS", "exportSeconds",
                "processLifetimePeakRSSBeforeBytes", "processLifetimePeakRSSAfterBytes",
                "stillMaterialMotionInteriorMaxChannelDelta", "outputBytes")
    result = []
    for row in rows:
        if not isinstance(row, dict):
            raise ValueError("Expected a measurement object")
        for key in required:
            value = row.get(key)
            if isinstance(value, bool) or not isinstance(value, (int, float)) or not math.isfinite(value):
                raise ValueError(f"Missing or invalid measurement: {key}")
            if value < 0:
                raise ValueError(f"Negative measurement: {key}")
        if any(row[key] <= 0 for key in ("width", "height", "sourceFrames", "sourceFPS")):
            raise ValueError("Geometry, frame count and frame rate must be positive")
        before = row["processLifetimePeakRSSBeforeBytes"]
        after = row["processLifetimePeakRSSAfterBytes"]
        if after < before:
            raise ValueError("Process lifetime high-water mark cannot decrease")
        seconds = row["sourceFrames"] / row["sourceFPS"]
        result.append({
            "width": row["width"], "height": row["height"],
            "sourceFrames": row["sourceFrames"], "sourceFPS": row["sourceFPS"],
            "syntheticSourceSeconds": seconds,
            "exportSeconds": row["exportSeconds"],
            "exportSecondsPerSourceSecond": row["exportSeconds"] / seconds,
            "processLifetimePeakAfterMiB": after / 1024**2,
            "processHighWaterMarkIncreaseMiB": (after - before) / 1024**2,
            "stillMaterialMotionInteriorMaxChannelDelta": row["stillMaterialMotionInteriorMaxChannelDelta"],
            "outputBytes": row["outputBytes"],
        })
    return result


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("measurements", type=Path, help="Exported large-output-cost-and-parity.json attachment")
    args = parser.parse_args()
    try:
        rows = summarize(json.loads(args.measurements.read_text()))
    except (OSError, ValueError) as error:
        parser.error(str(error))
    print(json.dumps({
        "schema": "glasscard-motion-measurements-v1",
        "evidence": str(args.measurements.resolve()),
        "scope": "Host synthetic SDR export; four frames per input in the existing study",
        "limitations": [
            "Lifetime process RSS is not per-export peak allocation or physical-device memory",
            "Low-FPS flat backgrounds do not establish 30/60-FPS textured motion performance",
            "No audio, PhotoKit, real paired-resource, HDR or wide-color acceptance is inferred",
            "No frame-level MainActor timing is measured",
        ],
        "measurements": rows,
    }, indent=2, allow_nan=False))


if __name__ == "__main__":
    main()

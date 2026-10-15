"""Summarize exported attachments from the research-only Swift probe.

Usage: python3 analyze_glasscard_appearance.py ATTACHMENT_DIRECTORY OUTPUT_DIRECTORY
Uses only synthetic probe measurements; never reads private photo sources.
"""
import csv
import json
import math
from pathlib import Path
import shutil
import sys


def luminance(gray):
    return gray / 12.92 if gray <= 0.04045 else ((gray + 0.055) / 1.055) ** 2.4


def contrast(alpha, ink_alpha, linear_compositing=False):
    # Uniform white source + black rail + white ink. Simplified model excludes
    # actual shadows, color conversion, glyph coverage and quantization.
    substrate = 1 - alpha
    foreground = ink_alpha + substrate * (1 - ink_alpha)
    if not linear_compositing:
        substrate, foreground = luminance(substrate), luminance(foreground)
    return (foreground + 0.05) / (substrate + 0.05)


def alpha_bound(ink_alpha, linear_compositing):
    low, high = 0.0, 1.0
    for _ in range(60):
        mid = (low + high) / 2
        if contrast(mid, ink_alpha, linear_compositing) >= 4.5:
            high = mid
        else:
            low = mid
    return high


def main():
    source, target = map(Path, sys.argv[1:3])
    target.mkdir(parents=True, exist_ok=True)
    for test in json.loads((source / "manifest.json").read_text()):
        for attachment in test["attachments"]:
            name = attachment["suggestedHumanReadableName"].split("_0_")[0]
            extension = Path(attachment["exportedFileName"]).suffix
            destination = target / (name if name.endswith(extension) else name + extension)
            shutil.copy2(source / attachment["exportedFileName"], destination)
    pixels = list(csv.DictReader((target / "material-pixels.csv").open()))
    fits = list(csv.DictReader((target / "text-fit-matrix.csv").open()))
    groups = {}
    for row in fits:
        key = tuple(row[x] for x in ("language", "repetitions", "orientation", "slot"))
        groups.setdefault(key, []).append(row)
    mismatches = []
    max_ratio_span = 0.0
    for key, values in groups.items():
        if len({row["outcome"] for row in values}) > 1:
            mismatches.append({"case": key, "measurements": values})
        sizes = [float(row["normalizedPointSize"]) for row in values]
        max_ratio_span = max(max_ratio_span, max(sizes) / min(sizes) - 1)
    size_counts = {}
    for edge in ("360", "1080", "4284"):
        selected = [row for row in fits if row["shortEdge"] == edge]
        size_counts[edge] = {outcome: sum(row["outcome"] == outcome for row in selected) for outcome in ("fits", "overflow")}
    geometry = []
    for width, height in ((360, 480), (480, 360), (1080, 1440), (1440, 1080), (4284, 5712)):
        edge = min(width, height)
        panel_h = edge * 0.13
        panel_w = width - edge * 0.036
        # Capsule = rectangle minus two square corner areas plus a circle.
        area = panel_w * panel_h - (4 - math.pi) * (panel_h / 2) ** 2
        top = math.floor(height - edge * 0.016 - panel_h - panel_h * 0.08 * 3)
        geometry.append({"canvas": [width, height], "panelHeight": panel_h,
            "panelAreaFraction": area / (width * height),
            "overlayRGBABytes": width * (height - top) * 4,
            "basePrimarySize": panel_h * 0.165 * 1.12,
            "baseSecondarySize": panel_h * 0.135 * 1.04,
            "minimumPrimarySize": panel_h * 0.165 * 1.12 * 0.72,
            "minimumSecondarySize": panel_h * 0.135 * 1.04 * 0.70})
    report = {
        "status": "research measurements, not device or material acceptance",
        "pixelRows": len(pixels), "fitRows": len(fits), "scaleGroups": len(groups),
        "fitCountsByShortEdge": size_counts, "outcomeScaleMismatches": mismatches,
        "largestNormalizedFontSizeSpan": max_ratio_span,
        "whiteBackgroundMeasurements": [row for row in pixels if row["sourceGray"] == "255"],
        "simplifiedAlphaBoundsFor4_5": {mode: {str(ink): alpha_bound(ink, linear) for ink in (0.96, 0.78, 1.0)}
            for mode, linear in (("encoded_sRGB_blend", False), ("linear_light_blend", True))},
        "geometryDerivedFromCurrentTokens": geometry,
    }
    (target / "summary.json").write_text(json.dumps(report, indent=2, ensure_ascii=False) + "\n")
    print(json.dumps(report, indent=2, ensure_ascii=False))


if __name__ == "__main__":
    main()

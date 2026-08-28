#!/usr/bin/env python3
"""Check the small, stable invariants of MemoMark's Codex governance files."""

from __future__ import annotations

import argparse
from pathlib import Path


DEFAULT_REQUIRED_FILES = {
    "AGENTS.md",
    "AI_CONTEXT.md",
    "Docs/CURRENT_BRIEF.md",
    "Docs/03_Engineering/2026-08-28-codex-governance-spec.md",
    "Docs/03_Engineering/2026-08-28-github-ios-skills-research.md",
    ".codex/skills/memomark-quality-gates/SKILL.md",
}


def collect_findings(
    root: Path, *, required_files: set[str] | None = None
) -> list[str]:
    findings: list[str] = []
    required = DEFAULT_REQUIRED_FILES if required_files is None else required_files

    for relative in sorted(required):
        if not (root / relative).is_file():
            findings.append(f"missing: {relative}")

    def read(relative: str) -> str:
        path = root / relative
        return path.read_text(encoding="utf-8") if path.is_file() else ""

    agents = read("AGENTS.md")
    ai_context = read("AI_CONTEXT.md")
    if "Docs/CURRENT_BRIEF.md" not in agents:
        findings.append("AGENTS.md does not route through Docs/CURRENT_BRIEF.md")
    if "Docs/CURRENT_BRIEF.md" not in ai_context:
        findings.append("AI_CONTEXT.md does not route through Docs/CURRENT_BRIEF.md")
    if "github-ios-skills-research.md" not in read("Docs/CURRENT_BRIEF.md"):
        findings.append("current brief does not route through GitHub iOS/Apple Skill research")

    skill_paths = {
        "ui": ".codex/skills/memomark-ui-reviewer/SKILL.md",
        "product": ".codex/skills/memomark-product-manager/SKILL.md",
        "release": ".codex/skills/memomark-release-readiness/SKILL.md",
        "renderer": ".codex/skills/memomark-renderer-contract/SKILL.md",
        "media": ".codex/skills/memomark-media-fidelity/SKILL.md",
    }
    skill_text = {name: read(path) for name, path in skill_paths.items()}

    for name, text in skill_text.items():
        if "Source/PhotoMemo/" in text:
            findings.append(f"{name} skill contains retired Source/PhotoMemo path")

    if "/Users/rui/Desktop/PhotoMemo" in skill_text["release"]:
        findings.append("release skill contains a fixed local checkout path")
    for stale in ("Docs/PRODUCT_SPEC.md", "Docs/MVP.md", "Docs/DEVELOPMENT_PLAN.md"):
        if stale in skill_text["product"]:
            findings.append(f"product skill routes through historical source: {stale}")
    if "explicitly authorized the push" not in skill_text["release"]:
        findings.append("release skill does not require explicit push authorization")
    simulator = read(".codex/skills/ios-simulator/SKILL.md")
    if "not substitutes for required signed physical-device acceptance" not in simulator:
        findings.append("ios-simulator skill lacks the MemoMark physical-device boundary")
    quality = read(".codex/skills/memomark-quality-gates/SKILL.md")
    if "load only for substantial UI or release audits" not in read("Docs/CURRENT_BRIEF.md"):
        findings.append("current brief lacks on-demand quality-gate routing")
    normalized_quality = " ".join(quality.split())
    if "NOT VERIFIED" not in quality or "physical iPhone 17 Pro Max" not in normalized_quality:
        findings.append("quality-gates skill lacks evidence/device rules")
    if "blanket Swift 6 concurrency fix" not in read(".codex/skills/swiftui-patterns/SKILL.md"):
        findings.append("SwiftUI skill lacks a non-blanket MainActor boundary")
    ui_skill = read(".codex/skills/memomark-ui-reviewer/SKILL.md")
    if "Liquid Glass is conditional polish only" not in ui_skill:
        findings.append("UI reviewer lacks conditional Liquid Glass boundary")
    if "VoiceOver label/value/traits" not in ui_skill:
        findings.append("UI reviewer lacks cross-cutting accessibility checks")
    media_skill = read(".codex/skills/memomark-media-fidelity/SKILL.md")
    if "source-to-output evidence row" not in media_skill:
        findings.append("media fidelity skill lacks source-to-output evidence contract")
    renderer_skill = read(".codex/skills/memomark-renderer-contract/SKILL.md")
    if "relevance check" not in renderer_skill:
        findings.append("renderer skill lacks async relevance check")
    release_skill = read(".codex/skills/memomark-release-readiness/SKILL.md")
    if "App Review" not in release_skill or "MetricKit" not in release_skill:
        findings.append("release skill lacks policy and post-release evidence gates")
    photokit = read(".codex/skills/photokit/SKILL.md")
    if "relevance/cancellation path" not in photokit:
        findings.append("PhotoKit skill lacks callback relevance boundary")
    verification = read(".codex/skills/verification-loop/SKILL.md")
    if "MemoMark Project Profile" not in verification:
        findings.append("verification loop lacks MemoMark project profile")
    activity = read(".codex/skills/activitykit/SKILL.md")
    if "conditional capability for MemoMark" not in activity:
        findings.append("ActivityKit skill lacks conditional capability boundary")

    legacy_skill_names = {
        "photomemo-swiftui-reviewer",
        "photomemo-product-manager",
        "photomemo-exif",
        "photomemo-renderer",
        "photomemo-release-manager",
    }
    for legacy_name in sorted(legacy_skill_names):
        if (root / ".codex" / "skills" / legacy_name).exists():
            findings.append(f"legacy Skill directory remains: {legacy_name}")
        for relative in (".codex/skills/README.md", "Docs/03_Engineering/2026-08-28-github-ios-skills-research.md"):
            if legacy_name in read(relative):
                findings.append(f"active Skill documentation contains legacy name: {legacy_name}")

    return findings


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("root", nargs="?", type=Path, default=Path.cwd())
    args = parser.parse_args()
    findings = collect_findings(args.root.resolve())
    if findings:
        print("Codex governance findings:")
        for finding in findings:
            print(f"- {finding}")
        return 1
    print("Codex governance checks passed.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

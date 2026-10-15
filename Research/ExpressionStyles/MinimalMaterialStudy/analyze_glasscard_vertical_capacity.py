"""Summarize horizontal-compatible capacity, fit and covered area. Standard library only.
Usage: python3 analyze_glasscard_vertical_capacity.py ATTACHMENTS OUTPUT_DIR
"""
import csv
import json
from pathlib import Path
import shutil
import sys
source, target = map(Path, sys.argv[1:3])
target.mkdir(parents=True, exist_ok=True)
for test in json.loads((source / 'manifest.json').read_text()):
    for item in test['attachments']:
        name = item['suggestedHumanReadableName'].split('_0_')[0]
        suffix = Path(item['exportedFileName']).suffix
        shutil.copy2(source / item['exportedFileName'], target / (name + suffix))
rows = list(csv.DictReader((target / 'vertical-capacity.csv').open()))
assert len(rows) == 768
summary = []
for mode, aspect in [(m,a) for m in ['proportional','compatible'] for a in ['4x3','16x9']]:
    for factor in sorted({r['multiplier'] for r in rows if r['aspect'] == aspect and r['mode'] == mode}, key=float):
        group = [r for r in rows if r['aspect'] == aspect and r['mode'] == mode and r['multiplier'] == factor]
        assert len(group) == 48
        baseline = {(r['language'],r['repeats'],r['slot']):r for r in rows if r['aspect'] == aspect and r['mode'] == mode and r['multiplier'] == '1.0'}
        lost = [r for r in group if r['outcome'] == 'overflow' and baseline[(r['language'],r['repeats'],r['slot'])]['outcome'] != 'overflow']
        gained = [r for r in group if r['outcome'] != 'overflow' and baseline[(r['language'],r['repeats'],r['slot'])]['outcome'] == 'overflow']
        data = dict(mode=mode, aspect=aspect, multiplier=float(factor),
                    heightFraction=float(group[0]['panelHeightFraction']),
                    capsuleAreaFraction=float(group[0]['capsuleAreaFraction']),
                    overflowingSlots=sum(r['outcome']=='overflow' for r in group),
                    newlyOverflowing=len(lost), newlyFitting=len(gained),
                    fittingFontGains=sum(r['outcome'] != 'overflow' and baseline[(r['language'],r['repeats'],r['slot'])]['outcome'] != 'overflow' and float(r['displayFont']) > float(baseline[(r['language'],r['repeats'],r['slot'])]['displayFont']) + 0.02 for r in group))
        if mode == 'compatible':
            assert not lost
            for slot in ['0','1','2','3']:
                floor = min(float(r['displayFont']) for r in baseline.values() if r['slot'] == slot)
                assert min(float(r['displayFont']) for r in group if r['slot'] == slot) >= floor - 0.001
        summary.append(data)
        print(json.dumps(data))
(target / 'summary.json').write_text(json.dumps(summary, indent=2)+'\n')

"""Summarize layout candidate fit and covered area. Standard library only.
Usage: python3 analyze_glasscard_sizing.py ATTACHMENTS OUTPUT_DIR
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
rows = list(csv.DictReader((target / 'landscape-sizing.csv').open()))
assert len(rows) == 384
summary = []
for aspect in ['4x3', '16x9']:
    for factor in sorted({r['multiplier'] for r in rows if r['aspect'] == aspect}, key=float):
        group = [r for r in rows if r['aspect'] == aspect and r['multiplier'] == factor]
        assert len(group) == 48
        baseline = {(r['language'],r['repeats'],r['slot']):r for r in rows if r['aspect'] == aspect and r['multiplier'] == '1.0'}
        lost = [r for r in group if r['outcome'] == 'overflow' and baseline[(r['language'],r['repeats'],r['slot'])]['outcome'] != 'overflow']
        gained = [r for r in group if r['outcome'] != 'overflow' and baseline[(r['language'],r['repeats'],r['slot'])]['outcome'] == 'overflow']
        data = dict(aspect=aspect, multiplier=float(factor),
                    heightFraction=float(group[0]['panelHeightFraction']),
                    capsuleAreaFraction=float(group[0]['capsuleAreaFraction']),
                    overflowingSlots=sum(r['outcome']=='overflow' for r in group),
                    newlyOverflowing=len(lost), newlyFitting=len(gained))
        summary.append(data)
        print(json.dumps(data))
(target / 'summary.json').write_text(json.dumps(summary, indent=2)+'\n')

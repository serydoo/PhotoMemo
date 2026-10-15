"""Summarize actual output resizing; zero-mask cases remain missing contrast.
Usage: python3 analyze_glasscard_vertical_display.py ATTACHMENTS OUTPUT_DIR
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
        stem = item['suggestedHumanReadableName'].split('_0_')[0]
        suffix = Path(item['exportedFileName']).suffix
        shutil.copy2(source / item['exportedFileName'], target / (stem + suffix))
rows = list(csv.DictReader((target / 'vertical-display.csv').open()))
assert len(rows) == 576
for row in rows:
    if int(row['corePixels90']) == 0:
        assert row['minimum'] == row['p10'] == row['median'] == 'NA'
    else:
        assert float(row['minimum']) >= 1
summary = []
for aspect in ['4x3', '16x9']:
    for multiplier in ['1.0', '1.2', '1.4']:
        for density in ['1', '3']:
            group = [r for r in rows if r['aspect'] == aspect and r['multiplier'] == multiplier and r['rasterDensity'] == density and r['displayWidth'] == '360']
            assert len(group) == 16
            sampled = [r for r in group if int(r['corePixels90']) > 0]
            data = dict(aspect=aspect, multiplier=float(multiplier), density=int(density),
                        primaryDisplayFont=float(next(r for r in group if r['slot']=='0')['displayFont']),
                        secondaryDisplayFont=float(next(r for r in group if r['slot']=='1')['displayFont']),
                        meanSampledInkMass=sum(float(r['sampledInkMass']) for r in group)/len(group),
                        minimumPixels50=min(int(r['pixels50']) for r in group),
                        absentCoreGroups=len(group)-len(sampled),
                        sampledContrastGroups=len(sampled),
                        groupsBelowTarget=sum(float(r['minimum']) < 4.5 for r in sampled),
                        minimumAmongSampled=min((float(r['minimum']) for r in sampled), default=None),
                        lowestP10AmongSampled=min((float(r['p10']) for r in sampled), default=None))
            summary.append(data)
            print(json.dumps(data))
(target / 'summary.json').write_text(json.dumps(summary, indent=2)+'\n')

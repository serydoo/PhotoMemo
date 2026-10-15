"""Summarize synthetic ROI blur, halo controls and byte arithmetic.
Usage: python3 analyze_glasscard_roi.py ATTACHMENTS OUTPUT_DIR
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
rows = list(csv.DictReader((target / 'roi-blur.csv').open()))
assert len(rows) == 80
assert all(int(r['outsideMaxByteDifference']) == 0 and int(r['haloMaxByteDifference']) <= 1 for r in rows)
summary = []
for pattern in ['white','bright-checker','full-checker','fine-stripes','gradient']:
    baseline = [r for r in rows if r['pattern']==pattern and float(r['radius'])==0]
    baseline_difference = sum(float(r['horizontalDifference']) for r in baseline)/4
    for radius in sorted({float(r['radius']) for r in rows if r['pattern']==pattern}):
        group = [r for r in rows if r['pattern']==pattern and float(r['radius'])==radius]
        assert len(group)==4
        average = sum(float(r['horizontalDifference']) for r in group)/4
        data = dict(pattern=pattern, radius=radius,
                    haloRGBABytes=int(group[0]['haloBytes']),
                    meanHorizontalDifference=average,
                    horizontalDifferenceRatio=average/baseline_difference if baseline_difference > 1e-12 else None,
                    minimumContrast=min(float(r['minimum']) for r in group),
                    lowestP10=min(float(r['p10']) for r in group))
        summary.append(data)
        print(json.dumps(data))
(target / 'summary.json').write_text(json.dumps(summary,indent=2)+'\n')

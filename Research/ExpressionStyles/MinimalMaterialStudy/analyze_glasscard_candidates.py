"""Summarize synthetic renderer measurements; standard library only.
Usage: python3 analyze_glasscard_candidates.py EXPORTED_ATTACHMENTS OUTPUT_DIR
"""
import csv
import json
from pathlib import Path
import shutil
import sys

source, target = map(Path, sys.argv[1:3])
target.mkdir(parents=True, exist_ok=True)
for test in json.loads((source / 'manifest.json').read_text()):
    for attachment in test['attachments']:
        stem = attachment['suggestedHumanReadableName'].split('_0_')[0]
        extension = Path(attachment['exportedFileName']).suffix
        shutil.copy2(source / attachment['exportedFileName'], target / (stem + extension))
rows = list(csv.DictReader((target / 'material-candidates.csv').open()))
assert len(rows) == 192
summary = []
for alpha in [0.42, 0.50, 0.56, 0.62]:
    for opacity in [0.78, 0.96]:
        selected = [r for r in rows if float(r['surfaceAlpha']) == alpha and float(r['secondaryOpacity']) == opacity]
        assert len(selected) == 24
        white = [r for r in selected if r['sourceGray'] == '255']
        values = {
            'surfaceAlpha': alpha, 'secondaryOpacity': opacity,
            'whitePrimary1080': float(next(r for r in white if r['shortEdge'] == '1080' and r['slot'] == '0')['peakPixelContrast']),
            'whiteSecondary1080': float(next(r for r in white if r['shortEdge'] == '1080' and r['slot'] == '1')['peakPixelContrast']),
            'minimumMeasuredPeakContrast': min(float(r['peakPixelContrast']) for r in selected)
        }
        values['admitsFurtherScreening'] = values['minimumMeasuredPeakContrast'] >= 4.5
        summary.append(values)
(target / 'summary.json').write_text(json.dumps(summary, indent=2) + '\n')
for row in summary:
    print(f"{row['surfaceAlpha']:.2f} / {row['secondaryOpacity']:.2f}: primary {row['whitePrimary1080']:.3f}, secondary {row['whiteSecondary1080']:.3f}, minimum {row['minimumMeasuredPeakContrast']:.3f}, screen {row['admitsFurtherScreening']}")

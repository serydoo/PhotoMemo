"""Summarize explicitly resampled output rasters; standard library only.
Usage: python3 analyze_glasscard_downsampling.py EXPORTED_ATTACHMENTS OUTPUT_DIR
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
        extension = Path(item['exportedFileName']).suffix
        shutil.copy2(source / item['exportedFileName'], target / (name + extension))
rows = list(csv.DictReader((target / 'output-downsampling.csv').open()))
assert len(rows) == 192
summary = []
for orientation in ['portrait3x4', 'landscape4x3', 'portrait9x16', 'landscape16x9']:
    for density in ['1', '3']:
        group = [r for r in rows if r['orientation'] == orientation and r['displayWidth'] == '360' and r['rasterDensity'] == density]
        assert len(group) == 8
        secondary = [r for r in group if r['slot'] in ['1', '3']]
        result = dict(orientation=orientation, density=int(density),
                      primaryDisplayFont=float(next(r for r in group if r['slot'] == '0')['fittedDisplayFont']),
                      secondaryDisplayFont=float(secondary[0]['fittedDisplayFont']),
                      zeroCore90Groups=sum(int(r['pixels90']) == 0 for r in group),
                      minimumSecondaryCore90=min(int(r['pixels90']) for r in secondary),
                      minimumRelativeCoverage=min(float(r['maxRelativeCoverage']) for r in group))
        summary.append(result)
        print(json.dumps(result))
(target / 'summary.json').write_text(json.dumps(summary, indent=2) + '\n')

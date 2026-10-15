"""Summarize paired-coordinate glyph-core contrast. Standard library only.
Usage: python3 analyze_glasscard_textures.py ATTACHMENTS OUTPUT_DIR
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
rows = list(csv.DictReader((target / 'texture-contrast.csv').open()))
assert len(rows) == 192
summary = []
for alpha, opacity, fraction in [(a, o, f) for a, o in [(0.42, 0.78), (0.56, 0.96), (0.62, 0.78)] for f in [0.75, 0.90]]:
    group = [r for r in rows if float(r['surfaceAlpha']) == alpha and float(r['secondaryOpacity']) == opacity and float(r['maskFraction']) == fraction]
    assert len(group) == 32
    assert all(int(r['corePixels']) > 0 and float(r['minimum']) > 1 for r in group)
    values = dict(surfaceAlpha=alpha, secondaryOpacity=opacity, maskFraction=fraction,
                  minimum=min(float(r['minimum']) for r in group),
                  lowestP10=min(float(r['p10']) for r in group),
                  lowestMedian=min(float(r['median']) for r in group),
                  groupsBelowTarget=sum(float(r['minimum']) < 4.5 for r in group))
    summary.append(values)
    print(json.dumps(values))
(target / 'summary.json').write_text(json.dumps(summary, indent=2) + '\n')

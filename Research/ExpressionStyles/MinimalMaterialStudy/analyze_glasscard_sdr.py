#!/usr/bin/env python3
"""Summarize research-only sRGB sampled core contrast; no acceptance claim."""
import csv,json,sys
from pathlib import Path
folder=Path(sys.argv[1])
rows=list(csv.DictReader((folder/'sdr-luminance.csv').open()))
assert len(rows)==144
assert len({(r['pattern'],r['candidate'],r['slot']) for r in rows})==144
assert all(int(r['corePixels'])>0 for r in rows)
summary={}
for candidate in sorted({r['candidate'] for r in rows}):
    group=[r for r in rows if r['candidate']==candidate]
    summary[candidate]={'minimum':min(float(r['minimum']) for r in group),'lowestP10':min(float(r['p10']) for r in group),'groupsBelow4_5':sum(float(r['minimum'])<4.5 for r in group),'patterns':{}}
    for pattern in sorted({r['pattern'] for r in group}):
        part=[r for r in group if r['pattern']==pattern]
        summary[candidate]['patterns'][pattern]={'minimum':min(float(r['minimum']) for r in part),'p10':min(float(r['p10']) for r in part),'backgroundMean':sum(float(r['backgroundMean']) for r in part)/len(part)}
(folder/'summary.json').write_text(json.dumps(summary,indent=2)+'\n')
print(json.dumps(summary,indent=2))

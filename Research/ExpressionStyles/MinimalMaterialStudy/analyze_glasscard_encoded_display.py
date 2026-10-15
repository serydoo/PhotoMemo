#!/usr/bin/env python3
"""Keep absent cores explicit; no device/WCAG acceptance inference."""
import csv,json,math,sys
from pathlib import Path
folder=Path(sys.argv[1])
rows=list(csv.DictReader((folder/'encoded-display.csv').open()))
key=lambda r:(r['glyph'],r['format'],r['width'],r['density'],r['slot'])
formats=[f for f in ['native','png','jpg','heic','jpg90','jpg100','jpgRaster'] if f in {r['format'] for r in rows}]
assert len(formats) in (4,6,7) and len(rows)==len(formats)*32 and len({key(r) for r in rows})==len(rows)
for r in rows:
 absent=int(r['corePixels'])==0
 assert (r['minimum']=='NA')==absent and (r['p10']=='NA')==absent
 if not absent: assert math.isfinite(float(r['minimum'])) and float(r['minimum'])>=1
 assert float(r['sampledInkMass'])>0
lookup={key(r):r for r in rows}
for r in rows:
 if r['format']=='png':
  baseline=lookup[(r['glyph'],'native',r['width'],r['density'],r['slot'])]
  for field in ['displayFont','corePixels','minimum','p10','sampledInkMass','maxNormalizedAlpha']:
   assert r[field]==baseline[field],field
summary={}
for width in ['360.0','600.0']:
 for density in ['1.0','3.0']:
  groupKey=f'{width}@{density}'
  summary[groupKey]={}
  for fmt in formats:
   group=[r for r in rows if r['width']==width and r['density']==density and r['format']==fmt]
   assert len(group)==8
   valid=[r for r in group if r['minimum']!='NA']
   summary[groupKey][fmt]={'groups':8,'missingCoreGroups':8-len(valid),'minimum':min((float(r['minimum']) for r in valid),default=None),'lowestP10':min((float(r['p10']) for r in valid),default=None),'groupsBelow4_5':sum(float(r['minimum'])<4.5 for r in valid),'primaryFont':float(group[0]['displayFont']),'secondaryFont':float(group[1]['displayFont']),'meanSampledInkMass':sum(float(r['sampledInkMass']) for r in group)/8}
(folder/'summary.json').write_text(json.dumps(summary,indent=2)+'\n')
print(json.dumps(summary,indent=2))

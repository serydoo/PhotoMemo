#!/usr/bin/env python3
"""Summarize controlled sRGB compositor parity, not media certification."""
import csv,json,sys
from pathlib import Path
folder=Path(sys.argv[1])
rows=list(csv.DictReader((folder/'final-sdr-composition.csv').open()))
assert len(rows)==32 and len({(r['pattern'],r['slot']) for r in rows})==32
assert all(int(r['pngMaxByteDifference'])==0 and int(r['outsideMaxByteDifference'])==0 for r in rows)
report={
 'rows':len(rows),
 'oldMinimum':min(float(r['oldMinimum']) for r in rows),
 'newMinimum':min(float(r['newMinimum']) for r in rows),
 'newLowestP10':min(float(r['newP10']) for r in rows),
 'maxByteDifference':max(int(r['maxByteDifference']) for r in rows),
 'maxCoreContrastDifference':max(abs(float(r['oldMinimum'])-float(r['newMinimum'])) for r in rows),
 'groupsBelow4_5':sum(float(r['newMinimum'])<4.5 for r in rows),
 'colors':json.loads((folder/'final-sdr-color-report.json').read_text()),
 'patterns':{}
}
for pattern in sorted({r['pattern'] for r in rows}):
 group=[r for r in rows if r['pattern']==pattern]
 report['patterns'][pattern]={'newMinimum':min(float(r['newMinimum']) for r in group),'newP10':min(float(r['newP10']) for r in group)}
(folder/'summary.json').write_text(json.dumps(report,indent=2)+'\n')
print(json.dumps(report,indent=2))

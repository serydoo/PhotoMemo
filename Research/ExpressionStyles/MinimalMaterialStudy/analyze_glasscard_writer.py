#!/usr/bin/env python3
"""Read actual-writer measurements; preserve missing fields in report."""
import csv,json,sys
from pathlib import Path
folder=Path(sys.argv[1])
rows=list(csv.DictReader((folder/'writer-sdr-readback.csv').open()))
assert len(rows)==12 and len({(r['format'],r['slot']) for r in rows})==12
metadata=json.loads((folder/'writer-sdr-metadata.json').read_text())
report={}
for ext in ['png','jpg','heic']:
 group=[r for r in rows if r['format']==ext]
 assert len(group)==4
 report[ext]={'originalMinimum':min(float(r['originalMinimum']) for r in group),'decodedMinimum':min(float(r['decodedMinimum']) for r in group),'decodedLowestP10':min(float(r['decodedP10']) for r in group),'maxRGBAByteDifference':max(int(r['maxByteDifference']) for r in group),'meanRGBAByteDifference':float(group[0]['meanByteDifference']),'metadata':next(m for m in metadata if m['format']==ext)}
(folder/'summary.json').write_text(json.dumps(report,indent=2)+'\n')
print(json.dumps(report,indent=2))

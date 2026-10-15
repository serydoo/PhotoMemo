import json
import sys
from pathlib import Path
from collections import defaultdict
rows=json.loads(Path(sys.argv[1]).read_text())
assert len(rows)==54
assert len({(r["sample"],r["format"],r["route"]) for r in rows})==54
assert all(r["capture"]=="2001:02:03 04:05:06" and r["exposure"]==0.01 and r["latitude"]==22.5 and r["gpsSet"] for r in rows)
summary=defaultdict(lambda:{"count":0,"propertyMatches":0,"metadataMatches":0})
for r in rows:
    s=summary[r["format"]+"/"+r["route"]]
    s["count"]+=1
    s["propertyMatches"]+=r["propertyComment"]==r["input"]
    s["metadataMatches"]+=r["metadataComment"]==r["input"]
print(json.dumps(dict(summary),indent=2))

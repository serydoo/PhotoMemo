"""Summarize controlled Unicode readback; no global metadata claims."""
import json
import sys
from collections import defaultdict
from pathlib import Path
rows=json.loads(Path(sys.argv[1]).read_text())
assert len(rows)==54
assert len({(r["sample"],r["format"],r["route"]) for r in rows})==54
summary=defaultdict(lambda: {"count":0,"commentMatches":0,"tiffMatches":0,"iptcMatches":0,"pngMatches":0})
for r in rows:
    result=summary[r["format"]+"/"+r["route"]]
    result["count"]+=1
    result["commentMatches"]+=r["comment"]==r["input"]
    for field in ["tiff","iptc","png"]:
        result[field+"Matches"]+=r[field]==r["input"]
print(json.dumps(dict(summary),ensure_ascii=False,indent=2))

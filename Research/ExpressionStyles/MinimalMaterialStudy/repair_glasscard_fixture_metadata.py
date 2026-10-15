"""Research copies only; strict same-size patch, no production callers."""
import json
import sys
import zlib
from pathlib import Path
from inspect_glasscard_containers import inspect, png_exif, heic_exif, user_comment, require, number

def repair(data,ext,text):
    require(ext in ("png","heic"),"unsupported container")
    tiff,info=png_exif(data) if ext=="png" else heic_exif(data)
    u=user_comment(tiff)
    raw=(b"ASCII\0\0\0"+text.encode("ascii")) if text.isascii() else b"UNICODE\0"+text.encode("utf-16-be")
    require(len(raw)<=u["count"],"insufficient UserComment capacity")
    crc_offset=None
    if ext=="png":
        cursor=8
        while data[cursor+4:cursor+8]!=b"eXIf":cursor+=number(data,cursor,4)+12
        start=cursor+8;crc_offset=start+len(tiff)
    else:start=info["extentOffset"]+info["tiffOffset"]
    output=bytearray(data)
    storage=start+u["storageOffset"];count=start+u["countOffset"]
    output[storage:storage+u["count"]]=raw+b"\0"*(u["count"]-len(raw))
    output[count:count+4]=len(raw).to_bytes(4,u["byteOrder"])
    allowed=[(storage,storage+u["count"]),(count,count+4)]
    if crc_offset is not None:
        output[crc_offset:crc_offset+4]=(zlib.crc32(output[start-4:crc_offset])&0xffffffff).to_bytes(4,"big")
        allowed.append((crc_offset,crc_offset+4))
    output=bytes(output)
    require(len(output)==len(data),"length changed")
    require(all(a==b or any(lo<=i<hi for lo,hi in allowed) for i,(a,b) in enumerate(zip(data,output))),"unrelated bytes changed")
    verified=inspect(output,ext)
    require(verified["userComment"]["rawHex"]==raw.hex(),"patched storage mismatch")
    return output,allowed

if __name__=="__main__":
    root=Path(sys.argv[1]);out=Path(sys.argv[2]);require(root.resolve()!=out.resolve(),"input/output directories must differ");out.mkdir(parents=True,exist_ok=True)
    rows=[]
    for entry in json.loads((root/"fixture-manifest.json").read_text()):
        data=(root/entry["file"]).read_bytes();ext=Path(entry["file"]).suffix[1:]
        try:
            result,ranges=repair(data,ext,entry["input"])
        except ValueError as error:
            rows.append(dict(entry,status="rejected",reason=str(error)));continue
        (out/entry["file"]).write_bytes(result)
        rows.append(dict(entry,status="patched",allowedRanges=ranges,fileLength=len(result)))
    (out/"repair-manifest.json").write_text(json.dumps(rows,ensure_ascii=False,indent=2))
    print(json.dumps([{k:v for k,v in r.items() if k not in ("input","readback")} for r in rows],indent=2))

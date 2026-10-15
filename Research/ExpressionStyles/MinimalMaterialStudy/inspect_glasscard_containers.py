"""Read-only controlled-fixture inspector, not a general HEIF/TIFF validator."""
import json
import sys
import zlib
from pathlib import Path

class Rejected(ValueError):
    pass

def require(condition, reason):
    if not condition:
        raise Rejected(reason)

def read(data, start, count):
    require(start >= 0 and count >= 0 and start + count <= len(data), 'out of bounds')
    return data[start:start + count]

def number(data, start, count, order='big'):
    return int.from_bytes(read(data,start,count),order)

def boxes(data,start=0,end=None):
    end=len(data) if end is None else end
    require(0<=start<=end<=len(data),'invalid box boundary')
    result=[]
    while start<end:
        require(start+8<=end,'truncated box header')
        size=number(data,start,4); kind=read(data,start+4,4).decode('ascii'); header=8
        if size==1:
            require(start+16<=end,'truncated large box');size=number(data,start+8,8);header=16
        if size==0:size=end-start
        require(header<=size<=end-start,'invalid box size')
        result.append((kind,start+header,start+size));start+=size
    return result

def png_exif(data):
    require(data[:8]==b'\x89PNG\r\n\x1a\n','not PNG')
    offset=8;exif=[];chunks=[]
    while offset<len(data):
        length=number(data,offset,4);kind=read(data,offset+4,4)
        payload=read(data,offset+8,length);crc=number(data,offset+8+length,4)
        require(zlib.crc32(kind+payload)&0xffffffff==crc,'CRC mismatch')
        chunks.append(kind.decode('ascii'))
        if kind==b'eXIf':exif.append(payload)
        offset+=length+12
        if kind==b'IEND':break
    require(offset==len(data) and chunks[-1]=='IEND' and len(exif)==1,'ambiguous PNG')
    return exif[0],{'chunks':chunks,'allCRCValid':True}

def heic_exif(data):
    top=boxes(data);meta=[b for b in top if b[0]=='meta'];require(len(meta)==1,'ambiguous meta')
    children=boxes(data,meta[0][1]+4,meta[0][2]); mapping={}
    iinf=[b for b in children if b[0]=='iinf'];iloc=[b for b in children if b[0]=='iloc']
    require(len(iinf)==len(iloc)==1,'ambiguous item tables')
    _,begin,end=iinf[0];version=number(data,begin,1);require(version in (0,1),'unsupported iinf')
    count_size=2 if version==0 else 4
    item_count=number(data,begin+4,count_size)
    entries=boxes(data,begin+4+count_size,end);require(len(entries)==item_count,'item count mismatch')
    for kind,start,stop in entries:
        require(kind=='infe','unsupported item info');v=number(data,start,1);require(v in (2,3),'unsupported infe')
        id_size=2 if v==2 else 4
        item_id=number(data,start+4,id_size)
        require(start+4+id_size+6<=stop,'truncated infe')
        protection=number(data,start+4+id_size,2)
        item_type=read(data,start+6+id_size,4)
        if item_type==b'Exif':
            require(protection==0,'protected Exif');require(item_id not in mapping,'duplicate Exif');mapping[item_id]=None
    require(len(mapping)==1,'ambiguous Exif item')
    _,begin,end=iloc[0];v=number(data,begin,1);require(v in (0,1,2),'unsupported iloc')
    cursor=begin+4
    def take(n):
        nonlocal cursor
        require(cursor+n<=end,'truncated iloc');value=number(data,cursor,n);cursor+=n;return value
    widths=take(2);offset_size=widths>>12;length_size=(widths>>8)&15;base_size=(widths>>4)&15;index_size=widths&15 if v else 0
    require(all(n in (0,4,8) for n in (offset_size,length_size,base_size,index_size)),'unsupported iloc widths')
    count=take(2 if v<2 else 4);require(count<=1024,'too many items')
    extents=None
    for _ in range(count):
        item_id=take(2 if v<2 else 4);method=take(2)&15 if v else 0
        reference=take(2);base=take(base_size);extent_count=take(2);require(extent_count<=1024,'too many extents')
        parts=[]
        for _ in range(extent_count):
            if index_size:take(index_size)
            offset=take(offset_size);length=take(length_size);parts.append((base+offset,length))
        if item_id in mapping:
            require(method==0 and reference==0 and len(parts)==1,'unsupported Exif extent')
            require(extents is None,'duplicate iloc Exif');extents=parts
    require(cursor==end and extents is not None,'invalid iloc')
    offset,length=extents[0]
    require(any(kind=='mdat' and start<=offset and offset+length<=stop for kind,start,stop in top),'Exif outside mdat')
    payload=read(data,offset,length);tiff_offset=4+number(payload,0,4)
    require(tiff_offset<len(payload),'invalid TIFF item offset')
    return payload[tiff_offset:],{'itemID':next(iter(mapping)),'extentOffset':offset,'extentLength':length,'tiffOffset':tiff_offset,'ilocVersion':v,'singleExtent':True}

def user_comment(tiff):
    require(tiff[:2] in (b'II',b'MM'),'not TIFF');order='little' if tiff[:2]==b'II' else 'big'
    def n(offset,width):return number(tiff,offset,width,order)
    require(n(2,2)==42,'unsupported TIFF magic')
    def entries(offset):
        count=n(offset,2);require(count<=1024,'too many TIFF tags')
        read(tiff,offset+2,count*12+4)
        result={}
        for i in range(count):
            pos=offset+2+i*12;tag=n(pos,2);require(tag not in result,'duplicate tag')
            result[tag]=(n(pos+2,2),n(pos+4,4),n(pos+8,4),pos)
        return result
    root=entries(n(4,4));require(0x8769 in root,'missing EXIF IFD')
    kind,count,offset,_=root[0x8769];require(kind==4 and count==1,'invalid EXIF pointer')
    exif=entries(offset);require(0x9286 in exif,'missing UserComment')
    kind,count,offset,pos=exif[0x9286];require(kind==7 and count>=8,'unsupported UserComment storage')
    raw=read(tiff,offset,count)
    return {'byteOrder':order,'storageOffset':offset,'countOffset':pos+4,'count':count,'rawHex':raw.hex(),'encodingHeader':raw[:8].hex(),'payloadHex':raw[8:].hex()}

def inspect(data,extension):
    tiff,container=png_exif(data) if extension=='png' else heic_exif(data)
    return {'container':container,'userComment':user_comment(tiff)}

if __name__=='__main__':
    root=Path(sys.argv[1]);manifest=json.loads((root/'fixture-manifest.json').read_text());rows=[]
    for entry in manifest:
        file=root/entry['file'];result=inspect(file.read_bytes(),file.suffix[1:]);result.update(entry)
        expected=entry['input'].encode('utf-16-be').hex()
        result['rawUTF16BEMatches']=result['userComment']['payloadHex']==expected
        result['readbackMatches']=entry['readback']==entry['input'];rows.append(result)
    print(json.dumps(rows,ensure_ascii=False,indent=2))

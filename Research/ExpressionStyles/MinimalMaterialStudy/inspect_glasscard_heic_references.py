"""Read-only iloc observation for synthetic fixtures, not a general HEIF validator."""
import json
import sys
from pathlib import Path
from inspect_glasscard_containers import boxes, number, read, require


def inspect_references(data):
    require(len(data) <= 16 * 1024 * 1024, 'oversized research fixture')
    top = boxes(data)
    meta = [entry for entry in top if entry[0] == 'meta']
    require(len(meta) == 1, 'ambiguous meta')
    _, start, end = meta[0]
    require(number(data, start, 4) == 0, 'unsupported meta flags')
    children = boxes(data, start + 4, end)
    info = [entry for entry in children if entry[0] == 'iinf']
    locations = [entry for entry in children if entry[0] == 'iloc']
    require(len(info) == len(locations) == 1, 'ambiguous item tables')
    _, start, end = info[0]
    version = number(data, start, 1)
    require(version in (0, 1), 'unsupported iinf')
    count_width = 2 if version == 0 else 4
    count = number(data, start + 4, count_width)
    require(count <= 1024, 'too many item definitions')
    entries = boxes(data, start + 4 + count_width, end)
    require(len(entries) == count, 'item count mismatch')
    types = {}
    for kind, start, end in entries:
        require(kind == 'infe', 'unexpected item definition')
        version = number(data, start, 1)
        require(version in (2, 3), 'unsupported infe')
        width = 2 if version == 2 else 4
        require(start + 10 + width <= end, 'truncated infe')
        item = number(data, start + 4, width)
        require(item not in types, 'duplicate item definition')
        types[item] = read(data, start + 6 + width, 4).decode('ascii')
    _, start, end = locations[0]
    version = number(data, start, 1)
    require(version in (0, 1, 2), 'unsupported iloc')
    cursor = start + 4

    def take(width):
        nonlocal cursor
        require(cursor + width <= end, 'truncated iloc')
        value = number(data, cursor, width)
        cursor += width
        return value

    sizes = take(2)
    offset_width, length_width, base_width = sizes >> 12, (sizes >> 8) & 15, (sizes >> 4) & 15
    index_width = sizes & 15 if version else 0
    require(all(width in (0, 4, 8) for width in (offset_width, length_width, base_width, index_width)), 'unsupported widths')
    count = take(2 if version < 2 else 4)
    require(count <= 1024, 'too many item locations')
    result, seen = [], set()
    total = 0
    for _ in range(count):
        item = take(2 if version < 2 else 4)
        require(item in types and item not in seen, 'invalid item ID')
        seen.add(item)
        method = take(2) & 15 if version else 0
        reference, base, extent_count = take(2), take(base_width), take(2)
        total += extent_count
        require(total <= 1024, 'too many extents')
        extents = []
        for _ in range(extent_count):
            index = take(index_width) if index_width else 0
            offset, length = take(offset_width), take(length_width)
            extents.append({'index': index, 'rawOffset': offset, 'length': length})
        result.append({'itemID': item, 'type': types[item], 'constructionMethod': method,
                       'dataReferenceIndex': reference, 'baseOffset': base, 'extents': extents})
    require(cursor == end and seen == set(types), 'incomplete item tables')
    return {'ilocVersion': version, 'idatPayloadRanges': [[start, end] for kind, start, end in children if kind == 'idat'], 'items': result}


if __name__ == '__main__':
    print(json.dumps([{'file': Path(path).name, **inspect_references(Path(path).read_bytes())}
                      for path in sys.argv[1:]], indent=2))

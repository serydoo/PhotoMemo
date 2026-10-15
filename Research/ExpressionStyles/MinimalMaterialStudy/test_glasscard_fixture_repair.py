import sys
import json
import unittest
from pathlib import Path
from repair_glasscard_fixture_metadata import repair
from inspect_glasscard_containers import inspect, Rejected
ROOT=Path(sys.argv.pop(1))

class RepairControls(unittest.TestCase):
    def test_all_reserved_fixtures(self):
        manifest=json.loads((ROOT/"fixture-manifest.json").read_text())
        for row in manifest:
            if not row["reserved"]:continue
            before=(ROOT/row["file"]).read_bytes();ext=Path(row["file"]).suffix[1:]
            after,allowed=repair(before,ext,row["input"])
            self.assertEqual(len(before),len(after))
            self.assertTrue(all(a==b or any(lo<=i<hi for lo,hi in allowed) for i,(a,b) in enumerate(zip(before,after))))
            inspect(after,ext)

    def test_insufficient_capacity(self):
        for ext in ("png","heic"):
            data=(ROOT/f"fixture-4.{ext}").read_bytes()
            with self.assertRaisesRegex(Rejected,"insufficient UserComment capacity"):repair(data,ext,"Cafe\u0301 365")

    def test_bad_crc_before_patch(self):
        data=bytearray((ROOT/"fixture-2.png").read_bytes());data[20]^=1
        with self.assertRaisesRegex(Rejected,"CRC mismatch"):repair(bytes(data),"png","相伴365天")

    def test_unsupported_container(self):
        with self.assertRaisesRegex(Rejected,"unsupported container"):repair(b"", "jpg","text")

if __name__=="__main__":unittest.main()

import sys
import unittest
from pathlib import Path
from inspect_glasscard_containers import inspect, png_exif, heic_exif, user_comment, Rejected

ROOT=Path(sys.argv.pop(1))

class InspectorControls(unittest.TestCase):
    def test_valid_twelve_fixtures(self):
        for index in range(6):
            for ext in ('png','heic'):
                inspect((ROOT/f'fixture-{index}.{ext}').read_bytes(),ext)

    def test_png_bad_crc(self):
        data=bytearray((ROOT/'fixture-2.png').read_bytes());data[20]^=1
        with self.assertRaisesRegex(Rejected,'CRC mismatch'):inspect(bytes(data),'png')

    def test_truncated_containers(self):
        for ext in ('png','heic'):
            data=(ROOT/f'fixture-2.{ext}').read_bytes()
            for end in (0,1,7,len(data)-1):
                with self.assertRaises(Rejected):inspect(data[:end],ext)

    def test_png_trailing_bytes(self):
        data=(ROOT/'fixture-2.png').read_bytes()+b'trailing'
        with self.assertRaises(Rejected):inspect(data,'png')

    def test_tiff_out_of_bounds_pointer(self):
        for ext in ('png','heic'):
            data=(ROOT/f'fixture-2.{ext}').read_bytes()
            tiff,_=(png_exif(data) if ext=='png' else heic_exif(data))
            broken=bytearray(tiff);broken[4:8]=b'\xff'*4
            with self.assertRaisesRegex(Rejected,'out of bounds'):user_comment(bytes(broken))

    def test_heic_invalid_tiff_item_offset(self):
        data=bytearray((ROOT/'fixture-2.heic').read_bytes());_,info=heic_exif(data)
        start=info['extentOffset'];data[start:start+4]=b'\xff'*4
        with self.assertRaisesRegex(Rejected,'invalid TIFF item offset'):inspect(bytes(data),'heic')

if __name__=='__main__':unittest.main()

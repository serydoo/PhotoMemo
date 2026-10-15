import struct
import unittest
from inspect_glasscard_heic_references import inspect_references
from inspect_glasscard_containers import Rejected


def box(kind, payload):
    return struct.pack('>I', len(payload)+8)+kind.encode('ascii')+payload


def fixture(item_id=1):
    infe = box('infe', b'\x02\0\0\0'+struct.pack('>HH', 1, 0)+b'grid\0')
    iinf = box('iinf', b'\0'*4+struct.pack('>H', 1)+infe)
    iloc = box('iloc', b'\x01\0\0\0'+struct.pack('>HH', 0x4400, 1)
               +struct.pack('>HHHHII', item_id, 1, 0, 1, 0, 8))
    return box('meta', b'\0'*4+iinf+iloc+box('idat', b'\0'*8))


class ReferenceObservationTests(unittest.TestCase):
    def test_reports_local_grid_reference_without_claiming_validation(self):
        result = inspect_references(fixture())
        self.assertEqual(result['ilocVersion'], 1)
        self.assertEqual(result['items'][0]['type'], 'grid')
        self.assertEqual(result['items'][0]['constructionMethod'], 1)
        self.assertEqual(result['items'][0]['extents'], [{'index':0,'rawOffset':0,'length':8}])
        self.assertEqual(len(result['idatPayloadRanges']), 1)

    def test_unknown_item_rejected(self):
        with self.assertRaises(Rejected):
            inspect_references(fixture(item_id=2))

    def test_truncation_and_missing_tables_rejected(self):
        for data in [b'', fixture()[:-1], box('meta', b'\0'*4)]:
            with self.subTest(length=len(data)), self.assertRaises(Rejected):
                inspect_references(data)


if __name__ == '__main__':
    unittest.main()

import unittest
from analyze_glasscard_motion_measurements import summarize


class MotionMeasurementsTests(unittest.TestCase):
    def fixture(self):
        return [{"width": 1920, "height": 1080, "sourceFrames": 4,
                 "sourceFPS": 4, "exportSeconds": 2,
                 "processLifetimePeakRSSBeforeBytes": 100 * 1024**2,
                 "processLifetimePeakRSSAfterBytes": 120 * 1024**2,
                 "stillMaterialMotionInteriorMaxChannelDelta": 3,
                 "outputBytes": 1024}]

    def test_report_keeps_host_cost_and_lifetime_peak_distinct(self):
        row = summarize(self.fixture())[0]
        self.assertEqual(row["syntheticSourceSeconds"], 1)
        self.assertEqual(row["exportSecondsPerSourceSecond"], 2)
        self.assertEqual(row["processLifetimePeakAfterMiB"], 120)
        self.assertEqual(row["processHighWaterMarkIncreaseMiB"], 20)
        self.assertNotIn("exportPeakMiB", row)

    def test_zero_high_water_increase_is_not_zero_export_memory(self):
        rows = self.fixture()
        rows[0]["processLifetimePeakRSSAfterBytes"] = rows[0]["processLifetimePeakRSSBeforeBytes"]
        self.assertEqual(summarize(rows)[0]["processHighWaterMarkIncreaseMiB"], 0)

    def test_missing_measurement_is_rejected(self):
        rows = self.fixture()
        del rows[0]["exportSeconds"]
        with self.assertRaises(ValueError):
            summarize(rows)

    def test_invalid_timing_or_nonfinite_values_are_rejected(self):
        for field, value in [("sourceFPS", 0), ("exportSeconds", float("nan")),
                             ("sourceFrames", -1)]:
            rows = self.fixture()
            rows[0][field] = value
            with self.assertRaises(ValueError):
                summarize(rows)


if __name__ == "__main__":
    unittest.main()

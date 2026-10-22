import unittest
from flame_full_board import observation_age

class FreshnessTest(unittest.TestCase):
    def test_device_ahead_clock_cannot_pass_as_negative_freshness(self):
        with self.assertRaises(AssertionError):
            observation_age('2026-10-22T00:00:00.403+00:00', 1792627200.0)

    def test_real_same_clock_dispatch_includes_roundtrip_delay(self):
        self.assertAlmostEqual(observation_age('2026-10-22T00:00:00+00:00', 1792627200.125), .125)
        with self.assertRaises(AssertionError):
            observation_age('2026-10-22T00:00:00+00:00', 1792627200.4)

if __name__ == '__main__':
    unittest.main()

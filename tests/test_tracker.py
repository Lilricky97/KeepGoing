import unittest
from dataclasses import replace

from keepgoing.tracker import update
from tests.helpers import SETTINGS, make_offer, make_watch


class TrackerTest(unittest.TestCase):
    def setUp(self):
        self.state = {}
        self.watch = make_watch()

    def check(self, price, settings=SETTINGS, watch=None):
        return update(self.state, watch or self.watch, make_offer(price), settings, "2026-10-14T10:00:00+00:00")

    def test_first_check_starts_monitoring(self):
        event = self.check(100)
        self.assertEqual(event.kind, "start")
        self.assertEqual(self.state["baseline"], 100)
        self.assertEqual(self.state["lowest"], 100)

    def test_small_changes_are_ignored(self):
        self.check(100)
        self.assertIsNone(self.check(97))  # -3 €: sotto la soglia di 5 €
        self.assertIsNone(self.check(103))
        self.assertEqual(self.state["baseline"], 100)

    def test_threshold_uses_percentage_for_expensive_flights(self):
        self.check(1000)
        self.assertIsNone(self.check(980))  # -20 € ma solo -2% (< 3%)
        self.assertEqual(self.check(960).kind, "drop")

    def test_drop_is_notified_and_becomes_new_baseline(self):
        self.check(100)
        event = self.check(90)
        self.assertEqual(event.kind, "drop")
        self.assertEqual(event.previous, 100)
        self.assertEqual(event.change, -10)
        self.assertTrue(event.is_record)
        self.assertEqual(self.state["baseline"], 90)

    def test_slow_drift_eventually_notifies(self):
        self.check(100)
        for price in (98, 96, 97):
            self.assertIsNone(self.check(price))
        self.assertEqual(self.check(94).kind, "drop")  # -6 € rispetto all'ultima notifica

    def test_rise_is_notified_when_enabled(self):
        self.check(100)
        event = self.check(120)
        self.assertEqual(event.kind, "rise")
        self.assertFalse(event.is_record)

    def test_rise_is_silent_with_drops_only(self):
        settings = replace(SETTINGS, notify_on="drops")
        self.check(100, settings)
        self.assertIsNone(self.check(120, settings))
        self.assertEqual(self.state["baseline"], 120)
        self.assertEqual(self.check(110, settings).kind, "drop")

    def test_target_price_notified_once_then_rearmed(self):
        watch = make_watch(target_price=95)
        self.check(100, watch=watch)
        event = self.check(97, watch=watch)  # cambio piccolo ma obiettivo... non ancora raggiunto
        self.assertIsNone(event)
        event = self.check(94, watch=watch)  # -6 €: ribasso + obiettivo
        self.assertEqual(event.kind, "drop")
        self.assertTrue(event.hit_target)
        self.assertIsNone(self.check(93, watch=watch))  # già notificato
        self.check(110, watch=watch)  # risale: si riarma
        event = self.check(95, watch=watch)
        self.assertTrue(event.hit_target)

    def test_target_hit_with_small_change(self):
        watch = make_watch(target_price=98)
        self.check(100, watch=watch)
        event = self.check(98, watch=watch)
        self.assertEqual(event.kind, "target")
        self.assertEqual(self.state["baseline"], 98)

    def test_history_is_capped(self):
        settings = replace(SETTINGS, history_limit=3)
        for price in (100, 101, 102, 103, 104):
            self.check(price, settings)
        self.assertEqual([p["price"] for p in self.state["history"]], [102, 103, 104])


if __name__ == "__main__":
    unittest.main()

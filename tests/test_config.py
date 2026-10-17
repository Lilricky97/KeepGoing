import unittest
from datetime import date

from keepgoing.config import ConfigError, parse_config

WATCH = {"origin": "mil", "destination": "BCN", "depart": "2026-12", "return": "2026-12"}


class ConfigTest(unittest.TestCase):
    def test_defaults_and_derived_values(self):
        config = parse_config({"watch": [WATCH]})
        watch = config.watches[0]
        self.assertEqual(config.settings.provider, "travelpayouts")
        self.assertEqual(watch.origin, "MIL")
        self.assertEqual(watch.id, "mil-bcn-2026-12-2026-12")
        self.assertEqual(watch.name, "MIL → BCN")
        self.assertFalse(watch.one_way)

    def test_settings_are_read(self):
        config = parse_config({"settings": {"provider": "demo", "currency": "usd", "notify_on": "drops"}, "watch": [WATCH]})
        self.assertEqual(config.settings.currency, "USD")
        self.assertEqual(config.settings.notify_on, "drops")

    def test_errors_are_explained(self):
        cases = [
            ({"watch": [{**WATCH, "origin": "Milano"}]}, "codice IATA"),
            ({"watch": [{**WATCH, "depart": "12/2026"}]}, "YYYY-MM"),
            ({"watch": [{**WATCH, "depart": "2026-13"}]}, "non è una data valida"),
            ({"watch": [{**WATCH, "destionation": "BCN"}]}, "refuso"),
            ({"watch": [{**WATCH, "depart": "2026-12-20", "return": "2026-12-10"}]}, "prima della partenza"),
            ({"watch": [WATCH, WATCH]}, "stesso id"),
            ({"settings": {"provider": "skyscanner"}, "watch": [WATCH]}, "sconosciuto"),
            ({"settings": {"notify_on": "always"}, "watch": [WATCH]}, "notify_on"),
        ]
        for raw, message in cases:
            with self.subTest(message=message):
                with self.assertRaises(ConfigError) as ctx:
                    parse_config(raw)
                self.assertIn(message, str(ctx.exception))

    def test_no_watches_is_allowed(self):
        self.assertEqual(parse_config({}).watches, [])

    def test_app_watches_are_added_after_config_ones(self):
        app = [
            {"id": "rom-lon-2027-02-14", "name": "Roma → Londra", "origin": "ROM", "destination": "LON",
             "depart": "2027-02-14", "target_price": 50, "added_at": "2026-10-17T10:00:00Z"},
        ]
        config = parse_config({"watch": [WATCH]}, app)
        self.assertEqual([w.id for w in config.watches], ["mil-bcn-2026-12-2026-12", "rom-lon-2027-02-14"])
        self.assertEqual([w.source for w in config.watches], ["config", "app"])
        self.assertTrue(config.watches[1].one_way)
        self.assertEqual(config.warnings, [])

    def test_bad_app_watches_are_skipped_not_fatal(self):
        app = [
            {**WATCH, "depart": "domani"},
            {**WATCH, "id": "mil-bcn-2026-12-2026-12"},  # già in config.toml
            "non un oggetto",
            {"origin": "FCO", "destination": "JFK", "depart": "2027-03"},
        ]
        config = parse_config({"watch": [WATCH]}, app)
        self.assertEqual([w.id for w in config.watches], ["mil-bcn-2026-12-2026-12", "fco-jfk-2027-03"])
        self.assertEqual(len(config.warnings), 3)
        self.assertIn("YYYY-MM", config.warnings[0])
        self.assertIn("già monitorato", config.warnings[1])

    def test_load_app_watches_file(self):
        import json
        import tempfile
        from pathlib import Path

        from keepgoing.config import load_app_watches

        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / "watches.json"
            self.assertEqual(load_app_watches(path), [])  # il file non c'è ancora
            path.write_text(json.dumps({"version": 1, "watches": [WATCH]}))
            self.assertEqual(load_app_watches(path), [WATCH])
            path.write_text("{rotto")
            with self.assertRaisesRegex(ConfigError, "JSON"):
                load_app_watches(path)

    def test_expired_watches(self):
        month = parse_config({"watch": [{**WATCH, "return": None, "depart": "2026-10"}]}).watches[0]
        self.assertFalse(month.is_expired(date(2026, 10, 31)))
        self.assertTrue(month.is_expired(date(2026, 11, 1)))
        day = parse_config({"watch": [{**WATCH, "return": None, "depart": "2026-10-14"}]}).watches[0]
        self.assertTrue(day.is_expired(date(2026, 10, 15)))


if __name__ == "__main__":
    unittest.main()


class AppContractTest(unittest.TestCase):
    """tests/fixtures/watches-from-app.json è stato scritto dal codice dell'app (AppWatch.swift)."""

    def test_engine_reads_what_the_app_writes(self):
        from pathlib import Path

        from keepgoing.config import load_app_watches

        fixture = Path(__file__).parent / "fixtures" / "watches-from-app.json"
        config = parse_config({}, load_app_watches(fixture))
        self.assertEqual(config.warnings, [])
        one_way, round_trip = config.watches
        self.assertEqual(one_way.id, "fco-jfk-2027-03")
        self.assertTrue(one_way.one_way and one_way.direct_only)
        self.assertEqual(one_way.target_price, 300)
        self.assertEqual(round_trip.id, "mil-bcn-2026-12-05-2026-12-12")
        self.assertEqual(round_trip.return_, "2026-12-12")
        self.assertEqual({w.source for w in config.watches}, {"app"})

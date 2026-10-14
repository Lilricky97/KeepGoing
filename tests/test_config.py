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
            ({"watch": []}, "Nessun volo"),
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

    def test_expired_watches(self):
        month = parse_config({"watch": [{**WATCH, "return": None, "depart": "2026-10"}]}).watches[0]
        self.assertFalse(month.is_expired(date(2026, 10, 31)))
        self.assertTrue(month.is_expired(date(2026, 11, 1)))
        day = parse_config({"watch": [{**WATCH, "return": None, "depart": "2026-10-14"}]}).watches[0]
        self.assertTrue(day.is_expired(date(2026, 10, 15)))


if __name__ == "__main__":
    unittest.main()

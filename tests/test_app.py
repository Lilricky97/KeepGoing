import json
import tempfile
import unittest
from contextlib import redirect_stdout
from datetime import datetime, timezone
from io import StringIO
from pathlib import Path

from keepgoing.app import run_check
from keepgoing.cli import main, sparkline
from keepgoing.config import Config, Settings
from keepgoing.notifiers import NotifyError
from keepgoing.providers import ProviderError
from keepgoing.storage import Store
from tests.helpers import make_offer, make_watch

NOW = datetime(2026, 10, 14, 10, 0, tzinfo=timezone.utc)


class ScriptedProvider:
    name = "scripted"

    def __init__(self, prices):
        self.prices = prices

    def cheapest(self, watch, currency):
        price = self.prices[watch.id].pop(0)
        if isinstance(price, Exception):
            raise price
        return None if price is None else make_offer(price)


class RecordingNotifier:
    name = "recorder"

    def __init__(self, fail=False):
        self.sent = []
        self.fail = fail

    def send(self, notification):
        if self.fail:
            raise NotifyError("giù")
        self.sent.append(notification)


class RunCheckTest(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.path = Path(self.tmp.name) / "data" / "prices.json"
        self.config = Config(
            Settings(),
            [make_watch(id="a", name="A"), make_watch(id="b", name="B"), make_watch(id="old", depart="2026-01")],
        )

    def tearDown(self):
        self.tmp.cleanup()

    def run_once(self, provider, notifiers):
        store = Store(self.path)
        with redirect_stdout(StringIO()):
            result = run_check(self.config, store, notifiers, provider_factory=lambda n, s: provider, now=NOW)
        store.save()
        return result

    def test_full_cycle_saves_history_and_notifies(self):
        provider = ScriptedProvider({"a": [100, 90], "b": [ProviderError("rete"), None]})
        recorder = RecordingNotifier()
        broken = RecordingNotifier(fail=True)

        first = self.run_once(provider, [broken, recorder])
        self.assertEqual((first.checked, first.failed), (1, 1))
        self.assertEqual([e.kind for e in first.events], ["start"])

        second = self.run_once(provider, [recorder])
        self.assertEqual([e.kind for e in second.events], ["drop"])
        self.assertEqual(len(recorder.sent), 2)  # un canale rotto non blocca gli altri

        data = json.loads(self.path.read_text())
        self.assertEqual(data["version"], 1)
        self.assertEqual(data["active"], ["a", "b", "old"])
        self.assertNotIn("old", data["watches"])  # scaduto: saltato
        state = data["watches"]["a"]
        self.assertEqual([p["price"] for p in state["history"]], [100, 90])
        self.assertEqual(state["watch"]["origin"], "MIL")
        self.assertEqual(state["last"]["price"], 90)
        self.assertEqual(state["lowest"], 90)


class CliTest(unittest.TestCase):
    def test_check_and_history_with_demo_provider(self):
        with tempfile.TemporaryDirectory() as tmp:
            config = Path(tmp) / "config.toml"
            config.write_text(
                '[settings]\nprovider = "demo"\n\n[[watch]]\norigin = "MIL"\ndestination = "BCN"\ndepart = "2099-12"\n'
            )
            data = Path(tmp) / "prices.json"
            files = ["--config", str(config), "--data", str(data), "--watches", str(Path(tmp) / "watches.json")]
            out = StringIO()
            with redirect_stdout(out):
                self.assertEqual(main([*files, "check"]), 0)
                self.assertEqual(main([*files, "history"]), 0)
            self.assertIn("Monitoraggio avviato", out.getvalue())
            self.assertIn("mil-bcn-2099-12", out.getvalue())
            self.assertTrue(data.is_file())

    def test_check_uses_flights_added_from_the_app(self):
        with tempfile.TemporaryDirectory() as tmp:
            config = Path(tmp) / "config.toml"
            config.write_text('[settings]\nprovider = "demo"\n')
            watches = Path(tmp) / "watches.json"
            data = Path(tmp) / "prices.json"
            files = ["--config", str(config), "--data", str(data), "--watches", str(watches)]
            out = StringIO()
            with redirect_stdout(out):
                self.assertEqual(main([*files, "check"]), 0)  # nessun volo: non è un errore
                self.assertFalse(data.exists())  # e non salva uno storico vuoto
                watches.write_text(json.dumps({"version": 1, "watches": [
                    {"id": "fco-jfk-2099-03", "name": "Roma → New York", "origin": "FCO",
                     "destination": "JFK", "depart": "2099-03", "added_at": "2026-10-17T10:00:00Z"},
                    {"origin": "XX", "destination": "JFK", "depart": "2099-03"},
                ]}))
                self.assertEqual(main([*files, "check"]), 0)
            self.assertIn("Nessun volo da monitorare", out.getvalue())
            self.assertIn("Attenzione: Volo dall'app ignorato", out.getvalue())
            saved = json.loads(data.read_text())
            self.assertEqual(saved["active"], ["fco-jfk-2099-03"])
            self.assertEqual(saved["watches"]["fco-jfk-2099-03"]["watch"]["source"], "app")

    def test_bad_config_returns_error(self):
        out = StringIO()
        with redirect_stdout(out):
            self.assertEqual(main(["--config", "/non/esiste.toml", "check"]), 1)
        self.assertIn("non trovato", out.getvalue())

    def test_sparkline(self):
        self.assertEqual(sparkline([1, 2, 3]), "▁▅█")
        self.assertEqual(sparkline([5, 5]), "▄▄")


if __name__ == "__main__":
    unittest.main()

import json
import unittest

from keepgoing.messages import fmt_price, format_event
from keepgoing.notifiers import NotifyError, build_notifiers
from keepgoing.notifiers.apns import ApnsNotifier, build_payload
from keepgoing.notifiers.base import Notification
from keepgoing.notifiers.ntfy import NtfyNotifier
from keepgoing.notifiers.telegram import TelegramNotifier
from keepgoing.tracker import Event
from tests.helpers import FakeFetch, make_offer, make_watch


class MessagesTest(unittest.TestCase):
    def test_price_format(self):
        self.assertEqual(fmt_price(89, "EUR"), "89 €")
        self.assertEqual(fmt_price(1234.5, "EUR"), "1.234,50 €")
        self.assertEqual(fmt_price(10, "USD"), "10 $")

    def test_drop_message(self):
        watch = make_watch(target_price=90)
        offer = make_offer(
            85, departure_at="2026-12-10T09:30:00+01:00", transfers=0, flight_number="VY6312", link="https://x.test"
        )
        n = format_event(Event("drop", watch, offer, previous=100, lowest_before=95, hit_target=True))
        self.assertEqual(n.title, "🔻 Milano → Barcellona: 85 € (-15 €)")
        self.assertIn("sceso da 100 € a 85 € (-15%)", n.body)
        self.assertIn("Nuovo minimo storico", n.body)
        self.assertIn("Sotto il tuo obiettivo di 90 €", n.body)
        self.assertIn("MIL → BCN · andata 10/12/2026 09:30 · diretto · VY6312", n.body)
        self.assertTrue(n.urgent)
        self.assertEqual(n.url, "https://x.test")
        self.assertEqual(n.watch_id, "mil-bcn")

    def test_rise_message(self):
        n = format_event(Event("rise", make_watch(), make_offer(120), previous=100, lowest_before=90))
        self.assertEqual(n.title, "🔺 Milano → Barcellona: 120 € (+20 €)")
        self.assertIn("Minimo visto finora: 90 €", n.body)
        self.assertFalse(n.urgent)


class ChannelsTest(unittest.TestCase):
    def test_telegram_escapes_html(self):
        fetch = FakeFetch({"ok": True})
        TelegramNotifier("T", "42", fetch=fetch).send(Notification("A<B", "x & y", url="https://x.test", urgent=True))
        body = fetch.calls[0]["body"]
        self.assertIn("<b>A&lt;B</b>", body["text"])
        self.assertIn("x &amp; y", body["text"])
        self.assertFalse(body["disable_notification"])
        self.assertIn("/botT/sendMessage", fetch.calls[0]["url"])

    def test_telegram_error(self):
        with self.assertRaises(NotifyError):
            TelegramNotifier("T", "42", fetch=FakeFetch({"ok": False, "description": "chat not found"})).send(
                Notification("t", "b")
            )

    def test_ntfy_uses_json_publish(self):
        fetch = FakeFetch({})
        NtfyNotifier("viaggi", fetch=fetch).send(Notification("🔻 Volo", "testo", url="https://x.test"))
        call = fetch.calls[0]
        self.assertEqual(call["url"], "https://ntfy.sh")
        self.assertEqual(call["body"]["topic"], "viaggi")
        self.assertEqual(call["body"]["click"], "https://x.test")

    def test_build_notifiers_from_env(self):
        self.assertEqual([n.name for n in build_notifiers({})], ["console"])
        env = {"TELEGRAM_BOT_TOKEN": "t", "TELEGRAM_CHAT_ID": "1", "NTFY_TOPIC": "x"}
        self.assertEqual([n.name for n in build_notifiers(env)], ["console", "telegram", "ntfy"])
        with self.assertRaisesRegex(NotifyError, "APNS_TEAM_ID"):
            build_notifiers({"APNS_KEY_ID": "K"})


class FakeResponse:
    def __init__(self, status_code, body=None):
        self.status_code = status_code
        self._body = body or {}

    def json(self):
        return self._body


class FakeClient:
    def __init__(self, *responses):
        self.responses = list(responses)
        self.calls = []

    def post(self, url, json=None, headers=None):
        self.calls.append({"url": url, "json": json, "headers": headers})
        return self.responses.pop(0)


def _ec_key() -> str:
    from cryptography.hazmat.primitives import serialization
    from cryptography.hazmat.primitives.asymmetric import ec

    key = ec.generate_private_key(ec.SECP256R1())
    return key.private_bytes(
        serialization.Encoding.PEM, serialization.PrivateFormat.PKCS8, serialization.NoEncryption()
    ).decode()


try:
    import cryptography  # noqa: F401
    import jwt
except ImportError:  # dipendenze facoltative (solo per le notifiche iPhone)
    jwt = None


@unittest.skipIf(jwt is None, "installa requirements.txt per testare le notifiche iPhone")
class ApnsTest(unittest.TestCase):
    def make(self, client, tokens=("aaaa1111", "bbbb2222")):
        return ApnsNotifier(_ec_key(), "KEY123", "TEAM45", "com.test.keepgoing", list(tokens), client=client)

    def test_sends_to_every_device_with_signed_token(self):
        client = FakeClient(FakeResponse(200), FakeResponse(200))
        notifier = self.make(client)
        notifier.send(Notification("🔻 Volo", "testo", url="https://x.test", urgent=True, watch_id="mil-bcn"))
        self.assertEqual(
            [c["url"] for c in client.calls],
            [
                "https://api.sandbox.push.apple.com/3/device/aaaa1111",
                "https://api.sandbox.push.apple.com/3/device/bbbb2222",
            ],
        )
        headers = client.calls[0]["headers"]
        self.assertEqual(headers["apns-topic"], "com.test.keepgoing")
        self.assertEqual(headers["apns-priority"], "10")
        token = headers["authorization"].removeprefix("bearer ")
        self.assertEqual(jwt.get_unverified_header(token), {"alg": "ES256", "kid": "KEY123", "typ": "JWT"})
        self.assertEqual(jwt.decode(token, options={"verify_signature": False})["iss"], "TEAM45")

    def test_payload_matches_ios_app(self):
        payload = build_payload(Notification("T", "B", url="https://x.test", watch_id="mil-bcn"))
        self.assertEqual(payload["aps"]["alert"], {"title": "T", "body": "B"})
        self.assertEqual(payload["aps"]["thread-id"], "mil-bcn")
        self.assertEqual(payload["watch_id"], "mil-bcn")
        self.assertEqual(payload["url"], "https://x.test")
        json.dumps(payload)

    def test_errors_explain_the_fix(self):
        client = FakeClient(FakeResponse(400, {"reason": "BadDeviceToken"}))
        with self.assertRaisesRegex(NotifyError, "APNS_ENVIRONMENT"):
            self.make(client, tokens=["aaaa1111"]).send(Notification("T", "B"))

    def test_built_from_env(self):
        env = {
            "APNS_KEY": _ec_key(), "APNS_KEY_ID": "K", "APNS_TEAM_ID": "T",
            "APNS_BUNDLE_ID": "com.x", "APNS_DEVICE_TOKENS": "abc, d e f", "APNS_ENVIRONMENT": "production",
        }
        apns = build_notifiers(env)[1]
        self.assertEqual(apns.device_tokens, ["abc", "def"])
        self.assertEqual(apns.host, "https://api.push.apple.com")


if __name__ == "__main__":
    unittest.main()

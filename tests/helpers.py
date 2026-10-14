from keepgoing.config import Settings
from keepgoing.models import Offer, Watch


def make_watch(**overrides) -> Watch:
    values = dict(id="mil-bcn", name="Milano → Barcellona", origin="MIL", destination="BCN", depart="2026-12")
    values.update(overrides)
    return Watch(**values)


def make_offer(price: float, **overrides) -> Offer:
    values = dict(price=price, currency="EUR", provider="test")
    values.update(overrides)
    return Offer(**values)


SETTINGS = Settings()


class FakeFetch:
    """Sostituisce request_json: registra le chiamate e restituisce risposte preparate."""

    def __init__(self, *responses):
        self.responses = list(responses)
        self.calls = []

    def __call__(self, method, url, **kwargs):
        self.calls.append({"method": method, "url": url, **kwargs})
        response = self.responses.pop(0)
        if isinstance(response, Exception):
            raise response
        return response

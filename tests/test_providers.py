import unittest
from datetime import datetime, timezone

from keepgoing.config import MissingCredentials, Settings
from keepgoing.http import HttpError
from keepgoing.providers import ProviderError, build_provider
from keepgoing.providers.demo import DemoProvider
from keepgoing.providers.serpapi import SerpApiProvider
from keepgoing.providers.travelpayouts import TravelpayoutsProvider
from tests.helpers import FakeFetch, make_watch

TP_RESPONSE = {
    "success": True,
    "currency": "eur",
    "data": [
        {
            "origin": "MIL", "destination": "BCN", "origin_airport": "MXP", "destination_airport": "BCN",
            "price": 112, "airline": "FR", "flight_number": "1234", "departure_at": "2026-12-05T06:30:00+01:00",
            "return_at": "2026-12-12T21:10:00+01:00", "transfers": 0, "return_transfers": 0,
            "duration": 210, "link": "/search/MIL0512BCN12121?t=FR1",
        },
        {
            "origin": "MIL", "destination": "BCN", "price": 89, "airline": "VY", "flight_number": "6312",
            "departure_at": "2026-12-10T09:30:00+01:00", "return_at": "2026-12-17T18:00:00+01:00",
            "transfers": 1, "link": "/search/MIL1012BCN17121?t=VY1",
        },
    ],
}

SERP_RESPONSE = {
    "search_metadata": {"google_flights_url": "https://www.google.com/travel/flights?tfs=abc"},
    "best_flights": [
        {"price": 140, "flights": [{"airline": "ITA", "flight_number": "AZ 78",
                                    "departure_airport": {"id": "LIN", "time": "2026-12-10 07:00"}}], "layovers": []},
    ],
    "other_flights": [
        {"price": 99, "flights": [{"airline": "Vueling", "flight_number": "VY 6312",
                                   "departure_airport": {"id": "MXP", "time": "2026-12-10 09:30"}}],
         "layovers": [{"id": "FCO"}]},
        {"flights": []},  # senza prezzo: va ignorato
    ],
}


class TravelpayoutsTest(unittest.TestCase):
    def test_returns_cheapest_offer_with_full_link(self):
        fetch = FakeFetch(TP_RESPONSE)
        offer = TravelpayoutsProvider("tok", fetch=fetch).cheapest(make_watch(return_="2026-12"), "EUR")
        self.assertEqual(offer.price, 89)
        self.assertEqual(offer.currency, "EUR")
        self.assertEqual(offer.flight_number, "VY6312")
        self.assertEqual(offer.transfers, 1)
        self.assertEqual(offer.link, "https://www.aviasales.com/search/MIL1012BCN17121?t=VY1")
        call = fetch.calls[0]
        self.assertEqual(call["headers"], {"X-Access-Token": "tok"})
        self.assertEqual(call["params"]["one_way"], "false")
        self.assertEqual(call["params"]["return_at"], "2026-12")
        self.assertEqual(call["params"]["market"], "it")

    def test_retries_without_market_when_empty(self):
        fetch = FakeFetch({"success": True, "data": []}, TP_RESPONSE)
        offer = TravelpayoutsProvider("tok", fetch=fetch).cheapest(make_watch(), "EUR")
        self.assertEqual(offer.price, 89)
        self.assertNotIn("market", fetch.calls[1]["params"])
        self.assertEqual(fetch.calls[0]["params"]["one_way"], "true")

    def test_no_results(self):
        fetch = FakeFetch({"success": True, "data": []}, {"success": True, "data": []})
        self.assertIsNone(TravelpayoutsProvider("tok", fetch=fetch).cheapest(make_watch(), "EUR"))

    def test_errors_become_provider_errors(self):
        fetch = FakeFetch(HttpError(401, "Unauthorized"))
        with self.assertRaisesRegex(ProviderError, "token non valido"):
            TravelpayoutsProvider("bad", fetch=fetch).cheapest(make_watch(), "EUR")
        fetch = FakeFetch({"success": False, "error": "rate limit"})
        with self.assertRaisesRegex(ProviderError, "rate limit"):
            TravelpayoutsProvider("tok", fetch=fetch).cheapest(make_watch(), "EUR")


class SerpApiTest(unittest.TestCase):
    def test_cheapest_across_best_and_other_flights(self):
        fetch = FakeFetch(SERP_RESPONSE)
        watch = make_watch(depart="2026-12-10", direct_only=True)
        offer = SerpApiProvider("key", fetch=fetch).cheapest(watch, "eur")
        self.assertEqual(offer.price, 99)
        self.assertEqual(offer.flight_number, "VY 6312")
        self.assertEqual(offer.transfers, 1)
        self.assertEqual(offer.departure_at, "2026-12-10 09:30")
        self.assertEqual(offer.link, "https://www.google.com/travel/flights?tfs=abc")
        params = fetch.calls[0]["params"]
        self.assertEqual(params["type"], 2)
        self.assertEqual(params["stops"], 1)
        self.assertEqual(params["currency"], "EUR")

    def test_requires_exact_dates(self):
        with self.assertRaisesRegex(ProviderError, "date esatte"):
            SerpApiProvider("key", fetch=FakeFetch()).cheapest(make_watch(depart="2026-12"), "EUR")

    def test_no_results_is_not_an_error(self):
        fetch = FakeFetch({"error": "Google Flights hasn't returned any results for this query."})
        self.assertIsNone(SerpApiProvider("key", fetch=fetch).cheapest(make_watch(depart="2026-12-10"), "EUR"))


class DemoAndFactoryTest(unittest.TestCase):
    def test_demo_is_stable_within_the_hour_and_dates_are_ordered(self):
        clock = lambda: datetime(2026, 10, 14, 10, 15, tzinfo=timezone.utc)
        watch = make_watch(return_="2026-12")
        first = DemoProvider(clock).cheapest(watch, "EUR")
        second = DemoProvider(clock).cheapest(watch, "EUR")
        self.assertEqual(first, second)
        self.assertLessEqual(first.departure_at, first.return_at)

    def test_missing_credentials(self):
        with self.assertRaises(MissingCredentials) as ctx:
            build_provider("travelpayouts", Settings(), env={})
        self.assertEqual(ctx.exception.variable, "TRAVELPAYOUTS_TOKEN")
        with self.assertRaises(MissingCredentials):
            build_provider("serpapi", Settings(), env={})
        self.assertEqual(build_provider("demo", Settings(), env={}).name, "demo")


if __name__ == "__main__":
    unittest.main()

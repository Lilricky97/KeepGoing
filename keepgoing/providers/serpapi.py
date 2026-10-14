"""Prezzi in tempo reale da Google Flights tramite SerpApi.

Più precisi di Travelpayouts ma richiedono date esatte (YYYY-MM-DD) e il piano
gratuito ha un numero limitato di ricerche al mese: ogni controllo di ogni volo
consuma una ricerca.
"""

from __future__ import annotations

import urllib.parse

from keepgoing.http import HttpError, request_json
from keepgoing.models import Offer, Watch
from keepgoing.providers.base import ProviderError

API_URL = "https://serpapi.com/search.json"


class SerpApiProvider:
    name = "serpapi"

    def __init__(self, api_key: str, language: str = "it", country: str = "it", fetch=request_json):
        self.api_key = api_key
        self.language = language
        self.country = country
        self.fetch = fetch

    def cheapest(self, watch: Watch, currency: str) -> Offer | None:
        for value in (watch.depart, watch.return_):
            if value and len(value) != 10:
                raise ProviderError(
                    f"SerpApi (Google Flights) richiede date esatte YYYY-MM-DD, non '{value}'. "
                    f"Per monitorare un mese intero usa provider = \"travelpayouts\"."
                )
        params = {
            "engine": "google_flights",
            "departure_id": watch.origin,
            "arrival_id": watch.destination,
            "outbound_date": watch.depart,
            "type": 2 if watch.one_way else 1,
            "currency": currency.upper(),
            "hl": self.language,
            "gl": self.country,
            "api_key": self.api_key,
        }
        if watch.return_:
            params["return_date"] = watch.return_
        if watch.direct_only:
            params["stops"] = 1
        try:
            payload = self.fetch("GET", API_URL, params=params)
        except HttpError as exc:
            raise ProviderError(f"SerpApi: {exc}") from None
        if payload.get("error"):
            if "hasn't returned any results" in payload["error"]:
                return None
            raise ProviderError(f"SerpApi: {payload['error']}")

        options = (payload.get("best_flights") or []) + (payload.get("other_flights") or [])
        priced = [o for o in options if isinstance(o.get("price"), (int, float))]
        if not priced:
            return None
        best = min(priced, key=lambda o: o["price"])
        legs = best.get("flights") or [{}]
        first = legs[0]
        link = (payload.get("search_metadata") or {}).get("google_flights_url") or _google_flights_url(watch)
        return Offer(
            price=float(best["price"]),
            currency=currency.upper(),
            provider=self.name,
            airline=first.get("airline"),
            flight_number=first.get("flight_number"),
            departure_at=(first.get("departure_airport") or {}).get("time"),
            return_at=watch.return_,
            transfers=len(best.get("layovers") or []),
            link=link,
        )


def _google_flights_url(watch: Watch) -> str:
    query = f"Flights from {watch.origin} to {watch.destination} on {watch.depart}"
    if watch.return_:
        query += f" returning {watch.return_}"
    return "https://www.google.com/travel/flights?q=" + urllib.parse.quote(query)

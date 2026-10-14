"""Prezzi da Aviasales tramite la Data API gratuita di Travelpayouts.

Sono i prezzi più bassi trovati dagli utenti Aviasales nelle ultime 48 ore:
non sono prezzi in tempo reale, ma sono gratuiti e funzionano anche per un
mese intero ("depart = 2026-12"), il che li rende ottimi per seguire i trend.
"""

from __future__ import annotations

from keepgoing.http import HttpError, request_json
from keepgoing.models import Offer, Watch
from keepgoing.providers.base import ProviderError

API_URL = "https://api.travelpayouts.com/aviasales/v3/prices_for_dates"
SITE_URL = "https://www.aviasales.com"


class TravelpayoutsProvider:
    name = "travelpayouts"

    def __init__(self, token: str, market: str | None = "it", fetch=request_json):
        self.token = token
        self.market = market
        self.fetch = fetch

    def cheapest(self, watch: Watch, currency: str) -> Offer | None:
        params = {
            "origin": watch.origin,
            "destination": watch.destination,
            "departure_at": watch.depart,
            "one_way": str(watch.one_way).lower(),
            "direct": str(watch.direct_only).lower(),
            "currency": currency.lower(),
            "sorting": "price",
            "limit": 10,
        }
        if watch.return_:
            params["return_at"] = watch.return_

        offers = self._search(params, currency)
        if not offers and self.market:
            # Alcuni mercati hanno pochi dati: riprova con quello predefinito.
            offers = self._search(params, currency, use_market=False)
        return min(offers, key=lambda o: o.price) if offers else None

    def _search(self, params: dict, currency: str, use_market: bool = True) -> list[Offer]:
        if use_market and self.market:
            params = {**params, "market": self.market}
        try:
            payload = self.fetch(
                "GET", API_URL, params=params, headers={"X-Access-Token": self.token}
            )
        except HttpError as exc:
            hint = " (token non valido?)" if exc.status in (401, 403) else ""
            raise ProviderError(f"Travelpayouts: {exc}{hint}") from None
        if payload.get("success") is False:
            raise ProviderError(f"Travelpayouts: {payload.get('error') or 'errore sconosciuto'}")
        response_currency = str(payload.get("currency") or currency).upper()
        return [
            offer
            for item in payload.get("data") or []
            if (offer := _parse_item(item, response_currency)) is not None
        ]


def _parse_item(item: dict, currency: str) -> Offer | None:
    try:
        price = float(item["price"])
    except (KeyError, TypeError, ValueError):
        return None
    link = item.get("link")
    if link and link.startswith("/"):
        link = SITE_URL + link
    airline = item.get("airline")
    number = item.get("flight_number")
    return Offer(
        price=price,
        currency=currency,
        provider=TravelpayoutsProvider.name,
        airline=airline,
        flight_number=f"{airline or ''}{number}" if number else None,
        departure_at=item.get("departure_at"),
        return_at=item.get("return_at"),
        transfers=item.get("transfers"),
        link=link,
    )

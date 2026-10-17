"""Strutture dati condivise: cosa monitoriamo (Watch) e cosa troviamo (Offer)."""

from __future__ import annotations

import calendar
from dataclasses import asdict, dataclass
from datetime import date


@dataclass(frozen=True)
class Watch:
    """Una tratta da monitorare, definita in config.toml."""

    id: str
    name: str
    origin: str
    destination: str
    depart: str  # "YYYY-MM" (tutto il mese) oppure "YYYY-MM-DD"
    return_: str | None = None  # None = solo andata
    direct_only: bool = False
    target_price: float | None = None
    provider: str | None = None  # se vuoto usa quello in [settings]
    source: str = "config"  # "config" = config.toml, "app" = aggiunto dall'app (watches.json)

    @property
    def one_way(self) -> bool:
        return self.return_ is None

    @property
    def route(self) -> str:
        return f"{self.origin} → {self.destination}"

    def is_expired(self, today: date) -> bool:
        """True se la data (o l'intero mese) di partenza è già passata."""
        return last_day(self.depart) < today


def last_day(value: str) -> date:
    """Ultimo giorno valido per una data "YYYY-MM" o "YYYY-MM-DD"."""
    parts = [int(p) for p in value.split("-")]
    if len(parts) == 3:
        return date(*parts)
    year, month = parts
    return date(year, month, calendar.monthrange(year, month)[1])


@dataclass
class Offer:
    """L'offerta più economica trovata da un provider per una tratta."""

    price: float
    currency: str
    provider: str
    airline: str | None = None
    flight_number: str | None = None
    departure_at: str | None = None
    return_at: str | None = None
    transfers: int | None = None
    link: str | None = None

    def to_dict(self) -> dict:
        return asdict(self)

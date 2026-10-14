"""Decide quando un cambio di prezzo merita una notifica.

Il confronto avviene con il "prezzo di riferimento" (baseline): il prezzo
dell'ultima notifica inviata. Così anche un calo lento, pochi euro alla volta,
prima o poi supera la soglia e ti viene segnalato.
"""

from __future__ import annotations

from dataclasses import dataclass

from keepgoing.config import Settings
from keepgoing.models import Offer, Watch


@dataclass
class Event:
    kind: str  # "start" | "drop" | "rise" | "target"
    watch: Watch
    offer: Offer
    previous: float | None  # prezzo di riferimento prima di questo controllo
    lowest_before: float | None  # minimo storico prima di questo controllo
    hit_target: bool = False

    @property
    def change(self) -> float | None:
        return None if self.previous is None else self.offer.price - self.previous

    @property
    def is_record(self) -> bool:
        return self.lowest_before is not None and self.offer.price < self.lowest_before


def update(state: dict, watch: Watch, offer: Offer, settings: Settings, now: str) -> Event | None:
    """Registra il nuovo prezzo nello stato del volo e restituisce l'evento da notificare."""
    price = offer.price
    history = state.setdefault("history", [])
    history.append({"at": now, "price": price})
    del history[: -settings.history_limit]
    state["last"] = {**offer.to_dict(), "checked_at": now}

    lowest = state.get("lowest")
    if lowest is None or price < lowest:
        state["lowest"] = price
        state["lowest_at"] = now

    hit_target = False
    if watch.target_price is not None:
        if price <= watch.target_price:
            hit_target = not state.get("target_notified", False)
            state["target_notified"] = True
        else:
            state["target_notified"] = False  # si riarma se il prezzo risale

    baseline = state.get("baseline")
    if baseline is None:
        state["baseline"] = price
        return Event("start", watch, offer, None, None, hit_target)

    change = price - baseline
    threshold = max(settings.min_change_abs, baseline * settings.min_change_pct / 100)
    kind = None
    if abs(change) >= threshold:
        state["baseline"] = price
        if change < 0:
            kind = "drop"
        elif settings.notify_on == "both":
            kind = "rise"
    if kind is None and hit_target:
        state["baseline"] = price
        kind = "target"
    if kind is None:
        return None
    return Event(kind, watch, offer, baseline, lowest, hit_target)

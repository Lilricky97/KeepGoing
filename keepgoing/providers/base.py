from __future__ import annotations

from typing import Protocol

from keepgoing.models import Offer, Watch


class ProviderError(Exception):
    """La ricerca non è andata a buon fine (rete, chiave errata, limiti...)."""


class Provider(Protocol):
    name: str

    def cheapest(self, watch: Watch, currency: str) -> Offer | None:
        """Restituisce l'offerta più economica, o None se non ce ne sono."""
        ...

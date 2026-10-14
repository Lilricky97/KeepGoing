"""Provider finto per provare l'app senza chiavi API.

I prezzi cambiano ogni ora in modo pseudo-casuale (ma riproducibile), così
puoi vedere arrivare notifiche di ribasso e rialzo.
"""

from __future__ import annotations

import random
import zlib
from datetime import datetime, timezone

from keepgoing.models import Offer, Watch, last_day


class DemoProvider:
    name = "demo"

    def __init__(self, clock=lambda: datetime.now(timezone.utc)):
        self.clock = clock

    def cheapest(self, watch: Watch, currency: str) -> Offer | None:
        base = 60 + zlib.crc32(watch.id.encode()) % 190
        hour = int(self.clock().timestamp() // 3600)
        rng = random.Random(f"{watch.id}:{hour}")
        price = round(base * rng.uniform(0.7, 1.3))
        departure = _pick_day(watch.depart, rng)
        return Offer(
            price=float(price),
            currency=currency.upper(),
            provider=self.name,
            airline="KG",
            flight_number=f"KG{rng.randint(100, 999)}",
            departure_at=departure,
            return_at=_pick_day(watch.return_, rng, not_before=departure) if watch.return_ else None,
            transfers=0 if watch.direct_only else rng.choice([0, 0, 1]),
            link=None,
        )


def _pick_day(value: str, rng: random.Random, not_before: str | None = None) -> str:
    if len(value) == 10:
        return value
    first = int(not_before[-2:]) if not_before and not_before.startswith(value) else 1
    return f"{value}-{rng.randint(first, last_day(value).day):02d}"

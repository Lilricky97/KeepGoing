"""Storico prezzi su file JSON (data/prices.json).

Lo stesso file viene letto dall'app iPhone: se cambi la struttura, aggiorna
anche ios/KeepGoing/Models/PriceData.swift.
"""

from __future__ import annotations

import json
import os
from datetime import datetime, timezone
from pathlib import Path

from keepgoing.models import Watch

SCHEMA_VERSION = 1


class Store:
    def __init__(self, path: str | Path):
        self.path = Path(path)
        if self.path.is_file():
            self.data = json.loads(self.path.read_text(encoding="utf-8"))
        else:
            self.data = {}
        self.data.setdefault("version", SCHEMA_VERSION)
        self.data.setdefault("watches", {})

    def watch_state(self, watch: Watch) -> dict:
        state = self.data["watches"].setdefault(watch.id, {})
        state["watch"] = {
            "name": watch.name,
            "origin": watch.origin,
            "destination": watch.destination,
            "depart": watch.depart,
            "return": watch.return_,
            "direct_only": watch.direct_only,
            "target_price": watch.target_price,
        }
        return state

    def set_active(self, watch_ids: list[str]) -> None:
        """Ordine dei voli presenti in config.toml (quelli rimossi restano nello storico)."""
        self.data["active"] = watch_ids

    def save(self) -> None:
        self.data["updated_at"] = datetime.now(timezone.utc).isoformat(timespec="seconds")
        self.path.parent.mkdir(parents=True, exist_ok=True)
        tmp = self.path.with_suffix(".tmp")
        tmp.write_text(json.dumps(self.data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
        os.replace(tmp, self.path)

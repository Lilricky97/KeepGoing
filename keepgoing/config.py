"""Lettura e validazione di config.toml."""

from __future__ import annotations

import os
import re
import tomllib
from dataclasses import dataclass, field
from datetime import date
from pathlib import Path

from keepgoing.models import Watch, last_day

PROVIDERS = ("travelpayouts", "serpapi", "demo")
NOTIFY_ON = ("drops", "both")

_IATA = re.compile(r"^[A-Z]{3}$")
_DATE = re.compile(r"^\d{4}-\d{2}(-\d{2})?$")
_WATCH_KEYS = {
    "id", "name", "origin", "destination", "depart", "return",
    "direct_only", "target_price", "provider",
}
_SETTINGS_KEYS = {
    "provider", "currency", "notify_on", "min_change_pct",
    "min_change_abs", "market", "history_limit",
}


class ConfigError(Exception):
    """Errore nella configurazione, con un messaggio comprensibile."""


class MissingCredentials(ConfigError):
    """Manca la chiave API (variabile d'ambiente) richiesta da un provider."""

    def __init__(self, variable: str, provider: str):
        super().__init__(
            f"Manca la variabile d'ambiente {variable} richiesta dal provider "
            f"'{provider}'. Aggiungila nel file .env (in locale) o nei secrets "
            f"del repository (GitHub Actions)."
        )
        self.variable = variable


@dataclass(frozen=True)
class Settings:
    provider: str = "travelpayouts"
    currency: str = "EUR"
    notify_on: str = "both"  # "drops" = solo ribassi, "both" = ribassi e rialzi
    min_change_pct: float = 3.0
    min_change_abs: float = 5.0
    market: str = "it"  # mercato Travelpayouts da cui leggere i prezzi
    history_limit: int = 500  # punti di storico conservati per ogni volo


@dataclass(frozen=True)
class Config:
    settings: Settings
    watches: list[Watch] = field(default_factory=list)


def load_config(path: str | Path) -> Config:
    path = Path(path)
    try:
        with path.open("rb") as fh:
            raw = tomllib.load(fh)
    except FileNotFoundError:
        raise ConfigError(f"File di configurazione non trovato: {path}") from None
    except tomllib.TOMLDecodeError as exc:
        raise ConfigError(f"{path} non è un TOML valido: {exc}") from None
    return parse_config(raw)


def parse_config(raw: dict) -> Config:
    settings = _parse_settings(raw.get("settings", {}))
    watches = [_parse_watch(i, item) for i, item in enumerate(raw.get("watch", []), 1)]
    if not watches:
        raise ConfigError("Nessun volo da monitorare: aggiungi almeno un blocco [[watch]].")
    seen: set[str] = set()
    for watch in watches:
        if watch.id in seen:
            raise ConfigError(f"Due voli hanno lo stesso id '{watch.id}': aggiungi un campo id diverso.")
        seen.add(watch.id)
    return Config(settings=settings, watches=watches)


def _parse_settings(raw: dict) -> Settings:
    _reject_unknown(raw, _SETTINGS_KEYS, "[settings]")
    settings = Settings(**raw)
    if settings.provider not in PROVIDERS:
        raise ConfigError(f"provider '{settings.provider}' sconosciuto: usa uno tra {', '.join(PROVIDERS)}.")
    if settings.notify_on not in NOTIFY_ON:
        raise ConfigError(f"notify_on deve essere 'drops' oppure 'both', non '{settings.notify_on}'.")
    if not re.fullmatch(r"[A-Za-z]{3}", settings.currency):
        raise ConfigError(f"currency '{settings.currency}' non valida: usa un codice come EUR.")
    if settings.min_change_pct < 0 or settings.min_change_abs < 0:
        raise ConfigError("min_change_pct e min_change_abs non possono essere negativi.")
    if settings.history_limit < 1:
        raise ConfigError("history_limit deve essere almeno 1.")
    return Settings(**{**raw, "currency": settings.currency.upper()})


def _parse_watch(index: int, raw: dict) -> Watch:
    where = f"[[watch]] n.{index}"
    _reject_unknown(raw, _WATCH_KEYS, where)
    for key in ("origin", "destination", "depart"):
        if not raw.get(key):
            raise ConfigError(f"{where}: manca il campo obbligatorio '{key}'.")

    origin = str(raw["origin"]).upper()
    destination = str(raw["destination"]).upper()
    for key, code in (("origin", origin), ("destination", destination)):
        if not _IATA.match(code):
            raise ConfigError(f"{where}: {key} '{code}' deve essere un codice IATA di 3 lettere (es. MIL, BCN).")

    depart = _check_date(where, "depart", raw["depart"])
    return_ = _check_date(where, "return", raw["return"]) if raw.get("return") else None
    if return_ and last_day(return_) < _first_day(depart):
        raise ConfigError(f"{where}: la data di ritorno è prima della partenza.")

    provider = raw.get("provider")
    if provider is not None and provider not in PROVIDERS:
        raise ConfigError(f"{where}: provider '{provider}' sconosciuto.")

    target = raw.get("target_price")
    watch_id = raw.get("id") or "-".join(
        p for p in (origin, destination, depart, return_) if p
    ).lower()
    return Watch(
        id=str(watch_id),
        name=str(raw.get("name") or f"{origin} → {destination}"),
        origin=origin,
        destination=destination,
        depart=depart,
        return_=return_,
        direct_only=bool(raw.get("direct_only", False)),
        target_price=float(target) if target is not None else None,
        provider=provider,
    )


def _check_date(where: str, key: str, value) -> str:
    value = str(value)
    if not _DATE.match(value):
        raise ConfigError(f"{where}: {key} '{value}' deve essere nel formato YYYY-MM oppure YYYY-MM-DD.")
    try:
        last_day(value)
    except ValueError:
        raise ConfigError(f"{where}: {key} '{value}' non è una data valida.") from None
    return value


def _first_day(value: str) -> date:
    parts = [int(p) for p in value.split("-")]
    return date(parts[0], parts[1], parts[2] if len(parts) == 3 else 1)


def _reject_unknown(raw: dict, allowed: set[str], where: str) -> None:
    unknown = sorted(set(raw) - allowed)
    if unknown:
        raise ConfigError(f"{where}: campo sconosciuto {', '.join(unknown)} (refuso?).")


def load_dotenv(path: str | Path = ".env") -> None:
    """Carica KEY=VALUE da un file .env senza sovrascrivere variabili già impostate."""
    path = Path(path)
    if not path.is_file():
        return
    for line in path.read_text(encoding="utf-8").splitlines():
        line = line.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        key, value = line.split("=", 1)
        os.environ.setdefault(key.strip(), value.strip().strip("'\""))

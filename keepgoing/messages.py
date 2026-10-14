"""Testi delle notifiche, in italiano."""

from __future__ import annotations

from datetime import datetime

from keepgoing.models import Offer, Watch
from keepgoing.notifiers.base import Notification
from keepgoing.tracker import Event

_SYMBOLS = {"EUR": "€", "USD": "$", "GBP": "£", "CHF": "CHF"}


def fmt_price(value: float, currency: str = "EUR") -> str:
    """89 → "89 €", 1234.5 → "1.234,50 €"."""
    decimals = 0 if float(value).is_integer() else 2
    number = f"{value:,.{decimals}f}".replace(",", "_").replace(".", ",").replace("_", ".")
    return f"{number} {_SYMBOLS.get(currency.upper(), currency.upper())}"


def fmt_change(value: float, currency: str = "EUR") -> str:
    sign = "+" if value > 0 else "-"
    return f"{sign}{fmt_price(abs(value), currency)}"


def fmt_date(value: str | None) -> str | None:
    if not value:
        return None
    try:
        parsed = datetime.fromisoformat(value.replace("Z", "+00:00"))
    except ValueError:
        return value
    if len(value) <= 10:
        return parsed.strftime("%d/%m/%Y")
    return parsed.strftime("%d/%m/%Y %H:%M")


def describe_offer(watch: Watch, offer: Offer) -> str:
    parts = [watch.route]
    if departure := fmt_date(offer.departure_at):
        parts.append(f"andata {departure}")
    if ret := fmt_date(offer.return_at):
        parts.append(f"ritorno {ret}")
    if offer.transfers is not None:
        parts.append({0: "diretto", 1: "1 scalo"}.get(offer.transfers, f"{offer.transfers} scali"))
    if offer.flight_number or offer.airline:
        parts.append(offer.flight_number or offer.airline)
    return " · ".join(parts)


def format_event(event: Event) -> Notification:
    watch, offer = event.watch, event.offer
    cur = offer.currency
    price = fmt_price(offer.price, cur)
    target = fmt_price(watch.target_price, cur) if watch.target_price is not None else None

    if event.kind == "start":
        title = f"👀 {watch.name}: {price}"
        lines = [f"Monitoraggio avviato. Il prezzo più basso adesso è {price}."]
    elif event.kind in ("drop", "rise"):
        arrow, verb = ("🔻", "sceso") if event.kind == "drop" else ("🔺", "salito")
        pct = abs(event.change) / event.previous * 100 if event.previous else 0
        title = f"{arrow} {watch.name}: {price} ({fmt_change(event.change, cur)})"
        sign = "-" if event.kind == "drop" else "+"
        lines = [f"Il prezzo è {verb} da {fmt_price(event.previous, cur)} a {price} ({sign}{pct:.0f}%)."]
    else:  # target
        title = f"🎯 {watch.name}: {price}"
        lines = [f"Il prezzo è sceso sotto il tuo obiettivo di {target}."]

    if event.is_record:
        lines.append("🏆 Nuovo minimo storico!")
    if event.hit_target and event.kind != "target":
        lines.append(f"🎯 Sotto il tuo obiettivo di {target}!")
    lines.append(f"✈️ {describe_offer(watch, offer)}")
    if event.lowest_before is not None and not event.is_record:
        lines.append(f"Minimo visto finora: {fmt_price(event.lowest_before, cur)}")

    return Notification(
        title=title,
        body="\n".join(lines),
        url=offer.link,
        urgent=event.kind in ("drop", "target") or event.hit_target,
        watch_id=watch.id,
    )

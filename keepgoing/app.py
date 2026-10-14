"""Un giro di controllo: chiede i prezzi, aggiorna lo storico, invia le notifiche."""

from __future__ import annotations

from dataclasses import dataclass, field
from datetime import datetime, timezone

from keepgoing import tracker
from keepgoing.config import Config
from keepgoing.messages import fmt_price, format_event
from keepgoing.notifiers import Notifier, NotifyError
from keepgoing.providers import ProviderError, build_provider
from keepgoing.storage import Store

_LABELS = {"start": "👀 primo prezzo", "drop": "🔻 ribasso", "rise": "🔺 rialzo", "target": "🎯 obiettivo"}


@dataclass
class CheckResult:
    checked: int = 0
    failed: int = 0
    events: list[tracker.Event] = field(default_factory=list)


def run_check(
    config: Config,
    store: Store,
    notifiers: list[Notifier],
    *,
    provider_factory=build_provider,
    now: datetime | None = None,
) -> CheckResult:
    now = now or datetime.now(timezone.utc)
    stamp = now.isoformat(timespec="seconds")
    providers = {}
    result = CheckResult()
    store.set_active([w.id for w in config.watches])

    for watch in config.watches:
        label = f"[{watch.name}]"
        if watch.is_expired(now.date()):
            print(f"{label} date già passate: lo salto (puoi toglierlo da config.toml)")
            continue
        name = watch.provider or config.settings.provider
        try:
            if name not in providers:
                providers[name] = provider_factory(name, config.settings)
            offer = providers[name].cheapest(watch, config.settings.currency)
        except ProviderError as exc:
            result.failed += 1
            print(f"{label} errore: {exc}")
            continue
        result.checked += 1
        if offer is None:
            print(f"{label} nessuna offerta trovata ({name})")
            continue

        event = tracker.update(store.watch_state(watch), watch, offer, config.settings, stamp)
        status = _LABELS[event.kind] if event else "nessuna novità"
        print(f"{label} {fmt_price(offer.price, offer.currency)} ({name}) — {status}")
        if event:
            result.events.append(event)
            notification = format_event(event)
            for notifier in notifiers:
                try:
                    notifier.send(notification)
                except NotifyError as exc:
                    print(f"{label} notifica non inviata: {exc}")
    return result

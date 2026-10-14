"""Comandi da terminale: python -m keepgoing <comando>."""

from __future__ import annotations

import argparse
import os
import time

from keepgoing import __version__
from keepgoing.app import run_check
from keepgoing.config import ConfigError, MissingCredentials, load_config, load_dotenv
from keepgoing.messages import fmt_date, fmt_price
from keepgoing.notifiers import Notification, NotifyError, build_notifiers
from keepgoing.notifiers.console import ConsoleNotifier
from keepgoing.storage import Store

_SPARK = "▁▂▃▄▅▆▇█"


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(
        prog="keepgoing",
        description="Monitora i prezzi dei voli e ti avvisa quando cambiano.",
    )
    parser.add_argument("--config", default="config.toml", help="file di configurazione (default: config.toml)")
    parser.add_argument("--data", default="data/prices.json", help="storico prezzi (default: data/prices.json)")
    parser.add_argument("--version", action="version", version=f"KeepGoing {__version__}")
    sub = parser.add_subparsers(dest="command", required=True)

    check = sub.add_parser("check", help="controlla i prezzi una volta")
    check.add_argument("--dry-run", action="store_true", help="mostra i risultati senza inviare notifiche né salvare")
    check.add_argument(
        "--skip-if-unconfigured",
        action="store_true",
        help="se manca la chiave API esce senza errore (usato da GitHub Actions)",
    )
    loop = sub.add_parser("watch", help="controlla i prezzi in continuazione")
    loop.add_argument("--every", type=int, default=180, metavar="MINUTI", help="minuti tra i controlli (default: 180)")
    sub.add_parser("test-notify", help="invia una notifica di prova su tutti i canali configurati")
    history = sub.add_parser("history", help="mostra lo storico dei prezzi")
    history.add_argument("watch_id", nargs="?", help="id del volo (senza: riepilogo di tutti)")
    history.add_argument("-n", type=int, default=15, help="quanti controlli mostrare (default: 15)")

    args = parser.parse_args(argv)
    load_dotenv()
    try:
        if args.command == "check":
            return _check(args)
        if args.command == "watch":
            return _watch(args)
        if args.command == "test-notify":
            return _test_notify()
        return _history(args)
    except (ConfigError, NotifyError) as exc:
        print(f"Errore: {exc}")
        return 1


def _check(args) -> int:
    config = load_config(args.config)
    store = Store(args.data)
    notifiers = [ConsoleNotifier()] if args.dry_run else build_notifiers()
    try:
        result = run_check(config, store, notifiers)
    except MissingCredentials as exc:
        if args.skip_if_unconfigured:
            print(f"KeepGoing non è ancora configurato, salto il controllo. {exc}")
            if os.environ.get("GITHUB_ACTIONS"):
                print(f"::warning title=KeepGoing non configurato::{exc}")
            return 0
        raise
    if not args.dry_run:
        store.save()
    print(f"Voli controllati: {result.checked} · notifiche: {len(result.events)} · errori: {result.failed}")
    return 1 if result.failed and not result.checked else 0


def _watch(args) -> int:
    print(f"Controllo ogni {args.every} minuti. Premi Ctrl+C per fermare.")
    try:
        while True:
            _check(argparse.Namespace(**vars(args), dry_run=False, skip_if_unconfigured=False))
            time.sleep(args.every * 60)
    except KeyboardInterrupt:
        print("\nFermato.")
        return 0


def _test_notify() -> int:
    notifiers = build_notifiers()
    names = ", ".join(n.name for n in notifiers)
    print(f"Canali attivi: {names}")
    if len(notifiers) == 1:
        print("Solo la console è attiva: configura le notifiche iPhone (vedi README).")
    notification = Notification(
        title="✅ KeepGoing funziona",
        body="Questa è una notifica di prova: se la vedi, le notifiche sono configurate bene.",
    )
    failed = 0
    for notifier in notifiers:
        try:
            notifier.send(notification)
            print(f"  {notifier.name}: inviata")
        except NotifyError as exc:
            failed += 1
            print(f"  {notifier.name}: ERRORE — {exc}")
    return 1 if failed else 0


def _history(args) -> int:
    watches = Store(args.data).data["watches"]
    if not watches:
        print("Nessuno storico ancora: esegui prima 'python -m keepgoing check'.")
        return 0
    if args.watch_id:
        state = watches.get(args.watch_id)
        if state is None:
            print(f"Nessun volo con id '{args.watch_id}'. Disponibili: {', '.join(watches)}")
            return 1
        cur = state.get("last", {}).get("currency", "EUR")
        print(f"{args.watch_id} · {state.get('watch', {}).get('name', '')}")
        for point in state.get("history", [])[-args.n:]:
            print(f"  {fmt_date(point['at'])}  {fmt_price(point['price'], cur)}")
        return 0
    for watch_id, state in watches.items():
        history = state.get("history", [])
        if not history:
            continue
        cur = state.get("last", {}).get("currency", "EUR")
        print(f"{watch_id} · {state.get('watch', {}).get('name', '')}")
        print(
            f"  ultimo {fmt_price(history[-1]['price'], cur)} ({fmt_date(history[-1]['at'])})"
            f" · minimo {fmt_price(state['lowest'], cur)} · {sparkline([p['price'] for p in history[-30:]])}"
        )
    return 0


def sparkline(values: list[float]) -> str:
    low, high = min(values), max(values)
    if high == low:
        return _SPARK[3] * len(values)
    return "".join(_SPARK[round((v - low) / (high - low) * (len(_SPARK) - 1))] for v in values)

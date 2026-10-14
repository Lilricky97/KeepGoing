"""Canali di notifica. La console è sempre attiva; gli altri si accendono con le variabili d'ambiente."""

from __future__ import annotations

import os
from pathlib import Path

from keepgoing.notifiers.apns import ApnsNotifier
from keepgoing.notifiers.base import Notification, Notifier, NotifyError
from keepgoing.notifiers.console import ConsoleNotifier
from keepgoing.notifiers.ntfy import NtfyNotifier
from keepgoing.notifiers.telegram import TelegramNotifier

__all__ = ["Notification", "Notifier", "NotifyError", "build_notifiers"]

APNS_VARS = ("APNS_KEY_ID", "APNS_TEAM_ID", "APNS_BUNDLE_ID", "APNS_DEVICE_TOKENS")


def build_notifiers(env=os.environ) -> list[Notifier]:
    notifiers: list[Notifier] = [ConsoleNotifier()]
    if apns := _build_apns(env):
        notifiers.append(apns)
    if env.get("TELEGRAM_BOT_TOKEN") and env.get("TELEGRAM_CHAT_ID"):
        notifiers.append(TelegramNotifier(env["TELEGRAM_BOT_TOKEN"], env["TELEGRAM_CHAT_ID"]))
    if env.get("NTFY_TOPIC"):
        notifiers.append(
            NtfyNotifier(
                env["NTFY_TOPIC"],
                server=env.get("NTFY_SERVER") or "https://ntfy.sh",
                token=env.get("NTFY_TOKEN") or None,
            )
        )
    return notifiers


def _build_apns(env) -> ApnsNotifier | None:
    key = env.get("APNS_KEY")
    if not key and env.get("APNS_KEY_FILE"):
        try:
            key = Path(env["APNS_KEY_FILE"]).read_text(encoding="utf-8")
        except OSError:
            raise NotifyError(f"Notifiche iPhone: non trovo il file {env['APNS_KEY_FILE']}.") from None
    if not key and not any(env.get(v) for v in APNS_VARS):
        return None  # canale non configurato
    missing = [v for v in APNS_VARS if not env.get(v)] + ([] if key else ["APNS_KEY"])
    if missing:
        raise NotifyError(f"Notifiche iPhone: mancano {', '.join(missing)}.")
    tokens = [t.strip().replace(" ", "") for t in env["APNS_DEVICE_TOKENS"].split(",") if t.strip()]
    return ApnsNotifier(
        key=key,
        key_id=env["APNS_KEY_ID"],
        team_id=env["APNS_TEAM_ID"],
        bundle_id=env["APNS_BUNDLE_ID"],
        device_tokens=tokens,
        environment=env.get("APNS_ENVIRONMENT") or "development",
    )

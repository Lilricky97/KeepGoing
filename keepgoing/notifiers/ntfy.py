from __future__ import annotations

from keepgoing.http import HttpError, request_json
from keepgoing.notifiers.base import Notification, NotifyError


class NtfyNotifier:
    """Notifiche push sul telefono con l'app gratuita ntfy (https://ntfy.sh)."""

    name = "ntfy"

    def __init__(self, topic: str, server: str = "https://ntfy.sh", token: str | None = None, fetch=request_json):
        self.topic = topic
        self.server = server.rstrip("/")
        self.token = token
        self.fetch = fetch

    def send(self, notification: Notification) -> None:
        body = {
            "topic": self.topic,
            "title": notification.title,
            "message": notification.body,
            "priority": 4 if notification.urgent else 3,
        }
        if notification.url:
            body["click"] = notification.url
            body["actions"] = [{"action": "view", "label": "Apri l'offerta", "url": notification.url}]
        headers = {"Authorization": f"Bearer {self.token}"} if self.token else None
        try:
            # Pubblicazione JSON: titolo e testo possono contenere emoji e accenti.
            self.fetch("POST", self.server, body=body, headers=headers)
        except HttpError as exc:
            raise NotifyError(f"ntfy: {exc}") from None

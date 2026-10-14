from __future__ import annotations

from dataclasses import dataclass
from typing import Protocol


@dataclass
class Notification:
    title: str
    body: str
    url: str | None = None
    urgent: bool = False  # ribassi e obiettivi raggiunti: notifica con priorità alta
    watch_id: str | None = None  # l'app iPhone lo usa per aprire il volo giusto


class NotifyError(Exception):
    pass


class Notifier(Protocol):
    name: str

    def send(self, notification: Notification) -> None: ...

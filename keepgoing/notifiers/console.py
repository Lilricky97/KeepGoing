from __future__ import annotations

from keepgoing.notifiers.base import Notification


class ConsoleNotifier:
    name = "console"

    def send(self, notification: Notification) -> None:
        print(f"\n  {notification.title}")
        for line in notification.body.splitlines():
            print(f"  {line}")
        if notification.url:
            print(f"  {notification.url}")
        print()

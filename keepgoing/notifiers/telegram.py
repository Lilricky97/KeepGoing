from __future__ import annotations

import html

from keepgoing.http import HttpError, request_json
from keepgoing.notifiers.base import Notification, NotifyError


class TelegramNotifier:
    name = "telegram"

    def __init__(self, bot_token: str, chat_id: str, fetch=request_json):
        self.bot_token = bot_token
        self.chat_id = chat_id
        self.fetch = fetch

    def send(self, notification: Notification) -> None:
        text = f"<b>{html.escape(notification.title)}</b>\n{html.escape(notification.body)}"
        if notification.url:
            text += f'\n\n<a href="{html.escape(notification.url)}">Apri l\'offerta</a>'
        try:
            response = self.fetch(
                "POST",
                f"https://api.telegram.org/bot{self.bot_token}/sendMessage",
                body={
                    "chat_id": self.chat_id,
                    "text": text,
                    "parse_mode": "HTML",
                    "disable_web_page_preview": True,
                    "disable_notification": not notification.urgent,
                },
            )
        except HttpError as exc:
            raise NotifyError(f"Telegram: {exc}") from None
        if not response.get("ok", False):
            raise NotifyError(f"Telegram: {response.get('description') or 'invio fallito'}")

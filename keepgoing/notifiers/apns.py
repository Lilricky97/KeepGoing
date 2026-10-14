"""Notifiche push all'app iPhone KeepGoing tramite Apple Push Notification service.

APNs parla solo HTTP/2, che la libreria standard non supporta: per questo canale
servono httpx[http2] e PyJWT[crypto] (vedi requirements.txt).
"""

from __future__ import annotations

import time

from keepgoing.notifiers.base import Notification, NotifyError

HOSTS = {
    "development": "https://api.sandbox.push.apple.com",  # app installata da Xcode
    "production": "https://api.push.apple.com",  # TestFlight / App Store
}
TOKEN_TTL = 50 * 60  # Apple accetta token JWT fino a 60 minuti


class ApnsNotifier:
    name = "iphone"

    def __init__(
        self,
        key: str,
        key_id: str,
        team_id: str,
        bundle_id: str,
        device_tokens: list[str],
        environment: str = "development",
        client=None,
    ):
        if environment not in HOSTS:
            raise NotifyError("APNS_ENVIRONMENT deve essere 'development' o 'production'.")
        self.key = key.replace("\\n", "\n").strip()
        self.key_id = key_id
        self.team_id = team_id
        self.bundle_id = bundle_id
        self.device_tokens = device_tokens
        self.host = HOSTS[environment]
        self._client = client
        self._jwt: tuple[float, str] | None = None

    def send(self, notification: Notification) -> None:
        client = self._get_client()
        headers = {
            "authorization": f"bearer {self._auth_token()}",
            "apns-topic": self.bundle_id,
            "apns-push-type": "alert",
            "apns-priority": "10" if notification.urgent else "5",
        }
        payload = build_payload(notification)
        errors = []
        for device in self.device_tokens:
            try:
                response = client.post(f"{self.host}/3/device/{device}", json=payload, headers=headers)
            except Exception as exc:  # errori di rete di httpx
                errors.append(f"{device[:8]}…: {exc}")
                continue
            if response.status_code != 200:
                errors.append(f"{device[:8]}…: {_reason(response)}")
        if errors:
            raise NotifyError("iPhone (APNs): " + "; ".join(errors))

    def _auth_token(self) -> str:
        now = time.time()
        if self._jwt is None or now - self._jwt[0] > TOKEN_TTL:
            import jwt  # PyJWT

            token = jwt.encode(
                {"iss": self.team_id, "iat": int(now)},
                self.key,
                algorithm="ES256",
                headers={"kid": self.key_id},
            )
            self._jwt = (now, token)
        return self._jwt[1]

    def _get_client(self):
        if self._client is None:
            try:
                import httpx
            except ImportError:
                raise NotifyError(
                    "iPhone (APNs): installa le dipendenze con 'pip install -r requirements.txt'"
                ) from None
            self._client = httpx.Client(http2=True, timeout=30)
        return self._client


def build_payload(notification: Notification) -> dict:
    watch_id = notification.watch_id
    aps = {
        "alert": {"title": notification.title, "body": notification.body},
        "sound": "default",
    }
    if watch_id:
        aps["thread-id"] = watch_id  # raggruppa le notifiche dello stesso volo
    payload = {"aps": aps}
    if watch_id:
        payload["watch_id"] = watch_id
    if notification.url:
        payload["url"] = notification.url
    return payload


def _reason(response) -> str:
    try:
        reason = response.json().get("reason", "")
    except ValueError:
        reason = ""
    hints = {
        "BadDeviceToken": " (token del dispositivo errato o APNS_ENVIRONMENT sbagliato)",
        "Unregistered": " (l'app è stata disinstallata: aggiorna il token)",
        "InvalidProviderToken": " (controlla APNS_KEY, APNS_KEY_ID e APNS_TEAM_ID)",
        "DeviceTokenNotForTopic": " (APNS_BUNDLE_ID non coincide con quello dell'app)",
        "TopicDisallowed": " (APNS_BUNDLE_ID non coincide con quello dell'app)",
    }
    return f"HTTP {response.status_code} {reason}{hints.get(reason, '')}".strip()

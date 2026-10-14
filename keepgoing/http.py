"""Client HTTP minimale basato solo sulla libreria standard (nessuna dipendenza)."""

from __future__ import annotations

import json
import urllib.error
import urllib.parse
import urllib.request

from keepgoing import __version__

USER_AGENT = f"KeepGoing/{__version__} (+https://github.com/Lilricky97/KeepGoing)"
TIMEOUT = 30


class HttpError(Exception):
    def __init__(self, status: int, detail: str):
        super().__init__(f"HTTP {status}: {detail}" if status else detail)
        self.status = status


def request_json(
    method: str,
    url: str,
    *,
    params: dict | None = None,
    headers: dict | None = None,
    body: dict | None = None,
    timeout: float = TIMEOUT,
) -> dict:
    if params:
        url = f"{url}?{urllib.parse.urlencode(params)}"
    all_headers = {"User-Agent": USER_AGENT, "Accept": "application/json", **(headers or {})}
    data = None
    if body is not None:
        data = json.dumps(body).encode("utf-8")
        all_headers["Content-Type"] = "application/json"
    req = urllib.request.Request(url, data=data, headers=all_headers, method=method)
    try:
        with urllib.request.urlopen(req, timeout=timeout) as resp:
            raw = resp.read()
    except urllib.error.HTTPError as exc:
        # Mai includere l'URL: per alcuni provider contiene la chiave API.
        detail = exc.read().decode("utf-8", "replace").strip()[:300]
        raise HttpError(exc.code, detail or str(exc.reason)) from None
    except (urllib.error.URLError, TimeoutError, OSError) as exc:
        raise HttpError(0, f"connessione fallita ({getattr(exc, 'reason', exc)})") from None
    try:
        return json.loads(raw) if raw else {}
    except json.JSONDecodeError:
        raise HttpError(0, "risposta non in formato JSON") from None

"""Fonti dei prezzi dei voli."""

from __future__ import annotations

import os

from keepgoing.config import MissingCredentials, Settings
from keepgoing.providers.base import Provider, ProviderError
from keepgoing.providers.demo import DemoProvider
from keepgoing.providers.serpapi import SerpApiProvider
from keepgoing.providers.travelpayouts import TravelpayoutsProvider

__all__ = ["Provider", "ProviderError", "build_provider"]


def build_provider(name: str, settings: Settings, env=os.environ) -> Provider:
    if name == "travelpayouts":
        token = env.get("TRAVELPAYOUTS_TOKEN")
        if not token:
            raise MissingCredentials("TRAVELPAYOUTS_TOKEN", name)
        return TravelpayoutsProvider(token, market=settings.market or None)
    if name == "serpapi":
        key = env.get("SERPAPI_KEY")
        if not key:
            raise MissingCredentials("SERPAPI_KEY", name)
        return SerpApiProvider(key)
    if name == "demo":
        return DemoProvider()
    raise ValueError(f"provider sconosciuto: {name}")

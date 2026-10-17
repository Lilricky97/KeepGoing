# KeepGoing — note per lo sviluppo

App che monitora i prezzi dei voli e notifica l'iPhone. Due parti:

- `keepgoing/` — motore Python (solo libreria standard; `httpx` e `PyJWT` servono solo per APNs). Gira su GitHub Actions (`.github/workflows/check-prices.yml`).
- `ios/` — app SwiftUI (iOS 17+). Il progetto Xcode usa una cartella sincronizzata: i file nuovi in `ios/KeepGoing/` vengono inclusi automaticamente.

Il contratto tra le due parti:
- `data/prices.json`: scritto da `keepgoing/storage.py`, letto da `ios/KeepGoing/Models/PriceData.swift`.
- `watches.json`: scritto dall'app (`ios/KeepGoing/Models/AppWatch.swift`, via API GitHub), letto da `keepgoing/config.py` (`load_app_watches`). `tests/fixtures/watches-from-app.json` è un file scritto dal codice Swift: se cambi il formato, rigeneralo.
- Payload push: `keepgoing/notifiers/apns.py` → `AppDelegate.swift`, chiave `watch_id`; esempio in `ios/notifica-di-prova.apns`.

Se cambi una parte, aggiorna l'altra.

## Convenzioni

- Testi per l'utente (notifiche, CLI, app, README) in italiano; identificatori in inglese.
- Test: `python -m unittest` (devono passare prima di ogni commit). L'app viene compilata e avviata nel simulatore da `.github/workflows/ios.yml` (screenshot negli artifact); in Debug `-kgScreen search|results|flights|detail|settings` apre una schermata precisa.

## Nuova versione

1. Aggiorna `__version__` in `keepgoing/__init__.py` e `MARKETING_VERSION` nel progetto Xcode.
2. Aggiorna `README.md` e aggiungi in cima a `CHANGELOG.md` una sezione `## vX.Y.Z — AAAA-MM-GG` (prima riga = riassunto, poi elenco).
3. Copia il README in `docs/versions/vX.Y.Z.md`.
4. Rigenera la nota Obsidian: `python3 tools/obsidian_note.py`.

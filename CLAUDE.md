# KeepGoing — note per lo sviluppo

App per iPhone e Mac che cerca voli su Google Voli, notifica i cambi di prezzo, analizza quando conviene e confronta i prezzi tra paesi.

- `ios/` — l'app SwiftUI, un solo target per iOS 17+ e macOS 14+ (le differenze tra piattaforme stanno in `Views/Platform.swift` e in `#if os(...)`), autonoma: cerca su Google Voli via SerpApi (`Services/GoogleFlightsClient.swift`), salva i voli monitorati sul telefono (`Services/MonitorStore.swift`), li ricontrolla (iPhone: ad app chiusa con `Services/BackgroundRefresh.swift`, identificatore in `ios/KeepGoing-Info.plist`; Mac: ogni 15 minuti finché l'app è aperta, con l'icona nella barra dei menu) e manda notifiche locali. Analisi per i grafici in `Models/PriceAnalysis.swift`, confronto tra paesi (`gl` di Google Voli) in `Models/Markets.swift`. Il progetto Xcode usa una cartella sincronizzata: i file nuovi in `ios/KeepGoing/` vengono inclusi automaticamente.
- `keepgoing/` — motore Python facoltativo, indipendente dall'app (solo libreria standard; `httpx` e `PyJWT` servono solo per APNs). Gira su GitHub Actions (`.github/workflows/check-prices.yml`) con i voli di `config.toml`/`watches.json`.

La logica delle notifiche esiste in due copie che devono restare uguali: `keepgoing/tracker.py` + `keepgoing/messages.py` e `ios/KeepGoing/Models/PriceTracker.swift` (soglia 5 € e 3% rispetto all'ultima notifica, obiettivo, minimo storico).

## Convenzioni

- Testi per l'utente (notifiche, CLI, app, README) in italiano; identificatori in inglese.
- Test: `python -m unittest` (devono passare prima di ogni commit). L'app viene compilata e avviata nel simulatore da `.github/workflows/ios.yml` (screenshot negli artifact); in Debug `-kgScreen search|results|compare|key|flights|detail|settings` apre una schermata precisa (con voli di esempio), anche sul Mac. La parte non grafica dell'app (modelli, PriceTracker, client) compila anche con Swift su Linux.

## Nuova versione

1. Aggiorna `__version__` in `keepgoing/__init__.py` e `MARKETING_VERSION` nel progetto Xcode.
2. Aggiorna `README.md` e aggiungi in cima a `CHANGELOG.md` una sezione `## vX.Y.Z — AAAA-MM-GG` (prima riga = riassunto, poi elenco).
3. Copia il README in `docs/versions/vX.Y.Z.md`.
4. Rigenera la nota Obsidian: `python3 tools/obsidian_note.py`.

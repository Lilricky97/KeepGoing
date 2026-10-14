# Changelog

Tutte le versioni di KeepGoing. Il README completo di ogni versione è in `docs/versions/`.

## v0.1.0 — 2026-10-14

Prima versione: motore che controlla i prezzi ogni 3 ore e app iPhone che riceve le notifiche push.

- Motore Python senza server: gira gratis su GitHub Actions ogni 3 ore e salva lo storico in `data/prices.json`.
- Voli da monitorare in `config.toml`: tratta, mese o giorno preciso, andata e ritorno o solo andata, solo diretti, prezzo obiettivo.
- Fonti dei prezzi: Travelpayouts/Aviasales (gratis), Google Flights tramite SerpApi, demo.
- Notifiche per primo prezzo, ribasso, rialzo (disattivabile), prezzo obiettivo raggiunto e minimo storico, con soglie anti-spam (5 € e 3%).
- Notifiche push all'app iPhone tramite Apple Push Notification service; Telegram e ntfy come canali extra facoltativi.
- App iPhone (SwiftUI, iOS 17+): lista dei voli, grafico del prezzo, dettagli e link all'offerta, apertura del volo toccando la notifica, codice del dispositivo da copiare.
- Nota Obsidian con i README di tutte le versioni (`obsidian/KeepGoing - Versioni.md`).

# Changelog

Tutte le versioni di KeepGoing. Il README completo di ogni versione è in `docs/versions/`.

## v0.2.0 — 2026-10-17

I voli si cercano e si aggiungono direttamente dall'app.

- Nuova scheda **Cerca**: partenza e arrivo con suggerimenti mentre scrivi, mese intero o giorno preciso, andata e ritorno o solo andata, solo voli diretti.
- Risultati dal più economico con logo della compagnia, orari, scali e durata; toccandone uno si apre l'offerta su Aviasales.
- **Monitora questo volo** (con prezzo obiettivo facoltativo) salva il volo su GitHub e fa partire subito il primo controllo.
- **I miei voli**: voli in attesa del primo controllo e possibilità di smettere di monitorarli.
- Impostazioni come scheda, con i token Travelpayouts (ricerca) e GitHub (salvataggio dei voli).
- Il motore legge i voli dell'app da `watches.json`; un volo sbagliato non blocca gli altri e senza voli non salva uno storico vuoto.
- `config.toml` ora contiene solo le impostazioni (i voli a mano restano possibili).

## v0.1.1 — 2026-10-14

L'app si prova nel simulatore di Xcode, senza iPhone né account sviluppatore.

- Voli di esempio nell'app finché il motore non ha fatto il primo controllo dei prezzi.
- Nel simulatore non serve firmare l'app; le notifiche si provano trascinando `ios/notifica-di-prova.apns` sulla finestra.
- L'app viene compilata e avviata nel simulatore su un Mac di GitHub a ogni modifica, con screenshot.

## v0.1.0 — 2026-10-14

Prima versione: motore che controlla i prezzi ogni 3 ore e app iPhone che riceve le notifiche push.

- Motore Python senza server: gira gratis su GitHub Actions ogni 3 ore e salva lo storico in `data/prices.json`.
- Voli da monitorare in `config.toml`: tratta, mese o giorno preciso, andata e ritorno o solo andata, solo diretti, prezzo obiettivo.
- Fonti dei prezzi: Travelpayouts/Aviasales (gratis), Google Flights tramite SerpApi, demo.
- Notifiche per primo prezzo, ribasso, rialzo (disattivabile), prezzo obiettivo raggiunto e minimo storico, con soglie anti-spam (5 € e 3%).
- Notifiche push all'app iPhone tramite Apple Push Notification service; Telegram e ntfy come canali extra facoltativi.
- App iPhone (SwiftUI, iOS 17+): lista dei voli, grafico del prezzo, dettagli e link all'offerta, apertura del volo toccando la notifica, codice del dispositivo da copiare.
- Nota Obsidian con i README di tutte le versioni (`obsidian/KeepGoing - Versioni.md`).

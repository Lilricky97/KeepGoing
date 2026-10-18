# Changelog

Tutte le versioni di KeepGoing. Il README completo di ogni versione è in `docs/versions/`.

## v0.4.0 — 2026-10-18

App anche per Mac, grafici subito, orari e giorni convenienti e confronto dei prezzi tra paesi per la VPN.

- La stessa app gira su iPhone e su Mac; sul Mac resta nella barra dei menu e ricontrolla i prezzi da sola finché è aperta.
- Nei risultati della ricerca: andamento del prezzo degli ultimi giorni secondo Google e prezzo per orario di partenza, con la fascia più economica.
- Dettaglio di un volo: si aggiorna all'apertura se l'ultimo controllo ha più di un'ora; nuova sezione "Quando conviene" con il giorno della settimana e l'ora del giorno in cui il prezzo è più basso.
- "Dove conviene collegarsi": lo stesso volo cercato su Google Voli da 17 paesi in un tocco; in cima il paese più conveniente per la VPN, il risparmio rispetto all'Italia e il link per ciascuno. La scelta dei paesi è facoltativa.
- Il paese più conveniente resta salvato con il volo monitorato e compare anche nella lista "I miei voli".
- Icona per Mac; la compilazione automatica su GitHub verifica e fotografa anche la versione per Mac.

## v0.3.0 — 2026-10-17

Prezzi da Google Voli e controlli fatti dall'app: niente più GitHub né token.

- Ricerca su Google Voli (tramite SerpApi, chiave gratuita con 250 ricerche al mese); senza chiave prezzi di esempio.
- Giudizio di Google sul prezzo (basso, nella media, alto) con la fascia tipica e l'andamento recente nel grafico.
- I voli monitorati restano sul telefono e l'app li ricontrolla da sola ogni 6, 12 o 24 ore, anche ad app chiusa.
- Notifiche generate dall'app: non servono più il token GitHub, le chiavi Apple Push né l'account sviluppatore a pagamento.
- Le città vengono cercate su tutti i loro aeroporti (Milano → Malpensa, Orio al Serio, Linate).
- Impostazioni: chiave di Google Voli con le ricerche rimaste, frequenza dei controlli, avvisi anche quando il prezzo sale.
- Ricerca a date precise (Google Voli non cerca su un mese intero).
- Il motore su GitHub resta disponibile come opzione facoltativa per esperti.

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

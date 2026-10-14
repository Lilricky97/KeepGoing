---
tags: [keepgoing, progetto, readme]
aliases: [KeepGoing versioni, KeepGoing README]
versione_attuale: v0.1.1
aggiornato: 2026-10-14
---

# KeepGoing — Versioni

> [!info] Come usare questa nota
> Ogni sezione contiene le novità e il README completo di una versione di KeepGoing,
> l'app che monitora i prezzi dei voli e manda notifiche sull'iPhone. La più recente è in alto.
> Generata da `tools/obsidian_note.py`: non modificarla a mano nel repository.

| Versione | Data | In breve |
|---|---|---|
| [[#v0.1.1]] | 2026-10-14 | L'app si prova nel simulatore di Xcode, senza iPhone né account sviluppatore. |
| [[#v0.1.0]] | 2026-10-14 | Prima versione: motore che controlla i prezzi ogni 3 ore e app iPhone che riceve le notifiche push. |

---

## v0.1.1

**Data:** 2026-10-14  
**In breve:** L'app si prova nel simulatore di Xcode, senza iPhone né account sviluppatore.

### Novità

- Voli di esempio nell'app finché il motore non ha fatto il primo controllo dei prezzi.
- Nel simulatore non serve firmare l'app; le notifiche si provano trascinando `ios/notifica-di-prova.apns` sulla finestra.
- L'app viene compilata e avviata nel simulatore su un Mac di GitHub a ogni modifica, con screenshot.

### README

#### KeepGoing ✈️

**Ti avvisa sull'iPhone quando il prezzo di un volo cambia, soprattutto quando scende.**

Scegli la tratta e il periodo (es. Milano → Barcellona a dicembre). KeepGoing cerca il volo più economico ogni 3 ore e, se il prezzo scende, sale o va sotto la cifra che hai scelto, ti manda una notifica dall'app **KeepGoing** direttamente sullo schermo, anche quando l'app è chiusa.

> Versione **0.1.1**: tutte le versioni sono in CHANGELOG.md.

---

##### Come funziona

```
 ┌──────────────────────────── GitHub (gratis, sempre acceso) ────────────────────────────┐
 │  ogni 3 ore il "motore" (Python):                                                       │
 │   1. chiede il volo più economico a Travelpayouts/Aviasales o Google Flights            │
 │   2. lo confronta con lo storico salvato in data/prices.json                            │
 │   3. se il prezzo è cambiato abbastanza → manda la notifica tramite Apple               │
 └──────────────────────────────────────────┬──────────────────────────────────────────────┘
                                            │ Apple Push Notification service
                                            ▼
                         📱 iPhone: notifica di KeepGoing a schermo
                            tocchi la notifica → si apre il volo nell'app
                            (grafico del prezzo, minimo storico, link all'offerta)
```

Perché serve un "motore" su GitHub? iOS non permette a un'app di restare sveglia in background per controllare i prezzi a orari regolari. Il controllo lo fa quindi GitHub (gratis), e l'app riceve le notifiche push come qualsiasi altra app.

###### Quando arriva una notifica

| Notifica | Quando |
|---|---|
| 👀 **Primo prezzo** | al primo controllo di un nuovo volo |
| 🔻 **Ribasso** | il prezzo scende di almeno **5 € e del 3%** rispetto all'ultima notifica |
| 🔺 **Rialzo** | il prezzo sale della stessa soglia (si può disattivare: `notify_on = "drops"`) |
| 🎯 **Obiettivo** | il prezzo va sotto il tuo `target_price` (una volta sola, si riattiva se risale) |
| 🏆 **Minimo storico** | aggiunto al messaggio quando è il prezzo più basso mai visto |

Il confronto è con il prezzo **dell'ultima notifica**, non dell'ultimo controllo: così anche un calo lento, pochi euro alla volta, prima o poi ti viene segnalato. Ribassi e obiettivi arrivano con priorità alta.

Esempio di notifica:

```
🔻 Milano → Barcellona: 84 € (-11 €)
Il prezzo è sceso da 95 € a 84 € (-12%).
🏆 Nuovo minimo storico!
✈️ MIL → BCN · andata 10/12/2026 09:30 · ritorno 17/12/2026 18:00 · diretto · VY6312
```

---

##### Cosa ti serve

| | Costo | A cosa serve |
|---|---|---|
| Account GitHub | gratis | fa girare il motore ogni 3 ore e salva lo storico |
| Account [Travelpayouts](https://www.travelpayouts.com) | gratis | fonte dei prezzi dei voli |
| Mac con Xcode | gratis (Mac App Store) | installare l'app sull'iPhone |
| [Apple Developer Program](https://developer.apple.com/programs/) | 99 €/anno | obbligatorio per le notifiche push sull'iPhone vero (e per non dover reinstallare l'app ogni 7 giorni); non serve per il simulatore |
| iPhone con iOS 17 o successivo | | |

---

##### Prova subito nel simulatore

Per vedere l'app non servono né l'iPhone né l'account sviluppatore, basta un Mac con Xcode:

1. Scarica il progetto (**Code** → **Download ZIP**) e apri `ios/KeepGoing.xcodeproj` con Xcode.
2. In alto, accanto a **KeepGoing**, scegli un simulatore (es. **iPhone 16**) e premi ▶︎ (oppure ⌘R).
3. L'app si apre con due **voli di esempio**: toccane uno per vedere il grafico e i dettagli.
4. Per vedere come arriva una notifica: nell'app tocca **Attiva** → **Consenti**, poi trascina il file `ios/notifica-di-prova.apns` dal Finder sulla finestra del simulatore. Toccando la notifica si apre il volo.

I voli di esempio restano finché il motore su GitHub non ha fatto il primo controllo dei prezzi; da lì in poi l'app mostra i tuoi.

---

##### Installazione

###### 1. Scegli i voli da monitorare

Apri `config.toml` (puoi modificarlo anche dal sito di GitHub, con l'icona ✏️) e scrivi i voli:

```toml
[[watch]]
name = "Milano → Barcellona"
origin = "MIL"            # MIL = tutti gli aeroporti di Milano; oppure MXP, LIN, BGY…
destination = "BCN"
depart = "2026-12"        # tutto il mese (YYYY-MM) oppure un giorno preciso (YYYY-MM-DD)
return = "2026-12"        # togli la riga per solo andata
direct_only = false       # true = solo voli diretti
target_price = 80         # facoltativo: avviso speciale sotto questa cifra
```

Puoi aggiungere quanti blocchi `[[watch]]` vuoi. In `[settings]` scegli la fonte dei prezzi, la valuta e le soglie di notifica.

###### 2. Collega la fonte dei prezzi (Travelpayouts)

1. Registrati gratis su [travelpayouts.com](https://www.travelpayouts.com) e unisciti al programma **Aviasales**.
2. Nel tuo profilo, nella sezione dedicata all'API, copia il **token API**.
3. Su GitHub apri il repository → **Settings** → **Secrets and variables** → **Actions** → **New repository secret**:
   - Name: `TRAVELPAYOUTS_TOKEN`
   - Secret: il token copiato

###### 3. Installa l'app sull'iPhone

1. Sul Mac scarica il progetto (**Code** → **Download ZIP**, oppure `git clone`).
2. Apri `ios/KeepGoing.xcodeproj` con Xcode.
3. Seleziona il progetto **KeepGoing** → target **KeepGoing** → scheda **Signing & Capabilities**:
   - **Team**: scegli il tuo account Apple Developer.
   - **Bundle Identifier**: è `com.lilricky97.keepgoing`. Se Xcode dice che non è disponibile, cambialo (es. `com.tuonome.keepgoing`) e usa lo stesso valore al passo 4.
4. Collega l'iPhone al Mac, sceglilo in alto come destinazione e premi ▶︎.
   La prima volta l'iPhone ti chiederà di attivare la **Modalità sviluppatore** (Impostazioni → Privacy e sicurezza).
5. Apri KeepGoing, tocca **Attiva** per le notifiche, poi ⚙️ → **Copia codice** (è il "codice di questo iPhone").

###### 4. Collega le notifiche push

1. Su [developer.apple.com/account](https://developer.apple.com/account) → **Certificates, IDs & Profiles** → **Keys** → **+**:
   nome `KeepGoing push`, spunta **Apple Push Notifications service (APNs)** → **Continue** → **Register** → **Download**.
   Scarichi un file `AuthKey_XXXXXXXXXX.p8`: **si può scaricare una volta sola**, conservalo. Annota il **Key ID**.
2. Il **Team ID** è in **Account** → **Membership details**.
3. Aggiungi questi secrets su GitHub (come al passo 2):

| Secret | Valore |
|---|---|
| `APNS_KEY` | tutto il contenuto del file `.p8` (aprilo con TextEdit, comprese le righe `BEGIN`/`END`) |
| `APNS_KEY_ID` | il Key ID (10 caratteri) |
| `APNS_TEAM_ID` | il Team ID (10 caratteri) |
| `APNS_BUNDLE_ID` | `com.lilricky97.keepgoing` (o quello che hai scelto in Xcode) |
| `APNS_DEVICE_TOKENS` | il codice copiato dall'app; più iPhone/iPad separati da virgola |
| `APNS_ENVIRONMENT` | `development` se l'app è installata da Xcode, `production` se da TestFlight/App Store |

###### 5. Prova

Su GitHub: scheda **Actions** → **Controllo prezzi voli** → **Run workflow**.
Dopo circa un minuto arriva sull'iPhone la prima notifica (👀) per ogni volo. Da lì in poi il controllo parte da solo ogni 3 ore.

Se qualcosa non va, apri l'esecuzione in **Actions**: il log spiega in italiano cosa manca (es. «token del dispositivo errato o APNS_ENVIRONMENT sbagliato»).

---

##### L'app

- **Lista dei voli**: prezzo attuale, variazione dall'ultimo controllo, minimo storico.
- **Dettaglio**: grafico dell'andamento con minimo e obiettivo, dettagli dell'offerta migliore (date, scali, volo, fonte) e il pulsante **Apri l'offerta**.
- **Notifiche**: arrivano anche ad app chiusa; toccandole si apre direttamente il volo.
- **Impostazioni** (⚙️): stato delle notifiche, codice dell'iPhone da copiare, repository da cui leggere i dati.

L'app legge `data/prices.json` da GitHub. Se il repository è **privato**, crea un token su GitHub (**Settings** → **Developer settings** → **Fine-grained tokens**, solo questo repository, permesso **Contents: Read-only**) e incollalo nelle impostazioni dell'app: resta salvato nel Portachiavi dell'iPhone.

---

##### Fonti dei prezzi

| `provider` | Pro | Contro | Chiave |
|---|---|---|---|
| `travelpayouts` *(predefinito)* | gratis, accetta un mese intero | prezzi trovati dagli utenti Aviasales nelle ultime 48 ore: non in tempo reale | `TRAVELPAYOUTS_TOKEN` |
| `serpapi` | Google Flights in tempo reale | servono date esatte; piano gratuito con un numero limitato di ricerche al mese (ogni controllo di ogni volo ne usa una) | `SERPAPI_KEY` ([serpapi.com](https://serpapi.com)) |
| `demo` | nessuna chiave, utile per provare | prezzi finti | — |

La fonte si sceglie in `[settings]` e si può cambiare per un singolo volo con `provider = "serpapi"` dentro il suo `[[watch]]`.

> Le API gratuite di Amadeus non esistono più: il portale self-service è stato chiuso a luglio 2026.

---

##### Provare sul computer (facoltativo)

Serve Python 3.11 o successivo.

```bash
pip install -r requirements.txt           # solo per le notifiche iPhone
cp .env.example .env                      # e inserisci le tue chiavi
python -m keepgoing check --dry-run       # mostra i prezzi senza notificare né salvare
python -m keepgoing check                 # un controllo vero
python -m keepgoing history               # riepilogo con mini-grafico ▁▃▅▂▁
python -m keepgoing test-notify           # notifica di prova su tutti i canali
python -m keepgoing watch --every 60      # controlla ogni 60 minuti finché non lo fermi
python -m unittest                        # test automatici
```

Per provare senza nessuna chiave metti `provider = "demo"` in `config.toml`.

###### Canali di notifica extra (facoltativi)

Oltre all'app, il motore può scrivere anche su Telegram (`TELEGRAM_BOT_TOKEN`, `TELEGRAM_CHAT_ID`) o su [ntfy](https://ntfy.sh) (`NTFY_TOPIC`): basta aggiungere i secrets. Utile come riserva mentre aspetti l'attivazione dell'account Apple Developer.

---

##### Limiti da sapere

- **Prezzi Travelpayouts**: sono indicativi (cache delle ricerche recenti); il prezzo finale si conferma sul sito dell'offerta.
- **Orari**: GitHub può ritardare i controlli programmati di qualche minuto, a volte di più.
- **Repository pubblico inattivo**: GitHub sospende i workflow programmati dopo 60 giorni senza attività. Se succede, riattivalo dalla scheda **Actions**.
- **Branch**: i controlli programmati girano sul branch predefinito del repository, ed è lì che viene salvato lo storico.
- **Aggiungere voli**: per ora si fa da `config.toml`, non ancora dall'app.

---

##### Struttura del progetto

```
config.toml                    ← i voli da monitorare
data/prices.json               ← storico prezzi (scritto dal motore, letto dall'app)
keepgoing/                     ← il motore Python
  providers/                   ←   fonti dei prezzi (travelpayouts, serpapi, demo)
  notifiers/                   ←   notifiche (apns = iPhone, telegram, ntfy, console)
  tracker.py                   ←   quando un cambio di prezzo merita una notifica
ios/KeepGoing.xcodeproj        ← l'app iPhone (SwiftUI)
ios/KeepGoing/                 ←   codice dell'app
ios/notifica-di-prova.apns     ←   notifica da trascinare sul simulatore
.github/workflows/             ← controllo ogni 3 ore, test, compilazione dell'app
tests/                         ← test del motore
docs/versions/                 ← il README di ogni versione
obsidian/                      ← nota Obsidian con tutti i README
tools/obsidian_note.py         ← rigenera la nota Obsidian
```

---

##### Versioni e nota Obsidian

Ogni versione ha la sua copia del README in `docs/versions/` e le novità in `CHANGELOG.md`.
Il file **`obsidian/KeepGoing - Versioni.md`** le raccoglie tutte in un'unica nota pronta da copiare nel tuo vault Obsidian (la più recente in alto). Si rigenera con:

```bash
python3 tools/obsidian_note.py
```


---

## v0.1.0

**Data:** 2026-10-14  
**In breve:** Prima versione: motore che controlla i prezzi ogni 3 ore e app iPhone che riceve le notifiche push.

### Novità

- Motore Python senza server: gira gratis su GitHub Actions ogni 3 ore e salva lo storico in `data/prices.json`.
- Voli da monitorare in `config.toml`: tratta, mese o giorno preciso, andata e ritorno o solo andata, solo diretti, prezzo obiettivo.
- Fonti dei prezzi: Travelpayouts/Aviasales (gratis), Google Flights tramite SerpApi, demo.
- Notifiche per primo prezzo, ribasso, rialzo (disattivabile), prezzo obiettivo raggiunto e minimo storico, con soglie anti-spam (5 € e 3%).
- Notifiche push all'app iPhone tramite Apple Push Notification service; Telegram e ntfy come canali extra facoltativi.
- App iPhone (SwiftUI, iOS 17+): lista dei voli, grafico del prezzo, dettagli e link all'offerta, apertura del volo toccando la notifica, codice del dispositivo da copiare.
- Nota Obsidian con i README di tutte le versioni (`obsidian/KeepGoing - Versioni.md`).

### README

#### KeepGoing ✈️

**Ti avvisa sull'iPhone quando il prezzo di un volo cambia, soprattutto quando scende.**

Scegli la tratta e il periodo (es. Milano → Barcellona a dicembre). KeepGoing cerca il volo più economico ogni 3 ore e, se il prezzo scende, sale o va sotto la cifra che hai scelto, ti manda una notifica dall'app **KeepGoing** direttamente sullo schermo, anche quando l'app è chiusa.

> Versione **0.1.0**: tutte le versioni sono in CHANGELOG.md.

---

##### Come funziona

```
 ┌──────────────────────────── GitHub (gratis, sempre acceso) ────────────────────────────┐
 │  ogni 3 ore il "motore" (Python):                                                       │
 │   1. chiede il volo più economico a Travelpayouts/Aviasales o Google Flights            │
 │   2. lo confronta con lo storico salvato in data/prices.json                            │
 │   3. se il prezzo è cambiato abbastanza → manda la notifica tramite Apple               │
 └──────────────────────────────────────────┬──────────────────────────────────────────────┘
                                            │ Apple Push Notification service
                                            ▼
                         📱 iPhone: notifica di KeepGoing a schermo
                            tocchi la notifica → si apre il volo nell'app
                            (grafico del prezzo, minimo storico, link all'offerta)
```

Perché serve un "motore" su GitHub? iOS non permette a un'app di restare sveglia in background per controllare i prezzi a orari regolari. Il controllo lo fa quindi GitHub (gratis), e l'app riceve le notifiche push come qualsiasi altra app.

###### Quando arriva una notifica

| Notifica | Quando |
|---|---|
| 👀 **Primo prezzo** | al primo controllo di un nuovo volo |
| 🔻 **Ribasso** | il prezzo scende di almeno **5 € e del 3%** rispetto all'ultima notifica |
| 🔺 **Rialzo** | il prezzo sale della stessa soglia (si può disattivare: `notify_on = "drops"`) |
| 🎯 **Obiettivo** | il prezzo va sotto il tuo `target_price` (una volta sola, si riattiva se risale) |
| 🏆 **Minimo storico** | aggiunto al messaggio quando è il prezzo più basso mai visto |

Il confronto è con il prezzo **dell'ultima notifica**, non dell'ultimo controllo: così anche un calo lento, pochi euro alla volta, prima o poi ti viene segnalato. Ribassi e obiettivi arrivano con priorità alta.

Esempio di notifica:

```
🔻 Milano → Barcellona: 84 € (-11 €)
Il prezzo è sceso da 95 € a 84 € (-12%).
🏆 Nuovo minimo storico!
✈️ MIL → BCN · andata 10/12/2026 09:30 · ritorno 17/12/2026 18:00 · diretto · VY6312
```

---

##### Cosa ti serve

| | Costo | A cosa serve |
|---|---|---|
| Account GitHub | gratis | fa girare il motore ogni 3 ore e salva lo storico |
| Account [Travelpayouts](https://www.travelpayouts.com) | gratis | fonte dei prezzi dei voli |
| Mac con Xcode | gratis (Mac App Store) | installare l'app sull'iPhone |
| [Apple Developer Program](https://developer.apple.com/programs/) | 99 €/anno | obbligatorio per le notifiche push (e per non dover reinstallare l'app ogni 7 giorni) |
| iPhone con iOS 17 o successivo | | |

---

##### Installazione

###### 1. Scegli i voli da monitorare

Apri `config.toml` (puoi modificarlo anche dal sito di GitHub, con l'icona ✏️) e scrivi i voli:

```toml
[[watch]]
name = "Milano → Barcellona"
origin = "MIL"            # MIL = tutti gli aeroporti di Milano; oppure MXP, LIN, BGY…
destination = "BCN"
depart = "2026-12"        # tutto il mese (YYYY-MM) oppure un giorno preciso (YYYY-MM-DD)
return = "2026-12"        # togli la riga per solo andata
direct_only = false       # true = solo voli diretti
target_price = 80         # facoltativo: avviso speciale sotto questa cifra
```

Puoi aggiungere quanti blocchi `[[watch]]` vuoi. In `[settings]` scegli la fonte dei prezzi, la valuta e le soglie di notifica.

###### 2. Collega la fonte dei prezzi (Travelpayouts)

1. Registrati gratis su [travelpayouts.com](https://www.travelpayouts.com) e unisciti al programma **Aviasales**.
2. Nel tuo profilo, nella sezione dedicata all'API, copia il **token API**.
3. Su GitHub apri il repository → **Settings** → **Secrets and variables** → **Actions** → **New repository secret**:
   - Name: `TRAVELPAYOUTS_TOKEN`
   - Secret: il token copiato

###### 3. Installa l'app sull'iPhone

1. Sul Mac scarica il progetto (**Code** → **Download ZIP**, oppure `git clone`).
2. Apri `ios/KeepGoing.xcodeproj` con Xcode.
3. Seleziona il progetto **KeepGoing** → target **KeepGoing** → scheda **Signing & Capabilities**:
   - **Team**: scegli il tuo account Apple Developer.
   - **Bundle Identifier**: è `com.lilricky97.keepgoing`. Se Xcode dice che non è disponibile, cambialo (es. `com.tuonome.keepgoing`) e usa lo stesso valore al passo 4.
4. Collega l'iPhone al Mac, sceglilo in alto come destinazione e premi ▶︎.
   La prima volta l'iPhone ti chiederà di attivare la **Modalità sviluppatore** (Impostazioni → Privacy e sicurezza).
5. Apri KeepGoing, tocca **Attiva** per le notifiche, poi ⚙️ → **Copia codice** (è il "codice di questo iPhone").

###### 4. Collega le notifiche push

1. Su [developer.apple.com/account](https://developer.apple.com/account) → **Certificates, IDs & Profiles** → **Keys** → **+**:
   nome `KeepGoing push`, spunta **Apple Push Notifications service (APNs)** → **Continue** → **Register** → **Download**.
   Scarichi un file `AuthKey_XXXXXXXXXX.p8`: **si può scaricare una volta sola**, conservalo. Annota il **Key ID**.
2. Il **Team ID** è in **Account** → **Membership details**.
3. Aggiungi questi secrets su GitHub (come al passo 2):

| Secret | Valore |
|---|---|
| `APNS_KEY` | tutto il contenuto del file `.p8` (aprilo con TextEdit, comprese le righe `BEGIN`/`END`) |
| `APNS_KEY_ID` | il Key ID (10 caratteri) |
| `APNS_TEAM_ID` | il Team ID (10 caratteri) |
| `APNS_BUNDLE_ID` | `com.lilricky97.keepgoing` (o quello che hai scelto in Xcode) |
| `APNS_DEVICE_TOKENS` | il codice copiato dall'app; più iPhone/iPad separati da virgola |
| `APNS_ENVIRONMENT` | `development` se l'app è installata da Xcode, `production` se da TestFlight/App Store |

###### 5. Prova

Su GitHub: scheda **Actions** → **Controllo prezzi voli** → **Run workflow**.
Dopo circa un minuto arriva sull'iPhone la prima notifica (👀) per ogni volo. Da lì in poi il controllo parte da solo ogni 3 ore.

Se qualcosa non va, apri l'esecuzione in **Actions**: il log spiega in italiano cosa manca (es. «token del dispositivo errato o APNS_ENVIRONMENT sbagliato»).

---

##### L'app

- **Lista dei voli**: prezzo attuale, variazione dall'ultimo controllo, minimo storico.
- **Dettaglio**: grafico dell'andamento con minimo e obiettivo, dettagli dell'offerta migliore (date, scali, volo, fonte) e il pulsante **Apri l'offerta**.
- **Notifiche**: arrivano anche ad app chiusa; toccandole si apre direttamente il volo.
- **Impostazioni** (⚙️): stato delle notifiche, codice dell'iPhone da copiare, repository da cui leggere i dati.

L'app legge `data/prices.json` da GitHub. Se il repository è **privato**, crea un token su GitHub (**Settings** → **Developer settings** → **Fine-grained tokens**, solo questo repository, permesso **Contents: Read-only**) e incollalo nelle impostazioni dell'app: resta salvato nel Portachiavi dell'iPhone.

---

##### Fonti dei prezzi

| `provider` | Pro | Contro | Chiave |
|---|---|---|---|
| `travelpayouts` *(predefinito)* | gratis, accetta un mese intero | prezzi trovati dagli utenti Aviasales nelle ultime 48 ore: non in tempo reale | `TRAVELPAYOUTS_TOKEN` |
| `serpapi` | Google Flights in tempo reale | servono date esatte; piano gratuito con un numero limitato di ricerche al mese (ogni controllo di ogni volo ne usa una) | `SERPAPI_KEY` ([serpapi.com](https://serpapi.com)) |
| `demo` | nessuna chiave, utile per provare | prezzi finti | — |

La fonte si sceglie in `[settings]` e si può cambiare per un singolo volo con `provider = "serpapi"` dentro il suo `[[watch]]`.

> Le API gratuite di Amadeus non esistono più: il portale self-service è stato chiuso a luglio 2026.

---

##### Provare sul computer (facoltativo)

Serve Python 3.11 o successivo.

```bash
pip install -r requirements.txt           # solo per le notifiche iPhone
cp .env.example .env                      # e inserisci le tue chiavi
python -m keepgoing check --dry-run       # mostra i prezzi senza notificare né salvare
python -m keepgoing check                 # un controllo vero
python -m keepgoing history               # riepilogo con mini-grafico ▁▃▅▂▁
python -m keepgoing test-notify           # notifica di prova su tutti i canali
python -m keepgoing watch --every 60      # controlla ogni 60 minuti finché non lo fermi
python -m unittest                        # test automatici
```

Per provare senza nessuna chiave metti `provider = "demo"` in `config.toml`.

###### Canali di notifica extra (facoltativi)

Oltre all'app, il motore può scrivere anche su Telegram (`TELEGRAM_BOT_TOKEN`, `TELEGRAM_CHAT_ID`) o su [ntfy](https://ntfy.sh) (`NTFY_TOPIC`): basta aggiungere i secrets. Utile come riserva mentre aspetti l'attivazione dell'account Apple Developer.

---

##### Limiti da sapere

- **Prezzi Travelpayouts**: sono indicativi (cache delle ricerche recenti); il prezzo finale si conferma sul sito dell'offerta.
- **Orari**: GitHub può ritardare i controlli programmati di qualche minuto, a volte di più.
- **Repository pubblico inattivo**: GitHub sospende i workflow programmati dopo 60 giorni senza attività. Se succede, riattivalo dalla scheda **Actions**.
- **Branch**: i controlli programmati girano sul branch predefinito del repository, ed è lì che viene salvato lo storico.
- **Aggiungere voli**: per ora si fa da `config.toml`, non ancora dall'app.

---

##### Struttura del progetto

```
config.toml                    ← i voli da monitorare
data/prices.json               ← storico prezzi (scritto dal motore, letto dall'app)
keepgoing/                     ← il motore Python
  providers/                   ←   fonti dei prezzi (travelpayouts, serpapi, demo)
  notifiers/                   ←   notifiche (apns = iPhone, telegram, ntfy, console)
  tracker.py                   ←   quando un cambio di prezzo merita una notifica
ios/KeepGoing.xcodeproj        ← l'app iPhone (SwiftUI)
ios/KeepGoing/                 ←   codice dell'app
.github/workflows/             ← controllo ogni 3 ore + test automatici
tests/                         ← test del motore
docs/versions/                 ← il README di ogni versione
obsidian/                      ← nota Obsidian con tutti i README
tools/obsidian_note.py         ← rigenera la nota Obsidian
```

---

##### Versioni e nota Obsidian

Ogni versione ha la sua copia del README in `docs/versions/` e le novità in `CHANGELOG.md`.
Il file **`obsidian/KeepGoing - Versioni.md`** le raccoglie tutte in un'unica nota pronta da copiare nel tuo vault Obsidian (la più recente in alto). Si rigenera con:

```bash
python3 tools/obsidian_note.py
```

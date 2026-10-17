---
tags: [keepgoing, progetto, readme]
aliases: [KeepGoing versioni, KeepGoing README]
versione_attuale: v0.3.0
aggiornato: 2026-10-17
---

# KeepGoing — Versioni

> [!info] Come usare questa nota
> Ogni sezione contiene le novità e il README completo di una versione di KeepGoing,
> l'app che monitora i prezzi dei voli e manda notifiche sull'iPhone. La più recente è in alto.
> Generata da `tools/obsidian_note.py`: non modificarla a mano nel repository.

| Versione | Data | In breve |
|---|---|---|
| [[#v0.3.0]] | 2026-10-17 | Prezzi da Google Voli e controlli fatti dall'app: niente più GitHub né token. |
| [[#v0.2.0]] | 2026-10-17 | I voli si cercano e si aggiungono direttamente dall'app. |
| [[#v0.1.1]] | 2026-10-14 | L'app si prova nel simulatore di Xcode, senza iPhone né account sviluppatore. |
| [[#v0.1.0]] | 2026-10-14 | Prima versione: motore che controlla i prezzi ogni 3 ore e app iPhone che riceve le notifiche push. |

---

## v0.3.0

**Data:** 2026-10-17  
**In breve:** Prezzi da Google Voli e controlli fatti dall'app: niente più GitHub né token.

### Novità

- Ricerca su Google Voli (tramite SerpApi, chiave gratuita con 250 ricerche al mese); senza chiave prezzi di esempio.
- Giudizio di Google sul prezzo (basso, nella media, alto) con la fascia tipica e l'andamento recente nel grafico.
- I voli monitorati restano sul telefono e l'app li ricontrolla da sola ogni 6, 12 o 24 ore, anche ad app chiusa.
- Notifiche generate dall'app: non servono più il token GitHub, le chiavi Apple Push né l'account sviluppatore a pagamento.
- Le città vengono cercate su tutti i loro aeroporti (Milano → Malpensa, Orio al Serio, Linate).
- Impostazioni: chiave di Google Voli con le ricerche rimaste, frequenza dei controlli, avvisi anche quando il prezzo sale.
- Ricerca a date precise (Google Voli non cerca su un mese intero).
- Il motore su GitHub resta disponibile come opzione facoltativa per esperti.

### README

#### KeepGoing ✈️

**Ti avvisa sull'iPhone quando il prezzo di un volo cambia, soprattutto quando scende.**

Nell'app cerchi un volo su **Google Voli** (es. Milano → Barcellona, 10–17 dicembre), vedi i prezzi e il giudizio di Google ("prezzo basso", "nella media", "alto") e tocchi **Monitora**. Da quel momento KeepGoing ricontrolla il prezzo da sola e, se scende, sale o va sotto la cifra che hai scelto, ti manda una notifica sullo schermo, anche ad app chiusa.

Niente server da configurare, niente account GitHub, niente chiavi Apple: serve solo una chiave gratuita per leggere Google Voli.

> Versione **0.3.0**: tutte le versioni sono in CHANGELOG.md.

---

##### Come funziona

```
 📱 KeepGoing
   Cerca ─────────► Google Voli (tramite SerpApi) ─► voli dal più economico
                                                     + giudizio di Google sul prezzo
   Monitora ──────► il volo resta salvato sul telefono
   Ogni 6/12/24 ore, anche ad app chiusa:
      ricontrolla Google Voli ─► il prezzo è cambiato abbastanza? ─► 🔔 notifica a schermo
                                                                     toccala → si apre il volo
```

###### Quando arriva una notifica

| Notifica | Quando |
|---|---|
| 🔻 **Ribasso** | il prezzo scende di almeno **5 € e del 3%** rispetto all'ultima notifica |
| 🔺 **Rialzo** | il prezzo sale della stessa soglia (si può disattivare nelle Impostazioni) |
| 🎯 **Obiettivo** | il prezzo va sotto il prezzo obiettivo che hai scelto (una volta sola, si riattiva se risale) |
| 🏆 **Minimo storico** | aggiunto al messaggio quando è il prezzo più basso mai visto |

Il confronto è con il prezzo **dell'ultima notifica**, non dell'ultimo controllo: così anche un calo lento, pochi euro alla volta, prima o poi ti viene segnalato.

Esempio:

```
🔻 Milano → Barcellona: 84 € (-11 €)
Il prezzo è sceso da 95 € a 84 € (-12%).
🏆 Nuovo minimo storico!
Google Voli: prezzo basso.
✈️ MXP → BCN · andata gio 10 dic, 09:30 · ritorno gio 17 dic · diretto · VY 6312
```

---

##### Cosa ti serve

| | Costo | Note |
|---|---|---|
| Mac con Xcode | gratis (Mac App Store) | per installare l'app |
| iPhone con iOS 17 o successivo | | oppure il simulatore di Xcode |
| Chiave di Google Voli ([SerpApi](https://serpapi.com)) | gratis, 250 ricerche al mese | senza chiave l'app funziona con prezzi di esempio |
| [Apple Developer Program](https://developer.apple.com/programs/) | 99 €/anno, **facoltativo** | senza, sull'iPhone l'app va reinstallata da Xcode ogni 7 giorni |

---

##### Prova subito nel simulatore

1. Scarica il progetto (**Code** → **Download ZIP**) e apri `ios/KeepGoing.xcodeproj` con Xcode.
2. In alto, accanto a **KeepGoing**, scegli un simulatore (es. **iPhone 17**) e premi ▶︎ (oppure ⌘R).
3. Scheda **Cerca**: tocca **Da**, scrivi "mil" e scegli Milano (tutti gli aeroporti) o un aeroporto; poi **A**, le date e **Cerca su Google Voli**.
4. Tocca **Monitora questo volo** → **Monitora** e consenti le notifiche.
5. Per vedere una notifica: aspetta una decina di minuti (senza chiave i prezzi di esempio cambiano ogni 10 minuti), poi in **I miei voli** trascina la lista verso il basso per ricontrollare. Se il prezzo è cambiato abbastanza arriva la notifica; toccandola si apre il volo.

---

##### Installare sull'iPhone

1. Apri `ios/KeepGoing.xcodeproj` con Xcode.
2. Seleziona il progetto **KeepGoing** → target **KeepGoing** → scheda **Signing & Capabilities** → **Team**: il tuo Apple ID (va bene anche quello gratuito, "Personal Team").
   Se Xcode dice che il **Bundle Identifier** `com.lilricky97.keepgoing` non è disponibile, cambialo (es. `com.tuonome.keepgoing`).
3. Collega l'iPhone al Mac, sceglilo in alto come destinazione e premi ▶︎.
   - La prima volta l'iPhone chiede di attivare la **Modalità sviluppatore** (Impostazioni → Privacy e sicurezza).
   - Con l'Apple ID gratuito: Impostazioni → Generali → **VPN e gestione dispositivi** → autorizza il tuo account sviluppatore.
4. Apri KeepGoing e consenti le notifiche.

###### La chiave di Google Voli

Google non offre un accesso gratuito diretto ai prezzi dei voli; li legge per te **SerpApi**, gratis fino a 250 ricerche al mese.

1. Nell'app: **Impostazioni** → **Crea la chiave gratis** (oppure vai su [serpapi.com](https://serpapi.com/users/sign_up)) e registrati, anche con l'account Google.
2. Nella dashboard di SerpApi copia la **Your Private API Key**.
3. Incollala in **Impostazioni** → **Google Voli**: sotto compare "Chiave valida" con le ricerche rimaste.

Ogni ricerca e ogni controllo di un volo usano una ricerca. Controllando ogni 12 ore, un volo ne usa circa 60 al mese: con il piano gratuito puoi monitorarne circa 4 (con 24 ore, circa 8). Le Impostazioni ti mostrano la stima per i tuoi voli.

---

##### L'app

- **Cerca**: partenza e arrivo con suggerimenti mentre scrivi (città con tutti i suoi aeroporti, o un singolo aeroporto), date, andata e ritorno o solo andata, solo voli diretti. I risultati di Google Voli sono ordinati dal più economico, con compagnia, orari, scali e durata, e c'è il giudizio di Google sul prezzo. **Apri la ricerca su Google Voli** apre la stessa ricerca sul sito di Google.
- **Monitora questo volo**: aggiunge il volo ai tuoi, con un prezzo obiettivo facoltativo. Il primo prezzo è quello che stai già guardando, quindi non consuma ricerche.
- **I miei voli**: prezzo attuale, variazione e giudizio di Google per ogni volo. Trascina in giù per ricontrollare subito; scorri un volo a sinistra per toglierlo.
- **Dettaglio**: grafico con l'andamento secondo Google Voli e i tuoi controlli, il volo più economico, **Controlla adesso**, **Smetti di monitorare**.
- **Impostazioni**: chiave di Google Voli con le ricerche rimaste, frequenza dei controlli (6, 12 o 24 ore), avvisi anche quando il prezzo sale, notifiche.

---

##### Limiti da sapere

- **Controlli ad app chiusa**: li fa partire iOS quando vuole, di solito qualche volta al giorno (più spesso se usi l'app). Se chiudi l'app scorrendola via dal multitasking, iOS non la sveglia finché non la riapri. Quando apri l'app, i voli da ricontrollare vengono controllati subito.
- **Date precise**: Google Voli cerca giorni precisi, non un mese intero.
- **Ricerche**: 250 al mese con il piano gratuito di SerpApi; quando finiscono l'app te lo dice e i controlli riprendono il mese dopo.
- **Prezzi**: sono quelli mostrati da Google Voli al momento del controllo; il prezzo finale si conferma sul sito della compagnia o dell'agenzia.
- **Apple ID gratuito**: l'app installata da Xcode dura 7 giorni, poi va reinstallata (i voli monitorati restano).

---

##### Motore su GitHub (facoltativo, per esperti)

Nella cartella `keepgoing/` c'è anche un "motore" Python che può controllare i prezzi da GitHub Actions ogni 3 ore, indipendentemente dall'app, e mandare notifiche su Telegram, [ntfy](https://ntfy.sh) o via Apple Push. **L'app non ne ha bisogno.** Serve solo se vuoi controlli a orari fissi anche con il telefono spento.

- I voli si scrivono in `config.toml` (blocchi `[[watch]]`, c'è un esempio nel file) o in `watches.json`.
- Fonti dei prezzi: `travelpayouts` (gratis, accetta anche un mese intero, `TRAVELPAYOUTS_TOKEN`), `serpapi` (Google Voli, `SERPAPI_KEY`), `demo`.
- Notifiche: `TELEGRAM_BOT_TOKEN` + `TELEGRAM_CHAT_ID`, `NTFY_TOPIC`, oppure le variabili `APNS_*` (vedi `.env.example`).
- Le chiavi vanno nei secrets del repository (**Settings** → **Secrets and variables** → **Actions**); il workflow è `.github/workflows/check-prices.yml`.

Sul computer (Python 3.11 o successivo):

```bash
pip install -r requirements.txt           # solo per le notifiche Apple Push
cp .env.example .env                      # e inserisci le tue chiavi
python -m keepgoing check --dry-run       # mostra i prezzi senza notificare né salvare
python -m keepgoing check                 # un controllo vero
python -m keepgoing history               # riepilogo con mini-grafico ▁▃▅▂▁
python -m keepgoing test-notify           # notifica di prova su tutti i canali
python -m unittest                        # test automatici
```

---

##### Struttura del progetto

```
ios/KeepGoing.xcodeproj        ← l'app iPhone (SwiftUI)
ios/KeepGoing/
  Models/                      ←   voli, ricerca, logica dei prezzi (PriceTracker.swift)
  Services/                    ←   Google Voli, suggerimenti, voli salvati, controlli in background
  Views/                       ←   schermate
ios/KeepGoing-Info.plist       ←   permesso per i controlli ad app chiusa
keepgoing/                     ← motore Python facoltativo
config.toml                    ←   impostazioni del motore
.github/workflows/             ← compilazione dell'app con screenshot, test, motore
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

## v0.2.0

**Data:** 2026-10-17  
**In breve:** I voli si cercano e si aggiungono direttamente dall'app.

### Novità

- Nuova scheda **Cerca**: partenza e arrivo con suggerimenti mentre scrivi, mese intero o giorno preciso, andata e ritorno o solo andata, solo voli diretti.
- Risultati dal più economico con logo della compagnia, orari, scali e durata; toccandone uno si apre l'offerta su Aviasales.
- **Monitora questo volo** (con prezzo obiettivo facoltativo) salva il volo su GitHub e fa partire subito il primo controllo.
- **I miei voli**: voli in attesa del primo controllo e possibilità di smettere di monitorarli.
- Impostazioni come scheda, con i token Travelpayouts (ricerca) e GitHub (salvataggio dei voli).
- Il motore legge i voli dell'app da `watches.json`; un volo sbagliato non blocca gli altri e senza voli non salva uno storico vuoto.
- `config.toml` ora contiene solo le impostazioni (i voli a mano restano possibili).

### README

#### KeepGoing ✈️

**Ti avvisa sull'iPhone quando il prezzo di un volo cambia, soprattutto quando scende.**

Nell'app cerchi un volo (es. Milano → Barcellona a dicembre), vedi i prezzi e tocchi **Monitora**. Da quel momento KeepGoing controlla il volo più economico ogni 3 ore e, se il prezzo scende, sale o va sotto la cifra che hai scelto, ti manda una notifica dall'app **KeepGoing** direttamente sullo schermo, anche quando l'app è chiusa.

> Versione **0.2.0**: tutte le versioni sono in CHANGELOG.md.

---

##### Come funziona

```
 📱 App KeepGoing: Cerca → scegli tratta e date → vedi i prezzi → Monitora
                                            │ salva il volo in watches.json su GitHub
                                            ▼
 ┌──────────────────────────── GitHub (gratis, sempre acceso) ────────────────────────────┐
 │  subito, e poi ogni 3 ore, il "motore" (Python):                                        │
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
| 🎯 **Obiettivo** | il prezzo va sotto il prezzo obiettivo che hai scelto (una volta sola, si riattiva se risale) |
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
| Account [Travelpayouts](https://www.travelpayouts.com) | gratis | fonte dei prezzi dei voli (ricerca nell'app e controlli del motore) |
| Mac con Xcode | gratis (Mac App Store) | installare l'app sull'iPhone |
| [Apple Developer Program](https://developer.apple.com/programs/) | 99 €/anno | obbligatorio per le notifiche push sull'iPhone vero (e per non dover reinstallare l'app ogni 7 giorni); non serve per il simulatore |
| iPhone con iOS 17 o successivo | | |

---

##### Prova subito nel simulatore

Per vedere l'app non servono né l'iPhone né l'account sviluppatore, basta un Mac con Xcode:

1. Scarica il progetto (**Code** → **Download ZIP**) e apri `ios/KeepGoing.xcodeproj` con Xcode.
2. In alto, accanto a **KeepGoing**, scegli un simulatore (es. **iPhone 16**) e premi ▶︎ (oppure ⌘R).
3. Nella scheda **Cerca** scegli partenza e arrivo (scrivi "mil", "barc"… e scegli dai suggerimenti), le date e tocca **Cerca voli**. Senza token Travelpayouts i prezzi sono di esempio.
4. Nella scheda **I miei voli** ci sono due **voli di esempio**: toccane uno per vedere il grafico e i dettagli.
5. Per vedere come arriva una notifica: nell'app tocca **Attiva** → **Consenti**, poi trascina il file `ios/notifica-di-prova.apns` dal Finder sulla finestra del simulatore. Toccando la notifica si apre il volo.

I voli di esempio spariscono appena monitori il tuo primo volo.

---

##### Installazione

###### 1. Collega la fonte dei prezzi (Travelpayouts)

1. Registrati gratis su [travelpayouts.com](https://www.travelpayouts.com) e unisciti al programma **Aviasales**.
2. Nel tuo profilo, nella sezione dedicata all'API, copia il **token API**.
3. Su GitHub apri il repository → **Settings** → **Secrets and variables** → **Actions** → **New repository secret**:
   - Name: `TRAVELPAYOUTS_TOKEN`
   - Secret: il token copiato
4. Tienilo a portata di mano: lo incollerai anche nell'app (passo 3), per la ricerca.

###### 2. Crea il token GitHub per l'app

L'app salva i voli che monitori nel file `watches.json` di questo repository, e per farlo le serve un token:

1. Su github.com: foto profilo → **Settings** → **Developer settings** → **Personal access tokens** → **Fine-grained tokens** → **Generate new token**.
2. **Repository access**: *Only select repositories* → **KeepGoing**.
3. **Permissions** → **Repository permissions** → **Contents**: *Read and write*.
4. **Generate token** e copialo.

###### 3. Installa l'app sull'iPhone

1. Sul Mac scarica il progetto (**Code** → **Download ZIP**, oppure `git clone`).
2. Apri `ios/KeepGoing.xcodeproj` con Xcode.
3. Seleziona il progetto **KeepGoing** → target **KeepGoing** → scheda **Signing & Capabilities**:
   - **Team**: scegli il tuo account Apple Developer.
   - **Bundle Identifier**: è `com.lilricky97.keepgoing`. Se Xcode dice che non è disponibile, cambialo (es. `com.tuonome.keepgoing`) e usa lo stesso valore al passo 4.
4. Collega l'iPhone al Mac, sceglilo in alto come destinazione e premi ▶︎.
   La prima volta l'iPhone ti chiederà di attivare la **Modalità sviluppatore** (Impostazioni → Privacy e sicurezza).
5. Apri KeepGoing e tocca **Attiva** per le notifiche.
6. Scheda **Impostazioni**: incolla il **token Travelpayouts** e il **token GitHub**, poi tocca **Copia codice** (è il "codice di questo iPhone", serve al passo 4).

###### 4. Collega le notifiche push

1. Su [developer.apple.com/account](https://developer.apple.com/account) → **Certificates, IDs & Profiles** → **Keys** → **+**:
   nome `KeepGoing push`, spunta **Apple Push Notifications service (APNs)** → **Continue** → **Register** → **Download**.
   Scarichi un file `AuthKey_XXXXXXXXXX.p8`: **si può scaricare una volta sola**, conservalo. Annota il **Key ID**.
2. Il **Team ID** è in **Account** → **Membership details**.
3. Aggiungi questi secrets su GitHub (come al passo 1):

| Secret | Valore |
|---|---|
| `APNS_KEY` | tutto il contenuto del file `.p8` (aprilo con TextEdit, comprese le righe `BEGIN`/`END`) |
| `APNS_KEY_ID` | il Key ID (10 caratteri) |
| `APNS_TEAM_ID` | il Team ID (10 caratteri) |
| `APNS_BUNDLE_ID` | `com.lilricky97.keepgoing` (o quello che hai scelto in Xcode) |
| `APNS_DEVICE_TOKENS` | il codice copiato dall'app; più iPhone/iPad separati da virgola |
| `APNS_ENVIRONMENT` | `development` se l'app è installata da Xcode, `production` se da TestFlight/App Store |

###### 5. Monitora il tuo primo volo

Nell'app: scheda **Cerca** → scegli tratta e date → **Cerca voli** → **Monitora questo volo** (puoi aggiungere un prezzo obiettivo) → **Monitora**.
Il volo compare in **I miei voli** "in attesa del primo controllo": il salvataggio fa partire subito il motore su GitHub e dopo un paio di minuti arriva la prima notifica (👀). Da lì in poi il controllo parte da solo ogni 3 ore.
Per smettere di monitorare un volo, scorrilo verso sinistra in **I miei voli**.

Se qualcosa non va, apri l'esecuzione in **Actions**: il log spiega in italiano cosa manca (es. «token del dispositivo errato o APNS_ENVIRONMENT sbagliato»).

---

##### L'app

- **Cerca**: partenza e arrivo con suggerimenti mentre scrivi (città o singolo aeroporto), mese intero o giorno preciso, andata e ritorno o solo andata, solo voli diretti. I risultati sono ordinati dal più economico, con compagnia, orari, scali e durata; toccandone uno si apre l'offerta su Aviasales. **Monitora questo volo** lo aggiunge ai tuoi voli, con un prezzo obiettivo facoltativo.
- **I miei voli**: prezzo attuale, variazione dall'ultimo controllo, minimo storico; scorri a sinistra per smettere di monitorare.
- **Dettaglio**: grafico dell'andamento con minimo e obiettivo, dettagli dell'offerta migliore (date, scali, volo, fonte) e il pulsante **Apri l'offerta**.
- **Notifiche**: arrivano anche ad app chiusa; toccandole si apre direttamente il volo.
- **Impostazioni**: notifiche, codice dell'iPhone da copiare, token Travelpayouts e GitHub, repository del motore.

L'app legge lo storico (`data/prices.json`) e i voli monitorati (`watches.json`) da GitHub; i token restano salvati nel Portachiavi dell'iPhone.
I voli si possono scrivere anche a mano in `config.toml` (blocchi `[[watch]]`, c'è un esempio nel file): quelli non si tolgono dall'app.

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
- **Ricerca nell'app**: usa gli stessi prezzi del motore (Travelpayouts, ultime 48 ore); per rotte poco cercate può non trovare risultati, ma puoi monitorarle lo stesso.

---

##### Struttura del progetto

```
config.toml                    ← impostazioni del motore (e voli scritti a mano)
watches.json                   ← voli aggiunti dall'app (lo crea l'app)
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

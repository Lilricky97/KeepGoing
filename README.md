# KeepGoing ✈️

**Ti avvisa sull'iPhone quando il prezzo di un volo cambia, soprattutto quando scende.**

Nell'app cerchi un volo su **Google Voli** (es. Milano → Barcellona, 10–17 dicembre), vedi i prezzi e il giudizio di Google ("prezzo basso", "nella media", "alto") e tocchi **Monitora**. Da quel momento KeepGoing ricontrolla il prezzo da sola e, se scende, sale o va sotto la cifra che hai scelto, ti manda una notifica sullo schermo, anche ad app chiusa.

Niente server da configurare, niente account GitHub, niente chiavi Apple: serve solo una chiave gratuita per leggere Google Voli.

> Versione **0.3.0**: tutte le versioni sono in [CHANGELOG.md](CHANGELOG.md).

---

## Come funziona

```
 📱 KeepGoing
   Cerca ─────────► Google Voli (tramite SerpApi) ─► voli dal più economico
                                                     + giudizio di Google sul prezzo
   Monitora ──────► il volo resta salvato sul telefono
   Ogni 6/12/24 ore, anche ad app chiusa:
      ricontrolla Google Voli ─► il prezzo è cambiato abbastanza? ─► 🔔 notifica a schermo
                                                                     toccala → si apre il volo
```

### Quando arriva una notifica

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

## Cosa ti serve

| | Costo | Note |
|---|---|---|
| Mac con Xcode | gratis (Mac App Store) | per installare l'app |
| iPhone con iOS 17 o successivo | | oppure il simulatore di Xcode |
| Chiave di Google Voli ([SerpApi](https://serpapi.com)) | gratis, 250 ricerche al mese | senza chiave l'app funziona con prezzi di esempio |
| [Apple Developer Program](https://developer.apple.com/programs/) | 99 €/anno, **facoltativo** | senza, sull'iPhone l'app va reinstallata da Xcode ogni 7 giorni |

---

## Prova subito nel simulatore

1. Scarica il progetto (**Code** → **Download ZIP**) e apri `ios/KeepGoing.xcodeproj` con Xcode.
2. In alto, accanto a **KeepGoing**, scegli un simulatore (es. **iPhone 17**) e premi ▶︎ (oppure ⌘R).
3. Scheda **Cerca**: tocca **Da**, scrivi "mil" e scegli Milano (tutti gli aeroporti) o un aeroporto; poi **A**, le date e **Cerca su Google Voli**.
4. Tocca **Monitora questo volo** → **Monitora** e consenti le notifiche.
5. Per vedere una notifica: aspetta una decina di minuti (senza chiave i prezzi di esempio cambiano ogni 10 minuti), poi in **I miei voli** trascina la lista verso il basso per ricontrollare. Se il prezzo è cambiato abbastanza arriva la notifica; toccandola si apre il volo.

---

## Installare sull'iPhone

1. Apri `ios/KeepGoing.xcodeproj` con Xcode.
2. Seleziona il progetto **KeepGoing** → target **KeepGoing** → scheda **Signing & Capabilities** → **Team**: il tuo Apple ID (va bene anche quello gratuito, "Personal Team").
   Se Xcode dice che il **Bundle Identifier** `com.lilricky97.keepgoing` non è disponibile, cambialo (es. `com.tuonome.keepgoing`).
3. Collega l'iPhone al Mac, sceglilo in alto come destinazione e premi ▶︎.
   - La prima volta l'iPhone chiede di attivare la **Modalità sviluppatore** (Impostazioni → Privacy e sicurezza).
   - Con l'Apple ID gratuito: Impostazioni → Generali → **VPN e gestione dispositivi** → autorizza il tuo account sviluppatore.
4. Apri KeepGoing e consenti le notifiche.

### La chiave di Google Voli

Google non offre un accesso gratuito diretto ai prezzi dei voli; li legge per te **SerpApi**, gratis fino a 250 ricerche al mese.

1. Nell'app: **Impostazioni** → **Crea la chiave gratis** (oppure vai su [serpapi.com](https://serpapi.com/users/sign_up)) e registrati, anche con l'account Google.
2. Nella dashboard di SerpApi copia la **Your Private API Key**.
3. Incollala in **Impostazioni** → **Google Voli**: sotto compare "Chiave valida" con le ricerche rimaste.

Ogni ricerca e ogni controllo di un volo usano una ricerca. Controllando ogni 12 ore, un volo ne usa circa 60 al mese: con il piano gratuito puoi monitorarne circa 4 (con 24 ore, circa 8). Le Impostazioni ti mostrano la stima per i tuoi voli.

---

## L'app

- **Cerca**: partenza e arrivo con suggerimenti mentre scrivi (città con tutti i suoi aeroporti, o un singolo aeroporto), date, andata e ritorno o solo andata, solo voli diretti. I risultati di Google Voli sono ordinati dal più economico, con compagnia, orari, scali e durata, e c'è il giudizio di Google sul prezzo. **Apri la ricerca su Google Voli** apre la stessa ricerca sul sito di Google.
- **Monitora questo volo**: aggiunge il volo ai tuoi, con un prezzo obiettivo facoltativo. Il primo prezzo è quello che stai già guardando, quindi non consuma ricerche.
- **I miei voli**: prezzo attuale, variazione e giudizio di Google per ogni volo. Trascina in giù per ricontrollare subito; scorri un volo a sinistra per toglierlo.
- **Dettaglio**: grafico con l'andamento secondo Google Voli e i tuoi controlli, il volo più economico, **Controlla adesso**, **Smetti di monitorare**.
- **Impostazioni**: chiave di Google Voli con le ricerche rimaste, frequenza dei controlli (6, 12 o 24 ore), avvisi anche quando il prezzo sale, notifiche.

---

## Limiti da sapere

- **Controlli ad app chiusa**: li fa partire iOS quando vuole, di solito qualche volta al giorno (più spesso se usi l'app). Se chiudi l'app scorrendola via dal multitasking, iOS non la sveglia finché non la riapri. Quando apri l'app, i voli da ricontrollare vengono controllati subito.
- **Date precise**: Google Voli cerca giorni precisi, non un mese intero.
- **Ricerche**: 250 al mese con il piano gratuito di SerpApi; quando finiscono l'app te lo dice e i controlli riprendono il mese dopo.
- **Prezzi**: sono quelli mostrati da Google Voli al momento del controllo; il prezzo finale si conferma sul sito della compagnia o dell'agenzia.
- **Apple ID gratuito**: l'app installata da Xcode dura 7 giorni, poi va reinstallata (i voli monitorati restano).

---

## Motore su GitHub (facoltativo, per esperti)

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

## Struttura del progetto

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

## Versioni e nota Obsidian

Ogni versione ha la sua copia del README in `docs/versions/` e le novità in `CHANGELOG.md`.
Il file **`obsidian/KeepGoing - Versioni.md`** le raccoglie tutte in un'unica nota pronta da copiare nel tuo vault Obsidian (la più recente in alto). Si rigenera con:

```bash
python3 tools/obsidian_note.py
```

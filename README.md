# KeepGoing ✈️

**Ti avvisa sull'iPhone e sul Mac quando il prezzo di un volo cambia, soprattutto quando scende.**

Nell'app cerchi un volo su **Google Voli** (es. Milano → Barcellona, 10–17 dicembre), vedi i prezzi e il giudizio di Google ("prezzo basso", "nella media", "alto") e tocchi **Monitora**. Da quel momento KeepGoing ricontrolla il prezzo da sola e, se scende, sale o va sotto la cifra che hai scelto, ti manda una notifica sullo schermo, anche ad app chiusa.

In più ti mostra **quando** conviene (fascia oraria di partenza, giorno e ora in cui il prezzo scende) e **da dove**: cerca lo stesso volo da 17 paesi e ti dice in quale collegarti con la VPN per pagarlo meno.

Niente server da configurare, niente account GitHub, niente chiavi Apple: serve solo una chiave gratuita per leggere Google Voli.

> Versione **0.4.0**: tutte le versioni sono in [CHANGELOG.md](CHANGELOG.md).

---

## Come funziona

```
 📱 KeepGoing
   Cerca ─────────► Google Voli (tramite SerpApi) ─► voli dal più economico
                                                     + giudizio di Google sul prezzo
                                                     + grafico degli ultimi giorni e orari più economici
   Dove conviene ──► lo stesso volo cercato da 17 paesi 🇬🇧 🇺🇸 🇹🇷 🇮🇳 … ─► "Collegati da 🇹🇷 Turchia: 71 €" 
   Monitora ──────► il volo resta salvato sul telefono
   Ogni 6/12/24 ore (iPhone: anche ad app chiusa · Mac: finché l'app è aperta):
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
| Mac con macOS 14 o successivo | | per usare KeepGoing anche sul Mac (stessa app) |
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

## Usare l'app sul Mac

È la stessa app, compilata per il Mac: sul Mac i controlli sono più regolari, perché l'app resta aperta.

1. Apri `ios/KeepGoing.xcodeproj` con Xcode.
2. In alto, accanto a **KeepGoing**, scegli **My Mac** come destinazione e premi ▶︎. Non servono account né firme.
3. Si apre la finestra di KeepGoing e in alto a destra, nella barra dei menu, compare l'icona ✈︎ con i prezzi dei voli monitorati.

Se chiudi la finestra KeepGoing continua a lavorare dalla barra dei menu: ogni 15 minuti guarda se qualche volo va ricontrollato e ti manda la notifica. Per chiuderla del tutto: icona ✈︎ → **Esci da KeepGoing**. Per riaverla sempre, aggiungila in Impostazioni di Sistema → Generali → **Elementi login**.

Sul Mac la chiave di Google Voli è salvata nelle preferenze dell'app invece che nel Portachiavi, perché un'app compilata da Xcode senza account sviluppatore cambierebbe firma a ogni compilazione e il Portachiavi chiederebbe ogni volta la password.

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

Ogni ricerca, ogni controllo di un volo e ogni paese del confronto usano una ricerca (un confronto completo ne usa 17). Controllando ogni 12 ore, un volo ne usa circa 60 al mese: con il piano gratuito puoi monitorarne circa 4 (con 24 ore, circa 8). Le Impostazioni ti mostrano la stima per i tuoi voli.

---

## L'app

- **Cerca**: partenza e arrivo con suggerimenti mentre scrivi (città con tutti i suoi aeroporti, o un singolo aeroporto), date, andata e ritorno o solo andata, solo voli diretti. I risultati di Google Voli sono ordinati dal più economico, con compagnia, orari, scali e durata, e c'è il giudizio di Google sul prezzo. **Apri la ricerca su Google Voli** apre la stessa ricerca sul sito di Google.
- **Grafici subito**: già nei risultati c'è l'andamento del prezzo degli ultimi giorni secondo Google e il prezzo di ogni volo in base all'**ora di partenza**, con la fascia più economica ("I voli più economici partono di mattina").
- **Dove conviene collegarsi (VPN)**: tocca **Trova il paese più conveniente** e l'app cerca subito lo stesso volo su Google Voli da tutti i 17 paesi (Regno Unito, Stati Uniti, Germania, Turchia, India, Brasile…). In cima vedi il paese da cui collegarti, il prezzo e quanto risparmi rispetto all'Italia, con il link a Google Voli "come da lì"; sotto, il prezzo in ogni paese. Il risultato resta salvato con il volo monitorato e compare anche in **I miei voli**. Ogni paese usa una ricerca: se vuoi risparmiarne, in **Paesi da confrontare** puoi togliere quelli che non ti interessano.
- **Monitora questo volo**: aggiunge il volo ai tuoi, con un prezzo obiettivo facoltativo. Il primo prezzo è quello che stai già guardando, quindi non consuma ricerche.
- **I miei voli**: prezzo attuale, variazione e giudizio di Google per ogni volo. Trascina in giù per ricontrollare subito; scorri un volo a sinistra per toglierlo.
- **Dettaglio**: si aggiorna da solo quando lo apri (se l'ultimo controllo ha più di un'ora). Grafico con l'andamento secondo Google Voli e i tuoi controlli; **Quando conviene**: il giorno della settimana in cui il prezzo è stato più basso e, man mano che l'app fa controlli, l'ora del giorno in cui scende; il paese da cui conviene collegarsi, il volo più economico, **Controlla adesso**, **Smetti di monitorare**.
- **Impostazioni**: chiave di Google Voli con le ricerche rimaste, frequenza dei controlli (6, 12 o 24 ore), avvisi anche quando il prezzo sale, notifiche.

---

## Limiti da sapere

- **Controlli ad app chiusa**: li fa partire iOS quando vuole, di solito qualche volta al giorno (più spesso se usi l'app). Se chiudi l'app scorrendola via dal multitasking, iOS non la sveglia finché non la riapri. Quando apri l'app, i voli da ricontrollare vengono controllati subito.
- **Date precise**: Google Voli cerca giorni precisi, non un mese intero.
- **Ricerche**: 250 al mese con il piano gratuito di SerpApi; quando finiscono l'app te lo dice e i controlli riprendono il mese dopo.
- **Prezzi**: sono quelli mostrati da Google Voli al momento del controllo; il prezzo finale si conferma sul sito della compagnia o dell'agenzia.
- **Apple ID gratuito**: sull'iPhone l'app installata da Xcode dura 7 giorni, poi va reinstallata (i voli monitorati restano). Sul Mac non scade.
- **Confronto tra paesi e VPN**: Google converte i prezzi in euro; al pagamento la banca può applicare cambio e commissioni, alcune compagnie chiedono carta o indirizzo del paese e i termini di certi siti vietano la VPN. È un'indicazione: controlla sempre il prezzo finale.
- **"Quando conviene"**: il giorno si basa sullo storico di Google (circa due mesi); l'ora del giorno sui tuoi controlli, quindi diventa affidabile solo dopo un po' di controlli.
- **iPhone e Mac non si sincronizzano**: ognuno ha i suoi voli monitorati.

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
ios/KeepGoing.xcodeproj        ← l'app per iPhone e Mac (SwiftUI)
ios/KeepGoing/
  Models/                      ←   voli, ricerca, logica dei prezzi (PriceTracker), analisi (PriceAnalysis), paesi (Markets)
  Services/                    ←   Google Voli, suggerimenti, voli salvati, controlli in background
  Views/                       ←   schermate
ios/KeepGoing-Info.plist       ←   permesso per i controlli ad app chiusa
keepgoing/                     ← motore Python facoltativo
config.toml                    ←   impostazioni del motore
.github/workflows/             ← compilazione dell'app (iPhone e Mac) con screenshot, test, motore
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

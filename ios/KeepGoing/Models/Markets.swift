import Foundation

/// Un paese da cui cercare su Google Voli (parametro `gl`). Lo stesso volo può costare
/// meno cercandolo da un altro paese: è l'idea del "trucco della VPN".
struct Market: Codable, Identifiable, Hashable {
    var code: String  // codice paese di Google, es. "it"
    var name: String
    var flag: String
    var id: String { code }
}

enum Markets {
    static let home = Market(code: "it", name: "Italia", flag: "🇮🇹")

    static let all: [Market] = [
        home,
        Market(code: "uk", name: "Regno Unito", flag: "🇬🇧"),
        Market(code: "us", name: "Stati Uniti", flag: "🇺🇸"),
        Market(code: "de", name: "Germania", flag: "🇩🇪"),
        Market(code: "fr", name: "Francia", flag: "🇫🇷"),
        Market(code: "es", name: "Spagna", flag: "🇪🇸"),
        Market(code: "ch", name: "Svizzera", flag: "🇨🇭"),
        Market(code: "pl", name: "Polonia", flag: "🇵🇱"),
        Market(code: "ro", name: "Romania", flag: "🇷🇴"),
        Market(code: "al", name: "Albania", flag: "🇦🇱"),
        Market(code: "tr", name: "Turchia", flag: "🇹🇷"),
        Market(code: "eg", name: "Egitto", flag: "🇪🇬"),
        Market(code: "in", name: "India", flag: "🇮🇳"),
        Market(code: "th", name: "Thailandia", flag: "🇹🇭"),
        Market(code: "br", name: "Brasile", flag: "🇧🇷"),
        Market(code: "mx", name: "Messico", flag: "🇲🇽"),
        Market(code: "ar", name: "Argentina", flag: "🇦🇷"),
    ]

    /// Scelta iniziale: l'Italia come riferimento e i paesi dove di solito i voli costano meno.
    /// Sei ricerche invece di diciassette; gli altri paesi si possono aggiungere.
    static let recommended: Set<String> = ["it", "tr", "in", "br", "ar", "pl"]

    /// Paesi da confrontare: quelli scelti dall'utente, altrimenti i consigliati.
    static func selection(defaults: UserDefaults = .standard) -> Set<String> {
        guard let saved = defaults.stringArray(forKey: "compare.markets"), !saved.isEmpty else {
            return recommended
        }
        return Set(saved)
    }

    static func saveSelection(_ codes: Set<String>, defaults: UserDefaults = .standard) {
        defaults.set(codes.sorted(), forKey: "compare.markets")
    }
}

/// Il paese più conveniente trovato per un volo, da mostrare ovunque.
struct BestMarket: Codable, Hashable {
    var market: Market
    var price: Double
    var homePrice: Double?  // prezzo cercando dall'Italia
    var googleURL: URL?
    var comparedAt: Date
    var countries: Int  // quanti paesi sono stati confrontati

    /// Risparmio rispetto all'Italia (nil se l'Italia non era nel confronto).
    var saving: Double? { homePrice.map { $0 - price } }
    var isHome: Bool { market.code == Markets.home.code }
}

/// Il volo più economico trovato cercando da un paese.
struct MarketPrice: Identifiable {
    var market: Market
    var cheapest: FlightOffer?
    var googleURL: URL?
    var error: String?
    var id: String { market.code }

    var price: Double? { cheapest?.price }
}

enum MarketComparison {
    /// Ordina dal più economico; i paesi senza prezzo vanno in fondo.
    static func sorted(_ prices: [MarketPrice]) -> [MarketPrice] {
        prices.sorted { a, b in
            switch (a.price, b.price) {
            case let (x?, y?): return x != y ? x < y : a.market.name < b.market.name  // stesso prezzo: ordine fisso
            case (_?, nil): return true
            case (nil, _?): return false
            case (nil, nil): return a.market.name < b.market.name
            }
        }
    }

    /// Il paese più conveniente e quanto si risparmia rispetto all'Italia (se è stata cercata).
    static func best(_ prices: [MarketPrice]) -> (market: MarketPrice, saving: Double?)? {
        guard let best = sorted(prices).first, let bestPrice = best.price else { return nil }
        let home = prices.first { $0.market.code == Markets.home.code }?.price
        return (best, home.map { $0 - bestPrice })
    }

    /// Riassunto da salvare e mostrare (nil se nessun paese ha restituito un prezzo).
    static func summary(_ prices: [MarketPrice], at date: Date = .now) -> BestMarket? {
        guard let best = sorted(prices).first, let price = best.price else { return nil }
        return BestMarket(
            market: best.market,
            price: price,
            homePrice: prices.first { $0.market.code == Markets.home.code }?.price,
            googleURL: best.googleURL,
            comparedAt: date,
            countries: prices.filter { $0.price != nil }.count
        )
    }
}

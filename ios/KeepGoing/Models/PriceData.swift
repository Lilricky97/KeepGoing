import Foundation

/// Contenuto di data/prices.json, scritto dal motore Python (keepgoing/storage.py).
struct PriceData: Decodable {
    var version: Int
    var updatedAt: Date?
    var active: [String]?
    var watches: [String: WatchState]

    enum CodingKeys: String, CodingKey {
        case version, active, watches
        case updatedAt = "updated_at"
    }

    static func decode(_ data: Data) throws -> PriceData {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let text = try container.decode(String.self)
            guard let date = parseISODate(text) else {
                throw DecodingError.dataCorruptedError(in: container, debugDescription: "Data non valida: \(text)")
            }
            return date
        }
        return try decoder.decode(PriceData.self, from: data)
    }
}

struct WatchState: Decodable {
    var watch: WatchInfo?
    var baseline: Double?
    var lowest: Double?
    var lowestAt: Date?
    var last: LastOffer?
    var history: [PricePoint]

    enum CodingKeys: String, CodingKey {
        case watch, baseline, lowest, last, history
        case lowestAt = "lowest_at"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        watch = try c.decodeIfPresent(WatchInfo.self, forKey: .watch)
        baseline = try c.decodeIfPresent(Double.self, forKey: .baseline)
        lowest = try c.decodeIfPresent(Double.self, forKey: .lowest)
        lowestAt = try c.decodeIfPresent(Date.self, forKey: .lowestAt)
        last = try c.decodeIfPresent(LastOffer.self, forKey: .last)
        history = try c.decodeIfPresent([PricePoint].self, forKey: .history) ?? []
    }
}

struct WatchInfo: Decodable {
    var name: String
    var origin: String
    var destination: String
    var depart: String
    var returnDate: String?
    var directOnly: Bool?
    var targetPrice: Double?
    var source: String?  // "app" = aggiunto dall'app (watches.json), altrimenti config.toml

    enum CodingKeys: String, CodingKey {
        case name, origin, destination, depart, source
        case returnDate = "return"
        case directOnly = "direct_only"
        case targetPrice = "target_price"
    }
}

struct LastOffer: Decodable {
    var price: Double
    var currency: String
    var provider: String?
    var airline: String?
    var flightNumber: String?
    var departureAt: String?
    var returnAt: String?
    var transfers: Int?
    var link: String?
    var checkedAt: Date?

    enum CodingKeys: String, CodingKey {
        case price, currency, provider, airline, transfers, link
        case flightNumber = "flight_number"
        case departureAt = "departure_at"
        case returnAt = "return_at"
        case checkedAt = "checked_at"
    }
}

struct PricePoint: Decodable, Identifiable, Equatable {
    var at: Date
    var price: Double
    var id: Date { at }
}

/// Un volo monitorato, pronto da mostrare.
struct Flight: Identifiable {
    let id: String
    let info: WatchInfo?
    let state: WatchState?  // nil = aggiunto dall'app, il motore non l'ha ancora controllato
    let isActive: Bool

    var name: String { info?.name ?? id }
    var route: String { info.map { "\($0.origin) → \($0.destination)" } ?? "" }
    var isFromApp: Bool { info?.source == "app" }
    var isPending: Bool { state == nil }
    var history: [PricePoint] { state?.history ?? [] }
    var lowest: Double? { state?.lowest }
    var last: LastOffer? { state?.last }
    var currency: String { last?.currency ?? "EUR" }
    var currentPrice: Double? { last?.price ?? history.last?.price }

    /// Differenza rispetto al controllo precedente (negativa = è sceso).
    var lastChange: Double? {
        let points = history
        guard points.count >= 2 else { return nil }
        return points[points.count - 1].price - points[points.count - 2].price
    }

    /// Unisce lo storico del motore (prices.json) con i voli aggiunti dall'app (watches.json).
    /// `appWatches` nil = watches.json non ancora letto.
    static func combine(prices: PriceData?, appWatches: [AppWatch]?) -> [Flight] {
        let states = prices?.watches ?? [:]
        var appByID: [String: AppWatch] = [:]
        for watch in appWatches ?? [] where appByID[watch.id] == nil {
            appByID[watch.id] = watch
        }
        var result: [Flight] = []
        var seen = Set<String>()
        func add(_ id: String, isActive: Bool) {
            guard seen.insert(id).inserted else { return }
            let info = appByID[id]?.info ?? states[id]?.watch
            result.append(Flight(id: id, info: info, state: states[id], isActive: isActive))
        }

        for id in prices?.active ?? states.keys.sorted() {
            // Tolto dall'app: sparisce subito, anche se il motore non è ancora ripassato.
            if states[id]?.watch?.source == "app", appWatches != nil, appByID[id] == nil { continue }
            add(id, isActive: true)
        }
        for watch in appWatches ?? [] {
            add(watch.id, isActive: true)  // appena aggiunti, in attesa del primo controllo
        }
        for id in states.keys.sorted() where states[id]?.watch?.source != "app" {
            add(id, isActive: false)  // tolti da config.toml: resta lo storico
        }
        return result
    }
}

func parseISODate(_ text: String) -> Date? {
    let formatter = ISO8601DateFormatter()
    if let date = formatter.date(from: text) { return date }
    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    return formatter.date(from: text)
}

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

    enum CodingKeys: String, CodingKey {
        case name, origin, destination, depart
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
    let state: WatchState
    let isActive: Bool

    var info: WatchInfo? { state.watch }
    var name: String { info?.name ?? id }
    var route: String { info.map { "\($0.origin) → \($0.destination)" } ?? "" }
    var currency: String { state.last?.currency ?? "EUR" }
    var currentPrice: Double? { state.last?.price ?? state.history.last?.price }

    /// Differenza rispetto al controllo precedente (negativa = è sceso).
    var lastChange: Double? {
        let points = state.history
        guard points.count >= 2 else { return nil }
        return points[points.count - 1].price - points[points.count - 2].price
    }
}

extension PriceData {
    /// Voli in config.toml prima (nel loro ordine), poi quelli rimossi.
    var flights: [Flight] {
        let order = active ?? watches.keys.sorted()
        let activeSet = Set(order)
        let current = order.compactMap { id in watches[id].map { Flight(id: id, state: $0, isActive: true) } }
        let archived = watches.keys.filter { !activeSet.contains($0) }.sorted().compactMap { id in
            watches[id].map { Flight(id: id, state: $0, isActive: false) }
        }
        return current + archived
    }
}

func parseISODate(_ text: String) -> Date? {
    let formatter = ISO8601DateFormatter()
    if let date = formatter.date(from: text) { return date }
    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    return formatter.date(from: text)
}

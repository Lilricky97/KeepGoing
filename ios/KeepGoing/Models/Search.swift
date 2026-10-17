import Foundation

/// Una città o un aeroporto (dai suggerimenti di Travelpayouts).
struct Place: Codable, Identifiable, Hashable {
    var code: String
    var name: String
    var type: String  // "city" oppure "airport"
    var countryName: String?
    var cityName: String?

    var id: String { "\(type)-\(code)" }
    var isAirport: Bool { type == "airport" }

    /// "Milano, Italia" per un aeroporto, "Italia" per una città.
    var subtitle: String {
        [isAirport ? cityName : nil, countryName].compactMap { $0 }.joined(separator: ", ")
    }

    enum CodingKeys: String, CodingKey {
        case code, name, type
        case countryName = "country_name"
        case cityName = "city_name"
    }
}

extension Place {
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        code = try c.decode(String.self, forKey: .code)
        name = try c.decodeIfPresent(String.self, forKey: .name) ?? code
        type = try c.decodeIfPresent(String.self, forKey: .type) ?? "city"
        countryName = try c.decodeIfPresent(String.self, forKey: .countryName)
        cityName = try c.decodeIfPresent(String.self, forKey: .cityName)
    }
}

/// Cosa sta cercando l'utente.
struct SearchQuery: Hashable {
    var origin: Place
    var destination: Place
    var depart: String  // "YYYY-MM" oppure "YYYY-MM-DD"
    var returnDate: String?  // nil = solo andata
    var directOnly: Bool

    var title: String { "\(origin.name) → \(destination.name)" }
}

/// Un volo trovato dalla ricerca.
struct FlightOffer: Identifiable {
    let id = UUID()
    var price: Double
    var currency: String
    var airline: String?
    var flightNumber: String?
    var departureAt: String?
    var returnAt: String?
    var transfers: Int?
    var durationTo: Int?  // minuti del volo di andata
    var link: URL?
}

struct SearchResult {
    var offers: [FlightOffer]
    var isSample: Bool  // true = nessun token Travelpayouts: prezzi di esempio
}

enum SearchError: LocalizedError {
    case badToken
    case api(String)
    case http(Int)

    var errorDescription: String? {
        switch self {
        case .badToken: return "Il token Travelpayouts non è valido: controllalo nelle Impostazioni."
        case let .api(message): return "Travelpayouts: \(message)"
        case let .http(status): return "Il servizio dei prezzi ha risposto con un errore (\(status)). Riprova tra poco."
        }
    }
}

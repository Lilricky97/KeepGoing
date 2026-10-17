import Foundation

/// Una città o un aeroporto (dai suggerimenti mentre si scrive).
struct Place: Codable, Identifiable, Hashable {
    var code: String
    var name: String
    var type: String  // "city" oppure "airport"
    var countryName: String?
    var cityName: String?
    var cityCode: String?

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
        case cityCode = "city_code"
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
        cityCode = try c.decodeIfPresent(String.self, forKey: .cityCode)
    }
}

/// Cosa sta cercando l'utente.
struct SearchQuery: Hashable {
    var origin: Place
    var destination: Place
    var depart: String  // "YYYY-MM-DD"
    var returnDate: String?  // nil = solo andata
    var directOnly: Bool

    var title: String { "\(origin.name) → \(destination.name)" }
}

/// Un volo trovato su Google Voli.
struct FlightOffer: Codable, Identifiable, Hashable {
    var id = UUID()
    var price: Double
    var currency: String
    var airline: String?
    var airlineLogo: URL?
    var flightNumber: String?
    var departureAirport: String?
    var arrivalAirport: String?
    var departureAt: String?  // "2026-12-10 09:30", ora locale dell'aeroporto
    var arrivalAt: String?
    var stops: Int
    var durationMinutes: Int?
}

/// Il giudizio di Google sul prezzo di questa tratta.
struct PriceInsights: Codable, Hashable {
    var lowestPrice: Double?
    var level: String?  // "low", "typical" oppure "high"
    var typicalLow: Double?
    var typicalHigh: Double?
    var history: [PricePoint] = []

    var levelText: String? {
        switch level {
        case "low": return "Prezzo basso"
        case "typical": return "Prezzo nella media"
        case "high": return "Prezzo alto"
        default: return nil
        }
    }
}

struct PricePoint: Codable, Hashable, Identifiable {
    var at: Date
    var price: Double
    var id: Date { at }
}

struct SearchResult {
    var offers: [FlightOffer]  // dal più economico
    var insights: PriceInsights?
    var googleURL: URL?
    var isSample: Bool  // true = nessuna chiave: prezzi di esempio

    var cheapest: FlightOffer? { offers.first }
}

enum SearchError: LocalizedError {
    case badKey
    case noSearchesLeft
    case api(String)
    case http(Int)

    var errorDescription: String? {
        switch self {
        case .badKey: return "La chiave di Google Voli (SerpApi) non è valida: controllala nelle Impostazioni."
        case .noSearchesLeft: return "Hai finito le ricerche gratuite di questo mese: ripartono il mese prossimo."
        case let .api(message): return "Google Voli: \(message)"
        case let .http(status): return "Google Voli non risponde (errore \(status)). Riprova tra poco."
        }
    }
}

extension Optional where Wrapped == String {
    /// nil se la stringa è vuota o fatta solo di spazi.
    var nonEmpty: String? {
        guard let value = self?.trimmingCharacters(in: .whitespacesAndNewlines), !value.isEmpty else { return nil }
        return value
    }
}

import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// Ricerca voli in tempo reale dall'app, con la stessa fonte del motore
/// (keepgoing/providers/travelpayouts.py).
struct TravelpayoutsClient {
    static let tokenKey = "travelpayouts-token"
    private static let pricesURL = "https://api.travelpayouts.com/aviasales/v3/prices_for_dates"
    private static let placesURL = "https://autocomplete.travelpayouts.com/places2"
    fileprivate static let siteURL = "https://www.aviasales.com"

    var token: String?
    var session: URLSession = .shared

    static func current() -> TravelpayoutsClient {
        TravelpayoutsClient(token: Keychain.read(tokenKey))
    }

    /// Voli dal più economico. Senza token restituisce prezzi di esempio.
    func search(_ query: SearchQuery, currency: String = "EUR") async throws -> SearchResult {
        guard let token = token.nonEmpty else {
            return SearchResult(offers: DemoSearch.offers(for: query, currency: currency), isSample: true)
        }
        var offers = try await fetch(query, token: token, currency: currency, market: "it")
        if offers.isEmpty {
            // Alcuni mercati hanno pochi dati: riprova con quello predefinito.
            offers = try await fetch(query, token: token, currency: currency, market: nil)
        }
        return SearchResult(offers: offers.sorted { $0.price < $1.price }, isSample: false)
    }

    /// Suggerimenti di città e aeroporti mentre si scrive (servizio pubblico, niente token).
    static func places(matching term: String, session: URLSession = .shared) async throws -> [Place] {
        let term = term.trimmingCharacters(in: .whitespacesAndNewlines)
        guard term.count >= 2, var components = URLComponents(string: placesURL) else { return [] }
        components.queryItems = [
            URLQueryItem(name: "locale", value: "it"),
            URLQueryItem(name: "types[]", value: "city"),
            URLQueryItem(name: "types[]", value: "airport"),
            URLQueryItem(name: "term", value: term),
        ]
        guard let url = components.url else { return [] }
        let (data, _) = try await session.data(from: url)
        return try JSONDecoder().decode([Place].self, from: data)
    }

    private func fetch(_ query: SearchQuery, token: String, currency: String, market: String?) async throws -> [FlightOffer] {
        guard var components = URLComponents(string: Self.pricesURL) else { return [] }
        var items = [
            URLQueryItem(name: "origin", value: query.origin.code),
            URLQueryItem(name: "destination", value: query.destination.code),
            URLQueryItem(name: "departure_at", value: query.depart),
            URLQueryItem(name: "one_way", value: query.returnDate == nil ? "true" : "false"),
            URLQueryItem(name: "direct", value: query.directOnly ? "true" : "false"),
            URLQueryItem(name: "currency", value: currency.lowercased()),
            URLQueryItem(name: "sorting", value: "price"),
            URLQueryItem(name: "limit", value: "30"),
        ]
        if let returnDate = query.returnDate {
            items.append(URLQueryItem(name: "return_at", value: returnDate))
        }
        if let market {
            items.append(URLQueryItem(name: "market", value: market))
        }
        components.queryItems = items
        guard let url = components.url else { return [] }
        var request = URLRequest(url: url)
        request.setValue(token, forHTTPHeaderField: "X-Access-Token")
        let (data, response) = try await session.data(for: request)
        let status = (response as? HTTPURLResponse)?.statusCode ?? 0
        if status == 401 || status == 403 { throw SearchError.badToken }
        guard status == 200 else { throw SearchError.http(status) }

        let decoded = try JSONDecoder().decode(PricesResponse.self, from: data)
        if decoded.success == false {
            throw SearchError.api(decoded.error ?? "errore sconosciuto")
        }
        let responseCurrency = (decoded.currency ?? currency).uppercased()
        return (decoded.data ?? []).compactMap { $0.offer(currency: responseCurrency) }
    }
}

private struct PricesResponse: Decodable {
    var success: Bool?
    var data: [PriceItem]?
    var currency: String?
    var error: String?

    enum CodingKeys: String, CodingKey { case success, data, currency, error }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        success = try? c.decode(Bool.self, forKey: .success)
        data = try? c.decode([PriceItem].self, forKey: .data)
        currency = try? c.decode(String.self, forKey: .currency)
        error = try? c.decode(String.self, forKey: .error)
    }
}

private struct PriceItem: Decodable {
    var price: Double?
    var airline: String?
    var flightNumber: String?
    var departureAt: String?
    var returnAt: String?
    var transfers: Int?
    var durationTo: Int?
    var link: String?

    enum CodingKeys: String, CodingKey {
        case price, airline, transfers, link
        case flightNumber = "flight_number"
        case departureAt = "departure_at"
        case returnAt = "return_at"
        case durationTo = "duration_to"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        price = try? c.decode(Double.self, forKey: .price)
        airline = try? c.decode(String.self, forKey: .airline)
        // Il numero di volo a volte arriva come testo, a volte come numero.
        flightNumber = (try? c.decode(String.self, forKey: .flightNumber))
            ?? (try? c.decode(Int.self, forKey: .flightNumber)).map(String.init)
        departureAt = try? c.decode(String.self, forKey: .departureAt)
        returnAt = try? c.decode(String.self, forKey: .returnAt)
        transfers = try? c.decode(Int.self, forKey: .transfers)
        durationTo = try? c.decode(Int.self, forKey: .durationTo)
        link = try? c.decode(String.self, forKey: .link)
    }

    func offer(currency: String) -> FlightOffer? {
        guard let price else { return nil }
        let url = link.flatMap { URL(string: $0.hasPrefix("/") ? TravelpayoutsClient.siteURL + $0 : $0) }
        return FlightOffer(
            price: price,
            currency: currency,
            airline: airline,
            flightNumber: flightNumber.map { number in
                number.hasPrefix(airline ?? "") ? number : "\(airline ?? "")\(number)"
            },
            departureAt: departureAt,
            returnAt: returnAt,
            transfers: transfers,
            durationTo: durationTo,
            link: url
        )
    }
}

/// Prezzi finti ma credibili, per provare la ricerca senza token.
enum DemoSearch {
    private static let airlines = ["FR", "U2", "VY", "AZ", "W6", "IB", "LH", "AF", "KL", "V7"]

    static func offers(for query: SearchQuery, currency: String) -> [FlightOffer] {
        var rng = SeededGenerator(seed: stableHash(
            "\(query.origin.code)-\(query.destination.code)-\(query.depart)-\(query.returnDate ?? "")-\(query.directOnly)"
        ))
        let base = Double(45 + rng.next() % 140)
        let offers = (0..<12).map { _ -> FlightOffer in
            let departDay = day(in: query.depart, notBefore: nil, using: &rng)
            let returnDay = query.returnDate.map { day(in: $0, notBefore: departDay, using: &rng) }
            let airline = airlines[Int(rng.next() % UInt64(airlines.count))]
            let transfers = query.directOnly ? 0 : [0, 0, 0, 1, 1, 2][Int(rng.next() % 6)]
            let multiplier = 0.75 + Double(rng.next() % 90) / 100 + Double(transfers) * -0.08
            return FlightOffer(
                price: (base * multiplier * (query.returnDate == nil ? 1 : 1.8)).rounded(),
                currency: currency.uppercased(),
                airline: airline,
                flightNumber: "\(airline)\(100 + rng.next() % 8900)",
                departureAt: "\(departDay)T\(time(using: &rng)):00+01:00",
                returnAt: returnDay.map { "\($0)T\(time(using: &rng)):00+01:00" },
                transfers: transfers,
                durationTo: 90 + Int(rng.next() % 60) + transfers * 150,
                link: nil
            )
        }
        return offers.sorted { $0.price < $1.price }
    }

    private static func day(in value: String, notBefore: String?, using rng: inout SeededGenerator) -> String {
        guard value.count == 7 else { return value }
        // Andata entro il 25, ritorno almeno il giorno dopo: date valide in ogni mese.
        var first = 1
        if let notBefore, notBefore.hasPrefix(value), let day = Int(notBefore.suffix(2)) {
            first = day + 1
        }
        let last = notBefore == nil ? 25 : 28
        return "\(value)-" + String(format: "%02d", first + Int(rng.next() % UInt64(last - first + 1)))
    }

    private static func time(using rng: inout SeededGenerator) -> String {
        String(format: "%02d:%02d", 6 + Int(rng.next() % 16), [0, 15, 30, 45][Int(rng.next() % 4)])
    }
}

/// Generatore pseudo-casuale riproducibile (SplitMix64).
struct SeededGenerator: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        state = seed
    }

    mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }
}

/// Hash stabile tra un avvio e l'altro (FNV-1a), a differenza di hashValue.
func stableHash(_ text: String) -> UInt64 {
    text.utf8.reduce(0xCBF2_9CE4_8422_2325) { ($0 ^ UInt64($1)) &* 0x0000_0100_0000_01B3 }
}

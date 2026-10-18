import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// Prezzi di Google Voli tramite SerpApi (piano gratuito: 250 ricerche al mese).
/// Senza chiave restituisce prezzi di esempio, così l'app si può provare subito.
struct GoogleFlightsClient {
    static let keyAccount = "serpapi-key"
    private static let searchURL = "https://serpapi.com/search.json"
    private static let accountURL = "https://serpapi.com/account.json"

    var apiKey: String?
    var session: URLSession = .shared

    static func current() -> GoogleFlightsClient {
        GoogleFlightsClient(apiKey: Keychain.read(keyAccount))
    }

    var isDemo: Bool { apiKey.nonEmpty == nil }

    /// `country` è il paese da cui "cerchi" su Google Voli (lo stesso volo può costare diverso).
    func search(_ query: SearchQuery, country: String = Markets.home.code, now: Date = .now) async throws -> SearchResult {
        guard let key = apiKey.nonEmpty else {
            return DemoSearch.result(for: query, now: now, country: country)
        }
        let from = await PlaceSearch.searchCodes(for: query.origin)
        let to = await PlaceSearch.searchCodes(for: query.destination)
        guard var components = URLComponents(string: Self.searchURL) else { throw SearchError.http(0) }
        var items = [
            URLQueryItem(name: "engine", value: "google_flights"),
            URLQueryItem(name: "departure_id", value: from),
            URLQueryItem(name: "arrival_id", value: to),
            URLQueryItem(name: "outbound_date", value: query.depart),
            URLQueryItem(name: "type", value: query.returnDate == nil ? "2" : "1"),
            URLQueryItem(name: "currency", value: "EUR"),
            URLQueryItem(name: "hl", value: "it"),
            URLQueryItem(name: "gl", value: country),
            URLQueryItem(name: "api_key", value: key),
        ]
        if let returnDate = query.returnDate {
            items.append(URLQueryItem(name: "return_date", value: returnDate))
        }
        if query.directOnly {
            items.append(URLQueryItem(name: "stops", value: "1"))
        }
        components.queryItems = items
        guard let url = components.url else { throw SearchError.http(0) }

        let (data, response) = try await session.data(from: url)
        return try Self.parse(data, status: (response as? HTTPURLResponse)?.statusCode ?? 0, query: query, country: country)
    }

    /// Lo stesso volo cercato da più paesi, dal più economico. Ogni paese usa una ricerca.
    func compare(_ query: SearchQuery, markets: [Market], now: Date = .now) async -> [MarketPrice] {
        let prices = await withTaskGroup(of: MarketPrice.self) { group in
            for market in markets {
                group.addTask {
                    do {
                        let result = try await search(query, country: market.code, now: now)
                        return MarketPrice(market: market, cheapest: result.cheapest, googleURL: result.googleURL)
                    } catch {
                        return MarketPrice(market: market, error: error.localizedDescription)
                    }
                }
            }
            var all: [MarketPrice] = []
            for await price in group {
                all.append(price)
            }
            return all
        }
        return MarketComparison.sorted(prices)
    }

    /// Legge la risposta di SerpApi (separata da `search` per poterla testare).
    static func parse(_ data: Data, status: Int, query: SearchQuery, country: String = Markets.home.code) throws -> SearchResult {
        let payload = try? JSONDecoder().decode(SerpResponse.self, from: data)
        if let error = payload?.error {
            if error.contains("hasn't returned any results") {
                return SearchResult(offers: [], insights: nil, googleURL: googleFlightsURL(for: query, country: country), isSample: false)
            }
            if status == 401 || error.localizedCaseInsensitiveContains("api key") { throw SearchError.badKey }
            if error.localizedCaseInsensitiveContains("run out of searches") { throw SearchError.noSearchesLeft }
            throw SearchError.api(error)
        }
        guard status == 200, let payload else { throw SearchError.http(status) }

        let offers = ((payload.bestFlights ?? []) + (payload.otherFlights ?? []))
            .compactMap { $0.offer() }
            .sorted { $0.price < $1.price }
        return SearchResult(
            offers: offers,
            insights: payload.priceInsights?.insights,
            googleURL: payload.searchMetadata?.googleFlightsURL.flatMap { URL(string: $0) } ?? googleFlightsURL(for: query, country: country),
            isSample: false
        )
    }

    /// Ricerche rimaste questo mese (chiedere non consuma ricerche).
    func searchesLeft() async throws -> Int? {
        guard let key = apiKey.nonEmpty, var components = URLComponents(string: Self.accountURL) else { return nil }
        components.queryItems = [URLQueryItem(name: "api_key", value: key)]
        guard let url = components.url else { return nil }
        let (data, response) = try await session.data(from: url)
        let status = (response as? HTTPURLResponse)?.statusCode ?? 0
        if status == 401 { throw SearchError.badKey }
        guard status == 200 else { throw SearchError.http(status) }
        return try JSONDecoder().decode(SerpAccount.self, from: data).totalSearchesLeft
    }

    /// Link alla stessa ricerca sul sito di Google Voli.
    static func googleFlightsURL(for query: SearchQuery, country: String = Markets.home.code) -> URL? {
        var text = "Voli da \(query.origin.code) a \(query.destination.code) il \(query.depart)"
        if let back = query.returnDate {
            text += " ritorno il \(back)"
        } else {
            text += " solo andata"
        }
        var components = URLComponents(string: "https://www.google.com/travel/flights")
        components?.queryItems = [
            URLQueryItem(name: "q", value: text),
            URLQueryItem(name: "hl", value: "it"),
            URLQueryItem(name: "gl", value: country),
            URLQueryItem(name: "curr", value: "EUR"),
        ]
        return components?.url
    }
}

// MARK: - Risposta di SerpApi

private struct SerpResponse: Decodable {
    var error: String?
    var bestFlights: [SerpItinerary]?
    var otherFlights: [SerpItinerary]?
    var priceInsights: SerpInsights?
    var searchMetadata: SerpMetadata?

    enum CodingKeys: String, CodingKey {
        case error
        case bestFlights = "best_flights"
        case otherFlights = "other_flights"
        case priceInsights = "price_insights"
        case searchMetadata = "search_metadata"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        error = try? c.decode(String.self, forKey: .error)
        bestFlights = try? c.decode([SerpItinerary].self, forKey: .bestFlights)
        otherFlights = try? c.decode([SerpItinerary].self, forKey: .otherFlights)
        priceInsights = try? c.decode(SerpInsights.self, forKey: .priceInsights)
        searchMetadata = try? c.decode(SerpMetadata.self, forKey: .searchMetadata)
    }
}

private struct SerpMetadata: Decodable {
    var googleFlightsURL: String?
    enum CodingKeys: String, CodingKey { case googleFlightsURL = "google_flights_url" }
}

private struct SerpAirport: Decodable {
    var id: String?
    var time: String?
}

private struct SerpLeg: Decodable {
    var departureAirport: SerpAirport?
    var arrivalAirport: SerpAirport?
    var airline: String?
    var airlineLogo: String?
    var flightNumber: String?

    enum CodingKeys: String, CodingKey {
        case airline
        case departureAirport = "departure_airport"
        case arrivalAirport = "arrival_airport"
        case airlineLogo = "airline_logo"
        case flightNumber = "flight_number"
    }
}

private struct SerpItinerary: Decodable {
    var price: Double?
    var totalDuration: Int?
    var flights: [SerpLeg]
    var layovers: Int
    var airlineLogo: String?

    enum CodingKeys: String, CodingKey {
        case price, flights, layovers
        case totalDuration = "total_duration"
        case airlineLogo = "airline_logo"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        price = try? c.decode(Double.self, forKey: .price)
        totalDuration = try? c.decode(Int.self, forKey: .totalDuration)
        flights = (try? c.decode([SerpLeg].self, forKey: .flights)) ?? []
        if let list = try? c.nestedUnkeyedContainer(forKey: .layovers) {
            layovers = list.count ?? 0
        } else {
            layovers = max(0, flights.count - 1)
        }
        airlineLogo = try? c.decode(String.self, forKey: .airlineLogo)
    }

    func offer() -> FlightOffer? {
        guard let price else { return nil }
        let first = flights.first
        let airlines = flights.compactMap(\.airline).reduce(into: [String]()) { if !$0.contains($1) { $0.append($1) } }
        return FlightOffer(
            price: price,
            currency: "EUR",
            airline: airlines.isEmpty ? nil : airlines.joined(separator: " + "),
            airlineLogo: (airlineLogo ?? first?.airlineLogo).flatMap { URL(string: $0) },
            flightNumber: first?.flightNumber,
            departureAirport: first?.departureAirport?.id,
            arrivalAirport: flights.last?.arrivalAirport?.id,
            departureAt: first?.departureAirport?.time,
            arrivalAt: flights.last?.arrivalAirport?.time,
            stops: layovers,
            durationMinutes: totalDuration
        )
    }
}

private struct SerpInsights: Decodable {
    var lowestPrice: Double?
    var priceLevel: String?
    var typicalPriceRange: [Double]?
    var priceHistory: [[Double]]?

    enum CodingKeys: String, CodingKey {
        case lowestPrice = "lowest_price"
        case priceLevel = "price_level"
        case typicalPriceRange = "typical_price_range"
        case priceHistory = "price_history"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        lowestPrice = try? c.decode(Double.self, forKey: .lowestPrice)
        priceLevel = try? c.decode(String.self, forKey: .priceLevel)
        typicalPriceRange = try? c.decode([Double].self, forKey: .typicalPriceRange)
        priceHistory = try? c.decode([[Double]].self, forKey: .priceHistory)
    }

    var insights: PriceInsights {
        let range = typicalPriceRange ?? []
        return PriceInsights(
            lowestPrice: lowestPrice,
            level: priceLevel,
            typicalLow: range.count == 2 ? range[0] : nil,
            typicalHigh: range.count == 2 ? range[1] : nil,
            history: (priceHistory ?? []).compactMap { pair in
                pair.count == 2 ? PricePoint(at: Date(timeIntervalSince1970: pair[0]), price: pair[1]) : nil
            }
        )
    }
}

private struct SerpAccount: Decodable {
    var totalSearchesLeft: Int?
    enum CodingKeys: String, CodingKey { case totalSearchesLeft = "total_searches_left" }
}

// MARK: - Prezzi di esempio

/// Prezzi finti ma credibili, per provare l'app senza chiave.
/// Cambiano ogni 10 minuti, così anche il monitoraggio e le notifiche si possono provare.
enum DemoSearch {
    private static let airlines = ["FR", "U2", "VY", "AZ", "W6", "IB", "LH", "AF", "KL", "V7"]

    static func result(for query: SearchQuery, now: Date, country: String = Markets.home.code) -> SearchResult {
        let route = "\(query.origin.code)-\(query.destination.code)-\(query.depart)-\(query.returnDate ?? "")-\(query.directOnly)"
        var routeRNG = SeededGenerator(seed: stableHash(route))
        let tripFactor: Double = query.returnDate == nil ? 1 : 1.8
        // Ogni paese ha il suo "listino": tra -15% e +12% rispetto all'Italia.
        var countryRNG = SeededGenerator(seed: stableHash("\(route)-\(country)"))
        let countryFactor: Double = country == Markets.home.code ? 1 : 0.85 + Double(countryRNG.next() % 28) / 100
        let base: Double = Double(45 + routeRNG.next() % 140) * tripFactor * countryFactor
        var rng = SeededGenerator(seed: stableHash("\(route)-\(Int(now.timeIntervalSince1970) / 600)"))

        let offers = (0..<12).map { _ -> FlightOffer in
            let code = airlines[Int(rng.next() % UInt64(airlines.count))]
            let stops = query.directOnly ? 0 : [0, 0, 0, 1, 1, 2][Int(rng.next() % 6)]
            let duration = 95 + Int(rng.next() % 60) + stops * 140
            let hour = 6 + Int(rng.next() % 15)
            let minute = [0, 15, 30, 45][Int(rng.next() % 4)]
            let arrivalMinutes = hour * 60 + minute + duration
            let factor: Double = 0.75 + Double(rng.next() % 80) / 100 - Double(stops) * 0.06
            return FlightOffer(
                price: (base * factor).rounded(),
                currency: "EUR",
                airline: Airlines.name(for: code),
                airlineLogo: Airlines.logoURL(for: code),
                flightNumber: "\(code) \(100 + rng.next() % 8900)",
                departureAirport: query.origin.code,
                arrivalAirport: query.destination.code,
                departureAt: "\(query.depart) " + String(format: "%02d:%02d", hour, minute),
                arrivalAt: "\(query.depart) " + String(format: "%02d:%02d", (arrivalMinutes / 60) % 24, arrivalMinutes % 60),
                stops: stops,
                durationMinutes: duration
            )
        }.sorted { $0.price < $1.price }

        let cheapest = offers.first?.price ?? base
        var history: [PricePoint] = []
        for day in 0..<30 {
            let at: Date = now.addingTimeInterval(Double(day - 29) * 86_400)
            let factor: Double = 1.05 + Double(routeRNG.next() % 30) / 100
            history.append(PricePoint(at: at, price: (cheapest * factor).rounded()))
        }
        let typicalLow = (base * 0.95).rounded(), typicalHigh = (base * 1.35).rounded()
        return SearchResult(
            offers: offers,
            insights: PriceInsights(
                lowestPrice: cheapest,
                level: cheapest < typicalLow ? "low" : cheapest > typicalHigh ? "high" : "typical",
                typicalLow: typicalLow,
                typicalHigh: typicalHigh,
                history: history
            ),
            googleURL: GoogleFlightsClient.googleFlightsURL(for: query, country: country),
            isSample: true
        )
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

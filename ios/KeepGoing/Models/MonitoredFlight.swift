import Foundation

/// Un volo che l'app tiene d'occhio, con lo storico dei controlli. Salvato sul telefono.
struct MonitoredFlight: Codable, Identifiable, Hashable {
    var id: String
    var name: String
    var origin: Place
    var destination: Place
    var depart: String  // "YYYY-MM-DD"
    var returnDate: String?
    var directOnly: Bool
    var targetPrice: Double?
    var addedAt: Date

    // Stato dei controlli (stessa logica di keepgoing/tracker.py)
    var baseline: Double?  // prezzo dell'ultima notifica
    var lowest: Double?
    var targetNotified = false
    var best: FlightOffer?
    var insights: PriceInsights?
    var googleURL: URL?
    var history: [PricePoint] = []
    var lastCheck: Date?
    var lastError: String?

    init(query: SearchQuery, name: String, targetPrice: Double?, addedAt: Date = .now) {
        id = Self.makeID(query)
        self.name = name
        origin = query.origin
        destination = query.destination
        depart = query.depart
        returnDate = query.returnDate
        directOnly = query.directOnly
        self.targetPrice = targetPrice
        self.addedAt = addedAt
    }

    static func makeID(_ query: SearchQuery) -> String {
        [query.origin.code, query.destination.code, query.depart, query.returnDate, query.directOnly ? "diretto" : nil]
            .compactMap { $0 }
            .joined(separator: "-")
            .lowercased()
    }

    var query: SearchQuery {
        SearchQuery(origin: origin, destination: destination, depart: depart, returnDate: returnDate, directOnly: directOnly)
    }

    var route: String { "\(origin.code) → \(destination.code)" }
    var currency: String { best?.currency ?? "EUR" }
    var currentPrice: Double? { best?.price ?? history.last?.price }

    /// Differenza rispetto al controllo precedente (negativa = è sceso).
    var lastChange: Double? {
        guard history.count >= 2 else { return nil }
        return history[history.count - 1].price - history[history.count - 2].price
    }

    /// Il volo è già partito: non serve più controllarlo.
    func isExpired(today: Date = .now, calendar: Calendar = .current) -> Bool {
        Format.isoDay(today, calendar: calendar) > depart
    }
}

extension MonitoredFlight {
    /// Voli di esempio per le anteprime di Xcode e gli screenshot automatici.
    static let samples: [MonitoredFlight] = {
        let mil = Place(code: "MIL", name: "Milano", type: "city", countryName: "Italia")
        let bcn = Place(code: "BCN", name: "Barcellona", type: "city", countryName: "Spagna")
        let rom = Place(code: "ROM", name: "Roma", type: "city", countryName: "Italia")
        let lon = Place(code: "LON", name: "Londra", type: "city", countryName: "Regno Unito")
        let start = Date.now.addingTimeInterval(-3 * 86_400)  // tre giorni fa: controlli recenti, grafici realistici

        var first = MonitoredFlight(
            query: SearchQuery(origin: mil, destination: bcn, depart: "2026-12-10", returnDate: "2026-12-17", directOnly: false),
            name: "Milano → Barcellona", targetPrice: 80, addedAt: start
        )
        let prices: [Double] = [112, 109, 118, 97, 95, 84]
        for (index, price) in prices.enumerated() {
            let at = start.addingTimeInterval(Double(index) * 43_200)
            first.history.append(PricePoint(at: at, price: price))
        }
        first.baseline = 84
        first.lowest = 84
        first.best = FlightOffer(
            price: 84, currency: "EUR", airline: "Vueling", airlineLogo: Airlines.logoURL(for: "VY"), flightNumber: "VY 6312",
            departureAirport: "MXP", arrivalAirport: "BCN", departureAt: "2026-12-10 09:30", arrivalAt: "2026-12-10 11:15",
            stops: 0, durationMinutes: 105
        )
        var googleHistory: [PricePoint] = []
        for day in 0..<30 {
            let at: Date = start.addingTimeInterval(Double(day - 27) * 86_400)
            let wobble: Double = Double((day * 7) % 11)
            let price: Double = 120 - Double(day) + wobble
            googleHistory.append(PricePoint(at: at, price: price))
        }
        first.insights = PriceInsights(lowestPrice: 84, level: "low", typicalLow: 95, typicalHigh: 140, history: googleHistory)
        first.lastCheck = Date.now.addingTimeInterval(-1800)  // mezz'ora fa: niente controllo all'apertura

        var second = MonitoredFlight(
            query: SearchQuery(origin: rom, destination: lon, depart: "2027-02-14", returnDate: nil, directOnly: true),
            name: "Roma → Londra", targetPrice: nil, addedAt: start
        )
        second.history = [PricePoint(at: start, price: 58), PricePoint(at: start.addingTimeInterval(43_200), price: 64)]
        second.baseline = 58
        second.lowest = 58
        second.best = FlightOffer(
            price: 64, currency: "EUR", airline: "ITA Airways", airlineLogo: Airlines.logoURL(for: "AZ"), flightNumber: "AZ 202",
            departureAirport: "FCO", arrivalAirport: "LHR", departureAt: "2027-02-14 07:05", arrivalAt: "2027-02-14 09:00",
            stops: 0, durationMinutes: 175
        )
        second.insights = PriceInsights(lowestPrice: 64, level: "typical", typicalLow: 55, typicalHigh: 90)
        second.lastCheck = Date.now.addingTimeInterval(-1800)
        return [first, second]
    }()
}

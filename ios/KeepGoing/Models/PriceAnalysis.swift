import Foundation

/// Analisi per i grafici: a che ora partono i voli più economici, in che giorno
/// e a che ora il prezzo è stato più basso.
enum PriceAnalysis {
    // MARK: Fasce orarie di partenza (dai risultati di una ricerca)

    struct Slot: Identifiable, Hashable {
        var name: String  // "Mattina"
        var range: String  // "6–12"
        var cheapest: Double?
        var count: Int
        var id: String { name }
    }

    private static let slotDefinitions: [(name: String, range: String, hours: Range<Int>)] = [
        ("Notte", "0–6", 0..<6),
        ("Mattina", "6–12", 6..<12),
        ("Pomeriggio", "12–18", 12..<18),
        ("Sera", "18–24", 18..<24),
    ]

    /// Ora di partenza (0–23) da "2026-12-10 09:30".
    static func departureHour(_ offer: FlightOffer) -> Int? {
        guard let raw = offer.departureAt, raw.count >= 13 else { return nil }
        return Int(raw.dropFirst(11).prefix(2))
    }

    static func timeSlots(_ offers: [FlightOffer]) -> [Slot] {
        slotDefinitions.map { definition in
            let prices = offers
                .filter { departureHour($0).map { definition.hours.contains($0) } ?? false }
                .map(\.price)
            return Slot(name: definition.name, range: definition.range, cheapest: prices.min(), count: prices.count)
        }
    }

    /// La fascia con il volo più economico (se ci sono voli in almeno due fasce).
    static func cheapestSlot(_ offers: [FlightOffer]) -> Slot? {
        let filled = timeSlots(offers).filter { $0.cheapest != nil }
        guard filled.count >= 2 else { return nil }
        return filled.min { ($0.cheapest ?? 0) < ($1.cheapest ?? 0) }
    }

    // MARK: Giorni e ore in cui il prezzo è più basso (da uno storico)

    struct Bucket: Identifiable, Hashable {
        var label: String  // "mar" oppure "8–12"
        var order: Int
        var average: Double
        var count: Int
        var id: Int { order }
    }

    /// Prezzo medio per giorno della settimana, da lunedì a domenica.
    static func weekdays(_ history: [PricePoint], calendar: Calendar = .current) -> [Bucket] {
        let names = ["dom", "lun", "mar", "mer", "gio", "ven", "sab"]  // weekday: 1 = domenica
        let groups = Dictionary(grouping: history) { calendar.component(.weekday, from: $0.at) }
        return groups.map { weekday, points in
            Bucket(
                label: names[(weekday - 1) % 7],
                order: (weekday + 5) % 7,  // lunedì = 0 … domenica = 6
                average: average(points),
                count: points.count
            )
        }
        .sorted { $0.order < $1.order }
    }

    /// Prezzo medio per fascia oraria di 4 ore (quando è stato controllato).
    static func hours(_ history: [PricePoint], calendar: Calendar = .current) -> [Bucket] {
        let groups = Dictionary(grouping: history) { calendar.component(.hour, from: $0.at) / 4 }
        return groups.map { block, points in
            Bucket(label: "\(block * 4)–\(block * 4 + 4)", order: block, average: average(points), count: points.count)
        }
        .sorted { $0.order < $1.order }
    }

    /// Il gruppo con il prezzo medio più basso e quanto si risparmia rispetto alla media,
    /// solo se ci sono abbastanza dati per dirlo.
    static func best(_ buckets: [Bucket], minCount: Int = 2) -> (bucket: Bucket, saving: Double)? {
        let valid = buckets.filter { $0.count >= minCount }
        guard valid.count >= 2, let best = valid.min(by: { $0.average < $1.average }) else { return nil }
        let overall = valid.map(\.average).reduce(0, +) / Double(valid.count)
        let saving = overall - best.average
        return saving >= 1 ? (best, saving) : nil
    }

    private static func average(_ points: [PricePoint]) -> Double {
        points.map(\.price).reduce(0, +) / Double(max(1, points.count))
    }
}

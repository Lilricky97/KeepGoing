import Foundation

/// Decide quando un cambio di prezzo merita una notifica: stessa logica di keepgoing/tracker.py.
///
/// Il confronto è con il prezzo dell'ultima notifica (baseline), non con l'ultimo controllo:
/// così anche un calo lento, pochi euro alla volta, prima o poi viene segnalato.
enum PriceTracker {
    struct Settings {
        var minChangeAbs = 5.0  // almeno 5 €…
        var minChangePct = 3.0  // …e almeno il 3%
        var notifyRises = true
        var historyLimit = 500
    }

    static func update(
        _ flight: inout MonitoredFlight,
        with result: SearchResult,
        at now: Date = .now,
        settings: Settings = Settings()
    ) -> PriceEvent? {
        flight.lastCheck = now
        flight.insights = result.insights ?? flight.insights
        flight.googleURL = result.googleURL ?? flight.googleURL
        guard let offer = result.cheapest else {
            flight.lastError = "Nessun volo trovato in questo controllo."
            return nil
        }
        flight.lastError = nil
        flight.best = offer
        let price = offer.price
        flight.history.append(PricePoint(at: now, price: price))
        if flight.history.count > settings.historyLimit {
            flight.history.removeFirst(flight.history.count - settings.historyLimit)
        }

        let lowestBefore = flight.lowest
        if lowestBefore == nil || price < lowestBefore! {
            flight.lowest = price
        }

        var hitTarget = false
        if let target = flight.targetPrice {
            if price <= target {
                hitTarget = !flight.targetNotified
                flight.targetNotified = true
            } else {
                flight.targetNotified = false  // si riarma se il prezzo risale
            }
        }

        guard let baseline = flight.baseline else {
            flight.baseline = price
            return PriceEvent(kind: .start, flight: flight, previous: nil, lowestBefore: nil, hitTarget: hitTarget)
        }

        let change = price - baseline
        let threshold = max(settings.minChangeAbs, baseline * settings.minChangePct / 100)
        var kind: PriceEvent.Kind?
        if abs(change) >= threshold {
            flight.baseline = price
            if change < 0 {
                kind = .drop
            } else if settings.notifyRises {
                kind = .rise
            }
        }
        if kind == nil && hitTarget {
            flight.baseline = price
            kind = .target
        }
        guard let kind else { return nil }
        return PriceEvent(kind: kind, flight: flight, previous: baseline, lowestBefore: lowestBefore, hitTarget: hitTarget)
    }
}

/// Un cambio di prezzo da notificare.
struct PriceEvent {
    enum Kind { case start, drop, rise, target }

    var kind: Kind
    var flight: MonitoredFlight
    var previous: Double?  // prezzo dell'ultima notifica
    var lowestBefore: Double?
    var hitTarget: Bool

    var price: Double { flight.best?.price ?? 0 }
    var change: Double? { previous.map { price - $0 } }
    var isRecord: Bool { lowestBefore.map { price < $0 } ?? false }

    // MARK: Testo della notifica (come keepgoing/messages.py)

    var title: String {
        let cur = flight.currency
        let priceText = Format.price(price, currency: cur)
        switch kind {
        case .start: return "👀 \(flight.name): \(priceText)"
        case .drop: return "🔻 \(flight.name): \(priceText) (\(Format.change(change ?? 0, currency: cur)))"
        case .rise: return "🔺 \(flight.name): \(priceText) (\(Format.change(change ?? 0, currency: cur)))"
        case .target: return "🎯 \(flight.name): \(priceText)"
        }
    }

    var body: String {
        let cur = flight.currency
        let priceText = Format.price(price, currency: cur)
        let target = flight.targetPrice.map { Format.price($0, currency: cur) } ?? ""
        var lines: [String] = []
        switch kind {
        case .start:
            lines.append("Monitoraggio avviato. Il prezzo più basso adesso è \(priceText).")
        case .drop, .rise:
            let before = self.previous ?? price
            let pct = before > 0 ? abs(price - before) / before * 100 : 0
            let verb = kind == .drop ? "sceso" : "salito"
            let sign = kind == .drop ? "-" : "+"
            lines.append("Il prezzo è \(verb) da \(Format.price(before, currency: cur)) a \(priceText) (\(sign)\(Int(pct.rounded()))%).")
        case .target:
            lines.append("Il prezzo è sceso sotto il tuo obiettivo di \(target).")
        }
        if isRecord {
            lines.append("🏆 Nuovo minimo storico!")
        }
        if hitTarget && kind != .target {
            lines.append("🎯 Sotto il tuo obiettivo di \(target)!")
        }
        if let level = flight.insights?.levelText {
            lines.append("Google Voli: \(level.lowercased()).")
        }
        lines.append("✈️ \(offerDescription)")
        if let lowestBefore, !isRecord {
            lines.append("Minimo visto finora: \(Format.price(lowestBefore, currency: cur))")
        }
        return lines.joined(separator: "\n")
    }

    private var offerDescription: String {
        let offer = flight.best
        var parts = ["\(offer?.departureAirport ?? flight.origin.code) → \(offer?.arrivalAirport ?? flight.destination.code)"]
        if let departure = Format.dayTime(offer?.departureAt ?? flight.depart) {
            parts.append("andata \(departure)")
        }
        if let back = Format.dayTime(flight.returnDate) {
            parts.append("ritorno \(back)")
        }
        if let offer {
            parts.append(Format.stops(offer.stops)?.lowercased() ?? "")
            if let number = offer.flightNumber ?? offer.airline {
                parts.append(number)
            }
        }
        return parts.filter { !$0.isEmpty }.joined(separator: " · ")
    }
}

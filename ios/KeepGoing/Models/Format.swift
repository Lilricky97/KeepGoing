import Foundation

enum Format {
    private static let italian = Locale(identifier: "it_IT")

    /// 89 → "89 €", 1234.5 → "1.234,50 €"
    static func price(_ value: Double, currency: String = "EUR") -> String {
        let decimals = value.rounded() == value ? 0 : 2
        return value.formatted(
            .currency(code: currency.uppercased())
                .precision(.fractionLength(decimals))
                .locale(italian)
        )
    }

    /// -15 → "-15 €", 20 → "+20 €"
    static func change(_ value: Double, currency: String = "EUR") -> String {
        (value > 0 ? "+" : "-") + price(abs(value), currency: currency)
    }

    /// "2026-12-10T09:30:00+01:00" → "10/12/2026 09:30" (ora locale dell'aeroporto, senza conversioni)
    static func tripDate(_ raw: String?) -> String? {
        guard let raw, raw.count >= 10 else { return nil }
        let c = Array(raw)
        var out = "\(String(c[8..<10]))/\(String(c[5..<7]))/\(String(c[0..<4]))"
        if c.count >= 16, c[10] == "T" || c[10] == " " {
            out += " " + String(c[11..<16])
        }
        return out
    }

    /// "2026-12" → "dicembre 2026", "2026-12-10" → "10/12/2026"
    static func period(_ raw: String) -> String {
        if raw.count == 10 { return tripDate(raw) ?? raw }
        let parts = raw.split(separator: "-").compactMap { Int($0) }
        guard parts.count == 2, (1...12).contains(parts[1]) else { return raw }
        let months = ["gennaio", "febbraio", "marzo", "aprile", "maggio", "giugno", "luglio",
                      "agosto", "settembre", "ottobre", "novembre", "dicembre"]
        return "\(months[parts[1] - 1]) \(parts[0])"
    }

    /// "2026-12-10T09:30:00+01:00" → "gio 10 dic, 09:30" (ora locale dell'aeroporto)
    static func dayTime(_ raw: String?) -> String? {
        guard let raw, raw.count >= 10 else { return nil }
        let c = Array(raw)
        guard let year = Int(String(c[0..<4])), let month = Int(String(c[5..<7])), let day = Int(String(c[8..<10])),
              let date = utcCalendar.date(from: DateComponents(year: year, month: month, day: day))
        else { return tripDate(raw) }
        let formatter = DateFormatter()
        formatter.locale = italian
        formatter.calendar = utcCalendar
        formatter.timeZone = utcCalendar.timeZone
        formatter.dateFormat = "EEE d MMM"
        var out = formatter.string(from: date)
        if c.count >= 16, c[10] == "T" || c[10] == " " {
            out += ", " + String(c[11..<16])
        }
        return out
    }

    /// 130 → "2 h 10 min"
    static func duration(_ minutes: Int?) -> String? {
        guard let minutes, minutes > 0 else { return nil }
        let hours = minutes / 60, rest = minutes % 60
        if hours == 0 { return "\(rest) min" }
        return rest == 0 ? "\(hours) h" : "\(hours) h \(rest) min"
    }

    /// Data scelta nel calendario → "2026-12-10" (giorno locale dell'utente).
    static func isoDay(_ date: Date, calendar: Calendar = .current) -> String {
        let parts = calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", parts.year ?? 0, parts.month ?? 0, parts.day ?? 0)
    }

    private static let utcCalendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC") ?? .current
        return calendar
    }()

    static func stops(_ transfers: Int?) -> String? {
        switch transfers {
        case nil: return nil
        case 0?: return "Diretto"
        case 1?: return "1 scalo"
        case let n?: return "\(n) scali"
        }
    }

    /// "3 ore fa"
    static func relative(_ date: Date) -> String {
        date.formatted(.relative(presentation: .named).locale(italian))
    }
}

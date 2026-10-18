import Charts
import SwiftUI

/// Andamento del prezzo: secondo Google Voli (grigio) e dai tuoi controlli (blu).
struct HistoryChart: View {
    var google: [PricePoint]
    var checks: [PricePoint] = []
    var target: Double?

    static func hasData(google: [PricePoint], checks: [PricePoint] = []) -> Bool {
        google.count >= 2 || checks.count >= 2
    }

    var body: some View {
        Chart {
            ForEach(google) { point in
                LineMark(x: .value("Data", point.at), y: .value("Prezzo", point.price), series: .value("Serie", "Google"))
                    .interpolationMethod(.stepEnd)
                    .foregroundStyle(by: .value("Fonte", "Google Voli"))
            }
            ForEach(checks) { point in
                LineMark(x: .value("Data", point.at), y: .value("Prezzo", point.price), series: .value("Serie", "Controlli"))
                    .interpolationMethod(.stepEnd)
                    .foregroundStyle(by: .value("Fonte", "I tuoi controlli"))
                PointMark(x: .value("Data", point.at), y: .value("Prezzo", point.price))
                    .foregroundStyle(by: .value("Fonte", "I tuoi controlli"))
            }
            if let target {
                RuleMark(y: .value("Obiettivo", target))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
                    .foregroundStyle(.orange)
                    .annotation(position: .top, alignment: .leading) {
                        Text("Obiettivo")
                            .font(.caption2)
                            .foregroundStyle(.orange)
                    }
            }
        }
        .chartForegroundStyleScale(["Google Voli": Color.gray.opacity(0.6), "I tuoi controlli": Color.accentColor])
        .chartYScale(domain: .automatic(includesZero: false))
        .chartLegend(checks.isEmpty ? .hidden : .visible)
        .chartLegend(position: .bottom)
        .frame(height: 220)
    }
}

/// Prezzo di ogni volo in base all'ora di partenza, con la fascia più economica.
struct DepartureTimesSection: View {
    let offers: [FlightOffer]

    var body: some View {
        let points: [(hour: Int, price: Double)] = offers.compactMap { offer in
            guard let hour = PriceAnalysis.departureHour(offer) else { return nil }
            return (hour: hour, price: offer.price)
        }
        if points.count >= 3 {
            Section {
                if let slot = PriceAnalysis.cheapestSlot(offers), let price = slot.cheapest {
                    Label {
                        Text("I voli più economici partono di **\(slot.name.lowercased())** (\(slot.range)): da \(Format.price(price)).")
                    } icon: {
                        Image(systemName: "clock.badge.checkmark")
                            .foregroundStyle(.green)
                    }
                    .font(.subheadline)
                }
                Chart {
                    ForEach(Array(points.enumerated()), id: \.offset) { _, point in
                        PointMark(x: .value("Ora di partenza", point.hour), y: .value("Prezzo", point.price))
                            .foregroundStyle(Color.accentColor)
                    }
                }
                .chartXScale(domain: 0...24)
                .chartXAxis {
                    AxisMarks(values: [0, 6, 12, 18, 24]) { value in
                        AxisGridLine()
                        AxisValueLabel {
                            if let hour = value.as(Int.self) { Text("\(hour):00") }
                        }
                    }
                }
                .chartYScale(domain: .automatic(includesZero: false))
                .frame(height: 160)
                .padding(.vertical, 6)
            } header: {
                Text("Orari di partenza")
            }
        }
    }
}

/// "Quando conviene": giorno della settimana (storico di Google) e ora del giorno (tuoi controlli).
struct WhenCheaperSection: View {
    let flight: MonitoredFlight

    var body: some View {
        let weekdays = PriceAnalysis.weekdays(flight.insights?.history ?? [])
        let hours = PriceAnalysis.hours(flight.history)
        let bestDay = PriceAnalysis.best(weekdays)
        let bestHour = PriceAnalysis.best(hours)
        Section {
            if let bestDay {
                Label {
                    Text("Negli ultimi giorni il prezzo è stato più basso di **\(Self.dayName(bestDay.bucket.label))**: in media \(Format.price(bestDay.saving.rounded())) in meno.")
                } icon: {
                    Image(systemName: "calendar.badge.checkmark")
                        .foregroundStyle(.green)
                }
                .font(.subheadline)
                BucketChart(buckets: weekdays, highlight: bestDay.bucket.order)
            }
            if let bestHour {
                Label {
                    Text("I tuoi controlli hanno trovato i prezzi più bassi tra le **\(bestHour.bucket.label)**: in media \(Format.price(bestHour.saving.rounded())) in meno.")
                } icon: {
                    Image(systemName: "clock.badge.checkmark")
                        .foregroundStyle(.green)
                }
                .font(.subheadline)
                BucketChart(buckets: hours, highlight: bestHour.bucket.order)
            } else {
                Text("Più controlli fa l'app, più capisce anche a che ora del giorno il prezzo tende a scendere.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        } header: {
            Text("Quando conviene")
        }
    }

    static func dayName(_ short: String) -> String {
        [
            "lun": "lunedì", "mar": "martedì", "mer": "mercoledì", "gio": "giovedì",
            "ven": "venerdì", "sab": "sabato", "dom": "domenica",
        ][short] ?? short
    }
}

/// Barre con il prezzo medio per gruppo; il più economico in verde.
struct BucketChart: View {
    let buckets: [PriceAnalysis.Bucket]
    let highlight: Int

    var body: some View {
        Chart {
            ForEach(buckets) { bucket in
                BarMark(x: .value("Quando", bucket.label), y: .value("Prezzo medio", bucket.average))
                    .foregroundStyle(bucket.order == highlight ? Color.green : Color.accentColor.opacity(0.35))
            }
        }
        .chartYScale(domain: .automatic(includesZero: false))
        .frame(height: 130)
        .padding(.vertical, 6)
    }
}

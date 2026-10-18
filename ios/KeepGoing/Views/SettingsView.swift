import SwiftUI

/// Scheda "Impostazioni": chiave di Google Voli, frequenza dei controlli e notifiche.
struct SettingsView: View {
    @EnvironmentObject private var notifications: NotificationManager
    @EnvironmentObject private var store: MonitorStore
    @Environment(\.openURL) private var openURL

    var body: some View {
        NavigationStack {
            Form {
                GoogleKeySection()
                Section {
                    Picker("Controlla ogni", selection: $store.checkIntervalHours) {
                        Text("6 ore").tag(6)
                        Text("12 ore").tag(12)
                        Text("24 ore").tag(24)
                    }
                    Toggle("Avvisami anche quando sale", isOn: $store.notifyRises)
                } header: {
                    Text("Controlli dei prezzi")
                } footer: {
                    if Platform.isMac {
                        Text("Con i voli che monitori ora servono circa \(store.estimatedSearchesPerMonth) ricerche al mese (il piano gratuito ne ha 250). Sul Mac i controlli partono da soli finché KeepGoing è aperta, anche solo con l'icona nella barra dei menu.")
                    } else {
                        Text("Con i voli che monitori ora servono circa \(store.estimatedSearchesPerMonth) ricerche al mese (il piano gratuito ne ha 250). I controlli ad app chiusa li fa partire iOS quando vuole, di solito qualche volta al giorno; non partono se chiudi l'app scorrendola via.")
                    }
                }
                notificationSection
                Section {
                    LabeledContent("Versione", value: Bundle.main.appVersion)
                }
            }
            .formStyle(.grouped)
            .navigationTitle("Impostazioni")
            .task {
                await notifications.refreshStatus()
            }
            .onChange(of: store.checkIntervalHours) { _, _ in
                BackgroundRefresh.schedule()
            }
        }
    }

    private var notificationSection: some View {
        Section("Notifiche") {
            switch notifications.authorization {
            case .authorized, .provisional, .ephemeral:
                Label("Notifiche attive", systemImage: "bell.fill")
                    .foregroundStyle(.green)
            case .denied:
                Label("Notifiche disattivate", systemImage: "bell.slash.fill")
                    .foregroundStyle(.red)
                Button(Platform.isMac ? "Apri Impostazioni di Sistema" : "Apri Impostazioni di iOS") {
                    if let url = Platform.notificationSettingsURL { openURL(url) }
                }
            default:
                Button("Attiva le notifiche") {
                    Task { await notifications.requestPermission() }
                }
            }
        }
    }
}

private extension Bundle {
    var appVersion: String {
        let version = infoDictionary?["CFBundleShortVersionString"] as? String ?? "?"
        let build = infoDictionary?["CFBundleVersion"] as? String ?? "?"
        return "\(version) (\(build))"
    }
}

#Preview {
    SettingsView()
        .environmentObject(NotificationManager.shared)
        .environmentObject(MonitorStore(preview: MonitoredFlight.samples))
}

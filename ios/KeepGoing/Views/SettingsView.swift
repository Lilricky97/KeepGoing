import SwiftUI
import UIKit

/// Scheda "Impostazioni": notifiche e collegamenti (Travelpayouts per la ricerca, GitHub per il motore).
struct SettingsView: View {
    @EnvironmentObject private var notifications: NotificationManager

    @AppStorage(GitHubSource.Keys.owner) private var owner = GitHubSource.defaultOwner
    @AppStorage(GitHubSource.Keys.repo) private var repo = GitHubSource.defaultRepo
    @AppStorage(GitHubSource.Keys.branch) private var branch = ""
    @State private var githubToken = Keychain.read(GitHubSource.Keys.token) ?? ""
    @State private var travelpayoutsToken = Keychain.read(TravelpayoutsClient.tokenKey) ?? ""
    @State private var copied = false

    var body: some View {
        NavigationStack {
            Form {
                notificationSection
                if let deviceToken = notifications.deviceToken {
                    deviceTokenSection(deviceToken)
                }
                Section {
                    SecureField("Token Travelpayouts", text: $travelpayoutsToken)
                    status(travelpayoutsToken.isEmpty ? "Senza token la ricerca mostra prezzi di esempio" : "Ricerca con prezzi veri", ok: !travelpayoutsToken.isEmpty)
                } header: {
                    Text("Ricerca voli")
                } footer: {
                    Text("È gratis: registrati su travelpayouts.com, unisciti al programma Aviasales e copia il token API dal tuo profilo. È lo stesso token che usa il motore su GitHub.")
                }
                Section {
                    SecureField("Token GitHub", text: $githubToken)
                    status(githubToken.isEmpty ? "Senza token non puoi aggiungere voli" : "Puoi aggiungere e togliere voli", ok: !githubToken.isEmpty)
                } header: {
                    Text("GitHub")
                } footer: {
                    Text("Serve per salvare i voli che monitori. Su github.com: Settings → Developer settings → Personal access tokens → Fine-grained tokens → Generate new token. Scegli solo il repository \(repo) e il permesso Contents: Read and write.")
                }
                Section {
                    TextField("Utente GitHub", text: $owner)
                    TextField("Repository", text: $repo)
                    TextField("Branch (vuoto = predefinito)", text: $branch)
                } header: {
                    Text("Repository del motore")
                }
                Section {
                    LabeledContent("Versione", value: Bundle.main.appVersion)
                }
            }
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
            .navigationTitle("Impostazioni")
            .task { await notifications.refreshStatus() }
            .onChange(of: githubToken) { _, value in
                Keychain.save(value.trimmingCharacters(in: .whitespacesAndNewlines), account: GitHubSource.Keys.token)
            }
            .onChange(of: travelpayoutsToken) { _, value in
                Keychain.save(value.trimmingCharacters(in: .whitespacesAndNewlines), account: TravelpayoutsClient.tokenKey)
            }
        }
    }

    private func status(_ text: String, ok: Bool) -> some View {
        Label(text, systemImage: ok ? "checkmark.circle.fill" : "info.circle")
            .font(.footnote)
            .foregroundStyle(ok ? Color.green : Color.secondary)
    }

    private var notificationSection: some View {
        Section {
            switch notifications.authorization {
            case .authorized, .provisional, .ephemeral:
                Label("Notifiche attive", systemImage: "bell.fill")
                    .foregroundStyle(.green)
            case .denied:
                Label("Notifiche disattivate", systemImage: "bell.slash.fill")
                    .foregroundStyle(.red)
                Button("Apri Impostazioni di iOS") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
            default:
                Button("Attiva le notifiche") {
                    Task { await notifications.requestPermission() }
                }
            }
            if let error = notifications.registrationError {
                Text(error)
                    .font(.footnote)
                    .foregroundStyle(.red)
            }
        } header: {
            Text("Notifiche")
        } footer: {
            if NotificationManager.isSimulator {
                Text("Sei nel simulatore: per provare una notifica trascina il file notifica-di-prova.apns sulla finestra del simulatore.")
            }
        }
    }

    private func deviceTokenSection(_ deviceToken: String) -> some View {
        Section {
            Text(deviceToken)
                .font(.footnote.monospaced())
                .textSelection(.enabled)
            Button {
                UIPasteboard.general.string = deviceToken
                copied = true
            } label: {
                Label(copied ? "Copiato!" : "Copia codice", systemImage: copied ? "checkmark" : "doc.on.doc")
            }
            ShareLink(item: deviceToken) {
                Label("Condividi codice", systemImage: "square.and.arrow.up")
            }
        } header: {
            Text("Codice di questo iPhone")
        } footer: {
            Text("Incollalo su GitHub in Settings → Secrets and variables → Actions, nel secret APNS_DEVICE_TOKENS. Serve al motore per sapere a quale iPhone mandare le notifiche.")
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
}

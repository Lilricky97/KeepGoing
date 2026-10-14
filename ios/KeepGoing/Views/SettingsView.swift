import SwiftUI
import UIKit

struct SettingsView: View {
    @EnvironmentObject private var notifications: NotificationManager
    @Environment(\.dismiss) private var dismiss

    @AppStorage(GitHubSource.Keys.owner) private var owner = GitHubSource.defaultOwner
    @AppStorage(GitHubSource.Keys.repo) private var repo = GitHubSource.defaultRepo
    @AppStorage(GitHubSource.Keys.branch) private var branch = ""
    @State private var token = Keychain.read(GitHubSource.Keys.token) ?? ""
    @State private var copied = false

    var body: some View {
        NavigationStack {
            Form {
                notificationSection
                if let deviceToken = notifications.deviceToken {
                    deviceTokenSection(deviceToken)
                }
                Section {
                    TextField("Utente GitHub", text: $owner)
                    TextField("Repository", text: $repo)
                    TextField("Branch (vuoto = predefinito)", text: $branch)
                    SecureField("Token (solo se il repo è privato)", text: $token)
                } header: {
                    Text("Da dove leggere i prezzi")
                } footer: {
                    Text("Il repository su GitHub dove gira il motore di KeepGoing. Se è privato serve un token \"fine-grained\" con permesso Contents: Read-only.")
                }
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                Section {
                    LabeledContent("Versione", value: Bundle.main.appVersion)
                }
            }
            .navigationTitle("Impostazioni")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Fine") { dismiss() }
                }
            }
            .task { await notifications.refreshStatus() }
            .onChange(of: token) { _, newValue in
                Keychain.save(newValue.trimmingCharacters(in: .whitespacesAndNewlines), account: GitHubSource.Keys.token)
            }
        }
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

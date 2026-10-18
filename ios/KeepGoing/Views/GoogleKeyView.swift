import SwiftUI

/// La chiave gratuita di SerpApi, che porta nell'app i prezzi veri di Google Voli:
/// campo, pulsante "Incolla" e verifica automatica (Impostazioni e configurazione guidata).
struct GoogleKeySection: View {
    var onVerified: () -> Void = {}

    @EnvironmentObject private var store: MonitorStore
    @State private var apiKey = Keychain.read(GoogleFlightsClient.keyAccount) ?? ""
    @State private var status = KeyStatus.idle
    @State private var attempt = 0

    private enum KeyStatus: Equatable {
        case idle, checking, valid(searchesLeft: Int?), invalid(String)
    }

    var body: some View {
        Section {
            SecureField("Chiave di Google Voli (SerpApi)", text: $apiKey)
                .noAutoCapitalization()
                .autocorrectionDisabled()
                .task(id: "\(attempt)-\(apiKey)") { await verify() }
            PasteButton(payloadType: String.self) { strings in
                guard let text = strings.first else { return }
                Task { @MainActor in apiKey = text.trimmingCharacters(in: .whitespacesAndNewlines) }
            }
            statusRow
            if let signUp = URL(string: "https://serpapi.com/users/sign_up") {
                Link(destination: signUp) {
                    Label("Crea la chiave gratis", systemImage: "key")
                }
            }
        } header: {
            Text("Google Voli")
        } footer: {
            Text("Google non dà accesso diretto ai prezzi: li legge per te SerpApi, gratis fino a 250 ricerche al mese. Tocca \"Crea la chiave gratis\", registrati (anche con l'account Google), copia la \"Your Private API Key\" e tocca \"Incolla\".")
        }
    }

    @ViewBuilder
    private var statusRow: some View {
        switch status {
        case .idle:
            Label("Senza chiave vedi prezzi di esempio", systemImage: "info.circle")
                .font(.footnote)
                .foregroundStyle(.secondary)
        case .checking:
            Label("Controllo la chiave…", systemImage: "hourglass")
                .font(.footnote)
                .foregroundStyle(.secondary)
        case let .valid(searchesLeft):
            Label(
                searchesLeft.map { "Chiave valida: \($0) ricerche rimaste questo mese" } ?? "Chiave valida",
                systemImage: "checkmark.circle.fill"
            )
            .font(.footnote)
            .foregroundStyle(.green)
        case let .invalid(message):
            Label(message, systemImage: "xmark.circle.fill")
                .font(.footnote)
                .foregroundStyle(.red)
            Button("Controlla di nuovo") { attempt += 1 }
        }
    }

    private func verify() async {
        let key = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        if key != Keychain.read(GoogleFlightsClient.keyAccount) ?? "" {
            Keychain.save(key, account: GoogleFlightsClient.keyAccount)
            store.keyChanged()
        }
        guard !key.isEmpty else {
            status = .idle
            return
        }
        status = .checking
        try? await Task.sleep(for: .milliseconds(700))  // aspetta che finisca di scrivere o incollare
        guard !Task.isCancelled else { return }
        do {
            let searchesLeft = try await GoogleFlightsClient(apiKey: key).searchesLeft()
            status = .valid(searchesLeft: searchesLeft)
            onVerified()
            // Fuori dalla vista: il ricontrollo continua anche se esci dalle Impostazioni.
            Task { await store.switchToRealPrices() }
        } catch {
            guard !Task.isCancelled, let message = MonitorStore.message(for: error) else { return }
            status = .invalid(message)
        }
    }
}

/// Configurazione guidata, aperta dall'avviso "Prezzi di esempio".
struct GoogleKeySheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var verified = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    step(1, "Tocca \"Crea la chiave gratis\" qui sotto e registrati su SerpApi (va bene anche l'account Google).")
                    step(2, "Nella pagina di SerpApi copia la \"Your Private API Key\" (la lunga serie di lettere e numeri).")
                    step(3, "Torna qui e tocca \"Incolla\": l'app controlla subito la chiave.")
                } header: {
                    Text("Prezzi veri in 3 passi")
                }
                GoogleKeySection { verified = true }
                if verified {
                    Section {
                        Button {
                            dismiss()
                        } label: {
                            Label("Mostra i prezzi veri", systemImage: "checkmark.circle.fill")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets())
                    }
                }
            }
            .formStyle(.grouped)
            .navigationTitle("Prezzi veri")
            .inlineNavigationTitle()
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Fine") { dismiss() }
                }
            }
        }
        .sheetSize()
    }

    private func step(_ number: Int, _ text: String) -> some View {
        Label(text, systemImage: "\(number).circle.fill")
    }
}

/// Avviso "Prezzi di esempio" con il pulsante per passare a quelli veri di Google Voli.
struct SampleNotice: View {
    /// Chiamata quando la configurazione si chiude con una chiave salvata (es. per rifare la ricerca).
    var onConnected: () -> Void = {}

    @State private var showKey = false

    var body: some View {
        Section {
            VStack(alignment: .leading, spacing: 10) {
                Label("Prezzi di esempio", systemImage: "info.circle.fill")
                    .font(.headline)
                    .foregroundStyle(.blue)
                Text("Sono inventati, per provare l'app. Per i prezzi veri di Google Voli serve una chiave gratuita: bastano due minuti.")
                    .font(.subheadline)
                Button("Usa i prezzi veri") { showKey = true }
                    .buttonStyle(.borderedProminent)
            }
            .padding(.vertical, 4)
            .sheet(isPresented: $showKey, onDismiss: {
                if !GoogleFlightsClient.current().isDemo { onConnected() }
            }) {
                GoogleKeySheet()
            }
            #if DEBUG
            .task { if DebugScreen.current == "key" { showKey = true } }
            #endif
        }
    }
}

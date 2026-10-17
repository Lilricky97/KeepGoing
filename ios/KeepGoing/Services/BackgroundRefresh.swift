import BackgroundTasks
import Foundation

/// Controlli dei prezzi con l'app chiusa. iOS decide quando farli partire (di solito qualche
/// volta al giorno, più spesso se usi l'app); non partono se chiudi l'app forzatamente.
enum BackgroundRefresh {
    /// Deve coincidere con BGTaskSchedulerPermittedIdentifiers in KeepGoing-Info.plist.
    static let identifier = "com.lilricky97.keepgoing.refresh"

    @MainActor
    static func schedule() {
        let store = MonitorStore.shared
        guard store.flights.contains(where: { !$0.isExpired() }) else { return }
        let request = BGAppRefreshTaskRequest(identifier: identifier)
        // Chiede di essere svegliata al più presto tra metà intervallo: i voli non ancora "scaduti" vengono saltati.
        request.earliestBeginDate = Date.now.addingTimeInterval(TimeInterval(store.checkIntervalHours) * 1800)
        try? BGTaskScheduler.shared.submit(request)  // nel simulatore non è disponibile: nessun problema
    }

    @MainActor
    static func run() async {
        schedule()  // il prossimo, anche se questo viene interrotto
        await MonitorStore.shared.checkDue()
    }
}

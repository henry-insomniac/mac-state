import MacStateFoundation
import MacStateStorage

@MainActor
enum AppAssembler {
    static func makeLiveContainer() -> DependencyContainer {
        let launchAtLoginService = SystemLaunchAtLoginService()
        let settingsStore = SettingsStore()
        let historyStore = MetricHistoryStore()
        let alertNotificationService = AlertNotificationService()
        let appState = AppState(
            launchAtLoginService: launchAtLoginService,
            settingsStore: settingsStore,
            historyStore: historyStore
        )
        let metricsMonitor = AppMetricsMonitor(
            appState: appState,
            historyStore: historyStore,
            alertNotificationService: alertNotificationService
        )

        return DependencyContainer(
            appState: appState,
            metricsMonitor: metricsMonitor,
            alertNotificationService: alertNotificationService
        )
    }
}

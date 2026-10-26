import MacStateFoundation
import MacStateStorage

@MainActor
enum AppAssembler {
    private static let legacyLoginHelperBundleIdentifier = "io.github.henry-insomniac.mac-state.login-helper"

    static func makeLiveContainer() -> DependencyContainer {
        let launchAtLoginService = SystemLaunchAtLoginService(
            legacyHelperBundleIdentifier: legacyLoginHelperBundleIdentifier
        )
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

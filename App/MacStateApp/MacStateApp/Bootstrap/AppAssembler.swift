import MacStateStorage

@MainActor
enum AppAssembler {
    static func makeLiveContainer() -> DependencyContainer {
        let settingsStore = SettingsStore()
        let appState = AppState(settingsStore: settingsStore)
        let metricsMonitor = AppMetricsMonitor(appState: appState)

        return DependencyContainer(
            appState: appState,
            metricsMonitor: metricsMonitor
        )
    }
}

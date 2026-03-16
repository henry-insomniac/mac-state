import MacStateStorage

@MainActor
enum AppAssembler {
    static func makeLiveContainer() -> DependencyContainer {
        let settingsStore = SettingsStore()
        let historyStore = MetricHistoryStore()
        let appState = AppState(
            settingsStore: settingsStore,
            historyStore: historyStore
        )
        let metricsMonitor = AppMetricsMonitor(
            appState: appState,
            historyStore: historyStore
        )

        return DependencyContainer(
            appState: appState,
            metricsMonitor: metricsMonitor
        )
    }
}

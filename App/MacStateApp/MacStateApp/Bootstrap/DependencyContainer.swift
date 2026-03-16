@MainActor
struct DependencyContainer {
    let appState: AppState
    let metricsMonitor: AppMetricsMonitor
    let alertNotificationService: AlertNotificationService
}

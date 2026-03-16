import Foundation
import MacStateMetrics
import MacStateStorage

@MainActor
final class AppMetricsMonitor {
    private let appState: AppState
    private let metricsProvider: any MetricsSnapshotProviding
    private let historyStore: MetricHistoryStore
    private let alertNotificationService: AlertNotificationService
    private var refreshTask: Task<Void, Never>?

    init(
        appState: AppState,
        metricsProvider: any MetricsSnapshotProviding = LiveMetricsProvider(),
        historyStore: MetricHistoryStore = MetricHistoryStore(),
        alertNotificationService: AlertNotificationService = AlertNotificationService()
    ) {
        self.appState = appState
        self.metricsProvider = metricsProvider
        self.historyStore = historyStore
        self.alertNotificationService = alertNotificationService
    }

    func start() {
        guard refreshTask == nil else {
            return
        }

        refreshTask = Task { [weak self] in
            guard let self else {
                return
            }

            await self.runRefreshLoop()
        }
    }

    func stop() {
        refreshTask?.cancel()
        refreshTask = nil
    }

    func refreshNow() {
        Task { [weak self] in
            guard let self else {
                return
            }

            await self.refreshMetrics()
        }
    }

    private func runRefreshLoop() async {
        await refreshMetrics()

        while !Task.isCancelled {
            do {
                try await Task.sleep(nanoseconds: 2_000_000_000)
            } catch {
                break
            }

            await refreshMetrics()
        }
    }

    private func refreshMetrics() async {
        do {
            let snapshot = try await metricsProvider.snapshot()
            let historySamples = await historyStore.append(snapshot: snapshot)
            let alertConfiguration = appState.alertConfiguration

            appState.apply(snapshot)
            appState.applyHistory(historySamples)
            appState.setErrorMessage(nil)

            if alertConfiguration.hasEnabledRules {
                await alertNotificationService.requestAuthorizationIfNeeded()
                let alerts = MetricAlertEvaluator.alerts(
                    for: snapshot,
                    configuration: alertConfiguration
                )
                appState.updateAlertActivity(
                    with: alerts,
                    at: snapshot.timestamp
                )
                await alertNotificationService.deliver(
                    alerts: alerts,
                    cooldownMinutes: alertConfiguration.clampedCooldownMinutes
                )
            }
        } catch {
            appState.setErrorMessage("Unable to read system metrics")
        }
    }
}

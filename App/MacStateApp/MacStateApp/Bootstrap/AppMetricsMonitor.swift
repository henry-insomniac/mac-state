import Foundation
import MacStateFoundation
import MacStateMetrics
import MacStateStorage
import WidgetKit

@MainActor
final class AppMetricsMonitor {
    private let appState: AppState
    private let metricsProvider: any MetricsSnapshotProviding
    private let historyStore: MetricHistoryStore
    private let alertNotificationService: AlertNotificationService
    private var sharedWidgetSnapshotStore: SharedWidgetSnapshotStore?
    private var widgetDeliveryPolicy = WidgetDeliveryPolicy()
    private var isRefreshing = false
    private var refreshTask: Task<Void, Never>?

    init(
        appState: AppState,
        metricsProvider: any MetricsSnapshotProviding = LiveMetricsProvider(),
        historyStore: MetricHistoryStore = MetricHistoryStore(),
        alertNotificationService: AlertNotificationService = AlertNotificationService(),
        sharedWidgetSnapshotStore: SharedWidgetSnapshotStore? = nil
    ) {
        self.appState = appState
        self.metricsProvider = metricsProvider
        self.historyStore = historyStore
        self.alertNotificationService = alertNotificationService
        self.sharedWidgetSnapshotStore = sharedWidgetSnapshotStore
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
                if #available(macOS 13.0, *) {
                    try await Task.sleep(for: .seconds(2))
                } else {
                    try await Task.sleep(nanoseconds: 2_000_000_000)
                }
            } catch {
                break
            }

            await refreshMetrics()
        }
    }

    private func refreshMetrics() async {
        guard !isRefreshing else { return }
        isRefreshing = true
        defer { isRefreshing = false }
        do {
            let snapshot = try await metricsProvider.snapshot()
            let historyTimeline = await historyStore.append(snapshot: snapshot)
            let alertConfiguration = appState.alertConfiguration

            appState.apply(snapshot)
            appState.applyHistory(historyTimeline)
            appState.setErrorMessage(nil)
            await saveWidgetSnapshotIfNeeded(snapshot)

            if alertConfiguration.hasEnabledRules {
                await alertNotificationService.requestAuthorizationIfNeeded()
                let alerts = MetricAlertEvaluator.alerts(
                    for: snapshot,
                    configuration: alertConfiguration,
                    language: appState.appLanguage
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
            appState.setErrorMessage(
                appState.resolvedLanguage == .simplifiedChinese
                    ? "无法读取系统指标"
                    : "Unable to read system metrics"
            )
        }
    }

    private func saveWidgetSnapshotIfNeeded(_ snapshot: MetricSnapshot) async {
        let date = snapshot.timestamp
        if widgetDeliveryPolicy.shouldCheckConfiguration(at: date) {
            let hasWidget = await hasConfiguredMetricOverviewWidget()
            widgetDeliveryPolicy.recordConfiguration(hasWidget: hasWidget, at: date)
        }
        guard widgetDeliveryPolicy.beginWrite(at: date) else { return }
        if sharedWidgetSnapshotStore == nil {
            sharedWidgetSnapshotStore = SharedWidgetSnapshotStore()
        }
        guard sharedWidgetSnapshotStore?.save(WidgetSnapshot(snapshot: snapshot)) == true else { return }
        if widgetDeliveryPolicy.shouldReloadAfterSuccessfulWrite(at: date) {
            WidgetCenter.shared.reloadTimelines(ofKind: SharedDataConfiguration.metricOverviewWidgetKind)
        }
    }

    private func hasConfiguredMetricOverviewWidget() async -> Bool {
        await withCheckedContinuation { continuation in
            WidgetCenter.shared.getCurrentConfigurations { result in
                let hasConfiguredWidget: Bool

                switch result {
                case let .success(configurations):
                    hasConfiguredWidget = configurations.contains { configuration in
                        configuration.kind == SharedDataConfiguration.metricOverviewWidgetKind
                    }
                case .failure:
                    hasConfiguredWidget = false
                }

                continuation.resume(returning: hasConfiguredWidget)
            }
        }
    }
}

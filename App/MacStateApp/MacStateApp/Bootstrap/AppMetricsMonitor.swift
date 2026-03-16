import Foundation
import MacStateMetrics

@MainActor
final class AppMetricsMonitor {
    private let appState: AppState
    private let metricsProvider: any MetricsSnapshotProviding
    private var refreshTask: Task<Void, Never>?

    init(
        appState: AppState,
        metricsProvider: any MetricsSnapshotProviding = LiveMetricsProvider()
    ) {
        self.appState = appState
        self.metricsProvider = metricsProvider
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
            appState.apply(snapshot)
            appState.setErrorMessage(nil)
        } catch {
            appState.setErrorMessage("Unable to read system metrics")
        }
    }
}

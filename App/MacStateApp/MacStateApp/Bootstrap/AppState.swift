import Foundation
import Combine
import MacStateMetrics
import MacStateStorage

@MainActor
final class AppState: ObservableObject {
    @Published var compactMenuBarText = true
    @Published private(set) var cpuUsage = 0.0
    @Published private(set) var memoryUsage = 0.0
    @Published private(set) var memoryUsedBytes: UInt64 = 0
    @Published private(set) var memoryTotalBytes: UInt64 = 0
    @Published private(set) var networkDownloadBytesPerSecond: UInt64 = 0
    @Published private(set) var networkUploadBytesPerSecond: UInt64 = 0
    @Published private(set) var activeNetworkInterfaces = 0
    @Published private(set) var platformSummary = "Detecting..."
    @Published private(set) var lastUpdatedAt = Date()
    @Published private(set) var errorMessage: String?

    private let settingsStore: SettingsStore
    private let metricsProvider: any MetricsSnapshotProviding
    private var refreshTask: Task<Void, Never>?

    init(
        settingsStore: SettingsStore = SettingsStore(),
        metricsProvider: any MetricsSnapshotProviding = LiveMetricsProvider()
    ) {
        self.settingsStore = settingsStore
        self.metricsProvider = metricsProvider
    }

    var menuBarTitle: String {
        guard compactMenuBarText else {
            return "mac-state"
        }

        return "mac-state \(percentageString(from: cpuUsage))"
    }

    var cpuUsageText: String {
        percentageString(from: cpuUsage)
    }

    var memoryUsageText: String {
        percentageString(from: memoryUsage)
    }

    var memoryFootprintText: String {
        guard memoryTotalBytes > 0 else {
            return "Collecting memory usage"
        }

        let usedGigabytes = Double(memoryUsedBytes) / 1_073_741_824
        let totalGigabytes = Double(memoryTotalBytes) / 1_073_741_824

        return "\(singleDecimalString(from: usedGigabytes)) / \(singleDecimalString(from: totalGigabytes)) GB"
    }

    var downloadRateText: String {
        rateString(from: networkDownloadBytesPerSecond)
    }

    var uploadRateText: String {
        rateString(from: networkUploadBytesPerSecond)
    }

    var networkStatusText: String {
        if activeNetworkInterfaces == 0 {
            return "No active interfaces"
        }

        if activeNetworkInterfaces == 1 {
            return "1 active interface"
        }

        return "\(activeNetworkInterfaces) active interfaces"
    }

    var lastUpdatedText: String {
        let components = Calendar.current.dateComponents([.hour, .minute], from: lastUpdatedAt)
        let hour = components.hour ?? 0
        let minute = components.minute ?? 0

        return "\(twoDigitString(hour)):\(twoDigitString(minute))"
    }

    func start() {
        guard refreshTask == nil else {
            return
        }

        refreshTask = Task { [weak self] in
            guard let self else {
                return
            }

            self.compactMenuBarText = await settingsStore.bool(for: .compactMenuBarText)
            await self.refreshMetrics()

            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 2_000_000_000)
                await self.refreshMetrics()
            }
        }
    }

    func stop() {
        refreshTask?.cancel()
        refreshTask = nil
    }

    func refreshNow() {
        Task {
            await refreshMetrics()
        }
    }

    func setCompactMenuBarText(_ value: Bool) {
        compactMenuBarText = value

        Task {
            await settingsStore.set(value, for: .compactMenuBarText)
        }
    }

    private func refreshMetrics() async {
        do {
            let snapshot = try await metricsProvider.snapshot()
            apply(snapshot)
            errorMessage = nil
        } catch {
            errorMessage = "Unable to read system metrics"
        }
    }

    private func apply(_ snapshot: MetricSnapshot) {
        cpuUsage = snapshot.cpuUsage
        memoryUsage = snapshot.memoryUsage
        memoryUsedBytes = snapshot.memoryUsedBytes
        memoryTotalBytes = snapshot.memoryTotalBytes
        networkDownloadBytesPerSecond = snapshot.networkDownloadBytesPerSecond
        networkUploadBytesPerSecond = snapshot.networkUploadBytesPerSecond
        activeNetworkInterfaces = snapshot.activeNetworkInterfaces
        platformSummary = snapshot.platform.architecture.rawValue
        lastUpdatedAt = snapshot.timestamp
    }

    private func percentageString(from value: Double) -> String {
        let percentage = Int((value * 100).rounded())
        return "\(percentage)%"
    }

    private func singleDecimalString(from value: Double) -> String {
        let roundedValue = (value * 10).rounded() / 10
        let wholePart = Int(roundedValue)
        let decimalPart = Int(abs((roundedValue - Double(wholePart)) * 10).rounded())

        return "\(wholePart).\(decimalPart)"
    }

    private func rateString(from bytesPerSecond: UInt64) -> String {
        let bytes = Double(bytesPerSecond)

        if bytes >= 1_048_576 {
            return "\(singleDecimalString(from: bytes / 1_048_576)) MB/s"
        }

        if bytes >= 1_024 {
            return "\(singleDecimalString(from: bytes / 1_024)) KB/s"
        }

        return "\(bytesPerSecond) B/s"
    }

    private func twoDigitString(_ value: Int) -> String {
        if value < 10 {
            return "0\(value)"
        }

        return "\(value)"
    }
}

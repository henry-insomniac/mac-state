import Foundation
import Combine
import MacStateMetrics
import MacStateStorage

@MainActor
final class AppState: ObservableObject {
    @Published var compactMenuBarText = true
    @Published private(set) var alertConfiguration = MetricAlertConfiguration()
    @Published private(set) var cpuUsage = 0.0
    @Published private(set) var cpuCores: [CPUCoreSnapshot] = []
    @Published private(set) var memoryUsage = 0.0
    @Published private(set) var memoryUsedBytes: UInt64 = 0
    @Published private(set) var memoryTotalBytes: UInt64 = 0
    @Published private(set) var diskUsedBytes: UInt64 = 0
    @Published private(set) var diskFreeBytes: UInt64 = 0
    @Published private(set) var diskTotalBytes: UInt64 = 0
    @Published private(set) var diskReadBytesPerSecond: UInt64 = 0
    @Published private(set) var diskWriteBytesPerSecond: UInt64 = 0
    @Published private(set) var networkDownloadBytesPerSecond: UInt64 = 0
    @Published private(set) var networkUploadBytesPerSecond: UInt64 = 0
    @Published private(set) var activeNetworkInterfaces = 0
    @Published private(set) var batterySnapshot: BatterySnapshot?
    @Published private(set) var processes: [ProcessSnapshot] = []
    @Published private(set) var historySamples: [MetricHistorySample] = []
    @Published private(set) var platformSummary = "Detecting..."
    @Published private(set) var lastUpdatedAt = Date()
    @Published private(set) var errorMessage: String?

    private let settingsStore: SettingsStore
    private let historyStore: MetricHistoryStore

    init(
        settingsStore: SettingsStore = SettingsStore(),
        historyStore: MetricHistoryStore = MetricHistoryStore()
    ) {
        self.settingsStore = settingsStore
        self.historyStore = historyStore
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

    var alertsSummaryText: String {
        if alertConfiguration.hasEnabledRules == false {
            return "All alerts are disabled"
        }

        return "Cooldown \(alertConfiguration.clampedCooldownMinutes)m"
    }

    var cpuCoreCountText: String {
        if cpuCores.isEmpty {
            return "Collecting per-core usage"
        }

        if cpuCores.count == 1 {
            return "1 logical core"
        }

        return "\(cpuCores.count) logical cores"
    }

    var cpuCoreTrendValues: [Double] {
        cpuCores.map(\.usage)
    }

    func cpuCoreUsageText(for core: CPUCoreSnapshot) -> String {
        percentageString(from: core.usage)
    }

    var memoryUsageText: String {
        percentageString(from: memoryUsage)
    }

    var memoryFootprintText: String {
        guard memoryTotalBytes > 0 else {
            return "Collecting memory usage"
        }

        return "\(storageString(from: memoryUsedBytes)) / \(storageString(from: memoryTotalBytes))"
    }

    var diskUsageText: String {
        guard diskTotalBytes > 0 else {
            return "Collecting disk usage"
        }

        return percentageString(from: Double(diskUsedBytes) / Double(diskTotalBytes))
    }

    var diskFootprintText: String {
        guard diskTotalBytes > 0 else {
            return "Disk metrics will appear once sampled"
        }

        return "\(storageString(from: diskUsedBytes)) / \(storageString(from: diskTotalBytes)) used"
    }

    var diskReadRateText: String {
        rateString(from: diskReadBytesPerSecond)
    }

    var diskWriteRateText: String {
        rateString(from: diskWriteBytesPerSecond)
    }

    var diskActivityText: String {
        "Read \(diskReadRateText) • Write \(diskWriteRateText)"
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

    var batteryStatusText: String {
        guard let batterySnapshot else {
            return "No battery metrics"
        }

        return percentageString(from: batterySnapshot.level)
    }

    var batteryDetailText: String {
        guard let batterySnapshot else {
            return "Battery metrics are unavailable on this Mac"
        }

        let powerText: String
        if batterySnapshot.isCharging {
            powerText = "Charging"
        } else if batterySnapshot.isOnBatteryPower {
            powerText = "On battery power"
        } else {
            powerText = "On AC power"
        }

        guard let minutes = batterySnapshot.timeRemainingMinutes, minutes > 0 else {
            return powerText
        }

        if batterySnapshot.isCharging {
            return "\(powerText) • \(durationString(fromMinutes: minutes)) to full"
        }

        if batterySnapshot.isOnBatteryPower {
            return "\(powerText) • \(durationString(fromMinutes: minutes)) remaining"
        }

        return powerText
    }

    var runningAppsText: String {
        if processes.isEmpty {
            return "No visible apps"
        }

        if processes.count == 1 {
            return "1 visible app"
        }

        return "\(processes.count) visible apps"
    }

    var historySummaryText: String {
        guard let firstSample = historySamples.first,
              let lastSample = historySamples.last else {
            return "History populates after the first successful samples"
        }

        let interval = max(lastSample.timestamp.timeIntervalSince(firstSample.timestamp), 0)

        if interval < 60 {
            return "\(historySamples.count) samples across \(Int(interval.rounded()))s"
        }

        return "\(historySamples.count) samples across \(durationString(fromMinutes: Int((interval / 60).rounded())))"
    }

    var cpuTrendValues: [Double] {
        historySamples.map(\.cpuUsage)
    }

    var memoryTrendValues: [Double] {
        historySamples.map(\.memoryUsage)
    }

    var networkTrendValues: [Double] {
        historySamples.map { Double($0.networkThroughputBytesPerSecond) }
    }

    var diskTrendValues: [Double] {
        historySamples.map { Double($0.diskThroughputBytesPerSecond) }
    }

    var batteryTrendValues: [Double] {
        historySamples.compactMap(\.batteryLevel)
    }

    var lastUpdatedText: String {
        let components = Calendar.current.dateComponents([.hour, .minute], from: lastUpdatedAt)
        let hour = components.hour ?? 0
        let minute = components.minute ?? 0

        return "\(twoDigitString(hour)):\(twoDigitString(minute))"
    }

    func loadPersistedState() async {
        compactMenuBarText = await settingsStore.bool(for: .compactMenuBarText)
        if let restoredAlertConfiguration = await settingsStore.codableValue(
            for: .alertConfiguration,
            as: MetricAlertConfiguration.self
        ) {
            alertConfiguration = restoredAlertConfiguration
        }
        historySamples = await historyStore.samples()
    }

    func setCompactMenuBarText(_ value: Bool) {
        compactMenuBarText = value

        Task {
            await settingsStore.set(value, for: .compactMenuBarText)
        }
    }

    func setCPUAlertEnabled(_ value: Bool) {
        updateAlertConfiguration { configuration in
            configuration.cpuHighUsage.isEnabled = value
        }
    }

    func setCPUAlertThreshold(_ value: Int) {
        updateAlertConfiguration { configuration in
            configuration.cpuHighUsage.thresholdPercent = value
        }
    }

    func setMemoryAlertEnabled(_ value: Bool) {
        updateAlertConfiguration { configuration in
            configuration.memoryHighUsage.isEnabled = value
        }
    }

    func setMemoryAlertThreshold(_ value: Int) {
        updateAlertConfiguration { configuration in
            configuration.memoryHighUsage.thresholdPercent = value
        }
    }

    func setBatteryAlertEnabled(_ value: Bool) {
        updateAlertConfiguration { configuration in
            configuration.batteryLowLevel.isEnabled = value
        }
    }

    func setBatteryAlertThreshold(_ value: Int) {
        updateAlertConfiguration { configuration in
            configuration.batteryLowLevel.thresholdPercent = value
        }
    }

    func setDiskAlertEnabled(_ value: Bool) {
        updateAlertConfiguration { configuration in
            configuration.diskActivityHigh.isEnabled = value
        }
    }

    func setDiskAlertThreshold(_ value: Int) {
        updateAlertConfiguration { configuration in
            configuration.diskActivityHigh.thresholdMegabytesPerSecond = value
        }
    }

    func setAlertCooldownMinutes(_ value: Int) {
        updateAlertConfiguration { configuration in
            configuration.cooldownMinutes = value
        }
    }

    func apply(_ snapshot: MetricSnapshot) {
        cpuUsage = snapshot.cpuUsage
        cpuCores = snapshot.cpuCores
        memoryUsage = snapshot.memoryUsage
        memoryUsedBytes = snapshot.memoryUsedBytes
        memoryTotalBytes = snapshot.memoryTotalBytes
        diskUsedBytes = snapshot.disk.usedBytes
        diskFreeBytes = snapshot.disk.freeBytes
        diskTotalBytes = snapshot.disk.totalBytes
        diskReadBytesPerSecond = snapshot.disk.readBytesPerSecond
        diskWriteBytesPerSecond = snapshot.disk.writeBytesPerSecond
        networkDownloadBytesPerSecond = snapshot.networkDownloadBytesPerSecond
        networkUploadBytesPerSecond = snapshot.networkUploadBytesPerSecond
        activeNetworkInterfaces = snapshot.activeNetworkInterfaces
        batterySnapshot = snapshot.battery
        processes = snapshot.processes
        platformSummary = snapshot.platform.architecture.rawValue
        lastUpdatedAt = snapshot.timestamp
    }

    func applyHistory(_ samples: [MetricHistorySample]) {
        historySamples = samples
    }

    func setErrorMessage(_ message: String?) {
        errorMessage = message
    }

    private func percentageString(from value: Double) -> String {
        let percentage = Int((value * 100).rounded())
        return "\(percentage)%"
    }

    private func updateAlertConfiguration(
        _ update: (inout MetricAlertConfiguration) -> Void
    ) {
        update(&alertConfiguration)
        let alertConfiguration = self.alertConfiguration

        Task {
            await settingsStore.set(alertConfiguration, for: .alertConfiguration)
        }
    }

    private func decimalString(from value: Double) -> String {
        let roundedValue = (value * 10).rounded() / 10
        let wholePart = Int(roundedValue.rounded(.towardZero))
        let decimalPart = Int(abs((roundedValue - Double(wholePart)) * 10).rounded())

        return "\(wholePart).\(decimalPart)"
    }

    private func storageString(from bytes: UInt64) -> String {
        let units = ["B", "KB", "MB", "GB", "TB"]
        var scaledValue = Double(bytes)
        var unitIndex = 0

        while scaledValue >= 1_024 && unitIndex < units.count - 1 {
            scaledValue /= 1_024
            unitIndex += 1
        }

        if unitIndex == 0 {
            return "\(bytes) \(units[unitIndex])"
        }

        return "\(decimalString(from: scaledValue)) \(units[unitIndex])"
    }

    private func durationString(fromMinutes minutes: Int) -> String {
        let hours = minutes / 60
        let remainingMinutes = minutes % 60

        if hours == 0 {
            return "\(remainingMinutes)m"
        }

        if remainingMinutes == 0 {
            return "\(hours)h"
        }

        return "\(hours)h \(remainingMinutes)m"
    }

    private func rateString(from bytesPerSecond: UInt64) -> String {
        let bytes = Double(bytesPerSecond)

        if bytes >= 1_048_576 {
            return "\(decimalString(from: bytes / 1_048_576)) MB/s"
        }

        if bytes >= 1_024 {
            return "\(decimalString(from: bytes / 1_024)) KB/s"
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

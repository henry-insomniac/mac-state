import Foundation

public struct MetricAlertConfiguration: Sendable, Equatable, Codable {
    public var cpuHighUsage: MetricAlertRule
    public var memoryHighUsage: MetricAlertRule
    public var batteryLowLevel: MetricAlertRule
    public var diskActivityHigh: DiskActivityAlertRule
    public var cooldownMinutes: Int

    public init(
        cpuHighUsage: MetricAlertRule = MetricAlertRule(thresholdPercent: 85),
        memoryHighUsage: MetricAlertRule = MetricAlertRule(thresholdPercent: 90),
        batteryLowLevel: MetricAlertRule = MetricAlertRule(thresholdPercent: 20),
        diskActivityHigh: DiskActivityAlertRule = DiskActivityAlertRule(thresholdMegabytesPerSecond: 250),
        cooldownMinutes: Int = 10
    ) {
        self.cpuHighUsage = cpuHighUsage
        self.memoryHighUsage = memoryHighUsage
        self.batteryLowLevel = batteryLowLevel
        self.diskActivityHigh = diskActivityHigh
        self.cooldownMinutes = cooldownMinutes
    }

    public var hasEnabledRules: Bool {
        cpuHighUsage.isEnabled
            || memoryHighUsage.isEnabled
            || batteryLowLevel.isEnabled
            || diskActivityHigh.isEnabled
    }

    public var clampedCooldownMinutes: Int {
        max(cooldownMinutes, 1)
    }
}

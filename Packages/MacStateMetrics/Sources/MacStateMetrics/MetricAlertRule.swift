import Foundation

public struct MetricAlertRule: Sendable, Equatable, Codable {
    public var isEnabled: Bool
    public var thresholdPercent: Int

    public init(
        isEnabled: Bool = false,
        thresholdPercent: Int
    ) {
        self.isEnabled = isEnabled
        self.thresholdPercent = thresholdPercent
    }

    public var thresholdValue: Double {
        min(max(Double(thresholdPercent) / 100, 0), 1)
    }
}

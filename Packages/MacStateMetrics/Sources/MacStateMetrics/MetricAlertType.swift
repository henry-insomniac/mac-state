import Foundation

public enum MetricAlertType: String, Sendable, Equatable, Hashable, Codable {
    case cpuHighUsage
    case memoryHighUsage
    case batteryLowLevel
    case diskActivityHigh
}

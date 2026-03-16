import Foundation

public enum MetricAlertType: String, Sendable, Equatable, Codable {
    case cpuHighUsage
    case memoryHighUsage
    case batteryLowLevel
    case diskActivityHigh
}

import Foundation

public struct DiskActivityAlertRule: Sendable, Equatable, Codable {
    public var isEnabled: Bool
    public var thresholdMegabytesPerSecond: Int

    public init(
        isEnabled: Bool = false,
        thresholdMegabytesPerSecond: Int
    ) {
        self.isEnabled = isEnabled
        self.thresholdMegabytesPerSecond = thresholdMegabytesPerSecond
    }

    public var thresholdBytesPerSecond: UInt64 {
        UInt64(max(thresholdMegabytesPerSecond, 0)) * 1_048_576
    }
}

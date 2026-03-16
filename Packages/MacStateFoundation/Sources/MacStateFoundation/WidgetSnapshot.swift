import Foundation

public struct WidgetSnapshot: Codable, Sendable, Equatable {
    public let timestamp: Date
    public let cpuUsage: Double
    public let memoryUsage: Double
    public let memoryUsedBytes: UInt64
    public let memoryTotalBytes: UInt64
    public let diskUsedBytes: UInt64
    public let diskTotalBytes: UInt64
    public let diskReadBytesPerSecond: UInt64
    public let diskWriteBytesPerSecond: UInt64
    public let networkDownloadBytesPerSecond: UInt64
    public let networkUploadBytesPerSecond: UInt64
    public let activeNetworkInterfaces: Int
    public let batteryLevel: Double?
    public let batteryIsCharging: Bool
    public let batteryIsOnBatteryPower: Bool
    public let batteryTimeRemainingMinutes: Int?
    public let platformSummary: String

    public init(
        timestamp: Date,
        cpuUsage: Double,
        memoryUsage: Double,
        memoryUsedBytes: UInt64,
        memoryTotalBytes: UInt64,
        diskUsedBytes: UInt64,
        diskTotalBytes: UInt64,
        diskReadBytesPerSecond: UInt64,
        diskWriteBytesPerSecond: UInt64,
        networkDownloadBytesPerSecond: UInt64,
        networkUploadBytesPerSecond: UInt64,
        activeNetworkInterfaces: Int,
        batteryLevel: Double?,
        batteryIsCharging: Bool,
        batteryIsOnBatteryPower: Bool,
        batteryTimeRemainingMinutes: Int?,
        platformSummary: String
    ) {
        self.timestamp = timestamp
        self.cpuUsage = cpuUsage
        self.memoryUsage = memoryUsage
        self.memoryUsedBytes = memoryUsedBytes
        self.memoryTotalBytes = memoryTotalBytes
        self.diskUsedBytes = diskUsedBytes
        self.diskTotalBytes = diskTotalBytes
        self.diskReadBytesPerSecond = diskReadBytesPerSecond
        self.diskWriteBytesPerSecond = diskWriteBytesPerSecond
        self.networkDownloadBytesPerSecond = networkDownloadBytesPerSecond
        self.networkUploadBytesPerSecond = networkUploadBytesPerSecond
        self.activeNetworkInterfaces = activeNetworkInterfaces
        self.batteryLevel = batteryLevel
        self.batteryIsCharging = batteryIsCharging
        self.batteryIsOnBatteryPower = batteryIsOnBatteryPower
        self.batteryTimeRemainingMinutes = batteryTimeRemainingMinutes
        self.platformSummary = platformSummary
    }

    public static let placeholder = WidgetSnapshot(
        timestamp: Date(),
        cpuUsage: 0.18,
        memoryUsage: 0.42,
        memoryUsedBytes: 6 * 1_024 * 1_024 * 1_024,
        memoryTotalBytes: 16 * 1_024 * 1_024 * 1_024,
        diskUsedBytes: 120 * 1_024 * 1_024 * 1_024,
        diskTotalBytes: 500 * 1_024 * 1_024 * 1_024,
        diskReadBytesPerSecond: 8 * 1_024 * 1_024,
        diskWriteBytesPerSecond: 3 * 1_024 * 1_024,
        networkDownloadBytesPerSecond: 12 * 1_024 * 1_024,
        networkUploadBytesPerSecond: 512 * 1_024,
        activeNetworkInterfaces: 1,
        batteryLevel: 0.88,
        batteryIsCharging: false,
        batteryIsOnBatteryPower: true,
        batteryTimeRemainingMinutes: 140,
        platformSummary: "appleSilicon"
    )
}

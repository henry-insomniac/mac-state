import Foundation
import MacStateFoundation

public struct MetricSnapshot: Sendable, Equatable {
    public let timestamp: Date
    public let cpuUsage: Double
    public let memoryUsage: Double
    public let memoryUsedBytes: UInt64
    public let memoryTotalBytes: UInt64
    public let networkDownloadBytesPerSecond: UInt64
    public let networkUploadBytesPerSecond: UInt64
    public let activeNetworkInterfaces: Int
    public let platform: PlatformCapabilities

    public init(
        timestamp: Date,
        cpuUsage: Double,
        memoryUsage: Double,
        memoryUsedBytes: UInt64,
        memoryTotalBytes: UInt64,
        networkDownloadBytesPerSecond: UInt64,
        networkUploadBytesPerSecond: UInt64,
        activeNetworkInterfaces: Int,
        platform: PlatformCapabilities
    ) {
        self.timestamp = timestamp
        self.cpuUsage = cpuUsage
        self.memoryUsage = memoryUsage
        self.memoryUsedBytes = memoryUsedBytes
        self.memoryTotalBytes = memoryTotalBytes
        self.networkDownloadBytesPerSecond = networkDownloadBytesPerSecond
        self.networkUploadBytesPerSecond = networkUploadBytesPerSecond
        self.activeNetworkInterfaces = activeNetworkInterfaces
        self.platform = platform
    }
}

public extension MetricSnapshot {
    static func placeholder(now: Date = Date()) -> MetricSnapshot {
        MetricSnapshot(
            timestamp: now,
            cpuUsage: 0.18,
            memoryUsage: 0.42,
            memoryUsedBytes: 6 * 1_024 * 1_024 * 1_024,
            memoryTotalBytes: 16 * 1_024 * 1_024 * 1_024,
            networkDownloadBytesPerSecond: 1_024 * 1_024 * 12,
            networkUploadBytesPerSecond: 1_024 * 512,
            activeNetworkInterfaces: 1,
            platform: .current
        )
    }
}

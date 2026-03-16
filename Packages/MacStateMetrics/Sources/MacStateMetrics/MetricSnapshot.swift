import Foundation
import MacStateFoundation

public struct MetricSnapshot: Sendable, Equatable {
    public let timestamp: Date
    public let cpuUsage: Double
    public let memoryUsage: Double
    public let networkDownloadRate: Double
    public let networkUploadRate: Double
    public let platform: PlatformCapabilities

    public init(
        timestamp: Date,
        cpuUsage: Double,
        memoryUsage: Double,
        networkDownloadRate: Double,
        networkUploadRate: Double,
        platform: PlatformCapabilities
    ) {
        self.timestamp = timestamp
        self.cpuUsage = cpuUsage
        self.memoryUsage = memoryUsage
        self.networkDownloadRate = networkDownloadRate
        self.networkUploadRate = networkUploadRate
        self.platform = platform
    }
}

public extension MetricSnapshot {
    static func placeholder(now: Date = Date()) -> MetricSnapshot {
        MetricSnapshot(
            timestamp: now,
            cpuUsage: 0.18,
            memoryUsage: 0.42,
            networkDownloadRate: 12.6,
            networkUploadRate: 4.2,
            platform: .current
        )
    }
}

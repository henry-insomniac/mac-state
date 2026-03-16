import Foundation

public struct MetricHistorySample: Sendable, Equatable, Codable, Identifiable {
    public let timestamp: Date
    public let cpuUsage: Double
    public let memoryUsage: Double
    public let diskUsage: Double
    public let downloadBytesPerSecond: UInt64
    public let uploadBytesPerSecond: UInt64
    public let batteryLevel: Double?

    public init(
        timestamp: Date,
        cpuUsage: Double,
        memoryUsage: Double,
        diskUsage: Double,
        downloadBytesPerSecond: UInt64,
        uploadBytesPerSecond: UInt64,
        batteryLevel: Double?
    ) {
        self.timestamp = timestamp
        self.cpuUsage = cpuUsage
        self.memoryUsage = memoryUsage
        self.diskUsage = diskUsage
        self.downloadBytesPerSecond = downloadBytesPerSecond
        self.uploadBytesPerSecond = uploadBytesPerSecond
        self.batteryLevel = batteryLevel
    }

    public init(snapshot: MetricSnapshot) {
        let diskUsage: Double
        if snapshot.disk.totalBytes > 0 {
            diskUsage = Double(snapshot.disk.usedBytes) / Double(snapshot.disk.totalBytes)
        } else {
            diskUsage = 0
        }

        self.init(
            timestamp: snapshot.timestamp,
            cpuUsage: snapshot.cpuUsage,
            memoryUsage: snapshot.memoryUsage,
            diskUsage: diskUsage,
            downloadBytesPerSecond: snapshot.networkDownloadBytesPerSecond,
            uploadBytesPerSecond: snapshot.networkUploadBytesPerSecond,
            batteryLevel: snapshot.battery?.level
        )
    }

    public var id: Date {
        timestamp
    }

    public var networkThroughputBytesPerSecond: UInt64 {
        downloadBytesPerSecond + uploadBytesPerSecond
    }
}

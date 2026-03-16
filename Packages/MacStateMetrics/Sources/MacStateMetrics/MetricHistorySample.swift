import Foundation

public struct MetricHistorySample: Sendable, Equatable, Codable, Identifiable {
    private enum CodingKeys: String, CodingKey {
        case timestamp
        case cpuUsage
        case memoryUsage
        case diskUsage
        case diskThroughputBytesPerSecond
        case downloadBytesPerSecond
        case uploadBytesPerSecond
        case batteryLevel
    }

    public let timestamp: Date
    public let cpuUsage: Double
    public let memoryUsage: Double
    public let diskUsage: Double
    public let diskThroughputBytesPerSecond: UInt64
    public let downloadBytesPerSecond: UInt64
    public let uploadBytesPerSecond: UInt64
    public let batteryLevel: Double?

    public init(
        timestamp: Date,
        cpuUsage: Double,
        memoryUsage: Double,
        diskUsage: Double,
        diskThroughputBytesPerSecond: UInt64,
        downloadBytesPerSecond: UInt64,
        uploadBytesPerSecond: UInt64,
        batteryLevel: Double?
    ) {
        self.timestamp = timestamp
        self.cpuUsage = cpuUsage
        self.memoryUsage = memoryUsage
        self.diskUsage = diskUsage
        self.diskThroughputBytesPerSecond = diskThroughputBytesPerSecond
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
            diskThroughputBytesPerSecond: snapshot.disk.readBytesPerSecond + snapshot.disk.writeBytesPerSecond,
            downloadBytesPerSecond: snapshot.networkDownloadBytesPerSecond,
            uploadBytesPerSecond: snapshot.networkUploadBytesPerSecond,
            batteryLevel: snapshot.battery?.level
        )
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.timestamp = try container.decode(Date.self, forKey: .timestamp)
        self.cpuUsage = try container.decode(Double.self, forKey: .cpuUsage)
        self.memoryUsage = try container.decode(Double.self, forKey: .memoryUsage)
        self.diskUsage = try container.decode(Double.self, forKey: .diskUsage)
        self.diskThroughputBytesPerSecond = try container.decodeIfPresent(
            UInt64.self,
            forKey: .diskThroughputBytesPerSecond
        ) ?? 0
        self.downloadBytesPerSecond = try container.decode(UInt64.self, forKey: .downloadBytesPerSecond)
        self.uploadBytesPerSecond = try container.decode(UInt64.self, forKey: .uploadBytesPerSecond)
        self.batteryLevel = try container.decodeIfPresent(Double.self, forKey: .batteryLevel)
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(timestamp, forKey: .timestamp)
        try container.encode(cpuUsage, forKey: .cpuUsage)
        try container.encode(memoryUsage, forKey: .memoryUsage)
        try container.encode(diskUsage, forKey: .diskUsage)
        try container.encode(diskThroughputBytesPerSecond, forKey: .diskThroughputBytesPerSecond)
        try container.encode(downloadBytesPerSecond, forKey: .downloadBytesPerSecond)
        try container.encode(uploadBytesPerSecond, forKey: .uploadBytesPerSecond)
        try container.encodeIfPresent(batteryLevel, forKey: .batteryLevel)
    }

    public var id: Date {
        timestamp
    }

    public var networkThroughputBytesPerSecond: UInt64 {
        downloadBytesPerSecond + uploadBytesPerSecond
    }
}

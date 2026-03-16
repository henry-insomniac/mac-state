import Foundation
import MacStateFoundation

public struct DiskSnapshot: Sendable, Equatable {
    public let usedBytes: UInt64
    public let freeBytes: UInt64
    public let totalBytes: UInt64

    public init(usedBytes: UInt64, freeBytes: UInt64, totalBytes: UInt64) {
        self.usedBytes = usedBytes
        self.freeBytes = freeBytes
        self.totalBytes = totalBytes
    }
}

public struct BatterySnapshot: Sendable, Equatable {
    public let currentCapacity: Int
    public let maxCapacity: Int
    public let isCharging: Bool
    public let isOnBatteryPower: Bool
    public let timeRemainingMinutes: Int?

    public init(
        currentCapacity: Int,
        maxCapacity: Int,
        isCharging: Bool,
        isOnBatteryPower: Bool,
        timeRemainingMinutes: Int?
    ) {
        self.currentCapacity = currentCapacity
        self.maxCapacity = maxCapacity
        self.isCharging = isCharging
        self.isOnBatteryPower = isOnBatteryPower
        self.timeRemainingMinutes = timeRemainingMinutes
    }

    public var level: Double {
        guard maxCapacity > 0 else {
            return 0
        }

        return min(max(Double(currentCapacity) / Double(maxCapacity), 0), 1)
    }
}

public struct ProcessSnapshot: Sendable, Equatable, Identifiable {
    public let id: Int32
    public let pid: Int32
    public let name: String
    public let isFrontmost: Bool

    public init(pid: Int32, name: String, isFrontmost: Bool) {
        self.id = pid
        self.pid = pid
        self.name = name
        self.isFrontmost = isFrontmost
    }
}

public struct MetricSnapshot: Sendable, Equatable {
    public let timestamp: Date
    public let cpuUsage: Double
    public let memoryUsage: Double
    public let memoryUsedBytes: UInt64
    public let memoryTotalBytes: UInt64
    public let disk: DiskSnapshot
    public let networkDownloadBytesPerSecond: UInt64
    public let networkUploadBytesPerSecond: UInt64
    public let activeNetworkInterfaces: Int
    public let battery: BatterySnapshot?
    public let processes: [ProcessSnapshot]
    public let platform: PlatformCapabilities

    public init(
        timestamp: Date,
        cpuUsage: Double,
        memoryUsage: Double,
        memoryUsedBytes: UInt64,
        memoryTotalBytes: UInt64,
        disk: DiskSnapshot,
        networkDownloadBytesPerSecond: UInt64,
        networkUploadBytesPerSecond: UInt64,
        activeNetworkInterfaces: Int,
        battery: BatterySnapshot?,
        processes: [ProcessSnapshot],
        platform: PlatformCapabilities
    ) {
        self.timestamp = timestamp
        self.cpuUsage = cpuUsage
        self.memoryUsage = memoryUsage
        self.memoryUsedBytes = memoryUsedBytes
        self.memoryTotalBytes = memoryTotalBytes
        self.disk = disk
        self.networkDownloadBytesPerSecond = networkDownloadBytesPerSecond
        self.networkUploadBytesPerSecond = networkUploadBytesPerSecond
        self.activeNetworkInterfaces = activeNetworkInterfaces
        self.battery = battery
        self.processes = processes
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
            disk: DiskSnapshot(
                usedBytes: 120 * 1_024 * 1_024 * 1_024,
                freeBytes: 380 * 1_024 * 1_024 * 1_024,
                totalBytes: 500 * 1_024 * 1_024 * 1_024
            ),
            networkDownloadBytesPerSecond: 1_024 * 1_024 * 12,
            networkUploadBytesPerSecond: 1_024 * 512,
            activeNetworkInterfaces: 1,
            battery: BatterySnapshot(
                currentCapacity: 88,
                maxCapacity: 100,
                isCharging: false,
                isOnBatteryPower: true,
                timeRemainingMinutes: 140
            ),
            processes: [
                ProcessSnapshot(pid: 101, name: "Xcode", isFrontmost: true),
                ProcessSnapshot(pid: 202, name: "Safari", isFrontmost: false),
                ProcessSnapshot(pid: 303, name: "Terminal", isFrontmost: false),
            ],
            platform: .current
        )
    }
}

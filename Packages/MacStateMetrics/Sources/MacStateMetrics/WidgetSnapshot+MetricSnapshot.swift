import MacStateFoundation

public extension WidgetSnapshot {
    init(snapshot: MetricSnapshot) {
        self.init(
            timestamp: snapshot.timestamp,
            cpuUsage: snapshot.cpuUsage,
            memoryUsage: snapshot.memoryUsage,
            memoryUsedBytes: snapshot.memoryUsedBytes,
            memoryTotalBytes: snapshot.memoryTotalBytes,
            diskUsedBytes: snapshot.disk.usedBytes,
            diskTotalBytes: snapshot.disk.totalBytes,
            diskReadBytesPerSecond: snapshot.disk.readBytesPerSecond,
            diskWriteBytesPerSecond: snapshot.disk.writeBytesPerSecond,
            networkDownloadBytesPerSecond: snapshot.networkDownloadBytesPerSecond,
            networkUploadBytesPerSecond: snapshot.networkUploadBytesPerSecond,
            activeNetworkInterfaces: snapshot.activeNetworkInterfaces,
            batteryLevel: snapshot.battery?.level,
            batteryIsCharging: snapshot.battery?.isCharging ?? false,
            batteryIsOnBatteryPower: snapshot.battery?.isOnBatteryPower ?? false,
            batteryTimeRemainingMinutes: snapshot.battery?.timeRemainingMinutes,
            platformSummary: snapshot.platform.architecture.rawValue
        )
    }
}

import Testing
@testable import MacStateMetrics
import Foundation
import MacStateFoundation

@Test func defaultSnapshotUsesExpectedRanges() {
    let snapshot = MetricSnapshot.placeholder()

    #expect(snapshot.cpuUsage >= 0)
    #expect(snapshot.cpuUsage <= 1)
    #expect(snapshot.cpuCores.isEmpty == false)
    #expect(snapshot.memoryUsage >= 0)
    #expect(snapshot.memoryUsage <= 1)
    #expect(snapshot.memoryUsedBytes <= snapshot.memoryTotalBytes)
    #expect(snapshot.disk.usedBytes <= snapshot.disk.totalBytes)
    #expect(snapshot.disk.freeBytes <= snapshot.disk.totalBytes)
    #expect(snapshot.disk.readBytesPerSecond >= 0)
    #expect(snapshot.disk.writeBytesPerSecond >= 0)
    #expect(snapshot.networkDownloadBytesPerSecond >= 0)
    #expect(snapshot.networkUploadBytesPerSecond >= 0)
    #expect(snapshot.processes.isEmpty == false)
    #expect(snapshot.battery?.level ?? 0 >= 0)
    #expect(snapshot.sensors.hasTemperatureTelemetry == true)
    #expect(snapshot.sensors.hasFanTelemetry == true)
}

@Test func cpuUsageUsesDeltaBetweenSamples() {
    let previous = CPULoadCounters(user: 100, nice: 20, system: 40, idle: 200)
    let current = CPULoadCounters(user: 130, nice: 20, system: 60, idle: 240)

    let usage = current.usage(since: previous)

    #expect(abs(usage - 0.5555555556) < 0.0001)
}

@Test func networkRatesUseElapsedTime() {
    let previous = NetworkCounters(
        timestamp: Date(timeIntervalSince1970: 100),
        receivedBytes: 1_000,
        sentBytes: 2_000,
        activeInterfaces: 1
    )
    let current = NetworkCounters(
        timestamp: Date(timeIntervalSince1970: 102),
        receivedBytes: 5_000,
        sentBytes: 3_000,
        activeInterfaces: 1
    )

    let rates = current.rates(since: previous)

    #expect(rates.download == 2_000)
    #expect(rates.upload == 500)
}

@Test func metricHistorySampleCapturesSnapshotFields() {
    let snapshot = MetricSnapshot.placeholder(
        now: Date(timeIntervalSince1970: 200)
    )

    let sample = MetricHistorySample(snapshot: snapshot)

    #expect(sample.timestamp == snapshot.timestamp)
    #expect(sample.cpuUsage == snapshot.cpuUsage)
    #expect(sample.memoryUsage == snapshot.memoryUsage)
    #expect(sample.diskThroughputBytesPerSecond == 11_534_336)
    #expect(sample.downloadBytesPerSecond == snapshot.networkDownloadBytesPerSecond)
    #expect(sample.uploadBytesPerSecond == snapshot.networkUploadBytesPerSecond)
    #expect(sample.batteryLevel == snapshot.battery?.level)
    #expect(sample.networkThroughputBytesPerSecond == 13_107_200)
}

@Test func diskRatesUseElapsedTime() {
    let previous = DiskIOCounters(
        timestamp: Date(timeIntervalSince1970: 100),
        readBytes: 2_000,
        writeBytes: 4_000
    )
    let current = DiskIOCounters(
        timestamp: Date(timeIntervalSince1970: 102),
        readBytes: 10_000,
        writeBytes: 5_000
    )

    let rates = current.rates(since: previous)

    #expect(rates.read == 4_000)
    #expect(rates.write == 500)
}

@Test func alertEvaluatorReturnsConfiguredAlerts() {
    let snapshot = MetricSnapshot(
        timestamp: Date(timeIntervalSince1970: 300),
        cpuUsage: 0.92,
        cpuCores: [
            CPUCoreSnapshot(index: 0, usage: 0.95),
            CPUCoreSnapshot(index: 1, usage: 0.88),
        ],
        memoryUsage: 0.93,
        memoryUsedBytes: 15,
        memoryTotalBytes: 16,
        disk: DiskSnapshot(
            usedBytes: 10,
            freeBytes: 20,
            totalBytes: 30,
            readBytesPerSecond: 300 * 1_048_576,
            writeBytesPerSecond: 10 * 1_048_576
        ),
        networkDownloadBytesPerSecond: 0,
        networkUploadBytesPerSecond: 0,
        activeNetworkInterfaces: 1,
        battery: BatterySnapshot(
            currentCapacity: 12,
            maxCapacity: 100,
            isCharging: false,
            isOnBatteryPower: true,
            timeRemainingMinutes: 25
        ),
        sensors: SensorSnapshot(
            thermalCondition: .serious,
            sourceDescription: "Test sensor data",
            cpuTemperatureCelsius: 92,
            gpuTemperatureCelsius: 74,
            batteryTemperatureCelsius: 35,
            fans: [
                FanSnapshot(
                    index: 0,
                    currentRPM: 3_500,
                    minimumRPM: 1_200,
                    maximumRPM: 5_500
                ),
            ]
        ),
        processes: [],
        platform: PlatformCapabilities.current
    )
    let configuration = MetricAlertConfiguration(
        cpuHighUsage: MetricAlertRule(isEnabled: true, thresholdPercent: 85),
        memoryHighUsage: MetricAlertRule(isEnabled: true, thresholdPercent: 90),
        batteryLowLevel: MetricAlertRule(isEnabled: true, thresholdPercent: 20),
        diskActivityHigh: DiskActivityAlertRule(
            isEnabled: true,
            thresholdMegabytesPerSecond: 200
        ),
        cooldownMinutes: 5
    )

    let alerts = MetricAlertEvaluator.alerts(
        for: snapshot,
        configuration: configuration
    )

    #expect(alerts.count == 4)
    #expect(alerts.map(\.type).contains(.cpuHighUsage))
    #expect(alerts.map(\.type).contains(.memoryHighUsage))
    #expect(alerts.map(\.type).contains(.batteryLowLevel))
    #expect(alerts.map(\.type).contains(.diskActivityHigh))
}

@Test func widgetSnapshotCopiesRelevantMetricFields() {
    let snapshot = MetricSnapshot.placeholder(
        now: Date(timeIntervalSince1970: 400)
    )

    let widgetSnapshot = WidgetSnapshot(snapshot: snapshot)

    #expect(widgetSnapshot.timestamp == snapshot.timestamp)
    #expect(widgetSnapshot.cpuUsage == snapshot.cpuUsage)
    #expect(widgetSnapshot.memoryUsage == snapshot.memoryUsage)
    #expect(widgetSnapshot.diskReadBytesPerSecond == snapshot.disk.readBytesPerSecond)
    #expect(widgetSnapshot.diskWriteBytesPerSecond == snapshot.disk.writeBytesPerSecond)
    #expect(widgetSnapshot.networkDownloadBytesPerSecond == snapshot.networkDownloadBytesPerSecond)
    #expect(widgetSnapshot.networkUploadBytesPerSecond == snapshot.networkUploadBytesPerSecond)
    #expect(widgetSnapshot.batteryLevel == snapshot.battery?.level)
}

@Test func thermalConditionMapsFromProcessInfoValues() {
    #expect(ThermalCondition(processInfoThermalState: .nominal) == .nominal)
    #expect(ThermalCondition(processInfoThermalState: .fair) == .fair)
    #expect(ThermalCondition(processInfoThermalState: .serious) == .serious)
    #expect(ThermalCondition(processInfoThermalState: .critical) == .critical)
}

import Testing
@testable import MacStateMetrics
import Foundation

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

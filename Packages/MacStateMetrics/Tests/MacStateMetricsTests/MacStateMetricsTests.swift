import Testing
@testable import MacStateMetrics
import Foundation

@Test func defaultSnapshotUsesExpectedRanges() {
    let snapshot = MetricSnapshot.placeholder()

    #expect(snapshot.cpuUsage >= 0)
    #expect(snapshot.cpuUsage <= 1)
    #expect(snapshot.memoryUsage >= 0)
    #expect(snapshot.memoryUsage <= 1)
    #expect(snapshot.memoryUsedBytes <= snapshot.memoryTotalBytes)
    #expect(snapshot.networkDownloadBytesPerSecond >= 0)
    #expect(snapshot.networkUploadBytesPerSecond >= 0)
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

import Testing
@testable import MacStateStorage
import Foundation
import MacStateFoundation
import MacStateMetrics

@Test func settingsStoreReadsValuesThatWereWritten() async {
    let defaults = UserDefaults(suiteName: #function)!
    defaults.removePersistentDomain(forName: #function)
    let store = SettingsStore(defaults: defaults)

    await store.set(true, for: SettingsKey.compactMenuBarText)

    let value = await store.bool(for: .compactMenuBarText)

    #expect(value == true)
}

@Test func settingsStoreReportsMissingBoolAsNil() async {
    let defaults = UserDefaults(suiteName: #function)!
    defaults.removePersistentDomain(forName: #function)
    let store = SettingsStore(defaults: defaults)

    let value = await store.boolValue(for: .compactMenuBarText)

    #expect(value == nil)
}

@Test func metricHistoryStoreRetainsMostRecentSamples() async {
    let fileURL = temporaryHistoryFileURL(named: #function)

    let store = MetricHistoryStore(
        fileURL: fileURL,
        legacyDefaults: nil,
        recentMaximumSampleCount: 2,
        dayMaximumBucketCount: 10
    )
    let first = MetricHistorySample(snapshot: .placeholder(now: Date(timeIntervalSince1970: 10)))
    let second = MetricHistorySample(snapshot: .placeholder(now: Date(timeIntervalSince1970: 20)))
    let third = MetricHistorySample(snapshot: .placeholder(now: Date(timeIntervalSince1970: 30)))

    _ = await store.append(first)
    _ = await store.append(second)
    let retained = await store.append(third)

    #expect(retained.recentSamples.count == 2)
    #expect(retained.recentSamples.first?.timestamp == second.timestamp)
    #expect(retained.recentSamples.last?.timestamp == third.timestamp)

    let reloadedStore = MetricHistoryStore(
        fileURL: fileURL,
        legacyDefaults: nil,
        recentMaximumSampleCount: 2,
        dayMaximumBucketCount: 10
    )
    let reloadedSamples = await reloadedStore.samples()

    #expect(reloadedSamples == retained.recentSamples)
}

@Test func metricHistoryStoreAggregatesSamplesIntoMinuteBuckets() async {
    let fileURL = temporaryHistoryFileURL(named: #function)
    let store = MetricHistoryStore(
        fileURL: fileURL,
        legacyDefaults: nil,
        recentMaximumSampleCount: 10,
        dayMaximumBucketCount: 10
    )

    let first = MetricHistorySample(
        timestamp: Date(timeIntervalSince1970: 0),
        cpuUsage: 0.2,
        memoryUsage: 0.4,
        diskUsage: 0.3,
        diskThroughputBytesPerSecond: 100,
        downloadBytesPerSecond: 200,
        uploadBytesPerSecond: 80,
        batteryLevel: 0.5
    )
    let second = MetricHistorySample(
        timestamp: Date(timeIntervalSince1970: 20),
        cpuUsage: 0.6,
        memoryUsage: 0.8,
        diskUsage: 0.7,
        diskThroughputBytesPerSecond: 500,
        downloadBytesPerSecond: 600,
        uploadBytesPerSecond: 120,
        batteryLevel: 0.7
    )
    let third = MetricHistorySample(
        timestamp: Date(timeIntervalSince1970: 80),
        cpuUsage: 0.3,
        memoryUsage: 0.5,
        diskUsage: 0.4,
        diskThroughputBytesPerSecond: 200,
        downloadBytesPerSecond: 300,
        uploadBytesPerSecond: 150,
        batteryLevel: 0.9
    )

    _ = await store.append(first)
    _ = await store.append(second)
    let timeline = await store.append(third)

    #expect(timeline.recentSamples.count == 3)
    #expect(timeline.daySamples.count == 2)
    #expect(timeline.daySamples[0].timestamp == Date(timeIntervalSince1970: 0))
    #expect(timeline.daySamples[1].timestamp == Date(timeIntervalSince1970: 60))
    #expect(abs(timeline.daySamples[0].cpuUsage - 0.4) < 0.0001)
    #expect(abs(timeline.daySamples[0].memoryUsage - 0.6) < 0.0001)
    #expect(timeline.daySamples[0].diskThroughputBytesPerSecond == 300)
    #expect(timeline.daySamples[0].downloadBytesPerSecond == 400)
    #expect(timeline.daySamples[0].uploadBytesPerSecond == 100)
    #expect(abs((timeline.daySamples[0].batteryLevel ?? 0) - 0.6) < 0.0001)
}

@Test func settingsStoreReadsCodableValuesThatWereWritten() async {
    let defaults = UserDefaults(suiteName: #function)!
    defaults.removePersistentDomain(forName: #function)
    let store = SettingsStore(defaults: defaults)
    let configuration = MetricAlertConfiguration(
        cpuHighUsage: MetricAlertRule(isEnabled: true, thresholdPercent: 80),
        memoryHighUsage: MetricAlertRule(isEnabled: false, thresholdPercent: 90),
        batteryLowLevel: MetricAlertRule(isEnabled: true, thresholdPercent: 15),
        diskActivityHigh: DiskActivityAlertRule(isEnabled: true, thresholdMegabytesPerSecond: 200),
        cooldownMinutes: 12
    )

    await store.set(configuration, for: .alertConfiguration)

    let restored = await store.codableValue(
        for: .alertConfiguration,
        as: MetricAlertConfiguration.self
    )

    #expect(restored == configuration)
}

@Test func settingsStoreReadsMenuBarPresentationThatWasWritten() async {
    let defaults = UserDefaults(suiteName: #function)!
    defaults.removePersistentDomain(forName: #function)
    let store = SettingsStore(defaults: defaults)
    let presentation = MenuBarPresentation(
        textMode: .iconOnly,
        primaryMetric: .networkDownload
    )

    await store.set(presentation, for: .menuBarPresentation)

    let restored = await store.codableValue(
        for: .menuBarPresentation,
        as: MenuBarPresentation.self
    )

    #expect(restored == presentation)
}

private func temporaryHistoryFileURL(named name: String) -> URL {
    let baseDirectoryURL = FileManager.default.temporaryDirectory
        .appendingPathComponent("mac-state-tests", isDirectory: true)
    try? FileManager.default.createDirectory(
        at: baseDirectoryURL,
        withIntermediateDirectories: true,
        attributes: nil
    )

    let sanitizedName = name.replacingOccurrences(of: " ", with: "-")
    let fileURL = baseDirectoryURL
        .appendingPathComponent(sanitizedName, isDirectory: true)
        .appendingPathComponent("metric-history.json", isDirectory: false)

    try? FileManager.default.removeItem(at: fileURL.deletingLastPathComponent())
    return fileURL
}

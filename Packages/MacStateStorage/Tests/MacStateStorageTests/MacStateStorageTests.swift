import Testing
@testable import MacStateStorage
import Foundation
import MacStateMetrics

@Test func settingsStoreReadsValuesThatWereWritten() async {
    let defaults = UserDefaults(suiteName: #function)!
    defaults.removePersistentDomain(forName: #function)
    let store = SettingsStore(defaults: defaults)

    await store.set(true, for: SettingsKey.compactMenuBarText)

    let value = await store.bool(for: .compactMenuBarText)

    #expect(value == true)
}

@Test func metricHistoryStoreRetainsMostRecentSamples() async {
    let suiteName = #function
    let defaults = UserDefaults(suiteName: suiteName)!
    defaults.removePersistentDomain(forName: suiteName)

    let store = MetricHistoryStore(
        defaults: UserDefaults(suiteName: suiteName)!,
        maximumSampleCount: 2
    )
    let first = MetricHistorySample(snapshot: .placeholder(now: Date(timeIntervalSince1970: 10)))
    let second = MetricHistorySample(snapshot: .placeholder(now: Date(timeIntervalSince1970: 20)))
    let third = MetricHistorySample(snapshot: .placeholder(now: Date(timeIntervalSince1970: 30)))

    _ = await store.append(first)
    _ = await store.append(second)
    let retained = await store.append(third)

    #expect(retained.count == 2)
    #expect(retained.first?.timestamp == second.timestamp)
    #expect(retained.last?.timestamp == third.timestamp)

    let reloadedStore = MetricHistoryStore(
        defaults: UserDefaults(suiteName: suiteName)!,
        maximumSampleCount: 2
    )
    let reloadedSamples = await reloadedStore.samples()

    #expect(reloadedSamples == retained)
}

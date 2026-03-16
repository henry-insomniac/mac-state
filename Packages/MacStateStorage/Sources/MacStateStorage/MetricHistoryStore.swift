import Foundation
import MacStateMetrics

public actor MetricHistoryStore {
    private enum StorageKey {
        static let samples = "mac-state.metric-history.samples"
    }

    private let defaults: UserDefaults
    private let maximumSampleCount: Int
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    public init(
        defaults: UserDefaults = .standard,
        maximumSampleCount: Int = 60
    ) {
        self.defaults = defaults
        self.maximumSampleCount = maximumSampleCount
    }

    public func samples() -> [MetricHistorySample] {
        loadSamples()
    }

    @discardableResult
    public func append(snapshot: MetricSnapshot) -> [MetricHistorySample] {
        append(MetricHistorySample(snapshot: snapshot))
    }

    @discardableResult
    public func append(_ sample: MetricHistorySample) -> [MetricHistorySample] {
        var samples = loadSamples()
        samples.append(sample)

        if samples.count > maximumSampleCount {
            samples = Array(samples.suffix(maximumSampleCount))
        }

        persist(samples)
        return samples
    }

    public func clear() {
        defaults.removeObject(forKey: StorageKey.samples)
    }

    private func loadSamples() -> [MetricHistorySample] {
        guard let data = defaults.data(forKey: StorageKey.samples) else {
            return []
        }

        return (try? decoder.decode([MetricHistorySample].self, from: data)) ?? []
    }

    private func persist(_ samples: [MetricHistorySample]) {
        guard let data = try? encoder.encode(samples) else {
            return
        }

        defaults.set(data, forKey: StorageKey.samples)
    }
}

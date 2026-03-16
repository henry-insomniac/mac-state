import Foundation
import MacStateMetrics

public actor MetricHistoryStore {
    private enum StorageKey {
        static let samples = "mac-state.metric-history.samples"
    }

    private struct StoredArchive: Codable {
        struct DayBucket: Codable {
            var sample: MetricHistorySample
            var sampleCount: Int
            var batterySampleCount: Int
        }

        var recentSamples: [MetricHistorySample]
        var dayBuckets: [DayBucket]

        var timeline: MetricHistoryArchive {
            MetricHistoryArchive(
                recentSamples: recentSamples,
                daySamples: dayBuckets.map(\.sample)
            )
        }
    }

    private let legacyDefaults: UserDefaults?
    private let fileURL: URL
    private let fileManager: FileManager
    private let recentMaximumSampleCount: Int
    private let dayMaximumBucketCount: Int
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    private let calendar = Calendar(identifier: .gregorian)
    private var archive: StoredArchive

    public init(
        fileURL: URL? = nil,
        legacyDefaults: UserDefaults? = .standard,
        fileManager: FileManager = .default,
        recentMaximumSampleCount: Int = 180,
        dayMaximumBucketCount: Int = 1_440
    ) {
        let resolvedFileURL = fileURL ?? Self.defaultFileURL(using: fileManager)

        self.legacyDefaults = legacyDefaults
        self.fileManager = fileManager
        self.fileURL = resolvedFileURL
        self.recentMaximumSampleCount = recentMaximumSampleCount
        self.dayMaximumBucketCount = dayMaximumBucketCount
        self.archive = Self.loadArchive(
            from: resolvedFileURL,
            decoder: JSONDecoder(),
            legacyDefaults: legacyDefaults,
            fileManager: fileManager
        )
    }

    public func samples() -> [MetricHistorySample] {
        archive.recentSamples
    }

    public func timeline() -> MetricHistoryArchive {
        archive.timeline
    }

    @discardableResult
    public func append(snapshot: MetricSnapshot) -> MetricHistoryArchive {
        append(MetricHistorySample(snapshot: snapshot))
    }

    @discardableResult
    public func append(_ sample: MetricHistorySample) -> MetricHistoryArchive {
        archive.recentSamples.append(sample)
        trimRecentSamplesIfNeeded()
        mergeDayBucket(for: sample)
        trimDayBucketsIfNeeded()
        persist()
        return archive.timeline
    }

    public func clear() {
        archive = StoredArchive(recentSamples: [], dayBuckets: [])

        try? fileManager.removeItem(at: fileURL)
        legacyDefaults?.removeObject(forKey: StorageKey.samples)
    }

    private func trimRecentSamplesIfNeeded() {
        guard archive.recentSamples.count > recentMaximumSampleCount else {
            return
        }

        archive.recentSamples = Array(archive.recentSamples.suffix(recentMaximumSampleCount))
    }

    private func trimDayBucketsIfNeeded() {
        guard archive.dayBuckets.count > dayMaximumBucketCount else {
            return
        }

        archive.dayBuckets = Array(archive.dayBuckets.suffix(dayMaximumBucketCount))
    }

    private func mergeDayBucket(for sample: MetricHistorySample) {
        let bucketTimestamp = minuteStart(for: sample.timestamp)
        let bucketSample = MetricHistorySample(
            timestamp: bucketTimestamp,
            cpuUsage: sample.cpuUsage,
            memoryUsage: sample.memoryUsage,
            diskUsage: sample.diskUsage,
            diskThroughputBytesPerSecond: sample.diskThroughputBytesPerSecond,
            downloadBytesPerSecond: sample.downloadBytesPerSecond,
            uploadBytesPerSecond: sample.uploadBytesPerSecond,
            batteryLevel: sample.batteryLevel
        )

        guard let lastBucket = archive.dayBuckets.last else {
            archive.dayBuckets.append(
                StoredArchive.DayBucket(
                    sample: bucketSample,
                    sampleCount: 1,
                    batterySampleCount: sample.batteryLevel == nil ? 0 : 1
                )
            )
            return
        }

        guard lastBucket.sample.timestamp == bucketTimestamp else {
            archive.dayBuckets.append(
                StoredArchive.DayBucket(
                    sample: bucketSample,
                    sampleCount: 1,
                    batterySampleCount: sample.batteryLevel == nil ? 0 : 1
                )
            )
            return
        }

        let mergedSampleCount = lastBucket.sampleCount + 1
        let mergedBatterySampleCount = lastBucket.batterySampleCount + (sample.batteryLevel == nil ? 0 : 1)

        let mergedSample = MetricHistorySample(
            timestamp: bucketTimestamp,
            cpuUsage: weightedAverage(
                currentValue: lastBucket.sample.cpuUsage,
                currentCount: lastBucket.sampleCount,
                nextValue: sample.cpuUsage
            ),
            memoryUsage: weightedAverage(
                currentValue: lastBucket.sample.memoryUsage,
                currentCount: lastBucket.sampleCount,
                nextValue: sample.memoryUsage
            ),
            diskUsage: weightedAverage(
                currentValue: lastBucket.sample.diskUsage,
                currentCount: lastBucket.sampleCount,
                nextValue: sample.diskUsage
            ),
            diskThroughputBytesPerSecond: weightedAverage(
                currentValue: lastBucket.sample.diskThroughputBytesPerSecond,
                currentCount: lastBucket.sampleCount,
                nextValue: sample.diskThroughputBytesPerSecond
            ),
            downloadBytesPerSecond: weightedAverage(
                currentValue: lastBucket.sample.downloadBytesPerSecond,
                currentCount: lastBucket.sampleCount,
                nextValue: sample.downloadBytesPerSecond
            ),
            uploadBytesPerSecond: weightedAverage(
                currentValue: lastBucket.sample.uploadBytesPerSecond,
                currentCount: lastBucket.sampleCount,
                nextValue: sample.uploadBytesPerSecond
            ),
            batteryLevel: mergedBatteryLevel(
                currentValue: lastBucket.sample.batteryLevel,
                currentCount: lastBucket.batterySampleCount,
                nextValue: sample.batteryLevel
            )
        )

        archive.dayBuckets[archive.dayBuckets.count - 1] = StoredArchive.DayBucket(
            sample: mergedSample,
            sampleCount: mergedSampleCount,
            batterySampleCount: mergedBatterySampleCount
        )
    }

    private func persist() {
        let parentDirectoryURL = fileURL.deletingLastPathComponent()
        try? fileManager.createDirectory(
            at: parentDirectoryURL,
            withIntermediateDirectories: true,
            attributes: nil
        )

        guard let data = try? encoder.encode(archive) else {
            return
        }

        try? data.write(to: fileURL, options: .atomic)
    }

    private func minuteStart(for date: Date) -> Date {
        if let interval = calendar.dateInterval(of: .minute, for: date) {
            return interval.start
        }

        return date
    }

    private func weightedAverage(
        currentValue: Double,
        currentCount: Int,
        nextValue: Double
    ) -> Double {
        let currentTotal = currentValue * Double(currentCount)
        return (currentTotal + nextValue) / Double(currentCount + 1)
    }

    private func weightedAverage(
        currentValue: UInt64,
        currentCount: Int,
        nextValue: UInt64
    ) -> UInt64 {
        let average = weightedAverage(
            currentValue: Double(currentValue),
            currentCount: currentCount,
            nextValue: Double(nextValue)
        )

        return UInt64(max(average.rounded(), 0))
    }

    private func mergedBatteryLevel(
        currentValue: Double?,
        currentCount: Int,
        nextValue: Double?
    ) -> Double? {
        let nextCount = nextValue == nil ? 0 : 1
        let totalCount = currentCount + nextCount

        guard totalCount > 0 else {
            return nil
        }

        let currentTotal = (currentValue ?? 0) * Double(currentCount)
        let nextTotal = (nextValue ?? 0) * Double(nextCount)
        return (currentTotal + nextTotal) / Double(totalCount)
    }

    private static func loadArchive(
        from fileURL: URL,
        decoder: JSONDecoder,
        legacyDefaults: UserDefaults?,
        fileManager: FileManager
    ) -> StoredArchive {
        if let data = try? Data(contentsOf: fileURL),
           let archive = try? decoder.decode(StoredArchive.self, from: data) {
            return archive
        }

        guard let legacyData = legacyDefaults?.data(forKey: StorageKey.samples),
              let recentSamples = try? decoder.decode([MetricHistorySample].self, from: legacyData) else {
            return StoredArchive(recentSamples: [], dayBuckets: [])
        }

        let store = StoredArchive(
            recentSamples: Array(recentSamples.suffix(180)),
            dayBuckets: legacyDayBuckets(from: recentSamples, limit: 1_440)
        )

        let parentDirectoryURL = fileURL.deletingLastPathComponent()
        try? fileManager.createDirectory(
            at: parentDirectoryURL,
            withIntermediateDirectories: true,
            attributes: nil
        )

        if let migratedData = try? JSONEncoder().encode(store) {
            try? migratedData.write(to: fileURL, options: .atomic)
        }

        return store
    }

    private static func legacyDayBuckets(
        from samples: [MetricHistorySample],
        limit: Int
    ) -> [StoredArchive.DayBucket] {
        var buckets: [StoredArchive.DayBucket] = []
        let calendar = Calendar(identifier: .gregorian)

        for sample in samples {
            let bucketTimestamp = calendar.dateInterval(of: .minute, for: sample.timestamp)?.start ?? sample.timestamp

            if let lastBucket = buckets.last, lastBucket.sample.timestamp == bucketTimestamp {
                let mergedSampleCount = lastBucket.sampleCount + 1
                let mergedBatterySampleCount = lastBucket.batterySampleCount + (sample.batteryLevel == nil ? 0 : 1)
                let mergedSample = MetricHistorySample(
                    timestamp: bucketTimestamp,
                    cpuUsage: weightedAverage(
                        currentValue: lastBucket.sample.cpuUsage,
                        currentCount: lastBucket.sampleCount,
                        nextValue: sample.cpuUsage
                    ),
                    memoryUsage: weightedAverage(
                        currentValue: lastBucket.sample.memoryUsage,
                        currentCount: lastBucket.sampleCount,
                        nextValue: sample.memoryUsage
                    ),
                    diskUsage: weightedAverage(
                        currentValue: lastBucket.sample.diskUsage,
                        currentCount: lastBucket.sampleCount,
                        nextValue: sample.diskUsage
                    ),
                    diskThroughputBytesPerSecond: weightedAverage(
                        currentValue: lastBucket.sample.diskThroughputBytesPerSecond,
                        currentCount: lastBucket.sampleCount,
                        nextValue: sample.diskThroughputBytesPerSecond
                    ),
                    downloadBytesPerSecond: weightedAverage(
                        currentValue: lastBucket.sample.downloadBytesPerSecond,
                        currentCount: lastBucket.sampleCount,
                        nextValue: sample.downloadBytesPerSecond
                    ),
                    uploadBytesPerSecond: weightedAverage(
                        currentValue: lastBucket.sample.uploadBytesPerSecond,
                        currentCount: lastBucket.sampleCount,
                        nextValue: sample.uploadBytesPerSecond
                    ),
                    batteryLevel: mergedBatteryLevel(
                        currentValue: lastBucket.sample.batteryLevel,
                        currentCount: lastBucket.batterySampleCount,
                        nextValue: sample.batteryLevel
                    )
                )

                buckets[buckets.count - 1] = StoredArchive.DayBucket(
                    sample: mergedSample,
                    sampleCount: mergedSampleCount,
                    batterySampleCount: mergedBatterySampleCount
                )
            } else {
                buckets.append(
                    StoredArchive.DayBucket(
                        sample: MetricHistorySample(
                            timestamp: bucketTimestamp,
                            cpuUsage: sample.cpuUsage,
                            memoryUsage: sample.memoryUsage,
                            diskUsage: sample.diskUsage,
                            diskThroughputBytesPerSecond: sample.diskThroughputBytesPerSecond,
                            downloadBytesPerSecond: sample.downloadBytesPerSecond,
                            uploadBytesPerSecond: sample.uploadBytesPerSecond,
                            batteryLevel: sample.batteryLevel
                        ),
                        sampleCount: 1,
                        batterySampleCount: sample.batteryLevel == nil ? 0 : 1
                    )
                )
            }
        }

        if buckets.count > limit {
            return Array(buckets.suffix(limit))
        }

        return buckets
    }

    private static func weightedAverage(
        currentValue: Double,
        currentCount: Int,
        nextValue: Double
    ) -> Double {
        let currentTotal = currentValue * Double(currentCount)
        return (currentTotal + nextValue) / Double(currentCount + 1)
    }

    private static func weightedAverage(
        currentValue: UInt64,
        currentCount: Int,
        nextValue: UInt64
    ) -> UInt64 {
        let average = weightedAverage(
            currentValue: Double(currentValue),
            currentCount: currentCount,
            nextValue: Double(nextValue)
        )

        return UInt64(max(average.rounded(), 0))
    }

    private static func mergedBatteryLevel(
        currentValue: Double?,
        currentCount: Int,
        nextValue: Double?
    ) -> Double? {
        let nextCount = nextValue == nil ? 0 : 1
        let totalCount = currentCount + nextCount

        guard totalCount > 0 else {
            return nil
        }

        let currentTotal = (currentValue ?? 0) * Double(currentCount)
        let nextTotal = (nextValue ?? 0) * Double(nextCount)
        return (currentTotal + nextTotal) / Double(totalCount)
    }

    private static func defaultFileURL(using fileManager: FileManager) -> URL {
        let applicationSupportURL = fileManager.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first ?? fileManager.temporaryDirectory

        return applicationSupportURL
            .appendingPathComponent("mac-state", isDirectory: true)
            .appendingPathComponent("metric-history.json", isDirectory: false)
    }
}

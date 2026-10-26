#if DEBUG || STORE_DIAGNOSTICS
import AppKit
import MacStateFoundation
import MacStateMetrics
import MacStateStorage

/// Invoked only by an explicit local validation launch; excluded from StoreRelease.
@MainActor
struct StoreDiagnostics {
    static func run() async {
        if CommandLine.arguments.contains("--history-write") || CommandLine.arguments.contains("--history-read") {
            await verifyHistoryAcrossLaunches()
            NSApp.terminate(nil)
            return
        }
        var report: [String: Any] = ["version": 1]
        do {
            let provider = LiveMetricsProvider()
            _ = try await provider.snapshot()
            await withCheckedContinuation { continuation in
                _ = Timer.scheduledTimer(withTimeInterval: 1, repeats: false) { _ in
                    continuation.resume()
                }
            }
            let snapshot = try await provider.snapshot()
            report["cpu"] = snapshot.cpuUsage
            report["cpuCores"] = snapshot.cpuCores.count
            report["memoryTotalBytes"] = snapshot.memoryTotalBytes
            report["memoryUsage"] = snapshot.memoryUsage
            report["networkInterfaces"] = snapshot.activeNetworkInterfaces
            report["networkDownloadBytesPerSecond"] = snapshot.networkDownloadBytesPerSecond
            report["diskCapacityBytes"] = snapshot.disk.totalBytes
            report["diskThroughputUnavailable"] = snapshot.disk.throughputBytesPerSecond == nil
            report["batteryAvailable"] = snapshot.battery != nil
            report["thermalState"] = snapshot.sensors.thermalCondition.rawValue
            report["sensorSource"] = snapshot.sensors.source.rawValue
            report["runningAppCount"] = snapshot.processes.count
            let sharedStore = SharedWidgetSnapshotStore()
            let widgetSnapshot = WidgetSnapshot(snapshot: snapshot)
            report["appGroupWrite"] = sharedStore.save(widgetSnapshot)
            report["appGroupReadBack"] = sharedStore.load() == widgetSnapshot
            let directory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
                .appendingPathComponent("mac-state-validation", isDirectory: true)
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            let historyURL = directory.appendingPathComponent("test-history.json")
            let history = MetricHistoryStore(fileURL: historyURL, legacyDefaults: nil)
            _ = await history.append(snapshot: snapshot)
            let restored = MetricHistoryStore(fileURL: historyURL, legacyDefaults: nil)
            let restoredSamples = await restored.samples()
            report["historyRoundTrip"] = restoredSamples.last?.timestamp == snapshot.timestamp
            let csv = MetricHistoryCSVExporter.csvString(for: restoredSamples)
            try csv.write(to: directory.appendingPathComponent("test-export.csv"), atomically: true, encoding: .utf8)
            report["containerExport"] = true
            report["sandboxContainer"] = NSHomeDirectory().contains("/Library/Containers/")
            let data = try JSONSerialization.data(withJSONObject: report, options: [.prettyPrinted, .sortedKeys])
            try data.write(to: directory.appendingPathComponent("report.json"), options: .atomic)
            print(String(decoding: data, as: UTF8.self))
            try await history.clear()
        } catch {
            NSLog("Store validation failed: %@", String(describing: error))
        }
        NSApp.terminate(nil)
    }
    private static func verifyHistoryAcrossLaunches() async {
        do {
            let directory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
                .appendingPathComponent("mac-state-validation", isDirectory: true)
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            let store = MetricHistoryStore(fileURL: directory.appendingPathComponent("restart-history.json"), legacyDefaults: nil)
            let expectedURL = directory.appendingPathComponent("restart-expected.json")
            if CommandLine.arguments.contains("--history-write") {
                try await store.clear()
                let snapshot = try await LiveMetricsProvider().snapshot()
                let sample = MetricHistorySample(snapshot: snapshot)
                _ = await store.append(sample)
                try JSONEncoder().encode([sample]).write(to: expectedURL, options: .atomic)
                print("History restart seed written in sandbox")
            } else {
                let expected = try JSONDecoder().decode([MetricHistorySample].self, from: Data(contentsOf: expectedURL))
                let actual = await store.samples()
                let restored = !expected.isEmpty && actual == expected
                print("History restored in a new sandbox process: \(restored)")
                try await store.clear()
                try FileManager.default.removeItem(at: expectedURL)
            }
        } catch {
            print("History restart validation failed: \(error)")
        }
    }
}
#endif

import Foundation
import MacStateMetrics

public enum MetricHistoryCSVExporter {
    public static func csvString(for samples: [MetricHistorySample]) -> String {
        let header = [
            "timestamp",
            "cpu_usage_percent",
            "memory_usage_percent",
            "disk_usage_percent",
            "disk_throughput_bytes_per_second",
            "download_bytes_per_second",
            "upload_bytes_per_second",
            "network_throughput_bytes_per_second",
            "battery_level_percent",
        ].joined(separator: ",")

        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [
            .withInternetDateTime,
            .withDashSeparatorInDate,
            .withColonSeparatorInTime,
        ]

        let rows = samples.map { sample in
            [
                formatter.string(from: sample.timestamp),
                decimalString(from: sample.cpuUsage * 100),
                decimalString(from: sample.memoryUsage * 100),
                decimalString(from: sample.diskUsage * 100),
                String(sample.diskThroughputBytesPerSecond),
                String(sample.downloadBytesPerSecond),
                String(sample.uploadBytesPerSecond),
                String(sample.networkThroughputBytesPerSecond),
                sample.batteryLevel.map { decimalString(from: $0 * 100) } ?? "",
            ].joined(separator: ",")
        }

        return ([header] + rows).joined(separator: "\n")
    }

    private static func decimalString(from value: Double) -> String {
        let roundedValue = (value * 100).rounded() / 100
        let wholePart = Int(roundedValue.rounded(.towardZero))
        let decimalPart = Int(abs((roundedValue - Double(wholePart)) * 100).rounded())

        if decimalPart == 0 {
            return "\(wholePart)"
        }

        if decimalPart < 10 {
            return "\(wholePart).0\(decimalPart)"
        }

        return "\(wholePart).\(decimalPart)"
    }
}
